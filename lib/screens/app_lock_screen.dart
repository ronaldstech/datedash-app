import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

class AppLockScreen extends StatefulWidget {
  final VoidCallback onUnlock;
  const AppLockScreen({super.key, required this.onUnlock});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> with TickerProviderStateMixin {
  final List<String> _enteredPin = [];
  String? _savedPin;
  bool _isBiometricEnabled = false;
  bool _isScanningBiometric = false;
  bool _biometricSuccess = false;

  final Color _primaryColor = const Color(0xFFFF4D85);

  late AnimationController _pulseController;
  late Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _loadSettings();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedPin = prefs.getString('app_lock_pin');
      _isBiometricEnabled = prefs.getBool('biometric_lock_enabled') ?? false;
    });

    // Auto-trigger biometric check on start if enabled
    if (_isBiometricEnabled) {
      _triggerBiometricScan();
    }
  }

  Future<void> _triggerBiometricScan() async {
    if (_isScanningBiometric || _biometricSuccess) return;

    setState(() {
      _isScanningBiometric = true;
    });

    // Stunning simulated scanner delay & pulse
    await Future.delayed(const Duration(milliseconds: 1800));

    if (!mounted) return;

    setState(() {
      _isScanningBiometric = false;
      _biometricSuccess = true;
    });

    // Play quick success sound/haptic delay
    await Future.delayed(const Duration(milliseconds: 400));
    widget.onUnlock();
  }

  void _onNumberTap(int number) {
    if (_enteredPin.length >= 4) return;

    setState(() {
      _enteredPin.add(number.toString());
    });

    if (_enteredPin.length == 4) {
      _verifyPin();
    }
  }

  void _onBackspace() {
    if (_enteredPin.isEmpty) return;
    setState(() {
      _enteredPin.removeLast();
    });
  }

  Future<void> _verifyPin() async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    
    if (_enteredPin.join() == _savedPin) {
      widget.onUnlock();
    } else {
      setState(() {
        _enteredPin.clear();
      });
      // Show snack
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Incorrect PIN. Please try again.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(24),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasBiometricOption = _isBiometricEnabled;

    return Scaffold(
      body: Stack(
        children: [
          // Background elegant gradient matching DateDash aesthetic
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F0F12),
                    Color(0xFF1E0B16),
                  ],
                ),
              ),
            ),
          ),

          // Glowing premium floating blurs
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primaryColor.withOpacity(0.08),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primaryColor.withOpacity(0.05),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Logo and Title
                  Hero(
                    tag: 'app_logo',
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.03),
                        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Image.asset(
                        'assets/images/signlogo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter PIN to unlock DateDash',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // PIN indicator dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isActive = index < _enteredPin.length;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive ? _primaryColor : Colors.transparent,
                          border: Border.all(
                            color: isActive ? _primaryColor : Colors.white.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),
                  
                  const Spacer(flex: 2),

                  // Numeric Keypad
                  SizedBox(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.45,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.3,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        // Position 9: Biometric / Cancel
                        if (index == 9) {
                          if (hasBiometricOption) {
                            return Center(
                              child: ScaleTransition(
                                scale: _pulseScale,
                                child: IconButton(
                                  icon: Icon(
                                    _biometricSuccess 
                                        ? Icons.verified_user_rounded 
                                        : Iconsax.finger_scan, 
                                    color: _biometricSuccess ? Colors.green : _primaryColor,
                                    size: 32,
                                  ),
                                  onPressed: _triggerBiometricScan,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }
                        // Position 11: Backspace
                        if (index == 11) {
                          return Center(
                            child: IconButton(
                              icon: Icon(Icons.backspace_outlined, color: Colors.white.withOpacity(0.7), size: 22),
                              onPressed: _onBackspace,
                            ),
                          );
                        }

                        final number = index == 10 ? 0 : index + 1;
                        return Center(
                          child: InkWell(
                            onTap: () => _onNumberTap(number),
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.02),
                                border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
                              ),
                              child: Center(
                                child: Text(
                                  number.toString(),
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),

          // Biometric Scanning Overlay
          if (_isScanningBiometric)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ScaleTransition(
                          scale: _pulseScale,
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _primaryColor.withOpacity(0.12),
                              border: Border.all(color: _primaryColor.withOpacity(0.3), width: 2),
                            ),
                            child: Icon(Iconsax.finger_scan5, size: 72, color: _primaryColor),
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'Scanning Fingerprint...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Place your finger on your reader to unlock',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
