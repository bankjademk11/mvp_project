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
  static const String _profilePicturesBucketId = 'company_logos';
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
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: widget.isDocument ? FileType.custom : FileType.image,
      allowedExtensions: widget.isDocument ? ['pdf', 'doc', 'docx'] : null,
    );

    if (result == null || result.files.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file selected.')),
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
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
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
        final languageState = ref.read(languageProvider);
        final t = (String key) => AppLocalizations.translate(key, languageState.languageCode);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t('file_uploaded_successfully').replaceFirst('{file}', widget.title)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final languageState = ref.read(languageProvider);
        final t = (String key) => AppLocalizations.translate(key, languageState.languageCode);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t('error_uploading_file')}: $e'),
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

    final uri = Uri.parse(widget.currentFileUrl!);
    final pathSegments = uri.pathSegments;
    if (pathSegments.length < 4) return;
    final bucketId = pathSegments[pathSegments.length - 4];
    final fileId = pathSegments[pathSegments.length - 2];

    final languageState = ref.read(languageProvider);
    final t = (String key) => AppLocalizations.translate(key, languageState.languageCode);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${t('delete')} ${widget.title}'),
        content: Text('${t('delete_confirm_message')} ${widget.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(t('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final appwriteService = ref.read(appwriteServiceProvider);
        final fileUploadService = FileUploadService(appwriteService);
        await fileUploadService.deleteFile(bucketId, fileId);
        widget.onFileUploaded(null);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.title} ${t('deleted_successfully')}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${t('error_deleting_file')}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleView() async {
    final languageState = ref.read(languageProvider);
    final t = (String key) => AppLocalizations.translate(key, languageState.languageCode);
    if (widget.currentFileUrl != null) {
      final uri = Uri.parse(widget.currentFileUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t('could_not_open_file')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageState = ref.watch(languageProvider);
    final t = (String key) => AppLocalizations.translate(key, languageState.languageCode);
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
            color: hasFile ? Colors.green : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(height: 8),
          Text(
            hasFile ? t('file_uploaded').replaceFirst('{file}', widget.title) : t('no_file_uploaded').replaceFirst('{file}', widget.title),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (_isUploading) ...[
            LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: Colors.grey.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${t('uploading')}... ${(_uploadProgress * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ] else if (hasFile) ...[
            // Buttons for when a file exists
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: _handleView,
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text(t('view_file').replaceFirst('{file}', widget.title)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _handleUpload,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: Text(t('replace_file')),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _handleDelete,
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: Text(t('delete')),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          ] else ...[
            // Button for when no file exists
            ElevatedButton.icon(
              onPressed: _handleUpload,
              icon: const Icon(Icons.upload_file),
              label: Text(widget.uploadButtonText),
            )
          ],
        ],
      ),
    );
  }
}