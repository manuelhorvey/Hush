import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/design_system/theme/theme.dart';
import '../../../../../core/responsive/responsive_layout.dart';
import '../../models/message.dart';
import '../providers/conversation_detail_provider.dart';
import '../widgets/conversation_app_bar.dart';
import '../widgets/conversation_input.dart';
import '../widgets/date_separator.dart';
import '../widgets/message_bubble.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String participantName;
  final bool isVerified;

  const ConversationScreen({
    super.key,
    required this.conversationId,
    required this.participantName,
    this.isVerified = false,
  });

  @override
  ConsumerState<ConversationScreen> createState() =>
      _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref
          .read(conversationDetailProvider.notifier)
          .load(widget.conversationId);
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final success = await ref
        .read(conversationDetailProvider.notifier)
        .sendMessage(widget.conversationId, text);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message queued — will send when back online.')),
      );
    }
    _scrollToBottom();
  }

  Future<void> _completeConversation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete this moment?'),
        content: const Text(
          'This will end this moment. Messages will be preserved until you let it go.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final success = await ref
          .read(conversationDetailProvider.notifier)
          .completeConversation(widget.conversationId);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to complete moment.')),
        );
      }
    }
  }

  Future<void> _destroyConversation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Let this moment go?'),
        content: const Text(
          'This will permanently delete all messages. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            child: const Text('Let Go'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final success = await ref
          .read(conversationDetailProvider.notifier)
          .destroyConversation(widget.conversationId);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to destroy moment.')),
        );
      }
    }
  }

  void _showParticipants() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Participants'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(ctx)
                      .colorScheme
                      .primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    widget.participantName[0].toUpperCase(),
                    style: Theme.of(ctx)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              title: Text(widget.participantName),
              subtitle: const Text('Participant'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(conversationDetailProvider);
    final messages = state.messages;

    // Group messages by date
    final groupedMessages = _groupByDate(messages);

    return Scaffold(
      appBar: ConversationAppBar(
        displayName: widget.participantName,
        isVerified: widget.isVerified,
        isActive: state.isActive,
        lifecycleStatus: state.lifecycleStatus,
        completedAt: state.completedAt,
        onViewProfile: _showParticipants,
        onVerifyIdentity: () => context.push('/verification'),
        onComplete: _completeConversation,
        onSecurityDetails: () => context.push('/security'),
        onDestroy: _destroyConversation,
        onReport: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report submitted')),
          );
        },
      ),
      body: AdaptiveWidth(
        child: Column(
          children: [
            Expanded(
              child: _buildBody(state, groupedMessages, cs),
            ),
            if (state.screenStatus == ConversationScreenStatus.loaded &&
                state.lifecycleStatus == 'completed')
              _buildCompletedBanner(cs)
            else if (state.lifecycleStatus != 'destroyed')
              _buildActionBanner(cs, state.isActive),
            ConversationInput(
              isActive: state.isActive && state.lifecycleStatus != 'destroyed',
              onSend: _sendMessage,
            ),
            if (state.lifecycleStatus == 'destroyed')
              _buildDestroyedBanner(cs),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    ConversationDetailState state,
    List<(String, List<Message>)> groupedMessages,
    ColorScheme cs,
  ) {
    switch (state.screenStatus) {
      case ConversationScreenStatus.loading:
        return _buildLoading(cs);
      case ConversationScreenStatus.error:
        return _buildError(cs);
      case ConversationScreenStatus.loaded:
        if (state.messages.isEmpty) {
          return _buildEmpty(cs);
        }
        return _buildMessageList(groupedMessages, cs);
    }
  }

  Widget _buildLoading(ColorScheme cs) {
    return ListView.builder(
      padding: const EdgeInsets.all(HushSpacing.lg),
      itemCount: 6,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: HushSpacing.md),
        child: Row(
          mainAxisAlignment:
              i.isEven ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 0.6,
              height: 48 + (i % 3) * 16.0,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(HushRadius.lg),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(ColorScheme cs) {
    final state = ref.watch(conversationDetailProvider);
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
              state.error ?? 'Unable to load moment',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: HushSpacing.sm),
            Text(
              'Please try again.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: HushSpacing.xl),
            OutlinedButton.icon(
              onPressed: () => ref
                  .read(conversationDetailProvider.notifier)
                  .load(widget.conversationId),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(HushSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: cs.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: HushSpacing.lg),
            Text(
              'No messages yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: HushSpacing.sm),
            Text(
              'Start your private moment.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedBanner(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HushSpacing.lg,
        vertical: HushSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(width: HushSpacing.sm),
          Expanded(
            child: Text(
              'Moment completed. You can let it go to permanently delete messages.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
            ),
          ),
          const SizedBox(width: HushSpacing.sm),
          Semantics(
            label: 'Let this moment go',
            button: true,
            child: FilledButton.tonalIcon(
              onPressed: _destroyConversation,
              icon: const Icon(Icons.delete_forever_rounded, size: 18),
              label: const Text('Let Go'),
              style: FilledButton.styleFrom(
                foregroundColor: cs.error,
                backgroundColor: cs.errorContainer.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBanner(ColorScheme cs, bool isActive) {
    if (!isActive) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HushSpacing.lg,
        vertical: HushSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Semantics(
            label: 'Complete moment',
            button: true,
            child: TextButton.icon(
              onPressed: _completeConversation,
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text('Complete Moment'),
              style: TextButton.styleFrom(
                foregroundColor: cs.tertiary,
              ),
            ),
          ),
          const SizedBox(width: HushSpacing.sm),
          Semantics(
            label: 'Let this moment go',
            button: true,
            child: TextButton.icon(
              onPressed: _destroyConversation,
              icon: const Icon(Icons.delete_forever_rounded, size: 18),
              label: const Text('Let Go'),
              style: TextButton.styleFrom(
                foregroundColor: cs.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestroyedBanner(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(HushSpacing.lg),
      color: cs.surfaceContainerLowest,
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_forever_rounded,
              size: 16,
              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(width: HushSpacing.sm),
            Text(
              'Moment has been let go.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(
    List<(String, List<Message>)> groupedMessages,
    ColorScheme cs,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(
        top: HushSpacing.md,
        bottom: HushSpacing.lg,
      ),
      itemCount: groupedMessages.length,
      itemBuilder: (context, groupIndex) {
        final (dateLabel, groupMessages) = groupedMessages[groupIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            DateSeparator(label: dateLabel),
            ...groupMessages.map((message) {
              final isMe = message.senderName == 'You';
              debugPrint('[MSG] Rendering: senderName="${message.senderName}" senderId="${message.senderId}" '
                  'isMe=$isMe content="${message.content.length > 30 ? message.content.substring(0, 30) : message.content}"');
              return MessageBubble(
                message: message,
                isMe: isMe,
              );
            }),
          ],
        );
      },
    );
  }

  List<(String, List<Message>)> _groupByDate(List<Message> messages) {
    if (messages.isEmpty) return [];

    final Map<String, List<Message>> grouped = {};
    for (final message in messages) {
      final key = message.dateGroupKey;
      grouped.putIfAbsent(key, () => []).add(message);
    }

    final order = ['Today', 'Yesterday', 'Earlier this week'];
    final result = <(String, List<Message>)>[];
    for (final key in order) {
      if (grouped.containsKey(key)) {
        result.add((messageDateLabel(key), grouped[key]!));
        grouped.remove(key);
      }
    }
    // Add remaining date groups in chronological order
    final remaining = grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    for (final entry in remaining) {
      result.add((entry.key, entry.value));
    }

    return result;
  }

  String messageDateLabel(String key) {
    final dateKeys = {
      'Today': 'Today',
      'Yesterday': 'Yesterday',
      'Earlier this week': 'Earlier this week',
    };
    return dateKeys[key] ?? key;
  }
}
