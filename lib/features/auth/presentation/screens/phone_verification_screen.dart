import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/routing/route_paths.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_strings.dart';
import 'package:tuish_food/features/auth/presentation/providers/auth_provider.dart';
import 'package:tuish_food/features/auth/presentation/providers/auth_state.dart';
import 'package:tuish_food/features/auth/presentation/widgets/otp_input_field.dart';

class PhoneVerificationScreen extends ConsumerStatefulWidget {
  const PhoneVerificationScreen({super.key});

  static const String routeName = 'phone-verification';
  static const String routePath = '/phone-verification';

  @override
  ConsumerState<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState
    extends ConsumerState<PhoneVerificationScreen> {
  final _phoneController = TextEditingController();
  bool _codeSent = false;
  String _otp = '';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onSendCode() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your phone number'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    ref.read(authNotifierProvider.notifier).signInWithPhone(phone);
  }

  void _onVerifyOtp() {
    if (_otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete 6-digit code'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    ref.read(authNotifierProvider.notifier).verifyOtp(_otp);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;
    final theme = Theme.of(context);

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.error,
          ),
        );
      } else if (next is PhoneCodeSent) {
        setState(() {
          _codeSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code sent!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (next is Authenticated) {
        context.go(RoutePaths.roleSelection);
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSizes.paddingAllL,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSizes.s16),

              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phone_android,
                  size: AppSizes.iconXL,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: AppSizes.s32),

              // Header
              Text(
                _codeSent ? AppStrings.verifyOtp : 'Phone Verification',
                style: theme.textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.s12),
              Text(
                _codeSent
                    ? 'Enter the 6-digit code sent to ${_phoneController.text}'
                    : 'Enter your phone number to receive a verification code',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSizes.s48),

              if (!_codeSent) ...[
                // Phone number input
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _onSendCode(),
                  decoration: const InputDecoration(
                    hintText: AppStrings.phone,
                    prefixIcon: Icon(Icons.phone_outlined),
                    helperText: 'Include country code (e.g., +1234567890)',
                  ),
                ),

                const SizedBox(height: AppSizes.s32),

                // Send code button
                ElevatedButton(
                  onPressed: isLoading ? null : _onSendCode,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Send Verification Code'),
                ),
              ] else ...[
                // OTP input
                OtpInputField(
                  onCompleted: (otp) {
                    _otp = otp;
                    _onVerifyOtp();
                  },
                  onChanged: (otp) {
                    _otp = otp;
                  },
                ),

                const SizedBox(height: AppSizes.s32),

                // Verify button
                ElevatedButton(
                  onPressed: isLoading ? null : _onVerifyOtp,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(AppStrings.verifyOtp),
                ),

                const SizedBox(height: AppSizes.s16),

                // Resend code
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive the code? ",
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: isLoading ? null : _onSendCode,
                      child: const Text(AppStrings.resendOtp),
                    ),
                  ],
                ),

                const SizedBox(height: AppSizes.s8),

                // Change phone number
                TextButton(
                  onPressed: () {
                    setState(() {
                      _codeSent = false;
                      _otp = '';
                    });
                    ref.read(authNotifierProvider.notifier).resetState();
                  },
                  child: const Text('Change Phone Number'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
