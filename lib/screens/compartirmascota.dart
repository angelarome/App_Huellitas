import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:http/http.dart' as http; 
import 'dart:convert';  
import 'package:dropdown_button2/dropdown_button2.dart';
import 'solicitudes.dart';
import 'mascotasCompartidas.dart';

class listvaciacompartirScreen extends StatefulWidget {
  final int id_dueno;
  const listvaciacompartirScreen({super.key, required this.id_dueno});

  @override
  State<listvaciacompartirScreen> createState() => _listvaciacompartirScreen();
}

class _listvaciacompartirScreen extends State<listvaciacompartirScreen> {
  List<Map<String, dynamic>> _usuarios = [];
  List<Map<String, dynamic>> _usuariosFiltrado = [];
  TextEditingController _buscarController = TextEditingController();
  bool get mostrarLista => _buscarController.text.isNotEmpty && _usuariosFiltrado.isNotEmpty;
  List<String> nombresMascotas = ["Cargando..."];
  List<Map<String, dynamic>> mascotas = [];
  String? _nombreMascota; 
  String? _idMascota;
  List<Map<String, dynamic>> solicitudes = [];
  bool cargandoSolicitudes = false;

  @override
  void initState() {
    super.initState();
    _obtenerusuarios();
    _obtenerMascotas(); // Llamamos a la API apenas se abre la pantalla
  }
  bool cargando = true;

  final List<String> tiposRelacion = [
    "Mamá",
    "Papá",
    "Tío",
    "Hermano",
    "Primo",
    "Abuelo",
    "Abuela",
    "Amigo",
    "Padrino",
    "Madrina",
    "Otro"
  ];

  String? _tipoRelacion;

  String capitalizar(String texto) {
    if (texto.isEmpty) return texto;
    return texto[0].toUpperCase() + texto.substring(1).toLowerCase();
  }


