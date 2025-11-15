import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'editarPaseador.dart';

class PerfilPaseadorScreen extends StatefulWidget {
  final int id_paseador;

  const PerfilPaseadorScreen({super.key, required this.id_paseador});

  @override
  State<PerfilPaseadorScreen> createState() => _PerfilPaseadorScreenState();
}

class _PerfilPaseadorScreenState extends State<PerfilPaseadorScreen> {
  int _seccionActiva = 1; // 0: Comentarios, 1: Perfil, 2: Citas
  DateTime? _fecha;
  TimeOfDay? _horaSeleccionada;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;
  List<Map<String, dynamic>> _paseador = [];
  File? _imagen; // para móvil
  Uint8List? _webImagen; // para web
  String? _imagenBase64; // imagen lista para enviar al backend
  bool _yaDioLike = false;
  List<Map<String, dynamic>> _calificacion = [];
  List<Map<String, dynamic>> _todasLasCitas = [];
  List<Map<String, dynamic>> _citasPendientes = [];
  List<Map<String, dynamic>> _nombrePaseador = [];
  bool _cargando = true;
  @override
  void initState() {
    super.initState();
    _obtenerPaseador(); // Llamamos a la API apenas se abre la pantalla
  }

  String capitalizar(String texto) {
    if (texto.isEmpty) return texto;
    return texto[0].toUpperCase() + texto.substring(1);
  }
  
  Future<void> _obtenerPaseador() async {
    final url = Uri.parse("http://localhost:5000/mipaseador");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_paseador": widget.id_paseador}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List paseador = data["paseador"] ?? [];
      setState(() {
        _paseador = paseador.map<Map<String, dynamic>>((m) {
          final paseadorMap = Map<String, dynamic>.from(m);

          // Decodificar imagen principal
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

          // Decodificar certificados (lista de Base64)
          final certificadosRaw = paseadorMap["certificado"];
          if (certificadosRaw != null) {
            if (certificadosRaw is List && certificadosRaw.isNotEmpty) {
              try {
                paseadorMap["certificadosBytes"] =
                    certificadosRaw.map<Uint8List>((c) => base64Decode(c.toString())).toList();
              } catch (e) {
                print("❌ Error decodificando certificados: $e");
                paseadorMap["certificadosBytes"] = [];
              }
            } else if (certificadosRaw is String && certificadosRaw.isNotEmpty) {
              try {
                paseadorMap["certificadosBytes"] = [base64Decode(certificadosRaw)];
              } catch (e) {
                print("❌ Error decodificando certificado único: $e");
                paseadorMap["certificadosBytes"] = [];
              }
            } else {
              paseadorMap["certificadosBytes"] = [];
            }
          } else {
            paseadorMap["certificadosBytes"] = [];
          }

          return paseadorMap;
        }).toList();
      });

      // ✅ Si hay veterinaria, obtener comentarios
      if (_paseador.isNotEmpty) {
        await _obtener_comentariosPaseador();
        await _obtenerCitas_paseador();
      }
    } else {
      print("❌ Error al obtener veterinaria: ${response.statusCode}");
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
                    '¿Deseas cancelar esta cita?',
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
                        onPressed: () {
                          overlayEntry?.remove();
                          onConfirmar();
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

void mostrarConfirmacionAceptarRegistro(BuildContext context, VoidCallback onConfirmar, id) {
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
                    '¿Deseas aceptar esta cita?',
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
                        onPressed: () {
                          overlayEntry?.remove();
                          onConfirmar();
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

        final url = Uri.parse("http://localhost:5000/actualizar_imagen_paseador");
        final response = await http.put(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "id_paseador": widget.id_paseador,
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

  Future<double> _promedio_paseador() async {
    if (_paseador.isEmpty) return 0.0;

    final url = Uri.parse("http://localhost:5000/promedioPaseador");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_paseador": widget.id_paseador}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["promedio"]?.toDouble() ?? 0.0;
    } else {
      return 0.0;
    }
  }

  Future<void> _obtener_comentariosPaseador() async {
    final url = Uri.parse("http://localhost:5000/comentariosPaseador");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_paseador": widget.id_paseador}),
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
    final url = Uri.parse("http://localhost:5000/likeComentarioPaseador"); // tu endpoint Flask
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id": idCalificacion,
          "like": nuevosLikes,
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

  Future<void> _obtenerCitas_paseador() async {
    final url = Uri.parse("http://localhost:5000/paseosPaseador");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_paseador": widget.id_paseador}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List citas = data["paseos"] ?? [];

      setState(() {
        _todasLasCitas = citas.map<Map<String, dynamic>>((m) => Map<String, dynamic>.from(m)).toList();
        _citasPendientes = _todasLasCitas.where((cita) => cita["estado"] == "pendiente").toList();
      });
    }
  }

  Future<Map<String, dynamic>?> _obtenerCitasUsuarios(int id_dueno) async {
    final url = Uri.parse("http://localhost:5000/obtenerUsuario");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_dueno": id_dueno}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["usuario"] != null && data["usuario"].isNotEmpty) {
        return data["usuario"][0];
      }
    } else {
      print("❌ Error al obtener usuario: ${response.statusCode}");
    }

    return null;
  }

  Future<Map<String, dynamic>?> _obtenerMascota(String idMascota) async {
    final url = Uri.parse("http://localhost:5000/obtenermascota");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_mascota": idMascota}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["mascotas"] != null && data["mascotas"].isNotEmpty) {
        return data["mascotas"][0];
      }
    } else {
      print("❌ Error al obtener mascota: ${response.statusCode}");
    }

    return null;
  }

