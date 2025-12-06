import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:http/http.dart' as http; 
import 'dart:convert';  
import 'package:flutter/foundation.dart' show kIsWeb;
import 'veterinarias.dart';
import 'miscitas.dart';

class BuscarvMascotaScreen extends StatefulWidget {
  final int id_dueno;
  const BuscarvMascotaScreen({super.key, required this.id_dueno});

  @override
  State<BuscarvMascotaScreen> createState() => _BuscarvMascotaScreenScreenState();
}

class _BuscarvMascotaScreenScreenState extends State<BuscarvMascotaScreen> {
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> _veterinarias = [];
  List<dynamic> veterinariaFiltradas = [];
  bool _cargando = true;
  TextEditingController _buscarController = TextEditingController();
  bool get mostrarLista => _buscarController.text.isNotEmpty && veterinariaFiltradas.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _obtenerVeterinaria(); // Llamamos a la API apenas se abre la pantalla
  }

  Future<void> _obtenerVeterinaria() async {
    final url = Uri.parse("https://apphuellitas-production.up.railway.app/veterinarias"); // 👈 misma ruta del backend
    final response = await http.get(url); // 👈 usar GET, no POST

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List veterinariaJson = data["veterinaria"] ?? [];

      setState(() {
        _veterinarias = veterinariaJson.map<Map<String, dynamic>>((m) {
          final veterinariaMap = Map<String, dynamic>.from(m);

          // 👇 Si la imagen está en base64
          if (veterinariaMap["imagen"] != null && veterinariaMap["imagen"].isNotEmpty) {
            try {
              veterinariaMap["foto"] = base64Decode(veterinariaMap["imagen"]);
            } catch (e) {
              print("❌ Error decodificando imagen: $e");
              veterinariaMap["foto"] = null;
            }
          } else {
            veterinariaMap["foto"] = null;
          }

          return veterinariaMap;
        }).toList();
      });
    } else {
      print("❌ Error al obtener veterinaria: ${response.statusCode}");
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
                image: AssetImage("assets/vete.jpg"),
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

                  // Flecha debajo del menú
                  Row(
                    children: [
                      Image.asset(
                        'assets/devolver5.png',
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
                      "Veterinarias",
                      style: TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tarjeta blanca que agrupa todo
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
                        // Ícono compartirm + barra de búsqueda con lupa a la derecha
                        Row(
                          children: [
                            Image.asset(
                              'assets/veterinaria22.png',
                              width: 40,
                              height: 40,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 10),
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
                                          hintText: "Buscar veterinaria o zona",
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                                          suffixIcon: Padding(
                                            padding: EdgeInsets.only(right: 2),
                                            child: SizedBox(
                                              width: 10, // ancho del icono
                                              height: 10, // alto del icono
                                              child: Image.asset(
                                                "assets/buscar.png",
                                                fit: BoxFit.contain, // mantiene proporción
                                              ),
                                            ),
                                          ),
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            final query = value.toLowerCase().trim();

                                            veterinariaFiltradas = _veterinarias.where((p) {
                                              final nombre = (p["nombre_veterinaria"] ?? '').toLowerCase();
                                              final zona = (p['departamento'] ?? '').toLowerCase();
                                              final ciudad = (p['ciudad'] ?? '').toLowerCase();
                                              // Retorna true si el query coincide en el nombre o en la dirección
                                              return nombre.contains(query) || 
                                              zona.contains(query) ||
                                              ciudad.contains(query);
                        
                                            }).toList();
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              if (mostrarLista)
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: veterinariaFiltradas.length,
                                  itemBuilder: (context, index) {
                                    final veterinaria = veterinariaFiltradas[index];
                                    return InkWell(
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => PerfilVeterinariaScreen(id_dueno: widget.id_dueno, id_veterinaria: veterinaria['id_veterinaria']),
                                          ),
                                        );
                                      },
                                      child: ListTile(
                                        leading: veterinaria['foto'] != null
                                          ? CircleAvatar(
                                              radius: 20, // la mitad del tamaño que quieras (40px)
                                              backgroundImage: MemoryImage(veterinaria['foto']),
                                            )
                                          : CircleAvatar(
                                              radius: 20,
                                              child: Icon(Icons.person),
                                            ),
                                        title: Text("${veterinaria['nombre_veterinaria']} "),
                                        subtitle: Text(
                                        "${veterinaria['ciudad'] ?? ''} - ${veterinaria['departamento'] ?? ''}")
                                      ),
                                    );
                                  },
                                )
                          
                              else
                                SizedBox.shrink(), // no muestra nada
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Tarjeta café "Mis citas"
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CalendarioScreen(id_dueno: widget.id_dueno), // <-- tu pantalla destino
                              ),
                            );
                          },
                          child: Container(
                            height: 70,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 163, 145, 124),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color.fromARGB(255, 131, 123, 99),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    "assets/Calendario.png",
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Mis citas",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),


                        const SizedBox(height: 10),

                        _tarjetaComentarios(),
               
                  // Botón "Mis citas"
                  
                ],
              ),
            ),
          
          ),
        ],
      ),
    );
    
  }

  Widget _tarjetaComentarios() {
    if (_veterinarias.isEmpty) {
      return const Center(
        child: Text(
          "No hay tiendas disponibles",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Column(
      children: _veterinarias.map<Widget>((veterinaria) {
        final String nombre = veterinaria['nombre_veterinaria'] ?? 'Sin nombre';
        final String direccion = veterinaria['direccion'] ?? 'Sin dirección';
        final String ciudad = veterinaria['ciudad'] ?? 'Sin ciudad';
        final String telefono = veterinaria['telefono']?.toString() ?? 'No disponible';
        final String? imagenBase64 = veterinaria['imagen']; // ✅ campo correcto del backend

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
                    : const AssetImage("assets/usuario.png") as ImageProvider,
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
                        color: Color.fromARGB(255, 37, 36, 36)
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
                      builder: (context) => PerfilVeterinariaScreen(id_dueno: widget.id_dueno, id_veterinaria: veterinaria['id_veterinaria']),
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