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
import 'mascotasCompartidas.dart';
import 'calendario.dart';
import 'menu_lateral.dart';
import 'compartirmascota.dart';

class CalendarioEventosScreen extends StatefulWidget {
  final int id_dueno;

  const CalendarioEventosScreen({super.key, required this.id_dueno});

  @override
  _CalendarioEventosScreenState createState() => _CalendarioEventosScreenState();
}

class _CalendarioEventosScreenState extends State<CalendarioEventosScreen> {
  DateTime _mesActual = DateTime(DateTime.now().year, DateTime.now().month);

  List<Map<String, dynamic>> _todaAgenda = [];
  
  @override
  void initState() {
    super.initState();
    _obteneragenda(); 
  }

  bool _menuAbierto = false;

  void _toggleMenu() {
    setState(() {
      _menuAbierto = !_menuAbierto;
    });
  }

  List<Map<String, dynamic>> _citasDelDiaActual = []; 

  Future<void> _obteneragenda() async {
    
    final url = Uri.parse("https://apphuellitas-production.up.railway.app/miagenda");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_dueno": widget.id_dueno}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List agenda = data["agenda"] ?? []; 

      setState(() {
        _todaAgenda = agenda.map<Map<String, dynamic>>((m) => Map<String, dynamic>.from(m)).toList(); 
      });
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
      case "enviado":
        return Image.asset("assets/Correcto.png", width: 16, height: 16);
      case "pendiente":
        return Image.asset("assets/reloj-de-arena.png", width: 16, height: 16);
      case "cancelado":
        return Image.asset("assets/cancelar.png", width: 16, height: 16);
      case "no recibido":
        return Image.asset("assets/cancelar.png", width: 16, height: 16);
      case "recibido":
        return Image.asset("assets/correcto.png", width: 16, height: 16);
      default:
        return Image.asset("assets/cancelar.png", width: 16, height: 16);
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    extendBodyBehindAppBar: true, // si quieres que el fondo llegue hasta arriba
    body: Stack(
      children: [
        // ------------ FONDO ------------
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/hut-9582608_1280.jpg"),
              fit: BoxFit.cover,
            ),
          ),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(color: Colors.black.withOpacity(0.25)),
        ),

        // ------------ BARRA SUPERIOR PERSONALIZADA ------------
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
        const SizedBox(height: 120),

