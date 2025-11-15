import 'package:flutter/material.dart';
import 'dart:ui'; // Para aplicar desenfoque si lo necesitas más adelante

class listvaciacompartirScreen extends StatelessWidget {
  const listvaciacompartirScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Botón flotante de chat
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () {
          // TODO: Acción de chat
        },
        child: Image.asset('assets/inteligent.png', width: 36, height: 36), // Icono de la IA , fit: BoxFit.contain
      ),

      body: Stack(
        children: [
          // 🌄 Imagen de fondo
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/hut-9582608_1280.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),

          // 🕶️ Capa oscura para contraste
          Container(
            color: Colors.black.withOpacity(0.3),
          ),

          // 🧱 Contenido principal
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: SizedBox(width: 24,height: 24, child: Image.asset('assets/Menu.png'),
                        ),
                        onPressed: () {},
                      ),
                      Row(
                        children: [
                          SizedBox(width: 24,height: 24, child: Image.asset('assets/Perfil.png'),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(width: 24,height: 24, child: Image.asset('assets/Calendr.png'),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(width: 24,height: 24, child: Image.asset('assets/Campana.png'),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 🔙 Ícono flecha debajo del menú
                  Row(
                    children: [
                      Image.asset(
                        'assets/flecha-izquierda 1.png',
                        width: 30,
                        height: 30,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 🐾 Título centrado
                  const Center(
                    child: Text(
                      "Solicitudes enviadas",
                      style: TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 🗃 Contenedor blanco centrado
                  Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      height: 350, // tamaño targeta blanca
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(235, 233, 222, 218), // color de la targeta blanca
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black26)],
                      ),
                      child: Column(
                        children: [
                          Image.asset(
                            "assets/grupo.png",
                            height: 150, // altura de imagen grupo
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.error, size: 80, color: Colors.red);
                            },
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Aún no has enviado ninguna solicitud para compartir mascota.",
                            style: TextStyle(fontSize: 18, color: Colors.black),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ✅ Botón fuera del recuadro blanco
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Navegar a pantalla de añadir mascota
                      },
                      icon: const Icon(Icons.add),
                      label: const Text("Enviar solicitud"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(235, 233, 222, 218), // color del boton
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}