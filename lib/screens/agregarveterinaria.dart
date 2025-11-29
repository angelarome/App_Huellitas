import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'veterinaria2.dart';

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

class AgregarVeterinariaScreen extends StatefulWidget {

  const AgregarVeterinariaScreen({super.key});

  @override
  State<AgregarVeterinariaScreen> createState() => _AgregarVeterinariaScreenState();
}

class _AgregarVeterinariaScreenState extends State<AgregarVeterinariaScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreTienda = TextEditingController();
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
  final _domicilioController = TextEditingController();

  TimeOfDay? _horaApertura;
  TimeOfDay? _horaCierre;
  TimeOfDay? _horaAperturaSabado;
  TimeOfDay? _horaCierreSabado;
  TimeOfDay? _horaAperturaDomingo;
  TimeOfDay? _horaCierreDomingo;
  bool _abreDomingo = false;
  Uint8List? _certificadoBytes;
  String? _rutaCertificado;
  String? _domicilioSeleccionada;

  File? _imagen; // para móvil
  Uint8List? _webImagen; // para web
  String? _imagenBase64; // imagen lista para enviar al backend


  Future<void> registrarVeterinaria() async {
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
    // 🧩 Validación de campos obligatorios
    if (_nombreTienda.text.isEmpty ||
        _cedula.text.isEmpty ||
        _tarifa.text.isEmpty ||
        _telefono.text.isEmpty ||
        _direccion.text.isEmpty ||
        _experiencia.text.isEmpty ||
        _horaApertura == null ||
        _horaCierre == null ||
        _horaAperturaSabado == null ||
        _horaCierreSabado == null ||
        _tipoPagoSeleccionado.isEmpty ||
        correoController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmarController.text.isEmpty) {
      mostrarMensajeFlotante(
        context,
        "⚠️ Por favor complete todos los campos obligatorios.",
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

      // 🌐 URL del backend
      final url = Uri.parse("http://localhost:5000/registrarVeterinaria");
      
      // 🧠 Datos a enviar
      final body = {
        
        "imagen": _imagenBase64 ?? "",
        "cedulaUsuario": _cedula.text,
        "nombre_veterinaria": _nombreTienda.text,
        "descripcion": _descripcion.text.isNotEmpty ? _descripcion.text : null,
        "experiencia": _experiencia.text,
        "direccion": _direccion.text,
        "telefono": _telefono.text,
        "domicilio": _domicilioSeleccionada ?? "",
        "horariolunesviernes": horaLunes,
        "cierrelunesviernes": cierreLunes,
        "horariosabado": horaSabado,
        "cierrehorasabado": cierreSabado,
        "horariodomingos": horaDomingo,
        "cierredomingos": cierreDomingo,
        "metodopago": _tipoPagoSeleccionado.join(", "),
        "certificado": _certificadoBytes != null ? base64Encode(_certificadoBytes!) : "",
        "tarifa": tarifaDecimal,
        "correo": correoController.text,
        "contrasena": confirmarController.text,
      };
      // 📤 Enviar solicitud al backend
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      // ✅ Respuesta correcta
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final tienda = data["miveterinaria"];
        final id_veterinaria = tienda["id_veterinaria"];

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PerfilVeterinariaScreen(id_veterinaria: id_veterinaria),
          ),
        );
        
        } else if (response.statusCode == 409) {
        mostrarMensajeFlotante(
          context,
            "⚠️ El usuario ya está registrado",
            colorFondo: const Color.fromARGB(255, 243, 243, 243),
            colorTexto: const Color.fromARGB(255, 0, 0, 0),
          );

      } else {
        mostrarMensajeFlotante(
          context,
          "❌ Error al registrar la veterinaria (${response.statusCode})",
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

  void mostrarConfirmacionRegistro(BuildContext context) {
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
                      '¿Deseas registrar esta veterinaria?',
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
                            registrarVeterinaria(); // 👉 Llama a la función que hace el registro
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
        // Fondo con imagen
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/paseador1.jpeg"),
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Filtro borroso
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
                // 🔹 Barra superior
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: SizedBox(
                        width: 24,
                        height: 24,
                        child: Image.asset('assets/Menu.png'),
                      ),
                      onPressed: () {},
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {},
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: Image.asset('assets/Perfil.png'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {},
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: Image.asset('assets/Calendr.png'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {},
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: Image.asset('assets/Campana.png'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                const Center(
                  child: Text(
                    "Mi veterinaria",
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
                              "Nombre de la Veterinaria",
                              "assets/Nombre.png",
                              _nombreTienda,
                              "Ej: Pet Paradise",
                              soloLetras: true,
                            ),
                            _campoTextoSimple("Cédula", "assets/cedula11.png", _cedula, "Ej: 1115574887", soloNumeros: true),
                            _campoHoraApertura(context),
                            _campoHoraCierre(context),
                            _campoHoraAperturaSabado(context),
                            _campoHoraCierreSabado(context),
                            _switchDiaCerrado(
                              "¿Abre los domingos?",
                              _abreDomingo,
                              (val) => setState(() => _abreDomingo = val),
                            ),
                            if (_abreDomingo) ...[
                              _campoHoraAperturaDomingo(context),
                              _campoHoraCierreDomingo(context),
                            ],
                            _campoTextoSimple(
                              "Teléfono",
                              "assets/Telefono.png",
                              _telefono,
                              "Ej: 3001234567",
                              soloNumeros: true,
                            ),
                            _dropdownConEtiqueta(
                              "Domicilio",
                              _icono("assets/domicilio.png"),
                              ["Si", "No"],
                              "Seleccione si tiene domicilio",
                              _domicilioSeleccionada,
                              (val) => setState(() => _domicilioSeleccionada = val),
                            ),
                            _campoTextoSimple(
                              "Dirección",
                              "assets/Ubicacion.png",
                              _direccion,
                              "Ej: Calle 123 #45-67",
                              esDireccion: true,
                            ),
                            _campoTextoSimple(
                              "Experiencia",
                              "assets/sombrero.png",
                              _experiencia,
                              "Ej: 5 años de servicio",
                              esDireccion: true,
                            ),
                            _campoTextoSimple(
                              "Tarifa por consulta",
                              "assets/precio.png",
                              _tarifa,
                              "Ej: 10.000",
                              formatoMiles: true,
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

                             _campoPassword(
                              "Contraseña",
                              controller: passwordController,
                              ocultar: _ocultarPassword,
                              onToggle: () {
                                setState(() => _ocultarPassword = !_ocultarPassword);
                              },
                              icono: Image.asset('assets/candado.png'),
                            ),
                  
                            _campoPassword(
                              "Confirmar contraseña",
                              controller: confirmarController, 
                              ocultar: _ocultarConfirmar,
                              onToggle: () {
                                setState(() => _ocultarConfirmar = !_ocultarConfirmar);
                              },
                              icono: Image.asset('assets/candado.png'),
                            ),

                            const SizedBox(height: 12),
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

                // 🔹 Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: lógica para cancelar
                      },
                      icon: SizedBox(
                        width: 24,
                        height: 24,
                        child: Image.asset('assets/cancelar.png'),
                      ),
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
                      onPressed: () => mostrarConfirmacionRegistro(context),
                      icon: SizedBox(
                        width: 24,
                        height: 24,
                        child: Image.asset('assets/Correcto.png'),
                      ),
                      label: const Text("Añadir"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
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
    bool formatoMiles = false, // 👈 NUEVO: agrega puntos de miles (ej: 10.000)
    bool esCorreo = false,
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
      filtros.add(FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9áéíóúÁÉÍÓÚñÑ\s#\-\.,]')));
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

  
  Widget _campoDescripcion(String etiqueta, String assetPath, TextEditingController controller,) {
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
          decoration: InputDecoration(
            hintText: "Digite descripción...",
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
        "Hora de apertura Lunes-Viernes",
        _horaApertura,
        (picked) => setState(() => _horaApertura = picked),
        "assets/Calendario.png",
        "Seleccione la hora de apertura",
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
        "Hora apertura sábado",
        _horaAperturaSabado,
        (picked) => setState(() => _horaAperturaSabado = picked),
        "assets/Calendario.png",
        "Seleccione la hora de apertura",
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
        "Hora apertura Domingo",
        _horaAperturaDomingo,
        (picked) => setState(() => _horaAperturaDomingo = picked),
        "assets/Calendario.png",
        "Seleccione la hora de apertura",
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
        Text(etiqueta, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            // 👇 Variable temporal para editar los métodos seleccionados
            List<String> _metodosSeleccionadosTemp = List.from(_tipoPagoSeleccionado);

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
                              value: _metodosSeleccionadosTemp.contains(opcion),
                              title: Text(opcion),
                              onChanged: (bool? valor) {
                                setStateSB(() {
                                  if (valor == true) {
                                    _metodosSeleccionadosTemp.add(opcion);
                                  } else {
                                    _metodosSeleccionadosTemp.remove(opcion);
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
                    TextButton(
                      onPressed: () => Navigator.pop(context, null),
                      child: const Text("Cancelar"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, _metodosSeleccionadosTemp),
                      child: const Text("Aceptar"),
                    ),
                  ],
                );
              },
            );

            if (resultado != null) {
              setState(() {
                _tipoPagoSeleccionado = resultado;
              });
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
   // 🔹 Campo de contraseña con estilo y validación
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
            hintText: "Ingrese su $label",
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
              return 'Por favor ingresa $label';
            }
            if (valor.length < 6) {
              return 'La contraseña debe tener al menos 6 caracteres';
            }
            return null;
          },
        ),
      ],
    );
  }

}
