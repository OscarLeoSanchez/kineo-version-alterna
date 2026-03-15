import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../data/services/auth_api_service.dart';
import '../../data/services/auth_session_controller.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isRegisterMode = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      const api = AuthApiService();
      final authController = AuthSessionScope.of(context);

      final session = _isRegisterMode
          ? await api.register(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              fullName: _nameController.text.trim(),
            )
          : await api.login(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );

      await authController.setSession(session);
      if (!mounted) return;
      if (_isRegisterMode) {
        Navigator.of(context).pushNamedAndRemoveUntil('/onboarding', (route) => false);
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _checkConnection() async {
    try {
      final message = await const AuthApiService().checkApiConnection();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF6F1E8), Color(0xFFE1ECDF), Color(0xFFD8D0C4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF163A37),
                      borderRadius: BorderRadius.circular(36),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kineo Coach',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Un sistema que adapta entrenamiento, nutricion y ritmo de trabajo a tu dia real.',
                          style: TextStyle(color: Colors.white70, height: 1.45),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isRegisterMode
                                ? 'Crea tu cuenta'
                                : 'Bienvenido de nuevo',
                            style: theme.textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _isRegisterMode
                                ? 'Te dejaremos listo para construir tu primer plan adaptativo.'
                                : 'Entra y sigue con el sistema que dejaste configurado.',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F0E8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFDBD3C5)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'API actual',
                                  style: theme.textTheme.labelLarge,
                                ),
                                const SizedBox(height: 4),
                                SelectableText(
                                  AppConfig.apiBaseUrl,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                if (_isRegisterMode)
                                  _buildField(
                                    _nameController,
                                    'Nombre completo',
                                  ),
                                if (_isRegisterMode) const SizedBox(height: 16),
                                _buildField(_emailController, 'Email'),
                                const SizedBox(height: 16),
                                _buildField(
                                  _passwordController,
                                  'Contrasena',
                                  obscureText: true,
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: _isSubmitting ? null : _submit,
                                    child: Text(
                                      _isSubmitting
                                          ? 'Procesando...'
                                          : _isRegisterMode
                                          ? 'Crear cuenta'
                                          : 'Ingresar',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: _isSubmitting
                                      ? null
                                      : () {
                                          setState(() {
                                            _isRegisterMode = !_isRegisterMode;
                                          });
                                        },
                                  child: Text(
                                    _isRegisterMode
                                        ? 'Ya tengo cuenta'
                                        : 'Crear una cuenta nueva',
                                  ),
                                ),
                                TextButton(
                                  onPressed: _isSubmitting ? null : _checkConnection,
                                  child: const Text('Probar conexion API'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Este campo es obligatorio';
        }
        if (label == 'Email' && !value.contains('@')) {
          return 'Ingresa un correo valido';
        }
        if (label == 'Contrasena' && value.length < 8) {
          return 'Usa al menos 8 caracteres';
        }
        if (label == 'Nombre completo' && value.trim().length < 2) {
          return 'Ingresa al menos 2 caracteres';
        }
        return null;
      },
      decoration: InputDecoration(labelText: label),
    );
  }
}
