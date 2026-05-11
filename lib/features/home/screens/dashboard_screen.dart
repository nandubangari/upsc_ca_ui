import 'dart:async';
import 'package:upsc_ca_ui/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:upsc_ca_ui/shared/models/dashboard_data.dart';
import 'package:upsc_ca_ui/shared/models/dashboard_task.dart';
import 'package:upsc_ca_ui/shared/models/article_model.dart';
import 'package:upsc_ca_ui/shared/widgets/gradient_background.dart';




import 'package:upsc_ca_ui/shared/widgets/section_header.dart';
import 'package:upsc_ca_ui/shared/widgets/task_card.dart';
import 'package:upsc_ca_ui/providers/dashboard_provider.dart';
import 'package:upsc_ca_ui/data/repositories/auth_repository.dart';
import 'package:upsc_ca_ui/data/services/profile_service.dart';
import 'package:upsc_ca_ui/data/services/quote_service.dart';

import 'package:upsc_ca_ui/features/reader/screens/article_reader_screen.dart';
import 'package:upsc_ca_ui/features/profile/screens/profile_setup_screen.dart';
import 'package:upsc_ca_ui/features/auth/screens/vajiram_login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _userName;
  Quote? _quote;
  final ScrollController _scrollController = ScrollController();
  Widget? _cachedUI;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    unawaited(_loadPersonalization());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(context.read<DashboardProvider>().loadDashboardData());
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<DashboardProvider>().loadMoreMonths();
    }
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
    return VisibilityDetector(
      key: const Key('dashboard-screen'),
      onVisibilityChanged: (info) {
        final provider = context.read<DashboardProvider>();
        if (info.visibleFraction <= 0) {
          provider.setDashboardVisible(false);
        } else {
          provider.setDashboardVisible(true);
        }
      },
      child: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
        // Optimization: If dashboard is not visible, return the cached UI to avoid expensive list rebuilds
        if (!provider.isDashboardVisible && _cachedUI != null) {
          return _cachedUI!;
        }

        // Handle Vajiram Login Required
        if (provider.needsVajiramLogin) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            provider.setNeedsVajiramLogin(false); // Reset to avoid loop
            final cookies = await Navigator.push<String>(
              context,
              MaterialPageRoute(builder: (context) => const VajiramLoginScreen()),
            );
            if (cookies != null) {
              AppLogger.d('DEBUG: [Dashboard] Vajiram login successful, initiating retry sync...');
              unawaited(provider.syncAllArticles(forceRefresh: true, isRetryAfterLogin: true, onlyRecent: true));
            }
          });
        }

        if (provider.isLoading) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
          );
        } else if (provider.error != null) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => unawaited(provider.loadDashboardData()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        } else if (provider.data == null) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Scaffold(
            body: Center(child: Text('No data found', style: TextStyle(color: isDark ? Colors.white : Colors.black87))),
          );
        }

        final data = provider.data!;
        final ui = GradientBackground(
          child: Column(
            children: [
              _buildTopBar(context, data.daysLeft),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 700;
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: CustomScrollView(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          slivers: isWide 
                              ? _buildWideSlivers(context, data, provider) 
                              : _buildNarrowSlivers(context, data, provider),
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
    ),
    );
  }

  Widget _buildTopBar(BuildContext context, int daysLeft) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final user = AuthRepository().currentUser;
    final provider = context.watch<DashboardProvider>();

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
                        child: CircleAvatar(
                          radius: 18,
                          backgroundImage: user?.photoURL != null 
                              ? NetworkImage(user!.photoURL!)
                              : const NetworkImage('https://api.dicebear.com/7.x/avataaars/png?seed=Nandhu'),
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
                  IconButton(
                    icon: Icon(
                      provider.isSyncing ? Icons.sync_disabled : Icons.sync,
                      size: 20,
                      color: provider.isSyncing ? Colors.grey : primaryColor,
                    ),
                    onPressed: (provider.isSyncing || !provider.isDashboardVisible) 
                        ? null 
                        : () => unawaited(provider.syncAllArticles(forceRefresh: false, onlyRecent: true)),
                    tooltip: 'Sync Sources',
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _showExamDatePicker(context, provider),
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
          if (provider.isSyncing && provider.syncStatus != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    provider.syncStatus!,
                    style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54),
                  ),
                ],
              ),
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

  List<Widget> _buildNarrowSlivers(BuildContext context, DashboardData data, DashboardProvider provider) {
    final nextUnread = provider.nextUnreadTaskAndArticle;
    final visibleCompleted = provider.visibleCompletedTasks;

    return [
      if (nextUnread != null)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverToBoxAdapter(
            child: _buildContinueReadingButton(context, nextUnread['task'], nextUnread['article']),
          ),
        ),
      
      if (data.inProgressTasks.isNotEmpty) ...[
        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(child: SectionHeader(title: 'In Progress', isLarge: true)),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverList.builder(
            itemCount: data.inProgressTasks.length,
            itemBuilder: (context, index) => TaskCard(task: data.inProgressTasks[index]),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],

      if (data.todayTasks.isNotEmpty) ...[
        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(child: SectionHeader(title: 'Today\'s Tasks', isLarge: true)),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverList.builder(
            itemCount: data.todayTasks.length,
            itemBuilder: (context, index) => TaskCard(task: data.todayTasks[index]),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],

      if (data.notStartedTasks.isNotEmpty) ...[
        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(child: SectionHeader(title: 'Not Started', isLarge: true)),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverList.builder(
            itemCount: data.notStartedTasks.length,
            itemBuilder: (context, index) => TaskCard(task: data.notStartedTasks[index]),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],

      if (data.completedTasks.isNotEmpty) ...[
        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(child: SectionHeader(title: 'Completed History', isLarge: true)),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverList.builder(
            itemCount: visibleCompleted.length,
            itemBuilder: (context, index) => TaskCard(task: visibleCompleted[index]),
          ),
        ),
        if (provider.isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          )
        else if (provider.hasMoreCompletedTasks)
          SliverToBoxAdapter(
            child: Center(
              child: TextButton(
                onPressed: provider.loadMoreCompletedTasks,
                child: const Text('SHOW MORE'),
              ),
            ),
          ),
      ],
      const SliverToBoxAdapter(child: SizedBox(height: 40)),
    ];
  }

  List<Widget> _buildWideSlivers(BuildContext context, DashboardData data, DashboardProvider provider) {
    final nextUnread = provider.nextUnreadTaskAndArticle;
    final visibleCompleted = provider.visibleCompletedTasks;

    return [
      if (nextUnread != null)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          sliver: SliverToBoxAdapter(
            child: _buildContinueReadingButton(context, nextUnread['task'], nextUnread['article']),
          ),
        ),

      if (data.inProgressTasks.isNotEmpty) ...[
        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(child: SectionHeader(title: 'In Progress', isLarge: true)),
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
              (context, index) => TaskCard(task: data.inProgressTasks[index]),
              childCount: data.inProgressTasks.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],

      if (data.todayTasks.isNotEmpty) ...[
        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(child: SectionHeader(title: 'Today\'s Tasks', isLarge: true)),
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
              (context, index) => TaskCard(task: data.todayTasks[index]),
              childCount: data.todayTasks.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],

      if (data.notStartedTasks.isNotEmpty) ...[
        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(child: SectionHeader(title: 'Not Started', isLarge: true)),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          sliver: SliverList.builder(
            itemCount: data.notStartedTasks.length,
            itemBuilder: (context, index) => TaskCard(task: data.notStartedTasks[index]),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],

      if (data.completedTasks.isNotEmpty) ...[
        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(child: SectionHeader(title: 'Completed History', isLarge: true)),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          sliver: SliverList.builder(
            itemCount: visibleCompleted.length,
            itemBuilder: (context, index) => TaskCard(task: visibleCompleted[index]),
          ),
        ),
        if (provider.isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          )
        else if (provider.hasMoreCompletedTasks)
          SliverToBoxAdapter(
            child: Center(
              child: TextButton(
                onPressed: provider.loadMoreCompletedTasks,
                child: const Text('SHOW MORE'),
              ),
            ),
          ),
      ],
      const SliverToBoxAdapter(child: SizedBox(height: 40)),
    ];
  }

  Widget _buildContinueReadingButton(BuildContext context, DashboardTask task, ArticleModel article) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          unawaited(Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArticleReaderScreen(
                initialUrl: article.url,
              ),
            ),
          ));
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
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
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
                    Text(
                      'CONTINUE READING',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
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
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
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
