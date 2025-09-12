import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../services/language_service.dart';

// Filter state provider
class JobFilters {
  final String? keyword;
  final String? provinceKey; // Stores the key, e.g., 'province_vientiane'
  final String? jobTypeKey; // Stores the key, e.g., 'job_type_full_time'
  final RangeValues salaryRange;
  final List<String> selectedSkills;
  final String? experience;
  final String sortBy;

  const JobFilters({
    this.keyword,
    this.provinceKey,
    this.jobTypeKey,
    this.salaryRange = const RangeValues(3, 50), // In millions
    this.selectedSkills = const [],
    this.experience,
    this.sortBy = 'latest',
  });

  JobFilters copyWith({
    String? keyword,
    String? provinceKey,
    String? jobTypeKey,
    RangeValues? salaryRange,
    List<String>? selectedSkills,
    String? experience,
    String? sortBy,
  }) {
    return JobFilters(
      keyword: keyword ?? this.keyword,
      provinceKey: provinceKey ?? this.provinceKey,
      jobTypeKey: jobTypeKey ?? this.jobTypeKey,
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

  // Keys from language_service.dart
  final _provinceKeys = const [
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

  final _jobTypeKeys = const [
    'job_type_full_time',
    'job_type_part_time',
    'job_type_contract',
    'job_type_internship',
    'job_type_temporary',
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
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final languageState = ref.watch(languageProvider);
    final t = (key) => AppLocalizations.translate(key, languageState.languageCode);

    // Experience level translations
    final experienceTranslations = {
      'new/no experience': t('no_experience'),
      '1-2 years': t('experience_1_2_years'),
      '3-5 years': t('experience_3_5_years'),
      '5+ years': t('experience_5_plus_years'),
    };

    // Sort option translations
    final sortOptionTranslations = {
      'latest': t('sort_latest'),
      'salary_high': t('sort_salary_high_low'),
      'salary_low': t('sort_salary_low_high'),
      'company': t('sort_company_az'),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(t('filter')),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: Text(t('clear_all')),
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
                  title: t('location'),
                  icon: Icons.location_on_outlined,
                  child: DropdownButtonFormField<String>(
                    value: _filters.provinceKey,
                    decoration: InputDecoration(
                      hintText: t('select_province'),
                      prefixIcon: const Icon(Icons.location_on_outlined),
                    ),
                    items: _provinceKeys.map((key) {
                      return DropdownMenuItem(
                        value: key,
                        child: Text(t(key)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _filters = _filters.copyWith(provinceKey: value);
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Job Type Filter
                _buildFilterSection(
                  title: t('job_type'),
                  icon: Icons.work_outline,
                  child: DropdownButtonFormField<String>(
                    value: _filters.jobTypeKey,
                    decoration: InputDecoration(
                      hintText: t('select_job_type'),
                      prefixIcon: const Icon(Icons.work_outline),
                    ),
                    items: _jobTypeKeys.map((key) {
                      return DropdownMenuItem(
                        value: key,
                        child: Text(t(key)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _filters = _filters.copyWith(jobTypeKey: value);
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Salary Range Filter
                _buildFilterSection(
                  title: '${t('salary_range')} (${t('lao_currency')})',
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
                  title: t('experience_level'),
                  icon: Icons.star_outline,
                  child: DropdownButtonFormField<String>(
                    value: _filters.experience,
                    decoration: InputDecoration(
                      hintText: t('select_experience'),
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
                  title: t('requirements'),
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
                  title: t('sort_by'),
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
                    child: Text(t('clear_all')),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _applyFilters,
                    child: Text(t('apply_filters')),
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
