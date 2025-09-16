import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart' as appwrite;
import 'package:appwrite/models.dart' as models;
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import './appwrite_service.dart'; // Import AppwriteService
import '../../services/language_service.dart';
import '../../services/application_service.dart';
import '../../services/notification_service.dart';
import '../../models/application.dart';
import '../../services/auth_service.dart';

class FileUploadService {
  final AppwriteService _appwriteService;
  static const String _profilePicturesBucketId = 'profile_pictures';
  static const String _resumesBucketId = 'company_logos'; // Using the same bucket as company logos to save resources
  static const String _companyLogosBucketId = 'company_logos'; // แยก bucket สำหรับ company logos
  
  FileUploadService(this._appwriteService);
  
  Future<String?> uploadProfilePicture(appwrite.InputFile file) async {
    try {
      final response = await _appwriteService.storage.createFile(
        bucketId: _profilePicturesBucketId,
        fileId: appwrite.ID.unique(),
        file: file,
      );
      
      // Return the file URL
      return 'https://cloud.appwrite.io/v1/storage/buckets/$_profilePicturesBucketId/files/${response.$id}/view?project=68bbb97a003baa58bb9c';
    } on appwrite.AppwriteException catch (e) {
      throw Exception('Failed to upload profile picture: ${e.message}');
    }
  }

  Future<String?> uploadResume(appwrite.InputFile file) async {
    try {
      final response = await _appwriteService.storage.createFile(
        bucketId: _resumesBucketId,
        fileId: appwrite.ID.unique(),
        file: file,
      );
      
      // Return the file URL
      return 'https://cloud.appwrite.io/v1/storage/buckets/$_resumesBucketId/files/${response.$id}/view?project=68bbb97a003baa58bb9c';
    } on appwrite.AppwriteException catch (e) {
      throw Exception('Failed to upload resume: ${e.message}');
    }
  }

  // เพิ่มฟังก์ชันสำหรับอัปโหลดโลโก้บริษัท
  Future<String?> uploadCompanyLogo(appwrite.InputFile file) async {
    try {
      final response = await _appwriteService.storage.createFile(
        bucketId: _companyLogosBucketId,
        fileId: appwrite.ID.unique(),
        file: file,
      );
      
      // Return the file URL
      return 'https://cloud.appwrite.io/v1/storage/buckets/$_companyLogosBucketId/files/${response.$id}/view?project=68bbb97a003baa58bb9c';
    } on appwrite.AppwriteException catch (e) {
      throw Exception('Failed to upload company logo: ${e.message}');
    }
  }

  Future<void> deleteFile(String bucketId, String fileId) async {
    try {
      await _appwriteService.storage.deleteFile(
        bucketId: bucketId,
        fileId: fileId,
      );
    } on appwrite.AppwriteException catch (e) {
      throw Exception('Failed to delete file: ${e.message}');
    }
  }
}

class FileUploadWidget extends ConsumerStatefulWidget {
  final String title;
  final String? currentFileUrl;
  final IconData icon;
  final String uploadButtonText;
  final Function(String?) onFileUploaded;
  final bool isDocument;
  
  const FileUploadWidget({
    super.key,
    required this.title,
    this.currentFileUrl,
    required this.icon,
    required this.uploadButtonText,
    required this.onFileUploaded,
    this.isDocument = false,
  });

  @override
  ConsumerState<FileUploadWidget> createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends ConsumerState<FileUploadWidget> {
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  Future<void> _handleUpload() async {
    // Use file_picker to get the actual file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: widget.isDocument ? FileType.custom : FileType.image, // Custom for documents (like PDF), image for profile pictures
      allowedExtensions: widget.isDocument ? ['pdf', 'doc', 'docx'] : ['jpg', 'jpeg', 'png'], // Specify allowed extensions
    );

    if (result == null || result.files.isEmpty) {
      // User canceled the picker or no file selected
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No file selected.')),
        );
      }
      return;
    }

    // Get the picked file
    PlatformFile pickedFile = result.files.first;

    // Create Appwrite InputFile from bytes for web compatibility
    final file = appwrite.InputFile.fromBytes(
      bytes: pickedFile.bytes!,
      filename: pickedFile.name,
    );

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Get Appwrite service
      final appwriteService = ref.read(appwriteServiceProvider);
      final fileUploadService = FileUploadService(appwriteService);

      String? fileUrl;
      if (widget.isDocument) {
        fileUrl = await fileUploadService.uploadResume(file);
      } else {
        fileUrl = await fileUploadService.uploadProfilePicture(file);
      }

      widget.onFileUploaded(fileUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('อัปโหลด${widget.title}สำเร็จแล้ว!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการอัปโหลด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  Future<void> _handleDelete() async {
    if (widget.currentFileUrl == null) return;
    
    // Extract file ID and bucket ID from URL
    final uri = Uri.parse(widget.currentFileUrl!);
    final pathSegments = uri.pathSegments;
    final bucketId = pathSegments[pathSegments.length - 3];
    final fileId = pathSegments[pathSegments.length - 2]; // Adjust based on actual URL structure
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ลบ${widget.title}'),
        content: Text('ท่านต้องการลบ${widget.title}นี้ບໍ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ຍົກເລີກ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ລົບ'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        // Get Appwrite service
        final appwriteService = ref.read(appwriteServiceProvider);
        final fileUploadService = FileUploadService(appwriteService);
        
        await fileUploadService.deleteFile(bucketId, fileId); // ส่ง bucketId ด้วย
        widget.onFileUploaded(null);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ລົບ${widget.title}ສຳເລັດແລ້ວ'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ເກີດຂໍ້ຜิดພາດໃນການລบໄຟລ໌: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = widget.currentFileUrl != null && widget.currentFileUrl!.isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            hasFile ? Icons.check_circle : widget.icon,
            size: 40,
            color: hasFile 
                ? Colors.green 
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(height: 8),
          Text(
            hasFile 
                ? 'มี${widget.title}ແລ້ວ' 
                : 'ຍັງບໍ່ໄດ້อัปโหลด${widget.title}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          
          if (_isUploading) ...{
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: Colors.grey.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'กําลังอัปโหลด... ${(_uploadProgress * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          } else ...{
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _handleUpload,
                    icon: Icon(hasFile ? Icons.refresh : Icons.upload_file),
                    label: Text(
                      hasFile ? 'อัปเดต${widget.title}' : widget.uploadButtonText,
                    ),
                  ),
                ),
                if (hasFile) ...{
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _handleDelete,
                    icon: const Icon(Icons.delete_outline),
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    tooltip: 'ลบไฟล์',
                  ),
                },
              ],
            ),
          },
        ],
      ),
    );
  }
}