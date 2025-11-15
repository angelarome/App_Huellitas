import 'package:flutter/material.dart';
import 'inicial2.dart'; // 👈 importa tu pantalla real aquí

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();

    // Controlador de animación (duración 2 segundos)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Movimiento de arriba hacia el centro
    _animation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _irASiguientePantalla() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const BienvenidaMascotasScreen(), // 👈 usa tu pantalla aquí
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _irASiguientePantalla, // 👉 toca en cualquier parte o el logo
        child: Stack(
          children: [
            // Fondo completo
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/inicio.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Capa de oscurecimiento suave
            Container(color: Colors.black.withOpacity(0.3)),

            // Logo animado que baja desde arriba
            Center(
              child: SlideTransition(
                position: _animation,
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/Logo_Tienda_de_Accesorios_para_Mascotas_Alegre_Café_y_Rosa-removebg-preview.png"),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