  Future<void> _obtenerusuarios() async {
    final url = Uri.parse("http://localhost:5000/usuarios"); // 👈 misma ruta del backend
    final response = await http.get(url); // 👈 usar GET, no POST

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List usuarioJson = List<Map<String, dynamic>>.from(data);

      setState(() {
        _usuarios = usuarioJson.map<Map<String, dynamic>>((m) {
          final usuarioMap = Map<String, dynamic>.from(m);

          // 👇 Si la imagen está en base64
          if (usuarioMap["foto_perfil"] != null && usuarioMap["foto_perfil"].isNotEmpty) {
            try {
              usuarioMap["foto"] = base64Decode(usuarioMap["foto_perfil"]);
            } catch (e) {
              print("❌ Error decodificando imagen: $e");
              usuarioMap["foto"] = null;
            }
          } else {
            usuarioMap["foto"] = null;
          }

          return usuarioMap;
        }).toList();
      });
    } else {
      print("❌ Error al obtener paseador: ${response.statusCode}");
    }
  }

  Future<void> _obtenerMascotas() async {
    setState(() => cargando = true);

    final url = Uri.parse("http://localhost:5000/mascotas");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_dueno": widget.id_dueno}),
    );

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);

      final List mascotasJson = data["mascotas"] ?? [];

      setState(() {
        mascotas = mascotasJson
            .map<Map<String, dynamic>>((m) => Map<String, dynamic>.from(m))
            .toList();

        nombresMascotas = mascotas
            .map((m) => m["nombre"].toString())
            .toList();

        // NO asignamos automáticamente la primera mascota
        _nombreMascota = null;

        cargando = false;

      });
    } else {
      setState(() => cargando = false);
      print("❌ Error al obtener mascotas: ${response.statusCode}");
    }
  }

  Future<void> enviar_solicitud(idMascota, idPersona) async {
    if (_nombreMascota == null ||
      _nombreMascota == "Cargando..." ||
      _tipoRelacion == null 
      ) {
      mostrarMensajeFlotante(
        context,
        "⚠️ Por favor complete todos los campos obligatorios.",
        colorFondo: Colors.white,
        colorTexto: Colors.redAccent,
      );
      return;
    }
    final url = Uri.parse("http://localhost:5000/enviar_solicitud");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        
        body: jsonEncode({
          "id_mascota": idMascota,
          "id_dueno": widget.id_dueno,
          "id_persona": idPersona,
          "tipo_relacion": _tipoRelacion,
        }),
      );
      if (response.statusCode == 200) {
        mostrarMensajeFlotante(
          context,
          "✅ Solicitud enviada correctamente",
          colorFondo: const Color.fromARGB(255, 243, 243, 243),
          colorTexto: const Color.fromARGB(255, 0, 0, 0),
        );

        // Limpiar selección de fecha y hora
        setState(() {
          _nombreMascota = null;
          _tipoRelacion = null;
        });
        await _obtenerSolicitudes();

      } else {
        mostrarMensajeFlotante(
          context,
          "❌ Error: No se pudo enviar la solicitud",
          colorFondo: Colors.white,
          colorTexto: Colors.redAccent,

        );
      }
    } catch (e) {
      mostrarMensajeFlotante(
        context,
        "❌ Error al enviar solicitud: $e",
      );
    }
  }

  Future<void> _obtenerSolicitudes() async {
    setState(() => cargandoSolicitudes = true);

    try {
      final url = Uri.parse("http://localhost:5000/obtener_solicitudes");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id_dueno": widget.id_dueno}),
      );

      if (response.statusCode != 200) {
        print("❌ Error HTTP: ${response.statusCode}");
        return;
      }

      final data = jsonDecode(response.body);

      // Ahora data es un Map con la clave "solicitudes"
      if (data == null || data["solicitudes"] == null) {
        return;
      }

      final List solicitudesJson = data["solicitudes"];


      final nuevasSolicitudes = solicitudesJson.map<Map<String, dynamic>>((m) {
        final item = Map<String, dynamic>.from(m);

        final imagenBase64 = item["imagen_mascota"];

        if (imagenBase64 != null && imagenBase64.toString().isNotEmpty) {
          try {
            item["imagen_mascota_bytes"] = base64Decode(imagenBase64);
          } catch (_) {
            print("❌ Error decodificando imagen de la mascota ID: ${item['id_mascota']}");
            item["imagen_mascota_bytes"] = null;
          }
        } else {
          item["imagen_mascota_bytes"] = null;
        }

        return item;
      }).toList();

      setState(() {
        solicitudes = nuevasSolicitudes;
      });
    } catch (e) {
      print("❌ Error inesperado al obtener solicitudes: $e");
    } finally {
      if (mounted) {
        setState(() => cargandoSolicitudes = false);
      }
    }
  }

  void mostrarMensajeFlotante(BuildContext context, String mensaje, {Color colorFondo = Colors.white, Color colorTexto = Colors.black}) {
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Fondo transparente para dar efecto flotante
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                overlayEntry?.remove(); // 👈 Cierra al hacer clic fuera
              },
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
          ),

          // Cuadro del mensaje
          Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                decoration: BoxDecoration(
                  color: colorFondo,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  mensaje,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorTexto,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Insertar overlay
    Overlay.of(context).insert(overlayEntry);

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
                image: AssetImage("assets/hut-9582608_1280.jpg"),
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
                      "Compartir mascota",
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
                                    hintText: "Buscar persona",
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
                                        _usuariosFiltrado = [];
                                        return;
                                      }

                                      // Dividir la búsqueda por espacios
                                      final palabras = query.split(' ');

                                      _usuariosFiltrado = _usuarios.where((p) {
                                        final nombre = (p['nombre'] ?? '').toLowerCase();
                                        final apellido = (p['apellido'] ?? '').toLowerCase();

                                        // Retorna true si alguna palabra coincide con nombre, apellido o zona
                                        return palabras.any((palabra) =>
                                            nombre.contains(palabra) ||
                                            apellido.contains(palabra));
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
                            itemCount: _usuariosFiltrado.length,
                            itemBuilder: (context, index) {
                              final usuario = _usuariosFiltrado[index];

                              // Filtramos para que no aparezca tu propio usuario
                              if (usuario['id_dueno'] == widget.id_dueno) {
                                return const SizedBox.shrink();
                              }

                              return ListTile(
                                leading: usuario['foto'] != null
                                    ? CircleAvatar(
                                        radius: 20,
                                        backgroundImage: MemoryImage(usuario['foto']),
                                      )
                                    : const CircleAvatar(
                                        radius: 20,
                                        child: Icon(Icons.person),
                                      ),
                                title: Text("${usuario['nombre']} ${usuario['apellido']}"),
                                trailing: SizedBox(
                                  width: 80, // tamaño del botón
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      _mostrarModalsolicitud(usuario['id_dueno']); // tu función de enviar solicitud
                                    },
                                    icon: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: Image.asset('assets/correo.png'), // tu icono personalizado
                                    ),
                                    label: const Text(
                                      "Enviar",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
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
                  Row(
                    children: [
                      // --- TARJETA 1 ---
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MascotasCompartidas(id_dueno: widget.id_dueno),
                              ),
                            );
                          },
                          child: Container(
                            height: 80,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color.fromARGB(255, 222, 127, 115),
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: Color.fromARGB(255, 138, 89, 80),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    "assets/grupo.png",
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                const Text(
                                  "Mascotas\ncompartidas",
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // --- TARJETA 2 ---
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(40),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Solicitudes(id_dueno: widget.id_dueno),
                              ),
                            );
                          },
                          child: Container(
                            height: 80,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color.fromARGB(255, 33, 138, 184),
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: Color.fromARGB(255, 51, 95, 176),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(40),
                                  child: Image.asset(
                                    "assets/correo.png",
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                const Text(
                                  "Solicitudes\nenviadas",
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
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
    if (_usuarios.isEmpty) {
      return const Center(
        child: Text(
          "No hay usuarios disponibles",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Column(
        children: _usuarios.map<Widget>((usuario) {
          final String nombre = capitalizar(usuario['nombre'] ?? 'Sin nombre');
          final String apellido = capitalizar(usuario['apellido'] ?? 'Sin apellido');
          final String? imagenBase64 = usuario['imagen'];

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:  const Color.fromARGB(187, 255, 255, 255),
            border: Border.all(
              color: const Color.fromARGB(255, 180, 179, 176),
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
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      _mostrarModalsolicitud(usuario['id_dueno']);
                    },
                    icon: SizedBox(
                      width: 24,
                      height: 24,
                      child: Image.asset('assets/correo.png'),
                    ),
                    label: const Text(
                      "Enviar solicitud",
                      style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 33, 138, 184),
                      foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _icono(String assetPath) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(width: 24, height: 24, child: Image.asset(assetPath)),
    );
  }

  
  void _mostrarModalsolicitud(int id_persona) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Enviar solicitud",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    nombresMascotas.isEmpty
                      ? const Text("No tienes mascotas registradas")
                      : ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 85), // Altura máxima del dropdown
                          child: _dropdownConEtiqueta(
                            "Nombre Mascota",
                            _icono("assets/Nombre.png"),
                            nombresMascotas,
                            "Seleccione la mascota",
                            _nombreMascota,
                            (val) {
                              setState(() {
                                _nombreMascota = val;

                                final mascota = mascotas.cast<Map<String, dynamic>>().firstWhere(
                                  (m) => m["nombre"] == val,
                                  orElse: () => <String, dynamic>{},
                                );
                                _idMascota = mascota.isNotEmpty ? mascota["id_mascotas"].toString() : null;
                              });
                            },
                          ),
                        ),

                    const SizedBox(height: 10),
                    _dropdownConEtiqueta(
                      "Relación",
                      _icono("assets/cuidado-de-mascotas-sinfondo.png"), // Cambia por un icono apropiado
                      tiposRelacion,
                      "Seleccione la relación",
                      _tipoRelacion,
                      (val) {
                        setState(() {
                          _tipoRelacion = val;
                        });
                      },
                    ),

                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: Image.asset(
                            "assets/cancelar.png",
                            height: 24,
                            width: 24,
                          ),
                          label: const Text("Cancelar"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await enviar_solicitud(_idMascota, id_persona);
                            Navigator.pop(context);
                          
                          },
                          icon: Image.asset(
                            "assets/correo.png",
                            height: 24,
                            width: 24,
                          ),
                          label: const Text("Enviar"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 33, 138, 184),
                            foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _dropdownConEtiqueta(
  String etiqueta,
  Widget icono,
  List<String>? opciones,
  String hintText,
  String? valorActual,
  Function(String?)? onChanged,
) {
  final listaSegura =
      (opciones == null || opciones.isEmpty) ? ["Sin opciones"] : opciones;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        etiqueta,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 46, 45, 45),
        ),
      ),
      const SizedBox(height: 2),
      DropdownButtonFormField2<String>(
        value: valorActual, 
        decoration: InputDecoration(
          hintText: hintText, // esto se mostrará si valorActual es null
          hintStyle: TextStyle(color: Colors.grey[800]),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 12,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(0),
            child: SizedBox(
              width: 24,
              height: 24,
              child: icono,
            ),
          ),
        ),
        
        items: listaSegura.map((opcion) {
          return DropdownMenuItem(
            value: opcion,
            child: Text(opcion),
          );
        }).toList(),
        onChanged: onChanged,
      ),
      const SizedBox(height: 12),
    ],
  );
}

}