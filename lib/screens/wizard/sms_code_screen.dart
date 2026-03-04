import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../config/dev_mode.dart';
import '../../config/environment.dart';
import '../../services/firebase_phone_auth_service.dart';
import '../../services/auth_session_manager.dart';
import '../../services/api_service.dart';
import '../../providers/onboarding_provider.dart';

/// SMS Verification Code Entry Screen
/// 6-digit code input with auto-advance, resend timer, and retry limits.
/// Verifies via Firebase → exchanges for Keycloak JWT → starts session.
///
/// Supports two modes:
/// 1. Onboarding mode (wrapped in OnboardingProvider) — advances to next wizard step
/// 2. Sign-in mode (no OnboardingProvider) — checks for existing profile → /home or error
///
/// In DevMode: auto-fills the test code (123456) and skips Keycloak if unavailable.
class SmsCodeScreen extends StatefulWidget {
  const SmsCodeScreen({super.key});

  @override
  State<SmsCodeScreen> createState() => _SmsCodeScreenState();
}

class _SmsCodeScreenState extends State<SmsCodeScreen> {
  static const Color _coral = Color(0xFFFF6B6B);
  static const int _codeLength = 6;
  static const int _resendSeconds = 60;
  static const int _maxResends = 5;

  final List<TextEditingController> _controllers =
      List.generate(_codeLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_codeLength, (_) => FocusNode());

  Timer? _resendTimer;
  int _secondsRemaining = _resendSeconds;
  bool _canResend = false;
  int _resendCount = 0;
  bool _isVerifying = false;
  String? _errorMessage;

