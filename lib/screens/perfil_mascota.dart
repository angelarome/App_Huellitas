import 'package:flutter/material.dart';
import 'dart:ui';
import 'menu_lateral.dart';
import 'higiene.dart';
import 'dart:typed_data';
import 'compartirmascota.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File; // Solo se usa en móvil
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'buscarTienda.dart';
import 'buscarVeterinaria.dart';

class ServiciosScreen extends StatefulWidget {
  final int id_dueno;
  final int idMascota;
  final String nombreMascota;
  final Uint8List? fotoMascota;

  const ServiciosScreen({
    super.key,
    required this.idMascota,
    required this.nombreMascota,
    required this.fotoMascota,
    required this.id_dueno,
  });

  @override
  State<ServiciosScreen> createState() => _ServiciosScreenState();
}

class _ServiciosScreenState extends State<ServiciosScreen> {
  File? _imagen; // para móvil
  Uint8List? _webImagen; // para web
  bool _menuAbierto = false;

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
        final url = Uri.parse("http://localhost:5000/actualizar_imagen_mascota");
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
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () {
          // Acción de IA
        },
        child: Image.asset(
          'assets/inteligent.png',
          width: 36,
          height: 36,
          fit: BoxFit.contain,
        ),
      ),
      body: Stack(
        children: [
          // Fondo con desenfoque
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

          // Contenido principal
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  
                  _barraSuperiorConAtras(context),
                  const SizedBox(height: 20),
                  _encabezado(),
                  const SizedBox(height: 20),
                  _contenedorServicios(context),
                ],
              ),
            ),
          ),

          
          // Menú lateral animado
          if (_menuAbierto)
            MenuLateralAnimado(onCerrar: _toggleMenu),
        ],
      ),
    );
  }

  // 🔹 Encabezado superior con menú y botones
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
                  builder: (context) => listvaciacompartirScreen(),
                ),
              );
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

  Widget _iconoTop(String asset, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(width: 24, height: 24, child: Image.asset(asset)),
    );
  }

  // 🔹 Encabezado con imagen y botones de acción
  Widget _encabezado() {
    return Column(
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: _seleccionarImagen,
              child: CircleAvatar(
                radius: 45,
                backgroundImage: _webImagen != null
                  ? MemoryImage(_webImagen!) // imagen cargada en web
                  : _imagen != null
                      ? FileImage(_imagen!) // imagen cargada en móvil
                      : (widget.fotoMascota != null
                          ? MemoryImage(widget.fotoMascota!) // imagen inicial
                          : const AssetImage("assets/usuario.png") as ImageProvider), // fallback
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
  
        Text(
          "${widget.nombreMascota[0].toUpperCase()}${widget.nombreMascota.substring(1).toLowerCase()}",
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 3, color: Colors.black)],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _iconoAccion("Compartir", "assets/compartir.png"),
            _iconoAccion("Información", "assets/Informacion.png"),
            _iconoAccion("Emergencia", "assets/Medicina.png"),
            _iconoAccion("Ver ubicación", "assets/Mapa.png"),
          ],
        ),
      ],
    );
  }


  Widget _iconoAccion(String label, String assetPath) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          SizedBox(width: 32, height: 32, child: Image.asset(assetPath)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white)),
        ],
      ),
    );
  }

  // 🔹 Contenedor principal de los servicios
  Widget _contenedorServicios(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black26)],
      ),
      child: Column(
        children: [
          const Text(
            "MIS SERVICIOS",
            style: TextStyle(
              fontSize: 24,
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _gridServicios(context),
        ],
      ),
    );
  }

  // 🔹 Grid de servicios
  Widget _gridServicios(BuildContext context) {
    final List<Map<String, dynamic>> servicios = [
      {
        "label": "HIGIENE",
        "icons": ["assets/gotaswhite.png", "assets/Perroagua.png"],
        "color": Colors.lightBlueAccent,
        "borderColor": const Color.fromARGB(255, 45, 120, 249),
      },
      {
        "label": "BIENESTAR DIARIO",
        "icons": ["assets/salud.png", "assets/Conejo.png"],
        "color": Colors.purple,
        "borderColor": Colors.deepPurple,
        
      },
      {
        "label": "MEDICINA",
        "icons": ["assets/Gatoinyeccion.png", "assets/medicamento.png"],
        "color": Colors.yellow.shade700,
        "borderColor": const Color.fromARGB(255, 206, 139, 51),
      },
      {
        "label": "Documentos",
        "icons": ["assets/documentos.png", "assets/archivo.png"],
        "color": const Color.fromARGB(255, 209, 211, 187),
        "borderColor": const Color.fromARGB(255, 106, 103, 100),
      },
      {
        "label": "Historial clinico",
        "icons": ["assets/informec.png", "assets/historiac.png"],
        "color": const Color.fromARGB(255, 238, 59, 59),
        "borderColor": const Color.fromARGB(255, 191, 14, 14),
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

  // 🔹 Tarjeta individual con acción de navegación
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
    switch (label.toUpperCase()) {
      case 'HIGIENE':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HigieneScreen(id: widget.idMascota)),
        );
        break;
      case 'PASEADORES':
        
        break;
      case 'VETERINARIA':
        break;
      case 'BIENESTAR DIARIO':
        break;
      case 'TIENDA':
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
