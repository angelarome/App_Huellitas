import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:http/http.dart' as http; 
import 'dart:convert';  
import 'package:flutter/foundation.dart' show kIsWeb;
import 'tiendas.dart';
import 'calendariomispedidos.dart';
import 'misreservascalendario.dart';
import 'compartirmascota.dart';
import 'calendario.dart';
import 'menu_lateral.dart';
import 'interfazIA.dart';

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
  TextEditingController _buscarController = TextEditingController();
  bool get mostrarLista => _buscarController.text.isNotEmpty && tiendasFiltradas.isNotEmpty;
  bool _menuAbierto = false;
  void _toggleMenu() {
    setState(() {
      _menuAbierto = !_menuAbierto;
    });
  }
  @override
  void initState() {
    super.initState();
    _obtenerTienda(); // Llamamos a la API apenas se abre la pantalla
  }


  Future<void> _obtenerTienda() async {
    final url = Uri.parse("https://apphuellitas-production.up.railway.app/tiendas"); // 👈 misma ruta del backend
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IaMascotasScreen(id_dueno: widget.id_dueno),
            ),
          );
        },
        child: Image.asset('assets/inteligent.png', width: 36, height: 36),
      ),
      body: Stack(
        children: [
          // Fondo
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/descarga.jpeg"),
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
                 _barraSuperiorConAtras(context),

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
                              boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black26)],
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
                                    // Buscador
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.9),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: TextField(
                                          controller: _buscarController,
                                          decoration: InputDecoration(
                                            hintText: "Buscar tienda o zona",
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                                            suffixIcon: Padding(
                                              padding: EdgeInsets.only(right: 4),
                                              child: Image.asset("assets/buscar.png", width: 20, height: 20),
                                            ),
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              final query = value.toLowerCase().trim();

                                              if (query.isEmpty) {
                                                tiendasFiltradas = [];
                                                return;
                                              }

                                              // Dividir la búsqueda por espacios
                                              final palabras = query.split(' ');

                                              tiendasFiltradas = _tienda.where((p) {
                                                final nombre = (p['nombre_negocio'] ?? '').toLowerCase();
                                                final zona = (p['departamento'] ?? '').toLowerCase();
                                                final ciudad = (p['ciudad'] ?? '').toLowerCase();

                                                // Retorna true si alguna palabra coincide con nombre, apellido o zona
                                                return palabras.any((palabra) =>
                                                    nombre.contains(palabra) ||
                                                    ciudad.contains(palabra) ||
                                                    zona.contains(palabra));
                                              }).toList();
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                // 🔹 Lista de paseadores filtrados
                                if (mostrarLista)
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: tiendasFiltradas.length,
                                    itemBuilder: (context, index) {
                                      final tienda = tiendasFiltradas[index];
                                      return InkWell(
                                        onTap: () {
                                          
                                        },
                                        child: ListTile(
                                          leading: tienda['foto'] != null
                                              ? CircleAvatar(
                                                  radius: 20, // la mitad del tamaño que quieras (40px)
                                                  backgroundImage: MemoryImage(tienda['foto']),
                                                )
                                              : CircleAvatar(
                                                  radius: 20,
                                                  child: Icon(Icons.person),
                                                ),
                                          title: Text("${tienda['nombre_negocio']}"),
                                          subtitle: Text(
                                            "${tienda['ciudad'] ?? ''} - ${tienda['departamento'] ?? ''}")
                                        ),
                                      );
                                    },
                                  )
                                else
                                  SizedBox.shrink(), // No muestra nada si no hay resultados
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),
                        
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CalendarioTiendaScreen(id_dueno: widget.id_dueno),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    height: 70,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color.fromARGB(255, 55, 131, 58),
                                        width: 2,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.asset(
                                            "assets/catalogo.png",
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        const Expanded(
                                          child: Text(
                                            "Mis pedidos",
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16), // Espacio entre las dos tarjetas
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CalendarioReservasScreen(id_dueno: widget.id_dueno),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    height: 70,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color.fromARGB(255, 223, 168, 6),
                                        width: 2,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.asset(
                                            "assets/reserva.png", // ícono de reservas
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        const Expanded(
                                          child: Text(
                                            "Mis reservas",
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          _tarjetaComentarios(),


                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  )],
                ),
              ),
            ),
            if (_menuAbierto)
            MenuLateralAnimado(onCerrar: _toggleMenu, id: widget.id_dueno),
          ],
        ),
      );
      
  }

  Widget _barraSuperior(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: SizedBox(
            width: 24,
            height: 24,
            child: Image.asset('assets/Menu.png'),
          ),
          onPressed: _toggleMenu,
        ),
        Row(
          children: [
            _iconoTop("assets/Perfil.png", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ListVaciaCompartirScreen(id_dueno: widget.id_dueno),
                ),
              );
            }),
            const SizedBox(width: 10),
            _iconoTop("assets/Calendr.png", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CalendarioEventosScreen(id_dueno: widget.id_dueno),
                ),
              );
            }),
            const SizedBox(width: 10),
            _iconoTop("assets/Campana.png", () {}),
          ],
        )

        
      ],
    );
  }

  Widget _iconoTop(String asset, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(width: 24, height: 24, child: Image.asset(asset)),
    );
  }

  Widget _barraSuperiorConAtras(BuildContext context) {
    return Column(
    crossAxisAlignment: CrossAxisAlignment.start, // alinear a la izquierda
    children: [
      _barraSuperior(context), // tu barra original

      // Tu botón de volver, justo debajo
      
      Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: IconButton(
            icon: Image.asset('assets/devolver5.png', width: 24, height: 24),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),
    ],
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
      final String ciudad = tienda['ciudad'] ?? 'Sin ciudad';
      final String direccion = tienda['direccion'] ?? 'Sin dirección';
      final String telefono = tienda['telefono']?.toString() ?? 'No disponible';
      final String? imagenBase64 = tienda['imagen']; // ✅ campo correcto del backend

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color.fromARGB(187, 255, 255, 255),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black26)],
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
                      color: Color.fromARGB(255, 37, 36, 36),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                    Image.asset('assets/mapa-de-colombia.png', width: 16, height: 16),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        ciudad,
                        style: const TextStyle(color: Color.fromARGB(255, 37, 36, 36)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(width: 12), // Espacio pequeño entre ciudad y dirección

                    // 📌 Icono dirección
                    Image.asset('assets/Ubicacion.png', width: 16, height: 16),
                    const SizedBox(width: 4),

                    // 🏠 Dirección
                    Flexible(
                      child: Text(
                        direccion,
                        style: const TextStyle(color: Color.fromARGB(255, 37, 36, 36)),
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
                        style: const TextStyle(color: Color.fromARGB(255, 37, 36, 36)),
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
                'assets/buscar.png',
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