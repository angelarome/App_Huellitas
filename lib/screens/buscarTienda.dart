import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:http/http.dart' as http; 
import 'dart:convert';  
import 'package:flutter/foundation.dart' show kIsWeb;
import 'tiendas.dart';

class TiendaMascotaScreen extends StatefulWidget {
  final int id_dueno;

  const TiendaMascotaScreen({super.key, required this.id_dueno});

  @override
  State<TiendaMascotaScreen> createState() => _TiendaMascotaScreenState();
}

class _TiendaMascotaScreenState extends State<TiendaMascotaScreen> {
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> _tienda = [];
  List<dynamic> tiendasFiltradas = [];
  bool _cargando = true;
  
  @override
  void initState() {
    super.initState();
    _obtenerTienda(); // Llamamos a la API apenas se abre la pantalla
  }


  Future<void> _obtenerTienda() async {
    final url = Uri.parse("http://localhost:5000/tiendas"); // 👈 misma ruta del backend
    final response = await http.get(url); // 👈 usar GET, no POST

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List tiendaJson = data["tienda"] ?? [];

      setState(() {
        _tienda = tiendaJson.map<Map<String, dynamic>>((m) {
          final tiendaMap = Map<String, dynamic>.from(m);

          // 👇 Si la imagen está en base64
          if (tiendaMap["imagen"] != null && tiendaMap["imagen"].isNotEmpty) {
            try {
              tiendaMap["foto"] = base64Decode(tiendaMap["imagen"]);
            } catch (e) {
              print("❌ Error decodificando imagen: $e");
              tiendaMap["foto"] = null;
            }
          } else {
            tiendaMap["foto"] = null;
          }

          return tiendaMap;
        }).toList();
      });
    } else {
      print("❌ Error al obtener tiendas: ${response.statusCode}");
    }
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 81, 68, 46),
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
                image: AssetImage("assets/Tienda.jpeg"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Difuminado
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),

          // Contenido
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Encabezado con íconos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Columna de menú y devolver
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () {},
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: Image.asset('assets/Menu.png'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {},
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: Image.asset('assets/devolver5.png'),
                            ),
                          ),
                        ],
                      ),

                      // Fila de íconos perfil, calendario y campana
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {},
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: Image.asset('assets/Perfil.png'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {},
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: Image.asset('assets/Calendr.png'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {},
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: Image.asset('assets/Campana3.png'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Título centrado
                  const Center(
                    child: Text(
                      "Tienda",
                      style: TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Contenido desplazable
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tarjeta blanca contenedora
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(187, 255, 255, 255),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(blurRadius: 6, color: Colors.black26)
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Barra de búsqueda
                                Row(
                                  children: [
                                    Image.asset(
                                      'assets/iconotienda.png',
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.contain,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.9),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          children: const [
                                            Expanded(
                                              child: TextField(
                                                decoration: InputDecoration(
                                                  hintText: "Buscar tienda",
                                                  border: InputBorder.none,
                                                ),
                                              ),
                                            ),
                                            Icon(Icons.search),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // Tarjeta café "Mis pedidos"
                                Container(
                                  height: 100,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                        255, 163, 145, 124),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color.fromARGB(
                                          255, 131, 123, 99),
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.asset(
                                          "assets/Calendario.png",
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      const Expanded(
                                        child: Text(
                                          "Mis pedidos",
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 20),

                                _tarjetaComentarios(),

                                const SizedBox(height: 30),
                                // Botón "Mis reservas"
                                Center(
                                  child: ElevatedButton.icon(
                                    onPressed: () {},
                                    icon: Image.asset('assets/estrella.png',
                                        width: 20, height: 20),
                                    label: const Text(
                                      "Mis reservas",
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(
                                          255, 163, 145, 124),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 30),
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
        ],
      ),
    );
  }


Widget _tarjetaComentarios() {
  if (_tienda.isEmpty) {
    return const Center(
      child: Text(
        "No hay tiendas disponibles",
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  return Column(
    children: _tienda.map<Widget>((tienda) {
      final String nombre = tienda['nombre_negocio'] ?? 'Sin nombre';
      final String direccion = tienda['direccion'] ?? 'Sin dirección';
      final String telefono = tienda['telefono']?.toString() ?? 'No disponible';
      final String? imagenBase64 = tienda['imagen']; // ✅ campo correcto del backend

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:  const Color.fromARGB(255, 241, 110, 154),
          border: Border.all(
            color: const Color.fromARGB(255, 247, 84, 138), // Aquí va el color del borde
            width: 2, // Ancho del borde
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🖼 Imagen de la tienda
            CircleAvatar(
              radius: 40,
              backgroundImage: (imagenBase64 != null && imagenBase64.isNotEmpty)
                  ? MemoryImage(base64Decode(imagenBase64))
                  : const AssetImage("assets/alex.png") as ImageProvider,
            ),
            const SizedBox(width: 12),

            // 🏪 Información
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Image.asset('assets/Ubicacion.png', width: 16, height: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          direccion,
                          style: const TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Image.asset('assets/Telefono.png', width: 16, height: 16),
                      const SizedBox(width: 4),
                      Text(
                        telefono,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 🔍 Botón lupa
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TiendaScreen(id_dueno: widget.id_dueno, idtienda: tienda['idtienda']),
                  ),
                );
              },
              icon: Image.asset(
                'assets/lupa.png',
                width: 40,
                height: 40,
              ),
              splashRadius: 24,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    }).toList(),
  );
}
}