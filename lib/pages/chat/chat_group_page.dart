import 'package:flutter/material.dart';
import 'package:mobile_app/pages/chat/chat_conversation_page.dart';
import 'package:mobile_app/pages/chat/models/chat_user.dart';

class ChatGroupPage extends StatefulWidget {
  const ChatGroupPage({super.key});

  @override
  State<ChatGroupPage> createState() => _ChatGroupPageState();
}

class _ChatGroupPageState extends State<ChatGroupPage> {
  final TextEditingController _groupNameController = TextEditingController();
  final List<ChatUser> _allUsers = [];
  final List<ChatUser> _selectedUsers = [];
  final List<Map<String, dynamic>> _existingGroups = [];

  @override
  void initState() {
    super.initState();

    // Carregar usuários mockados
    _loadUsers();

    // Carregar grupos existentes
    _loadExistingGroups();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  void _loadUsers() {
    // Dados mockados de usuários para seleção
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
    ]);
  }

  void _loadExistingGroups() {
    // Dados mockados de grupos existentes
    _existingGroups.addAll([
      {
        'id': 'g1',
        'name': 'Maria\'s Tur',
        'imageUrl': 'assets/images/profile1.png',
        'members': [_allUsers[0], _allUsers[1], _allUsers[2]],
        'lastMessage': 'Olá Pessoal! Vou sair às 15:00',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      },
      {
        'id': 'g2',
        'name': 'Carona Faculdade',
        'imageUrl': 'assets/images/profile3.png',
        'members': [_allUsers[1], _allUsers[3], _allUsers[4]],
        'lastMessage': 'Alguém vai amanhã para aula?',
        'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      },
    ]);
  }

  void _toggleUserSelection(ChatUser user) {
    setState(() {
      if (_selectedUsers.contains(user)) {
        _selectedUsers.remove(user);
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  void _createGroup() {
    if (_groupNameController.text.trim().isEmpty || _selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, informe um nome para o grupo e selecione pelo menos um usuário.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Simular a criação de um grupo
    final newGroupId =
        'g${_existingGroups.length + 3}'; // +3 para garantir que não haja conflito com IDs existentes
    final newGroupName = _groupNameController.text.trim();

    final newGroup = {
      'id': newGroupId,
      'name': newGroupName,
      'imageUrl': 'assets/images/profile1.png', // Usar uma imagem padrão
      'members': List<ChatUser>.from(_selectedUsers),
      'lastMessage': 'Grupo criado',
      'timestamp': DateTime.now(),
    };

    // Adicionar o novo grupo à lista
    setState(() {
      _existingGroups.add(newGroup);
      _groupNameController.clear();
      _selectedUsers.clear();
    });

    // Criar um objeto ChatUser para representar o grupo e retornar para a página anterior
    final groupUser = ChatUser(
      id: newGroupId,
      name: newGroupName,
      imageUrl: 'assets/images/profile1.png',
      lastMessage: 'Grupo criado',
    );

    // Mostrar mensagem de sucesso
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Grupo "$newGroupName" criado com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );

    // Capturar o BuildContext antes da operação assíncrona
    final currentContext = context;

    // Retornar à tela anterior passando o grupo criado
    // Importante: usar um pequeno atraso para garantir que a UI tenha tempo
    // de processar o fechamento do modal antes de navegar
    Future.delayed(const Duration(milliseconds: 100), () {
      // Verificar se o contexto ainda é válido
      if (currentContext.mounted) {
        Navigator.pop(currentContext, groupUser);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          'Grupos',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: _showCreateGroupModal,
          ),
        ],
      ),
      body:
          _existingGroups.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _existingGroups.length,
                itemBuilder: (context, index) {
                  final group = _existingGroups[index];
                  return _buildGroupItem(context, group);
                },
              ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group,
            size: 80,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.24),
          ),
          const SizedBox(height: 16),
          Text(
            'Sem grupos no momento',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie um novo grupo para começar a conversar',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateGroupModal,
            icon: const Icon(Icons.add),
            label: const Text('Criar Grupo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupItem(BuildContext context, Map<String, dynamic> group) {
    final List<ChatUser> members = group['members'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: AssetImage(group['imageUrl']),
        ),
        title: Text(
          group['name'],
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group['lastMessage'],
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${members.length} membros',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 10,
              ),
            ),
          ],
        ),
        trailing: Text(
          _formatTimestamp(group['timestamp']),
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
        onTap: () {
          // Navegar para a tela de conversa do grupo
          final user = ChatUser(
            id: group['id'],
            name: group['name'],
            imageUrl: group['imageUrl'],
            lastMessage: group['lastMessage'],
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      ChatConversationPage(user: user, groupId: group['id']),
            ),
          );
        },
      ),
    );
  }

  void _showCreateGroupModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Criar Novo Grupo',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _groupNameController,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Nome do grupo',
                        hintStyle: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        filled: true,
                        fillColor:
                            Theme.of(context).colorScheme.surfaceContainer,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Selecione os participantes:',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 300,
                      child: ListView.builder(
                        itemCount: _allUsers.length,
                        itemBuilder: (context, index) {
                          final user = _allUsers[index];
                          final isSelected = _selectedUsers.contains(user);

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: AssetImage(user.imageUrl),
                            ),
                            title: Text(
                              user.name,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            trailing:
                                isSelected
                                    ? Icon(
                                      Icons.check_circle,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    )
                                    : Icon(
                                      Icons.circle_outlined,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                            onTap: () {
                              setModalState(() {
                                _toggleUserSelection(user);
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancelar',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _createGroup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                          ),
                          child: Text(
                            'Criar Grupo',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final date = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (date == today) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (date == yesterday) {
      return 'Ontem';
    } else {
      return '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year}';
    }
  }
}
