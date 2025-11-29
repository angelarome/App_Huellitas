import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:http/http.dart' as http; 
import 'dart:convert';
import 'dart:typed_data'; // Para Uint8List
import 'dart:io'; // Para File (solo en móvil, no en web)
import 'higiene.dart';
import 'editarhigiene.dart';

class RecordatorioBanioScreen extends StatefulWidget {
  final int idMascota;
  final int id_higiene;
  final String frecuencia;
  final String dias_personalizados;
  final String notas;
  final String tipo;
  final String hora;
  final String fecha;

  const RecordatorioBanioScreen({super.key, required this.idMascota, required this.id_higiene, required this.frecuencia, required this.dias_personalizados, required this.notas, required this.tipo, required this.hora, required this.fecha});

  @override
  State<RecordatorioBanioScreen> createState() => _RecordatorioBanioScreenState();

}
class _RecordatorioBanioScreenState extends State<RecordatorioBanioScreen> {
  String nombreMascota = "";
  File? _imagen; // para móvil
  Uint8List? _webImagen; // para web
  

  @override
  void initState() {
    super.initState();
    obtenerMascotasPorId(); // Llamamos a la API apenas se abre la pantalla
  }

  void mostrarConfirmacionRegistro(BuildContext context, VoidCallback onConfirmar) {
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Fondo semitransparente
          Positioned.fill(
            child: GestureDetector(
              onTap: () {}, // Evita que se cierre al tocar fuera
              child: Container(
                color: Colors.black.withOpacity(0.4),
              ),
            ),
          ),

          // Cuadro del mensaje
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
                      '¿Deseas eliminar ${widget.tipo}?',
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
                        // ❌ Botón "No"
                        ElevatedButton.icon(
                          onPressed: () {
                            overlayEntry?.remove();
                          },
                          icon: Image.asset(
                            "assets/cancelar.png", // tu icono
                            width: 24,
                            height: 24,
                          ),
                          label: const Text('No', style: TextStyle(color: Colors.white, fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 202, 65, 65),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        // ✅ Botón "Sí"
                        ElevatedButton.icon(
                          onPressed: () {
                            overlayEntry?.remove();
                            eliminarHigiene(); // 👉 Llama a la función que hace el registro
                          },
                          icon: Image.asset(
                            "assets/Correcto.png", // tu icono
                            width: 24,
                            height: 24,
                          ),
                          label: const Text('Sí', style: TextStyle(color: Colors.white, fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                          ),
                        
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

    // 👇 Muestra el mensaje en pantalla
    Overlay.of(context).insert(overlayEntry);
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


  Future<void> obtenerMascotasPorId() async {
    final url = Uri.parse("http://localhost:5000/obtenermascota");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_mascota": widget.idMascota}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List mascotasJson = data["mascotas"] ?? [];
      setState(() {
        nombreMascota = mascotasJson[0]["nombre"] ?? "Sin nombre";
        _webImagen = mascotasJson[0]["imagen_perfil"] != null 
          ? base64Decode(mascotasJson[0]["imagen_perfil"]) 
          : null;
      });

    } else {
        print("Error al obtener mascotas: ${response.statusCode}");
    }
  }

  Future<void> eliminarHigiene() async {
    final url = Uri.parse("http://localhost:5000/eliminar_higiene");

    final response = await http.delete( // 👈 DELETE en lugar de POST
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id_mascota": widget.idMascota,
        "id_higiene": widget.id_higiene,
      }),
    );

    if (response.statusCode == 200) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HigieneScreen(id: widget.idMascota),
        ),
      );

      Future.delayed(const Duration(milliseconds: 300), () {
        mostrarMensajeFlotante(
          context,
          "✅ Higiene eliminada correctamente",
          colorFondo: const Color.fromARGB(255, 243, 243, 243),
        );
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

  Color _getColorHigiene(String? tipo) {
    switch (tipo) {
    case "Baño":
    return const Color.fromARGB(255, 135, 206, 250); // azul claro
    case "Peluquería":
    return const Color.fromARGB(255, 170, 128, 255); // morado pastel
    case "Manicure":
    return const Color.fromARGB(255, 255, 182, 193); // rosa pastel
    case "Cambio de arenero":
    return const Color.fromARGB(255, 144, 238, 144); // verde claro
    case "Cuidado dental":
    return const Color.fromARGB(255, 176, 224, 230); // celeste
    case "Cuidado de orejas":
    return const Color.fromARGB(255, 255, 255, 153); // amarillo pastel
    default:
    return Colors.grey.shade300; // color por defecto
    }
  }

  Color _getBorderColorHigiene(String? tipo) {
    switch (tipo) {
    case "Baño":
    return const Color.fromARGB(255, 70, 130, 180); // azul más intenso
    case "Peluquería":
    return const Color.fromARGB(255, 128, 0, 128); // morado intenso
    case "Manicure":
    return const Color.fromARGB(255, 255, 105, 180); // rosa más intenso
    case "Cambio de arenero":
    return const Color.fromARGB(255, 34, 139, 34); // verde más intenso
    case "Cuidado dental":
    return const Color.fromARGB(255, 0, 191, 255); // azul intenso
    case "Cuidado de orejas":
    return const Color.fromARGB(255, 255, 215, 0); // amarillo intenso
    default:
    return Colors.grey.shade700; // borde por defecto
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () {
          // TODO: Acción de chat
        },
        child: Image.asset('assets/inteligent.png', width: 36, height: 36),
      ),
      body: Stack(
        children: [
          // Fondo
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/Invierno.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
          Container(color: Colors.black.withOpacity(0.3)),

          // Contenido
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Encabezado superior (sin cambios)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Image.asset('assets/Menu.png', width: 24, height: 24),
                      ),
                      Row(
                        children: [
                          Image.asset('assets/Perfil.png', width: 24),
                          const SizedBox(width: 10),
                          Image.asset('assets/Calendr.png', width: 24),
                          const SizedBox(width: 10),
                          Image.asset('assets/Campana.png', width: 24),
                        ],
                      ),
                    ],
                  ),
                  // Ícono de devolver alineado con menú
                  const SizedBox(height: 10),
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

                  Text(
                    (widget.tipo.isNotEmpty ? widget.tipo : "Sin tipo").toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(1.5, 1.5),
                          color: Colors.black,
                          blurRadius: 2,
                        ),
                        Shadow(
                          offset: Offset(-1.5, -1.5),
                          color: Colors.black,
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),

                
                  const SizedBox(height: 10),

                 

                  // Tarjeta azul con contenido
                  Center(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color:  _getColorHigiene(widget.tipo),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black26)],
                        border: Border.all(color: _getBorderColorHigiene(widget.tipo), width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Stack(
                            children: [
                            // Texto delineado negro
                            Text(
                            "Mascota",
                            style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 3
                            ..color = Colors.black,
                            ),
                            ),
                            // Texto blanco encima
                            Text(
                            "Mascota",
                            style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            ),
                            ),
                            ],
                            ),
                            ),

