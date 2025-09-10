import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:appwrite/appwrite.dart' as appwrite;
import 'package:file_picker/file_picker.dart';
import '../../services/appwrite_service.dart';
import '../../services/file_upload_service.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';
import '../../common/widgets/primary_button.dart';

class SetupCompanyPage extends ConsumerStatefulWidget {
  const SetupCompanyPage({super.key});

  @override
  ConsumerState<SetupCompanyPage> createState() => _SetupCompanyPageState();
}

class _SetupCompanyPageState extends ConsumerState<SetupCompanyPage> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _companyDescriptionController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _websiteController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String _selectedIndustry = 'ເທກໂນໂລຢີສາລະສະໜ່ອງ';
  String _selectedCompanySize = '1-10 ຄົນ';
  String? _companyLogoUrl;
  bool _isUploading = false;
  bool _isLoading = false;
  
  @override
  void dispose() {
    _companyNameController.dispose();
    _companyDescriptionController.dispose();
    _companyAddressController.dispose();
    _websiteController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _uploadCompanyLogo() async {
    try {
      // Open file picker to select file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null) {
        final file = result.files.first;
        
        if (mounted) {
          setState(() {
            _isUploading = true;
          });
        }

        // Create InputFile for Appwrite
        appwrite.InputFile appwriteFile;
        if (file.bytes != null) {
          // For web
          appwriteFile = appwrite.InputFile.fromBytes(
            bytes: file.bytes!,
            filename: file.name,
            contentType: 'image/${file.extension ?? 'jpeg'}',
          );
        } else {
          // For mobile
          appwriteFile = appwrite.InputFile.fromPath(
            path: file.path!,
            filename: file.name,
          );
        }

        // Upload file to Appwrite
        final appwriteService = ref.read(appwriteServiceProvider);
        final fileUploadService = FileUploadService(appwriteService);
        
        final fileUrl = await fileUploadService.uploadCompanyLogo(appwriteFile);
        
        if (mounted) {
          setState(() {
            _companyLogoUrl = fileUrl;
            _isUploading = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ອັບໂຫລດໂລໂກ້ບໍລິສັດສຳເລັດແລ້ວ!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ເກີດຂໍ້ຜິດພາດໃນການອັບໂຫລດ: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _removeCompanyLogo() async {
    if (_companyLogoUrl != null) {
      try {
        // Extract file ID and bucket ID from URL
        final uri = Uri.parse(_companyLogoUrl!);
        final pathSegments = uri.pathSegments;
        final bucketId = pathSegments[pathSegments.length - 3];
        final fileId = pathSegments[pathSegments.length - 2];
        
        // Delete file from Appwrite
        final appwriteService = ref.read(appwriteServiceProvider);
        final fileUploadService = FileUploadService(appwriteService);
        await fileUploadService.deleteFile(bucketId, fileId);
        
        if (mounted) {
          setState(() {
            _companyLogoUrl = null;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ລົບໂລໂກ້ບໍລິສັດສຳເລັດແລ້ວ'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ເກີດຂໍ້ຜິດພາດໃນການລົບໂລໂກ້: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _saveCompanyData() async {
    if (_formKey.currentState!.validate()) {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }
      
      try {
        final authState = ref.read(authProvider);
        if (authState.user == null) {
          throw Exception('User not authenticated');
        }
        
        // Save user data through AuthService
        await ref.read(authProvider.notifier).updateUserProfile(
          companyName: _companyNameController.text,
          companyDescription: _companyDescriptionController.text,
          companyAddress: _companyAddressController.text,
          website: _websiteController.text,
          phone: _phoneController.text,
          industry: _selectedIndustry,
          companySize: _selectedCompanySize,
          companyLogoUrl: _companyLogoUrl,
        );
        
        // Force refresh user data to ensure authState is updated with the new company info
        await ref.read(authProvider.notifier).forceRefreshCurrentUser();
        
        // After saving and refreshing, redirect to employer dashboard
        if (mounted) {
          // Use push instead of go to ensure proper navigation stack
          context.push('/employer/dashboard');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ບັນທຶກຂໍ້ມູນບໍລິສັດສໍາເລັດແລ້ວ'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('ເກີດຂໍ້ຜິດພາດໃນການບັນທຶກ: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ຕັ້ງຄ່າຂໍ້ມູນບໍລິສັດ'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'ຂໍ້ມູນບໍລິສັດ',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ກະລຸນາໃສ່ຂໍ້ມູນບໍລິສັດຂອງທ່ານ',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              
              // Company Logo Section
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.business, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'ໂລໂກ້ບໍລິສັດ',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Column(
                          children: [
                            // Display company logo or placeholder
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade300, width: 2),
                              ),
                              child: _companyLogoUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.network(
                                        _companyLogoUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          // If image fails to load, show icon
                                          return Icon(
                                            Icons.business,
                                            size: 50,
                                            color: Colors.grey.shade500,
                                          );
                                        },
                                      ),
                                    )
                                  : Icon(
                                      Icons.business,
                                      size: 50,
                                      color: Colors.grey.shade500,
                                    ),
                            ),
                            const SizedBox(height: 16),
                            // Upload logo button
                            OutlinedButton.icon(
                              onPressed: _isUploading ? null : _uploadCompanyLogo,
                              icon: _isUploading 
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.upload),
                              label: Text(_isUploading ? 'ກຳລັງອັບໂຫລດ...' : 'ອັບໂຫລດໂລໂກ້'),
                            ),
                            if (_companyLogoUrl != null) ...[
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: _removeCompanyLogo,
                                icon: const Icon(Icons.delete, color: Colors.red),
                                label: const Text(
                                  'ລົບໂລໂກ້',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Basic Information
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'ຂໍ້ມູນພື້ນຖານ',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _companyNameController,
                        decoration: const InputDecoration(
                          labelText: 'ຊື່ບໍລິສັດ',
                          hintText: 'ປ້ອນຊື່ບໍລິສັດ',
                          prefixIcon: Icon(Icons.business_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'ກະລຸນາປ້ອນຊື່ບໍລິສັດ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _companyDescriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'ລາຍລະອຽດບໍລິສັດ',
                          hintText: 'ບັນຫາລາຍລະອຽດກ່ຽວກັບບໍລິສັດ',
                          prefixIcon: Icon(Icons.description_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'ກະລຸນາປ້ອນລາຍລະອຽດບໍລິສັດ';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Contact Information
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.contact_phone, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'ຂໍ້ມູນຕິດຕໍ່',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'ເບີໂທລະສັບ',
                          hintText: '020 12345678',
                          prefixIcon: Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _websiteController,
                        decoration: const InputDecoration(
                          labelText: 'ເວັບໄຊ',
                          hintText: 'https://company.com',
                          prefixIcon: Icon(Icons.language_outlined),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _companyAddressController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'ທີ່ຢູ່',
                          hintText: 'ປ້ອນທີ່ຢູ່ບໍລິສັດ',
                          prefixIcon: Icon(Icons.location_on_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Company Details
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.category, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'ລາຍລະອຽດເພີ່ມເຕີມ',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _selectedIndustry,
                        decoration: const InputDecoration(
                          labelText: 'ປະເພດອຸດສາຫະກໍາ',
                          prefixIcon: Icon(Icons.business_center_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          'ເທກໂນໂລຢີສາລະສະໜ່ອງ',
                          'ການເງິນ',
                          'ການສຶກສາ',
                          'ສາທາລະນະສຸກ',
                          'ການຄ້າ',
                          'ອຸດສາຫະກໍາ',
                          'ບໍລິການ',
                          'ອື່ນໆ',
                        ].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null && mounted) {
                            setState(() {
                              _selectedIndustry = newValue;
                            }
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCompanySize,
                        decoration: const InputDecoration(
                          labelText: 'ຂະໜາດບໍລິສັດ',
                          prefixIcon: Icon(Icons.people_outline),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          '1-10 ຄົນ',
                          '11-50 ຄົນ',
                          '51-200 ຄົນ',
                          '201-500 ຄົນ',
                          '501-1000 ຄົນ',
                          '1000+ ຄົນ',
                        ].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null && mounted) {
                            setState(() {
                              _selectedCompanySize = newValue;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: _isLoading ? 'ກຳລັງບັນທຶກ...' : 'ບັນທຶກຂໍ້ມູນ',
                  onPressed: _isLoading ? null : _saveCompanyData,
                  loading: _isLoading,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}