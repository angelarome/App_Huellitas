import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:http/http.dart' as http; 
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'dart:typed_data'; // Para Uint8List
import 'dart:io'; // Para File (solo en móvil, no en web)
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File; // Solo se usa en móvil
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'mimascota.dart';
import 'modificarMascota.dart';

class EditarMascotaScreen extends StatefulWidget {
  final int idMascota;
  final int id_dueno;

  const EditarMascotaScreen({super.key, required this.idMascota, required this.id_dueno});

  @override
  State<EditarMascotaScreen> createState() => _EditarMascotaScreen();

}
class _EditarMascotaScreen extends State<EditarMascotaScreen> {
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    obtenerMascotasPorId(); // Llamamos a la API apenas se abre la pantalla
  }


  String nombreMascota = "";
  String apellidoMascota = "";
  String especieMascota = "";
  String generoMascota = "";
  String razaMascota = "";
  double pesoMascota = 0.0;
  double limpiarPeso(dynamic valor) {
    if (valor == null) return 0.0;

    // Convertir a string y reemplazar comas por puntos
    final texto = valor.toString().replaceAll(",", ".");

    return double.tryParse(texto) ?? 0.0;
  }
  String esterilizadoMascota = "";
  DateTime? fechaNacimientoMascota;
  String formatearFecha(DateTime fecha) {
    return "${fecha.day.toString().padLeft(2,'0')}/"
          "${fecha.month.toString().padLeft(2,'0')}/"
          "${fecha.year}";
  }

  File? _imagen; // para móvil
  Uint8List? _webImagen; // para web


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
                      '¿Deseas eliminar $nombreMascota?',
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
                            eliminarMascota(); // 👉 Llama a la función que hace el registro
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
    try {
      final url = Uri.parse("https://apphuellitas-production.up.railway.app/obtenermascota");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id_mascota": widget.idMascota}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List mascotasJson = data["mascotas"] ?? [];
        if (mascotasJson.isEmpty) {
          setState(() => isLoading = false);
          return; // salir para no acceder al índice 0
        }
        setState(() {
          nombreMascota = mascotasJson[0]["nombre"] ?? "Sin nombre";
          apellidoMascota = mascotasJson[0]["apellido"] ?? "Sin apellido";
          especieMascota = mascotasJson[0]["especies"] ?? "Sin especie";
          generoMascota = mascotasJson[0]["sexo"] ?? "Sin género";
          razaMascota = mascotasJson[0]["raza"] ?? "Sin raza";
          pesoMascota = limpiarPeso(mascotasJson[0]["peso"]);
          esterilizadoMascota = mascotasJson[0]["esterilizado"] ?? "";
          final fechaJson = mascotasJson[0]["fecha_nacimiento"];

          if (fechaJson != null && fechaJson.toString().isNotEmpty) {
            fechaNacimientoMascota = DateTime.parse(fechaJson); // ✔️ Correcto
          } else {
            fechaNacimientoMascota = null;
          }
          _webImagen = mascotasJson[0]["imagen_perfil"] != null 
            ? base64Decode(mascotasJson[0]["imagen_perfil"]) 
            : null;
          isLoading = false; 
        });

      } else {
          print("Error al obtener mascotas: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
      setState(() => isLoading = false);
    }
  }

  // Método para abrir galería y actualizar imagen
  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final imagenSeleccionada = await picker.pickImage(source: ImageSource.gallery);

    if (imagenSeleccionada != null) {
      try {
        Uint8List bytes;

        // 📱 Si es móvil, leemos con File
        if (!kIsWeb) {
          final imagenFile = File(imagenSeleccionada.path);
          bytes = await imagenFile.readAsBytes();
          setState(() {
            _imagen = imagenFile;
          });
        } 
        // 💻 Si es web, leemos los bytes directamente
        else {
          bytes = await imagenSeleccionada.readAsBytes();
          setState(() {
            _webImagen = bytes;
          });
        }

        // ✅ Convertimos la imagen a Base64
        final imagenBase64 = base64Encode(bytes);

        // ✅ Enviamos al backend
        final url = Uri.parse("https://apphuellitas-production.up.railway.app/actualizar_imagen_mascota");
        final response = await http.put(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "idMascota": widget.idMascota,
            "fotoMascota": imagenBase64,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          // 👈 AÑADIDO: Forzar redibujado de la interfaz
          setState(() {});
        } else {
          mostrarMensajeFlotante(
            context,
            "❌ Error al actualizar la imagen",
            colorFondo: Colors.white,
            colorTexto: Colors.redAccent,
          );
        }
      } catch (e) {
        mostrarMensajeFlotante(
            context,
            "❌ Error al actualizar la imagen {$e}",
            colorFondo: Colors.white,
            colorTexto: Colors.redAccent,
          );
      }
    }
  }

  Future<void> eliminarMascota() async {
    final url = Uri.parse("https://apphuellitas-production.up.railway.app/eliminarMascota");

    final response = await http.delete( // 👈 DELETE en lugar de POST
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id_mascota": widget.idMascota,
      }),
    );

    if (response.statusCode == 200) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MiMascotaScreen(id_dueno: widget.id_dueno),
        ),
      );

      Future.delayed(const Duration(milliseconds: 300), () {
        mostrarMensajeFlotante(
          context,
          "✅ Mascota eliminada correctamente",
          colorFondo: const Color.fromARGB(255, 243, 243, 243),
        );
      });

    } else {
      mostrarMensajeFlotante(
        context,
        "❌ Error: No se pudo eliminar la mascota",
        colorFondo: Colors.white,
        colorTexto: Colors.redAccent,
      );
    }
  }

  Color _getColorHigiene(String? generoMascota) {
    switch (generoMascota) {
      case "Macho":
        return const Color.fromARGB(255, 76, 162, 255);     
      case "Hembra":
        return const Color.fromARGB(255, 255, 105, 180);   
      default:
        return Colors.grey.shade300;      // color por defecto
    }
  }

  Color _getBorderColorHigiene(String? generoMascota) {
    switch (generoMascota) {
      case "Macho":
        return const Color.fromARGB(255, 28, 106, 190);
      case "Hembra":
        return const Color.fromARGB(255, 219, 44, 131);
      default:
        return Colors.grey.shade700;
    }
  }

  String getIconoEspecie(String especie) {
    switch (especie.toLowerCase()) {
      case "perro":
        return "assets/Perrocafe.png";
      case "gato":
        return "assets/gato-negro.png";
      case "conejo":
        return "assets/conejo1.png";
      case "ave":
        return "assets/guacamayo.png";
      default:
        return "assets/masmascotas.png";
    }
  }

  String getIconoSexo(String sexo) {
    switch (sexo.toLowerCase()) {
      case "macho":
        return "assets/masculino.png";
      case "hembra":
        return "assets/mujer.png";
      default:
        return "assets/mujer.png"; // o cualquier icono neutro
    }
  }

  
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
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
                image: AssetImage("assets/fall-8404115_1280.jpg"),
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


                  // Tarjeta azul con contenido
                  Center(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _getColorHigiene(generoMascota),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black26)],
                        border: Border.all(color: _getBorderColorHigiene(generoMascota), width: 2),
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
                            child: Stack(
                              children: [
                                GestureDetector(
                                  onTap: _seleccionarImagen,
                                  child: CircleAvatar(
                                    radius: 45,
                                    backgroundImage: 
                                        _webImagen != null
                                            ? MemoryImage(_webImagen!)
                                            : _imagen != null
                                                ? FileImage(_imagen!)
                                                : const AssetImage("assets/usuario.png") as ImageProvider,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: _seleccionarImagen,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.redAccent,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(6),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          infoItem(
                            "assets/Nombre.png",
                            "Nombre",
                            nombreMascota.isNotEmpty 
                                ? nombreMascota[0].toUpperCase() + nombreMascota.substring(1).toLowerCase() 
                                : '',
                          ),
                          infoItem(
                            "assets/Apellido.png",
                            "Apellido",
                            apellidoMascota.isNotEmpty 
                                ? apellidoMascota[0].toUpperCase() + apellidoMascota.substring(1).toLowerCase() 
                                : '',
                          ),
                          infoItem(
                            getIconoEspecie(especieMascota),
                            "Especie",
                            especieMascota.isNotEmpty 
                                ? especieMascota[0].toUpperCase() + especieMascota.substring(1).toLowerCase() 
                                : '',
                          ),
                          infoItem(
                            getIconoSexo(generoMascota),
                            "Género",
                            generoMascota.isNotEmpty 
                                ? generoMascota[0].toUpperCase() + generoMascota.substring(1).toLowerCase() 
                                : '',
                          ),
                          infoItem(
                            "assets/Raza.png",
                            "Raza",
                            razaMascota.isNotEmpty 
                                ? razaMascota[0].toUpperCase() + razaMascota.substring(1).toLowerCase() 
                                : '',
                          ),
                          infoItem(
                            "assets/Peso.png",
                            "Peso",
                            pesoMascota.toString(),
                          ),
                          infoItem(
                            "assets/Calendario.png",
                            "Fecha de nacimiento",
                            fechaNacimientoMascota != null
                                ? formatearFecha(fechaNacimientoMascota!)
                                : "Sin fecha",
                          ),
                          infoItem(
                            "assets/carpeta.png",
                            "Esterilizado",
                            esterilizadoMascota.isNotEmpty 
                                ? esterilizadoMascota[0].toUpperCase() + esterilizadoMascota.substring(1).toLowerCase() 
                                : '',
                          ),
                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  mostrarConfirmacionRegistro(context, eliminarMascota);
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
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ModificarMascotaScreen(id_mascota: widget.idMascota, id_dueno: widget.id_dueno, imagen: _webImagen, nombre: nombreMascota, apellido: apellidoMascota, raza: razaMascota, especie: especieMascota, genero: generoMascota, esterilizado: esterilizadoMascota, pesoMascota: pesoMascota, fechaNacimientoMascota: fechaNacimientoMascota),
                                    ),
                                  );
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
                      color: const Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                  TextSpan(
                    text: value, // el valor normal
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize:  16,
                      color:   Color.fromARGB(255, 0, 0, 0),
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