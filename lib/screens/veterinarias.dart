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
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class PerfilVeterinariaScreen extends StatefulWidget {
  final int id_dueno;
  final int id_veterinaria;

  const PerfilVeterinariaScreen({super.key, required this.id_dueno, required this.id_veterinaria});

  @override
  State<PerfilVeterinariaScreen> createState() => _PerfilVeterinariaScreenState();
}

class _PerfilVeterinariaScreenState extends State<PerfilVeterinariaScreen> {
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> _veterinaria = [];
  DateTime? _fecha;
  TimeOfDay? _horaSeleccionada;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;
  int _seccionActiva = 1; // 0: Comentarios, 1: Perfil, 2: Citas
  bool _yaDioLike = false;
  List<Map<String, dynamic>> _calificacion = [];
  List<String> _mascotas= [];
  List<Uint8List?> _fotomascotas = [];

  File? _imagen; // para móvil
  Uint8List? _webImagen; // para web
  String? _imagenBase64; // imagen lista para enviar al backend

  Set<int> _comentariosConLike = {};

  TextEditingController _fechaController = TextEditingController();
  TextEditingController _horaController = TextEditingController();

  List<Map<String, dynamic>> comentarios = []; // viene de la API

  final TextEditingController comentarioCtrl = TextEditingController();
  int calificacion = 0;
  List<String> tiposPago = ["Cargando..."];
  String? _tipoPago = "Cargando...";
  List<Map<String, dynamic>> mascotas = [];
  List<String> nombresMascotas = ["Cargando..."];
  String? _nombreMascota; 
  String? _idMascota;
  final TextEditingController _motivo = TextEditingController();


  @override
  void initState() {
    super.initState();
    _obtenerVeterinaria();
    _obtenerMascotas();
  }
  bool cargando = true;
  
  String _capitalizar(String texto) {
  if (texto.isEmpty) return "";
  return texto[0].toUpperCase() + texto.substring(1).toLowerCase();
}

  String capitalizar(String texto) {
    if (texto.isEmpty) return texto;
    return texto[0].toUpperCase() + texto.substring(1);
  }

