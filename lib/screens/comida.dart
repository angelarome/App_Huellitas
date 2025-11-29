import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart'; 

class SimpleFoodWaterCalendar extends StatefulWidget {
final int idMascota;

const SimpleFoodWaterCalendar({super.key, required this.idMascota});

@override
_SimpleFoodWaterCalendarState createState() => _SimpleFoodWaterCalendarState();
}

class _SimpleFoodWaterCalendarState extends State<SimpleFoodWaterCalendar> {
  bool _loading = true;
  bool yaTieneDatos = false;
  int _ultimoTotalComida = 0;
  int _ultimoTotalAgua = 0;
  Map<int, bool> _diasComida = {};
  Map<int, bool> _diasAgua = {};

  @override
  void initState() {
    super.initState();
    _cargarDatosDia();
  }

  List<Map<String, dynamic>> comida = [];
  final comidaController = TextEditingController();
  final aguaController = TextEditingController();
  TextEditingController _totalcomidaController = TextEditingController();
  TextEditingController _totalaguaController = TextEditingController();

  Future _cargarDatosDia() async {
    setState(() {
      _loading = true;
    });

    final url = Uri.parse("http://localhost:5000/Comida");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_mascota": widget.idMascota}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List comidaJson = data["comida"] ?? [];

      // Mapas para marcar los días en el calendario
      Map<int, bool> diasComida = {};
      Map<int, bool> diasAgua = {};

      int totalComida = 0;
      int totalAgua = 0;

      for (var item in comidaJson) {
        final fecha = DateTime.parse(item["fecha"]);
        final dia = fecha.day;

        if ((item["gramos_consumidos"] ?? 0) > 0) diasComida[dia] = true;
        if ((item["agua_consumidos"] ?? 0) > 0) diasAgua[dia] = true;
      }

      // Buscar el último registro válido (no 0 ni null) para total de comida y agua
      for (var item in comidaJson.reversed) {
        if ((item["gramos_totales_dia"] ?? 0) > 0 && totalComida == 0) {
          totalComida = item["gramos_totales_dia"];
        }
        if ((item["agua_total_dia"] ?? 0) > 0 && totalAgua == 0) {
          totalAgua = item["agua_total_dia"];
        }
        if (totalComida > 0 && totalAgua > 0) break;
      }

      // Guardar los últimos totales en variables de estado
      _ultimoTotalComida = totalComida;
      _ultimoTotalAgua = totalAgua;
      setState(() {
        comida = List<Map<String, dynamic>>.from(comidaJson);
        _totalcomidaController.text = totalComida.toString();
        _totalaguaController.text = totalAgua.toString();
        _diasComida = diasComida;
        _diasAgua = diasAgua;
        _loading = false;
      });

      // Si no llega ningún dato, mostramos el diálogo para registrar totales
      if (comidaJson.isEmpty) {
        await _showAddDailyIntakeDialog(context, 1);
      }
    } else {
      setState(() {
        _loading = false;
      });
      mostrarMensajeFlotante(
        context,
        "❌ Error: ${response.statusCode}",
        colorFondo: Colors.white,
        colorTexto: Colors.redAccent,
      );
    }
}


  Future<void> guardarDatosTotal() async {
    if (comidaController.text.isEmpty || aguaController.text.isEmpty) {
      mostrarMensajeFlotante(
        context,
        "❌ Por favor, completa todos los campos",
        colorFondo: Colors.white,
        colorTexto: Colors.redAccent,
      );
      return; // Sale de la función si hay campos vacíos
    }

    final url = Uri.parse("http://localhost:5000/GuardarComida");

    final body = {
      "id_mascota": widget.idMascota,
      "gramos_totales_dia": comidaController.text,
      "agua_total_dia": aguaController.text,
      
    };

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      setState(() {
        yaTieneDatos = true; // ahora sí muestra el calendario
      });
      Navigator.pop(context);
      mostrarMensajeFlotante(
        context,
        "✅ Datos de comida guardados correctamente",
        colorFondo: const Color.fromARGB(255, 186, 237, 150), // verde bonito
        colorTexto: const Color.fromARGB(255, 0, 0, 0),
      );
      await _cargarDatosDia();
    } else {
      mostrarMensajeFlotante(
        context,
        "❌ Error: ${response.statusCode}",
        colorFondo: Colors.white,
        colorTexto: Colors.redAccent,

      );
    }
  }

  Future<void> actualizarDatosTotal(int gramosTotales, int aguaTotal) async {
    final url = Uri.parse("http://localhost:5000/ActualizarComida");

    final body = {
      "id_mascota": widget.idMascota,
      "gramos_totales_dia": gramosTotales, // <-- usar el parámetro
      "agua_total_dia": aguaTotal,         // <-- usar el parámetro
    };

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      setState(() {
        yaTieneDatos = true;
      });
      mostrarMensajeFlotante(
        context,
        "✅ Datos de comida guardados correctamente",
        colorFondo: const Color.fromARGB(255, 186, 237, 150),
        colorTexto: const Color.fromARGB(255, 0, 0, 0),
      );
      await _cargarDatosDia();
    } else {
      mostrarMensajeFlotante(
        context,
        "❌ Error: ${response.statusCode}",
        colorFondo: Colors.white,
        colorTexto: Colors.redAccent,
      );
    }
  }

  Future<void> _showAddDailyIntakeDialog(BuildContext context, int day) async {
    final comidaController = TextEditingController();
    final aguaController = TextEditingController();

    double totalComida = 0; // Aquí puedes traer el total desde tu base de datos si quieres
    double totalAgua = 0;

    await showDialog(
    context: context,
    builder: (context) {
    return AlertDialog(
    contentPadding: const EdgeInsets.all(16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    content: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
    // Título con estilo
    Stack(
    children: [
    Text(
    "Registrar Total Diario",
    style: TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    foreground: Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = Colors.black,
    ),
    ),
    const Text(
    "Registrar Total Diario",
    style: TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    ),
    ),
    ],
    ),
            const SizedBox(height: 16),

            // Input comida
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Cantidad de comida (g)",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: comidaController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: "Ej: 200",
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset("assets/comi.png", width: 24, height: 24),
                    ),
                    suffixText: "g",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 6),
                Text("Total comida hoy: ${totalComida.toStringAsFixed(0)} g",
                    style: TextStyle(color: Colors.black54, fontSize: 14)),
              ],
            ),

            const SizedBox(height: 12),

            // Input agua
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Cantidad de agua (ml)",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: aguaController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: "Ej: 500",
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset("assets/gotass.png", width: 24, height: 24),
                    ),
                    suffixText: "ml",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 6),
                Text("Total agua hoy: ${totalAgua.toStringAsFixed(0)} ml",
                    style: TextStyle(color: Colors.black54, fontSize: 14)),
              ],
            ),

            const SizedBox(height: 16),

            // Botones
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Image.asset("assets/cancelar.png", width: 24, height: 24),
                    label: const Text(
                      "Cancelar",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Image.asset("assets/Correcto.png", width: 24, height: 24),
                    label: const Text(
                      "Guardar",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      this.comidaController.text = comidaController.text;
                      this.aguaController.text = aguaController.text;
                      guardarDatosTotal(); // ✅ funciona porque está en el mismo State
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },

    );
  }

  Future<String?> showEditTotalsDialog(BuildContext context, {int totalComida = 200, int totalAgua = 500}) async {
  final comidaController = TextEditingController(text: totalComida.toString());
  final aguaController = TextEditingController(text: totalAgua.toString());

  return await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        contentPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título con estilo
            Stack(
              children: [
                Text(
                  "Ajustes de totales",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 3
                      ..color = Colors.black,
                  ),
                ),
                const Text(
                  "Ajustes de totales",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Input comida
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Total comida (g)",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: comidaController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: "Ej: 200",
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset("assets/comi.png", width: 24, height: 24),
                    ),
                    suffixText: "g",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 6),
                Text("Total comida actual: ${totalComida.toString()} g",
                    style: TextStyle(color: Colors.black54, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 12),

            // Input agua
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Total agua (ml)",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: aguaController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: "Ej: 500",
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset("assets/gotass.png", width: 24, height: 24),
                    ),
                    suffixText: "ml",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 6),
                Text("Total agua actual: ${totalAgua.toString()} ml",
                    style: TextStyle(color: Colors.black54, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 16),

            // Botones
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Image.asset("assets/cancelar.png", width: 24, height: 24),
                    label: const Text(
                      "Cancelar",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => Navigator.pop(context, null),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 204, 184, 82),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Image.asset("assets/Editar.png", width: 24, height: 24),
                    label: const Text(
                      "Editar",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                    // Validar primero
                    if (comidaController.text.isEmpty || aguaController.text.isEmpty) {
                      mostrarMensajeFlotante(
                        context,
                        "❌ Por favor, completa todos los campos",
                        colorFondo: Colors.white,
                        colorTexto: Colors.redAccent,
                      );
                      return;
                    }

                    final gramosTotales = int.tryParse(comidaController.text) ?? 0;
                    final aguaTotal = int.tryParse(aguaController.text) ?? 0;

                    if (gramosTotales == 0 || aguaTotal == 0) {
                      mostrarMensajeFlotante(
                        context,
                        "❌ Ingresa valores válidos mayores que 0",
                        colorFondo: Colors.white,
                        colorTexto: Colors.redAccent,
                      );
                      return;
                    }
                    Navigator.pop(context);
                    await actualizarDatosTotal(gramosTotales, aguaTotal);
                  },

                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}


  Future<void> guardarDatosComida(DateTime date, String gramos) async {
    final fechaStr = "${date.year.toString().padLeft(4,'0')}-"
                    "${date.month.toString().padLeft(2,'0')}-"
                    "${date.day.toString().padLeft(2,'0')}";

    final url = Uri.parse("http://localhost:5000/EditarComida");

    // Convertir los valores a int
    final gramosInt = int.tryParse(gramos) ?? 0;

    final body = {
      "id_mascota": widget.idMascota,
      "fecha": fechaStr,
      "gramos": gramosInt,

    };

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      setState(() {
        yaTieneDatos = true;
      });
      mostrarMensajeFlotante(
        context,
        "✅ Datos de comida guardados correctamente",
        colorFondo: const Color.fromARGB(255, 186, 237, 150),
        colorTexto: const Color.fromARGB(255, 0, 0, 0),
      );

      await _cargarDatosDia();  

    } else {
      mostrarMensajeFlotante(
        context,
        "❌ Error: ${response.statusCode}",
        colorFondo: Colors.white,
        colorTexto: Colors.redAccent,
      );
    }
  }

  Future<void> guardarDatosAgua(DateTime date, String agua) async {
    final fechaStr = "${date.year.toString().padLeft(4,'0')}-"
                    "${date.month.toString().padLeft(2,'0')}-"
                    "${date.day.toString().padLeft(2,'0')}";

    final url = Uri.parse("http://localhost:5000/EditarAgua");

    // Convertir los valores a int
    final aguaInt = int.tryParse(agua) ?? 0;

    final body = {
      "id_mascota": widget.idMascota,
      "fecha": fechaStr,
      "agua": aguaInt,
    };

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      setState(() {
        yaTieneDatos = true;
      });
      mostrarMensajeFlotante(
        context,
        "✅ Cantidad de agua guardados correctamente",
        colorFondo: const Color.fromARGB(255, 186, 237, 150),
        colorTexto: const Color.fromARGB(255, 0, 0, 0),
      );

      await _cargarDatosDia();  

    } else {
      mostrarMensajeFlotante(
        context,
        "❌ Error: ${response.statusCode}",
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

 @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: [
        // Fondo con imagen
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/comidass.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),

        // Blur + overlay
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
        ),

        // Contenido con scroll
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0), // ahora sí solo afecta el contenido
            child: Column(
              children: [
                _barraSuperior(context),
                const SizedBox(height: 20),

                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                  onPressed: () async {
                  final result = await showEditTotalsDialog(
                  context,
                  totalComida: _ultimoTotalComida,
                  totalAgua: _ultimoTotalAgua,
                  );
                    if (result != null) {
                      final partes = result.split(",");
                      setState(() {
                        _ultimoTotalComida = int.tryParse(partes[0]) ?? _ultimoTotalComida;
                        _ultimoTotalAgua = int.tryParse(partes[1]) ?? _ultimoTotalAgua;
                      });
                      // opcional: guardar los totales en tu backend si lo manejas allí
                    }
                  },
                  icon: Image.asset(
                    "assets/engranaje.png",
                    width: 24,
                    height: 24,
                  ),
                  label: const Text("Ajustes de totales"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 97, 95, 92),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),


                  ),
                  ),

                const SizedBox(height: 10),
                // Calendario Comida
                const _HeaderMes(titulo: "Comida"),
                const SizedBox(height: 10),
                const _DiasSemana(),
                const SizedBox(height: 10),
                Container(
                  height: 350,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 30,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (context, index) {
                      return _DayCard(
                        day: index + 1,
                        tipo: "comida",
                        yaComio: _diasComida[index + 1] ?? false, // marca si ya comió
                        onTap: (d) async {
                          final diaData = comida.firstWhere(
                            (c) => DateTime.parse(c["fecha"]).day == d,
                            orElse: () => {
                              "gramos_consumidos": 0,
                              // ya no necesitamos poner el total aquí
                            },
                          );

                          final yaComido = diaData["gramos_consumidos"] ?? 0;
                          final totalDia = _ultimoTotalComida > 0 ? _ultimoTotalComida : 200; // usa el último total

                          final gramos = await showAddFoodDialog(
                            context,
                            d,
                            yaComido: yaComido,
                            totalDia: totalDia,
                          );

                          if (gramos != null && gramos.isNotEmpty) {
                            final date = DateTime(DateTime.now().year, DateTime.now().month, d);
                            await guardarDatosComida(date, gramos);
                            await _cargarDatosDia();
                          }
                        },
                        
                      );
                    },
                  ),
                ),

                const SizedBox(height: 30),

                // Calendario Agua
                const _HeaderMes(titulo: "Agua"),
                const SizedBox(height: 10),
                const _DiasSemana(),
                const SizedBox(height: 10),
                Container(
                  height: 350,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 30,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (context, index) {
                    return _DayCard(
                      day: index + 1,
                      tipo: "agua",
                      yaBebio: _diasAgua[index + 1] ?? false,
                      onTap: (d) async {
                        // Buscar si ya hay datos de ese día
                        final diaData = comida.firstWhere(
                        (c) => DateTime.parse(c["fecha"]).day == d,
                        orElse: () => {"agua_consumidos": 0},
                        );

                        final yaBebido = diaData["agua_consumidos"] ?? 0;
                        final totalDia = _ultimoTotalAgua > 0 ? _ultimoTotalAgua : 500; // valor predeterminado si no hay registro

                        // Abrir el diálogo de agua pasando yaBebido y totalDia
                        final ml = await showAddWaterDialog(
                        context,
                        d,
                        yaTomado: yaBebido,
                        totalDia: totalDia,
                        );

                        if (ml != null && ml.isNotEmpty) {
                        final date = DateTime(DateTime.now().year, DateTime.now().month, d);
                        await guardarDatosAgua(date, ml);
                        await _cargarDatosDia(); // recarga para actualizar el calendario
                        }
                        }

                    );
                  },
                  ),

                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

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
              
            }),
            const SizedBox(width: 10),
            _iconoTop("assets/Calendr.png", () {}),
            const SizedBox(width: 10),
            _iconoTop("assets/Campana.png", () {}),
          ],
        )

        
      ],
    );
  }

