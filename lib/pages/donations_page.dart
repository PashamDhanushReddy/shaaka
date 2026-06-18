import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../utils/responsive.dart';

class DonationsPage extends StatefulWidget {
  const DonationsPage({super.key});

  @override
  State<DonationsPage> createState() => _DonationsPageState();
}

class _DonationsPageState extends State<DonationsPage> {
  final _formKey = GlobalKey<FormState>();
  String _selectedType = 'Food';
  final List<String> _donationTypes = ['Food', 'Clothes', 'Money', 'Education'];
  bool _isLoading = false;

  final _itemNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _pickupAddressController = TextEditingController(); // Also used for user address
  final _contactNumberController = TextEditingController(); // Also used for user mobile
  final _emailController = TextEditingController();
  final _amountController = TextEditingController();
  final _messageController = TextEditingController();

  final _nameController = TextEditingController();
  final _professionController = TextEditingController();
  final _subjectController = TextEditingController();
  final _durationController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    final userId = await StorageService.getUserId();
    if (userId != null) {
      final result = await ApiService.getProfile(userId);
      if (result['success'] == true && mounted) {
        final profile = result['data'];
        setState(() {
          _contactNumberController.text = profile.mobileNumber ?? '';
        });
      }
    }
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _pickupAddressController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _amountController.dispose();
    _messageController.dispose();
    
