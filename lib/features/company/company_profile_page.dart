import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/company_service.dart';
import '../../services/review_service.dart';
import '../../services/language_service.dart';
import '../../models/company.dart';
import '../../models/review.dart';

class CompanyProfilePage extends ConsumerStatefulWidget {
  final String companyId;

  const CompanyProfilePage({
    super.key,
    required this.companyId,
  });

  @override
  ConsumerState<CompanyProfilePage> createState() => _CompanyProfilePageState();
}

class _CompanyProfilePageState extends ConsumerState<CompanyProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // โหลดข้อมูลบริษัท
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(companyServiceProvider.notifier)
          .loadCompanyById(widget.companyId);
      ref.read(reviewServiceProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companyState = ref.watch(companyServiceProvider);
    final languageState = ref.watch(languageProvider);
    final t =
        (key) => AppLocalizations.translate(key, languageState.languageCode);

    if (companyState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(t('loading'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (companyState.error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(t('error'))),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(companyState.error!),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  ref
                      .read(companyServiceProvider.notifier)
                      .loadCompanyById(widget.companyId);
                },
                child: Text(t('try_again')),
              ),
            ],
          ),
        ),
      );
    }

    final company = companyState.selectedCompany;
    if (company == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t('company_not_found'))),
        body: Center(
          child: Text(t('company_not_found_message')),
        ),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildSliverAppBar(company, t),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(text: t('about')),
                    Tab(text: t('company_jobs')),
                    Tab(text: t('reviews')),
                    Tab(text: t('photos')),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAboutTab(company, t),
            _buildJobsTab(company, t),
            _buildReviewsTab(company, t),
            _buildPhotosTab(company, t),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(Company company, Function t) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60), // Space for app bar
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: company.logo != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  company.logo!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildDefaultLogo(company.name);
                                  },
                                ),
                              )
                            : _buildDefaultLogo(company.name),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              company.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Colors.white.withOpacity(0.9),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  company.province,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildRatingStars(company.rating),
                                const SizedBox(width: 8),
                                Text(
                                  '${company.rating.toStringAsFixed(1)} (${company.reviewCount} ${t('reviews')})',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildStatCard(
                          '${company.employeeCount}+', t('employees_count')),
                      const SizedBox(width: 16),
                      _buildStatCard(
                          '${company.foundedYear.year}', t('founded_year')),
                      const SizedBox(width: 16),
                      _buildStatCard(
                          '${company.industry.length}', t('job_categories')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultLogo(String companyName) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          companyName.isNotEmpty ? companyName[0].toUpperCase() : 'C',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starRating = index + 1;
        if (rating >= starRating) {
          return const Icon(Icons.star, color: Colors.amber, size: 16);
        } else if (rating >= starRating - 0.5) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 16);
        } else {
          return Icon(Icons.star_border,
              color: Colors.white.withOpacity(0.7), size: 16);
        }
      }),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutTab(Company company, Function t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(t('about_company')),
          const SizedBox(height: 12),
          Text(
            company.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          if (company.industry.isNotEmpty) ...[
            _buildSectionTitle(t('job_categories')),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: company.industry.map((industry) {
                return Chip(
                  label: Text(industry),
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
          if (company.benefits.isNotEmpty) ...[
            _buildSectionTitle(t('company_benefits')),
            const SizedBox(height: 12),
            ...company.benefits.map((benefit) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        benefit,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 24),
          ],
          if (company.culture != null) ...[
            _buildSectionTitle(t('company_culture')),
            const SizedBox(height: 12),
            Text(
              company.culture!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
          ],
          _buildSectionTitle('ข้อมูลติดต่อ'),
          const SizedBox(height: 12),
          if (company.address.isNotEmpty)
            _buildContactItem(Icons.location_on, t('address'), company.address),
          if (company.phone != null)
            _buildContactItem(Icons.phone, t('phone'), company.phone!),
          if (company.email != null)
            _buildContactItem(Icons.email, t('email'), company.email!),
          if (company.website != null)
            _buildContactItem(Icons.language, t('website'), company.website!),
        ],
      ),
    );
  }

  Widget _buildJobsTab(Company company, Function t) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'งานจาก ${company.name}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.work_outline,
                    size: 64,
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ยังไม่มีงานจากบริษัทนี้',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'กลับมาดูใหม่ในภายหลัง',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab(Company company, Function t) {
    final reviewState = ref.watch(reviewServiceProvider);
    final companyReviews =
        reviewState.reviews.where((r) => r.companyId == company.id).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${t('reviews')} (${companyReviews.length})',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              FilledButton.icon(
                onPressed: () {
                  // TODO: เปิดหน้าเขียนรีวิว
                },
                icon: const Icon(Icons.edit, size: 18),
                label: Text(t('write_review')),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (companyReviews.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.rate_review_outlined,
                      size: 64,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ยังไม่มีรีวิว',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'เป็นคนแรกที่รีวิวบริษัทนี้',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: companyReviews.length,
                itemBuilder: (context, index) {
                  final review = companyReviews[index];
                  return _buildReviewItem(review);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotosTab(Company company, Function t) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'ยังไม่มีรูปภาพ',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'รูปภาพของบริษัทจะแสดงที่นี่',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(CompanyReview review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Text(
                    review.userName.isNotEmpty ? review.userName[0] : 'U',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            review.userName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          if (review.isVerified) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.verified,
                              size: 16,
                              color: Colors.green,
                            ),
                          ],
                        ],
                      ),
                      Text(
                        review.position,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                ),
                _buildRatingStarsColored(review.rating),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              review.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              review.review,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${review.helpfulCount} คนพบว่ามีประโยชน์',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                ),
                TextButton.icon(
                  onPressed: () {
                    ref
                        .read(reviewServiceProvider.notifier)
                        .markReviewHelpful(review.id);
                  },
                  icon: const Icon(Icons.thumb_up_outlined, size: 16),
                  label: const Text('มีประโยชน์'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingStarsColored(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starRating = index + 1;
        if (rating >= starRating) {
          return const Icon(Icons.star, color: Colors.amber, size: 16);
        } else if (rating >= starRating - 0.5) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 16);
        } else {
          return const Icon(Icons.star_border, color: Colors.grey, size: 16);
        }
      }),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
