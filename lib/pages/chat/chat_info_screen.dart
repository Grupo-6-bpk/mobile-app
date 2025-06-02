import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/chat.dart';
import '../../models/user.dart';
import '../../models/chat_participant.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/chat_service.dart';

class ChatInfoScreen extends ConsumerStatefulWidget {
  final Chat chat;

  const ChatInfoScreen({super.key, required this.chat});

  @override
  ConsumerState<ChatInfoScreen> createState() => _ChatInfoScreenState();
}

class _ChatInfoScreenState extends ConsumerState<ChatInfoScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = widget.chat.isGroup && widget.chat.adminId == currentUser?.userId;
    final isGroup = widget.chat.isGroup;

    return Scaffold(
      appBar: AppBar(
        title: Text(isGroup ? 'Info do Grupo' : 'Info do Chat'),
        actions: [
          if (isGroup && isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              onPressed: () => _showDeleteChatDialog(),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildChatHeader(),
                
                const SizedBox(height: 24),
                
                _buildParticipantsSection(isAdmin),
                
                const SizedBox(height: 24),
                
                if (isGroup)
                  _buildActionsSection(isAdmin),
              ],
            ),
    );
  }

  Widget _buildChatHeader() {
    final displayName = widget.chat.getDisplayName(ref.watch(currentUserProvider)?.userId ?? 0);
    final displayAvatar = widget.chat.getDisplayAvatar(ref.watch(currentUserProvider)?.userId ?? 0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: displayAvatar != null
                  ? NetworkImage(displayAvatar)
                  : null,
              child: displayAvatar == null
                  ? Text(
                      _getInitials(displayName),
                      style: const TextStyle(fontSize: 24),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.chat.isGroup) ...[
              const SizedBox(height: 8),
              Text(
                '${widget.chat.participants.length} participantes',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsSection(bool isAdmin) {
    if (widget.chat.participants.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Nenhum participante encontrado',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.people),
                const SizedBox(width: 12),
                const Text(
                  'Participantes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (widget.chat.isGroup && isAdmin)
                  IconButton(
                    icon: const Icon(Icons.person_add),
                    onPressed: () => _showAddParticipantDialog(),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...widget.chat.participants.map((participant) => 
            _buildParticipantTile(participant, isAdmin)
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantTile(ChatParticipant participant, bool isAdmin) {
    final currentUser = ref.watch(currentUserProvider);
    final isCurrentUser = participant.userId == currentUser?.userId;
    final isAdminUser = participant.userId == widget.chat.adminId;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: participant.avatarUrl != null
            ? NetworkImage(participant.avatarUrl!)
            : null,
        child: participant.avatarUrl == null
            ? Text(_getInitials(participant.name))
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              isCurrentUser ? 'Você' : participant.name,
              style: TextStyle(
                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (isAdminUser)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Admin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          if (participant.isBlocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Bloqueado',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      subtitle: null,
      trailing: (!isCurrentUser && (isAdmin || !widget.chat.isGroup))
          ? PopupMenuButton<String>(
              onSelected: (value) => _handleParticipantAction(value, participant),
              itemBuilder: (context) => [
                if (!participant.isBlocked)
                  const PopupMenuItem(
                    value: 'block',
                    child: Row(
                      children: [
                        Icon(Icons.block, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Bloquear'),
                      ],
                    ),
                  ),
                if (participant.isBlocked)
                  const PopupMenuItem(
                    value: 'unblock',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Desbloquear'),
                      ],
                    ),
                  ),
                if (widget.chat.isGroup && isAdmin && !isAdminUser)
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Remover do grupo'),
                      ],
                    ),
                  ),
              ],
            )
          : null,
    );
  }

  Widget _buildActionsSection(bool isAdmin) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.settings),
                SizedBox(width: 12),
                Text(
                  'Ações',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (isAdmin)
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text(
                'Excluir Grupo',
                style: TextStyle(color: Colors.red),
              ),
              subtitle: const Text('Esta ação não pode ser desfeita'),
              onTap: () => _showDeleteChatDialog(),
            ),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.orange),
            title: const Text(
              'Sair do Grupo',
              style: TextStyle(color: Colors.orange),
            ),
            subtitle: const Text('Você pode ser readicionado por um admin'),
            onTap: () => _showLeaveGroupDialog(),
          ),
        ],
      ),
    );
  }

  void _handleParticipantAction(String action, ChatParticipant participant) {
    switch (action) {
      case 'block':
        _showBlockUserDialog(participant);
        break;
      case 'unblock':
        _showUnblockUserDialog(participant);
        break;
      case 'remove':
        _showRemoveUserDialog(participant);
        break;
    }
  }

  void _showAddParticipantDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddParticipantDialog(
        chatId: widget.chat.chatId,
        existingParticipantIds: widget.chat.participants.map((p) => p.userId).toList(),
      ),
    );
  }

  void _showBlockUserDialog(ChatParticipant participant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bloquear Usuário'),
        content: Text(
          'Deseja bloquear ${participant.name}? Esta pessoa não poderá enviar mensagens neste chat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => _blockUser(participant.userId),
            child: const Text(
              'Bloquear',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showUnblockUserDialog(ChatParticipant participant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desbloquear Usuário'),
        content: Text(
          'Deseja desbloquear ${participant.name}? Esta pessoa poderá voltar a enviar mensagens.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => _unblockUser(participant.userId),
            child: const Text(
              'Desbloquear',
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  void _showRemoveUserDialog(ChatParticipant participant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover do Grupo'),
        content: Text(
          'Deseja remover ${participant.name} do grupo? Esta pessoa poderá ser readicionada por um admin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => _removeUser(participant.userId),
            child: const Text(
              'Remover',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Grupo'),
        content: const Text(
          'Deseja excluir este grupo? Esta ação não pode ser desfeita e todas as mensagens serão perdidas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => _deleteChat(),
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showLeaveGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair do Grupo'),
        content: const Text(
          'Deseja sair deste grupo? Você poderá ser readicionado por um admin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => _leaveGroup(),
            child: const Text(
              'Sair',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _blockUser(int targetUserId) async {
    Navigator.pop(context);
    setState(() => _isLoading = true);

    try {
      final success = await ref.read(chatListProvider.notifier)
          .blockUser(widget.chat.chatId, targetUserId);
      
      if (success) {
        Navigator.of(context)..pop()..pop();
        
        await ref.read(chatListProvider.notifier).refresh();
        
        _showSuccessSnackBar('Usuário bloqueado com sucesso');
      } else {
        _showErrorSnackBar('Erro ao bloquear usuário');
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao bloquear usuário: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _unblockUser(int targetUserId) async {
    Navigator.pop(context); 
    setState(() => _isLoading = true);

    try {
      final success = await ref.read(chatListProvider.notifier)
          .unblockUser(widget.chat.chatId, targetUserId);
      
      if (success) {
        Navigator.of(context)..pop()..pop();
        
        await ref.read(chatListProvider.notifier).refresh();
        
        _showSuccessSnackBar('Usuário desbloqueado com sucesso');
      } else {
        _showErrorSnackBar('Erro ao desbloquear usuário');
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao desbloquear usuário: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeUser(int userId) async {
    Navigator.pop(context); 
    setState(() => _isLoading = true);

    try {
      final success = await ref.read(chatListProvider.notifier)
          .removeMemberFromGroup(widget.chat.chatId, userId);
      
      if (success) {
        Navigator.of(context)..pop()..pop();
        
        await ref.read(chatListProvider.notifier).refresh();
        
        _showSuccessSnackBar('Usuário removido do grupo');
      } else {
        _showErrorSnackBar('Erro ao remover usuário');
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao remover usuário: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteChat() async {
    Navigator.pop(context); 
    setState(() => _isLoading = true);

    try {
      final success = await ref.read(chatListProvider.notifier)
          .deleteChat(widget.chat.chatId);
      
      if (success) {
        Navigator.of(context)..pop()..pop();
        
        await ref.read(chatListProvider.notifier).refresh();
        
        _showSuccessSnackBar('Grupo excluído com sucesso');
      } else {
        _showErrorSnackBar('Erro ao excluir grupo');
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao excluir grupo: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _leaveGroup() async {
    Navigator.pop(context); 
    final currentUserId = ref.read(currentUserProvider)?.userId;
    if (currentUserId == null) return;

    setState(() => _isLoading = true);

    try {
      final success = await ref.read(chatListProvider.notifier)
          .removeMemberFromGroup(widget.chat.chatId, currentUserId);
      
      if (success) {
        Navigator.of(context)..pop()..pop();
        
        await ref.read(chatListProvider.notifier).refresh();
        
        _showSuccessSnackBar('Você saiu do grupo');
      } else {
        _showErrorSnackBar('Erro ao sair do grupo');
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao sair do grupo: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    
    final words = name.trim().split(' ');
    if (words.length >= 2 && words[0].isNotEmpty && words[1].isNotEmpty) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty && words[0].isNotEmpty) {
      return words[0][0].toUpperCase();
    }
    return '?';
  }
}

class _AddParticipantDialog extends ConsumerStatefulWidget {
  final int chatId;
  final List<int> existingParticipantIds;

  const _AddParticipantDialog({
    required this.chatId,
    required this.existingParticipantIds,
  });

  @override
  ConsumerState<_AddParticipantDialog> createState() => _AddParticipantDialogState();
}

class _AddParticipantDialogState extends ConsumerState<_AddParticipantDialog> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  List<User> _searchResults = [];
  User? _selectedUser;
  bool _isSearching = false;
  bool _isAdding = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar Participante'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Busque um usuário pelo número de telefone para adicionar ao grupo:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _phoneController,
              focusNode: _phoneFocusNode,
              decoration: InputDecoration(
                labelText: 'Número de telefone',
                hintText: 'Ex: (11) 99999-9999',
                prefixIcon: const Icon(Icons.phone),
                suffixIcon: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _searchUsers,
                      ),
                border: const OutlineInputBorder(),
                errorText: _errorMessage,
              ),
              keyboardType: TextInputType.phone,
              onSubmitted: (_) => _searchUsers(),
            ),
            
            const SizedBox(height: 16),
            
            if (_searchResults.isNotEmpty) ...[
              const Text(
                'Usuários encontrados:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    final isExistingParticipant = widget.existingParticipantIds.contains(user.userId);
                    final isSelected = _selectedUser?.userId == user.userId;
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user.avatarUrl != null
                            ? NetworkImage(user.avatarUrl!)
                            : null,
                        child: user.avatarUrl == null
                            ? Text(_getInitials(user.name))
                            : null,
                      ),
                      title: Text(user.name),
                      subtitle: Text(user.phone ?? ''),
                      trailing: isExistingParticipant
                          ? const Chip(
                              label: Text('Já no grupo'),
                              backgroundColor: Colors.grey,
                            )
                          : isSelected
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : null,
                      enabled: !isExistingParticipant,
                      onTap: isExistingParticipant
                          ? null
                          : () => setState(() {
                                _selectedUser = isSelected ? null : user;
                              }),
                      tileColor: isSelected
                          ? Theme.of(context).primaryColor.withOpacity(0.1)
                          : null,
                    );
                  },
                ),
              ),
            ] else if (_phoneController.text.isNotEmpty && !_isSearching) ...[
              const Text(
                'Nenhum usuário encontrado.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
            
            if (_selectedUser != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const Text(
                'Usuário selecionado:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: _selectedUser!.avatarUrl != null
                      ? NetworkImage(_selectedUser!.avatarUrl!)
                      : null,
                  child: _selectedUser!.avatarUrl == null
                      ? Text(_getInitials(_selectedUser!.name))
                      : null,
                ),
                title: Text(_selectedUser!.name),
                subtitle: Text(_selectedUser!.phone ?? ''),
                trailing: const Icon(Icons.check_circle, color: Colors.green),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        if (_selectedUser != null)
          TextButton(
            onPressed: _isAdding ? null : _addParticipant,
            child: _isAdding
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Adicionar'),
          ),
      ],
    );
  }

  Future<void> _searchUsers() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() {
        _errorMessage = 'Digite um número de telefone';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _searchResults = [];
      _selectedUser = null;
    });

    try {
      final chatService = ChatService();
      final users = await chatService.searchUsersByPhone(phone);
      
      setState(() {
        _searchResults = users;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao buscar usuários: $e';
        _isSearching = false;
      });
    }
  }

  Future<void> _addParticipant() async {
    if (_selectedUser == null) return;

    setState(() => _isAdding = true);

    try {
      final userId = _selectedUser!.userId;
      if (userId == null) {
        setState(() {
          _errorMessage = 'Usuário selecionado inválido';
          _isAdding = false;
        });
        return;
      }
      final success = await ref.read(chatListProvider.notifier)
          .addMemberToGroup(widget.chatId, userId);

      if (success) {
        Navigator.pop(context); 
        
        Navigator.of(context)..pop()..pop();
        
        await ref.read(chatListProvider.notifier).refresh();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedUser!.name} foi adicionado ao grupo'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Erro ao adicionar participante';
          _isAdding = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao adicionar participante: $e';
        _isAdding = false;
      });
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    
    final words = name.trim().split(' ');
    if (words.length >= 2 && words[0].isNotEmpty && words[1].isNotEmpty) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty && words[0].isNotEmpty) {
      return words[0][0].toUpperCase();
    }
    return '?';
  }
} 