    _nameController.dispose();
    _professionController.dispose();
    _subjectController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _selectedImage = image;
    });
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDate = pickedDate;
          _selectedTime = pickedTime;
        });
      }
    }
  }

  Future<void> _submitDonation() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedType != 'Education' && _selectedImage == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload an image')));
       return;
    }

    setState(() => _isLoading = true);

    final userId = await StorageService.getUserId();
    if (userId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to donate')));
        return;
    }

    final Map<String, String> fields = {
      'donation_type': _selectedType,
    };

    if (_selectedType == 'Food' || _selectedType == 'Clothes') {
      fields['item_name'] = _itemNameController.text.trim();
      fields['description'] = _descriptionController.text.trim();
      fields['quantity'] = _quantityController.text.trim();
      fields['pickup_address'] = _pickupAddressController.text.trim();
      fields['contact_number'] = _contactNumberController.text.trim();
      fields['email'] = _emailController.text.trim();
    } else if (_selectedType == 'Education') {
      fields['item_name'] = _nameController.text.trim();
      fields['profession'] = _professionController.text.trim();
      fields['subject'] = _subjectController.text.trim();
      fields['duration'] = _durationController.text.trim();
      fields['contact_number'] = _contactNumberController.text.trim();
      fields['email'] = _emailController.text.trim();
      
      if (_selectedDate != null && _selectedTime != null) {
         final dt = DateTime(
           _selectedDate!.year, 
           _selectedDate!.month, 
           _selectedDate!.day, 
           _selectedTime!.hour, 
           _selectedTime!.minute
         );
         fields['time_slot'] = dt.toIso8601String();
      } else {
         if (!mounted) return;
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a time slot')));
         setState(() => _isLoading = false);
         return;
      }

    } else {
      fields['amount'] = _amountController.text.trim();
      fields['message'] = _messageController.text.trim();
    }

    final result = await ApiService.createDonation(userId, fields, _selectedType == 'Education' ? null : _selectedImage);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Donation successful!'),
          backgroundColor: Colors.green,
        ),
      );
      
      _formKey.currentState?.reset();
      _itemNameController.clear();
      _descriptionController.clear();
      _quantityController.clear();
      _pickupAddressController.clear();
      _contactNumberController.clear();
      _emailController.clear();
      _amountController.clear();
      _messageController.clear();
      _nameController.clear();
      _professionController.clear();
      _subjectController.clear();
      _durationController.clear();
      setState(() {
        _selectedType = 'Food';
        _selectedImage = null;
        _selectedDate = null;
        _selectedTime = null;
      });
    } else {
      dynamic rawError = result['error'];
      if (rawError is Map && rawError.containsKey('error')) {
         rawError = rawError['error'];
      }
      String err = rawError.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donate')),
      body: Responsive.centeredWebContainer(
        context,
        maxWidth: 600,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'I want to donate', border: OutlineInputBorder()),
                items: _donationTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                     setState(() {
                        _selectedType = val;
                        _selectedImage = null; // Reset image on type change
                        _selectedDate = null;
                        _selectedTime = null;
                     });
                  }
                },
              ),
              const SizedBox(height: 24),

              if (_selectedType == 'Food' || _selectedType == 'Clothes') ...[
                 TextFormField(
                   controller: _itemNameController,
                   decoration: const InputDecoration(labelText: 'Item Name * (e.g., Rice, Shirts)', border: OutlineInputBorder()),
                   validator: (v) => v!.isEmpty ? 'Required' : null,
                 ),
                 const SizedBox(height: 16),
                 TextFormField(
                   controller: _quantityController,
                   decoration: const InputDecoration(labelText: 'Quantity * (e.g., 5 kg, 2 bags)', border: OutlineInputBorder()),
                   validator: (v) => v!.isEmpty ? 'Required' : null,
                 ),
                 const SizedBox(height: 16),
                 TextFormField(
                   controller: _descriptionController,
                   decoration: const InputDecoration(labelText: 'Description *', border: OutlineInputBorder()),
                   maxLines: 3,
                   validator: (v) => v!.isEmpty ? 'Required' : null,
                 ),
                 const SizedBox(height: 16),
                 TextFormField(
                   controller: _pickupAddressController,
                   decoration: const InputDecoration(labelText: 'Pickup Address *', border: OutlineInputBorder()),
                   validator: (v) => v!.isEmpty ? 'Required' : null,
                 ),
                 const SizedBox(height: 16),
                  TextFormField(
                   controller: _contactNumberController,
                   decoration: const InputDecoration(labelText: 'Contact Number *', border: OutlineInputBorder()),
                    validator: (v) {
                      if (v!.isEmpty) return 'Required';
                      if (v.length != 10) return 'Must be 10 digits';
                      return null;
                    },
                   keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^[6-9][0-9]*')),
                      LengthLimitingTextInputFormatter(10),
                    ],
                 ),
                 const SizedBox(height: 16),
                 TextFormField(
                   controller: _emailController,
                   decoration: const InputDecoration(labelText: 'Email *', border: OutlineInputBorder()),
                   validator: (v) => v!.isEmpty ? 'Required' : null,
                   keyboardType: TextInputType.emailAddress,
                 ),
                 const SizedBox(height: 16),
                 GestureDetector(
                   onTap: _pickImage,
                   child: Container(
                     height: 150,
                     decoration: BoxDecoration(
                       border: Border.all(color: Colors.grey),
                       borderRadius: BorderRadius.circular(8),
                       color: Colors.grey[100],
                     ),
                     child: _selectedImage != null
                       ? Image.file(File(_selectedImage!.path), fit: BoxFit.cover)
                       : const Column(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                             Text('Add Item Image *', style: TextStyle(color: Colors.grey)),
                           ],
                         ),
                   ),
                 ),

              ] else if (_selectedType == 'Education') ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name *', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _professionController,
                    decoration: const InputDecoration(labelText: 'Profession *', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _subjectController,
                    decoration: const InputDecoration(labelText: 'Subject *', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _selectDateTime(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Time Slot (Calendar) *',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _selectedDate != null && _selectedTime != null
                            ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} at ${_selectedTime!.format(context)}'
                            : 'Select Date & Time',
                        style: TextStyle(
                          color: _selectedDate != null ? Colors.black : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(labelText: 'Duration * (e.g., 1 hour)', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                   TextFormField(
                    controller: _contactNumberController,
                    decoration: const InputDecoration(labelText: 'Contact Number *', border: OutlineInputBorder()),
                    validator: (v) {
                      if (v!.isEmpty) return 'Required';
                      if (v.length != 10) return 'Must be 10 digits';
                      return null;
                    },
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^[6-9][0-9]*')),
                      LengthLimitingTextInputFormatter(10),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email *', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                    keyboardType: TextInputType.emailAddress,
                  ),

              ] else ...[
                 Center(
                   child: Column(
                     children: [
                        const Text('Scan to Pay via UPI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/d/d0/QR_code_for_mobile_English_Wikipedia.svg', // Placeholder QR
                          height: 200,
                          width: 200,
                        ),
                        const SizedBox(height: 5),
                        const Text('UPI ID: shaaka@upi (Example)', style: TextStyle(color: Colors.grey)),
                     ],
                   ),
                 ),
                 const SizedBox(height: 24),
                 TextFormField(
                   controller: _amountController,
                   decoration: const InputDecoration(labelText: 'Amount Paid (₹) *', border: OutlineInputBorder()),
                   validator: (v) => v!.isEmpty ? 'Required' : null,
                   keyboardType: TextInputType.number,
                   inputFormatters: [
                     FilteringTextInputFormatter.allow(RegExp(r'^[1-9][0-9]*')),
                   ],
                 ),
                 const SizedBox(height: 16),
                  TextFormField(
                   controller: _messageController,
                   decoration: const InputDecoration(labelText: 'Message *', border: OutlineInputBorder()),
                   maxLines: 2,
                   validator: (v) => v!.isEmpty ? 'Required' : null,
                 ),
                 const SizedBox(height: 16),
                 const Text('Upload Payment Screenshot *', style: TextStyle(fontWeight: FontWeight.bold)),
                 const SizedBox(height: 8),
                 GestureDetector(
                   onTap: _pickImage,
                   child: Container(
                     height: 150,
                     decoration: BoxDecoration(
                       border: Border.all(color: Colors.grey),
                       borderRadius: BorderRadius.circular(8),
                       color: Colors.grey[100],
                     ),
                     child: _selectedImage != null
                       ? Image.file(File(_selectedImage!.path), fit: BoxFit.cover)
                       : const Column(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             Icon(Icons.upload_file, size: 40, color: Colors.grey),
                             Text('Tap to upload screenshot', style: TextStyle(color: Colors.grey)),
                           ],
                         ),
                   ),
                 ),
              ],

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitDonation,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF5A8A5A),
                  foregroundColor: Colors.white,
                ),
                child: _isLoading 
                   ? const CircularProgressIndicator(color: Colors.white)
                   : const Text('Submit Donation', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
