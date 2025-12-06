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

class CalendarioReservasScreen extends StatefulWidget {
  final int id_tienda;

  const CalendarioReservasScreen({super.key, required this.id_tienda});

  @override
  _CalendarioReservasScreenState createState() => _CalendarioReservasScreenState();
}

class _CalendarioReservasScreenState extends State<CalendarioReservasScreen> {
  DateTime _mesActual = DateTime(DateTime.now().year, DateTime.now().month);

  List<Map<String, dynamic>> _todasReservas = [];
  
  @override
  void initState() {
    super.initState();
    _obtenerreservas(); // Llamamos a la API apenas se abre la pantalla
  }

  List<Map<String, dynamic>> _citasDelDiaActual = []; 

  Future<void> _obtenerreservas() async {
    final url = Uri.parse("https://apphuellitas-production.up.railway.app/reservas");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_tienda": widget.id_tienda}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List reserva = data["reserva"] ?? [];

      setState(() {
        _todasReservas = reserva.map<Map<String, dynamic>>((m) => Map<String, dynamic>.from(m)).toList(); 
      });
    }
  }

  Future<void> cancelarreserva(id) async {
    final url = Uri.parse("https://apphuellitas-production.up.railway.app/cancelar_reserva");

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        
        body: jsonEncode({
          "id": id,
        }),
      );
      if (response.statusCode == 200) {
        mostrarMensajeFlotante(
          context,
          "✅ Reserva cancelada correctamente",
          colorFondo: const Color.fromARGB(255, 243, 243, 243),
          colorTexto: const Color.fromARGB(255, 0, 0, 0),
        );

        await _obtenerreservas();

        // Limpiar selección de fecha y hora
        setState(() {
          Navigator.pop(context);
        });

      } else {
        mostrarMensajeFlotante(
          context,
          "❌ Error: No se pudo cancelar la reserva",
          colorFondo: Colors.white,
          colorTexto: Colors.redAccent,

        );
      }
    } catch (e) {
      mostrarMensajeFlotante(
        context,
        "❌ Error al cancelar reserva: $e",
      );
    }
  }

  Future<void> completada(id) async {
    final url = Uri.parse("https://apphuellitas-production.up.railway.app/reserva_completada");

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        
        body: jsonEncode({
          "id": id,
        }),
      );
      if (response.statusCode == 200) {
        mostrarMensajeFlotante(
          context,
          "✅ Reserva completada correctamente",
          colorFondo: const Color.fromARGB(255, 243, 243, 243),
          colorTexto: const Color.fromARGB(255, 0, 0, 0),
        );

        await _obtenerreservas();

        // Limpiar selección de fecha y hora
        setState(() {
          Navigator.pop(context);
        });

      } else {
        mostrarMensajeFlotante(
          context,
          "❌ Error: No se pudo marcar la reserva como completada.",
          colorFondo: Colors.white,
          colorTexto: Colors.redAccent,

        );
      }
    } catch (e) {
      mostrarMensajeFlotante(
        context,
        "❌ Error: No se pudo marcar la reserva como completada: $e",
      );
    }
  }

  Future<void> aceptarreserva(id) async {
    final url = Uri.parse("https://apphuellitas-production.up.railway.app/reserva_aceptada");

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        
        body: jsonEncode({
          "id": id,
        }),
      );
      if (response.statusCode == 200) {
        mostrarMensajeFlotante(
          context,
          "✅ Reserva aceptada correctamente",
          colorFondo: const Color.fromARGB(255, 243, 243, 243),
          colorTexto: const Color.fromARGB(255, 0, 0, 0),
        );

        await _obtenerreservas();

        // Limpiar selección de fecha y hora
        setState(() {
          Navigator.pop(context);
        });

      } else {
        mostrarMensajeFlotante(
          context,
          "❌ Error: No se pudo marcar la reserva como aceptada.",
          colorFondo: Colors.white,
          colorTexto: Colors.redAccent,

        );
      }
    } catch (e) {
      mostrarMensajeFlotante(
        context,
        "❌ Error: No se pudo marcar la reserva como aceptada: $e",
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
      case "aceptada":
        return Image.asset("assets/Correcto.png", width: 16, height: 16);
      case "pendiente":
        return Image.asset("assets/reloj-de-arena.png", width: 16, height: 16);
      case "cancelada":
        return Image.asset("assets/cancelar.png", width: 16, height: 16);
      case "no recogida":
        return Image.asset("assets/cancelar.png", width: 16, height: 16);
      case "recogida":
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
           
          },
        ),
        title: Text(
          "Calendario de reservas",
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
                image: AssetImage("assets/descarga.jpeg"),
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
        final citasDelDia = _todasReservas.where((cita) {
        // obtener la fecha de la cita
        final citaFechaStr = cita["fecha_reserva"]?.toString() ?? '';
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
          if (estado == "aceptada") {
            colorCita = Colors.green;
          } else if (estado == "cancelada") {
            colorCita = Colors.red;
          } else if (estado == "no recogida") {
            colorCita = Colors.red;
          }  else if (estado == "recogida") {
            colorCita = const Color.fromARGB(255, 36, 146, 215);
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
  Map<String, List<dynamic>> pedidosAgrupados = {};
  for (var cita in citas) {
    String idPedido = cita["idreserva"].toString();

    if (!pedidosAgrupados.containsKey(idPedido)) {
      pedidosAgrupados[idPedido] = [];
    }

    pedidosAgrupados[idPedido]!.add(cita);
  }

  List<Widget> botones = [];
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
                  "Reservas del día",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 2
                      ..color = Colors.black, // borde negro
                  ),
                ),
                // Texto blanco encima
                const Text(
                  "Reservas del día",
                  style: TextStyle(
                    fontSize: 20,
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
                child: Text("No hay reservas para este día"),
              )
            else 
              Flexible(
                child: SingleChildScrollView(
                  
                  child: Column(
                    children: pedidosAgrupados.entries.map((entry) {
                      final idPedido = entry.key;
                      final productos = entry.value;
                      final primerItem = productos[0];
                      final estado = primerItem["estado"].toString().toLowerCase();
                      final nombreCliente = "${primerItem["nombre_cliente"]} ${primerItem["apellido_cliente"]}";
                      double totalPedido = productos.fold(
                        0,
                        (sum, item) => sum + (double.tryParse(item["total"].toString()) ?? 0),
                      );
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFEFEF),
                          borderRadius: BorderRadius.circular(16),
                        ),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // 🔵 TÍTULO DEL PEDIDO
                            Text(
                              "Reservado por $nombreCliente",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 12),

                            Column(
                              children: productos.map<Widget>((cita) {
                                return _tarjetaProducto(cita);  
                              }).toList(),
                            ),

                            const SizedBox(height: 12),

                            Divider(
                              thickness: 1,
                              color: Colors.grey.shade300,

                            ),

                            Row(
                              children: [
                                Image.asset("assets/Calendario1.png", width: 16, height: 16),
                                const SizedBox(width: 4),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: "Fecha de vencimiento: ",
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                      ),
                                      TextSpan(
                                        text: primerItem["fecha_vencimiento"] ?? "Desconocido",
                                        style: const TextStyle(color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 5),

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
                                        text: primerItem["tipo_pago"] ?? "N/A",
                                        style: const TextStyle(color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),

                            // ESTADO
                            Row(
                              children: [
                                getImagenEstado(primerItem["estado"] ?? ""),
                                const SizedBox(width: 4),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: "Estado: ",
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                      ),
                                      TextSpan(
                                        text: primerItem["estado"] ?? "Desconocido",
                                        style: const TextStyle(color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  "Total:  ${NumberFormat('#,###', 'es_CO').format(totalPedido)}",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            if (estado == "pendiente")
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // 🔴 Botón Cancelar
                                ElevatedButton.icon(
                                  onPressed: () {
                                    mostrarConfirmacion(
                                      context,
                                      mensaje: "¿Deseas cancelar esta reserva?",
                                      onConfirmar: () => cancelarreserva(primerItem["idreserva"]),
                                    );
                                  },
                                  icon: Image.asset("assets/cancelar.png", width: 20, height: 20),
                                  label: const Text("Cancelar reserva", style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 202, 65, 65),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 16), 

                                ElevatedButton.icon(
                                  onPressed: () {
                                    mostrarConfirmacion(
                                      context,
                                      mensaje: "¿Deseas aceptar esta reserva?",
                                      onConfirmar: () => aceptarreserva(primerItem["idreserva"]),
                                    );
                                  },
                                  icon: Image.asset("assets/Correcto.png", width: 20, height: 20),
                                  label: const Text("Aceptar reserva", style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 55, 131, 58),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if (estado == "aceptada")
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Botón NO RECIBIDO
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      mostrarConfirmacion(
                                      context,
                                      mensaje: "¿Confirmas que ya el cliente recogio la reserva?",
                                      onConfirmar: () => completada(primerItem["idreserva"]),
                                      );
                                    },
                                    icon: Image.asset("assets/Correcto.png", width: 20, height: 20),
                                    label: const Text("Recogida", style: TextStyle(color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(255, 66, 176, 85),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ],
                              ),

                        ],
                      ));

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

  Widget _tarjetaProducto(Map cita) {
    final nombre = _capitalizar(cita["nombre_producto"] ?? "Sin nombre");
    final foto = cita["imagen_producto"];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(blurRadius: 4, color: Colors.black26),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FOTO
              ClipOval(
                child: foto != null
                    ? Image.memory(
                        base64Decode(foto),
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

              // INFORMACIÓN
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Text(
                          ("$nombre"),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 5, 5, 5)
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    // PRECIO
                    Row(
                      children: [
                        Image.asset("assets/precio.png", width: 18, height: 18),
                        const SizedBox(width: 4),
                        RichText(
                          text: TextSpan(
                            children: [
                              
                              TextSpan(
                                text: NumberFormat('#,###', 'es_CO')
                                    .format(double.tryParse(cita['precio_producto'].toString()) ?? 0),
                                style: const TextStyle(color: Colors.black, fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "x${cita['cantidad'] ?? 0}",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),


                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _capitalizar(String texto) {
    if (texto.isEmpty) return texto;
    return texto[0].toUpperCase() + texto.substring(1).toLowerCase();
  }

}
