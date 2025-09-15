import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/job_service.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';

class PostJobPage extends ConsumerStatefulWidget {
  const PostJobPage({super.key});

  @override
  ConsumerState<PostJobPage> createState() => _PostJobPageState();
}

class _PostJobPageState extends ConsumerState<PostJobPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // State variables
  String? _selectedProvince;
  String? _selectedJobType;

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _salaryMinController = TextEditingController();
  final _salaryMaxController = TextEditingController();
  final _tagsController = TextEditingController();

  // Data for dropdowns (using translation keys)
  final List<String> _jobTypeKeys = [
    'job_type_full_time',
    'job_type_part_time',
    'job_type_contract',
    'job_type_internship',
    'job_type_temporary',
  ];
  final List<String> _provinceKeys = [
    'province_attapue',
    'province_bokeo',
    'province_bolikhamxai',
    'province_champasak',
    'province_houaphanh',
    'province_khammouane',
    'province_luang_namtha',
    'province_luang_prabang',
    'province_oudomxay',
    'province_phongsaly',
    'province_salavan',
    'province_savannakhet',
    'province_sainyabuli',
    'province_sekong',
    'province_vientiane',
    'province_xaisomboun',
    'province_xiangkhouang',
    'vientiane_capital',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _salaryMinController.dispose();
    _salaryMaxController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _descriptionController.clear();
    _salaryMinController.clear();
    _salaryMaxController.clear();
    _tagsController.clear();
    setState(() {
      _selectedProvince = null;
      _selectedJobType = null;
    });
  }

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authState = ref.read(authProvider);
      final jobService = ref.read(JobService.jobServiceProvider);
      final languageCode = ref.read(languageProvider).languageCode;

      await jobService.createJob(
        title: _titleController.text.trim(),
        companyName: authState.user?.companyName ?? authState.user?.displayName ?? '',
        province: _selectedProvince != null ? AppLocalizations.translate(_selectedProvince!, languageCode) : null,
        type: _selectedJobType != null ? AppLocalizations.translate(_selectedJobType!, languageCode) : null,
        description: _descriptionController.text.trim(),
        salaryMin: _salaryMinController.text.isEmpty
            ? null
            : int.tryParse(_salaryMinController.text),
        salaryMax: _salaryMaxController.text.isEmpty
            ? null
            : int.tryParse(_salaryMaxController.text),
        tags: _tagsController.text.isEmpty
            ? []
            : _tagsController.text.split(',').map((tag) => tag.trim()).toList(),
        companyId: authState.user?.uid ?? '',
        teamId: authState.user?.teamId, // Add this
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        final languageState = ref.read(languageProvider);
        final t = (key) => AppLocalizations.translate(key, languageState.languageCode);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('job_posted_successfully')),
            backgroundColor: Colors.green,
          ),
        );

        _clearForm();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        final languageState = ref.read(languageProvider);
        final t = (key) => AppLocalizations.translate(key, languageState.languageCode);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t('error_posting_job')}: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageState = ref.watch(languageProvider);
    final t = (key) => AppLocalizations.translate(key, languageState.languageCode);
    final languageCode = languageState.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('post_new_job')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('job_details'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: t('job_title'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return t('job_title_required');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: t('job_description'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedProvince,
                decoration: InputDecoration(
                  labelText: t('province'),
                  border: const OutlineInputBorder(),
                ),
                items: _provinceKeys.map((String key) {
                  return DropdownMenuItem<String>(
                    value: key,
                    child: Text(AppLocalizations.translate(key, languageCode)),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedProvince = newValue;
                  });
                },
                validator: (value) => value == null ? t('province_required') : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedJobType,
                decoration: InputDecoration(
                  labelText: t('job_type'),
                  border: const OutlineInputBorder(),
                ),
                items: _jobTypeKeys.map((String key) {
                  return DropdownMenuItem<String>(
                    value: key,
                    child: Text(AppLocalizations.translate(key, languageCode)),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedJobType = newValue;
                  });
                },
                validator: (value) => value == null ? t('job_type_required') : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _salaryMinController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: t('salary_min'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _salaryMaxController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: t('salary_max'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tagsController,
                decoration: InputDecoration(
                  labelText: t('tags'),
                  hintText: t('tags_hint'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitJob,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(t('post_job')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}