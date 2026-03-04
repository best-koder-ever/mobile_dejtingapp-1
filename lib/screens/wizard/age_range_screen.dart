import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/onboarding_provider.dart';

/// Age Range Preference Screen — consistent white-background style
class AgeRangeScreen extends StatefulWidget {
  const AgeRangeScreen({super.key});

  @override
  State<AgeRangeScreen> createState() => _AgeRangeScreenState();
}

class _AgeRangeScreenState extends State<AgeRangeScreen> {
  static const double _minAllowed = 18;
  static const double _maxAllowed = 100;
  static const _coral = Color(0xFFFF6B6B);

  late RangeValues _range;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final data = OnboardingProvider.of(context).data;
    _range = RangeValues(
      data.minAge.toDouble().clamp(_minAllowed, _maxAllowed),
      data.maxAge.toDouble().clamp(_minAllowed, _maxAllowed),
    );
  }

  void _onNext() {
    final onboarding = OnboardingProvider.of(context);
    onboarding.data.minAge = _range.start.round();
    onboarding.data.maxAge = _range.end.round();
    onboarding.goNext(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final onboarding = OnboardingProvider.of(context);
    final startAge = _range.start.round();
    final endAge = _range.end.round();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => onboarding.abort(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: onboarding.progress(context),
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation(_coral),
              minHeight: 4,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    l10n.ageRangeTitle,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Age range display
                  Center(
                    child: Text(
                      '$startAge – $endAge',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: _coral,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      l10n.yearsOld,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Range slider
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _coral,
                      inactiveTrackColor: Colors.grey[300],
                      thumbColor: _coral,
                      overlayColor: _coral.withAlpha(40),
                      trackHeight: 4,
                      rangeThumbShape: const RoundRangeSliderThumbShape(
                        enabledThumbRadius: 14,
                        elevation: 4,
                      ),
                    ),
                    child: RangeSlider(
                      values: _range,
                      min: _minAllowed,
                      max: _maxAllowed,
                      divisions: (_maxAllowed - _minAllowed).round(),
                      labels: RangeLabels('$startAge', '$endAge'),
                      onChanged: (values) {
                        setState(() => _range = values);
                      },
                    ),
                  ),

                  // Min / Max labels
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${_minAllowed.round()}',
                            style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                        Text('${_maxAllowed.round()}',
                            style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Bottom hints
                  Row(
                    children: [
                      Icon(Icons.tune, color: Colors.grey[500], size: 18),
                      const SizedBox(width: 8),
                      Text(
                        l10n.editableInSettings,
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.visibility_off, color: Colors.grey[500], size: 18),
                      const SizedBox(width: 8),
                      Text(
                        l10n.notVisibleOnProfile,
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Next button — full width, always visible
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _coral,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(27),
                        ),
                      ),
                      child: const Text(
                        'Next',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
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
