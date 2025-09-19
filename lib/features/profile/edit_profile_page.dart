import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart' as appwrite; // Add this import with alias
import 'package:file_picker/file_picker.dart'; // Add this import
import '../../services/auth_service.dart';
import '../../services/file_upload_service.dart';
import '../../common/widgets/primary_button.dart';
import '../../services/language_service.dart';
import '../../services/appwrite_service.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  
  String? _selectedProvince;
  List<String> _selectedSkills = [];
  String? _profilePictureUrl;
  String? _resumeUrl;
  bool _isLoading = false;
  bool _isDataLoaded = false;
  
  final List<String> _provinces = [
    'Vientiane Capital',
    'Luang Prabang',
    'Savannakhet',
    'Champasak',
    'Khammouane',
    'Bolikhamsai',
    'Oudomxay',
    'Bokeo',
    'Phongsaly',
    'Luang Namtha',
    'Xayaboury',
    'Xiangkhouang',
    'Vientiane Province',
    'Borikhamxay',
    'Salavan',
    'Sekong',
    'Attapeu',
  ];
  
  final List<String> _availableSkills = [
    'Flutter', 'React', 'Node.js', 'Python', 'Java', 'JavaScript',
    'Sales', 'Marketing', 'Design', 'Management', 'Leadership',
    'Customer Service', 'Data Analysis', 'Accounting', 'Finance',
    'Project Management', 'Communication', 'Problem Solving',
    'Teamwork', 'Time Management', 'Microsoft Office',
    'Adobe Creative Suite', 'Social Media', 'SEO', 'Content Writing',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    try {
      final user = ref.read(authProvider).user;
      
      if (mounted) {
        setState(() {
          _nameController.text = user?.displayName ?? '';
          _phoneController.text = user?.phone ?? '';
          _bioController.text = user?.bio ?? '';
          // Only set province if it exists in our list
          _selectedProvince = (user?.province != null && _provinces.contains(user?.province)) 
              ? user?.province 
              : null;
          _selectedSkills = user?.skills ?? [];
          _profilePictureUrl = user?.avatarUrl;
          _resumeUrl = user?.resumeUrl;
          _isDataLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        final languageState = ref.read(languageProvider);
        final languageCode = languageState.languageCode;
        final errorLoading = AppLocalizations.translate('error_loading_data', languageCode);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$errorLoading: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    print('เริ่มบันทึกโปรไฟล์...');
    if (!_formKey.currentState!.validate()) {
      print('การตรวจสอบข้อมูลล้มเหลว');
      return;
    }
    
    setState(() {
      _isLoading = true;
      print('เปลี่ยนสถานะเป็นกำลังโหลด...');
    });
    
    try {
      // Get Appwrite service
      final appwriteService = ref.read(appwriteServiceProvider);
      
      // Get current user
      final currentUser = ref.read(authProvider).user;
      if (currentUser == null) {
        print('ไม่พบข้อมูลผู้ใช้');
        throw Exception('User not found');
      }
      
      print('กำลังเตรียมข้อมูลโปรไฟล์...');
      // Prepare profile data
      final profileData = {
        'userId': currentUser.uid, // เพิ่ม userId สำหรับการสร้างเอกสารใหม่
        'phone': _phoneController.text,
        'province': _selectedProvince,
        'skills': _selectedSkills,
        'bio': _bioController.text,
        'avatarUrl': _profilePictureUrl,
        'resumeUrl': _resumeUrl,
      };
      print('ข้อมูลโปรไฟล์: $profileData');
      
                    print('กำลังส่งข้อมูลไปยัง Appwrite...');
                    
                    // Update display name if it has changed
                    if (_nameController.text != currentUser.displayName) {
                      print('กำลังอัปเดตชื่อผู้ใช้...');
                      await ref.read(authProvider.notifier).updateDisplayName(_nameController.text);
                      print('อัปเดตชื่อผู้ใช้สำเร็จ');
                    }
      
                    try {
                      // พยายามอัปเดตเอกสารก่อน
                      await appwriteService.databases.updateDocument(
                        databaseId: '68bbb9e6003188d8686f',
                        collectionId: 'user_profiles',
                        documentId: currentUser.uid,
                        data: profileData,
                      );
                      print('อัปเดตข้อมูลสำเร็จใน Appwrite');
                    } on appwrite.AppwriteException catch (e) {
                      if (e.code == 404) {
                        // ถ้าไม่พบเอกสาร (404) ให้สร้างเอกสารใหม่
                        print('ไม่พบเอกสาร กำลังสร้างเอกสารใหม่...');
                        await appwriteService.databases.createDocument(
                          databaseId: '68bbb9e6003188d8686f',
                          collectionId: 'user_profiles',
                          documentId: currentUser.uid, // ใช้ userId เป็น documentId
                          data: profileData,
                          permissions: [ // เพิ่ม permissions สำหรับเอกสารใหม่
                            appwrite.Permission.read(appwrite.Role.user(currentUser.uid)),
                            appwrite.Permission.update(appwrite.Role.user(currentUser.uid)),
                            appwrite.Permission.delete(appwrite.Role.user(currentUser.uid)),
                          ],
                        );
                        print('สร้างข้อมูลสำเร็จใน Appwrite');
                      } else {
                        // ถ้าเป็น error อื่น ให้ rethrow
                        rethrow;
                      }
                    }
                    
                    // Refresh user data
                    await ref.read(authProvider.notifier).getCurrentUser();
                    print('โหลดข้อมูลผู้ใช้ใหม่แล้ว');      
      if (mounted) {
        print('Widget ยัง mounted อยู่ กำลังอัปเดต UI...');
        setState(() {
          _isLoading = false;
        });
        
        final languageState = ref.read(languageProvider);
        final languageCode = languageState.languageCode;
        final profileSaved = AppLocalizations.translate('profile_saved', languageCode);
        
        print('กำลังแสดง SnackBar...');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(profileSaved),
            backgroundColor: Colors.green,
          ),
        );
        
        print('กำลังปิดหน้าต่าง...');
        Navigator.pop(context);
      } else {
         print('Widget ถูก dispose ไปแล้ว ไม่สามารถอัปเดต UI ได้');
      }
    } catch (e, stackTrace) {
      print('เกิดข้อผิดพลาดในการบันทึกโปรไฟล์: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        final languageState = ref.read(languageProvider);
        final languageCode = languageState.languageCode;
        final error = AppLocalizations.translate('error', languageCode);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadProfilePicture() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result == null || result.files.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image selected.')),
        );
      }
      return;
    }

    PlatformFile pickedFile = result.files.first;
    final file = appwrite.InputFile.fromBytes(
      bytes: pickedFile.bytes!,
      filename: pickedFile.name,
    );

    setState(() {
      _isLoading = true; // Use _isLoading for this operation too
    });

    try {
      final appwriteService = ref.read(appwriteServiceProvider);
      final fileUploadService = FileUploadService(appwriteService);
      String? newImageUrl = await fileUploadService.uploadProfilePicture(file);

      if (newImageUrl != null) {
        // Update local state
        setState(() {
          _profilePictureUrl = newImageUrl;
        });
        // Update user profile in database
        await ref.read(authProvider.notifier).updateUserProfile(avatarUrl: newImageUrl);

        if (mounted) {
          final languageState = ref.read(languageProvider);
          final t = (String key) => AppLocalizations.translate(key, languageState.languageCode);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t('profile_picture_uploaded_successfully')),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final languageState = ref.read(languageProvider);
        final t = (String key) => AppLocalizations.translate(key, languageState.languageCode);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t('error_uploading_profile_picture')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleSkill(String skill) {
    setState(() {
      if (_selectedSkills.contains(skill)) {
        _selectedSkills.remove(skill);
      } else {
        _selectedSkills.add(skill);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageState = ref.watch(languageProvider);
    final languageCode = languageState.languageCode;
    
    // Define translation function
    final t = (String key) => AppLocalizations.translate(key, languageCode);
    
    // Get translations
    final editProfile = t('edit_profile');
    final tapToChange = t('tap_to_change_profile_picture');
    final personalInfo = t('personal_info');
    final fullName = t('full_name');
    final enterFullName = t('enter_full_name');
    final enterFullNameError = t('enter_full_name_error');
    final nameMinLengthError = t('name_min_length_error');
    final phone = t('phone');
    final enterPhoneHint = t('enter_phone_hint');
    final invalidPhoneError = t('invalid_phone_error');
    final province = t('province');
    final about = t('about');
    final introduceYourself = t('introduce_yourself');
    final enterBioHint = t('enter_bio_hint');
    final bioMaxLengthError = t('bio_max_length_error');
    final skills = t('skills');
    final selectSkills = t('select_skills');
    final selectedSkillsText = t('selected_skills');
    final profilePictureAndDocuments = t('profile_picture_and_documents');
    final profilePicture = t('profile_picture');
    final uploadPicture = t('upload_picture');
    final resume = t('resume');
    final uploadCV = t('upload_cv');
    final profileTip = t('profile_tip');
    final saving = t('saving');
    final save = t('save');
    final featureComingSoon = t('feature_coming_soon');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(editProfile),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: !_isDataLoaded
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Profile Picture Section
                    Container(
                      width: double.infinity,
                      color: Colors.white,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              _profilePictureUrl != null && _profilePictureUrl!.isNotEmpty
                                  ? ClipOval(
                                      child: Image.network(
                                        _profilePictureUrl!,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                          ),
                                          child: Center(
                                            child: Text(
                                              _nameController.text.isNotEmpty
                                                  ? _nameController.text.substring(0, 1).toUpperCase()
                                                  : 'U',
                                              style: const TextStyle(
                                                fontSize: 40,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            Theme.of(context).colorScheme.primary,
                                            Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          _nameController.text.isNotEmpty
                                              ? _nameController.text.substring(0, 1).toUpperCase()
                                              : 'U',
                                          style: const TextStyle(
                                            fontSize: 40,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _pickAndUploadProfilePicture,
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tapToChange,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Form Fields
                    _buildFormSection(
                      title: personalInfo,
                      icon: Icons.person_outline,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: fullName,
                            hintText: enterFullName,
                            prefixIcon: const Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return enterFullNameError;
                            }
                            if (value.trim().length < 2) {
                              return nameMinLengthError;
                            }
                            return null;
                          },

                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: phone,
                            hintText: enterPhoneHint,
                            prefixIcon: const Icon(Icons.phone),
                          ),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (value.length < 8) {
                                return invalidPhoneError;
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String?>(
                          value: _selectedProvince,
                          decoration: InputDecoration(
                            labelText: province,
                            hintText: t('select_province'), // ADDED HINT TEXT
                            prefixIcon: const Icon(Icons.location_on),
                          ),
                          items: _provinces.map((province) {
                            return DropdownMenuItem(
                              value: province,
                              child: Text(province),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedProvince = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return t('province_required');
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    
                    // Bio Section
                    _buildFormSection(
                      title: about,
                      icon: Icons.description_outlined,
                      children: [
                        TextFormField(
                          controller: _bioController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: introduceYourself,
                            hintText: enterBioHint,
                            prefixIcon: const Icon(Icons.edit_note),
                            alignLabelWithHint: true,
                          ),
                          validator: (value) {
                            if (value != null && value.length > 500) {
                              return bioMaxLengthError;
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    
                    // Skills Section
                    _buildFormSection(
                      title: skills,
                      icon: Icons.psychology_outlined,
                      children: [
                        Text(
                          selectSkills,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableSkills.map((skill) {
                            final isSelected = _selectedSkills.contains(skill);
                            return FilterChip(
                              label: Text(skill),
                              selected: isSelected,
                              onSelected: (_) => _toggleSkill(skill),
                              selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                              checkmarkColor: Theme.of(context).colorScheme.primary,
                            );
                          }).toList(),
                        ),
                        if (_selectedSkills.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$selectedSkillsText (${_selectedSkills.length}):',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedSkills.join(', '),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    // File Upload Sections
                    _buildFormSection(
                      title: profilePictureAndDocuments,
                      icon: Icons.file_upload_outlined,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: FileUploadWidget(
                                title: resume,
                                currentFileUrl: _resumeUrl,
                                icon: Icons.description_outlined,
                                uploadButtonText: uploadCV,
                                onFileUploaded: (url) {
                                  setState(() {
                                    _resumeUrl = url;
                                  });
                                },
                                isDocument: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  profileTip,
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Save Button
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: PrimaryButton(
                        text: _isLoading ? saving : save,
                        onPressed: _isLoading ? null : _saveProfile,
                        loading: _isLoading,
                        icon: _isLoading ? null : Icons.save,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFormSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}