  // Data from phone_entry_screen
  String? _verificationId;
  String? _phoneNumber;
  bool _autoVerified = false;
  String? _firebaseIdToken;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _extractRouteArgs();
      // DevMode: auto-fill test SMS code after a brief delay
      if (DevMode.enabled) {
        _autoFillTestCode();
      } else {
        _focusNodes[0].requestFocus();
      }
    });
  }

  /// Auto-fill the test SMS code in DevMode
  void _autoFillTestCode() {
    final testCode = DevMode.fakeSmsCode; // "123456"
    for (int i = 0; i < _codeLength && i < testCode.length; i++) {
      _controllers[i].text = testCode[i];
    }
    setState(() {});
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && !_autoVerified && !_hasNavigated) {
        final code = _controllers.map((c) => c.text).join();
        if (code.length == _codeLength) {
          _verifyCode(code);
        }
      }
    });
  }

  void _extractRouteArgs() {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) return;

    _verificationId = args['verificationId'] as String?;
    _phoneNumber = args['phoneNumber'] as String?;
    _autoVerified = args['autoVerified'] == true;
    _firebaseIdToken = args['firebaseIdToken'] as String?;

    // If auto-verified (Android), skip OTP entry — exchange token immediately
    if (_autoVerified && _firebaseIdToken != null) {
      _completeLogin(_firebaseIdToken!);
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _canResend = false;
    _secondsRemaining = _resendSeconds;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < _codeLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }

    final code = _controllers.map((c) => c.text).join();
    if (code.length == _codeLength) {
      _verifyCode(code);
    }
  }

  void _onKeyPress(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
    }
  }

  /// Whether we're in sign-in mode (no OnboardingProvider ancestor)
  bool get _isSignInMode => OnboardingProvider.maybeOf(context) == null;

  Future<void> _verifyCode(String code) async {
    if (_verificationId == null) {
      setState(() => _errorMessage = AppLocalizations.of(context).verificationSessionExpired);
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    // Desktop DevMode: Firebase not available — skip verification
    if (DevMode.enabled &&
        defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      debugPrint('🔧 DevMode on desktop: skipping Firebase SMS verify');
      if (mounted) {
        _handlePostAuth();
      }
      return;
    }

    try {
      final firebaseIdToken = await FirebasePhoneAuthService.verifySmsCode(
        verificationId: _verificationId!,
        smsCode: code,
      );

      if (firebaseIdToken == null) {
        if (mounted) {
          setState(() {
            _isVerifying = false;
            _errorMessage = AppLocalizations.of(context).invalidCode;
          });
          _clearCode();
        }
        return;
      }

      await _completeLogin(firebaseIdToken);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _errorMessage = AppLocalizations.of(context).verificationFailed;
        });
        _clearCode();
      }
    }
  }

  /// Exchange Firebase token → Keycloak JWT → start app session.
  Future<void> _completeLogin(String firebaseIdToken) async {
    setState(() => _isVerifying = true);

    try {
      final result = await AuthSessionManager.loginWithPhone(firebaseIdToken);

      if (!mounted) return;

      if (result.success) {
        _handlePostAuth();
      } else if (DevMode.enabled) {
        debugPrint('🔧 DevMode: Keycloak exchange failed, skipping forward. Error: ${result.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🔧 DevMode: Skipped Keycloak (not running). Phone verified via Firebase.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
          _handlePostAuth();
        }
      } else {
        setState(() {
          _isVerifying = false;
          _errorMessage = result.message ?? AppLocalizations.of(context).loginFailed;
        });
        _clearCode();
      }
    } catch (e) {
      if (!mounted) return;
      if (DevMode.enabled) {
        debugPrint('🔧 DevMode: Login exception, skipping forward. Error: $e');
        _handlePostAuth();
      } else {
        setState(() {
          _isVerifying = false;
          _errorMessage = AppLocalizations.of(context).couldNotCompleteLogin;
        });
        _clearCode();
      }
    }
  }

  /// Route after successful auth — depends on mode:
  /// - Onboarding mode → advance to next wizard step
  /// - Sign-in mode → check for existing profile → /home or show error
  Future<void> _handlePostAuth() async {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    final onboarding = OnboardingProvider.maybeOf(context);

    if (onboarding != null) {
      // Onboarding mode — continue wizard
      onboarding.goNext(context);
      return;
    }

    // Sign-in mode — check if user has an existing profile
    final appState = AppState();
    final token = appState.authToken;
    final userId = appState.userId;

    if (token != null && userId != null) {
      try {
        final resp = await http.get(
          Uri.parse('${EnvironmentConfig.settings.gatewayUrl}/api/users/$userId'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (!mounted) return;

        if (resp.statusCode == 200) {
          // Existing user with profile → go to home
          await appState.setOnboardingComplete();
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          return;
        }
      } catch (e) {
        debugPrint('⚠️ Profile check failed: $e');
      }
    }

    if (!mounted) return;

    // No profile found — this number isn't registered yet
    setState(() {
      _isVerifying = false;
      _errorMessage = AppLocalizations.of(context).accountNotFound;
    });
    _clearCode();
  }

  void _clearCode() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
  }

  void _resendCode() {
    if (!_canResend || _resendCount >= _maxResends || _phoneNumber == null) return;

    setState(() {
      _resendCount++;
      _errorMessage = null;
    });

    _clearCode();

    FirebasePhoneAuthService.verifyPhoneNumber(
      phoneNumber: _phoneNumber!,
      onCodeSent: (newVerificationId) {
        _verificationId = newVerificationId;
      },
      onVerificationCompleted: (credential) async {
        final idToken = await FirebasePhoneAuthService.signInWithAutoCredential(credential);
        if (idToken != null) {
          _completeLogin(idToken);
        }
      },
      onError: (message) {
        if (mounted) {
          setState(() => _errorMessage = message);
        }
      },
      onAutoRetrievalTimeout: () {
        debugPrint('Auto-retrieval timeout on resend');
      },
    );

    _startResendTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).codeResent(_maxResends - _resendCount)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final onboarding = OnboardingProvider.maybeOf(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress bar — only in onboarding mode
                  if (onboarding != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: onboarding.progress(context),
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation(_coral),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  Text(
                    l10n.enterVerificationCode,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _phoneNumber != null
                        ? l10n.codeSentToPhone(_phoneNumber!)
                        : l10n.codeSentToPhoneFallback,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  // DevMode banner
                  if (DevMode.enabled)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.bug_report, color: Colors.green[700], size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Test mode: code ${DevMode.fakeSmsCode} auto-filled',
                              style: TextStyle(fontSize: 13, color: Colors.green[800], fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 8),

                  // 6 digit input boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_codeLength, (i) {
                      return SizedBox(
                        width: 48,
                        height: 56,
                        child: KeyboardListener(
                          focusNode: FocusNode(),
                          onKeyEvent: (e) => _onKeyPress(i, e),
                          child: TextField(
                            controller: _controllers[i],
                            focusNode: _focusNodes[i],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            enabled: !_isVerifying,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                            decoration: InputDecoration(
                              counterText: '',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _errorMessage != null ? Colors.red : Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: _coral, width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red, width: 2),
                              ),
                              filled: true,
                              fillColor: _focusNodes[i].hasFocus ? Colors.white : Colors.grey[50],
                            ),
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: (v) => _onDigitChanged(i, v),
                          ),
                        ),
                      );
                    }),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 14)),
                  ],

                  const SizedBox(height: 32),

                  // Verifying spinner
                  if (_isVerifying)
                    Center(
                      child: Column(
                        children: [
                          const CircularProgressIndicator(color: _coral),
                          const SizedBox(height: 12),
                          Text(l10n.verifying, style: const TextStyle(color: Colors.black)),
                        ],
                      ),
                    ),

                  // Resend section
                  if (!_isVerifying) ...[
                    Center(
                      child: _canResend && _resendCount < _maxResends
                          ? TextButton(
                              onPressed: _resendCode,
                              child: Text(
                                l10n.resendCode,
                                style: const TextStyle(color: _coral, fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                            )
                          : Text(
                              _resendCount >= _maxResends
                                  ? l10n.maxResendReached
                                  : l10n.resendCodeIn(_secondsRemaining),
                              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                            ),
                    ),
                  ],

                  const Spacer(),

                  // "Go back" button for sign-in mode when account not found
                  if (_isSignInMode && _errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _coral,
                            side: const BorderSide(color: _coral),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          child: Text(l10n.goBackButton, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.smsRatesInfo,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
