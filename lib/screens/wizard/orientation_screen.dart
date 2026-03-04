import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/onboarding_provider.dart';

/// Sexual Orientation Screen
///
/// Orientation combos logic (industry-standard, matches Tinder/Bumble/Hinge):
/// - "Primary" group: Straight, Gay, Lesbian — mutually exclusive (pick max 1)
/// - "Spectrum" group: Bisexual, Pansexual, Queer, Questioning, Asexual, Demisexual
///   — can combine freely with each other + with 1 primary label
/// - Max 3 total selections
class OrientationScreen extends StatefulWidget {
  const OrientationScreen({super.key});

  @override
  State<OrientationScreen> createState() => _OrientationScreenState();
}

class _OrientationScreenState extends State<OrientationScreen> {
  final Set<String> _selected = {};
  bool _showOnProfile = false;
  static const int _maxSelections = 3;

  /// Primary attraction labels — mutually exclusive with each other.
  static const Set<String> _primaryGroup = {'Straight', 'Gay', 'Lesbian'};

  static const List<Map<String, String>> _orientations = [
    {'label': 'Straight', 'desc': 'Attracted to the opposite gender'},
    {'label': 'Gay', 'desc': 'Attracted to the same gender'},
    {'label': 'Lesbian', 'desc': 'Women attracted to women'},
    {'label': 'Bisexual', 'desc': 'Attracted to more than one gender'},
    {'label': 'Asexual', 'desc': 'Little or no sexual attraction'},
    {'label': 'Demisexual', 'desc': 'Attraction after emotional bond'},
    {'label': 'Pansexual', 'desc': 'Attraction regardless of gender'},
    {'label': 'Queer', 'desc': 'Not heterosexual or cisgender'},
    {'label': 'Questioning', 'desc': 'Exploring or unsure'},
  ];

  bool get _isValid => _selected.isNotEmpty;

  void _toggleOrientation(String orientation) {
    setState(() {
      if (_selected.contains(orientation)) {
        // Deselect
        _selected.remove(orientation);
      } else if (_selected.length < _maxSelections) {
        // If selecting a primary label, remove any other primary first
        if (_primaryGroup.contains(orientation)) {
          _selected.removeWhere((s) => _primaryGroup.contains(s));
        }
        _selected.add(orientation);
      }
    });
  }

  /// Whether this option can be tapped right now.
  bool _canSelect(String label) {
    if (_selected.contains(label)) return true; // can always deselect
    if (_selected.length >= _maxSelections) return false;
    // If selecting a primary and already have one, we'll swap — allow it
    if (_primaryGroup.contains(label)) return true;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => OnboardingProvider.of(context).goNext(context),
            child: Text(l10n.skipButton,
                style: TextStyle(color: Colors.grey[600], fontSize: 15)),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => OnboardingProvider.of(context).abort(context),
          ),
        ],
      ),
      body: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: OnboardingProvider.of(context).progress(context),
              backgroundColor: Colors.grey[200],
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFFF6B6B)),
              minHeight: 4,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    l10n.whatsYourOrientation,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.selectOrientations,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _orientations.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final o = _orientations[index];
                        final label = o['label']!;
                        final desc = o['desc']!;
                        final isSelected = _selected.contains(label);
                        final canSelect = _canSelect(label);

                        return GestureDetector(
                          onTap: canSelect
                              ? () => _toggleOrientation(label)
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFF6B6B).withAlpha(25)
                                  : Colors.white,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFFF6B6B)
                                    : canSelect
                                        ? Colors.grey[300]!
                                        : Colors.grey[200]!,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Opacity(
                              opacity: canSelect ? 1.0 : 0.4,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          label,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? const Color(0xFFFF6B6B)
                                                : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          desc,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[500],
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 12),
                                    const Icon(Icons.check_circle,
                                        color: Color(0xFFFF6B6B), size: 24),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: _showOnProfile,
                        onChanged: (v) =>
                            setState(() => _showOnProfile = v ?? false),
                        activeColor: const Color(0xFFFF6B6B),
                      ),
                      Expanded(
                        child: Text(
                          l10n.showOrientationOnProfile,
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Next button — always visible, dimmed when no selection
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isValid
                          ? () {
                              final d = OnboardingProvider.of(context).data;
                              d.orientation = _selected.toList();
                              d.orientationVisible = _showOnProfile;
                              OnboardingProvider.of(context).goNext(context);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B6B),
                        disabledBackgroundColor: Colors.grey[300],
                        disabledForegroundColor: Colors.white70,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27)),
                      ),
                      child: Text(
                        l10n.nextButton,
                        style:
                            const TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
