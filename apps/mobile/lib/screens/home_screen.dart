import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/conversations_provider.dart';
import '../services/messaging_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/conversation_card.dart';
import '../widgets/empty_state.dart';
import 'new_conversation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token;
    if (token != null) {
      context.read<ConversationsProvider>().load(token);
    }
  }

  String _conversationTitle(ConversationInfo conv, String? myUserId) {
    final others = conv.participants
        .where((p) => p.userId != myUserId)
        .map((p) => p.username)
        .toList();
    if (others.length == 1) return others.first;
    return '${others.first} +${others.length - 1}';
  }

  Future<void> _openConversation(ConversationInfo conv) async {
    await context.push(
      '/conversation/${conv.id}',
      extra: conv.participants,
    );
    _load();
  }

  List<ConversationInfo> _filtered(List<ConversationInfo> convs) {
    if (_searchQuery.isEmpty) return convs;
    final q = _searchQuery.toLowerCase();
    return convs.where((c) {
      final title = _conversationTitle(c, context.read<AuthProvider>().userId);
      return title.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ConversationsProvider>(
      builder: (context, auth, convs, _) {
        final myUserId = auth.userId;
        return Scaffold(
          appBar: AppBar(
            title: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                border: InputBorder.none,
                hintStyle: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              await context.push('/new-conversation');
              _load();
            },
            child: const Icon(Icons.add),
          ),
          body: convs.loading
              ? const Center(child: CircularProgressIndicator())
              : convs.conversations.isEmpty
                  ? EmptyState(
                      icon: Icons.chat_bubble_outline,
                      title: 'No conversations yet',
                      subtitle: 'Tap + to start a secure conversation',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          HushSpacing.lg,
                          HushSpacing.md,
                          HushSpacing.lg,
                          HushSpacing.xxl + 56,
                        ),
                        itemCount: _filtered(convs.conversations).length,
                        itemBuilder: (context, i) {
                          final conv = _filtered(convs.conversations)[i];
                          return ConversationCard(
                            title: _conversationTitle(conv, myUserId),
                            isActive: conv.isActive,
                            status: conv.status,
                            date: conv.createdAt.substring(0, 10),
                            onTap: () => _openConversation(conv),
                          );
                        },
                      ),
                    ),
        );
      },
    );
  }
}
