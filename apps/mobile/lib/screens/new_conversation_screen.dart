import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/crypto_service.dart';
import '../services/identity_service.dart';
import '../services/messaging_service.dart';
import 'chat_screen.dart';

class NewConversationScreen extends StatefulWidget {
  const NewConversationScreen({super.key});

  @override
  State<NewConversationScreen> createState() => _NewConversationScreenState();
}

class _NewConversationScreenState extends State<NewConversationScreen> {
  final _searchController = TextEditingController();
  final _messaging = MessagingService(
    api: ApiClient(baseUrl: 'http://$apiHost:8083'),
  );
  final _identity = IdentityService(
    api: ApiClient(baseUrl: 'http://$apiHost:8082'),
  );
  final _crypto = CryptoService();

  List<UserInfo> _results = [];
  final Set<String> _selectedIds = {};
  bool _loading = false;
  bool _creating = false;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadToken();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadToken() async {
    final auth = AuthService(
      api: ApiClient(baseUrl: 'http://$apiHost:8081'),
    );
    final session = await auth.getSession();
    if (mounted) setState(() => _token = session?.token);
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
      final users = await _messaging.searchUsers(_token!, query);
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
      final participantIds = _selectedIds.toList();

      final groupKey = _crypto.generateGroupKey();

      final encryptedKeys = <String, String>{};
      for (final pid in participantIds) {
        try {
          final pubKey = await _identity.getExchangeKey(_token!, pid);
          final encrypted =
              await _crypto.encryptGroupKey(groupKey, pubKey);
          encryptedKeys[pid] = encrypted;
        } catch (_) {}
      }

      final conv = await _messaging.createConversation(
        _token!,
        participantIds,
        encryptedKeys: encryptedKeys,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conv.id,
            participants: conv.participants,
          ),
        ),
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
              decoration: InputDecoration(
                labelText: 'Search by username',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                          color: selected ? Colors.green : Colors.grey,
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
