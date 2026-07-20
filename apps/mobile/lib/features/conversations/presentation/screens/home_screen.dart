import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/theme/theme.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../features/identity/presentation/providers/identity_notifier.dart';
import '../../models/conversation.dart';
import '../providers/conversations_provider.dart';
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
    final isDesktop = MediaQuery.of(context).size.shortestSide >= 600;

    // Build the tap handler: desktop selects in pane, mobile navigates
    void onConversationTap(Conversation conversation) {
      if (isDesktop) {
        setState(() => _selectedConversationId = conversation.id);
      } else {
        context.push('/conversation/${conversation.id}');
      }
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
                  return _buildBody(status, allActive, allClosed, cs, onConversationTap);
                },
              ),
            ),
          ),
        ],
      ),

      // Floating action button
      floatingActionButton: Semantics(
        label: 'New conversation',
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
    void Function(Conversation conversation)? onConversationTap,
  ) {
    switch (status) {
      case ConversationsStatus.loading:
        return const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        );

      case ConversationsStatus.error:
        return _buildError(cs);

      case ConversationsStatus.loaded:
      case ConversationsStatus.empty:
        return _buildContent(active, closed, cs, onConversationTap);
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
              'Unable to load conversations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: HushSpacing.sm),
            Text(
              'Your private conversations will resume\nwhen you\'re back online.',
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
    void Function(Conversation conversation)? onConversationTap,
  ) {
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
              title: 'Active',
              subtitle: 'Conversations that need your attention',
              conversations: active,
              initiallyExpanded: true,
              icon: Icons.chat_bubble_rounded,
              onConversationTap: onConversationTap,
            )
          else ...[
            _buildEmptySection(cs, 'No active conversations.',
                'Start a private conversation when you\'re ready.'),
          ],

          if (active.isNotEmpty && (closed.isNotEmpty || _searchQuery.isEmpty))
            const SizedBox(height: HushSpacing.xs),

          // Closed conversations
          if (closed.isNotEmpty)
            ConversationSection(
              title: 'Closed',
              subtitle: 'Completed conversations',
              conversations: closed,
              initiallyExpanded: false,
              icon: Icons.check_circle_outline_rounded,
              onConversationTap: onConversationTap,
            )
          else if (active.isNotEmpty) ...[
            const SizedBox(height: HushSpacing.md),
            _buildEmptySection(cs, 'No completed conversations yet.', null),
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
              'No conversations yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: HushSpacing.sm),
            Text(
              'Start a private conversation\nwhen you\'re ready.',
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
              label: const Text('New Conversation'),
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
          child: _buildBody(status, active, closed, cs, onConversationTap),
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
              ? _buildConversationDetail(selectedConversation, cs)
              : _buildEmptyCompanion(cs),
        ),
      ],
    );
  }

  Widget _buildConversationDetail(Conversation conversation, ColorScheme cs) {
    final custom = HushCustomColors.of(context);
    final isOpen = conversation.lifecycle.isOpen;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(HushSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Close button
          Align(
            alignment: Alignment.topRight,
            child: Semantics(
              label: 'Deselect conversation',
              button: true,
              child: IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                onPressed: () =>
                    setState(() => _selectedConversationId = null),
              ),
            ),
          ),

          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isOpen
                  ? (conversation.isVerified
                      ? custom.success.withValues(alpha: 0.12)
                      : cs.primaryContainer)
                  : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                conversation.firstOtherParticipantName?.isNotEmpty == true
                    ? conversation.firstOtherParticipantName![0].toUpperCase()
                    : '?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isOpen
                          ? (conversation.isVerified
                              ? custom.success
                              : cs.onPrimaryContainer)
                          : cs.onSurfaceVariant,
                    ),
              ),
            ),
          ),
          const SizedBox(height: HushSpacing.lg),

          // Name
          Text(
            conversation.displayName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: HushSpacing.sm),

          // Security status
          Row(
            children: [
              Icon(
                conversation.isVerified
                    ? Icons.verified_rounded
                    : Icons.lock_rounded,
                size: 16,
                color: conversation.isVerified
                    ? custom.success
                    : cs.onSurfaceVariant,
              ),
              const SizedBox(width: HushSpacing.xs),
              Text(
                conversation.isVerified ? 'Verified' : 'Private',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: conversation.isVerified
                          ? custom.success
                          : cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: HushSpacing.md),

          // Lifecycle status
          _DetailRow(
            icon: Icons.circle_rounded,
            iconColor: isOpen ? custom.success : cs.onSurfaceVariant,
            label: conversation.lifecycle.description,
          ),
          const SizedBox(height: HushSpacing.sm),

          // Started
          _DetailRow(
            icon: Icons.schedule_rounded,
            iconColor: cs.onSurfaceVariant,
            label: 'Started ${conversation.relativeTime}',
          ),
          if (conversation.completedAt != null) ...[
            const SizedBox(height: HushSpacing.sm),
            _DetailRow(
              icon: Icons.check_circle_outline_rounded,
              iconColor: cs.onSurfaceVariant,
              label: 'Completed ${conversation.completedRelativeTime}',
            ),
          ],
          const SizedBox(height: HushSpacing.xl),

          // Action buttons
          const Divider(),
          const SizedBox(height: HushSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.push('/conversation/${conversation.id}'),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Text(isOpen ? 'Open Conversation' : 'View Conversation'),
            ),
          ),
        ],
      ),
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
              'Select a conversation',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: HushSpacing.sm),
            Text(
              'Your conversations will appear here.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySection(ColorScheme cs, String title, String? subtitle) {
    return Padding(
      padding: const EdgeInsets.only(
        left: HushSpacing.xs,
        top: HushSpacing.lg,
        bottom: HushSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor.withValues(alpha: 0.7)),
        const SizedBox(width: HushSpacing.sm),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
