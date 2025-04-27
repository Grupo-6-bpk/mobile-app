import 'package:flutter/material.dart';
import 'package:mobile_app/pages/chat/chat_conversation_page.dart';
import 'package:mobile_app/pages/chat/models/chat_user.dart';

class UserSearchPage extends StatefulWidget {
  const UserSearchPage({super.key});

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<ChatUser> _allUsers = [];
  List<ChatUser> _filteredUsers = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    
    // Carregar usuários mockados
    _loadUsers();
    
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadUsers() {
    // Lista de usuários mockados para teste
    _allUsers.addAll([
      ChatUser(
        id: '1',
        name: 'Jéssica Santos',
        imageUrl: 'assets/images/profile1.png',
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
      ChatUser(
        id: '4',
        name: 'Carolina Silva',
        imageUrl: 'assets/images/profile1.png',
      ),
      ChatUser(
        id: '5',
        name: 'Roberto Araújo',
        imageUrl: 'assets/images/profile2.png',
      ),
      ChatUser(
        id: '6',
        name: 'Maria\'s Tur',
        imageUrl: 'assets/images/profile3.png',
      ),
      ChatUser(
        id: '7',
        name: 'Fernando Costa',
        imageUrl: 'assets/images/profile1.png',
      ),
      ChatUser(
        id: '8',
        name: 'Amanda Ribeiro',
        imageUrl: 'assets/images/profile2.png',
      ),
      ChatUser(
        id: '9',
        name: 'Carlos Mendes',
        imageUrl: 'assets/images/profile3.png',
      ),
      ChatUser(
        id: '10',
        name: 'Ana Paula',
        imageUrl: 'assets/images/profile1.png',
      ),
    ]);
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredUsers = [];
      } else {
        _filteredUsers = _allUsers
            .where((user) => user.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2133),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2133),
        elevation: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Buscar usuários...',
            hintStyle: TextStyle(color: Colors.white60),
            border: InputBorder.none,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
              onPressed: () {
                _searchController.clear();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Resultados da busca ou sugestões
          Expanded(
            child: _isSearching
                ? _buildSearchResults()
                : _buildSearchSuggestions(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_filteredUsers.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum usuário encontrado',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredUsers.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return _buildUserItem(user);
      },
    );
  }

  Widget _buildSearchSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Sugestões',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _allUsers.length > 5 ? 5 : _allUsers.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final user = _allUsers[index];
              return _buildUserItem(user);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserItem(ChatUser user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF272A3F),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: AssetImage(user.imageUrl),
            ),
          ],
        ),
        title: Text(
          user.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        trailing: const Icon(
          Icons.chat_bubble_outline,
          color: Color(0xFF3B59ED),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatConversationPage(user: user),
            ),
          );
        },
      ),
    );
  }
} 