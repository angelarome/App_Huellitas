import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'productoTienda.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:ui';
import 'editartienda.dart';
import 'editarProducto.dart';

class TiendaScreen extends StatefulWidget {
  final int id_dueno;
  final int idtienda;
  const TiendaScreen({super.key, required this.id_dueno, required this.idtienda});

  @override
  State<TiendaScreen> createState() => _TiendaScreenState();
}

class _TiendaScreenState extends State<TiendaScreen> {
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> _tienda = [];
  List<Map<String, dynamic>> _usuario = [];
  List<Map<String, dynamic>> _calificacion = [];
  List<Map<String, dynamic>> _producto = [];
  int _seccionActiva = 1; // 0: Comentarios, 1: Perfil, 2: Catálogo

  File? _imagen; // para móvil
  Uint8List? _webImagen; // para web
  String? _imagenBase64; // imagen lista para enviar al backend
  bool _yaDioLike = false;

  final TextEditingController comentarioCtrl = TextEditingController();
  int calificacion = 0;
  int cantidad = 1;
  Set<int> _comentariosConLike = {};
  @override
  void initState() {
    super.initState();
    _obtenerTienda();
  }

  Future<void> _cargarImagenPorDefecto() async {
    final byteData = await rootBundle.load('assets/usuario.png');
    final bytes = byteData.buffer.asUint8List();

    setState(() {
      _imagenBase64 = base64Encode(bytes);
      _webImagen = bytes; // para mostrarla en web
    });
  }


