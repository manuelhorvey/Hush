import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/messaging_service.dart';
import 'chat_screen.dart';
import 'devices_screen.dart';
import 'new_conversation_screen.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _username;
  String? _token;
  List<ConversationInfo> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = AuthService(
      api: ApiClient(baseUrl: 'http://$apiHost:8081'),
    );
    final session = await auth.getSession();
    if (session != null && mounted) {
      setState(() {
        _username = session.username;
        _token = session.token;
      });
      _loadConversations(session.token);
    }
  }

  Future<void> _loadConversations(String token) async {
    final messaging = MessagingService(
      api: ApiClient(baseUrl: 'http://$apiHost:8083'),
    );
    try {
      final convs = await messaging.listConversations(token);
      if (mounted) setState(() => _conversations = convs);
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final auth = AuthService(
      api: ApiClient(baseUrl: 'http://$apiHost:8081'),
    );
    await auth.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  Future<void> _openConversation(ConversationInfo conv) async {
    final destroyed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conv.id,
          otherUsername: 'User ${conv.participantId.substring(0, 8)}',
          otherUserId: conv.participantId,
        ),
      ),
    );

    if (destroyed == true && _token != null) {
      _loadConversations(_token!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_username != null ? 'Hush — $_username' : 'Hush'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.devices),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DevicesScreen()),
              );
            },
            tooltip: 'My Devices',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const NewConversationScreen(),
            ),
          );
          if (_token != null) _loadConversations(_token!);
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? const Center(child: Text('No conversations yet.'))
              : RefreshIndicator(
                  onRefresh: () async {
                    if (_token != null) await _loadConversations(_token!);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _conversations.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final conv = _conversations[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: conv.isActive
                              ? Colors.green.shade100
                              : Colors.grey.shade200,
                          child: Icon(
                            conv.isActive
                                ? Icons.chat
                                : Icons.check_circle_outline,
                            color: conv.isActive ? Colors.green : Colors.grey,
                          ),
                        ),
                        title: Text(
                            'User ${conv.participantId.substring(0, 8)}'),
                        subtitle: Row(
                          children: [
                            Text(conv.createdAt.substring(0, 10)),
                            const SizedBox(width: 8),
                            _statusChip(conv.status),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios,
                            size: 16),
                        onTap: () => _openConversation(conv),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _statusChip(String status) {
    final (label, color) = switch (status) {
      'completed' => ('Completed', Colors.grey),
      'destroyed' => ('Destroyed', Colors.red),
      _ => ('Active', Colors.green),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
