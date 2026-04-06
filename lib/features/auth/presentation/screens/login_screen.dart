import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/widgets/glass_scaffold.dart';
import 'package:tuish_food/routing/route_paths.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_strings.dart';
import 'package:tuish_food/features/auth/presentation/providers/auth_provider.dart';
import 'package:tuish_food/features/auth/presentation/providers/auth_state.dart';
import 'package:tuish_food/features/auth/presentation/widgets/social_sign_in_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const String routeName = 'login';
  static const String routePath = '/login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  late final AnimationController _animController;
  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _headerOffset;
  late final Animation<double> _emailOpacity;
  late final Animation<Offset> _emailOffset;
  late final Animation<double> _passwordOpacity;
  late final Animation<Offset> _passwordOffset;
  late final Animation<double> _forgotOpacity;
  late final Animation<Offset> _forgotOffset;
  late final Animation<double> _buttonOpacity;
  late final Animation<Offset> _buttonOffset;
  late final Animation<double> _socialOpacity;
  late final Animation<Offset> _socialOffset;
  late final Animation<double> _registerOpacity;
  late final Animation<Offset> _registerOffset;

  Animation<double> _buildOpacity(double start, double end) {
    return Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ),
    );
  }

  Animation<Offset> _buildSlide(double start, double end) {
    return Tween<Offset>(begin: const Offset(0, 20), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _headerOpacity = _buildOpacity(0.0, 0.3);
    _headerOffset = _buildSlide(0.0, 0.3);
    _emailOpacity = _buildOpacity(0.15, 0.45);
    _emailOffset = _buildSlide(0.15, 0.45);
    _passwordOpacity = _buildOpacity(0.3, 0.6);
    _passwordOffset = _buildSlide(0.3, 0.6);
    _forgotOpacity = _buildOpacity(0.4, 0.7);
    _forgotOffset = _buildSlide(0.4, 0.7);
    _buttonOpacity = _buildOpacity(0.5, 0.8);
    _buttonOffset = _buildSlide(0.5, 0.8);
    _socialOpacity = _buildOpacity(0.6, 0.9);
    _socialOffset = _buildSlide(0.6, 0.9);
    _registerOpacity = _buildOpacity(0.7, 1.0);
    _registerOffset = _buildSlide(0.7, 1.0);

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      ref
          .read(authNotifierProvider.notifier)
          .signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
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
      } else if (next is Authenticated) {
        // Navigate to splash and let the router redirect based on role.
        // Returning users (with a role) go straight to home;
        // new users (no role) get sent to role selection.
        context.go(RoutePaths.splash);
      }
    });

    return GlassScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSizes.paddingAllL,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSizes.s48),

                // Header
                AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) => Opacity(
                    opacity: _headerOpacity.value,
                    child: Transform.translate(
                      offset: _headerOffset.value,
                      child: child,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Welcome Back',
                        style: theme.textTheme.headlineLarge,
                      ),
                      const SizedBox(height: AppSizes.s8),
                      Text(
                        'Sign in to continue ordering delicious food',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSizes.s48),

                // Email field
                AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) => Opacity(
                    opacity: _emailOpacity.value,
                    child: Transform.translate(
                      offset: _emailOffset.value,
                      child: child,
                    ),
                  ),
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: _validateEmail,
                    decoration: const InputDecoration(
                      hintText: AppStrings.email,
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.s16),

                // Password field
                AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) => Opacity(
                    opacity: _passwordOpacity.value,
                    child: Transform.translate(
                      offset: _passwordOffset.value,
                      child: child,
                    ),
                  ),
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    validator: _validatePassword,
                    onFieldSubmitted: (_) => _onLogin(),
                    decoration: InputDecoration(
                      hintText: AppStrings.password,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.s8),

                // Forgot password
                AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) => Opacity(
                    opacity: _forgotOpacity.value,
                    child: Transform.translate(
                      offset: _forgotOffset.value,
                      child: child,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push(RoutePaths.forgotPassword),
                      child: const Text(AppStrings.forgotPassword),
                    ),
                  ),
                ),

                const SizedBox(height: AppSizes.s24),

                // Login button
                AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) => Opacity(
                    opacity: _buttonOpacity.value,
                    child: Transform.translate(
                      offset: _buttonOffset.value,
                      child: child,
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _onLogin,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : const Text(AppStrings.signIn),
                  ),
                ),

                const SizedBox(height: AppSizes.s32),

                // Social buttons section
                AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) => Opacity(
                    opacity: _socialOpacity.value,
                    child: Transform.translate(
                      offset: _socialOffset.value,
                      child: child,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Divider
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.s16,
                            ),
                            child: Text(
                              AppStrings.orContinueWith,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),

                      const SizedBox(height: AppSizes.s24),

                      // Phone sign in
                      SocialSignInButton(
                        icon: Icons.phone_outlined,
                        label: 'Continue with Phone',
                        onPressed: () => context.push(RoutePaths.phoneVerify),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSizes.s48),

                // Sign up link
                AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) => Opacity(
                    opacity: _registerOpacity.value,
                    child: Transform.translate(
                      offset: _registerOffset.value,
                      child: child,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppStrings.dontHaveAccount,
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () => context.push(RoutePaths.register),
                        child: const Text(AppStrings.signUp),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
