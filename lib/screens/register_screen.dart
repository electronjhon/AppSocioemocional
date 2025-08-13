import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';
import '../widgets/gradient_background.dart';

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
  final _courseController = TextEditingController();
  String _role = 'estudiante';
  String _selectedAvatar = avatarAssets.first;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _documentController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
      appBar: AppBar(title: const Text('Registro')),
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
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
                  decoration: const InputDecoration(labelText: 'Documento'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Correo'),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Correo inválido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  obscureText: true,
                  validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
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