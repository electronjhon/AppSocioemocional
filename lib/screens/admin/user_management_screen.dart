import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../widgets/gradient_background.dart';
import 'edit_user_screen.dart';

class UserManagementScreen extends StatefulWidget {
  final AuthService authService;
  final AppUser? user; // Si se pasa un usuario específico, se muestra solo ese
  
  const UserManagementScreen({
    super.key,
    required this.authService,
    this.user,
  });

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<AppUser> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterRole = 'todos';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.user != null) {
        _users = [widget.user!];
      } else {
        _users = await widget.authService.getAllUsers();
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar usuarios: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<AppUser> get _filteredUsers {
    return _users.where((user) {
      final matchesSearch = user.firstName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           user.lastName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           user.documentId.contains(_searchQuery) ||
                           user.email.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesRole = _filterRole == 'todos' || user.role == _filterRole;
      
      return matchesSearch && matchesRole;
    }).toList();
  }

  Future<void> _deleteUser(AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Usuario'),
        content: Text('¿Estás seguro de que quieres eliminar a ${user.firstName} ${user.lastName}?\n\nEsta acción eliminará al usuario y todos sus datos de emociones.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await widget.authService.deleteUser(user.uid);
        if (mounted) {
          if (success) {
            setState(() {
              _users.removeWhere((u) => u.uid == user.uid);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Usuario eliminado correctamente'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error al eliminar usuario'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteUserEmotions(AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Emociones'),
        content: Text('¿Estás seguro de que quieres eliminar todas las emociones de ${user.firstName} ${user.lastName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await widget.authService.deleteUserEmotions(user.uid);
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Emociones eliminadas correctamente'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error al eliminar emociones'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user != null ? 'Detalles del Usuario' : 'Gestión de Usuarios'),
        backgroundColor: const Color(0xFF00BCD4),
        foregroundColor: Colors.white,
        actions: [
          if (widget.user == null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadUsers,
            ),
        ],
      ),
      body: GradientBackground(
        child: Column(
          children: [
            // Filtros y búsqueda
            if (widget.user == null) ...[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Búsqueda
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Buscar usuarios...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    // Filtro por rol
                    Row(
                      children: [
                        const Text('Filtrar por rol: '),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _filterRole,
                          items: const [
                            DropdownMenuItem(value: 'todos', child: Text('Todos')),
                            DropdownMenuItem(value: 'estudiante', child: Text('Estudiantes')),
                            DropdownMenuItem(value: 'docente', child: Text('Docentes')),
                            DropdownMenuItem(value: 'administrador', child: Text('Administradores')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _filterRole = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            
            // Lista de usuarios
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredUsers.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No se encontraron usuarios',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 4,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getRoleColor(user.role),
                                  child: Text(
                                    '${user.firstName[0]}${user.lastName[0]}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  '${user.firstName} ${user.lastName}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${user.role.toUpperCase()} - ${user.course}'),
                                    Text('Doc: ${user.documentId}'),
                                    Text(user.email),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    switch (value) {
                                      case 'edit':
                                        final updated = await Navigator.of(context).push<bool>(
                                          MaterialPageRoute(
                                            builder: (_) => EditUserScreen(
                                              user: user,
                                              authService: widget.authService,
                                            ),
                                          ),
                                        );
                                        if (updated == true) {
                                          _loadUsers();
                                        }
                                        break;
                                      case 'delete_emotions':
                                        _deleteUserEmotions(user);
                                        break;
                                      case 'delete_user':
                                        _deleteUser(user);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, color: Colors.blue),
                                          SizedBox(width: 8),
                                          Text('Editar'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete_emotions',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_sweep, color: Colors.orange),
                                          SizedBox(width: 8),
                                          Text('Eliminar Emociones'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete_user',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_forever, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Eliminar Usuario'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'administrador':
        return Colors.red;
      case 'docente':
        return Colors.blue;
      case 'estudiante':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