  Future<void> aceptar_paseo(idCita) async {

    final url = Uri.parse("http://localhost:5000/aceptar_paseo");

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        
        body: jsonEncode({
          "id": idCita,
        
        }),
      );
      if (response.statusCode == 200) {
        mostrarMensajeFlotante(
          context,
          "✅ Paseo aceptado correctamente",
          colorFondo: const Color.fromARGB(255, 243, 243, 243),
          colorTexto: const Color.fromARGB(255, 0, 0, 0),
        );

        await _obtenerCitas_paseador();

        // Limpiar selección de fecha y hora
        setState(() {
          _fecha = null;
          _horaSeleccionada = null;
        });

      } else {
        mostrarMensajeFlotante(
          context,
          "❌ Error: No se pudo aceptar la cita",
          colorFondo: Colors.white,
          colorTexto: Colors.redAccent,

        );
      }
    } catch (e) {
      mostrarMensajeFlotante(
        context,
        "❌ Error al aceptar cita: $e",
      );
    }
  }

  Future<void> cancelar_paseo(idCita) async {
    final url = Uri.parse("http://localhost:5000/cancelar_paseo");

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        
        body: jsonEncode({
          "id": idCita,
        }),
      );
      if (response.statusCode == 200) {
        mostrarMensajeFlotante(
          context,
          "✅ Paseo cancelado correctamente",
          colorFondo: const Color.fromARGB(255, 243, 243, 243),
          colorTexto: const Color.fromARGB(255, 0, 0, 0),
        );

        await _obtenerCitas_paseador();

        // Limpiar selección de fecha y hora
        setState(() {
          _fecha = null;
          _horaSeleccionada = null;
        });

      } else {
        mostrarMensajeFlotante(
          context,
          "❌ Error: No se pudo cancelar la cita",
          colorFondo: Colors.white,
          colorTexto: Colors.redAccent,

        );
      }
    } catch (e) {
      mostrarMensajeFlotante(
        context,
        "❌ Error al cancelar cita: $e",
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () {},
        child: Image.asset('assets/inteligent.png', width: 36, height: 36),
      ),
      body: Stack(
        children: [
          // Fondo con desenfoque
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/bosque.jpeg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),

          // Contenido principal
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _menuSuperior(),
                  const SizedBox(height: 20),
                  _fotoYNombre(),
                  const SizedBox(height: 20),
                  _botonesSeccion(),
                  const SizedBox(height: 20),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(scale: animation, child: child),
                      );
                    },
                    child: _contenidoInferior(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // MENÚ SUPERIOR
  Widget _menuSuperior() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            GestureDetector(
              onTap: () {},
              child: SizedBox(width: 24, height: 24, child: Image.asset('assets/Menu.png')),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: SizedBox(width: 24, height: 24, child: Image.asset('assets/devolver5.png')),
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () {},
              child: SizedBox(width: 24, height: 24, child: Image.asset('assets/Perfil.png')),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {},
              child: SizedBox(width: 24, height: 24, child: Image.asset('assets/Calendr.png')),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {},
              child: SizedBox(width: 24, height: 24, child: Image.asset('assets/Campana3.png')),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // FOTO Y NOMBRE
  Widget _fotoYNombre() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
               onTap: _seleccionarImagen,
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.white,
                backgroundImage: kIsWeb
                    ? (_webImagen != null
                        ? MemoryImage(_webImagen!)
                        : (_paseador.isNotEmpty && _paseador[0]["foto"] != null
                            ? MemoryImage(_paseador[0]["foto"])
                            : const AssetImage('assets/usuario.png')
                                as ImageProvider))
                    : (_imagen != null
                        ? FileImage(_imagen!)
                        : (_paseador.isNotEmpty && _paseador[0]["foto"] != null
                            ? MemoryImage(_paseador[0]["foto"])
                            : const AssetImage('assets/usuario.png')
                                as ImageProvider)),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 4,
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
        const SizedBox(height: 10),
        Text(
          _paseador.isNotEmpty
            ? "${_paseador[0]["nombre"][0].toUpperCase()}${_paseador[0]["nombre"].substring(1)} "
              "${_paseador[0]["apellido"][0].toUpperCase()}${_paseador[0]["apellido"].substring(1)}"
            : "Cargando...",
          style: const TextStyle(
            fontSize: 28,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 4, color: Colors.black)],
          ),
        ),
        const SizedBox(height: 6),
        FutureBuilder<double>(
            future: _promedio_paseador(),
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
      ],
    );
  }

  // ═══════════════════════════════════════════
  // BOTONES DE SECCIÓN
  Widget _botonesSeccion() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color.fromARGB(255, 227, 90, 81), Color.fromARGB(255, 249, 48, 26)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _botonSeccion("Comentarios", 0),
          _botonSeccion("Perfil", 1),
          _botonSeccion("Paseos", 2),
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
  // ═══════════════════════════════════════════
  // CONTENIDO SEGÚN SECCIÓN
  Widget _contenidoInferior() {
    switch (_seccionActiva) {
      case 0:
        return _tarjetaComentarios();
      case 1:
        return _tarjetaPerfil();
      case 2:
        return Column(
          key: const ValueKey("citas"),
          children: [
            _tarjetaMascotasCompartidas(),
            const SizedBox(height: 20),
            _tarjetaCitaLara(),
          ],
        );
      default:
        return const SizedBox();
      }
    }

  // ═══════════════════════════════════════════
  // TARJETA PERFIL
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
  return Column(
    key: const ValueKey("perfil"),
    children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blue[700],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black26)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _datoConIcono(
              "Horario",
              "assets/Calendr.png",
              _paseador.isNotEmpty
                  ? "Lunes a Viernes: ${_paseador[0]["horariolunesviernes"] ?? "—"} – ${_paseador[0]["cierrelunesviernes"] ?? "—"}\n"
                    "Sábados: ${_paseador[0]["horariosabado"] ?? "—"} – ${_paseador[0]["cierresabado"] ?? "—"}\n"
                    "${(_paseador[0]["horariodomingo"] == null || _paseador[0]["horariodomingo"].isEmpty) ? "Domingos: Sin servicio" : "Domingos: ${_paseador[0]["horariodomingo"]} – ${_paseador[0]["cierredomingo"] ?? "—"}"}"
                  : "Lunes a Viernes: — – —\nSábados: — – —\nDomingos: —",
            ),
            _datoConIcono(
              "Experiencia",
              "assets/sombrero.png",
              _paseador.isNotEmpty ? (_paseador[0]["experiencia"] ?? "No disponible") : "No disponible",
            ),
            _datoConIcono(
              "Teléfono",
              "assets/Telefono.png",
              _paseador.isNotEmpty ? (_paseador[0]["telefono"] ?? "No disponible") : "No disponible",
            ),
            _datoConIcono(
              "Zona de servicio",
              "assets/Ubicacion.png",
              _paseador.isNotEmpty ? (_paseador[0]["zona_servicio"] ?? "No disponible") : "No disponible",
            ),
            _datoConIcono(
              "Tarifa por hora",
              "assets/precio.png",
              _paseador.isNotEmpty
                  ? (() {
                      final tarifaRaw = _paseador[0]["tarifa_hora"];
                      final tarifaNumero = tarifaRaw is num
                          ? tarifaRaw
                          : num.tryParse(tarifaRaw?.toString() ?? "0") ?? 0;

                      final tarifaFormateada =
                          "\$${NumberFormat("#,##0", "es_CO").format(tarifaNumero)}";
                      return tarifaFormateada;
                    })()
                  : "No disponible",
            ),
            _datoConIcono(
              "Tipo de pago",
              "assets/Pago.png",
              _paseador.isNotEmpty ? (_paseador[0]["tipo_pago"] ?? "No disponible") : "No disponible",
            ),
            _datoConIcono(
              "Descripción",
              "assets/Descripcion.png",
              _paseador.isNotEmpty ? (_paseador[0]["descripcion"] ?? "No disponible") : "No disponible",
            ),

                // ─── Certificados ───
          if (_paseador.isNotEmpty &&
              _paseador[0]["certificadosBytes"] != null &&
              (_paseador[0]["certificadosBytes"] as List).isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/clip.png', // reemplaza con la ruta de tu imagen
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 8), // espacio entre la imagen y el texto
                    const Text(
                      "Certificados",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: (_paseador[0]["certificadosBytes"] as List).length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final certificado = _paseador[0]["certificadosBytes"][index];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          certificado,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                ),
              ],
            )
          ]
        )
      ),
    
    
      const SizedBox(height: 20),
      ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditarPaseador(id_paseador: widget.id_paseador, imagen: _paseador[0]["imagen"], cedulaUsuario: _paseador[0]["cedula_usuario"], nombre_paseador: _paseador[0]["nombre"], apellido_paseador: _paseador[0]["apellido"], tarifa: _paseador[0]["tarifa_hora"], descripcion: _paseador[0]["descripcion"], experiencia: _paseador[0]["experiencia"], certificados: (_paseador[0]["certificadosBytes"] as List<dynamic>).map((e) => e as Uint8List).toList(), direccion: _paseador[0]["zona_servicio"], telefono: _paseador[0]["telefono"], horariolunesviernes: _paseador[0]["horariolunesviernes"], cierrelunesviernes: _paseador[0]["cierrelunesviernes"], horariosabado: _paseador[0]["horariosabado"], cierresabado: _paseador[0]["cierresabado"], horariodomingo: _paseador[0]["horariodomingo"], cierredomingo: _paseador[0]["cierredomingo"], metodopago: _paseador[0]["tipo_pago"]), // tu pantalla destino
            ),
          );
        },
        icon: SizedBox(
          width: 24,
          height: 24,
          child: Image.asset('assets/Editar.png', fit: BoxFit.contain),
        ),
        label: const Text("Editar perfil"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: const Color.fromARGB(255, 255, 255, 255),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ],
  );
}
  // ═══════════════════════════════════════════
  // TARJETA COMENTARIOS
  Widget _tarjetaComentarios() {
    if (_calificacion.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: _calificacion.map<Widget>((comentario) {
        return Container(
          key: ValueKey(comentario["id"]),
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
                    comentario["nombre"] != null && comentario["apellido"] != null
                        ? "${comentario["nombre"][0].toUpperCase()}${comentario["nombre"].substring(1).toLowerCase()} "
                          "${comentario["apellido"][0].toUpperCase()}${comentario["apellido"].substring(1).toLowerCase()}"
                        : "Usuario",
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

                  // 👍 Botón de like
                  // 👍 Botón de like
                  GestureDetector(
                    onTap: () async {
                    if (comentario["yaDioLike"] == true) return;

                    setState(() {
                      comentario["likes"] = (comentario["likes"] ?? 0) + 1;
                      comentario["yaDioLike"] = true;
                    });

                    await _sumarLike(comentario["id"], comentario["likes"]);

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


  Widget _campoHora({
  required BuildContext context,
  required String label,
  required TimeOfDay? hora,
  required void Function(TimeOfDay) onHoraSeleccionada,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 4),
      GestureDetector(
        onTap: () async {
          final TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: hora ?? TimeOfDay.now(),
            builder: (context, child) {
              return Theme(
                data: ThemeData.dark().copyWith(
                  timePickerTheme: TimePickerThemeData(
                    backgroundColor: Colors.blue[700],
                    hourMinuteTextColor: Colors.white,
                    dialHandColor: Colors.white,
                    dialTextColor: Colors.white,
                    entryModeIconColor: Colors.white,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            setState(() => onHoraSeleccionada(picked));
          }
        },
        child: AbsorbPointer(
          child: TextField(
            decoration: InputDecoration(
              hintText: hora == null ? "Seleccione la hora" : hora.format(context),
              hintStyle: TextStyle(color: Colors.grey[800]),
              prefixIcon: const Icon(Icons.access_time),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
    ],
  );
}

  Widget _tarjetaMascotasCompartidas() {
    return Container(
       margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 246, 245, 245),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black26)],
          border: Border.all(color: const Color.fromARGB(255, 131, 123, 99), width: 2),
        ),
        child: Row(
          children: [
            Image.asset("assets/Calendario.png", width: 40, height: 40),
            const SizedBox(width: 12),
            Stack(
              children: [
                Text(
                  "Calendario de paseos",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 2
                      ..color = Colors.black,
                  ),
                ),
                const Text(
                  "Calendario de paseos",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

  Widget _tarjetaCitaLara() {
    if (_citasPendientes.isEmpty) {
      return const SizedBox(); // o un texto: Center(child: Text("No hay citas pendientes"))
    }

    return Column(
    children: _citasPendientes.map<Widget>((cita) {
      final id = cita["idpaseo"];
      final idMascota = cita["id_mascota"].toString();
      final id_dueno = cita["id_dueno"];
      
      final puntoEncuentro = cita["punto_encuentro"] ?? "N/A";
      final metodoPago = cita["metodo_pago"] ?? "N/A";

      return FutureBuilder<List<dynamic>>(
        future: Future.wait([
          _obtenerMascota(idMascota),
          _obtenerCitasUsuarios(id_dueno),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Text("❌ Error al cargar datos: ${snapshot.error}");
          }

          final nombreMascota = (snapshot.data?[0]?["nombre"] ?? "Sin nombre").toString();
          final nombreCapitalizado = nombreMascota.isNotEmpty
              ? nombreMascota[0].toUpperCase() + nombreMascota.substring(1).toLowerCase()
              : "Sin nombre";
          final imagenMascota = snapshot.data?[0]?["imagen_perfil"];
          final nombre = (snapshot.data?[1]?["nombre"] ?? "").toString();
        final apellido = (snapshot.data?[1]?["apellido"] ?? "").toString();

        String capitalizar(String texto) {
          if (texto.isEmpty) return texto;
          return texto[0].toUpperCase() + texto.substring(1).toLowerCase();
        }

        final nombreUsuario = (nombre.isNotEmpty || apellido.isNotEmpty)
            ? "${capitalizar(nombre)} ${capitalizar(apellido)}"
            : "Sin propietario";
          final telefonoUsuario = snapshot.data?[1]?["telefono"] ?? "N/A";

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black26)],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen de la mascota
                ClipOval(
                  child: imagenMascota != null
                      ? Image.memory(
                          base64Decode(imagenMascota),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          "assets/usuario.png",
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                ),
                const SizedBox(width: 12),
                // Información
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                      // Datos de la mascota
                      Text(
                        capitalizar(nombreMascota),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Datos del propietario
                      Text("Propietario: $nombreUsuario"),
                      Text("Teléfono: $telefonoUsuario"),
                      Text("Fecha: ${_citasPendientes[0]["fecha"]}"),
                      Text("Hora inicio: ${_citasPendientes[0]["hora_inicio"]}"),
                      Text("Hora fin: ${_citasPendientes[0]["hora_fin"]}"),
                      Text("Punto de encuentro: $puntoEncuentro"),
                      Text("Tipo de pago: $metodoPago"),


                const SizedBox(height: 17),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                      onPressed: () {
                        mostrarConfirmacionRegistro(
                          context,
                          () {
                            cancelar_paseo(id); // acción concreta al confirmar
                          },
                          id,
                        );
                      },  
                        icon: Image.asset("assets/cancelar.png", width: 24, height: 24),
                        label: const Text("Cancelar cita",
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 202, 65, 65),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          mostrarConfirmacionAceptarRegistro(
                            context,
                            () {
                              aceptar_paseo(id); // acción concreta al confirmar
                            },
                            id,
                          );
                        },  

                        icon: Image.asset("assets/correcto.png", width: 24, height: 24),
                        label: const Text("Aceptar cita",
                        style: TextStyle(color: Colors.white)), 
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 93, 195, 113),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )]));
          },
        );
      }).toList(),
    );
  }
} 

Widget _campoConIcono(String label, String iconPath, String hint) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 4),
      TextField(
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: 24,
              height: 24,
              child: Image.asset(iconPath, fit: BoxFit.contain),
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ],
  );
}


