import 'dart:ui';
import 'package:flutter/material.dart';
import 'rol.dart';
import 'iniciarsesion.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo con imagen
          Image.asset(
            'assets/inicio.png',
            fit: BoxFit.cover,
          ),

          // Desenfoque suave del fondo
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),

          // Contenido principal
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset(
                'assets/Logo_Tienda_de_Accesorios_para_Mascotas_Alegre_Café_y_Rosa-removebg-preview.png',
                width: 280,
                height: 280,
              ),
              const SizedBox(height: 50),

              // Botón Iniciar sesión
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                },
                icon: const Icon(
                  Icons.login,
                  color: Colors.white,
                  size: 32, // ícono más grande
                ),
                label: const Text(
                  'Iniciar sesión',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    shadows: [
                      Shadow(
                        offset: Offset(1.5, 1.5),
                        color: Colors.black,
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  elevation: 6,
                ),
              ),

              const SizedBox(height: 25),


              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Rol1Screen()),
                  );
                },
                icon: const Icon(
                  Icons.person_add,
                  color: Colors.white,
                  size: 32, 
                ),
                label: const Text(
                  'Registrarse',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    shadows: [
                      Shadow(
                        offset: Offset(1.5, 1.5),
                        color: Colors.black,
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  elevation: 6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
