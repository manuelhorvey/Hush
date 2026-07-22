import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/theme/theme.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../providers/conversations_provider.dart';

class NewConversationScreen extends ConsumerStatefulWidget {
  const NewConversationScreen({super.key});

  @override
  ConsumerState<NewConversationScreen> createState() =>
      _NewConversationScreenState();
}

class _NewConversationScreenState
    extends ConsumerState<NewConversationScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _creating = false;
  ({String id, String username})? _selectedUser;
  List<({String id, String username})> _searchResults = [];
  bool _searching = false;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _searching = false;
        _showResults = false;
        _selectedUser = null;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      setState(() => _searching = true);
      try {
        final results = await ref
            .read(conversationsProvider.notifier)
            .searchUsers(query);
        if (mounted) {
          setState(() {
            _searchResults = results;
            _searching = false;
            _showResults = true;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _searchResults = [];
            _searching = false;
          });
        }
      }
    });
  }

  void _selectUser(({String id, String username}) user) {
    setState(() {
      _selectedUser = user;
      _searchController.text = user.username;
      _showResults = false;
    });
  }

  Future<void> _createConversation() async {
    if (_selectedUser == null) return;

    setState(() => _creating = true);

    try {
      final conversation = await ref
          .read(conversationsProvider.notifier)
          .createConversation(
            participantIds: [_selectedUser!.id],
          );

      if (!mounted) return;
      context.go(
        '/conversation/${conversation.id}',
        extra: _selectedUser!.username,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _creating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create moment')),
      );
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedUser = null;
      _searchController.clear();
      _searchResults = [];
    });
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
          if (_selectedUser != null)
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
      body: AdaptiveWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
            padding: const EdgeInsets.fromLTRB(
              HushSpacing.lg,
              HushSpacing.lg,
              HushSpacing.lg,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start a moment.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: HushSpacing.sm),
                Text(
                  'Search for the person you want to talk with.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: HushSpacing.xl),

                // Search input with autocomplete
                Semantics(
                  label: 'Search for a participant',
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.none,
                    decoration: InputDecoration(
                      labelText: _selectedUser != null ? 'Participant' : 'Search',
                      hintText: 'Search by name...',
                      prefixIcon: _selectedUser != null
                          ? GestureDetector(
                              onTap: _clearSelection,
                              child: Transform.scale(
                                scale: 0.8,
                                child: Chip(
                                  avatar: CircleAvatar(
                                    backgroundColor: cs.primaryContainer,
                                    child: Text(
                                      _selectedUser!.username[0]
                                          .toUpperCase(),
                                      style: TextStyle(
                                        color: cs.onPrimaryContainer,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  label: Text(
                                    _selectedUser!.username,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  deleteIcon: const Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                  ),
                                  onDeleted: _clearSelection,
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            )
                          : const Icon(Icons.search_rounded),
                      suffixIcon: _searching
                          ? Padding(
                              padding: const EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(HushRadius.md),
                      ),
                    ),
                    textInputAction: TextInputAction.search,
                  ),
                ),
              ],
            ),
          ),

          // Search results dropdown
          if (_showResults && _searchResults.isNotEmpty)
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: HushSpacing.lg,
                  vertical: HushSpacing.sm,
                ),
                itemCount: _searchResults.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  final selected = _selectedUser?.id == user.id;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: selected
                          ? cs.primaryContainer
                          : cs.surfaceContainerHighest,
                      child: Text(
                        user.username[0].toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: selected
                              ? cs.onPrimaryContainer
                              : cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    title: Text(
                      user.username,
                      style: TextStyle(
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    trailing: selected
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: cs.primary,
                            size: 20,
                          )
                        : null,
                    onTap: () => _selectUser(user),
                  );
                },
              ),
            ),

          if (_showResults && _searchResults.isEmpty && !_searching)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_search_rounded,
                      size: 40,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: HushSpacing.md),
                    Text(
                      'No one found',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: HushSpacing.xs),
                    Text(
                      'Try a different name.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
            ),

          if (!_showResults && _selectedUser == null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_search_rounded,
                      size: 48,
                      color: cs.primary.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: HushSpacing.md),
                    Text(
                      'Search for someone to start a moment with.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          // Privacy note + Start button
          if (_selectedUser != null)
            Padding(
              padding: const EdgeInsets.all(HushSpacing.lg),
              child: Column(
                children: [
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
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: cs.onSurfaceVariant
                                    .withValues(alpha: 0.5),
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: HushSpacing.lg),
                  Semantics(
                    label: 'Start moment with ${_selectedUser!.username}',
                    button: true,
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _creating ? null : _createConversation,
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
                              : 'Start Moment',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
