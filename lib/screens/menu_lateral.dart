import 'package:flutter/material.dart';

class MenuLateralAnimado extends StatefulWidget {
  final VoidCallback onCerrar; // 👈 Mover aquí la propiedad

  const MenuLateralAnimado({
    super.key,
    required this.onCerrar, // 👈 Añadir al constructor
  });

  @override
  State<MenuLateralAnimado> createState() => _MenuLateralAnimadoState();
}

class _MenuLateralAnimadoState extends State<MenuLateralAnimado>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

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

                // Opciones del menú
                _menuItem("Inicio", 'assets/casa.png'),
                _menuItem("Mascotas", 'assets/mascotas.png'),
                _menuItem("Tiendas", 'assets/Insumos.png'),
                _menuItem("Mis pedidos", 'assets/bolso.png'),
                _menuItem("Veterinarias", 'assets/Medico.png'),
                _menuItem("Mis citas", 'assets/citas.png'),
                _menuItem("Paseadores", 'assets/paseador.png'),
                _menuItem("Paseos programados", 'assets/paisaje.png'),
                _menuItem("Configuración", 'assets/engranaje.png'),

                const SizedBox(height: 20),
                Divider(color: Colors.grey),
                const SizedBox(height: 10),

                _menuItem("Soporte", 'assets/soporte.png'),
                _menuItem("Cerrar sesión", 'assets/cerrarsesion.png'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuItem(String label, String iconPath) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Image.asset(iconPath, width: 24, height: 24),
        title: Text(label),
        onTap: cerrarMenu,
      ),
    );
  }
}
