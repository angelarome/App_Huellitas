import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io' show File; // Solo se usa en móvil
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:ui';
import 'mimascota.dart';
import 'compartirmascota.dart';
import 'menu_lateral.dart';
import 'calendario.dart';
import 'interfazIA.dart';
import 'notificaciones.dart';
import "mascota.dart";
import 'buscarVeterinaria.dart';
import 'buscarTienda.dart';
import 'buscarpaseador.dart';
import 'mascotasCompartidas.dart';

class Pantalla1 extends StatefulWidget {
  final int id;
  final String cedula;
  final String nombreUsuario;
  final String apellidoUsuario;
  final String telefono;
  final String direccion;
  final Uint8List fotoPerfil;


  const Pantalla1({
    super.key,
    required this.id,
    required this.cedula,
    required this.nombreUsuario,
    required this.apellidoUsuario,
    required this.telefono,
    required this.direccion,
    required this.fotoPerfil,
  });

  @override
  State<Pantalla1> createState() => _Pantalla1State();

  
  
}

class _Pantalla1State extends State<Pantalla1> {
  File? _imagen; // para móvil
  Uint8List? _webImagen; // para web
  bool _menuAbierto = false; // 👈 define esto en tu StatefulWidget

  String _capitalizar(String texto) {
    if (texto.isEmpty) return texto;
    return texto[0].toUpperCase() + texto.substring(1).toLowerCase();
  }


  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      OverlayEntry? overlayEntry;

      overlayEntry = OverlayEntry(
        builder: (context) => Stack(
          children: [
            // Fondo semitransparente que detecta clics
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  overlayEntry?.remove(); // 👈 Cierra al hacer clic fuera
                },
                child: Container(
                  color: Colors.black.withOpacity(0.2), // Le da un ligero sombreado al fondo
                ),
              ),
            ),

            // Cuadro del mensaje
            Positioned(
              top: MediaQuery.of(context).size.height / 2 - 100,
              left: MediaQuery.of(context).size.width * 0.1,
              right: MediaQuery.of(context).size.width * 0.1,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
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
                        '¡Bienvenido, ${_capitalizar(widget.nombreUsuario)} ${_capitalizar(widget.apellidoUsuario)}! 💚',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Nos alegra tenerte aquí 🐾',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                        ),
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
    });
  }


  void _toggleMenu() {
    setState(() {
      _menuAbierto = !_menuAbierto;
    });
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
        final url = Uri.parse("http://localhost:5000/actualizar_imagen");
        final response = await http.put(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "id": widget.id,
            "foto_perfil": imagenBase64,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data["mensaje"] ?? "✅ Imagen actualizada correctamente")),
          );

          // 👈 AÑADIDO: Forzar redibujado de la interfaz
          setState(() {});
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ Error al actualizar la imagen: ${response.statusCode}")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ Error: $e")),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    // Mostrar imagen nueva si se seleccionó, o la de la BD si no
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IaMascotasScreen(),
            ),
          );
        },
        child: Image.asset('assets/inteligent.png', width: 36, height: 36), // Icono de la IA , fit: BoxFit.contain
      ),
      body: Stack(
        children: [
          // Fondo con desenfoque
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/hut-9582608_1280.jpg"),
                fit: BoxFit.cover,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(color: Colors.black.withOpacity(0.2)),
            ),
          ),

          // 🧱 Contenido principal
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
                          // 🔹 PERFIL
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => listvaciacompartirScreen(id_dueno: widget.id),
                                ),
                              );
                            },
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: Image.asset('assets/Perfil.png'),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // 🔹 CALENDARIO
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CalendarioEventosScreen(),
                                ),
                              );
                            },
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: Image.asset('assets/Calendr.png'),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // 🔹 CAMPANA (notificaciones)
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NotifiMascotaScreen(),
                                ),
                              );
                            },
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: Image.asset('assets/Campana.png'),
                            ),
                          ),
                        ],
                      )
                    ]
                  ),
                  const SizedBox(height: 20),

                  // 🔸 Foto de perfil con botón de cámara
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: _seleccionarImagen,
                        child: CircleAvatar(
                          radius: 45,
                          backgroundImage: _webImagen != null
                              ? MemoryImage(_webImagen!)
                              : _imagen != null
                                  ? FileImage(_imagen!)
                                  : MemoryImage(widget.fotoPerfil),
                          child: (_webImagen == null && _imagen == null)
                              ? null
                              : null,
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

                  const SizedBox(height: 10),

                  if (_menuAbierto) ...[
                    // Fondo semitransparente para cerrar el menú al tocar fuera
                    GestureDetector(
                      onTap: _toggleMenu,
                      child: Container(
                        color: Colors.black54,
                      ),
                    ),
                    // Menú lateral animado
                    MenuLateralAnimado(onCerrar: _toggleMenu),
                  ],

                  // Nombre del usuario
                  Text(
                    "${_capitalizar(widget.nombreUsuario)} ${_capitalizar(widget.apellidoUsuario)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "¡Bienvenido a Huellitas!",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            "MIS SERVICIOS",
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _gridServicios(context),
                      ],
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

Widget _gridServicios(BuildContext context) {
    final List<Map<String, dynamic>> servicios = [
      {
        "label": "Mis mascotas",
        "icons": ["assets/cuidadob.png", "assets/Mismascotas.png"],
        "color": Colors.lightBlueAccent,
        "borderColor": const Color.fromARGB(255, 45, 120, 249),
      },
      {
        "label": "Paseadores",
        "icons": ["assets/jugarperrof.png", "assets/pasear.png"],
        "color": Colors.redAccent,
        "borderColor": const Color.fromARGB(255, 204, 33, 21),
      },
      {
        "label": "Veterinaria",
        "icons": ["assets/estetoscopi.png", "assets/Medico.png"],
        "color":  const Color.fromARGB(255, 93, 187, 96),
        "borderColor": Colors.greenAccent.shade700,
      },
      {
        "label": "Tienda",
        "icons": ["assets/Insumos.png", "assets/comprastienda.png"],
        "color": Colors.pinkAccent,
        "borderColor": const Color.fromARGB(255, 255, 24, 101),
      },
    ];

    double screenWidth = MediaQuery.of(context).size.width;
    double aspectRatio = screenWidth < 400 ? 1.1 : screenWidth < 600 ? 1.3 : 1.5;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: aspectRatio,
      ),
      itemCount: servicios.length,
      itemBuilder: (context, index) {
        final servicio = servicios[index];
        List<String> iconos = List<String>.from(servicio["icons"]);

        return _tarjetaServicio(
          context,
          servicio["label"].toString(),
          iconos,
          servicio["color"] as Color,
          servicio["borderColor"] as Color,
        );
      },
    );
  }

