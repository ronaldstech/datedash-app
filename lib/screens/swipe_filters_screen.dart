import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../providers/profile_provider.dart';

class SwipeFiltersScreen extends StatefulWidget {
  const SwipeFiltersScreen({super.key});

  @override
  State<SwipeFiltersScreen> createState() => _SwipeFiltersScreenState();
}

class _SwipeFiltersScreenState extends State<SwipeFiltersScreen> {
  late int _minAge;
  late int _maxAge;
  late double _maxDistance;
  late String _gender;
  late bool _ageStrict;
  late bool _distanceStrict;
  bool _isSaving = false;

  final List<String> _genderOptions = ['Men', 'Women', 'Everyone'];
  final Color _primaryColor = const Color(0xFFFF4D85);
  final Color _secondaryColor = const Color(0xFF4FC3F7);

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileProvider>().userProfile;
    _minAge = profile?.filterMinAge ?? 18;
    // ensure range slider doesn't crash if min > max somehow
    _maxAge = (profile?.filterMaxAge ?? 60) < _minAge
        ? _minAge
        : (profile?.filterMaxAge ?? 60);
    _maxDistance = profile?.filterMaxDistance ?? 50.0;

    _gender = profile?.filterGender ?? 'Everyone';
    if ((profile?.filterGender == null || profile!.filterGender!.isEmpty) &&
        profile?.gender != null) {
      if (profile!.gender == 'Male') _gender = 'Women';
      if (profile.gender == 'Female') _gender = 'Men';
    }

    _ageStrict = profile?.filterAgeStrict ?? false;
    _distanceStrict = profile?.filterDistanceStrict ?? false;
    if (!_genderOptions.contains(_gender)) {
      _gender = 'Everyone';
    }
  }

  Future<void> _saveFilters() async {
    setState(() => _isSaving = true);
    try {
      await context.read<ProfileProvider>().updateFilters(
            _minAge,
            _maxAge,
            _maxDistance,
            _gender,
            _ageStrict,
            _distanceStrict,
          );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving filters: $e')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildGroupCard({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.04),
          width: 1,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: child,
    );
  }

  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color activeThumbColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              if (!value)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          height: 32,
          child: Transform.scale(
            scale: 0.85,
            child: Switch.adaptive(
              value: value,
              activeThumbColor: activeThumbColor,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pull Tab
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Discovery Filters',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      style: IconButton.styleFrom(
                        backgroundColor: isDark
                            ? Colors.white12
                            : Colors.black.withValues(alpha: 0.04),
                        minimumSize: const Size(32, 32),
                      ),
                      icon: const Icon(Icons.close, size: 16),
                    ),
                  ],
                ),
              ),

              // 1. Gender Group
              _buildGroupCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Iconsax.profile_2user,
                            size: 18, color: _primaryColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Show me',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black26
                            : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: _genderOptions.map((option) {
                          final isSelected = _gender == option;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _gender = option);
                              },
                              behavior: HitTestBehavior.opaque,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _primaryColor
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color:
                                                _primaryColor.withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          )
                                        ]
                                      : [],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : isDark
                                            ? Colors.white60
                                            : Colors.black54,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Age Group
              _buildGroupCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Iconsax.calendar_1,
                                size: 18, color: _primaryColor),
                            const SizedBox(width: 8),
                            const Text(
                              'Age Range',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$_minAge - $_maxAge',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: _primaryColor,
                        inactiveTrackColor: _primaryColor.withValues(alpha: 0.15),
                        thumbColor: Colors.white,
                        overlayColor: _primaryColor.withValues(alpha: 0.1),
                        trackHeight: 4,
                        rangeThumbShape: const RoundRangeSliderThumbShape(
                            enabledThumbRadius: 10, elevation: 4),
                      ),
                      child: RangeSlider(
                        values:
                            RangeValues(_minAge.toDouble(), _maxAge.toDouble()),
                        min: 18,
                        max: 99,
                        onChanged: (RangeValues values) {
                          setState(() {
                            _minAge = values.start.round();
                            _maxAge = values.end.round();
                          });
                        },
                      ),
                    ),
                    Divider(
                        color: isDark ? Colors.white12 : Colors.black12,
                        height: 24),
                    _buildToggleRow(
                      title: 'Strict Age Match',
                      subtitle: "We'll slip in a few outliers if you run out.",
                      value: _ageStrict,
                      activeThumbColor: _primaryColor,
                      onChanged: (val) => setState(() => _ageStrict = val),
                    ),
                  ],
                ),
              ),

              // 3. Distance Group
              _buildGroupCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Iconsax.location,
                                size: 18, color: _secondaryColor),
                            const SizedBox(width: 8),
                            const Text(
                              'Maximum Distance',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _secondaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_maxDistance.round()} km',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _secondaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: _secondaryColor,
                        inactiveTrackColor: _secondaryColor.withValues(alpha: 0.15),
                        thumbColor: Colors.white,
                        overlayColor: _secondaryColor.withValues(alpha: 0.1),
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 10, elevation: 4),
                      ),
                      child: Slider(
                        value: _maxDistance,
                        min: 1,
                        max: 150,
                        onChanged: (value) {
                          setState(() {
                            _maxDistance = value;
                          });
                        },
                      ),
                    ),
                    Divider(
                        color: isDark ? Colors.white12 : Colors.black12,
                        height: 24),
                    _buildToggleRow(
                      title: 'Strict Distance Match',
                      subtitle:
                          "We'll suggest folks further away if you run out.",
                      value: _distanceStrict,
                      activeThumbColor: _secondaryColor,
                      onChanged: (val) => setState(() => _distanceStrict = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Apply Button
              ElevatedButton(
                onPressed: _isSaving ? null : _saveFilters,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _primaryColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Apply Filters',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

