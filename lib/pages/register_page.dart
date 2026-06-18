import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import 'profile_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  
  final _fullNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _genderController = TextEditingController();

  final _otpController = TextEditingController();

  String? _selectedCategory;
  String? _selectedGender;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _otpSent = false;
  bool _otpVerified = false;
  XFile? _profileImage;
  Uint8List? _profileImageBytes;
  String? _profileImageUrl;

  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasDigits = false;
  bool _hasSpecialCharacters = false;

  void _checkPassword(String password) {
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasDigits = password.contains(RegExp(r'[0-9]'));
      _hasSpecialCharacters = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  final ImagePicker _imagePicker = ImagePicker();

  final List<String> _categories = ['Customer'];
  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void dispose() {
    _fullNameController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _genderController.dispose();

    _otpController.dispose();
    super.dispose();
  }

  Future<void> _requestOTP() async {
    String mobile = _mobileController.text.trim();
    if (mobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your mobile number first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (mobile.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mobile number must be exactly 10 digits'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!RegExp(r'^[6-9]').hasMatch(mobile)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mobile number must start with 6, 7, 8, or 9'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await ApiService.requestOTP(_mobileController.text.trim());

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true && mounted) {
      setState(() {
        _otpSent = true;
        _otpController.clear(); // Clear any previous OTP
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('OTP Sent'),
          content: const Text(
            'OTP has been sent! Check your backend terminal/console to see the OTP code.\n\n'
            'The OTP field is now available below for you to enter the code.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['error']?['error'] ?? 'Failed to send OTP. Please try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await ApiService.verifyOTP(
      _mobileController.text.trim(),
      _otpController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true && mounted) {
      setState(() {
        _otpVerified = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP verified successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['error']?['error'] ?? 'Invalid OTP. Please try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Add Profile Photo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _imageSourceCard(
                    ctx,
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    color: Colors.teal,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _imageSourceCard(
                    ctx,
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageSourceCard(
    BuildContext ctx, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 130,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }


  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _profileImage = image;
          _profileImageBytes = bytes;
        });

        setState(() {
          _isLoading = true;
        });

        final uploadResult = await ApiService.uploadImage(_profileImage!);

        setState(() {
          _isLoading = false;
        });

        if (uploadResult['success'] == true) {
          setState(() {
            _profileImageUrl = uploadResult['url'];
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile picture uploaded successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  uploadResult['error']?['error'] ?? 'Failed to upload image',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_otpVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify OTP first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });



    final userData = {
      'full_name': _fullNameController.text.trim(),
      'mobile_number': _mobileController.text.trim(),
      'password': _passwordController.text,
      'category': _selectedCategory,
      'gender': _selectedGender,
      'profile_pic_url': _profileImageUrl,

    };

    final result = await ApiService.register(userData);

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true && mounted) {
      final user = result['data'];
      await StorageService.saveUserId(user.id!);
      await StorageService.saveUserCategory(user.category);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const ProfilePage(isCompletingProfile: true),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful. Please complete your profile.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['error']?['error'] ?? 'Registration failed. Please try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        elevation: 0,
      ),
      body: Responsive.centeredWebContainer(
        context,
        maxWidth: 600,
        child: SafeArea(
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.verified_user_outlined,
                                color: Theme.of(context).colorScheme.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Mobile Verification',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        enabled: !_otpSent,
                        decoration: const InputDecoration(
                          labelText: 'Mobile Number',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                          counterText: "", // Hide maxLength counter if desired, or keep it
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
                      const SizedBox(height: 16),
                      if (!_otpSent)
                        ElevatedButton(
                          onPressed: _isLoading ? null : _requestOTP,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Send OTP'),
                        ),
                      if (_otpSent && !_otpVerified) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Check your backend terminal for the OTP code',
                                  style: TextStyle(
                                    color: Colors.blue[900],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          autofocus: true,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Enter OTP',
                            hintText: '000000',
                            prefixIcon: Icon(Icons.lock_clock),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _verifyOTP,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Verify OTP'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _otpSent = false;
                                    _otpController.clear();
                                  });
                                },
                          child: const Text('Resend OTP'),
                        ),
                      ],
                      if (_otpVerified)
                        const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              'OTP Verified',
                              style: TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: AppAnimations.medium,
                      curve: AppAnimations.defaultCurve,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.scale(
                            scale: value,
                            child: child,
                          ),
                        );
                      },
                      child: Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 3,
                                ),
                              ),
                              child: ClipOval(
                                child: _profileImageBytes != null
                                    ? Image.memory(
                                        _profileImageBytes!,
                                        fit: BoxFit.cover,
                                      )
                                    : _profileImageUrl != null
                                        ? Image.network(
                                            _profileImageUrl!,
                                            fit: BoxFit.cover,
                                          )
                                        : Icon(
                                            Icons.person,
                                            size: 60,
                                            color: Theme.of(context).textTheme.bodyMedium!.color!,
                                          ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Material(
                                color: AppTheme.accentTerracotta,
                                shape: const CircleBorder(),
                                elevation: 4,
                                child: InkWell(
                                  onTap: _isLoading ? null : _showImageSourceActionSheet,
                                  borderRadius: BorderRadius.circular(24),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      items: _genders.map((String gender) {
                        return DropdownMenuItem<String>(
                          value: gender,
                          child: Text(gender),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedGender = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      onChanged: _checkPassword,
                      decoration: InputDecoration(
                        labelText: 'Password *',
                        prefixIcon: Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (!_hasMinLength || !_hasUppercase || !_hasLowercase || !_hasDigits || !_hasSpecialCharacters) {
                            return 'Password must meet all requirements';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Column(
                        children: [
                            _buildPasswordRequirement('At least 8 characters', _hasMinLength),
                            _buildPasswordRequirement('At least 1 uppercase letter', _hasUppercase),
                            _buildPasswordRequirement('At least 1 lowercase letter', _hasLowercase),
                            _buildPasswordRequirement('At least 1 number', _hasDigits),
                            _buildPasswordRequirement('At least 1 special character', _hasSpecialCharacters),
                        ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password *',
                        prefixIcon: Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    _AnimatedButton(
                      onPressed: _isLoading ? null : _register,
                      isLoading: _isLoading,
                      child: const Text('Register'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed('/login');
                      },
                      child: const Text('Already have an account? Login'),
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

  Widget _buildPasswordRequirement(String requirement, bool isMet) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: isMet ? 1.0 : 0.0),
      duration: AppAnimations.fast,
      curve: AppAnimations.defaultCurve,
      builder: (context, value, child) {
        return Opacity(
          opacity: 0.5 + (value * 0.5),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: AppAnimations.fast,
                child: Icon(
                  isMet ? Icons.check_circle : Icons.circle_outlined,
                  key: ValueKey(isMet),
                  color: isMet ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodySmall!.color!,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                requirement,
                style: TextStyle(
                  color: isMet
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).textTheme.bodySmall!.color!,
                  fontSize: 12,
                  fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      },
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