Widget _tarjetaServicio(BuildContext context, String label, List<String> assetPaths,
      Color color, Color borderColor) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _abrirPagina(context, label),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double iconSize = constraints.maxWidth * 0.30;
          double iconSpacing = 6;

          bool esPaseadores = label == "PASEADORES";
          if (esPaseadores) {
            iconSize = constraints.maxWidth * 0.30;
            iconSpacing = 4;
          }

          Widget iconosWidget = esPaseadores
              ? Wrap(
                  alignment: WrapAlignment.center,
                  spacing: iconSpacing,
                  children: assetPaths.map((path) {
                    return SizedBox(
                      width: iconSize,
                      height: iconSize,
                      child: Image.asset(path, fit: BoxFit.contain),
                    );
                  }).toList(),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: assetPaths.map((path) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: iconSpacing),
                      child: SizedBox(
                        width: iconSize,
                        height: iconSize,
                        child: Image.asset(path, fit: BoxFit.contain),
                      ),
                    );
                  }).toList(),
                );

          return Container(
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: borderColor, width: 1.5),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black26)],
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                  ),
                ),
                const SizedBox(height: 10),
                iconosWidget,
              ],
            ),
          );
        },
      ),
    );
  }

  // 🔹 Navegación según el servicio
  void _abrirPagina(BuildContext context, String label) {
     print("Se tocó: $label");
    switch (label.toUpperCase()) {
      case 'MIS MASCOTAS':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MiMascotaScreen(id_dueno: widget.id)),
        );
        break;
      case 'PASEADORES':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BuscarPaseador(id_dueno: widget.id)),
        );
        break;
      case 'VETERINARIA':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BuscarvMascotaScreen(id_dueno: widget.id)),
        );
        break;
      case 'BIENESTAR DIARIO':
        break;
      case 'TIENDA':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TiendaMascotaScreen(id_dueno: widget.id)),
        );
        break;
      case 'MEDICINA':
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Página no disponible')),
        );
    }
  }

}