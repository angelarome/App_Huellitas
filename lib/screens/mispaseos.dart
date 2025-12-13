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
import 'compartirmascota.dart';
import 'calendario.dart';
import 'menu_lateral.dart';
import 'interfazIA.dart';

class CalendarioScreen extends StatefulWidget {
  final int id_dueno;

  const CalendarioScreen({super.key, required this.id_dueno});

  @override
  _CalendarioScreenState createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  DateTime _mesActual = DateTime(DateTime.now().year, DateTime.now().month);

  List<Map<String, dynamic>> _todasLasCitas = [];
  
  @override
  void initState() {
    super.initState();
    _obtenerPaseos(); // Llamamos a la API apenas se abre la pantalla
  }

  bool _menuAbierto = false;
  void _toggleMenu() {
    setState(() {
      _menuAbierto = !_menuAbierto;
    });
  }

  List<Map<String, dynamic>> _citasDelDiaActual = []; 

  Future<void> _obtenerPaseos() async {
    final url = Uri.parse("https://apphuellitas-production.up.railway.app/paseos_dueno");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_dueno": widget.id_dueno}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List citas = data["paseos"] ?? [];

      setState(() {
        _todasLasCitas = citas.map<Map<String, dynamic>>((m) => Map<String, dynamic>.from(m)).toList(); 
      });
    }
  }

  Future<void> cancelar_paseo(idCita) async {
    final url = Uri.parse("https://apphuellitas-production.up.railway.app/cancelar_paseo");

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

        await _obtenerPaseos();

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

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  
                  _barraSuperiorConAtras(context),

                ],
              ),
            ),
          ),

          if (_menuAbierto)
            MenuLateralAnimado(onCerrar: _toggleMenu, id: widget.id_dueno),
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
            _iconoTop("assets/Perfil.png", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ListVaciaCompartirScreen(id_dueno: widget.id_dueno),
                ),
              );
            }),
            const SizedBox(width: 10),
            _iconoTop("assets/Calendr.png", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CalendarioEventosScreen(id_dueno: widget.id_dueno),
                ),
              );
            }),
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

  Widget _barraSuperiorConAtras(BuildContext context) {
    return Column(
    crossAxisAlignment: CrossAxisAlignment.start, // alinear a la izquierda
    children: [
      _barraSuperior(context), // tu barra original

      // Tu botón de volver, justo debajo
      
      Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: IconButton(
            icon: Image.asset('assets/devolver5.png', width: 24, height: 24),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),
    ],
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
                      
                      final nombreMascota = _capitalizar(cita["nombre_mascota"] ?? "Sin nombre");
                      final nombrePaseador = _capitalizar(cita["nombre_paseador"] ?? "");
                      final apellidoPaseador = _capitalizar(cita["apellido_paseador"] ?? "");
                      final fotoPaseador = cita["foto_paseador"];
                      final telefonoPaseador = cita["telefono_paseador"] ?? "Sin teléfono";
                      
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

                                // FOTO PASEADOR
                                ClipOval(
                                  child: fotoPaseador != null
                                      ? Image.memory(
                                          base64Decode(fotoPaseador),
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

                                // INFORMACION
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      
                                      // Nombre mascota con contorno
                                      Stack(
                                        children: [
                                          Text(
                                            ("$nombrePaseador $apellidoPaseador"),
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              foreground: Paint()
                                                ..style = PaintingStyle.stroke
                                                ..strokeWidth = 2
                                                ..color = Colors.black,
                                            ),
                                          ),
                                          Text(
                                            ("$nombrePaseador $apellidoPaseador"),
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 3),

                                      Row(
                                        children: [
                                          Image.asset("assets/Telefono.png", width: 16, height: 16),
                                          const SizedBox(width: 4),
                                          RichText(
                                            text: TextSpan(
                                              children: [
                                                const TextSpan(
                                                  text: "Teléfono: ",
                                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                                ),
                                                TextSpan(
                                                  text: telefonoPaseador ?? "N/A",
                                                  style: const TextStyle(color: Colors.black),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),

                                      Row(
                                        children: [
                                          Image.asset("assets/Calendario1.png", width: 16, height: 16),
                                          const SizedBox(width: 4),
                                          RichText(
                                            text: TextSpan(
                                              children: [
                                                const TextSpan(
                                                  text: "Fecha: ",
                                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                                ),
                                                TextSpan(
                                                  text: cita["fecha"] ?? "N/A",
                                                  style: const TextStyle(color: Colors.black),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),

                                      Row(
                                        children: [
                                          Image.asset("assets/Hora.png", width: 16, height: 16),
                                          const SizedBox(width: 4),
                                          RichText(
                                            text: TextSpan(
                                              children: [
                                                const TextSpan(
                                                  text: "Hora inicio: ",
                                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                                ),
                                                TextSpan(
                                                  text: cita["hora_inicio"] ?? "N/A",
                                                  style: const TextStyle(color: Colors.black),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),


                                      // HORA FIN
                                      Row(
                                        children: [
                                          Image.asset("assets/Hora.png", width: 16, height: 16),
                                          const SizedBox(width: 4),
                                          RichText(
                                            text: TextSpan(
                                              children: [
                                                const TextSpan(
                                                  text: "Hora fin: ",
                                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                                ),
                                                TextSpan(
                                                  text: cita["hora_fin"] ?? "N/A",
                                                  style: const TextStyle(color: Colors.black),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 3),

                                      // PUNTO DE ENCUENTRO
                                      Row(
                                        children: [
                                          Image.asset("assets/Ubicacion.png", width: 16, height: 16),
                                          const SizedBox(width: 4),
                                          RichText(
                                            text: TextSpan(
                                              children: [
                                                const TextSpan(
                                                  text: "Punto de encuentro: ",
                                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                                ),
                                                TextSpan(
                                                  text: cita["punto_encuentro"] ?? "N/A",
                                                  style: const TextStyle(color: Colors.black),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 3),

                                      // TIPO DE PAGO
                                      Row(
                                        children: [
                                          Image.asset("assets/pago.png", width: 16, height: 16),
                                          const SizedBox(width: 4),
                                          RichText(
                                            text: TextSpan(
                                              children: [
                                                const TextSpan(
                                                  text: "Tipo de pago: ",
                                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                                ),
                                                TextSpan(
                                                  text: cita["metodo_pago"] ?? "N/A",
                                                  style: const TextStyle(color: Colors.black),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 3),

                                      // PRECIO
                                      Row(
                                        children: [
                                          Image.asset("assets/precio.png", width: 16, height: 16),
                                          const SizedBox(width: 4),
                                          RichText(
                                            text: TextSpan(
                                              children: [
                                                const TextSpan(
                                                  text: "Precio: ",
                                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                                ),
                                                TextSpan(
                                                  text: NumberFormat('#,###', 'es_CO')
                                                      .format(double.tryParse(cita['total'].toString()) ?? 0),
                                                  style: const TextStyle(color: Colors.black),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 3),

                                      // MASCOTA
                                      Row(
                                        children: [
                                          Image.asset("assets/huellitas.png", width: 16, height: 16),
                                          const SizedBox(width: 4),
                                          RichText(
                                            text: TextSpan(
                                              children: [
                                                const TextSpan(
                                                  text: "Mascota: ",
                                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                                ),
                                                TextSpan(
                                                  text: _capitalizar(cita["nombre_mascota"] ?? "N/A"),
                                                  style: const TextStyle(color: Colors.black),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 3),

                                      // COMPORTAMIENTO
                                      Row(
                                        children: [
                                          Image.asset("assets/paseador.png", width: 16, height: 16),
                                          const SizedBox(width: 4),
                                          RichText(
                                            text: TextSpan(
                                              children: [
                                                const TextSpan(
                                                  text: "Comportamiento: ",
                                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                                ),
                                                TextSpan(
                                                  text: cita["comportamiento"] ?? "N/A",
                                                  style: const TextStyle(color: Colors.black),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 3),

                                      // ESTADO
                                      Row(
                                        children: [
                                          getImagenEstado(cita["estado"] ?? ""),
                                          const SizedBox(width: 4),
                                          RichText(
                                            text: TextSpan(
                                              children: [
                                                const TextSpan(
                                                  text: "Estado: ",
                                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                                ),
                                                TextSpan(
                                                  text: cita["estado"] ?? "Desconocido",
                                                  style: const TextStyle(color: Colors.black),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),


                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // BOTONES
                            if (cita["estado"] == "pendiente" || cita["estado"] == "Aceptado")
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [

                                  // CANCELAR
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      if (cita["estado"] == "pendiente") {
                                        mostrarConfirmacion(
                                          context,
                                          mensaje: "¿Deseas cancelar el paseo?",
                                          onConfirmar: () => cancelar_paseo(cita["idpaseo"]),
                                          iconoConfirmar: "assets/correcto.png",
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


                                 
                                ],
                              )
                          ],
                        ),
                      );

                    }).toList(),
                  ),
                ),
              )
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
