import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_user.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/gradient_background.dart';
import '../../providers/session_provider.dart';

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _urlController = TextEditingController();
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  
  List<String> _selectedRoles = ['estudiante'];
  List<String> _selectedCourses = [];
  List<String> _availableCourses = [];
  String? _selectedSpecificUser;
  List<AppUser> _availableUsers = [];
  List<AppUser> _filteredUsers = [];
  bool _loading = false;
  bool _isSpecificUser = false;
  
  // Filtros para estudiantes
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilterCourse = 'Todos';
  String _selectedFilterDocument = '';

  @override
  void initState() {
    super.initState();
    _loadAvailableCourses();
    _loadAvailableUsers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _urlController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableCourses() async {
    try {
      final users = await _authService.getAllUsers();
      final courses = users
          .where((user) => user.role == 'estudiante')
          .map((user) => user.course)
          .toSet()
          .toList();
      
      setState(() {
        _availableCourses = courses;
      });
    } catch (e) {
      print('Error cargando cursos: $e');
    }
  }

  Future<void> _loadAvailableUsers() async {
    try {
      final users = await _authService.getAllUsers();
      setState(() {
        _availableUsers = users.where((user) => user.role == 'estudiante').toList();
        _filteredUsers = List.from(_availableUsers);
      });
    } catch (e) {
      print('Error cargando usuarios: $e');
    }
  }

  void _filterUsers() {
    setState(() {
      _filteredUsers = _availableUsers.where((user) {
        // Filtro por búsqueda de texto (nombre, apellido o documento)
        bool matchesSearch = _searchController.text.isEmpty ||
            user.firstName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            user.lastName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            user.documentId.contains(_searchController.text);
        
        // Filtro por curso
        bool matchesCourse = _selectedFilterCourse == 'Todos' || 
            user.course == _selectedFilterCourse;
        
        // Filtro por documento
        bool matchesDocument = _selectedFilterDocument.isEmpty ||
            user.documentId.contains(_selectedFilterDocument);
        
        return matchesSearch && matchesCourse && matchesDocument;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedFilterCourse = 'Todos';
      _selectedFilterDocument = '';
      _filteredUsers = List.from(_availableUsers);
    });
  }

  AppUser? get selectedUser {
    if (_selectedSpecificUser == null) return null;
    return _availableUsers.firstWhere(
      (user) => user.uid == _selectedSpecificUser,
      orElse: () => _availableUsers.first,
    );
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
    });

    try {
      final session = context.read<SessionProvider>();
      final currentUser = session.profile;
      
      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }

      print('Enviando notificación desde: ${currentUser.uid} - ${currentUser.firstName} ${currentUser.lastName}');

             final success = await _notificationService.sendNotification(
         title: _titleController.text.trim(),
         message: _messageController.text.trim(),
         url: _urlController.text.trim().isNotEmpty ? _urlController.text.trim() : null,
         senderUid: currentUser.uid,
         senderName: '${currentUser.firstName} ${currentUser.lastName}',
         targetRoles: _selectedRoles,
         targetCourses: _selectedCourses,
         specificRecipientUid: _isSpecificUser ? _selectedSpecificUser : null,
       );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notificación enviada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al enviar la notificación'),
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
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enviar Píldora'),
        backgroundColor: const Color(0xFF00BCD4),
        foregroundColor: Colors.white,
      ),
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nueva Píldora',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00BCD4),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Título de la píldora',
                            hintText: 'Ej: Recordatorio importante',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El título es requerido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                                                 TextFormField(
                           controller: _messageController,
                           decoration: const InputDecoration(
                             labelText: 'Mensaje',
                             hintText: 'Escribe el contenido de la píldora...',
                             border: OutlineInputBorder(),
                           ),
                           maxLines: 4,
                           validator: (value) {
                             if (value == null || value.trim().isEmpty) {
                               return 'El mensaje es requerido';
                             }
                             return null;
                           },
                         ),
                         const SizedBox(height: 16),
                         TextFormField(
                           controller: _urlController,
                           decoration: const InputDecoration(
                             labelText: 'URL (opcional)',
                             hintText: 'https://ejemplo.com',
                             border: OutlineInputBorder(),
                             prefixIcon: Icon(Icons.link),
                           ),
                           keyboardType: TextInputType.url,
                           validator: (value) {
                             if (value != null && value.trim().isNotEmpty) {
                               final urlPattern = RegExp(
                                 r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
                               );
                               if (!urlPattern.hasMatch(value.trim())) {
                                 return 'Ingresa una URL válida';
                               }
                             }
                             return null;
                           },
                         ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Configuración de destinatarios
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Destinatarios',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Roles objetivo
                        const Text(
                          'Roles objetivo:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            FilterChip(
                              label: const Text('Estudiantes'),
                              selected: _selectedRoles.contains('estudiante'),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedRoles.add('estudiante');
                                  } else {
                                    _selectedRoles.remove('estudiante');
                                  }
                                });
                              },
                            ),
                            FilterChip(
                              label: const Text('Docentes'),
                              selected: _selectedRoles.contains('docente'),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedRoles.add('docente');
                                  } else {
                                    _selectedRoles.remove('docente');
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Cursos específicos
                        if (_availableCourses.isNotEmpty) ...[
                          const Text(
                            'Cursos específicos (opcional):',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: _availableCourses.map((course) {
                              return FilterChip(
                                label: Text(course),
                                selected: _selectedCourses.contains(course),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedCourses.add(course);
                                    } else {
                                      _selectedCourses.remove(course);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedCourses.isEmpty 
                                ? 'Se enviará a todos los cursos'
                                : 'Se enviará solo a: ${_selectedCourses.join(', ')}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 16),
                        
                        // Usuario específico
                        Row(
                          children: [
                            Checkbox(
                              value: _isSpecificUser,
                              onChanged: (value) {
                                setState(() {
                                  _isSpecificUser = value ?? false;
                                  if (!_isSpecificUser) {
                                    _selectedSpecificUser = null;
                                  }
                                });
                              },
                            ),
                            const Text('Enviar a estudiante específico'),
                          ],
                        ),
                        
                        if (_isSpecificUser) ...[
                          const SizedBox(height: 16),
                          
                          // Filtros de búsqueda
                          Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Filtros de búsqueda',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  // Campo de búsqueda
                                  TextFormField(
                                    controller: _searchController,
                                    decoration: const InputDecoration(
                                      labelText: 'Buscar por nombre o documento',
                                      hintText: 'Escribe para buscar...',
                                      prefixIcon: Icon(Icons.search),
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (value) => _filterUsers(),
                                  ),
                                  
                                  const SizedBox(height: 12),
                                  
                                  // Filtro por curso
                                  DropdownButtonFormField<String>(
                                    value: _selectedFilterCourse,
                                    decoration: const InputDecoration(
                                      labelText: 'Filtrar por curso',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: [
                                      const DropdownMenuItem(
                                        value: 'Todos',
                                        child: Text('Todos los cursos'),
                                      ),
                                      ..._availableCourses.map((course) {
                                        return DropdownMenuItem(
                                          value: course,
                                          child: Text(course),
                                        );
                                      }).toList(),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedFilterCourse = value!;
                                        _filterUsers();
                                      });
                                    },
                                  ),
                                  
                                  const SizedBox(height: 12),
                                  
                                                                     // Filtro por documento
                                   TextFormField(
                                     decoration: const InputDecoration(
                                       labelText: 'Filtrar por documento',
                                       hintText: 'Número de documento',
                                       prefixIcon: Icon(Icons.badge),
                                       border: OutlineInputBorder(),
                                     ),
                                     onChanged: (value) {
                                       setState(() {
                                         _selectedFilterDocument = value;
                                         _filterUsers();
                                       });
                                     },
                                   ),
                                   
                                   const SizedBox(height: 12),
                                   
                                   // Botón para limpiar filtros
                                   SizedBox(
                                     width: double.infinity,
                                     child: OutlinedButton.icon(
                                       onPressed: _clearFilters,
                                       icon: const Icon(Icons.clear),
                                       label: const Text('Limpiar filtros'),
                                       style: OutlinedButton.styleFrom(
                                         foregroundColor: Colors.grey,
                                       ),
                                     ),
                                   ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Lista de estudiantes filtrados
                          if (_filteredUsers.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Estudiantes encontrados:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00BCD4),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_filteredUsers.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListView.builder(
                                itemCount: _filteredUsers.length,
                                itemBuilder: (context, index) {
                                  final user = _filteredUsers[index];
                                  final isSelected = _selectedSpecificUser == user.uid;
                                  
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isSelected 
                                          ? const Color(0xFF00BCD4) 
                                          : Colors.grey.shade300,
                                      child: Text(
                                        '${user.firstName[0]}${user.lastName[0]}',
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.grey.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      '${user.firstName} ${user.lastName}',
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                    subtitle: Text('Doc: ${user.documentId} - ${user.course}'),
                                    trailing: isSelected 
                                        ? const Icon(Icons.check_circle, color: Color(0xFF00BCD4))
                                        : null,
                                    onTap: () {
                                      setState(() {
                                        _selectedSpecificUser = user.uid;
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ] else ...[
                            const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  'No se encontraron estudiantes con los filtros aplicados',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          
                          // Card del estudiante seleccionado
                          if (selectedUser != null) ...[
                            const SizedBox(height: 16),
                            Card(
                              elevation: 4,
                              color: const Color(0xFF00BCD4).withOpacity(0.1),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.person,
                                          color: Color(0xFF00BCD4),
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Estudiante Seleccionado',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color(0xFF00BCD4),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 30,
                                          backgroundColor: const Color(0xFF00BCD4),
                                          child: Text(
                                            '${selectedUser!.firstName[0]}${selectedUser!.lastName[0]}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${selectedUser!.firstName} ${selectedUser!.lastName}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Documento: ${selectedUser!.documentId}',
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              Text(
                                                'Curso: ${selectedUser!.course}',
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              Text(
                                                'Email: ${selectedUser!.email}',
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Mensaje de validación
                if (_isSpecificUser && _selectedSpecificUser == null) ...[
                  Card(
                    color: Colors.orange.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Debes seleccionar un estudiante para enviar la píldora',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Botón de envío
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_loading || (_isSpecificUser && _selectedSpecificUser == null)) 
                        ? null 
                        : _sendNotification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BCD4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Enviar Píldora',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
