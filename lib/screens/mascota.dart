import 'dart:ui';               // Para aplicar desenfoque
import 'dart:convert';          // Para jsonEncode y base64Encode
import 'dart:io';               // Para File y _imagen!.readAsBytes()
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http; 
import 'package:image_picker/image_picker.dart';
import 'mimascota.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'compartirmascota.dart';
import 'calendario.dart';
import 'menu_lateral.dart';

class AgregarMascotaScreen extends StatefulWidget {
  const AgregarMascotaScreen({super.key, required this.id_dueno, required this.cedula,
    required this.nombreUsuario,
    required this.apellidoUsuario,
    required this.telefono,
    required this.direccion,
    required this.fotoPerfil,
    required this.departamento,
    required this.ciudad,});

  final int id_dueno;
  final String cedula;
  final String nombreUsuario;
  final String apellidoUsuario;
  final String telefono;
  final String direccion;
  final Uint8List fotoPerfil;
  final String departamento;
  final String ciudad;

  @override
  State<AgregarMascotaScreen> createState() => _AgregarMascotaScreenState();
}
  
class _AgregarMascotaScreenState extends State<AgregarMascotaScreen> {
  DateTime? _fechaNacimiento;
  
  final _formKey = GlobalKey<FormState>(); 
    // Método para abrir galería
  File? _imagen; // para móvil
  Uint8List? _webImagen; // para web
  String? _imagenBase64; 
  String? especieSeleccionada;
  String? generoSeleccionado;
  String? esterilizado;

  bool _menuAbierto = false; // 👈 define esto en tu StatefulWidget

  void _toggleMenu() {
    setState(() {
      _menuAbierto = !_menuAbierto;
    });
  }

  final nombreController = TextEditingController();
  final apellidoController = TextEditingController();
  final razaController = TextEditingController();
  final pesoController = TextEditingController();
  final generoController = TextEditingController();
  final especiesController = TextEditingController();
  final esterilizadoController = TextEditingController();
  // ✅ Cargar imagen por defecto apenas se abra la pantalla
  @override
  void initState() {
    super.initState();
    _cargarImagenPorDefecto();
  }

