import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';
import '../utils/responsive.dart';

class AddressFormPage extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const AddressFormPage({super.key, this.initialData});

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _fullNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _flatController = TextEditingController();
  final _areaController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _townCityController = TextEditingController();
  final _deliveryInstructionsController = TextEditingController();

  String _selectedCountry = 'India';
  String _selectedState = 'TELANGANA'; // Default as per screenshot
  bool _isDefault = false;
  double? _latitude;
  double? _longitude;

  final List<String> _countries = ['India'];
  final List<String> _states = [
    'ANDHRA PRADESH', 'ARUNACHAL PRADESH', 'ASSAM', 'BIHAR', 'CHHATTISGARH',
    'GOA', 'GUJARAT', 'HARYANA', 'HIMACHAL PRADESH', 'JHARKHAND', 'KARNATAKA',
    'KERALA', 'MADHYA PRADESH', 'MAHARASHTRA', 'MANIPUR', 'MEGHALAYA', 'MIZORAM',
    'NAGALAND', 'ODISHA', 'PUNJAB', 'RAJASTHAN', 'SIKKIM', 'TAMIL NADU',
    'TELANGANA', 'TRIPURA', 'UTTAR PRADESH', 'UTTARAKHAND', 'WEST BENGAL',
    'DELHI', // UTs
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _initializeFormData(widget.initialData!);
    } else {
        _loadUserData();
    }
  }
  
  Future<void> _loadUserData() async {
      final userId = await StorageService.getUserId();
      if (userId == null) return;
      final result = await ApiService.getProfile(userId);
      if (result['success'] == true && mounted) {
           final user = result['data'];
           if (_fullNameController.text.isEmpty) _fullNameController.text = user.fullName ?? '';
           if (_mobileController.text.isEmpty) _mobileController.text = user.mobileNumber ?? '';
           if (_flatController.text.isEmpty) _flatController.text = user.addressLine ?? '';
           if (_townCityController.text.isEmpty) _townCityController.text = user.city ?? 'Hyderabad';
           if (_pincodeController.text.isEmpty) _pincodeController.text = user.pincode ?? '500014';
      }
  }

  void _initializeFormData(Map<String, dynamic> data) {
    _fullNameController.text = data['full_name'] ?? '';
    _mobileController.text = data['mobile_number'] ?? '';
    _pincodeController.text = data['pincode'] ?? '';
    _flatController.text = data['flat_house_building'] ?? '';
    _areaController.text = data['area_street_sector'] ?? '';
    _landmarkController.text = data['landmark'] ?? '';
    _townCityController.text = data['town_city'] ?? '';
    _deliveryInstructionsController.text = data['delivery_instructions'] ?? '';
    _selectedState = data['state'] ?? 'TELANGANA';
    _isDefault = data['is_default'] ?? false;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _mobileController.dispose();
    _pincodeController.dispose();
    _flatController.dispose();
    _areaController.dispose();
    _landmarkController.dispose();
    _townCityController.dispose();
    _deliveryInstructionsController.dispose();
    super.dispose();
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
            _townCityController.text = placemark.locality ?? placemark.subAdministrativeArea ?? '';
            _areaController.text = placemark.subLocality ?? placemark.thoroughfare ?? '';
            _landmarkController.text = placemark.name ?? '';
            _flatController.clear(); // GPS can't determine flat/building details
            _latitude = position.latitude;
            _longitude = position.longitude;
            
            String? mappedState;
            if (placemark.administrativeArea != null) {
                String adminArea = placemark.administrativeArea!.toUpperCase();
                for (String state in _states) {
                    if (adminArea.contains(state) || state.contains(adminArea)) {
                        mappedState = state;
                        break;
                    }
                }
            }
            if (mappedState != null) {
                _selectedState = mappedState;
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

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final userId = await StorageService.getUserId();
      if (userId == null) return;

      final addressData = {
        'full_name': _fullNameController.text.trim(),
        'mobile_number': _mobileController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'flat_house_building': _flatController.text.trim(),
        'area_street_sector': _areaController.text.trim(),
        'landmark': _landmarkController.text.trim(),
        'town_city': _townCityController.text.trim(),
        'state': _selectedState,
        'country': _selectedCountry,
        'is_default': _isDefault,
        'delivery_instructions': _deliveryInstructionsController.text.trim(),
      };

      if (_latitude != null && _longitude != null) {
        addressData['google_maps_link'] = 'https://www.google.com/maps/search/?api=1&query=$_latitude,$_longitude';
      }

      Map<String, dynamic> result;
      if (widget.initialData != null && widget.initialData!['id'] != null) {
        result = await ApiService.updateUserAddress(userId, widget.initialData!['id'], addressData);
      } else {
        result = await ApiService.addUserAddress(userId, addressData);
      }

      if (mounted) {
        if (result['success'] == true) {
          Navigator.pop(context, result['data']); // Return the created/updated address
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'].toString()), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialData == null ? 'Add a new address' : 'Edit address'),
        backgroundColor: Colors.teal[50], // Light background for app bar
        elevation: 0,
      ),
      body: Responsive.centeredWebContainer(
        context,
        maxWidth: 600,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Edit your delivery address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          onPressed: _getCurrentLocation,
                          icon: const Icon(Icons.my_location, color: Colors.blue),
                          label: const Text('Use Current Location', style: TextStyle(color: Colors.blue)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedCountry,
                      decoration: const InputDecoration(
                        labelText: 'Country/Region',
                        border: OutlineInputBorder(),
                      ),
                      items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => _selectedCountry = v!),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Full name (First and Last name)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Please enter a name' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Mobile number',
                        hintText: '10-digit mobile number without prefixes',
                        border: OutlineInputBorder(),
                      ),
                       inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                      validator: (v) {
                         if (v == null || v.isEmpty) return 'Please enter mobile number';
                         if (v.length != 10) return 'Must be 10 digits';
                         if (!RegExp(r'^[6-9]').hasMatch(v)) return 'Must start with 6-9';
                         return null;
                      },
                    ),
                    const Text('May be used to assist delivery', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 24),


                    TextFormField(
                      controller: _flatController,
                      decoration: const InputDecoration(
                        labelText: 'Flat, House no., Building, Company, Apartment',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _areaController,
                      decoration: const InputDecoration(
                        labelText: 'Area, Street, Sector, Village',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _landmarkController,
                      decoration: const InputDecoration(
                        labelText: 'Landmark',
                        hintText: 'E.g. near apollo hospital',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _pincodeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Pincode',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _townCityController,
                              decoration: const InputDecoration(
                              labelText: 'Town/City',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _selectedState,
                      decoration: const InputDecoration(
                        labelText: 'State',
                        border: OutlineInputBorder(),
                      ),
                      items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) => setState(() => _selectedState = v!),
                    ),
                    const SizedBox(height: 24),


                    
                    ExpansionTile(
                        title: const Text('Delivery instructions (optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Notes, preferences and more'),
                        children: [
                            Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: TextFormField(
                                    controller: _deliveryInstructionsController,
                                    maxLines: 3,
                                    decoration: const InputDecoration(
                                        hintText: 'Provide details such as building description, security info, etc.',
                                        border: OutlineInputBorder(),
                                    ),
                                ),
                            )
                        ],
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveAddress,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.yellow[700], // Amazon-like yellow
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: const Text('Use this address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}
