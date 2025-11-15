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
import 'editarVeterinaria.dart';

class PerfilVeterinariaScreen extends StatefulWidget {
  final int id_veterinaria;

  const PerfilVeterinariaScreen({super.key, required this.id_veterinaria});

  @override
  State<PerfilVeterinariaScreen> createState() => _PerfilVeterinariaScreenState();
}

class _PerfilVeterinariaScreenState extends State<PerfilVeterinariaScreen> {
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> _veterinaria = [];
  List<Map<String, dynamic>> _citas = [];
  List<Map<String, dynamic>> _todasLasCitas = [];
  List<Map<String, dynamic>> _citasPendientes = [];
  int _seccionActiva = 1; // 0: Comentarios, 1: Perfil, 2: Citas
  DateTime? _fecha;
  TimeOfDay? _horaSeleccionada;
  bool _yaDioLike = false;
  List<String> _usuario = [];
  List<String> _telefonos = [];
  List<Map<String, dynamic>> _calificacion = [];
  List<String> _mascotas= [];
  List<Uint8List?> _fotomascotas = [];

  File? _imagen; // para móvil
  Uint8List? _webImagen; // para web
  String? _imagenBase64; // imagen lista para enviar al backend

  Set<int> _comentariosConLike = {};

  TextEditingController _fechaController = TextEditingController();
  TextEditingController _horaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _obtenerVeterinaria();
  }

  
  String _capitalizar(String texto) {
  if (texto.isEmpty) return "";
  return texto[0].toUpperCase() + texto.substring(1).toLowerCase();
}

  String capitalizar(String texto) {
    if (texto.isEmpty) return texto;
    return texto[0].toUpperCase() + texto.substring(1);
  }

  Future<void> _obtenerVeterinaria() async {
    final url = Uri.parse("http://localhost:5000/miveterinaria");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id": widget.id_veterinaria}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List veterinaria = data["veterinaria"] ?? [];
      setState(() {
        _veterinaria = veterinaria.map<Map<String, dynamic>>((m) {
          final veterinariaMap = Map<String, dynamic>.from(m);

          // Decodificar imagen principal
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

          // Decodificar certificados (lista de Base64)
          final certificadosRaw = veterinariaMap["certificados"];
          if (certificadosRaw != null) {
            if (certificadosRaw is List && certificadosRaw.isNotEmpty) {
              try {
                veterinariaMap["certificadosBytes"] =
                    certificadosRaw.map<Uint8List>((c) => base64Decode(c.toString())).toList();
              } catch (e) {
                print("❌ Error decodificando certificados: $e");
                veterinariaMap["certificadosBytes"] = [];
              }
            } else if (certificadosRaw is String && certificadosRaw.isNotEmpty) {
              try {
                veterinariaMap["certificadosBytes"] = [base64Decode(certificadosRaw)];
              } catch (e) {
                print("❌ Error decodificando certificado único: $e");
                veterinariaMap["certificadosBytes"] = [];
              }
            } else {
              veterinariaMap["certificadosBytes"] = [];
            }
          } else {
            veterinariaMap["certificadosBytes"] = [];
          }

          return veterinariaMap;
        }).toList();
      });

      // ✅ Si hay veterinaria, obtener comentarios
      if (_veterinaria.isNotEmpty) {
        await _obtener_comentariosVeterinaria();
        await _obtenerCitas_Veterinaria();
      }
    } else {
      print("❌ Error al obtener veterinaria: ${response.statusCode}");
    }
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

        final url = Uri.parse("http://localhost:5000/actualizar_imagen_veterinaria");
        final response = await http.put(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "id": widget.id_veterinaria,
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

  Future<double> _promedio_veterinaria() async {
    if (_veterinaria.isEmpty) return 0.0;

    final url = Uri.parse("http://localhost:5000/promedioVeterinaria");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_veterinaria": widget.id_veterinaria}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["promedio"]?.toDouble() ?? 0.0;
    } else {
      return 0.0;
    }
  }

  Future<void> _obtener_comentariosVeterinaria() async {
    final url = Uri.parse("http://localhost:5000/comentariosVeterinaria");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_veterinaria": widget.id_veterinaria}),
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
    final url = Uri.parse("http://localhost:5000/likeComentarioVeterinaria"); // tu endpoint Flask
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

  Future<void> _obtenerCitas_Veterinaria() async {
    final url = Uri.parse("http://localhost:5000/citasVeterinaria");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_veterinaria": widget.id_veterinaria}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List citas = data["citas"] ?? [];

      setState(() {
        _todasLasCitas = citas.map<Map<String, dynamic>>((m) => Map<String, dynamic>.from(m)).toList();
        _citasPendientes = _todasLasCitas.where((cita) => cita["estado"] == "pendiente").toList();
      });
    }
  }

  Future<Map<String, dynamic>?> _obtenerCitasUsuarios(int id_dueno) async {
    print("📤 Enviando id_dueno: $id_dueno");
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

  Future<Map<String, dynamic>?> _obtenerMascota(int idMascota) async {
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


  Future<void> aceptar_cita_medica(idCita) async {
    // 🗓️ FECHA — siempre se formatea (aunque no se cambie)
    String fecha = "";
    if (_fecha != null) {
      // Si el usuario elige nueva fecha
      fecha = "${_fecha!.year.toString().padLeft(4, '0')}-"
              "${_fecha!.month.toString().padLeft(2, '0')}-"
              "${_fecha!.day.toString().padLeft(2, '0')}";
    } 

    // ⏰ HORA — también siempre se formatea
    String hora = "";
    if (_horaSeleccionada != null) {
      // Si el usuario cambia la hora
      hora = _horaSeleccionada!.hour.toString().padLeft(2, '0') + ":" +
            _horaSeleccionada!.minute.toString().padLeft(2, '0') + ":00";
    } 

    final url = Uri.parse("http://localhost:5000/aceptar_cita_medica");

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        
        body: jsonEncode({
          "id": idCita,
          "fecha": fecha,
          "hora": hora, 
        }),
      );
      if (response.statusCode == 200) {
        mostrarMensajeFlotante(
          context,
          "✅ Cita aceptada correctamente",
          colorFondo: const Color.fromARGB(255, 243, 243, 243),
          colorTexto: const Color.fromARGB(255, 0, 0, 0),
        );

        await _obtenerCitas_Veterinaria();

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

  Future<void> cancelar_cita_medica(idCita) async {
    final url = Uri.parse("http://localhost:5000/cancelar_cita_medica");

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
          "✅ Cita cancelada correctamente",
          colorFondo: const Color.fromARGB(255, 243, 243, 243),
          colorTexto: const Color.fromARGB(255, 0, 0, 0),
        );

        await _obtenerCitas_Veterinaria();

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
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/paseador1.jpeg"),
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
                  _menuSuperior(),
                  const SizedBox(height: 20),
                  _fotoYNombre(),
                  const SizedBox(height: 12),
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
              

                  if (_seccionActiva == 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: ElevatedButton.icon(
                         onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Editarveterinaria(idveterinaria: widget.id_veterinaria, imagen: _veterinaria[0]["imagen"], cedulaUsuario: _veterinaria[0]["cedula_usuario"], nombre_veterinaria: _veterinaria[0]["nombre_veterinaria"], tarifa: _veterinaria[0]["tarifa"], descripcion: _veterinaria[0]["descripcion"], experiencia: _veterinaria[0]["experiencia"], certificados: _veterinaria[0]["certificados"], direccion: _veterinaria[0]["direccion"], telefono: _veterinaria[0]["telefono"], domicilio: _veterinaria[0]["domicilio"], horariolunesviernes: _veterinaria[0]["horariolunesviernes"], cierrelunesviernes: _veterinaria[0]["cierrelunesviernes"], horariosabado: _veterinaria[0]["horariosabado"], cierresabado: _veterinaria[0]["cierresabado"], horariodomingo: _veterinaria[0]["horariodomingo"], cierredomingo: _veterinaria[0]["horariodomingo"], metodopago: _veterinaria[0]["tipo_pago"]), // tu pantalla destino
                            ),
                          );
                        },
                        icon: Image.asset('assets/Editar.png', width: 20),
                        label: const Text("Editar veterinaria"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        
                        ),
                      ),
                    ),
                  if (_seccionActiva == 1) const SizedBox(height: 20),
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
                        : (_veterinaria.isNotEmpty && _veterinaria[0]["foto"] != null
                            ? MemoryImage(_veterinaria[0]["foto"])
                            : const AssetImage('assets/usuario.png')
                                as ImageProvider))
                    : (_imagen != null
                        ? FileImage(_imagen!)
                        : (_veterinaria.isNotEmpty && _veterinaria[0]["foto"] != null
                            ? MemoryImage(_veterinaria[0]["foto"])
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
          _veterinaria.isNotEmpty &&
          _veterinaria[0]["nombre_veterinaria"] != null &&
          (_veterinaria[0]["nombre_veterinaria"] as String).isNotEmpty
              ? '${(_veterinaria[0]["nombre_veterinaria"] as String).trim()[0].toUpperCase()}${(_veterinaria[0]["nombre_veterinaria"] as String).trim().substring(1)}'
              : "Sin nombre",
          style: const TextStyle(
            fontSize: 28,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 4, color: Colors.black)],
          ),
        ),
        const SizedBox(height: 6),
    
          FutureBuilder<double>(
            future: _promedio_veterinaria(),
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
          colors: [Color.fromARGB(255, 82, 228, 80), Color.fromARGB(255, 48, 126, 12)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _botonSeccion("Comentarios", 0),
          _botonSeccion("Perfil", 1),
          _botonSeccion("Citas", 2),
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
        _datoConIcono(
          "Horario",
          "assets/Calendr.png",
          _veterinaria.isNotEmpty
              ? "Lunes a Viernes: ${_veterinaria[0]["horariolunesviernes"] ?? "—"} – ${_veterinaria[0]["cierrelunesviernes"] ?? "—"}\n"
                "Sábados: ${_veterinaria[0]["horariosabado"] ?? "—"} – ${_veterinaria[0]["cierresabado"] ?? "—"}\n"
                "${(_veterinaria[0]["horariodomingo"] == null || _veterinaria[0]["horariodomingo"].isEmpty) ? "Domingos: Sin servicio" : "Domingos: ${_veterinaria[0]["horariodomingo"]} – ${_veterinaria[0]["cierredomingo"] ?? "—"}"}"
              : "Lunes a Viernes: — – —\nSábados: — – —\nDomingos: —",
        ),
        _datoConIcono(
          "Experiencia",
          "assets/sombrero.png",
          _veterinaria.isNotEmpty ? (_veterinaria[0]["experiencia"] ?? "No disponible") : "No disponible",
        ),
        _datoConIcono(
          "Teléfono",
          "assets/Telefono.png",
          _veterinaria.isNotEmpty ? (_veterinaria[0]["telefono"] ?? "No disponible") : "No disponible",
        ),
        _datoConIcono(
          "Dirección",
          "assets/Ubicacion.png",
          _veterinaria.isNotEmpty ? (_veterinaria[0]["direccion"] ?? "No disponible") : "No disponible",
        ),
        _datoConIcono(
          "Tarifa por consulta",
          "assets/precio.png",
          _veterinaria.isNotEmpty
              ? (() {
                  final tarifaRaw = _veterinaria[0]["tarifa"];
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
          _veterinaria.isNotEmpty ? (_veterinaria[0]["tipo_pago"] ?? "No disponible") : "No disponible",
        ),
        _datoConIcono(
          "Domicilio",
          "assets/domicilio.png",
          _veterinaria.isNotEmpty ? (_veterinaria[0]["domicilio"] ?? "No disponible") : "No disponible",
        ),
        _datoConIcono(
          "Descripción",
          "assets/Descripcion.png",
          _veterinaria.isNotEmpty ? (_veterinaria[0]["descripcion"] ?? "No disponible") : "No disponible",
        ),

            // ─── Certificados ───
      if (_veterinaria.isNotEmpty &&
          _veterinaria[0]["certificadosBytes"] != null &&
          (_veterinaria[0]["certificadosBytes"] as List).isNotEmpty)
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
                itemCount: (_veterinaria[0]["certificadosBytes"] as List).length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final certificado = _veterinaria[0]["certificadosBytes"][index];
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
        key: ValueKey(comentario["id_calificacion_veterinaria"]),
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
                  "${_capitalizar(comentario["nombre"] ?? "Usuario")} ${_capitalizar(comentario["apellido"] ?? "")}".trim(),
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

                  await _sumarLike(comentario["id_calificacion_veterinaria"], comentario["likes"]);

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
  // ═══════════════════════════════════════════
  // TARJETAS DE CITAS
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
                  "Calendario de citas",
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
                  "Calendario de citas",
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
    // 🔹 Tarjeta calendario
      Container(
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
                  "Calendario de pedidos",
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
                  "Calendario de pedidos",
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
    if (_citasPendientes.isEmpty) {
      return const SizedBox(); // o un texto: Center(child: Text("No hay citas pendientes"))
    }

    return Column(
      children: _citasPendientes.map<Widget>((cita) {
        final id = cita["id_cita_veterinaria"];
        final idMascota = cita["id_mascota"];
        final id_dueno = cita["id_dueno"];
        final motivo = cita["motivo"] ?? "N/A";
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

            final nombreMascota = snapshot.data?[0]?["nombre"] ?? "Sin nombre";
            final imagenMascota = snapshot.data?[0]?["imagen_perfil"];
            final nombre = snapshot.data?[1]?["nombre"] ?? "";
            final apellido = snapshot.data?[1]?["apellido"] ?? "";
            final nombreUsuario = (nombre.isNotEmpty || apellido.isNotEmpty)
                ? '${nombre[0].toUpperCase()}${nombre.substring(1)} ${apellido[0].toUpperCase()}${apellido.substring(1)}'
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              capitalizar(nombreMascota),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text("Propietario: $nombreUsuario"),
                            Text("Teléfono: $telefonoUsuario"),
                            const SizedBox(height: 4),
                            Text("Motivo: $motivo"),
                            Text("Tipo de pago: $metodoPago"),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 17),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                      onPressed: () {
                        mostrarConfirmacionRegistro(
                          context,
                          () {
                            cancelar_cita_medica(id); // acción concreta al confirmar
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
                          _mostrarModalFechaHora(id);
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
            );
          },
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════
  void _mostrarModalFechaHora(int idCita) {
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
                    "Asignar cita",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Selecciona la fecha y la hora en que podrás atender a la mascota.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 20),

                  // 👉 Pasamos setStateModal
                  _campoFecha(context),
                  const SizedBox(height: 10),
                  _campoHora(context),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: Image.asset(
                          "assets/cancelar.png",
                          height: 24, // 👈 Tamaño del icono
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
                        // 1️⃣ Llamar a la función que hace la petición
                        await aceptar_cita_medica(idCita);

                        // 2️⃣ Limpiar fecha y hora
                        

                        // 3️⃣ Cerrar el diálogo
                        Navigator.pop(context);

          
                      },
                      icon: Image.asset(
                        "assets/correcto.png",
                        height: 24,
                        width: 24,
                      ),
                      label: const Text("Aceptar"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
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

  // ═══════════════════════════════════════════
  Widget _campoFecha(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
    
          const SizedBox(width: 6),
          const Text(
            "Fecha",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ],
      ),
      const SizedBox(height: 4),
      GestureDetector(
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            setState(() {
              _fecha = picked;
              _fechaController.text =
                  "${picked.day}/${picked.month}/${picked.year}";
            });
          }
        },
        child: AbsorbPointer(
          child: TextField(
            controller: _fechaController,
            decoration: InputDecoration(
              hintText: "Seleccione la fecha",
              hintStyle: TextStyle(color: Colors.grey[800]),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  'assets/calendario1.png', // 👈 Aquí también puedes usar tu imagen
                  width: 24,
                  height: 24,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
    ],
  );
}



  Widget _campoHora(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Text(
            "Hora",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      GestureDetector(
        onTap: () async {
          final TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
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
            setState(() {
              _horaSeleccionada = picked;
              _horaController.text = picked.format(context);
            });
          }
        },
        child: AbsorbPointer(
          child: TextField(
            controller: _horaController,
            decoration: InputDecoration(
              hintText: "Seleccione la hora",
              hintStyle: TextStyle(color: Colors.grey[800]),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  'assets/hora.png', // 👈 Aquí va tu imagen personalizada
                  width: 24,
                  height: 24,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
    ],
  );
}
}