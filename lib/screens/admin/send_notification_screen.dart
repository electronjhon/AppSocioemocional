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
  bool _loading = false;
  bool _isSpecificUser = false;

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
      });
    } catch (e) {
      print('Error cargando usuarios: $e');
    }
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
                            const Text('Enviar a usuario específico'),
                          ],
                        ),
                        
                        if (_isSpecificUser) ...[
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedSpecificUser,
                            decoration: const InputDecoration(
                              labelText: 'Seleccionar usuario',
                              border: OutlineInputBorder(),
                            ),
                            items: _availableUsers.map((user) {
                              return DropdownMenuItem(
                                value: user.uid,
                                child: Text('${user.firstName} ${user.lastName} - ${user.course}'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedSpecificUser = value;
                              });
                            },
                            validator: _isSpecificUser ? (value) {
                              if (value == null) {
                                return 'Selecciona un usuario';
                              }
                              return null;
                            } : null,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Botón de envío
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _sendNotification,
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
