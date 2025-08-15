import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';
import '../widgets/gradient_background.dart';
import '../widgets/school_logo.dart';

const avatarAssets = [
  'assets/avatars/avatar1.svg',
  'assets/avatars/avatar2.svg',
  'assets/avatars/avatar3.svg',
];

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _documentController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _courseController = TextEditingController();
  String _role = 'estudiante';
  String _selectedAvatar = avatarAssets.first;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _documentController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService().registerWithEmail(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        documentId: _documentController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: _role,
        course: _courseController.text.trim(),
        avatarAsset: _selectedAvatar,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro'),
        centerTitle: true,
      ),
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 20),
                const SchoolLogo(size: 80.0),
                const SizedBox(height: 16),
                const Text(
                  'Institución Educativa Departamental\nPbro. Carlos Garavito A.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Apellido'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _documentController,
                  decoration: const InputDecoration(
                    labelText: 'Documento',
                    hintText: 'Ej: 12345678',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'El documento es requerido';
                    }
                    if (v.length < 8) {
                      return 'El documento debe tener al menos 8 dígitos';
                    }
                    if (!RegExp(r'^\d+$').hasMatch(v)) {
                      return 'El documento solo debe contener números';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo',
                    hintText: 'ejemplo@correo.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'El correo es requerido';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                      return 'Ingrese un correo válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    hintText: 'Mínimo 6 caracteres',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'La contraseña es requerida';
                    }
                    if (v.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(v)) {
                      return 'La contraseña debe contener letras y números';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Contraseña',
                    hintText: 'Repita la contraseña',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Confirme la contraseña';
                    }
                    if (v != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _courseController,
                  decoration: const InputDecoration(labelText: 'Curso'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                const Text('Rol'),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Estudiante'),
                        value: 'estudiante',
                        groupValue: _role,
                        onChanged: (v) => setState(() => _role = v!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Docente'),
                        value: 'docente',
                        groupValue: _role,
                        onChanged: (v) => setState(() => _role = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Escoge un avatar'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (_, i) {
                      final asset = avatarAssets[i];
                      final selected = asset == _selectedAvatar;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedAvatar = asset),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: selected ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                            border: Border.all(color: selected ? Colors.blue : Colors.white70),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: SvgPicture.asset(asset, width: 72, height: 72),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemCount: avatarAssets.length,
                  ),
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Registrar'),
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