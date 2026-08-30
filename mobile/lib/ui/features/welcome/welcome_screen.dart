import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:later/l10n/app_localizations.dart';
import 'package:later/ui/app_providers.dart';
import 'package:later/ui/core/theme/later_assets.dart';
import 'package:later/ui/core/theme/later_theme.dart';
import 'package:later/ui/core/widgets/later_mark_pattern.dart';

class OnboardingSlide {
  const OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.tags,
    this.highlightIcon = false,
  });

  final String title;
  final String description;
  final IconData icon;
  final List<String> tags;
  final bool highlightIcon;
}

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<OnboardingSlide> _getSlides(BuildContext context) {
    final l10n = context.l10n;
    return [
      OnboardingSlide(
        title: l10n.get('onboarding1Title'),
        description: l10n.get('onboarding1Desc'),
        icon: Icons.share_rounded,
        tags: const ['TikTok', 'Instagram', 'YouTube', 'Browser'],
      ),
      OnboardingSlide(
        title: l10n.get('onboarding2Title'),
        description: l10n.get('onboarding2Desc'),
        icon: Icons.auto_awesome_rounded,
        tags: const ['Auto Titles', 'Smart Tags', 'Gemini AI'],
        highlightIcon: true,
      ),
      OnboardingSlide(
        title: l10n.get('onboarding3Title'),
        description: l10n.get('onboarding3Desc'),
        icon: Icons.bookmark_added_rounded,
        tags: const ['Offline First', 'Map Pins', 'Collections'],
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext(int slidesCount) {
    if (_currentPage < slidesCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeWelcome();
    }
  }

  void _completeWelcome() {
    ref.read(welcomeSeenProvider.notifier).completeWelcome();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final slides = _getSlides(context);
    final isLastPage = _currentPage == slides.length - 1;
    final l10n = context.l10n;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: LaterMarkPattern()),
          SafeArea(
            child: Column(
              children: [
                // Top Header Bar with Logo and Skip
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SvgPicture.asset(
                        LaterAssets.logowithtext,
                        height: 28,
                        fit: BoxFit.contain,
                        colorFilter: ColorFilter.mode(onSurface, BlendMode.srcIn),
                        semanticsLabel: 'Later Logo',
                      ),
                      TextButton(
                        onPressed: _completeWelcome,
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.secondary,
                          textStyle: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        child: Text(l10n.get('skip')),
                      ),
                    ],
                  ),
                ),

                // Main Onboarding PageView
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemCount: slides.length,
                    itemBuilder: (context, index) {
                      final slide = slides[index];
                      return _buildSlideCard(slide, theme, isDark);
                    },
                  ),
                ),

                // Page Indicator Dots
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(slides.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        height: 8.0,
                        width: isActive ? 24.0 : 8.0,
                        decoration: BoxDecoration(
                          color: isActive
                              ? theme.colorScheme.primary
                              : theme.dividerColor.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      );
                    }),
                  ),
                ),

                // Bottom Action Button (Next / Get Started)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        shape: const RoundedRectangleBorder(borderRadius: LaterTheme.radius),
                      ),
                      onPressed: () => _onNext(slides.length),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLastPage ? l10n.get('getStarted') : l10n.get('next'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isLastPage ? Icons.check_circle_outline_rounded : Icons.arrow_forward_rounded,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlideCard(OnboardingSlide slide, ThemeData theme, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),

                  // Slide Hero Icon Box
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: slide.highlightIcon
                          ? (isDark ? Colors.amber.shade900.withValues(alpha: 0.3) : Colors.amber.shade50)
                          : theme.colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: slide.highlightIcon
                            ? Colors.amber.shade700.withValues(alpha: 0.5)
                            : theme.dividerColor,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (slide.highlightIcon ? Colors.amber : theme.colorScheme.primary)
                              .withValues(alpha: 0.08),
                          blurRadius: 24,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      slide.icon,
                      size: 44,
                      color: slide.highlightIcon ? Colors.amber.shade700 : theme.colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Slide Title
                  Text(
                    slide.title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Slide Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      slide.description,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Feature Badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: slide.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Text(
                          tag,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