  Future<void> _cargarImagenPorDefecto() async {
    final byteData = await rootBundle.load('assets/usuario.png');
    final bytes = byteData.buffer.asUint8List();
    setState(() {
      _imagenBase64 = base64Encode(bytes);
      _webImagen = bytes; // para mostrarla en web
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
        _imagenBase64 = base64Encode(bytes); 
        } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ Error: $e")),
        );
      }
    }
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
                    const Text(
                      '¿Deseas registrar esta mascota?',
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
                          onPressed: () { overlayEntry?.remove(); },
                          icon: Image.asset(
                            "assets/cancelar.png", // tu icono
                            width: 24,
                            height: 24,
                          ),
                          label: const Text('No', style: TextStyle(color: Colors.white, fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 202, 65, 65),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                  
                        ),
                        ElevatedButton.icon(          
                          onPressed: () {
                            overlayEntry?.remove();
                            _registrarMascota(); // 👉 Llama a la función que hace el registro
                          },
                          icon: Image.asset(
                            "assets/Correcto.png", // tu icono
                            width: 24,
                            height: 24,
                          ),
                          label: const Text('Sí', style: TextStyle(color: Colors.white, fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          // Fondo semitransparente que reacciona al toque
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                overlayEntry?.remove(); // 👈 Cierra al tocar cualquier parte
              },
              child: Container(color: Colors.black.withOpacity(0.3)),
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


  Future<void> _registrarMascota() async {
   List<String> camposFaltantes = [];

    // Helper reutilizable para detectar "vacío"
    bool estaVacio(dynamic valor) {
      if (valor == null) return true;
      // Si es un TextEditingController -> usar .text
      if (valor is TextEditingController) {
        return valor.text.trim().isEmpty;
      }
      // Si es String
      if (valor is String) {
        return valor.trim().isEmpty;
      }
      // Para otros tipos (bool, DateTime, etc.) usamos su toString seguro
      return valor.toString().trim().isEmpty;
    }

    // Validaciones
    // Validar formulario (si estás usando validators dentro de los TextFormField,
    // _formKey.currentState!.validate() debe haberse llamado antes si quieres incluirlo)
    if (!_formKey.currentState!.validate()) {
      camposFaltantes.add("Campos del formulario");
    }

    // Especie (si es String o variable seleccionada)
    if (estaVacio(especieSeleccionada)) {
      camposFaltantes.add("Especie");
    }

    // Género
    if (estaVacio(generoSeleccionado)) {
      camposFaltantes.add("Género");
    }

    // Fecha de nacimiento (DateTime o String)
    if (_fechaNacimiento == null || estaVacio(_fechaNacimiento)) {
      camposFaltantes.add("Fecha de nacimiento");
    }

    // Peso (TextEditingController)
    if (estaVacio(pesoController)) {
      camposFaltantes.add("Peso");
    }

    // Esterilizado (si es un bool o una selección)
    if (esterilizado == null || estaVacio(esterilizado)) {
      camposFaltantes.add("Esterilizado");
    }

    // Raza (TextEditingController)
    if (estaVacio(razaController)) {
      camposFaltantes.add("Raza");
    }

    // Mostrar mensaje si faltan campos
    if (camposFaltantes.isNotEmpty) {
      mostrarMensajeFlotante(
        context,
        "⚠️ Faltan campos: ${camposFaltantes.join(', ')}",
        colorFondo: Colors.white,
        colorTexto: const Color.fromARGB(255, 211, 60, 60),
      );
      return;
    }


    // Formatear la fecha
    String? fechaStr;
    if (_fechaNacimiento != null) {
      fechaStr = "${_fechaNacimiento!.year.toString().padLeft(4,'0')}-"
                "${_fechaNacimiento!.month.toString().padLeft(2,'0')}-"
                "${_fechaNacimiento!.day.toString().padLeft(2,'0')}";
    }

    final url = Uri.parse("https://apphuellitas-production.up.railway.app/registrarMascota");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "nombre": nombreController.text,
        "apellido": apellidoController.text,
        "raza": razaController.text,
        "genero": generoSeleccionado,
        "peso": pesoController.text,
        "especie": especieSeleccionada,
        "fecha_nacimiento": fechaStr,
        "imagen": _imagenBase64,
        "esterilizado": esterilizado,
        "id_dueno": widget.id_dueno,
      }),
    );

    if (response.statusCode == 201) {
      // Decodificamos la respuesta si quieres usarla
      final data = jsonDecode(response.body);
      final mascota = data["mascota"];

      mostrarMensajeFlotante(
        context,
        "✅ Mascota registrada correctamente",
        colorFondo: const Color.fromARGB(255, 243, 243, 243), // verde bonito
        colorTexto: const Color.fromARGB(255, 0, 0, 0),
      );

      // Navegar a la pantalla MiMascotaScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MiMascotaScreen(id_dueno: widget.id_dueno, cedula: widget.cedula, nombreUsuario: widget.nombreUsuario, apellidoUsuario: widget.apellidoUsuario, telefono: widget.telefono, direccion: widget.direccion, fotoPerfil: widget.fotoPerfil, departamento: widget.departamento, ciudad: widget.ciudad),
        ),
      );
    } else {
      // Mensaje de error
      final error = jsonDecode(response.body)["error"];
      mostrarMensajeFlotante(
        context,
        "❌ Error: $error",
        colorFondo: Colors.white,
        colorTexto: Colors.redAccent,

      );
    }
  }

  final Map<String, String> iconosEspecie = {
    "Perro": "assets/Perrogris.png",
    "Gato": "assets/gato-negro.png",
    "Ave": "assets/guacamayo.png",
    "Conejo": "assets/conejo1.png",
    "Otro": "assets/masmascotas.png",
  };

  final Map<String, String> iconosGenero = {
    "Macho": "assets/chico.png",
    "Hembra": "assets/femenino.png",
  };

  
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
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                          
                  _barraSuperiorConAtras(context),

                  const SizedBox(height: 20),

                  const Center(
                    child: Text(
                      "Añadir mascota",
                      style: TextStyle(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  
                  Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.9,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black26)],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // --- Imagen de la mascota ---
                            Align(
                              alignment: Alignment.center,
                              child: Stack(
                                children: [
                                  GestureDetector(
                                    onTap: _seleccionarImagen,
                                    child: CircleAvatar(
                                      radius: 45,
                                      backgroundColor: Colors.white,
                                      backgroundImage: kIsWeb
                                          ? (_webImagen != null
                                              ? MemoryImage(_webImagen!)
                                              : const AssetImage('assets/usuario.png'))
                                          : (_imagen != null
                                              ? FileImage(_imagen!)
                                              : const AssetImage('assets/usuario.png')) as ImageProvider,
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

                            const SizedBox(height: 16),

                            _campoTextoConEtiqueta(
                              "Nombre",
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SizedBox(width: 24, height: 24, child: Image.asset('assets/Nombre.png')),
                              ),
                              nombreController,
                              tipo: 'letras',
                              hintText: "ej: Max",
                            ),
                            _campoTextoConEtiqueta(
                              "Apellido",
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SizedBox(width: 24, height: 24, child: Image.asset('assets/Apellido.png')),
                              ),
                              apellidoController,
                              tipo: 'letras',
                              hintText: "ej: Pérez",
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _dropdownConEtiqueta(
                                    "Especie",
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Image.asset(
                                          especieSeleccionada != null
                                              ? iconosEspecie[especieSeleccionada!]!
                                              : 'assets/Especie.png',
                                        ),
                                      ),
                                    ),
                                    ["Perro", "Gato", "Ave", "Conejo", "Otro"],
                                    "Seleccione",
                                    valorInicial: especieSeleccionada,
                                    onChanged: (valor) {
                                      setState(() {
                                        especieSeleccionada = valor;
                                      });
                                    },
                                  ),
                                ),

                                const SizedBox(width: 12), // espacio entre los dos campos

                                Expanded(
                                  child: _dropdownConEtiqueta(
                                    "Género",
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Image.asset(
                                          generoSeleccionado != null
                                              ? iconosGenero[generoSeleccionado!]!
                                              : 'assets/Genero.png',
                                        ),
                                      ),
                                    ),
                                    ["Macho", "Hembra"],
                                    "Seleccione",
                                    valorInicial: generoSeleccionado,
                                    onChanged: (valor) {
                                      setState(() {
                                        generoSeleccionado = valor;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            _campoTextoConEtiqueta(
                              "Raza",
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SizedBox(width: 24, height: 24, child: Image.asset('assets/Raza.png')),
                              ),
                              razaController,
                              tipo: 'letras',
                              hintText: "ej: Labrador / Persa / Loro Amazónico",
                            ),
                            _campoFechaNacimiento(context),
                    
                            Row(
                              children: [
                                Expanded(
                                  child: _campoPeso(
                                    "Peso",
                                    "assets/Peso.png",
                                    pesoController,
                                  ),
                                ),

                                const SizedBox(width: 12), // espacio horizontal

                                Expanded(
                                  child: _dropdownConEtiquetaEsterilizado(
                                    "¿Está esterilizado?",
                                    _icono("assets/carpeta.png"),
                                    ["Si", "No"],
                                    "Seleccione",
                                    esterilizado,
                                    (val) => setState(() => esterilizado = val),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  icon: SizedBox(width: 24, height: 24, child: Image.asset('assets/cancelar.png')),
                                  label: const Text("Cancelar"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    mostrarConfirmacionRegistro(context, _registrarMascota); // 👈 Muestra el mensaje en lugar de registrar directo
                                  },
                                  icon: SizedBox(width: 24, height: 24, child: Image.asset('assets/Correcto.png')),
                                  label: const Text("Añadir"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            ),
          ),
          if (_menuAbierto)
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              child: MenuLateralAnimado(onCerrar: _toggleMenu, id: widget.id_dueno),
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
  

  Widget _icono(String assetPath) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(width: 24, height: 24, child: Image.asset(assetPath)),
    );
  }


  Widget _campoTextoConEtiqueta(
    String etiqueta, 
    Widget iconoWidget, 
    TextEditingController controller, {
    String hintText = '',
    String tipo = 'texto', // 'texto', 'num' o 'letras'
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: tipo == 'num' ? TextInputType.number : TextInputType.text,
          inputFormatters: [
            if (tipo == 'num') FilteringTextInputFormatter.digitsOnly,
            if (tipo == 'letras')
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
          ],
          maxLength: (etiqueta == "Cédula" || etiqueta == "Teléfono") ? 10 : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: hintText.isEmpty ? "Digite $etiqueta" : hintText,
            prefixIcon: iconoWidget,
            counterText: "",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (valor) {
            if (valor == null || valor.isEmpty) {
              return 'Por favor ingresa $etiqueta';
            }
            if (tipo == 'num' && !RegExp(r'^[0-9]+$').hasMatch(valor)) {
              return 'Solo se permiten números';
            }
            if (tipo == 'letras' && !RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(valor)) {
              return 'Solo se permiten letras';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _dropdownConEtiquetaEsterilizado(String etiqueta, Widget icono, List<String> opciones, String hintText, String? valorActual, Function(String?) onChanged) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey[800]),
              prefixIcon: icono,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            value: valorActual,
            items: opciones.map((opcion) {
              return DropdownMenuItem(value: opcion, child: Text(opcion));
            }).toList(),
            onChanged: onChanged,
          ),
          const SizedBox(height: 12),
        ],
      );
    }

  Widget _dropdownConEtiqueta(
    String etiqueta,
    Widget iconoWidget,
    List<String> opciones,
    String hintText,
    {String? valorInicial, required Function(String?) onChanged}
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[800]),
            prefixIcon: iconoWidget,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          value: valorInicial,
          items: opciones.map((opcion) {
            return DropdownMenuItem(value: opcion, child: Text(opcion));
          }).toList(),
          onChanged: onChanged,
        ),
        const SizedBox(height: 12),
      ],
    );
  }


  Widget _campoPeso(String etiqueta, String imagePath, TextEditingController controller) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        etiqueta,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      const SizedBox(height: 4),
      TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly, // solo números
        ],
        decoration: InputDecoration(
          hintText: "Ej: 23",
          hintStyle: TextStyle(color: Colors.grey[800]),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(8.0), // margen para que no se vea aplastado
            child: Image.asset(
              imagePath,
              width: 24,
              height: 24,
            ),
          ),
          suffixText: "Kg",
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      const SizedBox(height: 12),
    ],
  );
}


  Widget _campoFechaNacimiento(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Fecha de nacimiento",
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      const SizedBox(height: 4),
      GestureDetector(
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime(2020),
            firstDate: DateTime(2000),
            lastDate: DateTime.now(),
            builder: (context, child) {
              return Theme(
                data: ThemeData(
                  useMaterial3: true,
                  colorScheme: ColorScheme.light(
                    primary: Color(0xFF3A97F5),   // 🌟 Color celeste (botones, selección)
                    onPrimary: Colors.white,      // Texto dentro de los botones
                    surface: Colors.white,        // Fondo del calendario
                    onSurface: Colors.black87,    // Texto general
                  ),
                  textButtonTheme: TextButtonThemeData(
                    style: TextButton.styleFrom(
                      foregroundColor: Color(0xFF3A97F5), // Color de "Cancelar"
                    ),
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            setState(() {
              _fechaNacimiento = picked;
            });
          }
        },
        child: AbsorbPointer(
          child: TextField(
            decoration: InputDecoration(
              hintText: _fechaNacimiento == null
                  ? "Seleccione la fecha"
                  : "${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}",
              hintStyle: TextStyle(color: Colors.grey[800]),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  "assets/Calendario.png", // tu imagen personalizada
                  width: 24,
                  height: 24,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
    ],
  );
}

}