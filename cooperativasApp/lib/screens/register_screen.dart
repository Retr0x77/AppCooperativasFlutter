//archivo register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_service.dart';

class RegisterScreen extends StatelessWidget {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Clave para el formulario

  Future<void> _register(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      // Validar el formulario
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.register(
        _emailController.text,
        _passwordController.text,
        _nameController.text,
      );

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Registro completo. Ahora puedes iniciar sesión.')),
      );

      // Redirigir a la pantalla de inicio de sesión
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade300, Colors.blue.shade700],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  // Usar un formulario
                  key: _formKey, // Asignar la clave al formulario
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Registro",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        // Cambiar a TextFormField
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: "Nombre",
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu nombre';
                          }
                          return null; // Sin errores
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        // Cambiar a TextFormField
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: "Correo electrónico",
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu correo electrónico';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Por favor ingresa un correo electrónico válido';
                          }
                          return null; // Sin errores
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        // Cambiar a TextFormField
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: "Contraseña",
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu contraseña';
                          }
                          if (value.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          return null; // Sin errores
                        },
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => _register(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          "Registrarse",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
