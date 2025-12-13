import 'dart:typed_data';
import 'package:flutter/material.dart';
import '1pantalla.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; 
import 'buscarpaseador.dart';
import 'calendarioveterinaria.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'iniciarsesion.dart';
import 'mitienda2.dart';
import 'calendarioreservasTienda.dart';
import 'calendariopedidostienda.dart';

class MenuLateralAnimado extends StatefulWidget {
  final VoidCallback onCerrar;
  final int id;


  const MenuLateralAnimado({
    super.key,
    required this.onCerrar,
    required this.id,

  });

  @override
  State<MenuLateralAnimado> createState() => _MenuLateralAnimadoState();
}


class _MenuLateralAnimadoState extends State<MenuLateralAnimado>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;

  List<Map<String, dynamic>> dueno = [];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void cerrarMenu() {
    _controller.reverse().then((_) {
      widget.onCerrar(); // 👈 ahora funciona correctamente
    });
  }


  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.7,
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 247, 242, 239),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado centrado con ícono de menú a la derecha
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/Logo_Tienda_de_Accesorios_para_Mascotas_Alegre_Café_y_Rosa-removebg-preview.png',
                            width: 60,
                            height: 60,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Huellitas",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Image.asset('assets/Menu.png', width: 24, height: 24),
                      onPressed: cerrarMenu,
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Items del menú
                _menuItem("Inicio", 'assets/casa.png', () {
                  if (dueno.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PerfilTiendaScreen(idtienda: widget.id)
                      ),
                    );
                  } else {
                    // Opcional: mostrar un mensaje de espera o error
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("❌ Usuario no cargado todavía")),
                    );
                  }
                }),
                _menuItem("Pedidos", 'assets/bolso.png', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CalendarioTiendaScreen(
                        id_tienda: widget.id,
                      ),
                    ),
                  );
                }),
                _menuItem("Reservas", 'assets/reserva.png', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CalendarioReservasScreen(
                        id_tienda: widget.id,
                      ),
                    ),
                  );
                }),
            
                const SizedBox(height: 20),
                Divider(color: Colors.grey),
                const SizedBox(height: 10),
                _menuItem("Soporte", 'assets/soporte.png', () {
                  Navigator.pushNamed(context, "/pedidos");
                }),
                _menuItem("Cerrar sesión", 'assets/cerrar-sesion.png', () {
                  cerrarSesion(context);
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuItem(String texto, String icono, Function()? onTap) {
    return ListTile(
      leading: Image.asset(icono, width: 25, height: 25),
      title: Text(texto),
      onTap: onTap,   // 👈 aquí pasa lo que ejecutarás
    );
  }

  Future<void> cerrarSesion(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    // Borramos toda la información de sesión
    await prefs.remove('logueado');
    await prefs.remove('idUsuario');
    await prefs.remove('idVeterinaria');
    await prefs.remove('idTienda');
    await prefs.remove('idPaseador');

    // Redirigimos al login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }
}
