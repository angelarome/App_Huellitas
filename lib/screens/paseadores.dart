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
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class _MilesFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern('es_CO');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String texto = newValue.text.replaceAll('.', '');
    if (texto.isEmpty) return newValue.copyWith(text: '');
    try {
      final valor = int.parse(texto);
      final nuevoTexto = _formatter.format(valor);
      return TextEditingValue(
        text: nuevoTexto,
        selection: TextSelection.collapsed(offset: nuevoTexto.length),
      );
    } catch (_) {
      return oldValue;
    }
  }
}


class PerfilPaseadorScreen extends StatefulWidget {
  final int id_dueno;
  final int id_paseador;

  const PerfilPaseadorScreen({super.key, required this.id_dueno, required this.id_paseador});

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
  List<String> tiposPago = ["Cargando..."];
  String? _tipoPago = "Cargando...";
  List<Map<String, dynamic>> mascotas = [];
  List<String> nombresMascotas = ["Cargando..."];
  String? _nombreMascota; 
  String? _idMascota;
  final TextEditingController _direccion = TextEditingController();
  TextEditingController _tarifa = TextEditingController();
  TextEditingController _total = TextEditingController(); 
  double _tarifaPaseador = 0;

  @override
    void initState() {
      super.initState();
      _obtenerPaseador(); // Llamamos a la API apenas se abre la pantalla
      _obtenerMascotas();
  } 
  
  bool cargando = true;

  final TextEditingController comentarioCtrl = TextEditingController();
    int calificacion = 0;

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

      // PRIMERO llenas _paseador
      final listaMapeada = paseador.map<Map<String, dynamic>>((m) {
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

        // Decodificar certificados
        final certificadosRaw = paseadorMap["certificado"];
        if (certificadosRaw != null) {
          if (certificadosRaw is List && certificadosRaw.isNotEmpty) {
            paseadorMap["certificadosBytes"] =
                certificadosRaw.map<Uint8List>((c) => base64Decode(c.toString())).toList();
          } else if (certificadosRaw is String && certificadosRaw.isNotEmpty) {
            paseadorMap["certificadosBytes"] = [base64Decode(certificadosRaw)];
          } else {
            paseadorMap["certificadosBytes"] = [];
          }
        } else {
          paseadorMap["certificadosBytes"] = [];
        }

        return paseadorMap;
      }).toList();

