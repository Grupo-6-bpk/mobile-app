import 'package:flutter/material.dart';
import 'package:mobile_app/pages/chat/chat_conversation_page.dart';
import 'package:mobile_app/pages/chat/chat_group_page.dart';
import 'package:mobile_app/pages/chat/models/chat_user.dart';
import 'package:mobile_app/pages/chat/user_search_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<ChatUser> _users = [];
  List<ChatUser> _groups = [];
  List<ChatUser> _filteredUsers = [];
  List<ChatUser> _filteredGroups = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Dados mockados para testes
    _users = [
      ChatUser(
        id: '1',
        name: 'Jéssica Santos',
        imageUrl: 'assets/images/profile1.png',
        lastMessage: 'Vamos combinar o horário para amanhã',
      ),
      ChatUser(
        id: '2',
        name: 'Nicolas Neto',
        imageUrl: 'assets/images/profile2.png',
      ),
      ChatUser(
        id: '3',
        name: 'Pedro Neto',
        imageUrl: 'assets/images/profile3.png',
      ),
    ];

    // Grupos mockados
    _groups = [
      ChatUser(
        id: 'g1',
        name: 'Maria\'s Tur',
        imageUrl: 'assets/images/profile1.png',
        lastMessage: 'Olá Pessoal! Vou sair às 15:00',
      ),
    ];

    _filteredUsers = List.from(_users);
    _filteredGroups = List.from(_groups);

    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = List.from(_users);
        _filteredGroups = List.from(_groups);
      } else {
        _filteredUsers =
            _users
                .where((user) => user.name.toLowerCase().contains(query))
                .toList();

        _filteredGroups =
            _groups
                .where((group) => group.name.toLowerCase().contains(query))
                .toList();
      }
    });
  }

  void _navigateToUserSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserSearchPage()),
    );
  }

  void _navigateToGroupManagement() async {
    // Capturar o contexto atual antes de iniciar operação assíncrona
    final currentContext = context;

    // Esperar o resultado da navegação para a página de grupos
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatGroupPage()),
    );

    // Se um novo grupo foi criado, adicionar à lista de grupos
    if (result != null && result is ChatUser && currentContext.mounted) {
      // Log para depuração - removido na versão de produção
      // print('Grupo recebido: ${result.name}, ID: ${result.id}');

      setState(() {
        _groups.add(result);
        _filteredGroups = List.from(_groups);
      });

      // Mostrar feedback ao usuário se o contexto ainda estiver válido
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text('Grupo "${result.name}" adicionado à sua lista'),
            backgroundColor: Colors.green,
          ),
        );

        // Forçar a mudança para a tab de grupos
        _tabController.animateTo(1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2133),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2133),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Mensagens',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.white),
            onPressed: _navigateToUserSearch,
          ),
          IconButton(
            icon: const Icon(Icons.group_add, color: Colors.white),
            onPressed: _navigateToGroupManagement,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF3B59ED),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [Tab(text: 'Conversas'), Tab(text: 'Grupos')],
        ),
      ),
      body: Column(
        children: [
          // Barra de pesquisa
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF272A3F),
                hintText: 'Procurar',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Lista de conversas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab Conversas
                _buildConversationsList(),

                // Tab Grupos
                _buildGroupsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList() {
    return ListView.builder(
      itemCount: _filteredUsers.length,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return _buildUserListTile(context, user);
      },
    );
  }

  Widget _buildGroupsList() {
    if (_filteredGroups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.group, size: 80, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'Sem grupos no momento',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crie um novo grupo para começar a conversar',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToGroupManagement,
              icon: const Icon(Icons.add),
              label: const Text('Criar Grupo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B59ED),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredGroups.length,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemBuilder: (context, index) {
        final group = _filteredGroups[index];
        return _buildUserListTile(context, group, isGroup: true);
      },
    );
  }

  Widget _buildUserListTile(
    BuildContext context,
    ChatUser user, {
    bool isGroup = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFF272A3F),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[300],
              backgroundImage: AssetImage(user.imageUrl),
            ),
            if (isGroup)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B59ED),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF272A3F),
                      width: 2,
                    ),
                  ),
                  child: const Icon(Icons.people, size: 8, color: Colors.white),
                ),
              ),
          ],
        ),
        title: Text(
          user.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          user.lastMessage ?? '',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () async {
          // Capturar o contexto antes de operação assíncrona
          final currentContext = context;

          // Navegar para a tela de conversa
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ChatConversationPage(
                    user: user,
                    groupId: isGroup ? user.id : null,
                  ),
            ),
          );

          // Verificar se o grupo foi excluído
          if (result == 'deleted') {
            if (isGroup) {
              setState(() {
                // Remover o grupo usando o ID do grupo
                _groups.removeWhere((group) => group.id == user.id);
                // Atualizar a lista filtrada
                _filteredGroups = List.from(_groups);
                // Forçar uma reconstrução do widget
                _tabController.animateTo(0); // Trocar para aba "Conversas"
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) {
                    setState(() {
                      _tabController.animateTo(1); // Voltar para aba "Grupos"
                    });
                  }
                });
              });

              // Usar o contexto capturado para mostrar snackbar
              if (currentContext.mounted) {
                ScaffoldMessenger.of(currentContext).showSnackBar(
                  const SnackBar(
                    content: Text('Grupo removido da sua lista'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } else {
              // Caso seja uma conversa individual excluída
              setState(() {
                _users.removeWhere((u) => u.id == user.id);
                _filteredUsers = List.from(_users);
              });

              // Usar o contexto capturado para mostrar snackbar
              if (currentContext.mounted) {
                ScaffoldMessenger.of(currentContext).showSnackBar(
                  const SnackBar(
                    content: Text('Conversa removida da sua lista'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          }
        },
      ),
    );
  }
}
