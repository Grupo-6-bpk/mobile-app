import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import 'chat_screen.dart';

class NewChatScreen extends ConsumerStatefulWidget {
  const NewChatScreen({super.key});

  @override
  ConsumerState<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends ConsumerState<NewChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String _searchQuery = '';
  
  final TextEditingController _groupNameController = TextEditingController();
  final List<User> _selectedUsers = [];
  bool _isCreatingGroup = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _groupNameController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Conversa'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Chat Direto'),
            Tab(text: 'Criar Grupo'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDirectChatTab(),
          _buildGroupChatTab(),
        ],
      ),
    );
  }

  Widget _buildDirectChatTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por telefone (ex: 11999)',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.trim();
              });
            },
          ),
        ),
        
        Expanded(
          child: _searchQuery.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Digite um número de telefone',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Ex: 11999, 41988, etc.',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : _buildUserSearchResults(),
        ),
      ],
    );
  }

  Widget _buildUserSearchResults() {
    final usersAsync = ref.watch(userSearchProvider(_searchQuery));
    final currentUser = ref.watch(currentUserProvider);

    return usersAsync.when(
      data: (users) {
        final filteredUsers = users.where((user) => 
          user.userId != currentUser?.userId
        ).toList();

        if (filteredUsers.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_off,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Nenhum usuário encontrado',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Verifique o número e tente novamente',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final user = filteredUsers[index];
            return _UserListItem(
              user: user,
              onTap: () => _createDirectChat(user),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Erro na busca',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupChatTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _groupNameController,
            decoration: InputDecoration(
              hintText: 'Nome do grupo (ex: Carona Campus)',
              prefixIcon: const Icon(Icons.group),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            maxLength: 50,
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar usuários para adicionar',
              prefixIcon: const Icon(Icons.person_add),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.trim();
              });
            },
          ),
        ),

        if (_selectedUsers.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Participantes selecionados (${_selectedUsers.length}):',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedUsers.length,
                    itemBuilder: (context, index) {
                      final user = _selectedUsers[index];
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Chip(
                          avatar: CircleAvatar(
                            radius: 12,
                            backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                                ? NetworkImage(user.avatarUrl!)
                                : null,
                            child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                                ? Text(
                                    _getInitials(user.name),
                                    style: const TextStyle(fontSize: 10),
                                  )
                                : null,
                          ),
                          label: Text(
                            user.name ?? 'Usuário',
                            style: const TextStyle(fontSize: 12),
                          ),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            setState(() {
                              _selectedUsers.remove(user);
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],

        if (_selectedUsers.isNotEmpty && _groupNameController.text.trim().isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: _canCreateGroup() && !_isCreatingGroup ? _createGroup : null,
              icon: _isCreatingGroup
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.group_add),
              label: Text(_isCreatingGroup ? 'Criando grupo...' : 'Criar Grupo'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: _canCreateGroup() 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],

        // Lista de usuários para adicionar
        Expanded(
          child: _searchQuery.isEmpty
              ? _buildGroupEmptyState()
              : _buildGroupUserSearchResults(),
        ),
      ],
    );
  }

  Widget _buildGroupEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.group_add,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Crie um grupo para caronas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Busque usuários para adicionar ao grupo',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Como criar um grupo:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '1. Digite um nome para o grupo\n2. Busque e adicione participantes\n3. Clique em "Criar Grupo"',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Você será automaticamente o administrador',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupUserSearchResults() {
    final usersAsync = ref.watch(userSearchProvider(_searchQuery));
    final currentUser = ref.watch(currentUserProvider);

    return usersAsync.when(
      data: (users) {
        // Filtrar usuários já selecionados e o próprio usuário
        final availableUsers = users
            .where((user) => 
              user.userId != currentUser?.userId && // Não incluir o próprio usuário
              !_selectedUsers.any((selected) => selected.userId == user.userId)
            )
            .toList();

        if (availableUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.person_off,
                  size: 48,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty 
                      ? 'Digite algo para buscar usuários'
                      : 'Nenhum usuário disponível',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: availableUsers.length,
          itemBuilder: (context, index) {
            final user = availableUsers[index];
            return _UserListItem(
              user: user,
              trailing: IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                onPressed: () {
                  setState(() {
                    _selectedUsers.add(user);
                  });
                  _showUserAddedSnackBar(user.name ?? 'Usuário');
                },
              ),
              onTap: () {
                setState(() {
                  _selectedUsers.add(user);
                });
                _showUserAddedSnackBar(user.name ?? 'Usuário');
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Erro na busca: $error',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  bool _canCreateGroup() {
    return _groupNameController.text.trim().isNotEmpty && 
           _selectedUsers.isNotEmpty;
  }

  Future<void> _createDirectChat(User user) async {
    try {
      final chatNotifier = ref.read(chatListProvider.notifier);
      if (user.userId == null) {
        _showErrorSnackBar('Usuário inválido: ID ausente');
        return;
      }
      final chat = await chatNotifier.createDirectChat(user.userId!);
      
      if (chat != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(chat: chat),
          ),
        );
      } else {
        _showErrorSnackBar('Erro ao criar conversa');
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao criar conversa: $e');
    }
  }

  Future<void> _createGroup() async {
    final groupName = _groupNameController.text.trim();
    
    if (!_canCreateGroup()) {
      if (groupName.isEmpty) {
        _showErrorSnackBar('Digite um nome para o grupo');
      } else {
        _showErrorSnackBar('Adicione pelo menos 1 participante');
      }
      return;
    }

    setState(() {
      _isCreatingGroup = true;
    });

    try {
      final chatNotifier = ref.read(chatListProvider.notifier);
      final participantIds = _selectedUsers
          .map((u) => u.userId)
          .whereType<int>()
          .toList();
      
      final chat = await chatNotifier.createGroup(groupName, participantIds);
      
      if (chat != null && mounted) {
        await Future.delayed(const Duration(seconds: 2));
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(chat: chat),
          ),
        );
      } else {
        _showErrorSnackBar('Erro ao criar grupo');
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao criar grupo: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingGroup = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showUserAddedSnackBar(String userName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$userName adicionado ao grupo'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty) {
      return words[0][0].toUpperCase();
    }
    return '?';
  }
}

class _UserListItem extends StatelessWidget {
  final User user;
  final VoidCallback onTap;
  final Widget? trailing;

  const _UserListItem({
    required this.user,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
              ? NetworkImage(user.avatarUrl!)
              : null,
          child: user.avatarUrl == null || user.avatarUrl!.isEmpty
              ? Text(_getInitials(user.name))
              : null,
        ),
        title: Text(
          user.name ?? 'Usuário',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: user.phone != null && user.phone!.isNotEmpty
            ? Text(user.phone!)
            : null,
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty) {
      return words[0][0].toUpperCase();
    }
    return '?';
  }
} 