      setState(() {
        _paseador = listaMapeada;

        if (_paseador.isNotEmpty) {
          final tipo = (_paseador[0]["tipo_pago"] ?? "").toString();

          // SEPARAR tipos de pago por coma
          tiposPago = tipo.split(",").map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

          // NO seleccionar automáticamente ninguno
          _tipoPago = null;
          _tarifaPaseador = double.tryParse((_paseador[0]["tarifa_hora"] ?? "0").toString()) ?? 0;

          // También podemos actualizar el TextEditingController
          _tarifa.text = _tarifaPaseador.toStringAsFixed(0).replaceAllMapped(
              RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
        } else {
          tiposPago = ["No disponible"];
          _tipoPago = "No disponible";
          _tarifaPaseador = 0;
          _tarifa.text = "0";
        }
      });


      // Obtener comentarios
      if (_paseador.isNotEmpty) {
        await _obtener_comentariosPaseador();
      }

    } else {
      print("❌ Error al obtener veterinaria: ${response.statusCode}");
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

  void _calcularTotal() {
    if (_horaInicio != null && _horaFin != null) {
      // Convertir TimeOfDay a horas decimales
      final inicio = _horaInicio!.hour + _horaInicio!.minute / 60;
      final fin = _horaFin!.hour + _horaFin!.minute / 60;

      double horas = fin - inicio;
      if (horas < 0) horas = 0; // evita negativo si se escoge mal

      // Tomar la tarifa por hora del TextEditingController
      String tarifaTexto = _tarifa.text.replaceAll('.', ''); // quitar puntos de miles
      double tarifa = double.tryParse(tarifaTexto) ?? 0;

      double total = tarifa * horas;

      // Formatear con puntos de miles
      _total.text = total.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    }
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

  Future<void> registrarPaseo() async {
    if (_nombreMascota == null ||
      _nombreMascota == "Cargando..." ||
      _tipoPago == null ||
      _tipoPago!.isEmpty ||
      _horaInicio == null ||
      _horaFin == null ||
      _direccion.text.isEmpty) {
      mostrarMensajeFlotante(
        context,
        "⚠️ Por favor complete todos los campos obligatorios.",
        colorFondo: Colors.white,
        colorTexto: Colors.redAccent,
      );
      return;
    }

    try {
      // 💰 Procesar tarifa (quitar puntos y convertir a double)
      String totalTexto = _total.text.replaceAll('.', '');
      double totalDecimal = double.tryParse(totalTexto) ?? 0;

      String fecha = "${_fecha!.year.toString().padLeft(4, '0')}-"
                  "${_fecha!.month.toString().padLeft(2, '0')}-"
                  "${_fecha!.day.toString().padLeft(2, '0')}";
      // 🕒 Formatear horarios
      String horaInicio = "${_horaInicio!.hour.toString().padLeft(2, '0')}:${_horaInicio!.minute.toString().padLeft(2, '0')}:00";
      String cierreFin= "${_horaFin!.hour.toString().padLeft(2, '0')}:${_horaFin!.minute.toString().padLeft(2, '0')}:00";
      // 🌐 URL del backend
      final url = Uri.parse("http://localhost:5000/registrarPaseo");

      // 🧠 Datos a enviar
      final body = {
        "id_mascota": _idMascota,
        "id_dueno": widget.id_dueno,
        "id_paseador": widget.id_paseador,
        "direccion": _direccion.text,
        "horarioInicio": horaInicio,
        "cierrefin": cierreFin,
        "metodopago": _tipoPago,
        "tarifa": totalDecimal.toString(),
        "fecha": fecha,
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
          _fecha = null;
          _horaInicio = null;
          _horaFin = null;
          _direccion.clear();
          _total.clear();
          _nombreMascota = null;
          _idMascota = null;
          _tipoPago = null;
        });
        mostrarMensajeFlotante(
          context,
          "✅ Paseo agendado correctamente",
          colorFondo: const Color.fromARGB(255, 243, 243, 243),
          colorTexto: const Color.fromARGB(255, 0, 0, 0),
        );

      } else {
        mostrarMensajeFlotante(
          context,
          "❌ Error al agendar paseo (${response.statusCode})",
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
                      '¿Deseas agendar este paseo?',
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
                                  comentarioEditar["id_calificacion_paseador"],
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

    final url = Uri.parse("http://localhost:5000/comentarPaseador");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id_paseador": widget.id_paseador,
        "id_dueno": widget.id_dueno,
        "comentario": comentario,
        "calificacion": rating
      }),
    );

    if (response.statusCode == 200) {
      // 🔥 Volver a cargar los comentarios
      await _obtener_comentariosPaseador();

      // 🔥 Volver a cargar el promedio
      await _promedio_paseador();

      // 🔥 Refrescar la pantalla
      setState(() {});
    } else {
      print("Error: ${response.body}");
    }
  }

