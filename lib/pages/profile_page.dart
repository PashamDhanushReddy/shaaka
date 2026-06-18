import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../constants/location_data.dart';
import '../theme/app_theme.dart';
import '../services/location_service.dart';
import 'login_page.dart';
import '../widgets/shimmer_widgets.dart';
import '../utils/responsive.dart';

class ProfilePage extends StatefulWidget {
  final bool isCompletingProfile;

  const ProfilePage({
    super.key,
    this.isCompletingProfile = false,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isEditing = false;

  final _fullNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _genderController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();

  String? _selectedGender;
  String? _selectedCountry;
  String? _selectedState;
  double? _latitude;
  double? _longitude;
  final List<String> _genders = ['Male', 'Female', 'Other'];
  XFile? _profileImage;
  Uint8List? _profileImageBytes;
  final ImagePicker _imagePicker = ImagePicker();


  @override
  void initState() {
    super.initState();
    _isEditing = widget.isCompletingProfile;
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _mobileController.dispose();
    _genderController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final userId = await StorageService.getUserId();
    if (userId == null) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
        );
      }
      return;
    }

    final result = await ApiService.getProfile(userId);
    if (result['success'] == true && mounted) {
      setState(() {
        _userProfile = result['data'];
        _populateFields();
        _isLoading = false;
      });
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['error']?['error'] ?? 'Failed to load profile',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _populateFields() {
    if (_userProfile != null) {
      _fullNameController.text = _userProfile!.fullName;
      _mobileController.text = _userProfile!.mobileNumber;
      _selectedGender = _userProfile!.gender;
      _addressController.text = _userProfile!.addressLine ?? '';
      _cityController.text = _userProfile!.city ?? '';
      
      _selectedCountry = _userProfile!.country;
      _selectedState = _userProfile!.state;
        
      if (_selectedCountry != null && !LocationData.countryStateMap.containsKey(_selectedCountry)) {
        _selectedCountry = null;
        _selectedState = null;
      } else if (_selectedCountry != null && _selectedState != null) {
        final states = LocationData.countryStateMap[_selectedCountry];
        if (states != null) {
          bool found = false;
          for (String s in states) {
            if (s.toLowerCase() == _selectedState!.toLowerCase()) {
              _selectedState = s;
              found = true;
              break;
            }
          }
          if (!found) {
            _selectedState = null;
          }
        }
      }
      _pincodeController.text = _userProfile!.pincode ?? '';
      

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
                'Update Profile Photo',
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
          if (_userProfile != null) {
            final updateResult = await ApiService.updateProfile(
              _userProfile!.id!,
              {'profile_pic_url': uploadResult['url']},
            );
            if (updateResult['success'] == true) {
              setState(() {
                _userProfile = updateResult['data'];
                _profileImage = null; // Clear local file after upload
                _profileImageBytes = null;
              });
            }
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile picture updated successfully'),
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

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      final position = await LocationService.getCurrentPosition();
      if (position != null) {
        final placemark = await LocationService.getAddressFromCoordinates(
            position.latitude, position.longitude);
        if (placemark != null) {
          setState(() {
            _pincodeController.text = placemark.postalCode ?? '';
            _cityController.text = placemark.locality ?? placemark.subAdministrativeArea ?? '';
            _addressController.text = [
                placemark.name,
                placemark.thoroughfare,
                placemark.subLocality
            ].where((e) => e != null && e.isNotEmpty).join(', ');
            
            _latitude = position.latitude;
            _longitude = position.longitude;

            _selectedCountry = 'India';

            String? mappedState;
            if (placemark.administrativeArea != null && LocationData.countryStateMap.containsKey(_selectedCountry)) {
                String adminArea = placemark.administrativeArea!.toUpperCase();
                for (String state in LocationData.countryStateMap[_selectedCountry]!) {
                    if (adminArea.contains(state.toUpperCase()) || state.toUpperCase().contains(adminArea)) {
                        mappedState = state;
                        break;
                    }
                }
            }
            if (mappedState != null) {
                _selectedState = mappedState;
            } else {
                _selectedState = null;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location fetched successfully!'), backgroundColor: Colors.green),
          );
        }
      } else {
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not access location. Please check permissions.'), backgroundColor: Colors.red),
          );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }



  Future<void> _updateProfile() async {
    if (_userProfile == null) return;

    setState(() {
      _isLoading = true;
    });

    final userData = {
      'full_name': _fullNameController.text.trim(),
      'gender': _selectedGender,
      'address_line': _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      'city': _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
      'state': _selectedState,
      'country': _selectedCountry,
      'pincode': _pincodeController.text.trim().isEmpty
          ? null
          : _pincodeController.text.trim(),
    };

    if (_latitude != null && _longitude != null) {
        userData['google_maps_link'] = 'https://www.google.com/maps/search/?api=1&query=$_latitude,$_longitude';
    }

    final result = await ApiService.updateProfile(_userProfile!.id!, userData);

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true && mounted) {
      setState(() {
        _userProfile = result['data'];
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      if (widget.isCompletingProfile) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
          (route) => false,
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['error']?['error'] ?? 'Failed to update profile',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showChangePasswordDialog() {
    final _currentPasswordController = TextEditingController();
    final _newPasswordController = TextEditingController();
    final _confirmPasswordController = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    bool _isDialogLoading = false;
    bool _obscureCurrent = true;
    bool _obscureNew = true;
    bool _obscureConfirm = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _currentPasswordController,
                        obscureText: _obscureCurrent,
                        decoration: InputDecoration(
                          labelText: 'Current Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureCurrent ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureCurrent = !_obscureCurrent;
                              });
                            },
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter current password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: _obscureNew,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNew ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureNew = !_obscureNew;
                              });
                            },
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter new password';
                          }
                          
                          final bool hasMinLength = value.length >= 8;
                          final bool hasUppercase = value.contains(RegExp(r'[A-Z]'));
                          final bool hasLowercase = value.contains(RegExp(r'[a-z]'));
                          final bool hasDigits = value.contains(RegExp(r'[0-9]'));
                          final bool hasSpecialCharacters = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

                          if (!hasMinLength) return 'At least 8 Characters are required';
                          if (!hasUppercase) return 'At least 1 Uppercase letter is required';
                          if (!hasLowercase) return 'At least 1 Lowercase letter is required';
                          if (!hasDigits) return 'At least 1 Number is required';
                          if (!hasSpecialCharacters) return 'At least 1 Special character is required';

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirm = !_obscureConfirm;
                              });
                            },
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm new password';
                          }
                          if (value != _newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isDialogLoading
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isDialogLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              _isDialogLoading = true;
                            });

                            final result = await ApiService.changePassword(
                              _userProfile!.id!,
                              _currentPasswordController.text,
                              _newPasswordController.text,
                            );

                            setState(() {
                              _isDialogLoading = false;
                            });

                            if (result['success'] == true) {
                              if (mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Password changed successfully'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      result['error']?['error'] ?? 'Failed to change password',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                  child: _isDialogLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Change'),
                ),
              ],
            );
          },
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    if (_isLoading && _userProfile == null) {
      return const ProfileShimmer();
    }

    if (_userProfile == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        body: const Center(
          child: Text('Failed to load profile'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isCompletingProfile ? 'Complete Profile' : 'Profile'),
        automaticallyImplyLeading: !widget.isCompletingProfile,
        elevation: 0,
        actions: [
          if (!_isEditing)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            )
          else if (!widget.isCompletingProfile)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isLoading ? null : _updateProfile,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(
                          Icons.check,
                          color: Colors.white,
                        ),
                ),
              ),
            ),
        ],
      ),
      body: Responsive.centeredWebContainer(
        context,
        maxWidth: 600,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Added extra bottom padding
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
                            : _userProfile!.profilePicUrl != null
                                ? Image.network(
                                    _userProfile!.profilePicUrl!,
                                    fit: BoxFit.cover,
                                  )
                                : Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Theme.of(context).textTheme.bodyMedium!.color!,
                                  ),
                      ),
                    ),
                    if (_isEditing)
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
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _fullNameController,
                      enabled: _isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _mobileController,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        prefixIcon: Icon(Icons.person_outline),
                        border: const OutlineInputBorder(),
                        filled: !_isEditing,
                        fillColor: !_isEditing ? Colors.grey[200] : null,
                      ),
                      items: _genders.map((String gender) {
                        return DropdownMenuItem<String>(
                          value: gender,
                          child: Text(gender),
                        );
                      }).toList(),
                      onChanged: _isEditing
                          ? (String? newValue) {
                              setState(() {
                                _selectedGender = newValue;
                              });
                            }
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Category: ${_userProfile!.category}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: Text(
                            'Address Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (_isEditing)
                          TextButton.icon(
                            onPressed: _getCurrentLocation,
                            icon: const Icon(Icons.my_location, size: 16, color: Colors.blue),
                            label: const Text('My Location', style: TextStyle(color: Colors.blue, fontSize: 13)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      enabled: _isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        prefixIcon: Icon(Icons.home),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cityController,
                      enabled: _isEditing,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        prefixIcon: Icon(Icons.location_city),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCountry,
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        prefixIcon: Icon(Icons.public),
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      items: LocationData.countryStateMap.keys
                          .map((country) => DropdownMenuItem(
                                value: country,
                                child: Text(country),
                              ))
                          .toList(),
                      onChanged: _isEditing
                          ? (val) {
                              setState(() {
                                _selectedCountry = val;
                                _selectedState = null; // Reset state when country changes
                              });
                            }
                          : null,
                      validator: (value) {
                         if (value == null || value.isEmpty) {
                          return 'Please select a country';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedState,
                      decoration: const InputDecoration(
                        labelText: 'State',
                        prefixIcon: Icon(Icons.map),
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      items: _selectedCountry != null
                          ? LocationData.countryStateMap[_selectedCountry]!
                              .map((state) => DropdownMenuItem(
                                    value: state,
                                    child: Text(state),
                                  ))
                              .toList()
                          : [],
                      onChanged: _isEditing
                          ? (val) {
                              setState(() {
                                _selectedState = val;
                              });
                            }
                          : null,
                        validator: (value) {
                         if (value == null || value.isEmpty) {
                          return 'Please select a state';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pincodeController,
                      enabled: _isEditing,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Pincode',
                        prefixIcon: Icon(Icons.pin),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_isEditing) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
              const SizedBox(height: 8),
              if (!widget.isCompletingProfile)
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _populateFields();
                    });
                  },
                  child: const Text('Cancel'),
                ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: OutlinedButton.icon(
                  onPressed: _showChangePasswordDialog,
                  icon: const Icon(Icons.lock_reset, color: AppTheme.accentTerracotta),
                  label: const Text(
                    'Change Password',
                    style: TextStyle(color: AppTheme.accentTerracotta),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.accentTerracotta),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await StorageService.clearAll();
                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                  icon: Icon(Icons.logout_outlined, color: Theme.of(context).colorScheme.error),
                  label: Text(
                    'Logout',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Theme.of(context).colorScheme.error),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }
}

