import 'package:flutter/material.dart';
import 'dart:ui';

class NotifiMascotaScreen extends StatefulWidget {
  const NotifiMascotaScreen({super.key});

  @override
  State<NotifiMascotaScreen> createState() => _NotifiMascotaScreenState();
}

class _NotifiMascotaScreenState extends State<NotifiMascotaScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(187, 255, 255, 255),
        onPressed: () {
          // TODO: Acción de chat
        },
        child: Image.asset('assets/inteligent.png', width: 36, height: 36),
      ),
      body: Stack(
        children: [
          // Fondo
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/hut-9582608_1280.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Difuminado
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),

          // Contenido
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado con íconos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Image.asset('assets/Menu.png', width: 24, height: 24),
                        onPressed: () {},
                      ),
                      Row(
                        children: [
                          Image.asset('assets/Calendr.png', width: 24, height: 24),
                          const SizedBox(width: 10),
                          Image.asset('assets/Campana.png', width: 24, height: 24),
                          const SizedBox(width: 10),
                          Image.asset('assets/Perfil.png', width: 24, height: 24),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Flecha de regreso
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

                  // Título
                  const Center(
                    child: Text(
                      "Mis notificaciones",
                      style: TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tarjeta blanca contenedora
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(187, 255, 255, 255),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black26)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                
                        // Tarjeta morada de notificación
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 221, 143, 254), // color
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color.fromARGB(255, 131, 123, 99), width: 2),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🐶 Imagen circular de la mascota
                            ClipOval(
                              child: Image.asset(
                                "assets/Lara.jpeg",
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // 📄 Texto y botón
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Lara",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "Sofía Navarro te envió una solicitud para compartir mascota",
                                    style: TextStyle(fontSize: 16, color: Color.fromARGB(255, 19, 19, 19)),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          // TODO: Acción al ver detalles
                                        },
                                        icon: Image.asset(
                                          'assets/informacion.png',
                                          width: 20,
                                          height: 20,
                                        ),
                                        label: const Text("Ver detalles"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                                          foregroundColor: const Color.fromARGB(255, 112, 72, 121),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                                            ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}