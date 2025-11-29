import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:http/http.dart' as http; 
import 'dart:convert';  
import 'dart:typed_data';
import 'package:dropdown_button2/dropdown_button2.dart';

class MascotasCompartidas extends StatefulWidget {
  final int id_dueno;
  const MascotasCompartidas({super.key, required this.id_dueno});

  @override
  State<MascotasCompartidas> createState() => _MascotasCompartidasState();
}

class _MascotasCompartidasState extends State<MascotasCompartidas> {
  bool cargandoSolicitudes = false;
  List<Map<String, dynamic>> mascotas = [];
  String? _nombreMascota; 
  String? _idMascota;

  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _obtenerMascotas();
  }

  Future<void> _obtenerMascotas() async {
    setState(() => cargandoSolicitudes = true);

    try {
      final url = Uri.parse("http://localhost:5000/obtener_mascotas_compartidas");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id_dueno": widget.id_dueno}),
      );

      if (response.statusCode != 200) {
        print("❌ Error HTTP: ${response.statusCode}");
        return;
      }

      final data = jsonDecode(response.body);

      if (data == null || data["mascotas"] == null) {
        print("❌ No hay mascotas compartidas");
        return;
      }

      final List mascotasJson = data["mascotas"];

      final mascotasProcessed = mascotasJson.map<Map<String, dynamic>>((m) {
        final item = Map<String, dynamic>.from(m);

        final imagenBase64 = item["foto_mascota"]; // CORREGIDO

        if (imagenBase64 != null && imagenBase64.toString().isNotEmpty) {
          try {
            item["imagen_mascota_bytes"] = base64Decode(imagenBase64);
          } catch (_) {
            print("❌ Error decodificando imagen de mascota ID ${item['id_mascotas']}");
            item["imagen_mascota_bytes"] = null;
          }
        } else {
          item["imagen_mascota_bytes"] = null;
        }

        return item;
      }).toList();

      setState(() {
        mascotas = mascotasProcessed;
      });

    } catch (e) {
      print("❌ Error inesperado al obtener solicitudes: $e");
    } finally {
      if (mounted) {
        setState(() => cargandoSolicitudes = false);
      }
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

  String capitalizar(String texto) {
    if (texto.isEmpty) return texto;
    return texto[0].toUpperCase() + texto.substring(1);
  }
 @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 81, 68, 46),
        onPressed: () {},
        child: Image.asset('assets/inteligent.png', width: 36, height: 36),
      ),

      body: Stack(
        children: [
          // Fondo
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/hut-9582608_1280.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Difuminado
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),

          // Contenido principal
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Image.asset('assets/Menu.png', width: 24, height: 24),
                        onPressed: () {},
                      ),
                      Row(
                        children: [
                          Image.asset('assets/Calendr.png', width: 24, height: 24),
                          const SizedBox(width: 10),
                          Image.asset('assets/Campana.png', width: 24, height: 24),
                          const SizedBox(width: 10),
                          Image.asset('assets/Perfil.png', width: 24, height: 24),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Flecha
                  Image.asset(
                    'assets/devolver5.png',
                    width: 30,
                    height: 30,
                  ),

                  const SizedBox(height: 10),

                  // Título
                  const Center(
                    child: Text(
                      "Compartir mascota",
                      style: TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(blurRadius: 4, color: Colors.black),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Lista de solicitudes
                  mascotas.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(20),
                          child: Container(
                            height: 200,
                            padding: const EdgeInsets.symmetric(
                                vertical: 20, horizontal: 120),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(187, 255, 255, 255),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color.fromARGB(255, 180, 179, 176),
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 6,
                                  offset: Offset(1, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  "assets/grupo.png",
                                  width: 70,
                                  height: 70,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  "No tienes mascotas compartidas",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )

                      // SI HAY MASCOTAS
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: mascotas.length,
                          itemBuilder: (context, index) {
                            final mascota = mascotas[index];
                            final Uint8List? imagenBytes =
                                mascota["imagen_mascota_bytes"];
                            final esMiSolicitud =
                                mascota["id_remitente"] == widget.id_dueno;

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(187, 255, 255, 255),
                                border: Border.all(
                                  color:
                                      const Color.fromARGB(255, 180, 179, 176),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 45,
                                    backgroundImage: imagenBytes != null
                                        ? MemoryImage(imagenBytes)
                                        : const AssetImage("assets/usuario.png")
                                            as ImageProvider,
                                  ),
                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          capitalizar(
                                                  mascota["nombre_otro_dueno"] ??
                                                      "Sin nombre") +
                                              " " +
                                              capitalizar(mascota["apellido_otro_dueno"] ??
                                                  ""),
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 3),

                                        Text.rich(
                                          TextSpan(
                                            children: [
                                              const TextSpan(
                                                text: "Mascota: ",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              TextSpan(
                                                text: capitalizar(
                                                    mascota["nombre_mascota"] ??
                                                        "Sin nombre"),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 3),

                                        Text.rich(
                                          TextSpan(
                                            children: [
                                              const TextSpan(
                                                text: "Parentesco: ",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              TextSpan(
                                                text: capitalizar(mascota[
                                                            "parentesco"]
                                                        ?.toString() ??
                                                    "Sin parentesco"),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 3),

                                        
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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


