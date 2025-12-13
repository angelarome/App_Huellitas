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
import 'calendariopedidostienda.dart';
import 'calendarioreservasTienda.dart';
import 'iniciarsesion.dart';
import 'barralateraltienda.dart';

class PerfilTiendaScreen extends StatefulWidget {
  final int idtienda;
  const PerfilTiendaScreen({super.key, required this.idtienda});

  @override
  State<PerfilTiendaScreen> createState() => _PerfilTiendaScreenState();
}

class _PerfilTiendaScreenState extends State<PerfilTiendaScreen> {
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

  bool _menuAbierto = false;
  void _toggleMenu() {
    setState(() {
      _menuAbierto = !_menuAbierto;
    });
  }

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

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final imagenSeleccionada = await picker.pickImage(source: ImageSource.gallery);

    if (imagenSeleccionada != null) {
      try {
        Uint8List bytes;

        if (!kIsWeb) {
          final imagenFile = File(imagenSeleccionada.path);
          bytes = await imagenFile.readAsBytes();
          setState(() {
            _imagen = imagenFile;
          });
        } else {
          bytes = await imagenSeleccionada.readAsBytes();
          setState(() {
            _webImagen = bytes;
          });
        }

        final imagenBase64 = base64Encode(bytes);

        final url = Uri.parse("https://apphuellitas-production.up.railway.app/actualizar_imagen_tienda");
        final response = await http.put(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "id": widget.idtienda,
            "imagen": imagenBase64,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          mostrarMensajeFlotante(
          context,
            "✅ Imagen actualizada correctamente",
            colorFondo: const Color.fromARGB(255, 243, 243, 243),
            colorTexto: const Color.fromARGB(255, 0, 0, 0),
          );
          setState(() {}); // forzar redibujado
        } else {
          mostrarMensajeFlotante(
            context,
            "❌ Error al actualizar la imagen: ${response.statusCode}",
          );
        }
      } catch (e) {
        mostrarMensajeFlotante(
          context,
          "❌ Error al cancelar cita: $e",
        );
      }
    }
  }

  Future<void> _obtenerTienda() async {
    final url = Uri.parse("https://apphuellitas-production.up.railway.app/mitienda");
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

    final url = Uri.parse("https://apphuellitas-production.up.railway.app/promedioTienda");
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
    final url = Uri.parse("https://apphuellitas-production.up.railway.app/comentariosTienda");
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
    final url = Uri.parse("https://apphuellitas-production.up.railway.app/likeComentario"); // tu endpoint Flask
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
    final url = Uri.parse("https://apphuellitas-production.up.railway.app/misproductos");
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
      final url = Uri.parse("https://apphuellitas-production.up.railway.app/eliminarProducto");
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
                    '¿Deseas eliminar este producto',
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
                image: AssetImage("assets/descarga.jpeg"),
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
                  _barraSuperior(context),
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
                                      onTap: _seleccionarImagen,
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
                                        Positioned(
                                          bottom: 0,
                                          right: 2,
                                          child: GestureDetector(
                                            onTap: _seleccionarImagen,
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                color: Colors.redAccent,
                                                shape: BoxShape.circle,
                                              ),
                                              padding: const EdgeInsets.all(6),
                                              child: const Icon(
                                                Icons.camera_alt,
                                                color: Colors.white,
                                                size: 22,
                                              ),
                                            ),
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
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProductoMascotaScreen(idtienda: widget.idtienda),
                                      ),
                                    );
                                  },
                                  icon: Image.asset(
                                    'assets/agregar.png', // 🐾 tu imagen personalizada
                                    width: 28,  // ajusta el tamaño a tu gusto
                                    height: 28,
                                  ),
                                  label: Stack(
                                    children: [
                                      // 🔹 Texto negro (borde)
                                      Text(
                                        "Añadir Producto",
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
                                        "Añadir Producto",
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
                              if (_seccionActiva == 1)
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => Editartienda(idtienda: widget.idtienda, imagen: _tienda[0]["imagen"], cedulaUsuario: _tienda[0]["cedula_usuario"], nombreTienda: _tienda[0]["nombre_negocio"], descripcion: _tienda[0]["descripcion"], direccion: _tienda[0]["direccion"], telefono: _tienda[0]["telefono"], domicilio: _tienda[0]["domicilio"], horariolunesviernes: _tienda[0]["horariolunesviernes"], cierrelunesviernes: _tienda[0]["cierrelunesviernes"], horariosabado: _tienda[0]["horariosabado"], cierresabado: _tienda[0]["cierresabado"], horariodomingo: _tienda[0]["horariodomingo"], cierredomingo: _tienda[0]["cierredomingo"], metodopago: _tienda[0]["metodo_pago"], departamento: _tienda[0]["departamento"], ciudad: _tienda[0]["ciudad"]),
                                      ),
                                    );
                                  },
                                  icon: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Image.asset('assets/Editar.png',
                                        fit: BoxFit.contain),
                                  ),
                                  label: const Text("Editar perfil"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              const SizedBox(height: 40),
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
          if (_menuAbierto)
            MenuLateralAnimado(onCerrar: _toggleMenu, id: widget.idtienda),
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
        return _tarjetaComentarios();
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
          "Departamento",
          "assets/mapa-de-colombia.png",
          _tienda.isNotEmpty ? (_tienda[0]["departamento"] ?? "No disponible") : "No disponible",
        ),
        _datoConIcono(
          "Ciudad",
          "assets/alfiler.png",
          _tienda.isNotEmpty ? (_tienda[0]["ciudad"] ?? "No disponible") : "No disponible",
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
          ],
        ),
      );
    }).toList(),
  );
}


  // 🔹 Si hay productos, los mostramos
  Widget _tarjetaCatalogo() {
    // 🔹 Tarjetas de arriba: Mis pedidos / Mis reservas
    Widget tarjetasSuperiores = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CalendarioTiendaScreen(id_tienda: widget.idtienda),
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
                      color: Color.fromARGB(255, 55, 131, 58),
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
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          "Pedidos",
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
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CalendarioReservasScreen(id_tienda: widget.idtienda),
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
                      color: Color.fromARGB(255, 223, 168, 6),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          "assets/reserva.png",
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          "Reservas",
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
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
      ],
    );

    // 🔹 Si NO hay productos
    if (_producto.isEmpty) {
      return Column(
        key: ValueKey("catalogo"),
        children: [
          tarjetasSuperiores,
          Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(minHeight: 300),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(blurRadius: 6, color: Colors.black26),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset("assets/catalogo.png", width: 60, height: 60),
                SizedBox(height: 20),
                Text(
                  "Aún no tienes ningún producto registrado",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  "¡Añade uno para comenzar!",
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    // 🔹 Si SÍ hay productos
    return Column(
      key: ValueKey("catalogo"),
      children: [
        tarjetasSuperiores,

        // 🔹 Lista de productos
        ..._producto.map<Widget>((producto) {
          final nombreOriginal = producto["nombre"] ?? "Sin nombre";
          final nombre = nombreOriginal.isNotEmpty
              ? nombreOriginal[0].toUpperCase() +
                  nombreOriginal.substring(1).toLowerCase()
              : "Sin nombre";

          final descripcion = producto["descripcion"] ?? "Sin descripción";
          final disponibles = producto["cantidad_disponible"] ?? "N/A";

          final precioNumero = producto["precio"] is num
              ? producto["precio"]
              : num.tryParse(producto["precio"].toString()) ?? 0;

          final precioFormateado =
              "\$${NumberFormat("#,##0", "es_CO").format(precioNumero)}";

          Uint8List? foto;
          final imagenBase64 = producto["imagen"];
          if (imagenBase64 != null && imagenBase64.isNotEmpty) {
            foto = base64Decode(imagenBase64);
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 246, 245, 245),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(blurRadius: 6, color: Colors.black26),
              ],
              border: Border.all(
                color: Color.fromARGB(255, 131, 123, 99),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: foto != null
                          ? Image.memory(foto,
                              width: 90, height: 90, fit: BoxFit.cover)
                          : Image.asset("assets/perfilshop.png",
                              width: 90, height: 90, fit: BoxFit.cover),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombre,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(descripcion,
                              style: TextStyle(fontSize: 14)),
                          SizedBox(height: 4),
                          Text("Disponibles: $disponibles",
                              style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    Text(
                      precioFormateado,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        mostrarConfirmacionRegistro(
                          context,
                          () {
                            _eliminarProducto(producto["idproducto"]);
                          },
                          producto["idproducto"],
                        );
                      },
                      icon: Image.asset('assets/Botebasura.png', width: 20),
                      label: Text("Eliminar"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 210, 42, 42),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductoMascotaEditarScreen(
                              idtienda: widget.idtienda,
                              idproducto: producto["idproducto"],
                              nombre: producto["nombre"],
                              precio: double.tryParse(
                                      producto["precio"].toString()) ??
                                  0.0,
                              cantidad: int.tryParse(producto["cantidad_disponible"].toString()) ?? 0,
                              imagen: producto["imagen"],
                              descripcion: producto["descripcion"],
                            ),
                          ),
                        );
                      },
                      icon: Image.asset('assets/Editar.png', width: 20),
                      label: Text("Editar"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.white,
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

}