Widget _iconoTop(String assetPath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 24,
        height: 24,
        child: Image.asset(assetPath),
      ),
    );
  }

void _toggleMenu() {
    // Lógica para abrir/cerrar el menú lateral
  }
class _HeaderMes extends StatelessWidget {
  final String titulo;

  const _HeaderMes({required this.titulo});

  @override
Widget build(BuildContext context) {
  final now = DateTime.now();
  final mesAno = DateFormat("MMMM yyyy").format(now); // ej: noviembre 2025

  return Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    margin: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: LinearGradient(
        colors: [Colors.blue.shade700, Colors.blue.shade400],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 6,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.calendar_today, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Text(
          "$titulo - $mesAno",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black26,
                offset: Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
}

// ------------------------------------------------------------
// DÍAS DE LA SEMANA
// ------------------------------------------------------------
class _DiasSemana extends StatelessWidget {
  const _DiasSemana({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      margin: const EdgeInsets.symmetric(vertical: 8), // separación opcional
      decoration: BoxDecoration(
        color: Colors.white, // fondo blanco
        borderRadius: BorderRadius.circular(12), // esquinas redondeadas
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          _WeekDay("L"),
          _WeekDay("M"),
          _WeekDay("X"),
          _WeekDay("J"),
          _WeekDay("V"),
          _WeekDay("S"),
          _WeekDay("D"),
        ],
      ),
    );
  }
}

class _WeekDay extends StatelessWidget {
  final String label;
  const _WeekDay(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// TARJETA DE CADA DÍA
// ------------------------------------------------------------
class _DayCard extends StatelessWidget {
  final int day;
  final String tipo;
  final bool yaComio;
  final bool yaBebio;
  final Function(int) onTap;

  const _DayCard({
    required this.day,
    required this.tipo,
    required this.onTap,
    this.yaComio = false,
    this.yaBebio = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Icon icono;
    Color bgColor = Colors.white;

    if (tipo == "comida") {
      icono = Icon(Icons.restaurant, size: 16, color: yaComio ? Colors.green : Colors.orange);
      if (yaComio) bgColor = Colors.green.shade100;
    } else {
      icono = Icon(Icons.local_drink, size: 16, color: yaBebio ? Colors.blue : Colors.blue.shade300);
      if (yaBebio) bgColor = Colors.blue.shade100;
    }

    return GestureDetector(
      onTap: () => onTap(day),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: const [
            BoxShadow(
              blurRadius: 3,
              color: Colors.black12,
              offset: Offset(0, 2),
            )
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 6),
            Text(
              "$day",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            icono,
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
// ------------------------------------------------------------
// DIÁLOGO PARA REGISTRAR **COMIDA**
// ------------------------------------------------------------
Future<String?> showAddFoodDialog(BuildContext context, int day, {int totalDia = 0, int yaComido = 0}) async {
  final ateController = TextEditingController();

  return await showDialog<String>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          // Total actual = yaComido + lo que ingresa el usuario
          final totalActual = yaComido + (int.tryParse(ateController.text) ?? 0);

          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Text(
                      "Registrar comida",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 3
                          ..color = Colors.black,
                      ),
                    ),
                    const Text(
                      "Registrar comida",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: ateController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: "Ej: 200 g",
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset("assets/comi.png", width: 24, height: 24),
                    ),
                    suffixText: "g",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (_) => setState(() {}), // recalcula totalActual
                ),
                const SizedBox(height: 6),
                Text(
                  "Total comida hoy: ${yaComido + (int.tryParse(ateController.text) ?? 0)}/$totalDia g",
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        icon: Image.asset("assets/cancelar.png", width: 24, height: 24),
                        label: const Text("Cancelar"),
                        onPressed: () => Navigator.pop(context, null),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        icon: Image.asset("assets/Correcto.png", width: 24, height: 24),
                        label: const Text("Guardar"),
                        onPressed: () => Navigator.pop(context, ateController.text),
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      );
    },
  );
}


// ----------

Future<String?> showAddWaterDialog(BuildContext context, int day, {int totalDia = 0, int yaTomado = 0}) async {
final drankController = TextEditingController();

return await showDialog<String>(
context: context,
builder: (context) {
return StatefulBuilder(
builder: (context, setState) {
// Total actual = yaTomado + lo que ingresa el usuario
final totalActual = yaTomado + (int.tryParse(drankController.text) ?? 0);


      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Text(
                  "Registrar agua",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 3
                      ..color = Colors.black,
                  ),
                ),
                const Text(
                  "Registrar agua",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: drankController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: "Ej: 500 ml",
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset("assets/gotass.png", width: 24, height: 24),
                ),
                suffixText: "ml",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (_) => setState(() {}), // recalcula totalActual
            ),
            const SizedBox(height: 6),
            Text(
              "Total agua hoy: $totalActual/$totalDia ml",
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    icon: Image.asset("assets/cancelar.png", width: 24, height: 24),
                    label: const Text("Cancelar"),
                    onPressed: () => Navigator.pop(context, null),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    icon: Image.asset("assets/Correcto.png", width: 24, height: 24),
                    label: const Text("Guardar"),
                    onPressed: () => Navigator.pop(context, drankController.text),
                  ),
                ),
              ],
            )
          ],
        ),
      );
    },
  );
},

);
}





