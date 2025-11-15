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
  final int id_dueno;
  final int id_veterinaria;

  const PerfilVeterinariaScreen({super.key, required this.id_dueno, required this.id_veterinaria});

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
        return _tarjetaComentarios();
      case 1:
        return _tarjetaPerfil();
      case 2:
        return Column(
          key: const ValueKey("citas"),
          children: [
            const SizedBox(height: 20),
            
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
 
  // ══════════════════════════════════════════
}