  Future<void> _editarComentario(int idComentario) async {
    final url = Uri.parse("http://localhost:5000/editarcomentarioPaseador");

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id_calificacion_paseador": idComentario,
        "calificacion": calificacion,
        "comentario": comentarioCtrl.text,
      }),
    );

    if (response.statusCode == 200) {
      await _obtener_comentariosPaseador();
      await _promedio_paseador();
      setState(() {});
    } else {
      print("Error: ${response.body}");
    }
  }

  Future<void> eliminarComentario(int idComentario) async {
    final url = Uri.parse("http://localhost:5000/eliminarcomentarioPaseador");

    final response = await http.delete(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"idComentario": idComentario}),
    );

    if (response.statusCode == 200) {
      // refrescar datos
      await _obtener_comentariosPaseador();
      await _promedio_paseador();
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
        return Column(
          key: const ValueKey("citas"),
          children: [
            _tarjetaMascotasCompartidas(),
            const SizedBox(height: 10),

          // 🔹 Botón debajo de la tarjeta
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                mostrarConfirmacionAgenda(
                  context,
                  () async {
                    // 🔹 Función que registra la cita en el backend
                    await registrarPaseo();
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
                  style: TextStyle(
                    color: Color.fromARGB(255, 46, 45, 45), // 👈 aquí cambias el color
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  foregroundColor:  const Color.fromARGB(255, 131, 123, 99),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),
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
          key: ValueKey(comentario["id_calificacion_paseador"]),
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

                    await _sumarLike(comentario["id_calificacion_paseador"], comentario["likes"]);

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
            Expanded(child: _campoFecha(context)),
            const SizedBox(width: 12),
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
              child: _campoHora(
                context: context,
                titulo: "Hora inicio",
                horaSeleccionada: _horaInicio,
                onHoraSeleccionada: (val) {
                  setState(() {
                    _horaInicio = val;
                    _calcularTotal();
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _campoHora(
                context: context,
                titulo: "Hora fin",
                horaSeleccionada: _horaFin,
                onHoraSeleccionada: (val) {
                  setState(() {
                    _horaFin = val;
                    _calcularTotal();
                  });
                },
              ),
            ),
          ],
        ),

        Row(
          children: [
            Expanded(
              child: _campoTextoSimple(
                "Zona de servicio",
                "assets/Ubicacion.png",
                _direccion,
                "Ej: Sevilla Valle, Caicedonia Valle",
                esDireccion: true,
              ),
            ),
            const SizedBox(width: 12), // espacio entre los campos
            Expanded(
              child: _campoTextoSimple(
                "Total a pagar",
                "assets/precio.png",
                _total,
                "Total",
                formatoMiles: true,
                readOnly: true,
              ),
            ),
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

  Widget _campoFecha(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Fecha",
          style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 46, 45, 45)),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: ColorScheme.dark(primary: Colors.blue[700]!),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() {
                _fecha = picked;
              });
            }
          },
          child: AbsorbPointer(
            child: TextField(
              decoration: InputDecoration(
                hintText: _fecha == null
                    ? "Seleccione la fecha"
                    : "${_fecha!.day}/${_fecha!.month}/${_fecha!.year}",
                hintStyle: TextStyle(color: Colors.grey[800]),

                // 👇 Aquí reemplazamos el ícono por una imagen personalizada
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(8.0), // Ajusta el espacio
                  child: Image.asset(
                    "assets/Calendario.png", // ruta de tu imagen
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

  Widget _campoHora({
  required BuildContext context,
  required String titulo,
  required TimeOfDay? horaSeleccionada,
  required Function(TimeOfDay?) onHoraSeleccionada,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        titulo,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 43, 42, 42),
        ),
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
            onHoraSeleccionada(picked);
          }
        },

        child: AbsorbPointer(
          child: TextField(
            decoration: InputDecoration(
              hintText: horaSeleccionada == null
                  ? "Seleccione la hora"
                  : horaSeleccionada.format(context),
              hintStyle: TextStyle(color: Colors.grey[800]),

              prefixIcon: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset("assets/Hora.png", width: 24, height: 24),
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
              () => eliminarComentario(comentario["id_calificacion_paseador"]),
              comentario["id_calificacion_paseador"], // ← tercer parámetro obligatorio
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
    bool esCorreo = false,// 👈 NUEVO: agrega puntos de miles (ej: 10.000)
  }) {
    List<TextInputFormatter> filtros = [];

    if (soloLetras) {
      // ✅ Solo letras (mayúsculas, minúsculas, tildes, ñ) y espacios
      filtros.add(FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')));
      
    } else if (soloNumeros) {
      // ✅ Solo números
      filtros.add(FilteringTextInputFormatter.digitsOnly);
    } else if (esDireccion) {
      // ✅ Letras, números, espacios y caracteres comunes en direcciones
      filtros.add(FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9áéíóúÁÉÍÓÚñÑ\s#\-\.,]')));
    } else if (formatoMiles) {
      // ✅ Formatear con puntos de miles automáticamente
      filtros.add(_MilesFormatter());
    } else if (esCorreo) {
    // ✅ Solo caracteres válidos para correos electrónicos
    filtros.add(FilteringTextInputFormatter.allow(
        RegExp(r'[a-zA-Z0-9@._\-]')));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 46, 45, 45)),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: formatoMiles || soloNumeros ? TextInputType.number : TextInputType.text,
          inputFormatters: filtros,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[800]),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: Image.asset(iconoPath, fit: BoxFit.contain),
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

