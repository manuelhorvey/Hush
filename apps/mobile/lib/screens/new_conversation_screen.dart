import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
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

  List<UserInfo> _results = [];
  bool _loading = false;
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

  Future<void> _startConversation(UserInfo user) async {
    if (_token == null) return;
    try {
      final conv = await _messaging.createConversation(_token!, user.id);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conv.id,
            otherUsername: user.username,
            otherUserId: user.id,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
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
      ),
      body: Column(
        children: [
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
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(user.username[0].toUpperCase()),
                        ),
                        title: Text(user.username),
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () => _startConversation(user),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
