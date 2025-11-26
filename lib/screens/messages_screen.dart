import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mini_social_network/utils/screen_manager.dart';
import '../models/messages.dart';
import '../services/list_message_service.dart';
import '../widgets/messages_widget.dart';
import '../main.dart';
import '../theme/app_theme.dart';
import 'all_screen.dart';
import 'direct/direct_chat_screen.dart';
import 'group/group_chat_screen.dart';

class ConversationListScreen extends StatefulWidget {
  final GlobalKey<ConversationListScreenState> conversationListScreenKey;
  const ConversationListScreen({required this.conversationListScreenKey})
      : super(key: conversationListScreenKey);

  @override
  ConversationListScreenState createState() => ConversationListScreenState();

  void reload() {
    final state = conversationListScreenKey.currentState;
    if (state != null) {
      state._silentReload();
    }
  }
}

class ConversationListScreenState extends State<ConversationListScreen>
    with RouteAware, SingleTickerProviderStateMixin {
  final List<Conversation> _conversations = [];
  final MessageService _messageService = MessageService();
  final ScreenManager _screenManager = ScreenManager();

  bool _isInitialLoading = true;
  bool _isSilentLoading = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _screenManager.registerConversationList(this);
    CurrentScreenManager.updateCurrentScreen('conversationList');
    _loadConversations();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    routeObserver.unsubscribe(this);
    _screenManager.unregisterConversationList();
    CurrentScreenManager.clear();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    try {
      List<Conversation> contactConversations =
          await _messageService.getConversationsWithContact();

      if (mounted) {
        setState(() {
          _conversations
            ..clear()
            ..addAll(contactConversations);
          _isInitialLoading = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      print('❌ Failed to load conversations: $e');
      if (mounted) {
        setState(() => _isInitialLoading = false);
      }
    }
  }

  /// 🔇 Silent reload - pas de loader visible
  Future<void> _silentReload() async {
    if (_isSilentLoading) return;

    setState(() => _isSilentLoading = true);

    try {
      List<Conversation> contactConversations =
          await _messageService.getConversationsWithContact();

      if (mounted) {
        setState(() {
          _conversations
            ..clear()
            ..addAll(contactConversations);
          _isSilentLoading = false;
        });
      }
    } catch (e) {
      print('❌ Failed to silent reload conversations: $e');
      if (mounted) {
        setState(() => _isSilentLoading = false);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute? route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    super.didPopNext();
    CurrentScreenManager.updateCurrentScreen('conversationList');
    _silentReload();
  }

  Widget _buildAvatar(Contact contact, BuildContext context) {
    final hasStory = contact.story.isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (hasStory) {
          _navigateToAllStoriesScreen(context, contact);
        } else {
          _navigateToChatScreen(context, contact);
        }
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: hasStory
              ? const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          border: hasStory
              ? null
              : Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.2),
                  width: 2,
                ),
        ),
        padding: EdgeInsets.all(hasStory ? 2.5 : 0),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          padding: EdgeInsets.all(hasStory ? 2 : 0),
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl: contact.photo ?? '',
              placeholder: (context, url) => Container(
                color: AppTheme.primaryColor.withOpacity(0.1),
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: AppTheme.primaryColor.withOpacity(0.1),
                child: const Icon(
                  Icons.person,
                  size: 28,
                  color: AppTheme.primaryColor,
                ),
              ),
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 200),
              fadeOutDuration: const Duration(milliseconds: 200),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToAllStoriesScreen(BuildContext context, Contact contact) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllStoriesScreen(
          storyIds: contact.story,
          initialIndex: 0,
        ),
      ),
    );
  }

  Widget _buildStatus(Contact user) {
    if (user.presence != 'inactif') {
      return Positioned(
        right: 2,
        bottom: 2,
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.secondaryColor,
            border: Border.all(
              color: Theme.of(context).scaffoldBackgroundColor,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.secondaryColor.withOpacity(0.4),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _navigateToChatScreen(BuildContext context, Contact contact) {
    if (contact.type == "groupe") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GroupChatScreen(groupId: contact.id),
        ),
      );
    } else if (contact.type == "utilisateur") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DirectChatScreen(contactId: contact.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isInitialLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        const AlwaysStoppedAnimation(AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chargement des conversations...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                // Header avec stories
                SliverAppBar(
                  expandedHeight: 120,
                  floating: false,
                  pinned: false,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    background: SafeArea(
                      child: _conversations.isEmpty
                          ? Center(
                              child: Text(
                                'Aucune conversation',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              itemCount: _conversations.length,
                              itemBuilder: (context, index) {
                                final conversation = _conversations[index];
                                return Container(
                                  width: 72,
                                  margin: const EdgeInsets.only(right: 8),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Stack(
                                        children: [
                                          _buildAvatar(
                                            conversation.contact,
                                            context,
                                          ),
                                          _buildStatus(conversation.contact),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Flexible(
                                        child: Text(
                                          conversation.contact.nom,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 11,
                                                height: 1.2,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ),

                // Divider subtil
                SliverToBoxAdapter(
                  child: Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Liste des conversations
                SliverPadding(
                  padding: const EdgeInsets.only(top: 8),
                  sliver: _conversations.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: Theme.of(context)
                                      .iconTheme
                                      .color
                                      ?.withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucune conversation',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return FadeTransition(
                                opacity: _fadeAnimation,
                                child: ConversationWidget(
                                  conversation: _conversations[index],
                                ),
                              );
                            },
                            childCount: _conversations.length,
                          ),
                        ),
                ),
              ],
            ),

      // Indicateur de silent reload subtil
      floatingActionButton: _isSilentLoading
          ? Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            )
          : null,
    );
  }
}
