import 'package:flutter/material.dart';
import 'dart:ui';
import 'inicial3.dart';
import 'pantalla_inicio.dart';

class BienvenidaMascotasScreen extends StatelessWidget {
  const BienvenidaMascotasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🌄 Imagen de fondo
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/inicio.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 🌫️ Filtro borroso
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),

          // 🧩 Contenido principal centrado verticalmente
          SafeArea(
            child: Stack(
              children: [
                // 🔘 Botón "Omitir" en la parte superior derecha
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16, right: 16),
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SplashScreen()),
                        );
                      },
                      icon: Image.asset(
                        'assets/omitir2.png', 
                        width: 20,
                        height: 20,
                      ),
                      label: const Text(
                        "Omitir",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ),
                
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 📝 Título principal más grande
                        const Text(
                          "Agrega mascotas, tiendas y servicios",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30, // Aumentado
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // 🟦 Cuadro blanco más ancho y centrado
                        Container(
                          width: MediaQuery.of(context).size.width * 0.95,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black26)],
                          ),
                          child: Column(
                            children: [
                              Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    "assets/inicial2.jpg",
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: -20, // sobresale hacia el recuadro blanco
                                  left: -10,   // esquina inferior derecha
                                  child: Image.asset(
                                    "assets/huellitas.png", // tu ícono (por ejemplo, una huella)
                                    width: 90,
                                    height: 90,
                                  ),
                                ),
                              ],
                            ),
                              const SizedBox(height: 16),
                              const Text(
                                "Crea tu perfil y organiza tus mascotas y servicios en un solo lugar.",
                                style: TextStyle(fontSize: 16, color: Colors.black87),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // 👉 Botón blanco con texto blanco y borde negro
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.6,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ComidapaseoMascotasScreen(), 
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.black, width: 1.5),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Texto negro detrás (borde)
                                Text(
                                  "Siguiente",
                                  style: TextStyle(
                                    fontSize: 24, // tamaño del texto
                                    fontWeight: FontWeight.w500,
                                    foreground: Paint()
                                      ..style = PaintingStyle.stroke
                                      ..strokeWidth = 1.5
                                      ..color = Colors.black,
                                  ),
                                ),
                                // Texto blanco encima
                                Text(
                                  "Siguiente",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}