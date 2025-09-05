import 'package:flutter/material.dart';

// Mock file upload service
class FileUploadService {
  
  static Future<String?> uploadProfilePicture() async {
    await Future.delayed(const Duration(seconds: 2));
    return 'https://example.com/profile/image_${DateTime.now().millisecondsSinceEpoch}.jpg';
  }

  static Future<String?> uploadResume() async {
    await Future.delayed(const Duration(seconds: 3));
    return 'https://example.com/documents/resume_${DateTime.now().millisecondsSinceEpoch}.pdf';
  }

  static Future<void> deleteFile(String fileUrl) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // In real implementation, delete file from server
  }
}

class FileUploadWidget extends StatefulWidget {
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
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  Future<void> _handleUpload() async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });
    
    try {
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          setState(() {
            _uploadProgress = i / 100;
          });
        }
      }
      
      String? fileUrl;
      if (widget.isDocument) {
        fileUrl = await FileUploadService.uploadResume();
      } else {
        fileUrl = await FileUploadService.uploadProfilePicture();
      }
      
      widget.onFileUploaded(fileUrl);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ອັບໂຫລດ${widget.title}ສຳເລັດແລ້ວ!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ເກີດຂໍ້ຜິດພາດໃນການອັບໂຫລດ: $e'),
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
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ລົບ${widget.title}'),
        content: Text('ທ່ານຕ້ອງການລົບ${widget.title}ນີ້ບໍ?'),
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
        await FileUploadService.deleteFile(widget.currentFileUrl!);
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
              content: Text('ເກີດຂໍ້ຜິດພາດໃນການລົບໄຟລ໌: $e'),
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
                ? 'ມີ${widget.title}ແລ້ວ' 
                : 'ຍັງບໍ່ໄດ້ອັບໂຫລດ${widget.title}',
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
              'ກຳລັງອັບໂຫລດ... ${(_uploadProgress * 100).toInt()}%',
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
                      hasFile ? 'ອັບເດດ${widget.title}' : widget.uploadButtonText,
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
                    tooltip: 'ລົບໄຟລ໌',
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