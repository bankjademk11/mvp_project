import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../services/language_service.dart';

// Filter state provider
class JobFilters {
  final String? province;
  final String? jobType;
  final RangeValues salaryRange;
  final List<String> selectedSkills;
  final String? experience;
  final String sortBy;

  const JobFilters({
    this.province,
    this.jobType,
    this.salaryRange = const RangeValues(5, 25), // In millions
    this.selectedSkills = const [],
    this.experience,
    this.sortBy = 'latest',
  });

  JobFilters copyWith({
    String? province,
    String? jobType,
    RangeValues? salaryRange,
    List<String>? selectedSkills,
    String? experience,
    String? sortBy,
  }) {
    return JobFilters(
      province: province ?? this.province,
      jobType: jobType ?? this.jobType,
      salaryRange: salaryRange ?? this.salaryRange,
      selectedSkills: selectedSkills ?? this.selectedSkills,
      experience: experience ?? this.experience,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

final jobFiltersProvider = StateProvider<JobFilters>((ref) => const JobFilters());

class JobFiltersPage extends ConsumerStatefulWidget {
  const JobFiltersPage({super.key});

  @override
  ConsumerState<JobFiltersPage> createState() => _JobFiltersPageState();
}

class _JobFiltersPageState extends ConsumerState<JobFiltersPage> {
  late JobFilters _filters;
  
  final _provinces = const [
    'Vientiane Capital',
    'Luang Prabang', 
    'Savannakhet',
    'Champasak',
    'Khammouane',
    'Bolikhamsai',
  ];
  
  final _jobTypes = const [
    'Full-time',
    'Part-time',
    'Contract',
    'Freelance',
    'Internship',
  ];
  
  final _experienceLevels = const [
    'new/no experience',
    '1-2 years',
    '3-5 years',
    '5+ years',
  ];
  
  final _availableSkills = const [
    'Flutter', 'React', 'Node.js', 'Python', 'Java',
    'Sales', 'Marketing', 'Design', 'Management',
    'Customer Service', 'Data Analysis', 'Accounting',
  ];
  
  final _sortOptions = const {
    'latest': 'Latest',
    'salary_high': 'Salary: High-Low',
    'salary_low': 'Salary: Low-High',
    'company': 'Company A-Z',
  };

  @override
  void initState() {
    super.initState();
    _filters = ref.read(jobFiltersProvider);
  }

  String _formatSalary(double value) {
    return '${value.toInt()}M';
  }

  void _resetFilters() {
    setState(() {
      _filters = const JobFilters();
    });
  }

  void _applyFilters() {
    ref.read(jobFiltersProvider.notifier).state = _filters;
    Navigator.pop(context, _filters);
  }

  @override
  Widget build(BuildContext context) {
    final languageState = ref.watch(languageProvider);
    final languageCode = languageState.languageCode;
    
    // Get translations
    final filterTitle = AppLocalizations.translate('filter', languageCode);
    final clearAll = AppLocalizations.translate('clear_all', languageCode);
    final location = AppLocalizations.translate('location', languageCode);
    final selectProvince = AppLocalizations.translate('select_province', languageCode);
    final jobType = AppLocalizations.translate('job_type', languageCode);
    final selectJobType = AppLocalizations.translate('select_job_type', languageCode);
    final salaryRange = AppLocalizations.translate('salary_range', languageCode);
    final laoCurrency = AppLocalizations.translate('lao_currency', languageCode);
    final experienceLevel = AppLocalizations.translate('experience_level', languageCode);
    final selectExperience = AppLocalizations.translate('select_experience', languageCode);
    final requiredSkills = AppLocalizations.translate('requirements', languageCode);
    final sortBy = AppLocalizations.translate('sort_by', languageCode);
    final applyFilters = AppLocalizations.translate('apply_filters', languageCode);
    
    // Experience level translations
    final experienceTranslations = {
      'new/no experience': AppLocalizations.translate('no_experience', languageCode),
      '1-2 years': AppLocalizations.translate('experience_1_2_years', languageCode),
      '3-5 years': AppLocalizations.translate('experience_3_5_years', languageCode),
      '5+ years': AppLocalizations.translate('experience_5_plus_years', languageCode),
    };
    
    // Sort option translations
    final sortOptionTranslations = {
      'latest': AppLocalizations.translate('sort_latest', languageCode),
      'salary_high': AppLocalizations.translate('sort_salary_high_low', languageCode),
      'salary_low': AppLocalizations.translate('sort_salary_low_high', languageCode),
      'company': AppLocalizations.translate('sort_company_az', languageCode),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(filterTitle),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: Text(clearAll),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Location Filter
                _buildFilterSection(
                  title: location,
                  icon: Icons.location_on_outlined,
                  child: DropdownButtonFormField<String>(
                    value: _filters.province,
                    decoration: InputDecoration(
                      hintText: selectProvince,
                      prefixIcon: const Icon(Icons.location_on_outlined),
                    ),
                    items: _provinces.map((province) {
                      return DropdownMenuItem(
                        value: province,
                        child: Text(province),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _filters = _filters.copyWith(province: value);
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),
                
                // Job Type Filter
                _buildFilterSection(
                  title: jobType,
                  icon: Icons.work_outline,
                  child: DropdownButtonFormField<String>(
                    value: _filters.jobType,
                    decoration: InputDecoration(
                      hintText: selectJobType,
                      prefixIcon: const Icon(Icons.work_outline),
                    ),
                    items: _jobTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _filters = _filters.copyWith(jobType: value);
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),
                
                // Salary Range Filter
                _buildFilterSection(
                  title: '$salaryRange ($laoCurrency)',
                  icon: Icons.payments_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RangeSlider(
                        min: 3,
                        max: 50,
                        divisions: 47,
                        values: _filters.salaryRange,
                        labels: RangeLabels(
                          _formatSalary(_filters.salaryRange.start),
                          _formatSalary(_filters.salaryRange.end),
                        ),
                        onChanged: (values) {
                          setState(() {
                            _filters = _filters.copyWith(salaryRange: values);
                          });
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatSalary(_filters.salaryRange.start),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Text(
                            _formatSalary(_filters.salaryRange.end),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Experience Level Filter
                _buildFilterSection(
                  title: experienceLevel,
                  icon: Icons.star_outline,
                  child: DropdownButtonFormField<String>(
                    value: _filters.experience,
                    decoration: InputDecoration(
                      hintText: selectExperience,
                      prefixIcon: const Icon(Icons.star_outline),
                    ),
                    items: _experienceLevels.map((level) {
                      return DropdownMenuItem(
                        value: level,
                        child: Text(experienceTranslations[level] ?? level),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _filters = _filters.copyWith(experience: value);
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),
                
                // Skills Filter
                _buildFilterSection(
                  title: requiredSkills,
                  icon: Icons.psychology_outlined,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableSkills.map((skill) {
                      final isSelected = _filters.selectedSkills.contains(skill);
                      return FilterChip(
                        label: Text(skill),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            final skills = List<String>.from(_filters.selectedSkills);
                            if (selected) {
                              skills.add(skill);
                            } else {
                              skills.remove(skill);
                            }
                            _filters = _filters.copyWith(selectedSkills: skills);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Sort By Filter
                _buildFilterSection(
                  title: sortBy,
                  icon: Icons.sort,
                  child: Column(
                    children: _sortOptions.entries.map((entry) {
                      return RadioListTile<String>(
                        title: Text(sortOptionTranslations[entry.key] ?? entry.value),
                        value: entry.key,
                        groupValue: _filters.sortBy,
                        onChanged: (value) {
                          setState(() {
                            _filters = _filters.copyWith(sortBy: value);
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // Bottom Action Buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetFilters,
                    child: Text(clearAll),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _applyFilters,
                    child: Text(applyFilters),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
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
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}