                          const SizedBox(height: 16),

                          Center(
                            child: CircleAvatar(
                              radius: 40,
                              backgroundImage: _webImagen != null
                                  ? MemoryImage(_webImagen!) // Base64 desde la API
                                  : AssetImage("assets/usuario.png") as ImageProvider, // Imagen por defecto
                            ),
                          ),   
                          const SizedBox(height: 12),

                          infoItem(
                            "assets/Nombre.png",
                            "Nombre", nombreMascota.isNotEmpty 
                                ? nombreMascota[0].toUpperCase() + nombreMascota.substring(1).toLowerCase() 
                                : '',
                          ),
                          infoItem("assets/Etiqueta.png", "Tipo",widget.tipo),
                          infoItem("assets/Calendario.png", "Fecha", widget.fecha),
                          infoItem("assets/Hora.png", "Hora", widget.hora),
                          Column(
                            children: [
                              infoItem("assets/Frecuencia.png", "Frecuencia", widget.frecuencia),

                              if (widget.frecuencia == "Personalizada" &&
                                  widget.dias_personalizados != null &&
                                  widget.dias_personalizados!.isNotEmpty)
                                infoItem(
                                  "assets/evaluacion.png",
                                  "Días", widget.dias_personalizados,
                                ),
                            ],
                          ),
                          infoItem("assets/Notas.png", "Notas", widget.notas, isNote: true),

                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  mostrarConfirmacionRegistro(context, eliminarHigiene);
                                },
                                icon: Image.asset('assets/Botebasura.png', width: 20),
                                label: const Text("Eliminar"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditarCuidadoScreen(
                                        idMascota: widget.idMascota,
                                        id_higiene: widget.id_higiene,
                                        nombreMascota: nombreMascota,
                                        frecuencia: widget.frecuencia,
                                        dias_personalizados: widget.dias_personalizados,
                                        notas: widget.notas,
                                        tipo: widget.tipo,
                                        hora: widget.hora,
                                        fecha: widget.fecha,
                                      ),
                                    ),
                                  ).then((value) {
                                    if (value == true) {
                                      // 👇 Aquí recargas la info sin reabrir la pantalla
                                      setState(() {
                                        obtenerMascotasPorId(); // vuelve a obtener nombre e imagen
                                      });
                                    }
                                  });
                                },
                                icon: Image.asset('assets/Editar.png', width: 20),
                                label: const Text("Editar"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            ),
          ),
        ],
      ),
    );
  }

  // Widget para mostrar ítem con ícono
  Widget infoItem(String iconPath, String label, String value, {bool isNote = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(iconPath, width: 24, height: 24),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "$label: ", // la etiqueta en negrita
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16, 
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                  TextSpan(
                    text: value, // el valor normal
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: isNote ? 14 : 16,
                      color:  Color.fromARGB(255, 37, 36, 36),
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