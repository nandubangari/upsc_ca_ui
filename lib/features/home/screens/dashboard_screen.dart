import 'dart:async';
import 'package:upsc_ca_ui/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:upsc_ca_ui/shared/models/dashboard_task.dart';
import 'package:upsc_ca_ui/shared/models/article_model.dart';
import 'package:upsc_ca_ui/shared/widgets/shimmer_task_card.dart';

import 'package:upsc_ca_ui/shared/widgets/section_header.dart';
import 'package:upsc_ca_ui/shared/widgets/task_card.dart';
import 'package:upsc_ca_ui/providers/dashboard_provider.dart';
import 'package:upsc_ca_ui/data/repositories/auth_repository.dart';
import 'package:upsc_ca_ui/data/services/profile_service.dart';
import 'package:upsc_ca_ui/data/services/quote_service.dart';

import 'package:upsc_ca_ui/features/profile/screens/profile_setup_screen.dart';
import 'package:upsc_ca_ui/features/auth/screens/vajiram_login_screen.dart';
import 'package:upsc_ca_ui/core/utils/link_launcher_utils.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with AutomaticKeepAliveClientMixin {
  String? _userName;
  Quote? _quote;
  final ScrollController _scrollController = ScrollController();
  Widget? _cachedUI;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    
    // Defer heavy data loading until after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadPersonalization());
      unawaited(context.read<DashboardProvider>().loadDashboardData());
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPersonalization() async {
    try {
      final profile = await ProfileService().getProfile();
      final quote = await QuoteService().getRandomQuote();
      if (mounted) {
        setState(() {
          _userName = profile?.name ?? AuthRepository().currentUser?.displayName ?? 'Aspirant';
          _quote = quote;
        });
      }
    } catch (e) {
      AppLogger.d('DEBUG: [Dashboard] Error loading personalization: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    
    return VisibilityDetector(
      key: const Key('dashboard-screen'),
      onVisibilityChanged: (info) {
        final provider = context.read<DashboardProvider>();
        provider.setDashboardVisible(info.visibleFraction > 0);
      },
      child: Selector<DashboardProvider, bool>(
        selector: (_, p) => p.isDashboardVisible,
        builder: (context, isVisible, _) {
          // 1. Optimization: Return cached UI if dashboard is not visible
          if (!isVisible && _cachedUI != null) return _cachedUI!;

          // 2. Main Content and Login Side Effects
          return Selector<DashboardProvider, (bool, bool, String?, bool, int, bool)>(
            selector: (_, p) => (p.isLoading, p.isInitialLoading, p.error, p.data != null, p.data?.daysLeft ?? 0, p.needsVajiramLogin),
            builder: (context, state, _) {
              final (isLoading, isInitialLoading, error, hasData, daysLeft, needsLogin) = state;

              // Handle Vajiram Login Side Effect
              if (needsLogin) {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  final provider = context.read<DashboardProvider>();
                  provider.setNeedsVajiramLogin(false); // Reset to avoid loop
                  final cookies = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(builder: (context) => const VajiramLoginScreen()),
                  );
                  if (cookies != null) {
                    AppLogger.d('DEBUG: [Dashboard] Vajiram login successful, initiating retry sync...');
                    unawaited(provider.syncAllArticles(forceRefresh: true, isRetryAfterLogin: true, onlyRecent: false));
                  }
                });
              }

              if (isLoading || isInitialLoading) {
                return _buildLoadingSkeleton(context, daysLeft);
              } else if (error != null) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: $error', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => unawaited(context.read<DashboardProvider>().loadDashboardData()),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              } else if (!hasData) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Scaffold(
                  body: Center(child: Text('No data found', style: TextStyle(color: isDark ? Colors.white : Colors.black87))),
                );
              }

              final ui = Scaffold(
                body: Column(
                  children: [
                    _buildTopBar(context, daysLeft),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 700;
                          return Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1000),
                              child: NotificationListener<ScrollNotification>(
                                onNotification: (notification) {
                                  if (notification is ScrollUpdateNotification) {
                                    if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200) {
                                      context.read<DashboardProvider>().loadMoreMonths();
                                    }
                                  }
                                  return false;
                                },
                                child: CustomScrollView(
                                  controller: _scrollController,
                                  physics: const BouncingScrollPhysics(),
                                  slivers: isWide 
                                      ? _buildWideSlivers(context, context.read<DashboardProvider>()) 
                                      : _buildNarrowSlivers(context, context.read<DashboardProvider>()),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
              _cachedUI = ui;
              return ui;
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton(BuildContext context, int daysLeft) {
    return Scaffold(
      body: Column(
        children: [
          _buildTopBar(context, daysLeft),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                itemCount: 10,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 8, bottom: 12),
                      child: SectionHeader(title: 'LOADING YOUR TASKS...', isLarge: true),
                    );
                  }
                  return const ShimmerTaskCard();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, int daysLeft) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        unawaited(Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
                        ));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 1),
                        ),
                        child: Selector<AuthRepository, String?>(
                          selector: (_, r) => r.currentUser?.photoURL,
                          builder: (context, photoURL, _) {
                            return Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: photoURL != null 
                                      ? ResizeImage.resizeIfNeeded(108, null, NetworkImage(photoURL))
                                      : ResizeImage.resizeIfNeeded(108, null, const NetworkImage('https://api.dicebear.com/7.x/avataaars/png?seed=Nandhu')),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              // Optimized for GPU texture cache
                              clipBehavior: Clip.none,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (_userName != null)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi, ${_userName!.split(' ')[0]}',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            if (_quote != null)
                              Text(
                                _quote!.text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDark ? Colors.white38 : Colors.black38,
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                  height: 1.2,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  Selector<DashboardProvider, (bool, bool)>(
                    selector: (_, p) => (p.isSyncing, p.isDashboardVisible),
                    builder: (context, state, _) {
                      final (isSyncing, isVisible) = state;
                      return IconButton(
                        icon: Icon(
                          isSyncing ? Icons.sync_disabled : Icons.sync,
                          size: 20,
                          color: isSyncing ? Colors.grey : primaryColor,
                        ),
                        onPressed: (isSyncing || !isVisible) 
                            ? null 
                            : () => unawaited(context.read<DashboardProvider>().syncAllArticles(forceRefresh: false, onlyRecent: true)),
                        tooltip: 'Sync Sources',
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _showExamDatePicker(context, context.read<DashboardProvider>()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.timer_outlined, size: 14, color: primaryColor),
                          const SizedBox(width: 6),
                          Text(
                            '$daysLeft DAYS LEFT',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Selector<DashboardProvider, (bool, String?)>(
            selector: (_, p) => (p.isSyncing, p.syncStatus),
            builder: (context, state, _) {
              final (isSyncing, syncStatus) = state;
              if (isSyncing && syncStatus != null) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const RepaintBoundary(
                        child: SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        syncStatus,
                        style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showExamDatePicker(BuildContext context, DashboardProvider provider) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)), // Up to 5 years
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      await provider.updateExamDate(picked);
    }
  }

  List<Widget> _buildNarrowSlivers(BuildContext context, DashboardProvider provider) {
    return [
      Selector<DashboardProvider, Map<String, dynamic>?>(
        selector: (_, p) => p.nextUnreadTaskAndArticle,
        builder: (context, nextUnread, _) {
          if (nextUnread == null) return const SliverToBoxAdapter(child: SizedBox.shrink());
          return SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverToBoxAdapter(
              child: _buildContinueReadingButton(context, nextUnread['task'], nextUnread['article']),
            ),
          );
        },
      ),
      
      Selector<DashboardProvider, List<String>>(
        selector: (_, p) => p.inProgressDateList,
        shouldRebuild: (prev, next) {
          if (prev.length != next.length) return true;
          for (int i = 0; i < prev.length; i++) {
            if (prev[i] != next[i]) return true;
          }
          return false;
        },
        builder: (context, dates, _) {
          if (dates.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
          return SliverMainAxisGroup(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(child: SectionHeader(title: 'In Progress (${dates.length})', isLarge: true)),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverFixedExtentList.builder(
                  itemExtent: 88,
                  itemCount: dates.length,
                  itemBuilder: (context, index) {
                    final date = dates[index];
                    return TaskCard(
                      key: ValueKey('in-progress-$date'),
                      date: date,
                      isFree: index < 2,
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          );
        },
      ),

      Selector<DashboardProvider, List<String>>(
        selector: (_, p) => p.todayDateList,
        shouldRebuild: (prev, next) {
          if (prev.length != next.length) return true;
          for (int i = 0; i < prev.length; i++) {
            if (prev[i] != next[i]) return true;
          }
          return false;
        },
        builder: (context, dates, _) {
          if (dates.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
          return SliverMainAxisGroup(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(child: SectionHeader(title: 'Today\'s Tasks (${dates.length})', isLarge: true)),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverFixedExtentList.builder(
                  itemExtent: 88,
                  itemCount: dates.length,
                  itemBuilder: (context, index) {
                    final date = dates[index];
                    final inProgressCount = provider.inProgressDateList.length;
                    return TaskCard(
                      key: ValueKey('today-$date'),
                      date: date,
                      isFree: (index + inProgressCount) < 2,
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          );
        },
      ),

      Selector<DashboardProvider, List<String>>(
        selector: (_, p) => p.repetitionDateList,
        shouldRebuild: (prev, next) {
          if (prev.length != next.length) return true;
          for (int i = 0; i < prev.length; i++) {
            if (prev[i] != next[i]) return true;
          }
          return false;
        },
        builder: (context, dates, _) {
          if (dates.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
          return SliverMainAxisGroup(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(child: SectionHeader(title: 'Repetition (${dates.length})', isLarge: true)),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverFixedExtentList.builder(
                  itemExtent: 88,
                  itemCount: dates.length,
                  itemBuilder: (context, index) {
                    final date = dates[index];
                    final offset = provider.inProgressDateList.length + provider.todayDateList.length;
                    return TaskCard(
                      key: ValueKey('repetition-$date'),
                      date: date,
                      isFree: (index + offset) < 2,
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          );
        },
      ),

      Selector<DashboardProvider, List<String>>(
        selector: (_, p) => p.notStartedDateList,
        shouldRebuild: (prev, next) {
          if (prev.length != next.length) return true;
          for (int i = 0; i < prev.length; i++) {
            if (prev[i] != next[i]) return true;
          }
          return false;
        },
        builder: (context, dates, _) {
          if (dates.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
          return SliverMainAxisGroup(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(child: SectionHeader(title: 'Not Started (${dates.length})', isLarge: true)),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverFixedExtentList.builder(
                  itemExtent: 88,
                  itemCount: dates.length,
                  itemBuilder: (context, index) {
                    final date = dates[index];
                    final offset = provider.inProgressDateList.length + 
                                   provider.todayDateList.length + 
                                   provider.repetitionDateList.length;
                    return TaskCard(
                      key: ValueKey('not-started-$date'),
                      date: date,
                      isFree: (index + offset) < 2,
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          );
        },
      ),

      Selector<DashboardProvider, (List<String>, int)>(
        selector: (_, p) => (p.completedDateList, p.data?.completedTasks.length ?? 0),
        shouldRebuild: (prev, next) {
          if (prev.$2 != next.$2) return true;
          if (prev.$1.length != next.$1.length) return true;
          for (int i = 0; i < prev.$1.length; i++) {
            if (prev.$1[i] != next.$1[i]) return true;
          }
          return false;
        },
        builder: (context, state, _) {
          final (dates, totalCount) = state;
          if (dates.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
          return SliverMainAxisGroup(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(child: SectionHeader(title: 'Completed History ($totalCount)', isLarge: true)),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList.builder(
                  itemCount: dates.length,
                  itemBuilder: (context, index) {
                    final date = dates[index];
                    final offset = provider.inProgressDateList.length + 
                                   provider.todayDateList.length + 
                                   provider.repetitionDateList.length + 
                                   provider.notStartedDateList.length;
                    return TaskCard(
                      key: ValueKey('completed-$date'),
                      date: date,
                      isFree: (index + offset) < 2,
                    );
                  },
                ),
              ),
              Selector<DashboardProvider, (bool, bool)>(
                selector: (_, p) => (p.isLoadingMore, p.hasMoreCompletedTasks),
                builder: (context, state, _) {
                  final (isLoadingMore, hasMore) = state;
                  if (isLoadingMore) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                    );
                  } else if (hasMore) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: TextButton(
                          onPressed: provider.loadMoreCompletedTasks,
                          child: const Text('SHOW MORE'),
                        ),
                      ),
                    );
                  }
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                },
              ),
            ],
          );
        },
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 40)),
    ];
  }

  List<Widget> _buildWideSlivers(BuildContext context, DashboardProvider provider) {
    return [
      Selector<DashboardProvider, Map<String, dynamic>?>(
        selector: (_, p) => p.nextUnreadTaskAndArticle,
        builder: (context, nextUnread, _) {
          if (nextUnread == null) return const SliverToBoxAdapter(child: SizedBox.shrink());
          return SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            sliver: SliverToBoxAdapter(
              child: _buildContinueReadingButton(context, nextUnread['task'], nextUnread['article']),
            ),
          );
        },
      ),

      Selector<DashboardProvider, List<String>>(
        selector: (_, p) => p.inProgressDateList,
        shouldRebuild: (prev, next) {
          if (prev.length != next.length) return true;
          for (int i = 0; i < prev.length; i++) {
            if (prev[i] != next[i]) return true;
          }
          return false;
        },
        builder: (context, dates, _) {
          if (dates.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
          return SliverMainAxisGroup(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(child: SectionHeader(title: 'In Progress (${dates.length})', isLarge: true)),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 80,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final date = dates[index];
                      return TaskCard(
                        key: ValueKey('wide-in-progress-$date'),
                        date: date,
                        isFree: index < 2,
                      );
                    },
                    childCount: dates.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          );
        },
      ),

      Selector<DashboardProvider, List<String>>(
        selector: (_, p) => p.todayDateList,
        shouldRebuild: (prev, next) {
          if (prev.length != next.length) return true;
          for (int i = 0; i < prev.length; i++) {
            if (prev[i] != next[i]) return true;
          }
          return false;
        },
        builder: (context, dates, _) {
          if (dates.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
          return SliverMainAxisGroup(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(child: SectionHeader(title: 'Today\'s Tasks (${dates.length})', isLarge: true)),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 80,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final date = dates[index];
                      final inProgressCount = provider.inProgressDateList.length;
                      return TaskCard(
                        key: ValueKey('wide-today-$date'),
                        date: date,
                        isFree: (index + inProgressCount) < 2,
                      );
                    },
                    childCount: dates.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          );
        },
      ),

      Selector<DashboardProvider, List<String>>(
        selector: (_, p) => p.repetitionDateList,
        shouldRebuild: (prev, next) {
          if (prev.length != next.length) return true;
          for (int i = 0; i < prev.length; i++) {
            if (prev[i] != next[i]) return true;
          }
          return false;
        },
        builder: (context, dates, _) {
          if (dates.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
          return SliverMainAxisGroup(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(child: SectionHeader(title: 'Repetition (${dates.length})', isLarge: true)),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 80,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final date = dates[index];
                      final offset = provider.inProgressDateList.length + provider.todayDateList.length;
                      return TaskCard(
                        key: ValueKey('wide-repetition-$date'),
                        date: date,
                        isFree: (index + offset) < 2,
                      );
                    },
                    childCount: dates.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          );
        },
      ),

      Selector<DashboardProvider, List<String>>(
        selector: (_, p) => p.notStartedDateList,
        shouldRebuild: (prev, next) {
          if (prev.length != next.length) return true;
          for (int i = 0; i < prev.length; i++) {
            if (prev[i] != next[i]) return true;
          }
          return false;
        },
        builder: (context, dates, _) {
          if (dates.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
          return SliverMainAxisGroup(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(child: SectionHeader(title: 'Not Started (${dates.length})', isLarge: true)),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                sliver: SliverFixedExtentList.builder(
                  itemExtent: 88,
                  itemCount: dates.length,
                  itemBuilder: (context, index) {
                    final date = dates[index];
                    final offset = provider.inProgressDateList.length + 
                                   provider.todayDateList.length + 
                                   provider.repetitionDateList.length;
                    return TaskCard(
                      key: ValueKey('wide-not-started-$date'),
                      date: date,
                      isFree: (index + offset) < 2,
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          );
        },
      ),

      Selector<DashboardProvider, (List<String>, int)>(
        selector: (_, p) => (p.completedDateList, p.data?.completedTasks.length ?? 0),
        shouldRebuild: (prev, next) {
          if (prev.$2 != next.$2) return true;
          if (prev.$1.length != next.$1.length) return true;
          for (int i = 0; i < prev.$1.length; i++) {
            if (prev.$1[i] != next.$1[i]) return true;
          }
          return false;
        },
        builder: (context, state, _) {
          final (dates, totalCount) = state;
          if (dates.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
          return SliverMainAxisGroup(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(child: SectionHeader(title: 'Completed History ($totalCount)', isLarge: true)),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                sliver: SliverList.builder(
                  itemCount: dates.length,
                  itemBuilder: (context, index) {
                    final date = dates[index];
                    final offset = provider.inProgressDateList.length + 
                                   provider.todayDateList.length + 
                                   provider.repetitionDateList.length + 
                                   provider.notStartedDateList.length;
                    return TaskCard(
                      key: ValueKey('wide-completed-$date'),
                      date: date,
                      isFree: (index + offset) < 2,
                    );
                  },
                ),
              ),
              Selector<DashboardProvider, (bool, bool)>(
                selector: (_, p) => (p.isLoadingMore, p.hasMoreCompletedTasks),
                builder: (context, state, _) {
                  final (isLoadingMore, hasMore) = state;
                  if (isLoadingMore) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                    );
                  } else if (hasMore) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: TextButton(
                          onPressed: provider.loadMoreCompletedTasks,
                          child: const Text('SHOW MORE'),
                        ),
                      ),
                    );
                  }
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                },
              ),
            ],
          );
        },
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 40)),
    ];
  }

  Widget _buildContinueReadingButton(BuildContext context, DashboardTask task, ArticleModel article) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final profile = await ProfileService().getProfile();
          final preference = profile?.readingPreference ?? 'internal_browser';
          
          if (context.mounted) {
            await LinkLauncherUtils.launchArticle(
              context: context,
              article: article,
              preference: preference,
              task: task,
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor,
                primaryColor.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            // Removed BoxShadow for GPU performance
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CONTINUE READING',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'FROM ${task.date.toUpperCase()}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
