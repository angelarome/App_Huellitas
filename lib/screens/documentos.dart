import 'package:flutter/material.dart';
import 'dart:ui'; // Para aplicar desenfoque si lo necesitas más adelante
import 'package:http/http.dart' as http; 
import 'dart:convert';  
import 'añadir_documento.dart';
import 'dart:typed_data';
import 'interfazIA.dart';
import 'compartirmascota.dart';
import 'calendario.dart';
import 'menu_lateral.dart';
import 'perfil_mascota.dart';

class AgregarDocumentosScreen extends StatefulWidget {
  
  final int id;
  final int id_dueno;
  final String nombreMascota;
  final Uint8List? fotoMascota;

  const AgregarDocumentosScreen({super.key, required this.id, required this.id_dueno, required this.fotoMascota, required this.nombreMascota,});
  @override
  State<AgregarDocumentosScreen> createState() => _AgregarDocumentosScreenState();
  
}

class _AgregarDocumentosScreenState extends State<AgregarDocumentosScreen> {
  bool _confirmado = false;
  List<Map<String, dynamic>> _documentos = [];
  bool _menuAbierto = false; // 👈 define esto en tu StatefulWidget

  void _toggleMenu() {
    setState(() {
      _menuAbierto = !_menuAbierto;
    });
  }

  @override
  void initState() {
    super.initState();
    _obtenerDocumentos(); // Llamamos a la API apenas se abre la pantalla
  }


  Future<void> _obtenerDocumentos() async {
    final url = Uri.parse("https://apphuellitas-production.up.railway.app/documentos");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_mascota": widget.id}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List documentosJson = data["documentos"] ?? []; 
      setState(() {
        
        _documentos = documentosJson.map<Map<String, dynamic>>((m) {
          final documentoMap = Map<String, dynamic>.from(m);
          final certificadosRaw = documentoMap["imagen"];
          if (certificadosRaw != null) {
            if (certificadosRaw is List && certificadosRaw.isNotEmpty) {
              try {
                documentoMap["certificadosBytes"] =
                    certificadosRaw.map<Uint8List>((c) => base64Decode(c.toString())).toList();
              } catch (e) {
                documentoMap["certificadosBytes"] = [];
              }
            } else if (certificadosRaw is String && certificadosRaw.isNotEmpty) {
              try {
                documentoMap["certificadosBytes"] = [base64Decode(certificadosRaw)];
              } catch (e) {

                documentoMap["certificadosBytes"] = [];
              }
            } else {
              documentoMap["certificadosBytes"] = [];
            }
          } else {
            documentoMap["certificadosBytes"] = [];
          }

          return documentoMap;
        }).toList();
      });
    } else {
        print("Error al obtener los documentos: ${response.statusCode}");
    }
  }


  Future<void> eliminarDocumento(int id_documento) async {
    final url = Uri.parse("https://apphuellitas-production.up.railway.app/eliminar_documento");

    final response = await http.delete( // 👈 DELETE en lugar de POST
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id_documento": id_documento,
      }),
    );

    if (response.statusCode == 200) {
      mostrarMensajeFlotante(
        context,
        "✅ Documento eliminado correctamente",
        colorFondo: const Color.fromARGB(255, 243, 243, 243),
      );
      setState(() {
        _obtenerDocumentos(); // vuelve a consultar la BD
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
  int idDocumento, // 👉 Recibe el ID
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
                          eliminarDocumento(idDocumento); // 👉 LLAMA TU FUNCIÓN
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IaMascotasScreen(id_dueno: widget.id_dueno),
            ),
          );
        },
        child: Image.asset('assets/inteligent.png', width: 36, height: 36),
      ),

      body: Stack(
        children: [
          // 🌄 Imagen de fondo
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/fondodocumentos.jpg"),
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
                  _barraSuperiorConAtras(context),
                  const SizedBox(height: 10),

                  const Center(
                    child: Text(
                      "Documentos de la mascota",
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
                      if (_documentos.isEmpty)
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
                                  "assets/documentos.png",
                                  height: 100,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.error,
                                        size: 80, color: Colors.red);
                                  },
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  "Añade el primer documento y lleva el control fácilmente",
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
                        children: _documentos.map<Widget>((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10), // espacio entre tarjetas
                            child: GestureDetector(
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.9,
                                height: 490,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black26)],
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Image.asset('assets/documentos.png', width: 20, height: 20),
                                        const SizedBox(width: 6),
                                        const Text(
                                          "Nombre del documento: ",
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        Flexible(
                                          child: Text(
                                            item['nombre'] ?? "Sin nombre",
                                            style: const TextStyle(fontSize: 16),
                                            softWrap: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
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
                                              "Documento",
                                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Center(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: Image.memory(
                                              (item["certificadosBytes"] as List).isNotEmpty
                                                  ? (item["certificadosBytes"] as List)[0]
                                                  : Uint8List(0),
                                              width: MediaQuery.of(context).size.width * 0.75,
                                              height: 350,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    // BOTONES
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            mostrarConfirmacionRegistro(context, item['id_documento']);
                                          },
                                          icon: Image.asset('assets/Botebasura.png', width: 20),
                                          label: const Text("Eliminar"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                          );
                        }).toList(),
                      ),


                      const SizedBox(height: 10),

                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AgregarDocumentoScreen(id: widget.id, id_dueno: widget.id_dueno, nombreMascota: widget.nombreMascota, fotoMascota: widget.fotoMascota),
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
                                "Añadir Documento",
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
                                "Añadir Documento",
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
          if (_menuAbierto)
            MenuLateralAnimado(onCerrar: _toggleMenu, id: widget.id_dueno),
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
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiciosScreen(idMascota: widget.id, id_dueno: widget.id_dueno, nombreMascota: widget.nombreMascota, fotoMascota: widget.fotoMascota),
                ),
              );
            },
          ),
        ),
      ),
    ],
  );
}

}
