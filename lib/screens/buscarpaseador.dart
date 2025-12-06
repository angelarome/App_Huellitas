import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:http/http.dart' as http; 
import 'dart:convert';  
import 'package:flutter/foundation.dart' show kIsWeb;
import 'paseadores.dart';
import 'package:intl/intl.dart';
import 'mispaseos.dart';

class BuscarPaseador extends StatefulWidget {
  final int id_dueno;
  const BuscarPaseador({super.key, required this.id_dueno});

  @override
  State<BuscarPaseador> createState() => _BuscarPaseador();
}

class _BuscarPaseador extends State<BuscarPaseador> {
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> _paseador = [];
  List<Map<String, dynamic>> _paseadorFiltrado = [];
  bool _cargando = true;
  TextEditingController _buscarController = TextEditingController();
  bool get mostrarLista => _buscarController.text.isNotEmpty && _paseadorFiltrado.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _obtenerPaseadores(); // Llamamos a la API apenas se abre la pantalla
  }

  String capitalizar(String texto) {
    if (texto.isEmpty) return texto;
    return texto[0].toUpperCase() + texto.substring(1).toLowerCase();
  }


  Future<void> _obtenerPaseadores() async {
    final url = Uri.parse("https://apphuellitas-production.up.railway.app/paseadores"); // 👈 misma ruta del backend
    final response = await http.get(url); // 👈 usar GET, no POST

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List paseadorJson = data["paseador"] ?? [];

      setState(() {
        _paseador = paseadorJson.map<Map<String, dynamic>>((m) {
          final paseadorMap = Map<String, dynamic>.from(m);

          // 👇 Si la imagen está en base64
          if (paseadorMap["imagen"] != null && paseadorMap["imagen"].isNotEmpty) {
            try {
              paseadorMap["foto"] = base64Decode(paseadorMap["imagen"]);
            } catch (e) {
              print("❌ Error decodificando imagen: $e");
              paseadorMap["foto"] = null;
            }
          } else {
            paseadorMap["foto"] = null;
          }

          return paseadorMap;
        }).toList();
      });
    } else {
      print("❌ Error al obtener paseador: ${response.statusCode}");
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
                image: AssetImage("assets/bosque.jpeg"),
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
                      "Paseadores",
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
                        // 🔹 Ícono compartir + barra de búsqueda con lupa a la derecha
                        Row(
                          children: [
                            Image.asset(
                              'assets/compartirm.png',
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
                                    hintText: "Buscar paseador o zona",
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
                                        _paseadorFiltrado = [];
                                        return;
                                      }

                                      // Dividir la búsqueda por espacios
                                      final palabras = query.split(' ');

                                      _paseadorFiltrado = _paseador.where((p) {
                                        final nombre = (p['nombre'] ?? '').toLowerCase();
                                        final apellido = (p['apellido'] ?? '').toLowerCase();
                                        final zona = (p['departamento'] ?? '').toLowerCase();
                                        final ciudad = (p['ciudad'] ?? '').toLowerCase();

                                        // Retorna true si alguna palabra coincide con nombre, apellido o zona
                                        return palabras.any((palabra) =>
                                            nombre.contains(palabra) ||
                                            apellido.contains(palabra) ||
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
                            itemCount: _paseadorFiltrado.length,
                            itemBuilder: (context, index) {
                              final paseador = _paseadorFiltrado[index];
                              return InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PerfilPaseadorScreen(
                                        id_dueno: widget.id_dueno,
                                        id_paseador: paseador["id_paseador"],
                                      ),
                                    ),
                                  );
                                },
                                child: ListTile(
                                  leading: paseador['foto'] != null
                                    ? CircleAvatar(
                                        radius: 20, // la mitad del tamaño que quieras (40px)
                                        backgroundImage: MemoryImage(paseador['foto']),
                                      )
                                    : CircleAvatar(
                                        radius: 20,
                                        child: Icon(Icons.person),
                                      ),
                                  title: Text("${paseador['nombre']} ${paseador['apellido']}"),
                                  subtitle: Text(
                                    "${paseador['ciudad'] ?? ''} - ${paseador['departamento'] ?? ''}"

                                  ),
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

                  // Tarjeta café "Mis citas"
                 GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CalendarioScreen(id_dueno: widget.id_dueno),
                      ),
                    );
                  },
                  child: Container(
                    height: 70,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 163, 145, 124),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color.fromARGB(255, 131, 123, 99), width: 2),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
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

                  // Tarjeta de comentarios
                  _tarjetaComentarios(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaComentarios() {
    if (_paseador.isEmpty) {
      return const Center(
        child: Text(
          "No hay paseadores disponibles",
          style: TextStyle(color: Color.fromARGB(255, 37, 36, 36)),
        ),
      );
    }

    return Column(
        children: _paseador.map<Widget>((paseador) {
          final String nombre = capitalizar(paseador['nombre'] ?? 'Sin nombre');
          final String apellido = capitalizar(paseador['apellido'] ?? 'Sin apellido');
          final String ciudad = paseador['ciudad'] ?? 'Sin ciudad';
          final String direccion = paseador['zona_servicio'] ?? 'Sin zona';
          final String telefono = paseador['telefono']?.toString() ?? 'No disponible';

          final tarifaRaw = paseador["tarifa_hora"];
          final tarifaNumero = tarifaRaw is num
              ? tarifaRaw
              : num.tryParse(tarifaRaw?.toString() ?? "0") ?? 0;

          final tarifaFormateada =
              "\$${NumberFormat("#,##0", "es_CO").format(tarifaNumero)}";

          final String? imagenBase64 = paseador['imagen'];

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
                      "$nombre $apellido",
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
                        const SizedBox(width: 10),
                        Image.asset('assets/precio.png', width: 16, height: 16),
                        const SizedBox(width: 4),
                        Text(
                          tarifaFormateada,
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
                      builder: (context) => PerfilPaseadorScreen(id_dueno: widget.id_dueno, id_paseador: paseador['id_paseador']),
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