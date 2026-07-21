import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/components/indicators/empty_section.dart';
import '../../../../core/design_system/theme/theme.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../features/identity/presentation/providers/identity_notifier.dart';
import '../../models/conversation.dart';
import '../providers/conversations_provider.dart';
import '../widgets/conversation_detail_pane.dart';
import '../widgets/conversation_search.dart';
import '../widgets/conversation_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedConversationId;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: HushMotion.normal,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: HushMotion.decelerate,
    );
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conversationsProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  List<Conversation> _filter(List<Conversation> conversations) {
    if (_searchQuery.isEmpty) return conversations;
    final q = _searchQuery.toLowerCase();
    return conversations
        .where((c) => c.displayName.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final conversationsState = ref.watch(conversationsProvider);
    final identity = ref.watch(identityNotifierProvider);
    final status = conversationsState.status;

    final allActive = _filter(conversationsState.activeConversations);
    final allClosed = _filter(conversationsState.closedConversations);
    final allConversations = [...allActive, ...allClosed];

    void onConversationTap(Conversation conversation) {
      context.push('/conversation/${conversation.id}',
          extra: conversation.displayName);
    }

    return Scaffold(
      body: Column(
        children: [
          // Header
          _buildHeader(cs, identity.user?.displayName),

          // Body
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ResponsiveBuilder(
                builder: (context, size) {
                  if (size.isDesktop || size.isTablet) {
                    return _buildDesktopLayout(
                      status, allActive, allClosed, allConversations, cs, size,
                    );
                  }
                  return _buildBody(
                    status, allActive, allClosed, cs, onConversationTap,
                    selectedConversationId: null,
                  );
                },
              ),
            ),
          ),
        ],
      ),

      // Floating action button
      floatingActionButton: Semantics(
        label: 'Start a moment',
        button: true,
        child: FloatingActionButton(
          onPressed: () async {
            await context.push('/new-conversation');
            if (mounted) {
              ref.read(conversationsProvider.notifier).load();
            }
          },
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs, String? displayName) {
    final initial = displayName?.isNotEmpty == true
        ? displayName![0].toUpperCase()
        : '?';

    return Container(
      padding: EdgeInsets.fromLTRB(
        HushSpacing.lg,
        MediaQuery.of(context).padding.top + HushSpacing.md,
        HushSpacing.lg,
        HushSpacing.md,
      ),
      child: Row(
        children: [
          // Hush logo/name
          Semantics(
            label: 'Hush',
            child: Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 22,
                  color: cs.primary,
                ),
                const SizedBox(width: HushSpacing.sm),
                Text(
                  'Hush',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Identity avatar with settings access
          Semantics(
            label: 'Open settings',
            button: true,
            child: GestureDetector(
              onTap: () => context.push('/settings'),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onPrimaryContainer,
                        ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    ConversationsStatus status,
    List<Conversation> active,
    List<Conversation> closed,
    ColorScheme cs,
    void Function(Conversation conversation)? onConversationTap, {
    String? selectedConversationId,
  })
  {
    switch (status) {
      case ConversationsStatus.loading:
        return const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        );

      case ConversationsStatus.error:
        return _buildError(cs);

      case ConversationsStatus.loaded:
      case ConversationsStatus.empty:
        return _buildContent(active, closed, cs, onConversationTap,
            selectedConversationId: selectedConversationId);
    }
  }

  Widget _buildError(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(HushSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: cs.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: HushSpacing.lg),
            Text(
              'Unable to load moments',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: HushSpacing.sm),
            Text(
              'Your moments will resume\nwhen you\'re back online.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: HushSpacing.xl),
            OutlinedButton.icon(
              onPressed: () =>
                  ref.read(conversationsProvider.notifier).load(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    List<Conversation> active,
    List<Conversation> closed,
    ColorScheme cs,
    void Function(Conversation conversation)? onConversationTap, {
    String? selectedConversationId,
  })
  {
    // Show empty state if both lists are empty
    if (active.isEmpty && closed.isEmpty) {
      return _buildEmptyAll(cs);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(conversationsProvider.notifier).load(),
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          HushSpacing.lg,
          0,
          HushSpacing.lg,
          HushSpacing.xxl + 56, // FAB clearance
        ),
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.only(bottom: HushSpacing.lg),
            child: ConversationSearch(
              controller: _searchController,
              onChanged: (v) => setState(() {
                _searchQuery = v;
                _selectedConversationId = null;
              }),
            ),
          ),

          // Active conversations
          if (active.isNotEmpty)
            ConversationSection(
              title: 'Active Moments',
              subtitle: 'Moments that need your attention',
              conversations: active,
              initiallyExpanded: true,
              icon: Icons.chat_bubble_rounded,
              onConversationTap: onConversationTap,
              selectedConversationId: selectedConversationId,
            )
          else ...[
            const HushEmptySection(
              title: 'No active moments.',
              subtitle: 'Start a private moment when you\'re ready.',
            ),
          ],

          if (active.isNotEmpty && (closed.isNotEmpty || _searchQuery.isEmpty))
            const SizedBox(height: HushSpacing.xs),

          // Closed conversations
          if (closed.isNotEmpty)
            ConversationSection(
              title: 'Past Moments',
              subtitle: 'Moments that have ended',
              conversations: closed,
              initiallyExpanded: false,
              icon: Icons.check_circle_outline_rounded,
              onConversationTap: onConversationTap,
              selectedConversationId: selectedConversationId,
            )
          else if (active.isNotEmpty) ...[
            const SizedBox(height: HushSpacing.md),
            const HushEmptySection(
              title: 'No moments yet.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyAll(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(HushSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 56,
              color: cs.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: HushSpacing.lg),
            Text(
              'No moments yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: HushSpacing.sm),
            Text(
              'Start a private moment\nwhen you\'re ready.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: HushSpacing.xl),
            FilledButton.icon(
              onPressed: () async {
                await context.push('/new-conversation');
                if (mounted) {
                  ref.read(conversationsProvider.notifier).load();
                }
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Start a Moment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    ConversationsStatus status,
    List<Conversation> active,
    List<Conversation> closed,
    List<Conversation> allConversations,
    ColorScheme cs,
    ScreenSize size,
  ) {
    final listWidth = size.isDesktop ? 380.0 : 320.0;

    // Find selected conversation
    final selectedConversation = _selectedConversationId != null
        ? allConversations.where((c) => c.id == _selectedConversationId).firstOrNull
        : null;

    // Navigation helper
    void onConversationTap(Conversation conversation) {
      setState(() => _selectedConversationId = conversation.id);
    }

    return Row(
      children: [
        // Conversation list pane (always visible)
        SizedBox(
          width: listWidth,
          child: _buildBody(
                status, active, closed, cs, onConversationTap,
                selectedConversationId: _selectedConversationId,
              ),
        ),

        // Vertical divider
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),

        // Companion pane — shows detail when a conversation is selected
        Expanded(
          child: selectedConversation != null
              ? ConversationDetailPane(
                  conversation: selectedConversation,
                  onDeselect: () =>
                      setState(() => _selectedConversationId = null),
                )
              : _buildEmptyCompanion(cs),
        ),
      ],
    );
  }

  Widget _buildEmptyCompanion(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(HushSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: cs.onSurfaceVariant.withValues(alpha: 0.2),
            ),
            const SizedBox(height: HushSpacing.lg),
            Text(
              'Select a moment',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: HushSpacing.sm),
            Text(
              'Your moments will appear here.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
            ),
          ],
        ),
      ),
    );
  }

}