  Future<void> _obtenerVeterinaria() async {
    final url = Uri.parse("https://apphuellitas-production.up.railway.app/miveterinaria");
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

      setState(() {
        _veterinaria = _veterinaria;

        if (_veterinaria.isNotEmpty) {
          final tipo = (_veterinaria[0]["tipo_pago"] ?? "").toString();

          // SEPARAR tipos de pago por coma
          tiposPago = tipo.split(",").map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

          // NO seleccionar automáticamente ninguno
          _tipoPago = null;
        } else {
          tiposPago = ["No disponible"];
          _tipoPago = "No disponible";
        }
      });

      // ✅ Si hay veterinaria, obtener comentarios
      if (_veterinaria.isNotEmpty) {
        await _obtener_comentariosVeterinaria();
      }
    } else {
      print("❌ Error al obtener veterinaria: ${response.statusCode}");
    }
  }

  Future<void> _obtenerMascotas() async {
    setState(() => cargando = true);

    final url = Uri.parse("https://apphuellitas-production.up.railway.app/mascotas");
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

  Future<void> _cargarImagenPorDefecto() async {
    final byteData = await rootBundle.load('assets/usuario.png');
    final bytes = byteData.buffer.asUint8List();

    setState(() {
      _imagenBase64 = base64Encode(bytes);
      _webImagen = bytes; // para mostrarla en web
    });
  }

  Uint8List? _decodificarImagenMascota(String? nombre) {
    if (nombre == null) return null;

    Map<String, dynamic>? mascota;

    try {
      mascota = mascotas.firstWhere(
        (m) => m["nombre"] == nombre,
      );
    } catch (e) {
      return null; // no encontró la mascota → no hay imagen
    }

    final base64Img = mascota["imagen_perfil"];

    if (base64Img == null || base64Img.isEmpty) return null;

    try {
      return base64Decode(base64Img);
    } catch (e) {
      return null;
    }
  }

  Future<void> registrarCita() async {
   // --- Lista de campos faltantes ---
    List<String> camposFaltantes = [];

    // Nombre de mascota
    if (_nombreMascota == null ||
        _nombreMascota == "Cargando..." ||
        _nombreMascota!.trim().isEmpty) {
      camposFaltantes.add("Nombre de la mascota");
    }

    // Tipo de pago
    if (_tipoPago == null || _tipoPago!.trim().isEmpty) {
      camposFaltantes.add("Tipo de pago");
    }

    // Motivo
    if (_motivo.text.trim().isEmpty) {
      camposFaltantes.add("Motivo");
    }

    // Mostrar mensaje si faltan campos
    if (camposFaltantes.isNotEmpty) {
      mostrarMensajeFlotante(
        context,
        "⚠️ Faltan campos: ${camposFaltantes.join(', ')}",
        colorFondo: Colors.white,
        colorTexto: Colors.redAccent,
      );
      return;
    }
    try {
      // 🌐 URL del backend
      final url = Uri.parse("https://apphuellitas-production.up.railway.app/registrarCitaVeterinaria");

      // 🧠 Datos a enviar
      final body = {
        "id_mascota": _idMascota,
        "id_dueno": widget.id_dueno,
        "id_veterinaria": widget.id_veterinaria,
        "motivo": _motivo.text,
        "metodopago": _tipoPago,
      };
      
      // 📤 Enviar solicitud al backend
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      // ✅ Respuesta correcta
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // 🔹 Limpiar formulario para nueva cita
        setState(() {
          _motivo.clear();
          _nombreMascota = null;
          _idMascota = null;
          _tipoPago = null;
        });
        mostrarMensajeFlotante(
          context,
          "✅ Cita veterinaria agendada correctamente",
          colorFondo: const Color.fromARGB(255, 243, 243, 243),
          colorTexto: const Color.fromARGB(255, 0, 0, 0),
        );

      } else {
        mostrarMensajeFlotante(
          context,
          "❌ Error al agendar la cita veterinaria (${response.statusCode})",
          colorFondo: Colors.white,
          colorTexto: Colors.redAccent,
        );
      }
    } catch (e) {
      mostrarMensajeFlotante(
        context,
        "❌ Error: ${e.toString()}",
        colorFondo: Colors.white,
        colorTexto: Colors.redAccent,
      );
    }
  }

  Future<double> _promedio_veterinaria() async {
    if (_veterinaria.isEmpty) return 0.0;

    final url = Uri.parse("https://apphuellitas-production.up.railway.app/promedioVeterinaria");
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
    final url = Uri.parse("https://apphuellitas-production.up.railway.app/comentariosVeterinaria");
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

  Future<void> eliminarComentario(int idComentario) async {
    final url = Uri.parse("https://apphuellitas-production.up.railway.app/eliminarcomentarioVeterinaria");

    final response = await http.delete(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"idComentario": idComentario}),
    );

    if (response.statusCode == 200) {
      // refrescar datos
      await _obtener_comentariosVeterinaria();
      await _promedio_veterinaria();
      setState(() {});
    } else {
      mostrarMensajeFlotante(
        context,
        "❌ Error al eliminar comentario",
      );
    }
  }


  Future<void> _sumarLike(int idCalificacion, int nuevosLikes) async {
    final url = Uri.parse("https://apphuellitas-production.up.railway.app/likeComentarioVeterinaria"); // tu endpoint Flask
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
                                  comentarioEditar["id_calificacion_veterinaria"],
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

    final url = Uri.parse("https://apphuellitas-production.up.railway.app/comentarVeterinaria");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id_veterinaria": widget.id_veterinaria,
        "id_dueno": widget.id_dueno,
        "comentario": comentario,
        "calificacion": rating
      }),
    );

    if (response.statusCode == 200) {
      // 🔥 Volver a cargar los comentarios
      await _obtener_comentariosVeterinaria();

      // 🔥 Volver a cargar el promedio
      await _promedio_veterinaria();

      // 🔥 Refrescar la pantalla
      setState(() {});
    } else {
      print("Error: ${response.body}");
    }
  }

  Future<void> _editarComentario(int idComentario) async {
    final url = Uri.parse("https://apphuellitas-production.up.railway.app/editarcomentarioVeterinaria");

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id_calificacion_veterinaria": idComentario,
        "calificacion": calificacion,
        "comentario": comentarioCtrl.text,
      }),
    );

    if (response.statusCode == 200) {
      await _obtener_comentariosVeterinaria();
      await _promedio_veterinaria();
      setState(() {});
    } else {
      print("Error: ${response.body}");
    }
  }

  void mostrarConfirmacionAgenda(BuildContext context, VoidCallback onConfirmar, id) {
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
                      '¿Deseas agendar este cita?',
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
        return SingleChildScrollView(
          child: Column(
            key: const ValueKey("citas"),
            children: [
              _tarjetaMascotasCompartidas(),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      mostrarConfirmacionAgenda(
                        context,
                        () async {
                          await registrarCita();
                        },
                        _idMascota,
                      );
                    },
                    icon: SizedBox(
                      width: 24,
                      height: 24,
                      child: Image.asset('assets/Especie.png'),
                    ),
                    label: const Text(
                      "Agendar Cita",
                      style: TextStyle(color: Color.fromARGB(255, 46, 45, 45)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.9),
                      foregroundColor: const Color.fromARGB(255, 131, 123, 99),
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
          "Departamento",
          "assets/mapa-de-colombia.png",
          _veterinaria.isNotEmpty ? (_veterinaria[0]["departamento"] ?? "No disponible") : "No disponible",
        ),
        _datoConIcono(
          "Ciudad",
          "assets/alfiler.png",
          _veterinaria.isNotEmpty ? (_veterinaria[0]["ciudad"] ?? "No disponible") : "No disponible",
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

            if (comentario["id_dueno"] == widget.id_dueno)
              _botonesEditarEliminar(comentario)
          ],
        ),
      );
    }).toList(),
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
            () => eliminarComentario(comentario["id_calificacion_veterinaria"]),
            comentario["id_calificacion_veterinaria"], // ← tercer parámetro obligatorio
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

    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [

        // 🔵 Título
        Stack(
          children: [
            Text(
              "Agendar Cita",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2
                  ..color = Colors.black,
              ),
            ),
            const Text(
              "Agendar Cita",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),

        const SizedBox(height: 15),

        // 🔵 Imagen + Nombre Mascota
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _imagenMascota(),
            const SizedBox(width: 12),


          Expanded(
            child: nombresMascotas.isEmpty
                ? const Text("No tienes mascotas registradas")
                : _dropdownConEtiqueta(
                    "Nombre Mascota",
                    _icono("assets/Nombre.png"),
                    nombresMascotas,
                    "Seleccione la mascota",
                    _nombreMascota, // inicial = null
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
          )

          ],
        ),

        const SizedBox(height: 10),

        // 🔵 FECHA Y HORA UNO AL LADO DEL OTRO
        Row(
          children: [
            Expanded(
              child: _dropdownConEtiqueta(
                "Tipo de pago",
                _icono("assets/Pago.png"),
                tiposPago,
                "Seleccione",
                _tipoPago,
                (val) => setState(() => _tipoPago = val),
              ),
            ),
          ],
        ),

        Row(
          children: [
            Expanded(
              child: _campoTextoSimple(
                "Motivo",
                "assets/descripcion.png",
                _motivo,
                "Ej.: control, fiebre, herida.",
                esDireccion: true,
              ),
            ),
            const SizedBox(width: 12), // espacio entre los campos
          ],
        ),
      ],
    ),
  );
  
}

  Widget _imagenMascota() {
    final imagen = _decodificarImagenMascota(_nombreMascota);

    if (imagen == null) {
      return Image.asset(
        "assets/usuario.png",
        width: 100,
        height: 100,
        fit: BoxFit.cover,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: Image.memory(
        imagen,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _icono(String assetPath) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(width: 24, height: 24, child: Image.asset(assetPath)),
    );
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
      const SizedBox(height: 4),
      DropdownButtonFormField<String>(
        value: valorActual, // <-- permitimos que sea null
        decoration: InputDecoration(
          hintText: hintText, // esto se mostrará si valorActual es null
          hintStyle: TextStyle(color: Colors.grey[800]),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 12,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(0),
            child: SizedBox(
              width: 40,
              height: 40,
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
  Widget _campoTextoSimple(
    String etiqueta,
    String iconoPath,
    TextEditingController controller,
    String hintText, {
    bool soloLetras = false,
    bool soloNumeros = false,
    bool esDireccion = false,
    bool formatoMiles = false, 
    bool readOnly = false, 
    bool esCorreo = false,
  }) {
    List<TextInputFormatter> filtros = [];

    if (soloLetras) {
      filtros.add(FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')));
    } else if (soloNumeros) {
      filtros.add(FilteringTextInputFormatter.digitsOnly);
    } else if (esDireccion) {
      filtros.add(FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9áéíóúÁÉÍÓÚñÑ\s#\-\.,]')));
    } else if (esCorreo) {
      filtros.add(FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._\-]')));
    }

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
        const SizedBox(height: 4),

        TextField(
          controller: controller,
          keyboardType: TextInputType.multiline,
          maxLines: 6,
          minLines: 6,
          inputFormatters: filtros,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[800]),
            
            // 🔥 AQUÍ EL CAMBIO IMPORTANTE
            prefixIcon: Padding(
              padding: const EdgeInsets.only(bottom: 115, right: 2),
              child: Image.asset(iconoPath, width: 22, height: 22),
            ),

            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          ),
        ),

        const SizedBox(height: 12),
      ],
    );
  }
}