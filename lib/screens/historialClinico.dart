import 'package:flutter/material.dart';
import 'dart:ui'; // Para aplicar desenfoque si lo necesitas más adelante
import 'package:http/http.dart' as http; 
import 'dart:convert';  
import 'añadirmedicamento.dart';
import 'tarjetamedicamento.dart';
import 'agregar_historial.dart';
import 'editar_historial.dart'; 

class Historialclinico extends StatefulWidget {
  
  final int id;

  const Historialclinico({super.key, required this.id});
  @override
  State<Historialclinico> createState() => _HistorialclinicoState();
  
}

class _HistorialclinicoState extends State<Historialclinico> {
  bool _confirmado = false;
  List<Map<String, dynamic>> _historial = [];
  bool _menuAbierto = false; // 👈 define esto en tu StatefulWidget

  void _toggleMenu() {
    setState(() {
      _menuAbierto = !_menuAbierto;
    });
  }

  @override
  void initState() {
    super.initState();
    _obtenerHistorial(); // Llamamos a la API apenas se abre la pantalla
  }


  Future<void> _obtenerHistorial() async {
    final url = Uri.parse("http://localhost:5000/historialClinico");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_mascota": widget.id}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List historiaJson = data["historia"] ?? [];

      setState(() {
        _historial = List<Map<String, dynamic>>.from(historiaJson);
      });
    } else {
        print("Error al obtener la historia: ${response.statusCode}");
    }
  }


  Future<void> eliminarHistorial(int id_historial) async {
    final url = Uri.parse("http://localhost:5000/eliminar_historial");

    final response = await http.delete( // 👈 DELETE en lugar de POST
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id_historial": id_historial,
      }),
    );

    if (response.statusCode == 200) {
      mostrarMensajeFlotante(
        context,
        "✅ Historial eliminado correctamente",
        colorFondo: const Color.fromARGB(255, 243, 243, 243),
      );
      setState(() {
        _obtenerHistorial(); // vuelve a consultar la BD
      });

    } else {
      mostrarMensajeFlotante(
        context,
        "❌ Error: No se pudo elimar",
        colorFondo: Colors.white,
        colorTexto: Colors.redAccent,
      );
    }
  }

  void mostrarMensajeFlotante(
    BuildContext context,
    String mensaje, {
    Color colorFondo = Colors.white,
    Color colorTexto = Colors.black,
  }) {
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Fondo semitransparente que cierra el mensaje al tocarlo
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
    Overlay.of(context).insert(overlayEntry);
  }

  void mostrarConfirmacionRegistro(
  BuildContext context,
  int idHistorial, // 👉 Recibe el ID
) {
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
                  const Text(
                    '¿Deseas eliminar este historial médico?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // ❌ NO
                      ElevatedButton.icon(
                        onPressed: () {
                          overlayEntry?.remove();
                        },
                        icon: Image.asset("assets/cancelar.png", width: 24),
                        label: const Text("No"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                      ),

                      // ✅ SÍ
                      ElevatedButton.icon(
                        onPressed: () {
                          overlayEntry?.remove();
                          eliminarHistorial(idHistorial); // 👉 LLAMA TU FUNCIÓN
                        },
                        icon: Image.asset("assets/Correcto.png", width: 24),
                        label: const Text("Sí"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
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
      // Botón flotante de chat
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () {
          // TODO: Acción de chat
        },
        child: Image.asset('assets/inteligent.png', width: 36, height: 36),
      ),

      body: Stack(
        children: [
          // 🌄 Imagen de fondo
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/vete.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),

          // 🕶️ Capa oscura para contraste
          Container(
            color: Colors.black.withOpacity(0.3),
          ),

          // Contenido principal
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
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
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Image.asset('assets/Perfil.png'),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Image.asset('assets/Calendr.png'),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Image.asset('assets/Campana.png'),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Ícono de devolver alineado con menú
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
                  const SizedBox(height: 10),

                  const Center(
                    child: Text(
                      "Historial Clínico",
                      style: TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  Column(
                    children: [
                      if (_historial.isEmpty)
                        Center(
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.85,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(235, 233, 222, 218),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(blurRadius: 6, color: Colors.black26)
                              ],
                            ),
                            child: Column(
                              children: [
                                Image.asset(
                                  "assets/historiac.png",
                                  height: 100,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.error,
                                        size: 80, color: Colors.red);
                                  },
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  "Añade el primer historial clínico y lleva el control fácilmente",
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.black),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                     else
                      Column(
                        children: _historial.map((item) {
                          double limpiarPeso(dynamic valor) {
                            if (valor == null) return 0.0;

                            // Convertir a string y reemplazar comas por puntos
                            final texto = valor.toString().replaceAll(",", ".");

                            return double.tryParse(texto) ?? 0.0;
                          }
                          String mostrarNombreVet(Map item) {
                            final nombreManual = item['nombre_veterinaria'];
                            final nombreBD = item['nombre_vet_bd'];
                            final idVet = item['id_veterinaria'];

                            if (nombreManual != null && nombreManual.toString().trim().isNotEmpty) {
                              return nombreManual;
                            }
                            if (nombreBD != null && nombreBD.toString().trim().isNotEmpty) {
                              return nombreBD;
                            }
                            if (idVet != null) {
                              return "Veterinaria #$idVet";
                            }
                            return "Sin veterinaria";
                          }

                          return GestureDetector(
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.9,
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black26)],
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              // Column directo para contenido flexible
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // FECHA Y HORA
                                  Row(
                                    children: [
                                      Image.asset('assets/Calendr.png', width: 20, height: 20),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Fecha: ",
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Text(
                                        item['fecha'] ?? "Sin fecha",
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(width: 20),
                                      Image.asset('assets/Hora.png', width: 20, height: 20),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Hora: ",
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Text(
                                        item['hora'] ?? "Sin hora",
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  // VETERINARIA
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Image.asset('assets/veterinaria22.png', width: 20, height: 20),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Veterinaria: ",
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Flexible(
                                        child: Text(
                                          mostrarNombreVet(item),
                                          style: TextStyle(fontSize: 16),
                                          softWrap: true, // permite que el texto se divida en varias líneas
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  // PESO
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Image.asset('assets/Peso.png', width: 20, height: 20),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Peso: ",
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Text(
                                        "${limpiarPeso(item['peso']).toString()} k", // agrega la "k"
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  // MOTIVO
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Image.asset('assets/huellitas.png', width: 20, height: 20),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Motivo: ",
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Flexible(
                                        child: Text(
                                          item['motivo_consulta'] ?? "Sin motivo",
                                          style: TextStyle(fontSize: 16),
                                          softWrap: true,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  // DIAGNÓSTICO
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Image.asset('assets/estetoscopio.png', width: 20, height: 20),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Diagnóstico: ",
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Flexible(
                                        child: Text(
                                          item['diagnostico'] ?? "Sin diagnóstico",
                                          style: TextStyle(fontSize: 16),
                                          softWrap: true,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  // TRATAMIENTO
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Image.asset('assets/medicamentoss.png', width: 20, height: 20),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Tratamiento: ",
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Flexible(
                                        child: Text(
                                          item['tratamiento'] ?? "Sin tratamiento",
                                          style: TextStyle(fontSize: 16),
                                          softWrap: true,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  // OBSERVACIONES
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Image.asset('assets/documentos.png', width: 20, height: 20),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Observaciones: ",
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Flexible(
                                        child: Text(
                                          item['observaciones'] ?? "Sin observaciones",
                                          style: TextStyle(fontSize: 16),
                                          softWrap: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                
                                  const SizedBox(height: 16),

                                  // BOTONES
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          mostrarConfirmacionRegistro(
                                              context, item['idhistorial_medico']);
                                        },
                                        icon: Image.asset('assets/Botebasura.png', width: 20),
                                        label: const Text("Eliminar"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 10),
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => EditarHistorialScreen(idMascota: widget.id, id_historial:item['idhistorial_medico'], id_veterinaria: item['id_veterinaria'], nombre_veterinaria: mostrarNombreVet(item), peso: double.tryParse(item['peso'].toString()) ?? 0.0, hora: item['hora'] ?? '', fecha: item['fecha'] ?? '', motivo: item['motivo_consulta'] ?? '', diagnostico: item['diagnostico'] ?? '', tratamiento: item['tratamiento'] ?? '', observaciones: item['observaciones'] ?? '',),
                                            ),
                                          );
                                        },
                                        icon: Image.asset('assets/Editar.png', width: 20),
                                        label: const Text("Editar"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.amber,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 10),
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),


                      const SizedBox(height: 30),

                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AgregarHistorialScreen(idMascota: widget.id),
                              ),
                            );
                          },
                          icon: Image.asset(
                            'assets/agregar.png', // 🐾 tu imagen personalizada
                            width: 28,  // ajusta el tamaño a tu gusto
                            height: 28,
                          ),
                          label: Stack(
                            children: [
                              // 🔹 Texto negro (borde)
                              Text(
                                "Añadir Historial",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  foreground: Paint()
                                    ..style = PaintingStyle.stroke
                                    ..strokeWidth = 2
                                    ..color = Colors.black,
                                ),
                              ),
                              // 🔹 Texto blanco encima
                              const Text(
                                "Añadir Historial",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(235, 233, 222, 218),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
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