  Future<void> _obtenerTienda() async {
    final url = Uri.parse("http://localhost:5000/mitienda");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id": widget.idtienda}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List tiendaJson = data["tienda"] ?? [];
      setState(() {
        _tienda = tiendaJson.map<Map<String, dynamic>>((m) {
          final tiendaMap = Map<String, dynamic>.from(m);

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
      // ✅ Si hay tienda, obtener usuario
    if (_tienda.isNotEmpty) {
      await _obtenerComentarios();
      await _obtenerProducto();
  
    }
  
  } else {
    print("❌ Error al obtener tienda: ${response.statusCode}");
  }
}

  Future<double> _obtenerPromedioTienda() async {
    if (_tienda.isEmpty) return 0.0;

    final url = Uri.parse("http://localhost:5000/promedioTienda");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_tienda": widget.idtienda}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["promedio"]?.toDouble() ?? 0.0;
    } else {
      return 0.0;
    }
  }

  Future<void> _obtenerComentarios() async {
    final url = Uri.parse("http://localhost:5000/comentariosTienda");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_tienda": _tienda[0]["idtienda"]}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List calificacion = data["calificacion"] ?? [];

      setState(() {
        _calificacion = calificacion.map<Map<String, dynamic>>((m) {
          return Map<String, dynamic>.from(m);
        }).toList();
      });
    } else {
      print("❌ Error al obtener comentarios: ${response.statusCode}");
    }
  }

  Future<void> _sumarLike(int idCalificacion, int nuevosLikes) async {
    final url = Uri.parse("http://localhost:5000/likeComentario"); // tu endpoint Flask
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id": idCalificacion,       // el ID del comentario
          "like": nuevosLikes, // la calificación
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Like actualizado en la base de datos");
      } else {
        print("⚠️ Error al actualizar el like: ${response.body}");
      }
    } catch (e) {
      print("❌ Error de conexión: $e");
    }
  }

  Future<void> _obtenerProducto() async {
    final url = Uri.parse("http://localhost:5000/misproductos");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_tienda": _tienda[0]["idtienda"]}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List producto = data["producto"] ?? [];

      final productosProcesados = producto.map<Map<String, dynamic>>((m) {
        final producto = Map<String, dynamic>.from(m);

        if (producto["imagen"] != null && producto["imagen"].isNotEmpty) {
              try {
                producto["foto"] = base64Decode(producto["imagen"]);
              } catch (e) {
                print("❌ Error decodificando imagen: $e");
                producto["foto"] = null;
              }
            } else {
              producto["foto"] = null;
            }

            return producto;
          }).toList();

          setState(() {
            _producto = productosProcesados;
          }
        );
      }
    }

  Future<void> _eliminarProducto(int idProducto) async {
    try {
      final url = Uri.parse("http://localhost:5000/eliminarProducto");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id_producto": idProducto,
          "id_tienda": widget.idtienda,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data["mensaje"] != null) {
          mostrarMensajeFlotante(
            context,
            "✅ Producto eliminado con éxito",
            colorFondo: const Color.fromARGB(255, 243, 243, 243),
            colorTexto: const Color.fromARGB(255, 0, 0, 0),
          );
          setState(() {
            _obtenerProducto();
          });
        } else {
          mostrarMensajeFlotante(
            context,
            "❌ No se pudo eliminar el producto: ${data["message"] ?? "Error desconocido"}",
          );
        }
      } else {
        mostrarMensajeFlotante(
          context,
          "❌ Error al eliminar producto: ${response.statusCode}",
        );
      }
    } catch (e) {
      mostrarMensajeFlotante(
        context,
        "❌ Ocurrió un error al eliminar producto: $e",
      );
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

  void mostrarConfirmacionRegistro(BuildContext context, VoidCallback onConfirmar, id) {
  OverlayEntry? overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () {},
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),
        ),
        Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 20, spreadRadius: 2, offset: const Offset(0, 6))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pets, color: Color(0xFF4CAF50), size: 50),
                  const SizedBox(height: 12),
                  Text(
                    '¿Deseas eliminar este comentario?',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () { overlayEntry?.remove(); },
                        icon: Image.asset(
                          "assets/cancelar.png", // tu icono
                          width: 24,
                          height: 24,
                        ),
                        label: const Text('No', style: TextStyle(color: Colors.white, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 202, 65, 65),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          overlayEntry?.remove(); // primero cierras el overlay
                          onConfirmar();    // esperas a que se ejecute correctamente la función async
                        },
                        icon: Image.asset(
                          "assets/Correcto.png", // tu icono
                          width: 24,
                          height: 24,
                        ),
                        label: const Text('Sí', style: TextStyle(color: Colors.white, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Overlay.of(context).insert(overlayEntry);
}

  void _mostrarModalComentario(BuildContext context, Map<String, dynamic>? comentarioEditar) {
    // Inicializar datos
    if (comentarioEditar != null) {
      calificacion = comentarioEditar["calificacion"];
      comentarioCtrl.text = comentarioEditar["opinion"];
    } else {
      calificacion = 0;
      comentarioCtrl.clear();
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            bool botonHabilitado = calificacion > 0 && comentarioCtrl.text.trim().isNotEmpty;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: const Color(0xFFF8F8F8),

              title: Center(
                child: Text(
                  comentarioEditar == null ? "Dejar un comentario" : "Editar comentario",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),

              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // ⭐ Estrellas
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          onPressed: () {
                            setStateModal(() {
                              calificacion = index + 1;
                            });
                          },
                          iconSize: 35,
                          icon: Icon(
                            Icons.star_rounded,
                            color: (index < calificacion)
                                ? Colors.amber[700]
                                : Colors.grey[400],
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 5),

                  // 📝 Texto
                  TextField(
                    controller: comentarioCtrl,
                    maxLines: 3,
                    onChanged: (_) => setStateModal(() {}),
                    decoration: InputDecoration(
                      hintText: "Escribe tu opinión aquí...",
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),

              actionsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),

              actionsAlignment: MainAxisAlignment.center, // Centra los botones horizontalmente

              actions: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    // BOTÓN CANCELAR
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            "assets/cancelar.png", // ← tu imagen
                            width: 20,
                            height: 20,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "Cancelar",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16), // Separación entre botones

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: botonHabilitado ? Colors.blueAccent : Colors.grey,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: botonHabilitado
                          ? () async {
                              if (comentarioEditar == null) {
                                await _enviarComentario();
                              } else {
                                await _editarComentario(
                                  comentarioEditar["id_calificacion_tienda"],
                                );
                              }
                              Navigator.pop(context);
                            }
                          : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            comentarioEditar == null
                                ? "assets/enviar.png"         // Imagen para enviar
                                : "assets/Correcto.png",       // Imagen para guardar
                            width: 20,
                            height: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            comentarioEditar == null ? "Enviar" : "Editar",
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _enviarComentario() async {
    String comentario = comentarioCtrl.text;
    int rating = calificacion;

    final url = Uri.parse("http://localhost:5000/comentarTienda");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id_tienda": widget.idtienda,
        "id_dueno": widget.id_dueno,
        "comentario": comentario,
        "calificacion": rating
      }),
    );

    if (response.statusCode == 200) {
      await _obtenerComentarios();
      await _obtenerPromedioTienda();

      // 🔥 Refrescar la pantalla
      setState(() {});
    } else {
      print("Error: ${response.body}");
    }
  }

  Future<void> _editarComentario(int idComentario) async {
    final url = Uri.parse("http://localhost:5000/editarcomentarioTienda");

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id_calificacion_tienda": idComentario,
        "calificacion": calificacion,
        "comentario": comentarioCtrl.text,
      }),
    );

    if (response.statusCode == 200) {
      await _obtenerComentarios();
      await _obtenerPromedioTienda();
      setState(() {});
    } else {
      print("Error: ${response.body}");
    }
  }

  Future<void> eliminarComentario(int idComentario) async {
    final url = Uri.parse("http://localhost:5000/eliminarcomentarioTienda");

    final response = await http.delete(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"idComentario": idComentario}),
    );

    if (response.statusCode == 200) {
      // refrescar datos
      await _obtenerComentarios();
      await _obtenerPromedioTienda();
      setState(() {});
    } else {
      mostrarMensajeFlotante(
        context,
        "❌ Error al eliminar comentario",
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () {
          // TODO: Acción de chat
        },
        child: Image.asset('assets/inteligent.png', width: 36, height: 36),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/Tienda.jpeg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Encabezado con menú y devolver
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () {},
                            child: SizedBox(
                                width: 24,
                                height: 24,
                                child: Image.asset('assets/Menu.png')),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: SizedBox(
                                width: 24,
                                height: 24,
                                child: Image.asset('assets/devolver5.png')),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {},
                            child: SizedBox(
                                width: 24,
                                height: 24,
                                child: Image.asset('assets/Perfil.png')),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {},
                            child: SizedBox(
                                width: 24,
                                height: 24,
                                child: Image.asset('assets/Calendr.png')),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {},
                            child: SizedBox(
                                width: 24,
                                height: 24,
                                child: Image.asset('assets/Campana3.png')),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Foto redonda y contenido
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Imagen de la tienda
                              Align(
                                alignment: Alignment.center,
                                child: Stack(
                                  children: [
                                    GestureDetector(
                                      child: CircleAvatar(
                                      radius: 55,
                                      backgroundColor: Colors.white,
                                      backgroundImage: kIsWeb
                                          ? (_webImagen != null
                                              ? MemoryImage(_webImagen!)
                                              : (_tienda.isNotEmpty && _tienda[0]["foto"] != null
                                                  ? MemoryImage(_tienda[0]["foto"])
                                                  : const AssetImage('assets/usuario.png')
                                                      as ImageProvider))
                                          : (_imagen != null
                                              ? FileImage(_imagen!)
                                              : (_tienda.isNotEmpty && _tienda[0]["foto"] != null
                                                  ? MemoryImage(_tienda[0]["foto"])
                                                  : const AssetImage('assets/usuario.png')
                                                      as ImageProvider)),

                                          ),
                                        ),
                                        
                                      ],
                                    ),
                                  ),
                               
                            const SizedBox(height: 10),

                            // Nombre y calificación
                            Text(
                              _tienda.isNotEmpty && _tienda[0]["nombre_negocio"] != null
                                ? _tienda[0]["nombre_negocio"][0].toUpperCase() +
                                    _tienda[0]["nombre_negocio"].substring(1).toLowerCase()
                                : "Nombre de la tienda",
                              style: const TextStyle(
                                fontSize: 28,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                              ),
                            ),

                            const SizedBox(height: 6),

                            FutureBuilder<double>(
                              future: _obtenerPromedioTienda(),
                              builder: (context, snapshot) {
                                double promedio = snapshot.data ?? 0.0;
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset("assets/estrella.png", width: 20, height: 20),
                                    const SizedBox(width: 6),
                                    Text(
                                      snapshot.connectionState == ConnectionState.waiting
                                          ? "Cargando..."
                                          : promedio > 0
                                              ? promedio.toStringAsFixed(1)
                                              : "Sin calificaciones",
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 20),

                        
                              // Botones secciones
                              _botonesSeccion(),
                              const SizedBox(height: 20),
                              // Contenido dinámico
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: ScaleTransition(
                                      scale: animation,
                                      child: child,
                                    ),
                                  );
                                },
                                child: _contenidoInferior(),
                              ),
                              const SizedBox(height: 20),
                              if (_seccionActiva == 2)
                                ElevatedButton.icon(
                                  onPressed: () {
                                    
                                  },
                                  icon: Image.asset(
                                    'assets/catalogo.png', // 🐾 tu imagen personalizada
                                    width: 28,  // ajusta el tamaño a tu gusto
                                    height: 28,
                                  ),
                                  label: Stack(
                                    children: [
                                      // 🔹 Texto negro (borde)
                                      Text(
                                        "Canasta",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          foreground: Paint()
                                            ..style = PaintingStyle.stroke
                                            ..strokeWidth = 2
                                            ..color = Colors.black,
                                        ),
                                      ),
                                      // 🔹 Texto blanco encima
                                      const Text(
                                        "Canasta",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(235, 233, 222, 218),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                            ),  
                              
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _botonesSeccion() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _botonSeccion("Comentarios", 0),
          _botonSeccion("Perfil", 1),
          _botonSeccion("Catálogo", 2),
        ],
      ),
    );
  }
  

  Widget _botonSeccion(String texto, int index) {
    final bool activo = _seccionActiva == index;
    return Expanded(
      child: TextButton(
        onPressed: () => setState(() => _seccionActiva = index),
        style: TextButton.styleFrom(
          backgroundColor: activo ? Colors.white.withOpacity(0.2) : Colors.transparent,
        ),
        child: Text(
          texto,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _contenidoInferior() {
    switch (_seccionActiva) {
      case 0:
        return Column(
          children: [
            _tarjetaComentarios(),   // ⬅️ tu tarjeta principal
            const SizedBox(height: 20),
            _comentar(),             // ⬅️ aquí aparece el botón COMENTAR
          ],
        );
      case 1:
        return _tarjetaPerfil();
      case 2:
        return _tarjetaCatalogo();
      default:
        return const SizedBox();
    }
  }

Widget _datoConIcono(String etiqueta, String iconoPath, String contenido) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 24, height: 24, child: Image.asset(iconoPath)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(etiqueta, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Text(contenido, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
    ),
  );
}


Widget _tarjetaPerfil() {
  return Container(
    key: const ValueKey("perfil"),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[700],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black26)],
      ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _datoConIcono("Horario", "assets/Calendr.png",
            _tienda.isNotEmpty? "Lunes a Viernes: ${_tienda[0]["horariolunesviernes"] ?? "—"} – ${_tienda[0]["cierrelunesviernes"] ?? "—"}\n"
              "Sábados: ${_tienda[0]["horariosabado"] ?? "—"} – ${_tienda[0]["cierresabado"] ?? "—"}\n"
              "${(_tienda[0]["horariodomingo"] == null || _tienda[0]["horariodomingo"].isEmpty) ? "Domingos: Sin servicio" : "Domingos: ${_tienda[0]["horariodomingo"]} – ${_tienda[0]["cierredomingo"] ?? "—"}"}"
            : "Lunes a Viernes: — – —\nSábados: — – —\nDomingos: —",),

        _datoConIcono(
          "Teléfono",
          "assets/Telefono.png",
          _tienda.isNotEmpty ? (_tienda[0]["telefono"] ?? "No disponible") : "No disponible",
        ),
        _datoConIcono(
          "Dirección",
          "assets/Ubicacion.png",
          _tienda.isNotEmpty ? (_tienda[0]["direccion"] ?? "No disponible") : "No disponible",
        ),
        _datoConIcono(
          "Tipo de pago", 
          "assets/Pago.png",
          _tienda.isNotEmpty ? (_tienda[0]["metodo_pago"] ?? "No disponible") : "No disponible",
        ),
        _datoConIcono("Domicilio", 
        "assets/domicilio.png", 
        _tienda.isNotEmpty ? (_tienda[0]["domicilio"] ?? "No disponible") : "No disponible",
        ),
        _datoConIcono("Descripción", 
        "assets/Descripcion.png",
        _tienda.isNotEmpty ? (_tienda[0]["descripcion"] ?? "No disponible") : "No disponible",),
      ],
    ),
   );
}