        Column(
          children: [
            SizedBox(height: 90), // separación debajo de la barra superior
            _headerBonito(),
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

  DateTime addMonthsSafe(DateTime fecha, int months) {
    int newYear = fecha.year + ((fecha.month + months - 1) ~/ 12);
    int newMonth = (fecha.month + months - 1) % 12 + 1;

    // Obtener el último día del mes resultante
    int lastDayOfMonth = DateTime(newYear, newMonth + 1, 0).day;

    // Ajustar el día si es mayor al último día del mes
    int day = fecha.day <= lastDayOfMonth ? fecha.day : lastDayOfMonth;

    return DateTime(newYear, newMonth, day);
  }
  List<DateTime> expandirFechas(DateTime fechaOriginal, String frecuencia) {
  List<DateTime> fechas = [];

  switch (frecuencia.toLowerCase()) {
    case 'Diario':
      for (int i = 0; i < 30; i++) fechas.add(fechaOriginal.add(Duration(days: i)));
      break;
    case 'Semanal':
      for (int i = 0; i < 8; i++) fechas.add(fechaOriginal.add(Duration(days: i * 7)));
      break;
    case 'Quincenal':
      for (int i = 0; i < 6; i++) fechas.add(fechaOriginal.add(Duration(days: i * 14)));
      break;
    case 'Mensual':
      for (int i = 0; i < 12; i++) fechas.add(addMonthsSafe(fechaOriginal, i));
      break;
    case 'Cada 3 meses':
      for (int i = 0; i < 4; i++) fechas.add(addMonthsSafe(fechaOriginal, i * 3));
      break;
    case 'Anual':
      for (int i = 0; i < 5; i++) fechas.add(DateTime(fechaOriginal.year + i, fechaOriginal.month, fechaOriginal.day));
      break;
    case 'Una sola vez':
    default:
      fechas.add(fechaOriginal);
  }

  return fechas;
}

Widget _gridDias() {
  final primerDia = DateTime(_mesActual.year, _mesActual.month, 1);
  final ultimoDia = DateTime(_mesActual.year, _mesActual.month + 1, 0);
  final totalDias = ultimoDia.day;
  final inicioSemana = primerDia.weekday % 7;

  return GridView.builder(
    padding: EdgeInsets.symmetric(horizontal: 16),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 7,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
    ),
    itemCount: totalDias + inicioSemana,
    itemBuilder: (context, index) {
      if (index < inicioSemana) return SizedBox();

      final dia = index - inicioSemana + 1;
      final fecha = DateTime(_mesActual.year, _mesActual.month, dia);

      final citasDelDia = _todaAgenda.expand((cita) {
        List<Map<String, dynamic>> citasExpandidas = [];

        DateTime fechaOriginal;
        try {
          fechaOriginal = DateTime.parse(cita["higiene_fecha"] ?? cita["medicamento_fecha"] ?? '');
        } catch (e) {
          return [];
        }

        final String frecuencia = (cita['higiene_frecuencia'] ?? cita['medicamento_frecuencia'] ?? '');
        final String diasPersonalizados = (cita['higiene_dias_personalizados'] ?? cita['medicamento_dias_personalizados'] ?? '').toLowerCase();

        // Expandir todas las fechas según frecuencia
        List<DateTime> fechasPosibles = expandirFechas(fechaOriginal, frecuencia);

        // Agregar días personalizados
        if (diasPersonalizados.isNotEmpty) {
          List<String> dias = diasPersonalizados.split(',').map((d) => d.trim().toLowerCase()).toList();
          for (int i = 0; i < 7; i++) {
            DateTime diaSemana = fecha.subtract(Duration(days: fecha.weekday - 1)).add(Duration(days: i));
            String nombreDia = ["Lun","Mar","Mié","Jue","Vie","Sáb","Dom"][i];
            if (dias.contains(nombreDia)) fechasPosibles.add(diaSemana);
          }
        }

        // Solo agregar si coincide con el día del grid
        for (var f in fechasPosibles) {
          if (f.year == fecha.year && f.month == fecha.month && f.day == fecha.day) {
            citasExpandidas.add(cita);
            break; // no agregar duplicadas
          }
        }

        return citasExpandidas;
      }).toList().cast<Map<String, dynamic>>();

      final bool tieneCita = citasDelDia.isNotEmpty;
      Color colorCita = const Color.fromARGB(0, 105, 186, 253);
      if (tieneCita) {
        colorCita = Colors.blue; // cualquier cita que llegue será azul
      }

      return GestureDetector(
        onTap: () => _mostrarCitasDelDia(citasDelDia),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorCita, width: 2),
            boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black26)],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 6,
                right: 6,
                child: Text("$dia", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              ),
              if (tieneCita)
                Positioned(
                  bottom: 6,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(width: 10, height: 10, decoration: BoxDecoration(color: colorCita, shape: BoxShape.circle)),
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
    _citasDelDiaActual = citas; // Guardamos todas las citas del día
  });

  List<Widget> botones = [];
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
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
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 12),
            Stack(
              children: [
                Text(
                  "Agenda del día",
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
                  "Agenda del día",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const Divider(),
            if (citas.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("No hay agenda para este día"),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: citas.expand((pedido) {
                      final List<Widget> tarjetas = [];

                      // Datos de la mascota
                      final String nombreMascota = pedido["nombre_mascota"] ?? "Sin nombre";
                      final String imagenMascota = pedido["imagen_perfil"] ?? "";

                      // 1️⃣ Higiene
                      if (pedido.containsKey("id_higiene") && pedido["id_higiene"] != null) {
                        final String horaHigieneOriginal = pedido['higiene_hora'] ?? '';
                        final String horaHigiene = horaHigieneOriginal.split(':').sublist(0, 2).join(':');
                        final String frecuencia = pedido['higiene_frecuencia'] ?? '';
                        final String dias_p = pedido['higiene_dias_personalizados'] ?? '';
                        final String notas = pedido['higiene_notas'] ?? '';

                        tarjetas.add(Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 161, 219, 255),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              ClipOval(
                                child: (imagenMascota.isNotEmpty)
                                    ? Image.memory(
                                        base64Decode(imagenMascota),
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.asset(
                                        "assets/default_pet.png",
                                        width: 60,
                                        height: 60,
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
                                          fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    RichText(
                                      text: TextSpan(
                                        style: const TextStyle(fontSize: 14, color: Colors.black), // estilo base
                                        children: [
                                          const TextSpan(
                                            text: "Tipo: ",
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          const TextSpan(
                                            text: "Higiene\n",
                                          ),
                                          if (frecuencia.isNotEmpty) ...[
                                            const TextSpan(
                                              text: "Frecuencia: ",
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            TextSpan(
                                              text: "$frecuencia\n",
                                            ),
                                          ],
                                          if (dias_p.isNotEmpty) ...[
                                            const TextSpan(
                                              text: "Días personalizados: ",
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            TextSpan(
                                              text: "$dias_p\n",
                                            ),
                                          ],
                                          if (horaHigiene.isNotEmpty) ...[
                                            const TextSpan(
                                              text: "Hora: ",
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            TextSpan(
                                              text: "$horaHigiene\n",
                                            ),
                                          ],
                                          if (notas.isNotEmpty) ...[
                                            const TextSpan(
                                              text: "Notas: ",
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            TextSpan(
                                              text: "$notas\n",
                                            ),
                                          ],
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ));
                      }

                      // 2️⃣ Medicamento
                      if (pedido.containsKey("id_medicamento") && pedido["id_medicamento"] != null) {
                        final String horaMedOri = pedido['medicamento_hora'] ?? '';
                        final String horaMed = horaMedOri.split(':').sublist(0, 2).join(':');
                         final String frecuencia = pedido['medicamento_frecuencia'] ?? '';
                        final String personalizado = pedido['medicamento_dias_personalizados'] ?? '';
                        final String dosis = pedido['dosis'] ?? '';
                        final String unidad = pedido['unidad'] ?? '';
                        final String descripcion = pedido['medicamento_descripcion'] ?? '';

                        tarjetas.add(Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 157, 252, 193),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              ClipOval(
                                child: (imagenMascota.isNotEmpty)
                                    ? Image.memory(
                                        base64Decode(imagenMascota),
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.asset(
                                        "assets/default_pet.png",
                                        width: 60,
                                        height: 60,
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
                                          fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    RichText(
                                      text: TextSpan(
                                        style: const TextStyle(fontSize: 14, color: Colors.black), // estilo base
                                        children: [
                                          const TextSpan(
                                            text: "Tipo: ",
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          const TextSpan(
                                            text: "Medicamento\n",
                                          ),
                                          if (frecuencia.isNotEmpty) ...[
                                            const TextSpan(
                                              text: "Frecuencia: ",
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            TextSpan(
                                              text: "$frecuencia\n",
                                            ),
                                          ],
                                          if (personalizado.isNotEmpty) ...[
                                            const TextSpan(
                                              text: "Días personalizados: ",
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            TextSpan(
                                              text: "$personalizado\n",
                                            ),
                                          ],
                                          if (horaMed.isNotEmpty) ...[
                                            const TextSpan(
                                              text: "Hora: ",
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            TextSpan(
                                              text: "$horaMed\n",
                                            ),
                                          ],
                                          if (dosis.isNotEmpty || unidad.isNotEmpty) ...[
                                            const TextSpan(
                                              text: "Dosis: ",
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            TextSpan(
                                              text: "$dosis $unidad\n",
                                            ),
                                          ],
                                          if (descripcion.isNotEmpty) ...[
                                            const TextSpan(
                                              text: "Descripción: ",
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            TextSpan(
                                              text: "$descripcion\n",
                                            ),
                                          ],
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ));
                      }

                      return tarjetas; // Puede retornar 0, 1 o 2 tarjetas
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

  String capitalizar(String texto) {
    if (texto.isEmpty) return "";
    return texto[0].toUpperCase() + texto.substring(1).toLowerCase();
  }



}
