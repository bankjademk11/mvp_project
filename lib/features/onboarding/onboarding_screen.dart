import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<OnboardingData> _pages = [
    OnboardingData(
      imagePath: 'assets/images/onboarding_1.png',
      title: 'ຄົ້ນພົບໂອກາດໃໝ່ໆ',
      description: 'ເລີ່ມຕົ້ນເສັ້ນທາງອາຊີບຂອງທ່ານ\nກັບຕຳແໜ່ງງານຈາກບໍລິສັດຊັ້ນນຳທົ່ວປະເທດ',
    ),
    OnboardingData(
      imagePath: 'assets/images/onboarding_2.png',
      title: 'ຊອກວຽກທີ່ກົງໃຈ',
      description: 'ລະບົບການຄົ້ນຫາອັດສະລິຍະ\nຊ່ວຍໃຫ້ທ່ານພົບວຽກທີ່ກົງກັບຄວາມສາມາດ',
    ),
    OnboardingData(
      imagePath: 'assets/images/onboarding_3.png',
      title: 'ສະໝັກງ່າຍ ພ້ອມເລີ່ມງານ',
      description: 'ສ້າງໂປຣໄຟລ໌ມືອາຊີບ ແລະ ສະໝັກວຽກໄດ້ທັນທີ\nບໍ່ພາດທຸກໂອກາດທີ່ສຳຄັນ',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
      _animationController.reset();
      _animationController.forward();
    });
  }

  void _navigateToNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(_pages[index].imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.2),
                  Colors.transparent,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text(
                      'ຂ້າມ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _pages[_currentPage].title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: [const Shadow(blurRadius: 10, color: Colors.black54)],
                              ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _pages[_currentPage].description,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w400,
                                shadows: [const Shadow(blurRadius: 8, color: Colors.black45)],
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? Colors.white : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _navigateToNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1 ? 'ເລີ່ມຕົ້ນใช้งาน' : 'ຕໍ່ໄປ',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String imagePath;
  final String title;
  final String description;

  OnboardingData({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}
