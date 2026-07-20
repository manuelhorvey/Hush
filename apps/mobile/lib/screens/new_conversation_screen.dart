import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/conversations_provider.dart';
import '../services/crypto_service.dart';
import '../services/identity_service.dart';
import '../services/messaging_service.dart';

class NewConversationScreen extends StatefulWidget {
  const NewConversationScreen({super.key});

  @override
  State<NewConversationScreen> createState() => _NewConversationScreenState();
}

class _NewConversationScreenState extends State<NewConversationScreen> {
  final _searchController = TextEditingController();

  List<UserInfo> _results = [];
  final Set<String> _selectedIds = {};
  bool _loading = false;
  bool _creating = false;
  String? _token;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _token = context.read<AuthProvider>().token;
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Timer? _debounce;
  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (_searchController.text.trim().isNotEmpty) {
        _search(_searchController.text.trim());
      } else {
        setState(() => _results = []);
      }
    });
  }

  Future<void> _search(String query) async {
    if (_token == null) return;
    setState(() => _loading = true);
    try {
      final messaging = context.read<MessagingService>();
      final users = await messaging.searchUsers(_token!, query);
      if (mounted) setState(() => _results = users);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Search failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createConversation() async {
    if (_token == null || _selectedIds.isEmpty) return;
    setState(() => _creating = true);

    try {
      final crypto = context.read<CryptoService>();
      final identity = context.read<IdentityService>();
      final convs = context.read<ConversationsProvider>();

      final participantIds = _selectedIds.toList();
      final groupKey = crypto.generateGroupKey();

      final encryptedKeys = <String, String>{};
      for (final pid in participantIds) {
        try {
          final pubKey = await identity.getExchangeKey(_token!, pid);
          final encrypted = await crypto.encryptGroupKey(groupKey, pubKey);
          encryptedKeys[pid] = encrypted;
        } catch (_) {}
      }

      final conv = await convs.create(
        _token!,
        participantIds,
        encryptedKeys: encryptedKeys,
      );

      if (!mounted) return;
      context.go(
        '/conversation/${conv.id}',
        extra: conv.participants,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _creating = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Conversation'),
        actions: [
          if (_selectedIds.isNotEmpty)
            TextButton.icon(
              onPressed: _creating ? null : _createConversation,
              icon: _creating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text('Start (${_selectedIds.length})'),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_selectedIds.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                '${_selectedIds.length} user${_selectedIds.length == 1 ? '' : 's'} selected',
                textAlign: TextAlign.center,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by username',
                prefixIcon: Icon(Icons.search),
              ),
              autofocus: true,
            ),
          ),
          if (_loading)
            const LinearProgressIndicator()
          else
            const SizedBox(height: 4),
          Expanded(
            child: _results.isEmpty
                ? const Center(child: Text('Type a username to search'))
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final user = _results[i];
                      final selected = _selectedIds.contains(user.id);
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(user.username[0].toUpperCase()),
                        ),
                        title: Text(user.username),
                        trailing: Icon(
                          selected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color:
                              selected ? Colors.green : Colors.grey,
                        ),
                        onTap: () {
                          setState(() {
                            if (selected) {
                              _selectedIds.remove(user.id);
                            } else {
                              _selectedIds.add(user.id);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
