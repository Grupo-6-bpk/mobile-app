import 'package:flutter/material.dart';
import 'package:mobile_app/pages/chat/models/chat_message.dart';
import 'package:mobile_app/pages/chat/models/chat_user.dart';

class ChatConversationPage extends StatefulWidget {
  final ChatUser user;
  final String? groupId;

  const ChatConversationPage({
    super.key,
    required this.user,
    this.groupId,
  });

  @override
  State<ChatConversationPage> createState() => _ChatConversationPageState();
}

class _ChatConversationPageState extends State<ChatConversationPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  
  // Lista de membros do grupo para exemplo
  final List<ChatUser> _groupMembers = [];
  // Lista de possíveis usuários para adicionar ao grupo
  final List<ChatUser> _allUsers = [];
  // Lista estática de usuários bloqueados para teste (seria armazenada em banco de dados)
  static final List<String> _blockedUsers = [];

  // Verificar se o usuário está bloqueado
  bool get _isUserBlocked => _blockedUsers.contains(widget.user.id);
  
  // Verificar se estamos em uma conversa de grupo
  bool get _isGroupChat => widget.groupId != null;

  @override
  void initState() {
    super.initState();
    
    // Carregar mensagens mockadas para teste
    _loadMessages();
    
    // Carregar membros e usuários para grupos
    if (widget.groupId != null) {
      _loadGroupMembers();
      _loadAvailableUsers();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadGroupMembers() {
    // Simular carregamento de membros do grupo
    _groupMembers.addAll([
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
    ]);
  }

  void _loadAvailableUsers() {
    // Simular carregamento de usuários disponíveis
    _allUsers.addAll([
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
        name: 'Amanda Ribeiro',
        imageUrl: 'assets/images/profile3.png',
      ),
      ChatUser(
        id: '7',
        name: 'Carlos Mendes',
        imageUrl: 'assets/images/profile1.png',
      ),
    ]);
  }

  void _loadMessages() {
    // Mensagens de exemplo para testes
    final List<ChatMessage> mockMessages = [
      ChatMessage(
        id: '1',
        senderId: 'currentUser',
        receiverId: widget.user.id,
        content: 'Olá, tudo bem?',
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        isRead: true,
      ),
      ChatMessage(
        id: '2',
        senderId: widget.user.id,
        receiverId: 'currentUser',
        content: 'Oi! Tudo bem e com você?',
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 1, minutes: 45)),
        isRead: true,
      ),
      ChatMessage(
        id: '3',
        senderId: 'currentUser',
        receiverId: widget.user.id,
        content: 'Tudo ótimo! Queria saber se podemos combinar uma carona para amanhã.',
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 1, minutes: 30)),
        isRead: true,
      ),
      ChatMessage(
        id: '4',
        senderId: widget.user.id,
        receiverId: 'currentUser',
        content: 'Claro! Para qual horário?',
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
        isRead: true,
      ),
      ChatMessage(
        id: '5',
        senderId: 'currentUser',
        receiverId: widget.user.id,
        content: 'Preciso estar no trabalho às 8h, então seria bom sair às 7h30.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        isRead: true,
      ),
      ChatMessage(
        id: '6',
        senderId: widget.user.id,
        receiverId: 'currentUser',
        content: 'Perfeito! Vou te buscar às 7h30 amanhã então.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
        isRead: true,
      ),
    ];

    setState(() {
      _messages.addAll(mockMessages);
    });

    // Rolar para o final da lista após carregar as mensagens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'currentUser',
      receiverId: widget.user.id,
      groupId: widget.groupId,
      content: _messageController.text.trim(),
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(newMessage);
      _messageController.clear();
    });

    // Rolar para o final da lista após enviar a mensagem
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }
  
  void _shareLocation() {
    // Implementação futura: integração com Google Maps
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de compartilhar localização será implementada em breve.'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showUserOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2133),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text(
                  'Excluir conversa',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConversationConfirmation();
                },
              ),
              const Divider(color: Colors.white24),
              if (_isUserBlocked)
                ListTile(
                  leading: const Icon(Icons.person_add, color: Colors.green),
                  title: const Text(
                    'Desbloquear usuário',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _unblockUser();
                  },
                )
              else
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.red),
                  title: const Text(
                    'Bloquear usuário',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showBlockUserConfirmation();
                  },
                ),
            ],
          ),
        );
      },
    );
  }
  
  void _showDeleteConversationConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF272A3F),
          title: const Text(
            'Excluir conversa',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Tem certeza que deseja excluir esta conversa? Esta ação não pode ser desfeita.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteConversation();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }
  
  void _showBlockUserConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF272A3F),
          title: const Text(
            'Bloquear usuário',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Tem certeza que deseja bloquear ${widget.user.name}? Vocês não poderão mais trocar mensagens.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _blockUser();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Bloquear'),
            ),
          ],
        );
      },
    );
  }
  
  void _deleteConversation() {
    // Aqui seria implementada a lógica para excluir a conversa do banco de dados
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Conversa excluída com sucesso'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context, 'deleted');
  }
  
  void _blockUser() {
    // Aqui seria implementada a lógica para bloquear o usuário
    setState(() {
      _blockedUsers.add(widget.user.id);
    });
    
    // Adicionar mensagem de sistema sobre o bloqueio
    final systemMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'system',
      receiverId: widget.user.id,
      content: 'Você bloqueou ${widget.user.name}. Vocês não poderão mais trocar mensagens.',
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(systemMessage);
    });
    
    // Rolar para o final da lista
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.user.name} foi bloqueado'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }

  void _unblockUser() {
    setState(() {
      _blockedUsers.remove(widget.user.id);
    });
    
    // Adicionar mensagem de sistema sobre o desbloqueio
    final systemMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'system',
      receiverId: widget.user.id,
      content: 'Você desbloqueou ${widget.user.name}. Vocês podem voltar a trocar mensagens.',
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(systemMessage);
    });
    
    // Rolar para o final da lista
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.user.name} foi desbloqueado'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2133),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2133),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage(widget.user.imageUrl),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: widget.groupId != null ? _showGroupInfo : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.user.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_isUserBlocked && !_isGroupChat)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.block,
                              color: Colors.red.shade300,
                              size: 14,
                            ),
                          ),
                      ],
                    ),
                    widget.groupId != null
                      ? Row(
                          children: [
                            Text(
                              '${_groupMembers.length} membros',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white70,
                              size: 14,
                            ),
                          ],
                        )
                      : const SizedBox(),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: widget.groupId != null ? _showGroupOptions : _showUserOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Aviso de bloqueio, se aplicável
          if (_isUserBlocked && !_isGroupChat)
            Container(
              width: double.infinity,
              color: Colors.red.withValues(alpha: 0.2),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.block, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Você bloqueou ${widget.user.name}. Vocês não podem trocar mensagens.',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: _unblockUser,
                    child: const Text(
                      'Desbloquear',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            
          // Lista de mensagens
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final bool isMe = message.senderId == 'currentUser';
                final bool isSystem = message.senderId == 'system';
                
                // Verificar se a mensagem deve mostrar timestamp
                final bool showTimestamp = index == 0 || 
                    _shouldShowTimestamp(_messages[index], index > 0 ? _messages[index - 1] : null);
                
                if (isSystem) {
                  return Column(
                    children: [
                      if (showTimestamp) _buildTimestampDivider(message.timestamp),
                      _buildSystemMessage(message),
                    ],
                  );
                }
                
                return Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (showTimestamp) _buildTimestampDivider(message.timestamp),
                    _buildMessageBubble(message, isMe),
                  ],
                );
              },
            ),
          ),
          
          // Campo de entrada de mensagem
          if (!_isUserBlocked || _isGroupChat)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              color: const Color(0xFF272A3F),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.location_on, color: Colors.red),
                    onPressed: _shareLocation,
                    tooltip: 'Compartilhar localização',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Digite uma mensagem...',
                        hintStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF3B59ED)),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: const Color(0xFF272A3F),
              child: const Center(
                child: Text(
                  'Você não pode enviar mensagens para este usuário',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildSystemMessage(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF3B59ED).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message.content,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage(widget.user.imageUrl),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.6,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFF3B59ED) : const Color(0xFF272A3F),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            Icon(
              message.isRead ? Icons.done_all : Icons.done,
              size: 16,
              color: message.isRead ? Colors.blue : Colors.white70,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimestampDivider(DateTime timestamp) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          const Expanded(
            child: Divider(color: Colors.white24),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              _formatDate(timestamp),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
          const Expanded(
            child: Divider(color: Colors.white24),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (dateToCheck == today) {
      return 'Hoje';
    } else if (dateToCheck == yesterday) {
      return 'Ontem';
    } else {
      return '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year}';
    }
  }

  bool _shouldShowTimestamp(ChatMessage currentMessage, ChatMessage? previousMessage) {
    if (previousMessage == null) return true;
    
    final currentDay = DateTime(
      currentMessage.timestamp.year,
      currentMessage.timestamp.month,
      currentMessage.timestamp.day,
    );
    
    final previousDay = DateTime(
      previousMessage.timestamp.year,
      previousMessage.timestamp.month,
      previousMessage.timestamp.day,
    );
    
    return currentDay != previousDay;
  }

  void _showGroupOptions() {
    if (widget.groupId == null) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2133),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_add, color: Colors.white),
                title: const Text(
                  'Adicionar participantes',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showAddMembersDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_remove, color: Colors.white),
                title: const Text(
                  'Remover participantes',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showRemoveMembersDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.white),
                title: const Text(
                  'Informações do grupo',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showGroupInfo();
                },
              ),
              const Divider(color: Colors.white24),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text(
                  'Excluir grupo',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteGroupConfirmation();
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Adicionar um usuário ou lista de usuários ao grupo
  void _addUsersToGroup(List<ChatUser> users) {
    if (users.isEmpty) return;
    
    setState(() {
      for (final user in users) {
        // Verificar se o usuário já está no grupo
        if (!_groupMembers.any((member) => member.id == user.id)) {
          _groupMembers.add(user);
        }
      }
    });
    
    // Mostrar mensagem de sistema para cada adição
    final userNames = users.map((user) => user.name).join(', ');
    final systemMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'system',
      groupId: widget.groupId,
      content: '$userNames ${users.length == 1 ? 'foi adicionado' : 'foram adicionados'} ao grupo',
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(systemMessage);
    });
    
    // Rolar para o final da lista
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }
  
  // Remover um usuário do grupo
  void _removeUserFromGroup(ChatUser user) {
    final userName = user.name;
    
    setState(() {
      _groupMembers.removeWhere((member) => member.id == user.id);
    });
    
    // Adicionar mensagem de sistema sobre a remoção
    final systemMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'system',
      groupId: widget.groupId,
      content: '$userName foi removido do grupo',
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(systemMessage);
    });
    
    // Rolar para o final da lista
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  // Método para verificar se um usuário é membro do grupo
  bool _isUserInGroup(String userId) {
    return _groupMembers.any((member) => member.id == userId);
  }

  void _showAddMembersDialog() {
    // Filtrar usuários que não são membros do grupo
    final availableUsers = _allUsers.where((user) => 
      !_isUserInGroup(user.id)
    ).toList();
    
    if (availableUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não há mais usuários disponíveis para adicionar ao grupo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Lista de usuários selecionados para adicionar
    List<ChatUser> selectedUsers = [];
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF272A3F),
              title: const Text(
                'Adicionar participantes',
                style: TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: ListView.builder(
                  itemCount: availableUsers.length,
                  itemBuilder: (context, index) {
                    final user = availableUsers[index];
                    final isSelected = selectedUsers.contains(user);
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: AssetImage(user.imageUrl),
                      ),
                      title: Text(
                        user.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.circle_outlined, color: Colors.white70),
                      onTap: () {
                        setModalState(() {
                          if (isSelected) {
                            selectedUsers.remove(user);
                          } else {
                            selectedUsers.add(user);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedUsers.isNotEmpty) {
                      // Adicionar os usuários selecionados ao grupo
                      _addUsersToGroup(selectedUsers);
                      
                      // Mostrar mensagem de sucesso
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${selectedUsers.length} ${selectedUsers.length == 1 ? 'usuário foi adicionado' : 'usuários foram adicionados'} ao grupo'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                    
                    // Fechar o diálogo atual
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B59ED),
                  ),
                  child: const Text('Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  void _showRemoveMembersDialog() {
    if (_groupMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não há membros no grupo para remover'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) {
        // Criamos uma cópia local da lista para o diálogo
        final localMembers = List<ChatUser>.from(_groupMembers);
        
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF272A3F),
              title: const Text(
                'Remover participantes',
                style: TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: localMembers.isEmpty
                    ? const Center(
                        child: Text(
                          'Não há membros no grupo',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.builder(
                        itemCount: localMembers.length,
                        itemBuilder: (context, index) {
                          final member = localMembers[index];
                          
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: AssetImage(member.imageUrl),
                            ),
                            title: Text(
                              member.name,
                              style: const TextStyle(color: Colors.white),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () {
                                // Remover o membro na UI local
                                setModalState(() {
                                  localMembers.remove(member);
                                });
                                
                                // Remover o membro do grupo real
                                _removeUserFromGroup(member);
                                
                                // Mostrar mensagem de sucesso
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${member.name} foi removido do grupo'),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                                
                                // Fechar o diálogo se não tiver mais membros
                                if (localMembers.isEmpty) {
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Fechar',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  void _showGroupInfo() {
    showDialog(
      context: context,
      builder: (context) {
        // Criar uma cópia local da lista de membros atual para o diálogo
        final localMembers = List<ChatUser>.from(_groupMembers);
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF272A3F),
              title: const Text(
                'Informações do grupo',
                style: TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage: AssetImage(widget.user.imageUrl),
                        radius: 24,
                      ),
                      title: Text(
                        widget.user.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Criado em ${_formatDate(DateTime.now().subtract(const Duration(days: 10)))}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Participantes (${localMembers.length})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white70, size: 18),
                          onPressed: () {
                            // Atualizar a lista local com os membros atuais
                            setDialogState(() {
                              localMembers.clear();
                              localMembers.addAll(_groupMembers);
                            });
                          },
                          tooltip: 'Atualizar lista',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: localMembers.isEmpty
                          ? const Center(
                              child: Text(
                                'Não há membros no grupo',
                                style: TextStyle(color: Colors.white70),
                              ),
                            )
                          : ListView.builder(
                              itemCount: localMembers.length,
                              itemBuilder: (context, index) {
                                final member = localMembers[index];
                                
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: AssetImage(member.imageUrl),
                                  ),
                                  title: Text(
                                    member.name,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Fechar',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _showDeleteGroupConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF272A3F),
          title: const Text(
            'Excluir grupo',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Tem certeza que deseja excluir este grupo? Esta ação não pode ser desfeita e todas as mensagens serão perdidas.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Fechar o diálogo
                _deleteGroup();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  void _deleteGroup() {
    // Aqui seria implementada a lógica para excluir o grupo do banco de dados
    // Como estamos trabalhando com dados mockados, apenas simulamos a exclusão
    
    // Capturar o contexto antes de operação assíncrona
    final currentContext = context;
    
    // Mostrar uma mensagem de sucesso
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Grupo excluído com sucesso'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Pequeno atraso para garantir que o snackbar seja exibido antes de navegar
    Future.delayed(const Duration(milliseconds: 200), () {
      // Verificar se o contexto ainda é válido
      if (currentContext.mounted) {
        // Navegando de volta para a página anterior com sinal de exclusão
        Navigator.pop(currentContext, 'deleted');
      }
    });
  }
} 