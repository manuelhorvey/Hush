import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/theme/theme.dart';
import '../providers/conversations_provider.dart';

class NewConversationScreen extends ConsumerStatefulWidget {
  const NewConversationScreen({super.key});

  @override
  ConsumerState<NewConversationScreen> createState() =>
      _NewConversationScreenState();
}

class _NewConversationScreenState
    extends ConsumerState<NewConversationScreen> {
  final _nameController = TextEditingController();
  bool _creating = false;
  bool _hasName = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      final hasName = _nameController.text.trim().isNotEmpty;
      if (hasName != _hasName) {
        setState(() => _hasName = hasName);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createConversation() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _creating = true);

    try {
      final conversation = await ref
          .read(conversationsProvider.notifier)
          .createConversation(
            participantName: name,
            participantId: 'user-${DateTime.now().millisecondsSinceEpoch}',
          );

      if (!mounted) return;
      context.go('/conversation/${conversation.id}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _creating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create moment')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Start a Moment'),
        leading: Semantics(
          label: 'Cancel',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: _creating ? null : () => context.pop(),
          ),
        ),
        actions: [
          if (_hasName)
            Semantics(
              label: 'Start moment',
              button: true,
              child: IconButton(
                icon: _creating
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.onPrimary,
                        ),
                      )
                    : const Icon(Icons.check_rounded),
                onPressed: _creating ? null : _createConversation,
                tooltip: 'Start',
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(HushSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Explanation
            Text(
              'Start a moment.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: HushSpacing.sm),
            Text(
              'Enter the name of the person you want to talk with.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: HushSpacing.xl),

            // Name input
            Semantics(
              label: 'Participant name',
              child: TextField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Sarah',
                  prefixIcon: const Icon(Icons.person_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(HushRadius.md),
                  ),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: _hasName && !_creating
                    ? (_) => _createConversation()
                    : null,
              ),
            ),
            const SizedBox(height: HushSpacing.lg),

            // Privacy note
            Row(
              children: [
                Icon(
                  Icons.lock_rounded,
                  size: 14,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(width: HushSpacing.sm),
                Expanded(
                  child: Text(
                    'Your moment is private. Hush does not store or read your messages.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: HushSpacing.xxl),

            // Create button (full-width, shown when name is entered)
            Semantics(
              label: 'Start moment with $nameText',
              button: true,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _hasName && !_creating
                      ? _createConversation
                      : null,
                  icon: _creating
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimary,
                          ),
                        )
                      : const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    _creating
                        ? 'Creating...'
                        : 'Start a Moment',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get nameText {
    final text = _nameController.text.trim();
    return text.isNotEmpty ? text : 'participant';
  }
}
