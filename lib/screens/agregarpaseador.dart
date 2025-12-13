import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'mipaseador2.dart';
import 'iniciarsesion.dart';

class _MilesFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern('es_CO');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String texto = newValue.text.replaceAll('.', '');
    if (texto.isEmpty) return newValue.copyWith(text: '');
    try {
      final valor = int.parse(texto);
      final nuevoTexto = _formatter.format(valor);
      return TextEditingValue(
        text: nuevoTexto,
        selection: TextSelection.collapsed(offset: nuevoTexto.length),
      );
    } catch (_) {
      return oldValue;
    }
  }
}

class Agregarpaseador extends StatefulWidget {

  const Agregarpaseador({super.key});

  @override
  State<Agregarpaseador> createState() => _Agregarpaseador();
}

class _Agregarpaseador extends State<Agregarpaseador> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreTienda = TextEditingController();
  final TextEditingController _apellido = TextEditingController();
  final TextEditingController _telefono = TextEditingController();
  final TextEditingController _direccion = TextEditingController();
  final TextEditingController _descripcion= TextEditingController();
  final TextEditingController _experiencia = TextEditingController();
  final TextEditingController _tarifa = TextEditingController();
  final TextEditingController _cedula = TextEditingController();
  final TextEditingController correoController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmarController = TextEditingController();
  bool _ocultarPassword = true;
  bool _ocultarConfirmar = true;

  List<String> _tipoPagoSeleccionado = [];


  TimeOfDay? _horaApertura;
  TimeOfDay? _horaCierre;
  TimeOfDay? _horaAperturaSabado;
  TimeOfDay? _horaCierreSabado;
  TimeOfDay? _horaAperturaDomingo;
  TimeOfDay? _horaCierreDomingo;
  bool _abreDomingo = false;
  Uint8List? _certificadoBytes;
  String? _rutaCertificado;

  File? _imagen; // para móvil
  Uint8List? _webImagen; // para web
  String? _imagenBase64; // imagen lista para enviar al backend

  String? departamentoSeleccionado;
  String? ciudadSeleccionada;

  final Map<String, List<String>> ciudadesPorDepartamento = {
    "Cundinamarca": [
      "Bogotá",
      "Soacha",
      "Zipaquirá",
      "Chía",
      "Fusagasugá",
      "Girardot",
      "Facatativá",
      "Madrid",
      "Mosquera",
      "Cajicá",
    ],

    "Antioquia": [
      "Medellín",
      "Bello",
      "Envigado",
      "Itagüí",
      "Rionegro",
      "La Ceja",
      "Sabaneta",
      "Apartadó",
      "Turbo",
      "Caucasia",
    ],

    "Valle del Cauca": [
      "Cali",
      "Palmira",
      "Buenaventura",
      "Tuluá",
      "Buga",
      "Cartago",
      "Jamundí",
      "Yumbo",
      "Sevilla",      
      "Caicedonia",  
    ],

    "Atlántico": [
      "Barranquilla",
      "Soledad",
      "Malambo",
      "Galapa",
      "Sabanalarga",
      "Baranoa",
      "Puerto Colombia",
    ],

    "Santander": [
      "Bucaramanga",
      "Floridablanca",
      "Girón",
      "Piedecuesta",
      "Barrancabermeja",
      "San Gil",
      "Socorro",
    ],

    "Nariño": [
      "Pasto",
      "Ipiales",
      "Tumaco",
      "Túquerres",
      "Sandoná",
    ],

    "Bolívar": [
      "Cartagena",
      "Magangué",
      "Turbaco",
      "Arjona",
      "Mompox",
    ],

    "Tolima": [
      "Ibagué",
      "Espinal",
      "Melgar",
      "Honda",
      "Chaparral",
    ],

    "Cesar": [
      "Valledupar",
      "Aguachica",
      "Bosconia",
      "Curumaní",
    ],

    "Huila": [
      "Neiva",
      "Pitalito",
      "Garzón",
      "La Plata",
    ],

    "Boyacá": [
      "Tunja",
      "Duitama",
      "Sogamoso",
      "Chiquinquirá",
      "Paipa",
    ],

    "Meta": [
      "Villavicencio",
      "Acacías",
      "Granada",
      "Puerto López",
    ],

    "Risaralda": [
      "Pereira",
      "Dosquebradas",
      "Santa Rosa de Cabal",
    ],

    "Caldas": [
      "Manizales",
      "Chinchiná",
      "La Dorada",
      "Villamaría",
    ],

    "Quindío": [
      "Armenia",
      "Calarcá",
      "Quimbaya",
      "Montenegro",
    ],
  };
  
  @override
  void initState() {
    super.initState();
    _cargarImagenPorDefecto();

  }

  @override
  void dispose() {
    _nombreTienda.dispose();
    super.dispose();
  }

  Future<void> registrarPaseador() async {
   bool validarCorreo(String correo) {
      final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      return regex.hasMatch(correo);
    }
    if (passwordController.text != confirmarController.text) {
      mostrarMensajeFlotante(
          context,
          "❌ Las contraseñas no coinciden",
        );
      return;
    }
    if (!validarCorreo(correoController.text)) {
      mostrarMensajeFlotante(
          context,
          "❌ Por favor, ingrese un correo válido.",
        );
      return;
    }
    List<String> camposFaltantes = [];

    if (_nombreTienda.text.isEmpty) camposFaltantes.add("Nombre");
    if (_apellido.text.isEmpty) camposFaltantes.add("Apellido");
    if (_tarifa.text.isEmpty) camposFaltantes.add("Tarifa por hora");
    if (_telefono.text.isEmpty) camposFaltantes.add("Teléfono");
    if (_direccion.text.isEmpty) camposFaltantes.add("Dirección");
    if (_experiencia.text.isEmpty) camposFaltantes.add("Experiencia");
    if (_cedula.text.isEmpty) camposFaltantes.add("Cédula");

    if (correoController.text.isEmpty) camposFaltantes.add("Correo");
    if (passwordController.text.isEmpty) camposFaltantes.add("Contraseña");
    if (confirmarController.text.isEmpty) camposFaltantes.add("Confirmar contraseña");

    // Horarios
    if (_horaApertura == null) camposFaltantes.add("Hora de apertura");
    if (_horaCierre == null) camposFaltantes.add("Hora de cierre");
    if (_horaAperturaSabado == null) camposFaltantes.add("Apertura sábado");
    if (_horaCierreSabado == null) camposFaltantes.add("Cierre sábado");

    // Tipo de pago
    if (_tipoPagoSeleccionado.isEmpty) camposFaltantes.add("Tipo de pago");

    // Departamento y ciudad
    if (departamentoSeleccionado == null || departamentoSeleccionado!.isEmpty) {
      camposFaltantes.add("Departamento");
    }
    if (ciudadSeleccionada == null || ciudadSeleccionada!.isEmpty) {
      camposFaltantes.add("Ciudad");
    }

    // ---------------------------
    // SI HAY CAMPOS FALTANTES → MOSTRAR MENSAJE
    // ---------------------------
    if (camposFaltantes.isNotEmpty) {
      mostrarMensajeFlotante(
        context,
        "⚠️ Faltan los siguientes campos:\n• ${camposFaltantes.join("\n• ")}",
        colorFondo: Colors.white,
        colorTexto: Colors.redAccent,
      );
      return;
    }

    try {
      // 💰 Procesar tarifa (quitar puntos y convertir a double)
      String textoTarifa = _tarifa.text.replaceAll('.', '');
      double tarifaDecimal = double.parse(textoTarifa);

      // 🕒 Formatear horarios
      String horaLunes = "${_horaApertura!.hour.toString().padLeft(2, '0')}:${_horaApertura!.minute.toString().padLeft(2, '0')}:00";
      String cierreLunes = "${_horaCierre!.hour.toString().padLeft(2, '0')}:${_horaCierre!.minute.toString().padLeft(2, '0')}:00";
      String horaSabado = "${_horaAperturaSabado!.hour.toString().padLeft(2, '0')}:${_horaAperturaSabado!.minute.toString().padLeft(2, '0')}:00";
      String cierreSabado = "${_horaCierreSabado!.hour.toString().padLeft(2, '0')}:${_horaCierreSabado!.minute.toString().padLeft(2, '0')}:00";

      String? horaDomingo = _abreDomingo && _horaAperturaDomingo != null
          ? "${_horaAperturaDomingo!.hour.toString().padLeft(2, '0')}:${_horaAperturaDomingo!.minute.toString().padLeft(2, '0')}:00"
          : null;
      String? cierreDomingo = _abreDomingo && _horaCierreDomingo != null
          ? "${_horaCierreDomingo!.hour.toString().padLeft(2, '0')}:${_horaCierreDomingo!.minute.toString().padLeft(2, '0')}:00"
          : null;

      mostrarLoading(context);
      // 🌐 URL del backend
      final url = Uri.parse("https://apphuellitas-production.up.railway.app/registrarPaseador");

      // 🧠 Datos a enviar
      final body = {
        "nombre": _nombreTienda.text,
        "apellido": _apellido.text,
        "cedulaUsuario": _cedula.text,
        "imagen": _imagenBase64 ?? "",
        "descripcion": _descripcion.text.isNotEmpty ? _descripcion.text : null,
        "experiencia": _experiencia.text,
        "direccion": _direccion.text,
        "telefono": _telefono.text,
        "horariolunesviernes": horaLunes,
        "cierrelunesviernes": cierreLunes,
        "horariosabado": horaSabado,
        "cierrehorasabado": cierreSabado,
        "horariodomingos": horaDomingo,
        "cierredomingos": cierreDomingo,
        "metodopago": _tipoPagoSeleccionado.join(", "),
        "certificado": _certificadoBytes != null ? base64Encode(_certificadoBytes!) : "",
        "tarifa": tarifaDecimal.toString(),
        "correo": correoController.text,
        "contrasena": confirmarController.text,
        "departamento": departamentoSeleccionado,
        "ciudad": ciudadSeleccionada,
      };

      // 📤 Enviar solicitud al backend
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      ocultarLoading(context);
      if (response.statusCode == 201) {
        _nombreTienda.clear();
        _apellido.clear();
        _tarifa.clear();
        _telefono.clear();
        _direccion.clear();
        _experiencia.clear();
        _cedula.clear();
        correoController.clear();
        passwordController.clear();
        confirmarController.clear();

        // Horarios
        setState(() {
          _horaApertura = null;
          _horaCierre = null;
          _horaAperturaSabado = null;
          _horaCierreSabado = null;

          // Departamento y ciudad
          departamentoSeleccionado = null;
          ciudadSeleccionada = null;

          // Tipo de pago
          _tipoPagoSeleccionado = [];
        });
        final data = jsonDecode(response.body);
        final paseador = data["mipaseador"];
        final id_paseador = paseador["id_paseador"];
        mostrarMensajeFlotante(
          context,
          "✅ Perfil de paseador registrado correctamente",
          colorFondo: const Color.fromARGB(255, 243, 243, 243),
          colorTexto: const Color.fromARGB(255, 0, 0, 0),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PerfilPaseadorScreen(id_paseador: id_paseador)),
        );
      } else if (response.statusCode == 409) {
        mostrarMensajeFlotante(
          context,
          "⚠️ Este usuario ya está registrado.",
          colorFondo: Colors.white,
          colorTexto: Colors.orangeAccent,
        );
      }

      // 🔹 Otros errores
      else {
        mostrarMensajeFlotante(
          context,
          "❌ Error al registrar el perfil (${response.statusCode})",
          colorFondo: Colors.white,
          colorTexto: Colors.redAccent,
        );
      }
    } catch (e) {
      mostrarMensajeFlotante(
        context,
        "❌ Error: ${e.toString()}",
        colorFondo: Colors.white,
        colorTexto: Colors.redAccent,
      );
    }
  }

  void ocultarLoading(BuildContext context) {
    Navigator.of(context).pop(); // cierra el diálogo
  }


  void mostrarLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // No se puede cerrar tocando afuera
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
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



  Future<void> _cargarImagenPorDefecto() async {
    final byteData = await rootBundle.load('assets/usuario.png');
    final bytes = byteData.buffer.asUint8List();
    setState(() {
      _imagenBase64 = base64Encode(bytes);
      _webImagen = bytes; // para mostrarla en web
    });
  }

  // 📸 Método para abrir galería y actualizar imagen
  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final imagenSeleccionada = await picker.pickImage(source: ImageSource.gallery);

    if (imagenSeleccionada != null) {
      try {
        Uint8List bytes;

        if (!kIsWeb) {
          // 📱 Si es móvil
          final imagenFile = File(imagenSeleccionada.path);
          bytes = await imagenFile.readAsBytes();
          setState(() {
            _imagen = imagenFile;
          });
        } else {
          // 💻 Si es web
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

  Future<void> _seleccionarCertificado() async {
    try {
      final resultado = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (resultado != null) {
        if (kIsWeb) {
          // En web usamos solo los bytes
          final bytes = resultado.files.single.bytes;
          if (bytes != null) {
            setState(() {
              _certificadoBytes = bytes;
              _rutaCertificado = null; // path no disponible en web
            });
          }
        } else {
          // En móvil usamos path
          final path = resultado.files.single.path;
          if (path != null) {
            setState(() {
              _rutaCertificado = path;
              _certificadoBytes = resultado.files.single.bytes; // opcional, si quieres
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error al seleccionar certificado: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al seleccionar el archivo")),
      );
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
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/bosque.jpeg"), // fondo
              fit: BoxFit.cover,
            ),
          ),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Container(color: Colors.black.withOpacity(0.3)),
        ),
        Container(color: Colors.black.withOpacity(0.3)),

        // Contenido principal
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    "Mi perfil de paseador",
                    style: TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // 🔹 Contenedor principal de formulario
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.lightBlue.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Imagen de la tienda
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
                                              : const AssetImage('assets/usuario.png'))
                                          as ImageProvider,
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

                            // Campos del formulario
                            _campoTextoSimple(
                              "Nombre del paseador",
                              "assets/Nombre.png",
                              _nombreTienda,
                              "Ej: Lara",
                              soloLetras: true,  
                            ),
                            _campoTextoSimple(
                              "Apellido del paseador",
                              "assets/formato-de-texto.png",
                              _apellido,
                              "Ej: Mendez",
                              soloLetras: true,  
                            ),
                            _campoTextoSimple("Cédula", "assets/cedula11.png", _cedula, "Ej: 1115574887", soloNumeros: true),
                            Row(
                              children: [
                                Expanded(child: _campoHoraApertura(context)),
                                SizedBox(width: 12),
                                Expanded(child: _campoHoraCierre(context)),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(child: _campoHoraAperturaSabado(context)),
                                SizedBox(width: 12),
                                Expanded(child: _campoHoraCierreSabado(context)),
                              ],
                            ),
                            _switchDiaCerrado(
                              "¿Tiene disponibilidad los domingos?",
                              _abreDomingo,
                              (val) => setState(() => _abreDomingo = val),
                            ),

                            if (_abreDomingo) ...[
                              Row(
                                children: [
                                  Expanded(child: _campoHoraAperturaDomingo(context)),
                                  SizedBox(width: 12),
                                  Expanded(child: _campoHoraCierreDomingo(context)),
                                ],
                              ),
                            ],
                            _campoTextoSimple(
                              "Teléfono",
                              "assets/Telefono.png",
                              _telefono,
                              "Ej: 3001234567",
                              soloNumeros: true,
                            ),
                            
                            Row(
                              children: [
                                // Departamento
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Departamento",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          shadows: [
                                            Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black45),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      DropdownButtonFormField<String>(
                                        value: departamentoSeleccionado,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.white,
                                          prefixIcon: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: Image.asset("assets/mapa-de-colombia.png"),
                                            ),
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(12)),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                        hint: const Text("Seleccione"),
                                        items: ciudadesPorDepartamento.keys.map((departamento) {
                                          return DropdownMenuItem(
                                            value: departamento,
                                            child: Text(departamento),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            departamentoSeleccionado = value;
                                            ciudadSeleccionada = null; // reset ciudad
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 10), // Espacio entre los campos

                                // Ciudad
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Ciudad",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          shadows: [
                                            Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black45),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      DropdownButtonFormField<String>(
                                        value: ciudadSeleccionada,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.white,
                                          prefixIcon: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: Image.asset("assets/alfiler.png"),
                                            ),
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(12)),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                        hint: const Text("Seleccione"),
                                        items: (departamentoSeleccionado == null)
                                            ? []
                                            : ciudadesPorDepartamento[departamentoSeleccionado]!
                                                .map((ciudad) => DropdownMenuItem(
                                                      value: ciudad,
                                                      child: Text(ciudad),
                                                    ))
                                                .toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            ciudadSeleccionada = value;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                                

                            const SizedBox(height: 10),
                            _campoTextoSimple(
                              "Zona de servicio",
                              "assets/Ubicacion.png",
                              _direccion,
                              "Ej: Calle 123 #45-67",
                              esDireccion: true,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _campoTextoSimple(
                                    "Experiencia",
                                    "assets/sombrero.png",
                                    _experiencia,
                                    "Ej: 5 años ",
                                    esDireccion: true,
                                  ),
                                ),
                                SizedBox(width: 12), // separación
                                Expanded(
                                  child: _campoTextoSimple(
                                    "Tarifa por hora",
                                    "assets/precio.png",
                                    _tarifa,
                                    "Ej: 10.000",
                                    formatoMiles: true,
                                  ),
                                ),
                              ],
                            ),
                            _campoMultiSeleccion(
                              "Tipo de pago",
                              "assets/Pago.png",
                              ["Efectivo", "Tarjeta débito / crédito", "PSE", "Nequi", "Daviplata"],
                            ),
                            _campoDescripcion(
                              "Descripción",
                              "assets/Descripcion.png",
                              _descripcion,
                            ),

                            _campoTextoSimple(
                                "Correo",
                                "assets/gmail.png",
                                correoController,
                                "Ej: romero@gmail.com",
                                esCorreo: true,
                              ),

                            Row(
                              children: [
                                Expanded(
                                  child: _campoPassword(
                                    "Contraseña",
                                    controller: passwordController,
                                    ocultar: _ocultarPassword,
                                    onToggle: () {
                                      setState(() => _ocultarPassword = !_ocultarPassword);
                                    },
                                    icono: Image.asset('assets/candado.png'),
                                  ),
                                ),

                                SizedBox(width: 16), // espacio entre los campos

                                Expanded(
                                  child: _campoPassword(
                                    "Confirmar contraseña",
                                    controller: confirmarController,
                                    ocultar: _ocultarConfirmar,
                                    onToggle: () {
                                      setState(() => _ocultarConfirmar = !_ocultarConfirmar);
                                    },
                                    icono: Image.asset('assets/candado.png'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Sección de certificado
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: _seleccionarCertificado,
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF26303D), Color(0xFF192837)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            offset: const Offset(0, 3),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.upload_file, color: Colors.white),
                                          const SizedBox(width: 8),
                                          Text(
                                            (_rutaCertificado != null || _certificadoBytes != null)
                                                ? "Certificado cargado ✅"
                                                : "Subir certificado",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // Contenedor fijo para la imagen
                                  Container(
                                    width: double.infinity,
                                    height: 180,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.grey[200],
                                    ),
                                    child: (_rutaCertificado != null || _certificadoBytes != null)
                                        ? Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: kIsWeb
                                                    ? Image.memory(
                                                        _certificadoBytes!,
                                                        width: double.infinity,
                                                        height: 180,
                                                        fit: BoxFit.cover,
                                                      )
                                                    : Image.file(
                                                        File(_rutaCertificado!),
                                                        width: double.infinity,
                                                        height: 180,
                                                        fit: BoxFit.cover,
                                                      ),
                                              ),
                                              // Botón para eliminar
                                              Positioned(
                                                top: 4,
                                                right: 4,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.black54,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: IconButton(
                                                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                                    onPressed: () {
                                                      setState(() {
                                                        _rutaCertificado = null;
                                                        _certificadoBytes = null;
                                                      });
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : const Center(child: Text("No hay certificado")),
                                  ),
                                ],
                              )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    registrarPaseador();

                },
                  icon: SizedBox(
                    width: 30,
                    height: 30,
                    child: Image.asset('assets/agregar 1.png'),
                  ),
                  label: const Text(
                    'Registrarse',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(1.5, 1.5),
                          color: Colors.black,
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                    elevation: 6,
                  ),
                ),

                const SizedBox(height: 5),

                // 🔹 Texto para ir al login
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    child: const Text(
                      "¿Ya tienes una cuenta? Iniciar sesión",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        shadows: [
                          Shadow(
                            offset: Offset(1.5, 1.5),
                            color: Colors.black,
                            blurRadius: 2,
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
      ],
    ),
  );
}


  String _formatearHora(TimeOfDay hora) {
    final horaInt = hora.hourOfPeriod == 0 ? 12 : hora.hourOfPeriod;
    final periodo = hora.period == DayPeriod.am ? "AM" : "PM";
    return "${horaInt.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')} $periodo";
  }

  Widget _icono(String assetPath) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(width: 24, height: 24, child: Image.asset(assetPath)),
    );
  }


  Widget _campoTextoSimple(
    String etiqueta,
    String iconoPath,
    TextEditingController controller,
    String hintText, {
    bool soloLetras = false,
    bool soloNumeros = false,
    bool esDireccion = false,
    bool formatoMiles = false, 
    bool readOnly = false, 
    bool esCorreo = false,// 👈 NUEVO: agrega puntos de miles (ej: 10.000)
  }) {
    List<TextInputFormatter> filtros = [];

    if (soloLetras) {
      // ✅ Solo letras (mayúsculas, minúsculas, tildes, ñ) y espacios
      filtros.add(FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')));
      
    } else if (soloNumeros) {
      // ✅ Solo números
      filtros.add(FilteringTextInputFormatter.digitsOnly);
    } else if (esDireccion) {
      // ✅ Letras, números, espacios y caracteres comunes en direcciones
      filtros.add(FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z0-9\s\#\.,\-]")));
    } else if (formatoMiles) {
      // ✅ Formatear con puntos de miles automáticamente
      filtros.add(_MilesFormatter());
    } else if (esCorreo) {
    // ✅ Solo caracteres válidos para correos electrónicos
    filtros.add(FilteringTextInputFormatter.allow(
        RegExp(r'[a-zA-Z0-9@._\-]')));
    }

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
          keyboardType: formatoMiles || soloNumeros ? TextInputType.number : TextInputType.text,
          inputFormatters: filtros,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[800]),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: Image.asset(iconoPath, fit: BoxFit.contain),
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  
  Widget _campoDescripcion(String etiqueta, String assetPath, TextEditingController controller) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          SizedBox(width: 24, height: 24, child: Image.asset(assetPath)),
          const SizedBox(width: 8),
          Text(etiqueta, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
      const SizedBox(height: 4),
      TextField(
        controller: controller,
        maxLines: 4,
        keyboardType: TextInputType.multiline,
        inputFormatters: [
          FilteringTextInputFormatter.allow(
            RegExp(r"[a-zA-Z0-9 áéíóúÁÉÍÓÚñÑ.,()\-_/º°!?\s]"),
          ),
        ],
        decoration: InputDecoration(
          hintText: "Ej: Paseador responsable con experiencia en manejo de perros pequeños y grandes.",
          hintStyle: TextStyle(color: Colors.grey[800]),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      const SizedBox(height: 12),
    ],
  );
}

  Widget _switchDiaCerrado(String texto, bool valor, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(texto, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        Switch(value: valor, onChanged: onChanged, activeColor: Colors.green),
      ],
    );
  }

  Widget _campoHora(
    BuildContext context,
    String etiqueta,
    TimeOfDay? hora,
    Function(TimeOfDay) onPicked,
    String iconoPath,
    String hintText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            final TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: hora ?? TimeOfDay(hour: 9, minute: 0),
              builder: (context, child) {
                return Theme(
                  data: ThemeData.light().copyWith(
                    colorScheme: ColorScheme.light(primary: Colors.blue[700]!),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              onPicked(picked);
            }
          },
          child: AbsorbPointer(
            child: TextField(
              decoration: InputDecoration(
                hintText: hora == null ? hintText : _formatearHora(hora),
                hintStyle: TextStyle(color: Colors.grey[800]),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: Image.asset(iconoPath, fit: BoxFit.contain),
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _campoHoraApertura(BuildContext context) => _campoHora(
        context,
        "Hora disponible Lunes-Viernes",
        _horaApertura,
        (picked) => setState(() => _horaApertura = picked),
        "assets/Calendario.png",
        "Seleccione la hora de inicio de su disponibilidad",
      );

  Widget _campoHoraCierre(BuildContext context) => _campoHora(
        context,
        "Hora de cierre Lunes-Viernes",
        _horaCierre,
        (picked) => setState(() => _horaCierre = picked),
        "assets/Calendario1.png",
        "Seleccione la hora de cierre",
      );

  Widget _campoHoraAperturaSabado(BuildContext context) => _campoHora(
        context,
        "Hora disponible sábado",
        _horaAperturaSabado,
        (picked) => setState(() => _horaAperturaSabado = picked),
        "assets/Calendario.png",
        "Seleccione la hora de inicio de su disponibilidad",
      );

  Widget _campoHoraCierreSabado(BuildContext context) => _campoHora(
        context,
        "Hora cierre sábado",
        _horaCierreSabado,
        (picked) => setState(() => _horaCierreSabado = picked),
        "assets/Calendario1.png",
        "Seleccione la hora de cierre",
      );

  Widget _campoHoraAperturaDomingo(BuildContext context) => _campoHora(
        context,
        "Hora disponible Domingo",
        _horaAperturaDomingo,
        (picked) => setState(() => _horaAperturaDomingo = picked),
        "assets/Calendario.png",
        "Seleccione la hora de inicio de su disponibilidad",
      );

  Widget _campoHoraCierreDomingo(BuildContext context) => _campoHora(
        context,
        "Hora cierre Domingo",
        _horaCierreDomingo,
        (picked) => setState(() => _horaCierreDomingo = picked),
        "assets/Calendario1.png",
        "Seleccione la hora de cierre",
      );

  Widget _dropdownConEtiqueta(String etiqueta, Widget icono, List<String> opciones, String hintText, String? valorActual, Function(String?) onChanged) {
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

  Widget _campoMultiSeleccion(String etiqueta, String iconoPath, List<String> opciones) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            // 👇 variable temporal con nombre correcto
            List<String> metodosTemp = List.from(_tipoPagoSeleccionado);

            final resultado = await showDialog<List<String>>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text("Selecciona $etiqueta"),
                  content: StatefulBuilder(
                    builder: (context, setStateSB) {
                      return SingleChildScrollView(
                        child: Column(
                          children: opciones.map((opcion) {
                            return CheckboxListTile(
                              value: metodosTemp.contains(opcion),
                              title: Text(opcion),
                              onChanged: (bool? valor) {
                                setStateSB(() {
                                  if (valor == true) {
                                    metodosTemp.add(opcion);
                                  } else {
                                    metodosTemp.remove(opcion);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                  actions: [
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context, null),
                      icon: Image.asset(
                        "assets/icon_cancelar.png",
                        width: 20,
                        height: 20,
                      ),
                      label: const Text("Cancelar"),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, metodosTemp),
                      icon: Image.asset(
                        "assets/icon_aceptar.png",
                        width: 20,
                        height: 20,
                      ),
                      label: const Text("Aceptar"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                );
              },
            );

            if (resultado != null) {
              setState(() {
                _tipoPagoSeleccionado = resultado;
              });
              print("💳 Métodos seleccionados: $_tipoPagoSeleccionado");
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Row(
              children: [
                SizedBox(width: 24, height: 24, child: Image.asset(iconoPath)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _tipoPagoSeleccionado.isEmpty
                        ? "Ej: Efectivo, Tarjeta..."
                        : _tipoPagoSeleccionado.join(", "),
                    style: TextStyle(
                      color: _tipoPagoSeleccionado.isEmpty ? Colors.grey : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _campoPassword(
    String label, {
    required TextEditingController controller,
    required bool ocultar,
    required VoidCallback onToggle,
    required Widget icono,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔸 Texto del label encima del campo
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            shadows: [
              Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black45),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // 🔸 Campo de contraseña con validación y estilo
        TextFormField(
          controller: controller,
          obscureText: ocultar,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: "ej: 12345678",
            prefixIcon: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(width: 24, height: 24, child: icono),
            ),
            suffixIcon: IconButton(
              onPressed: onToggle,
              icon: Icon(
                ocultar ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[700],
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (valor) {
            if (valor == null || valor.isEmpty) {
              return 'La contraseña es obligatoria';
            }

            if (valor.length < 8) {
              return 'La contraseña debe tener al menos 8 caracteres';
            }

            final mayuscula = RegExp(r'[A-Z]');
            final minuscula = RegExp(r'[a-z]');
            final numero = RegExp(r'[0-9]');
            final simbolo = RegExp(r'[@#\$%&*_-]');

            if (!mayuscula.hasMatch(valor)) {
              return 'Debe contener al menos una letra mayúscula';
            }

            if (!minuscula.hasMatch(valor)) {
              return 'Debe contener al menos una letra minúscula';
            }

            if (!numero.hasMatch(valor)) {
              return 'Debe contener al menos un número';
            }

            if (!simbolo.hasMatch(valor)) {
              return 'Debe contener al menos un símbolo: @ # \$ % & * _ -';
            }

            // También podemos asegurar que solo tenga caracteres válidos
            final regex = RegExp(r'^[a-zA-Z0-9@#\$%&*_-]+$');
            if (!regex.hasMatch(valor)) {
              return 'Caracteres inválidos detectados';
            }

            return null; // contraseña válida
          },
        ),
      ],
    );
  }
  
}