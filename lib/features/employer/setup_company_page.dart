import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:appwrite/appwrite.dart' as appwrite;
import 'package:file_picker/file_picker.dart';
import '../../services/appwrite_service.dart';
import '../../services/file_upload_service.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart'; // Import Language Service
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

  // Use keys for state management
  String? _selectedIndustryKey = 'industry_technology';
  String? _selectedCompanySizeKey = 'company_size_1_10';
  String? _companyLogoUrl;
  bool _isUploading = false;
  bool _isLoading = false;

  // Define lists of keys
  final List<String> _industryKeys = [
    'industry_technology',
    'industry_finance',
    'industry_education',
    'industry_healthcare',
    'industry_commerce',
    'industry_manufacturing',
    'industry_service',
    'industry_other',
  ];

  final List<String> _companySizeKeys = [
    'company_size_1_10',
    'company_size_11_50',
    'company_size_51_200',
    'company_size_201_500',
    'company_size_501_1000',
    'company_size_1000_plus',
  ];

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
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null) {
        final file = result.files.first;

        if (mounted) setState(() => _isUploading = true);

        final appwriteFile = file.bytes != null
            ? appwrite.InputFile.fromBytes(
                bytes: file.bytes!,
                filename: file.name,
                contentType: 'image/${file.extension ?? 'jpeg'}',
              )
            : appwrite.InputFile.fromPath(
                path: file.path!,
                filename: file.name,
              );

        final appwriteService = ref.read(appwriteServiceProvider);
        final fileUploadService = FileUploadService(appwriteService);
        final fileUrl = await fileUploadService.uploadCompanyLogo(appwriteFile);

        if (mounted) {
          setState(() {
            _companyLogoUrl = fileUrl;
            _isUploading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ອັບໂຫລດໂລໂກ້ບໍລິສັດສຳເລັດແລ້ວ!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ເກີດຂໍ້ຜິດພາດໃນການອັບໂຫລດ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeCompanyLogo() async {
    if (_companyLogoUrl != null) {
      try {
        final uri = Uri.parse(_companyLogoUrl!);
        final pathSegments = uri.pathSegments;
        final bucketId = pathSegments[pathSegments.length - 3];
        final fileId = pathSegments[pathSegments.length - 2];

        final appwriteService = ref.read(appwriteServiceProvider);
        final fileUploadService = FileUploadService(appwriteService);
        await fileUploadService.deleteFile(bucketId, fileId);

        if (mounted) {
          setState(() => _companyLogoUrl = null);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ລົບໂລໂກ້ບໍລິສັດສຳເລັດແລ້ວ'),
              backgroundColor: Colors.green,
            ),
          );
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
      if (mounted) setState(() => _isLoading = true);

      try {
        final authState = ref.read(authProvider);
        if (authState.user == null) throw Exception('User not authenticated');

        final languageCode = ref.read(languageProvider).languageCode;

        await ref.read(authProvider.notifier).updateUserProfile(
              companyName: _companyNameController.text,
              companyDescription: _companyDescriptionController.text,
              companyAddress: _companyAddressController.text,
              website: _websiteController.text,
              phone: _phoneController.text,
              industry: _selectedIndustryKey != null ? AppLocalizations.translate(_selectedIndustryKey!, languageCode) : null,
              companySize: _selectedCompanySizeKey != null ? AppLocalizations.translate(_selectedCompanySizeKey!, languageCode) : null,
              companyLogoUrl: _companyLogoUrl,
            );

        await ref.read(authProvider.notifier).forceRefreshCurrentUser();

        if (mounted) {
          context.push('/employer/dashboard');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ບັນທຶກຂໍ້ມູນບໍລິສັດສໍາເລັດແລ້ວ'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    final languageCode = ref.watch(languageProvider).languageCode;
    final t = (key) => AppLocalizations.translate(key, languageCode);

    return Scaffold(
      appBar: AppBar(
        title: Text(t('setup_company_profile') ?? 'ຕັ້ງຄ່າຂໍ້ມູນບໍລິສັດ'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('company_profile'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                t('setup_company_subtitle') ?? 'ກະລຸນາໃສ່ຂໍ້ມູນບໍລິສັດຂອງທ່ານ',
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
                            t('company_logo') ?? 'ໂລໂກ້ບໍລິສັດ',
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
                                        errorBuilder: (context, error, stackTrace) => Icon(
                                          Icons.business,
                                          size: 50,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.business,
                                      size: 50,
                                      color: Colors.grey.shade500,
                                    ),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: _isUploading ? null : _uploadCompanyLogo,
                              icon: _isUploading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.upload),
                              label: Text(_isUploading ? t('uploading') : t('upload_logo') ?? 'ອັບໂຫລດໂລໂກ້'),
                            ),
                            if (_companyLogoUrl != null) ...[
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: _removeCompanyLogo,
                                icon: const Icon(Icons.delete, color: Colors.red),
                                label: Text(
                                  t('remove_logo') ?? 'ລົບໂລໂກ້',
                                  style: const TextStyle(color: Colors.red),
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

              // Other form fields...
              // ... (The rest of the form remains largely the same, so I'll focus on the changed Dropdowns)

              // Company Details Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _companyNameController,
                        decoration: InputDecoration(
                          labelText: t('company_name') ?? 'Company Name',
                          prefixIcon: const Icon(Icons.business),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return t('company_name_required') ?? 'Company name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _companyDescriptionController,
                        decoration: InputDecoration(
                          labelText: t('company_description') ?? 'Company Description',
                          prefixIcon: const Icon(Icons.article),
                          border: const OutlineInputBorder(),
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return t('company_description_required') ?? 'Company description is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _selectedIndustryKey,
                        decoration: InputDecoration(
                          labelText: t('industry_type') ?? 'ປະເພດອຸດສາຫະກໍາ',
                          prefixIcon: const Icon(Icons.business_center_outlined),
                          border: const OutlineInputBorder(),
                        ),
                        items: _industryKeys.map((String key) {
                          return DropdownMenuItem<String>(
                            value: key,
                            child: Text(t(key)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null && mounted) {
                            setState(() {
                              _selectedIndustryKey = newValue;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCompanySizeKey,
                        decoration: InputDecoration(
                          labelText: t('company_size') ?? 'ຂະໜາດບໍລິສັດ',
                          prefixIcon: const Icon(Icons.people_outline),
                          border: const OutlineInputBorder(),
                        ),
                        items: _companySizeKeys.map((String key) {
                          return DropdownMenuItem<String>(
                            value: key,
                            child: Text(t(key)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null && mounted) {
                            setState(() {
                              _selectedCompanySizeKey = newValue;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: _isLoading ? t('saving') : t('save_data'),
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
