import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/routing/route_names.dart';
import '../../core/utils/app_haptics.dart';
import '../../core/widgets/app_card.dart';
import '../../data/local/preference_service.dart';

class SecurityLockScreen extends ConsumerStatefulWidget {
  final bool isStartupUnlock;

  const SecurityLockScreen({super.key, this.isStartupUnlock = false});

  @override
  ConsumerState<SecurityLockScreen> createState() => _SecurityLockScreenState();
}

class _SecurityLockScreenState extends ConsumerState<SecurityLockScreen> {
  late bool _isLockEnabled;
  late bool _isBiometricsEnabled;
  late String _currentPin;
  String _enteredPin = '';
  late bool _isTestingLock;
  String _statusMessage = 'Enter your 4-digit passcode';
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(preferenceServiceProvider);
    _isLockEnabled = prefs.isAppLockEnabled();
    _isBiometricsEnabled = prefs.isBiometricsEnabled();
    _currentPin = prefs.getAppLockPin();
    _isTestingLock = widget.isStartupUnlock;
  }

  void _onKeyPress(String val) {
    if (_enteredPin.length < 4) {
      AppHaptics.light();
      setState(() {
        _enteredPin += val;
        _isError = false;
      });

      if (_enteredPin.length == 4) {
        _verifyOrSavePin();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      AppHaptics.light();
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _isError = false;
      });
    }
  }

  Future<void> _verifyOrSavePin() async {
    final prefs = ref.read(preferenceServiceProvider);

    if (_isTestingLock) {
      if (prefs.verifyPin(_enteredPin)) {
        AppHaptics.celebration();
        if (widget.isStartupUnlock) {
          if (!mounted) return;
          context.go(AppRoutes.home);
          return;
        }
        setState(() {
          _isTestingLock = false;
          _enteredPin = '';
          _statusMessage = 'App unlocked successfully! ✅';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ App Unlocked successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        AppHaptics.heavy();
        setState(() {
          _enteredPin = '';
          _isError = true;
          _statusMessage = 'Incorrect PIN! Try again.';
        });
      }
    } else {
      // Setting up new PIN
      await prefs.setAppLockPin(_enteredPin);
      await prefs.setAppLockEnabled(true);
      AppHaptics.celebration();
      setState(() {
        _currentPin = _enteredPin;
        _isLockEnabled = true;
        _enteredPin = '';
        _statusMessage = 'Passcode saved! 🔒';
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔒 Passcode lock is now active!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSetPinDialog() {
    setState(() {
      _isTestingLock = false;
      _enteredPin = '';
      _statusMessage = 'Enter new 4-digit passcode';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isTestingLock) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF1F5F9),
        appBar: AppBar(
          title: const Text('App Locked 🔒'),
          automaticallyImplyLeading: !widget.isStartupUnlock,
          leading: widget.isStartupUnlock
              ? const SizedBox.shrink()
              : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => setState(() {
                    _isTestingLock = false;
                    _enteredPin = '';
                  }),
                ),
        ),
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_rounded, size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                _statusMessage,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _isError ? AppColors.error : (isDark ? Colors.white : Colors.black87),
                ),
              ),
              const SizedBox(height: 24),
              // 4 PIN Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _enteredPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled
                          ? (_isError ? AppColors.error : AppColors.primary)
                          : Colors.transparent,
                      border: Border.all(
                        color: _isError ? AppColors.error : AppColors.primary,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
              const Spacer(),
              // Keypad
              _buildKeypad(isDark),
              const SizedBox(height: 32),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('App Lock & Privacy 🔒', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Hero Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1E293B),
                    const Color(0xFF0F172A),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_rounded, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Study Privacy Shield',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Protect your personal notes, grades, timetable, and study records with a passcode.',
                          style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Settings Controls
            AppCard(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text(
                      'Enable 4-Digit Passcode',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    subtitle: Text(
                      _isLockEnabled
                          ? 'App is protected with passcode'
                          : 'Require PIN to view student records',
                      style: const TextStyle(fontSize: 12),
                    ),
                    secondary: const Icon(Icons.pin_rounded, color: AppColors.primary),
                    value: _isLockEnabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) async {
                      AppHaptics.selection();
                      if (val && _currentPin.isEmpty) {
                        _showSetPinDialog();
                      } else {
                        final prefs = ref.read(preferenceServiceProvider);
                        await prefs.setAppLockEnabled(val);
                        setState(() {
                          _isLockEnabled = val;
                        });
                      }
                    },
                  ),
                  const Divider(height: 16),
                  SwitchListTile(
                    title: const Text(
                      'Biometric / Fingerprint Unlock',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    subtitle: const Text(
                      'Use device biometric sensor for fast access',
                      style: TextStyle(fontSize: 12),
                    ),
                    secondary: const Icon(Icons.fingerprint_rounded, color: AppColors.success),
                    value: _isBiometricsEnabled,
                    activeThumbColor: AppColors.success,
                    onChanged: (val) async {
                      AppHaptics.selection();
                      final prefs = ref.read(preferenceServiceProvider);
                      await prefs.setBiometricsEnabled(val);
                      setState(() {
                        _isBiometricsEnabled = val;
                      });
                    },
                  ),
                  if (_currentPin.isNotEmpty) ...[
                    const Divider(height: 16),
                    ListTile(
                      leading: const Icon(Icons.password_rounded, color: AppColors.secondary),
                      title: const Text(
                        'Change Passcode',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      subtitle: const Text('Update existing 4-digit PIN', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        AppHaptics.selection();
                        _showSetPinDialog();
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Live Test Button
            if (_isLockEnabled && _currentPin.isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    AppHaptics.selection();
                    setState(() {
                      _isTestingLock = true;
                      _enteredPin = '';
                      _statusMessage = 'Enter your 4-digit passcode';
                      _isError = false;
                    });
                  },
                  icon: const Icon(Icons.lock_clock_rounded, color: Colors.white),
                  label: const Text(
                    'Lock App Now (Test Challenge)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // PIN Setup Pad if creating/changing PIN
            if (_isLockEnabled && _currentPin.isEmpty || _statusMessage.contains('new')) ...[
              AppCard(
                child: Column(
                  children: [
                    Text(
                      _statusMessage,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        final isFilled = index < _enteredPin.length;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isFilled ? AppColors.primary : Colors.transparent,
                            border: Border.all(color: AppColors.primary, width: 2),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    _buildKeypad(isDark),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad(bool isDark) {
    return Column(
      children: [
        _buildKeypadRow(['1', '2', '3'], isDark),
        const SizedBox(height: 16),
        _buildKeypadRow(['4', '5', '6'], isDark),
        const SizedBox(height: 16),
        _buildKeypadRow(['7', '8', '9'], isDark),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 80, height: 60),
            _buildKeypadButton('0', isDark),
            SizedBox(
              width: 80,
              height: 60,
              child: IconButton(
                icon: const Icon(Icons.backspace_outlined),
                onPressed: _onBackspace,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> keys, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((k) => _buildKeypadButton(k, isDark)).toList(),
    );
  }

  Widget _buildKeypadButton(String digit, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2436) : const Color(0xFFE2E8F0),
        shape: BoxShape.circle,
      ),
      child: InkWell(
        onTap: () => _onKeyPress(digit),
        customBorder: const CircleBorder(),
        child: Center(
          child: Text(
            digit,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