Widget _tarjetaComentarios() {
  
  if (_calificacion.isEmpty) {
    return const SizedBox.shrink();
  }

  return Column(
    children: _calificacion.map<Widget>((comentario) {
      return Container(
        key: ValueKey(comentario["id_calificacion_tienda"]),
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(minHeight: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black26)],
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ⭐ Calificación numérica arriba
            Row(
              children: [
                Image.asset("assets/estrella.png", width: 24, height: 24),
                const SizedBox(width: 8),
                Text(
                  comentario["calificacion"].toString(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 🧑 Imagen y nombre de usuario
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: kIsWeb
                      ? (comentario["foto_perfil"] != null
                          ? MemoryImage(base64Decode(comentario["foto_perfil"]))
                          : const AssetImage("assets/alex.png") as ImageProvider)
                      : (comentario["foto_perfil"] != null
                          ? MemoryImage(base64Decode(comentario["foto_perfil"]))
                          : const AssetImage("assets/alex.png") as ImageProvider),
                ),
                const SizedBox(width: 12),
                Text(
                  "${(comentario["nombre"] ?? "Usuario")} ${(comentario["apellido"] ?? "")}".trim(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 💬 Opinión
            Text(
              comentario["opinion"] ?? "",
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),

            const SizedBox(height: 10),

            // ⭐ Estrellas + 👍 Likes
            Row(
              children: [
                for (int i = 0; i < (comentario["calificacion"] ?? 0); i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Image.asset("assets/estrella.png", width: 20, height: 20),
                  ),
                const SizedBox(width: 10),

                GestureDetector(
                  onTap: () async {
                    if (comentario["yaDioLike"] == true) return;

                    // Actualiza localmente
                    final nuevosLikes = (comentario["likes"] ?? 0) + 1;

                    setState(() {
                      comentario["likes"] = nuevosLikes;
                      comentario["yaDioLike"] = true;
                    });

                    // Luego actualiza en el servidor
                    await _sumarLike(comentario["id_calificacion_tienda"], nuevosLikes);
                  },
              
                  child: Row(
                    children: [
                      Image.asset(
                        "assets/like.png",
                        width: 20,
                        height: 20,
                        color: _yaDioLike ? Colors.blue : null, // Cambia color si ya dio like
                      ),
                      const SizedBox(width: 4),
                      Text(comentario["likes"]?.toString() ?? "0"),
                    ],
                  ),
                ),
              ],
            ),
            if (comentario["id_dueno"] == widget.id_dueno)
              _botonesEditarEliminar(comentario)
          ],
        ),
      );
    }).toList(),
  );
}


  // 🔹 Si hay productos, los mostramos
  Widget _tarjetaCatalogo() {
  if (_producto.isEmpty) {
    return Container(
      key: const ValueKey("catalogo"),
      width: MediaQuery.of(context).size.width * 0.9,
      constraints: const BoxConstraints(minHeight: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black26)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset("assets/catalogo.png", width: 60, height: 60),
          const SizedBox(height: 20),
          const Text(
            "La tienda aún no tiene ningún producto registrado",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
        ],
      ),
    );
  }

  // 🔹 Si hay productos, los mostramos
  return Column(
    key: const ValueKey("catalogo"),
    children: [

      // 🔹 Tarjetas de productos
      ..._producto.map<Widget>((producto) {
        final nombreOriginal = producto["nombre"] ?? "Sin nombre";
        final nombre = nombreOriginal.isNotEmpty
            ? nombreOriginal[0].toUpperCase() + nombreOriginal.substring(1).toLowerCase()
            : "Sin nombre";
        final descripcion = producto["descripcion"] ?? "Sin descripción";
        final disponibles = producto["cantidad_disponible"] ?? "N/A";
        final int maxCantidad = int.tryParse(producto["cantidad_disponible"].toString()) ?? 0;
        final precioNumero = producto["precio"] is num
            ? producto["precio"]
            : num.tryParse(producto["precio"]?.toString() ?? "0") ?? 0;

        final precioFormateado = "\$${NumberFormat("#,##0", "es_CO").format(precioNumero)}";

        Uint8List? foto;
        final imagenBase64 = producto['imagen'];
        if (imagenBase64 != null && imagenBase64.isNotEmpty) {
          foto = base64Decode(imagenBase64);
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 246, 245, 245),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black26)],
            border: Border.all(color: const Color.fromARGB(255, 131, 123, 99), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: foto != null
                        ? Image.memory(foto, width: 90, height: 90, fit: BoxFit.cover)
                        : Image.asset("assets/perfilshop.png",
                            width: 90, height: 90, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(descripcion, style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 4),
                        Text("Disponibles: $disponibles",
                            style: const TextStyle(fontSize: 14, color: Colors.black)),
                        Text(
                          precioFormateado,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              
                  Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Color.fromARGB(255, 131, 123, 99),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Botón MENOS
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (cantidad > 1) cantidad--;
                            });
                          },
                          child: Container(
                            width: 35,
                            height: double.infinity,
                            alignment: Alignment.center,
                            child: const Text(
                              "-",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),

                        // Línea separadora
                        Container(
                          width: 1,
                          height: 22,
                          color: Color.fromARGB(255, 131, 123, 99),
                        ),

                        // Número
                        Container(
                          width: 40,
                          height: double.infinity,
                          alignment: Alignment.center,
                          child: Text(
                            "$cantidad",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),

                        // Línea separadora
                        Container(
                          width: 1,
                          height: 22,
                          color: Color.fromARGB(255, 131, 123, 99),
                        ),

                        // Botón MÁS
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (cantidad < maxCantidad) {
                                cantidad++;
                              }
                            });
                          },
                          child: Container(
                            width: 35,
                            height: double.infinity,
                            alignment: Alignment.center,
                            child: const Text(
                              "+",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                  onPressed: () {
                    
                  },  
                    icon: Image.asset('assets/catalogo.png', width: 20),
                    label: const Text(
                      "Canasta",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 57, 172, 31),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      
                    },
                    icon: Image.asset('assets/reserva.png', width: 20),
                    label: const Text("Reservar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    ],
  );
}

Widget _botonesEditarEliminar(Map<String, dynamic> comentario) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      // ✏ Botón editar
      TextButton.icon(
        onPressed: () {
          _mostrarModalComentario(context, comentario);
        },
        icon: const Icon(Icons.edit, color: Colors.blue),
        label: const Text("Editar", style: TextStyle(color: Colors.blue)),
      ),

      const SizedBox(width: 8),

      // 🗑 Botón eliminar
      TextButton.icon(
        onPressed: () {
          mostrarConfirmacionRegistro(
            context,
            () => eliminarComentario(comentario["id_calificacion_tienda"]),
            comentario["id_calificacion_tienda"], // ← tercer parámetro obligatorio
          );
        },
        icon: const Icon(Icons.delete, color: Colors.red),
        label: const Text("Eliminar", style: TextStyle(color: Colors.red)),
      ),
    ],
  );
}


Widget _comentar() {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: ElevatedButton.icon(
      onPressed: () {
        _mostrarModalComentario(context, null);
      },
      icon: Image.asset(
        "assets/Editar.png",
        width: 24,
        height: 24,
      ),
      label: Stack(
        children: [
          // Borde negro
          Text(
            "Comentar",
            style: TextStyle(
              fontSize: 16,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2
                ..color = const Color.fromARGB(255, 29, 29, 29),
            ),
          ),

          // Relleno blanco
          Text(
            "Comentar",
            style: const TextStyle(
              fontSize: 16,
              color: Color.fromARGB(196, 255, 255, 255),
            ),
          ),
        ],
      ),
    ),
  );
}

}