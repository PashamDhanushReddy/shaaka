import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'home_customer_page.dart';
import 'home_vendor_page.dart';
import 'home_women_merchant_page.dart';
import 'profile_page.dart';
import '../utils/responsive.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await ApiService.login(
      _mobileController.text.trim(),
      _passwordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true && mounted) {
      final user = result['data'];
      await StorageService.saveUserId(user.id!);
      await StorageService.saveUserCategory(user.category);
      
      if (user.addressLine == null || user.addressLine!.isEmpty) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const ProfilePage(isCompletingProfile: true),
            ),
            (route) => false,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please complete your profile to continue.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => _getHomePage(user.category),
            ),
            (route) => false,
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['error'] is Map
                  ? (result['error']['error'] ?? 'Login failed')
                  : result['error'].toString(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _getHomePage(String category) {
    switch (category) {
      case 'Customer':
        return const HomeCustomerPage();
      case 'Vendor':
        return const HomeVendorPage();
      case 'Women Merchant':
        return const HomeWomenMerchantPage();
      default:
        return const HomeCustomerPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Responsive.centeredWebContainer(
        context,
        maxWidth: 600,
        child: SafeArea(
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: AppAnimations.medium,
                  curve: AppAnimations.defaultCurve,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.scale(
                        scale: value,
                        child: Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                'assets/images/logo.jpg',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: AppAnimations.medium,
                  curve: AppAnimations.defaultCurve,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Column(
                          children: [
                            Text(
                              'Welcome Back',
                              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Login to your account',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).textTheme.bodyMedium!.color!,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 48),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: AppAnimations.medium,
                  curve: AppAnimations.defaultCurve,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: TextFormField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                      counterText: "",
                    ),
                    maxLength: 10,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your mobile number';
                      }
                      if (value.length != 10) {
                        return 'Mobile number must be exactly 10 digits';
                      }
                      if (!RegExp(r'^[6-9]').hasMatch(value)) {
                        return 'Mobile number must start with 6, 7, 8, or 9';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: AppAnimations.medium,
                  curve: AppAnimations.defaultCurve,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Theme.of(context).textTheme.bodyMedium!.color!,
                            ),
                          ),
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 32),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: AppAnimations.slow,
                  curve: AppAnimations.defaultCurve,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: _AnimatedButton(
                    onPressed: _isLoading ? null : _login,
                    isLoading: _isLoading,
                    child: const Text('Login'),
                  ),
                ),
                const SizedBox(height: 20),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: AppAnimations.slow,
                  curve: AppAnimations.defaultCurve,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/register');
                          },
                          child: RichText(
                            text: TextSpan(
                              style: Theme.of(context).textTheme.bodyMedium,
                              children: [
                                TextSpan(
                                  text: "Don't have an account? ",
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                TextSpan(
                                  text: 'Register',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _AnimatedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget child;

  const _AnimatedButton({
    required this.onPressed,
    required this.isLoading,
    required this.child,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.fast,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        if (widget.onPressed != null) {
          widget.onPressed!();
        }
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 - (_controller.value * 0.05),
            child: ElevatedButton(
              onPressed: widget.onPressed,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: _isPressed ? 2 : 4,
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : widget.child,
            ),
          );
        },
      ),
    );
  }
}

