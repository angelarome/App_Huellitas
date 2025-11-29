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
import 'dart:ui' show ImageFilter;
import 'mipaseador2.dart';

class CalendarioScreen extends StatefulWidget {
  final int id_paseador;

  const CalendarioScreen({super.key, required this.id_paseador});

  @override
  _CalendarioScreenState createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  DateTime _mesActual = DateTime(DateTime.now().year, DateTime.now().month);

  List<Map<String, dynamic>> _todasLasCitas = [];
  
  @override
  void initState() {
    super.initState();
    _obtenerCitas_paseador(); // Llamamos a la API apenas se abre la pantalla
  }

  List<Map<String, dynamic>> _citasDelDiaActual = []; 

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

  Future<void> No_asistio_paseo(idCita) async {
    final url = Uri.parse("http://localhost:5000/no_asistio_paseo");

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
          "✅ Paseo marcado como 'No asistió' correctamente",
          colorFondo: const Color.fromARGB(255, 243, 243, 243),
          colorTexto: const Color.fromARGB(255, 0, 0, 0),
        );

        await _obtenerCitas_paseador(); // obtiene todas las citas actualizadas
        setState(() {
          Navigator.pop(context);
        });


      } else {
        mostrarMensajeFlotante(
          context,
          "❌ Error: No se pudo marcar el paseo como 'No asistió' ",
          colorFondo: Colors.white,
          colorTexto: Colors.redAccent,

        );
      }
    } catch (e) {
      mostrarMensajeFlotante(
        context,
        "❌ Error al marcar paseo: $e",
      );
    }
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
          Navigator.pop(context);
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
          Navigator.pop(context);
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

  Future<void> finalizado(String idCita, String comentario) async {
    final url = Uri.parse("http://localhost:5000/finalizado_paseo");

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        
        body: jsonEncode({
          "id": idCita,
          "comentario": comentario,
        }),
      );
      if (response.statusCode == 200) {
        mostrarMensajeFlotante(
          context,
          "✅ Paseo finalizado correctamente",
          colorFondo: const Color.fromARGB(255, 243, 243, 243),
          colorTexto: const Color.fromARGB(255, 0, 0, 0),
        );

        await _obtenerCitas_paseador(); // obtiene todas las citas actualizadas
        setState(() {});

        Navigator.pop(context); 


      } else {
        mostrarMensajeFlotante(
          context,
          "❌ Error: No se pudo marcar el paseo como finalizado ",
          colorFondo: Colors.white,
          colorTexto: Colors.redAccent,

        );
      }
    } catch (e) {
      mostrarMensajeFlotante(
        context,
        "❌ Error al marcar paseo: $e",
      );
    }
  }

  void mostrarDialogoComportamiento(BuildContext context, String idPaseo) {
  final TextEditingController _comportamientoController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color.fromARGB(255, 111, 178, 205),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Stack(
        alignment: Alignment.center,
        children: [
          // Borde negro
          Text(
            "Comportamiento de la mascota",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2
                ..color = Colors.black,
            ),
          ),
          // Texto blanco encima
          Text(
            "Comportamiento de la mascota",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
      content: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 238, 238, 238),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, // icono arriba
          children: [
            Image.asset(
              "assets/descripcion.png",
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _comportamientoController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: "Escribe aquí cómo se comportó la mascota...",
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                style: const TextStyle(color: Colors.black87, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center, // Centra los botones
      actions: [
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
                final comentario = _comportamientoController.text.trim();
                if (comentario.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Debes escribir un comentario")),
                  );
                  return;
                }
                await finalizado(idPaseo, comentario); // Llamada al backend
                await _obtenerCitas_paseador();
                setState(() {});
              },
              icon: Image.asset(
                "assets/correcto.png",
                height: 24,
                width: 24,
              ),
              label: const Text("Finalizar"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}



void mostrarConfirmacion(
  BuildContext context, {
  required String mensaje, // Texto que se mostrará
  required VoidCallback onConfirmar, // Acción al confirmar
  String iconoCancelar = "assets/cancelar.png",
  String iconoConfirmar = "assets/Correcto.png",
  Color colorConfirmar = const Color(0xFF4CAF50),
  Color colorCancelar = const Color.fromARGB(255, 202, 65, 65),
}) {
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pets, color: Color(0xFF4CAF50), size: 50),
                  const SizedBox(height: 12),
                  Text(
                    mensaje,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          overlayEntry?.remove();
                        },
                        icon: Image.asset(
                          iconoCancelar,
                          width: 24,
                          height: 24,
                        ),
                        label: const Text(
                          'No',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorCancelar,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          overlayEntry?.remove();
                          onConfirmar();
                        },
                        icon: Image.asset(
                          iconoConfirmar,
                          width: 24,
                          height: 24,
                        ),
                        label: const Text(
                          'Sí',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorConfirmar,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
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

  // Nombres de meses
  final List<String> meses = [
    "Enero",
    "Febrero",
    "Marzo",
    "Abril",
    "Mayo",
    "Junio",
    "Julio",
    "Agosto",
    "Septiembre",
    "Octubre",
    "Noviembre",
    "Diciembre",
  ];

  Widget getImagenEstado(String estado) {
    switch (estado.toLowerCase()) {
      case "Aceptado":
        return Image.asset("assets/Correcto.png", width: 16, height: 16);
      case "pendiente":
        return Image.asset("assets/reloj-de-arena.png", width: 16, height: 16);
      case "Cancelado":
        return Image.asset("assets/cancelar.png", width: 16, height: 16);
      case "No asistió":
        return Image.asset("assets/cancelar.png", width: 16, height: 16);
      case "Finalizado":
        return Image.asset("assets/correcto.png", width: 16, height: 16);
      default:
        return Image.asset("assets/cancelar.png", width: 16, height: 16);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // <-- AppBar encima del fondo
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 211, 70, 60),
        elevation: 0,
        leading: IconButton(
          icon: Image.asset(
            "assets/devolver5.png",   // ← tu imagen
            width: 26,
            height: 26,
            color: Colors.white,      // opcional, si quieres que se vea blanca
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PerfilPaseadorScreen(id_paseador: widget.id_paseador)),
            );
          },
        ),
        title: Text(
          "Calendario",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // ------------ FONDO ------------
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/bosque.jpeg"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: Colors.black.withOpacity(0.25)),
          ),

          // ------------ CONTENIDO ------------
          Column(
            children: [
              SizedBox(height: 90), // separación debajo de la AppBar

              _headerBonito(), // <-- nuevo header
              SizedBox(height: 20),

              _diasSemana(),
              SizedBox(height: 15),
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  child: _gridDias(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerBonito() {
  return Container(
    margin: EdgeInsets.symmetric(horizontal: 20),
    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
    decoration: BoxDecoration(
      color: Color.fromARGB(255, 211, 70, 60),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _mesActual = DateTime(_mesActual.year, _mesActual.month - 1);
            });
          },
          child: Icon(Icons.chevron_left_rounded,
              color: Colors.white, size: 34),
        ),

        Text(
          "${meses[_mesActual.month - 1]} ${_mesActual.year}",
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(blurRadius: 12, color: Colors.black),
            ],
          ),
        ),

        GestureDetector(
          onTap: () {
            setState(() {
              _mesActual = DateTime(_mesActual.year, _mesActual.month + 1);
            });
          },
          child: Icon(Icons.chevron_right_rounded,
              color: Colors.white, size: 34),
        ),
      ],
    ),
  );
}

  // ---------------- HEADER CON FLECHAS ----------------
  Widget _header() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 227, 90, 81),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ----------- FLECHA IZQUIERDA -----------
          GestureDetector(
            onTap: () {
              setState(() {
                _mesActual =
                    DateTime(_mesActual.year, _mesActual.month - 1);
              });
            },
            child: Icon(
              Icons.chevron_left_rounded,  // ← flecha moderna
              size: 34,
              color: Colors.white,
            ),
          ),

          // ----------- TEXTO DEL MES -----------
          Text(
            "${meses[_mesActual.month - 1]} ${_mesActual.year}",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(blurRadius: 10, color: Colors.black),
              ],
            ),
          ),

          // ----------- FLECHA DERECHA -----------
          GestureDetector(
            onTap: () {
              setState(() {
                _mesActual =
                    DateTime(_mesActual.year, _mesActual.month + 1);
              });
            },
            child: Icon(
              Icons.chevron_right_rounded, // ← flecha moderna
              size: 34,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  // ---------------- ENCABEZADO DE DÍAS ----------------
  Widget _diasSemana() {
  List<String> dias = ["L", "M", "M", "J", "V", "S", "D"];

  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: dias.map((d) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 22),
        margin: const EdgeInsets.symmetric(horizontal: 4), // espacio pequeño entre elementos
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withOpacity(0.6),
            width: 1,
          ),
        ),
        child: Text(
          d,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      );
    }).toList(),
  );
}

  // ---------------- GRID DEL MES ----------------
  Widget _gridDias() {
    final primerDia = DateTime(_mesActual.year, _mesActual.month, 1);
    final ultimoDia = DateTime(_mesActual.year, _mesActual.month + 1, 0);

    final int totalDias = ultimoDia.day;
    final int inicioSemana = primerDia.weekday % 7; // para que domingo sea 0

    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: totalDias + inicioSemana,
      itemBuilder: (context, index) {
        if (index < inicioSemana) {
          return SizedBox(); // Casillas vacías antes del día 1
        }

        final dia = index - inicioSemana + 1;
        final fecha = DateTime(_mesActual.year, _mesActual.month, dia);

        // Formato ISO para comparar con tu backend
        final fechaIso = DateFormat('yyyy-MM-dd').format(fecha);

        // Filtrar las citas de este día
        final citasDelDia = _todasLasCitas.where((cita) {
        // obtener la fecha de la cita
        final citaFechaStr = cita["fecha"]?.toString() ?? '';
        if (citaFechaStr.isEmpty) return false;

        DateTime citaFecha;
        try {
          citaFecha = DateTime.parse(citaFechaStr);
        } catch (e) {
          return false; // formato inválido
        }

        // comparar solo el día, mes y año
        return citaFecha.year == fecha.year &&
              citaFecha.month == fecha.month &&
              citaFecha.day == fecha.day;
        
      }).toList();

        final bool tieneCita = citasDelDia.isNotEmpty;

        // Determinar color según el estado de la primera cita del día
        Color colorCita = Colors.transparent;
        if (tieneCita) {
          final estado = (citasDelDia[0]["estado"] ?? "").toString().toLowerCase();
          if (estado == "aceptado") {
            colorCita = Colors.green;
          } else if (estado == "cancelado") {
            colorCita = Colors.red;
          } else if (estado == "no asistió") {
            colorCita = Colors.red;
          }  else if (estado == "finalizado") {
            colorCita = Colors.green;
          } else {
            colorCita = Colors.grey; // otro estado o pendiente
          }
        }

        return GestureDetector(
          onTap: () {
              _mostrarCitasDelDia(citasDelDia);

          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorCita,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: 4,
                  color: Colors.black26,
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 6,
                  right: 6,
                  child: Text(
                    "$dia",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),

                if (tieneCita)
                  Positioned(
                    bottom: 6,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colorCita,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _mostrarCitasDelDia(List<Map<String, dynamic>> citas) {
  setState(() {
    _citasDelDiaActual = citas; // ahora no dará error
  });

  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // para que pueda crecer si hay muchas citas
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 12),
            Stack(
              children: [
                // Contorno negro
                Text(
                  "Citas del día",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 2
                      ..color = Colors.black, // borde negro
                  ),
                ),
                // Texto blanco encima
                const Text(
                  "Citas del día",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // texto blanco
                  ),
                ),
              ],
            ),
            const Divider(),
            // Lista de tarjetas
            if (citas.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("No hay citas para este día"),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: citas.map<Widget>((cita) {
                      final idMascota = cita["id_mascota"]?.toString() ?? '';
                      final id_dueno = cita["id_dueno"] ?? '';
                      final idpaseo = cita["idpaseo"]?.toString() ?? '';
                      
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

                          final mascota = snapshot.data?[0];
                          final usuario = snapshot.data?[1];

                          final nombreMascota = mascota?["nombre"] ?? "Sin nombre";
                          final imagenMascota = mascota?["imagen_perfil"];
                          final nombreUsuario = usuario != null
                              ? "${_capitalizar(usuario["nombre"] ?? "")} ${_capitalizar(usuario["apellido"] ?? "")}"
                              : "Sin propietario";
                          final telefonoUsuario = usuario?["telefono"] ?? "N/A";

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Stack(
                                            children: [
                                              // Contorno negro
                                              Text(
                                                _capitalizar(nombreMascota),
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  foreground: Paint()
                                                    ..style = PaintingStyle.stroke
                                                    ..strokeWidth = 2
                                                    ..color = Colors.black,
                                                ),
                                              ),
                                              // Texto blanco encima
                                              Text(
                                                _capitalizar(nombreMascota),
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Image.asset(
                                                "assets/Nombre.png", // tu imagen
                                                width: 16,
                                                height: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text("Propietario: $nombreUsuario"),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              Image.asset(
                                                "assets/Telefono.png", // tu imagen
                                                width: 16,
                                                height: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text("Teléfono: $telefonoUsuario"),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              Image.asset(
                                                "assets/Calendario1.png",
                                                width: 16,
                                                height: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text("Fecha: ${cita["fecha"] ?? "N/A"}"),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              Image.asset(
                                                "assets/Hora.png",
                                                width: 16,
                                                height: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text("Hora inicio: ${cita["hora_inicio"] ?? "N/A"}"),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              Image.asset(
                                                "assets/Hora.png",
                                                width: 16,
                                                height: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text("Hora fin: ${cita["hora_fin"] ?? "N/A"}"),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              Image.asset(
                                                "assets/Ubicacion.png",
                                                width: 16,
                                                height: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text("Punto de encuentro: ${cita["punto_encuentro"] ?? "N/A"}"),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              Image.asset(
                                                "assets/pago.png",
                                                width: 16,
                                                height: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text("Tipo de pago: ${cita["metodo_pago"] ?? "N/A"}"),
                                            ],
                                          ),
                                          const SizedBox(height: 3),

                                          Row(
                                            children: [
                                              Image.asset("assets/precio.png", width: 16, height: 16),
                                              const SizedBox(width: 4),
                                              Text(
                                              "Precio: ${NumberFormat('#,###', 'es_CO').format(double.tryParse(cita['total'].toString()) ?? 0)}",
                                            ),
                                            ],
                                          ),

                                          const SizedBox(height: 3),

                                          Row(
                                            children: [
                                              Image.asset("assets/huellitas.png", width: 16, height: 16),
                                              const SizedBox(width: 4),
                                              Text("Comportamiento: ${cita["comportamiento"] ?? "N/A"}"),
                                            ],
                                          ),

                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              getImagenEstado(cita["estado"] ?? ""),
                                              const SizedBox(width: 4),
                                              Text("Estado: ${cita["estado"] ?? "Desconocido"}"),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Botones
                                if (cita["estado"] == "pendiente" || cita["estado"] == "Aceptado")
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // Botón Cancelar / No asistió
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          if (cita["estado"] == "pendiente") {
                                            // Si está pendiente, mostrar confirmación para cancelar
                                            mostrarConfirmacion(
                                              context,
                                              mensaje: "¿Deseas cancelar el paseo?",
                                              onConfirmar: () => cancelar_paseo(cita["idpaseo"]),
                                              iconoConfirmar: "assets/correcto.png",
                                            
                                            );
                                          } else if (cita["estado"] == "Aceptado") {
                                            // Si está aceptada, mostrar confirmación para marcar como no asistió
                                            mostrarConfirmacion(
                                              context,
                                              mensaje: "¿Deseas registrar que la mascota no asistió?",
                                              onConfirmar: () => No_asistio_paseo(cita["idpaseo"]),
                                              
                                            );
                                          }
                                        },
                                        icon: Image.asset("assets/cancelar.png", width: 20, height: 20),
                                        label: Text(
                                          cita["estado"] == "pendiente" ? "Cancelar" : "No asistió",
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color.fromARGB(255, 202, 65, 65),
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),

                                      const SizedBox(width: 8),

                                      // Botón Aceptar / Finalizado
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          if (cita["estado"] == "pendiente") {
                                            mostrarConfirmacion(
                                              context,
                                              mensaje: "¿Deseas aceptar el paseo?",
                                              onConfirmar: () => aceptar_paseo(cita["idpaseo"]),
                                            );
                                          } else if (cita["estado"] == "Aceptado") {
                                              mostrarDialogoComportamiento(context, cita["idpaseo"].toString());
                                          }
                                          
                                        },
                                        icon: Image.asset("assets/correcto.png", width: 24, height: 24),
                                        label: Text(
                                          cita["estado"] == "pendiente" ? "Aceptar" : "Finalizado",
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color.fromARGB(255, 93, 195, 113),
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ],
                                  )

                              ],
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}


  String _capitalizar(String texto) {
    if (texto.isEmpty) return texto;
    return texto[0].toUpperCase() + texto.substring(1).toLowerCase();
  }

}
