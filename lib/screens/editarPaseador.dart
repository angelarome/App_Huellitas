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
import 'mitienda2.dart';
import 'package:intl/intl.dart'; 
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'mipaseador2.dart';

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

class EditarPaseador extends StatefulWidget {
  final int id_paseador;
  final String imagen;
  final String cedulaUsuario;
  final String nombre_paseador;
  final String apellido_paseador;
  final String tarifa;
  final String? descripcion;
  final String experiencia;
  final List<Uint8List>? certificados;
  final String direccion;
  final String telefono;
  final String horariolunesviernes;
  final String cierrelunesviernes;
  final String horariosabado;
  final String cierresabado;
  final String? horariodomingo;
  final String? cierredomingo;
  final String metodopago; // 👈 ahora lista (si viene algo como ["Efectivo", "Nequi"])

  const EditarPaseador({
    super.key,
    required this.id_paseador,
    required this.imagen,
    required this.cedulaUsuario,
    required this.nombre_paseador,
    required this.apellido_paseador,
    required this.tarifa,
    required this.descripcion,
    required this.experiencia,
    required this.certificados,
    required this.direccion,
    required this.telefono,
    required this.horariolunesviernes,
    required this.cierrelunesviernes,
    required this.horariosabado,
    required this.cierresabado,
    required this.horariodomingo,
    required this.cierredomingo,
    required this.metodopago,
  });

  @override
  State<EditarPaseador> createState() => _EditarPaseador();
}

class _EditarPaseador extends State<EditarPaseador> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombrePaseador;
  late TextEditingController _apellidoPaseador;
   late TextEditingController _cedula;
  late TextEditingController _tarifa;
  late TextEditingController _telefono;
  late TextEditingController _direccion;
  late TextEditingController _experiencia;
  late TextEditingController _certificados;
  late TextEditingController _descripcion;
  late TextEditingController _horariolunesviernes;
  late TextEditingController _cierrelunesviernes;
  late TextEditingController _horariosabado;
  late TextEditingController _cierresabado;
  late TextEditingController _horariodomingo;
  late TextEditingController _cierredomingo;
  late TextEditingController _metodopago;

  bool _abreDomingo = false;
  List<String> _tipoPagoSeleccionado = [];

  File? _imagen;
  Uint8List? _webImagen;
  String? _imagenBase64;

  TimeOfDay? _horaApertura;
  TimeOfDay? _horaCierre;
  TimeOfDay? _horaAperturaSabado;
  TimeOfDay? _horaCierreSabado;
  TimeOfDay? _horaAperturaDomingo;
  TimeOfDay? _horaCierreDomingo;
  Uint8List? _certificadoBytes;
  String? _rutaCertificado;

  @override
  void initState() {
    super.initState();

    _nombrePaseador = TextEditingController(text: widget.nombre_paseador);
    _apellidoPaseador = TextEditingController(text: widget.apellido_paseador);
    _cedula = TextEditingController(text: widget.cedulaUsuario);
        // Convertir tarifa a número y formatear con separador de miles
    final tarifaNumero = double.tryParse(widget.tarifa.replaceAll(',', '')) ?? 0;
    final tarifaFormateada = NumberFormat("#,##0", "es_CO").format(tarifaNumero);

    _tarifa = TextEditingController(text: tarifaFormateada);
    _descripcion = TextEditingController(text: widget.descripcion ?? "");
    _direccion = TextEditingController(text: widget.direccion);
    _experiencia = TextEditingController(text: widget.experiencia);
    _certificadoBytes = widget.certificados != null && widget.certificados!.isNotEmpty
      ? widget.certificados![0] // si solo quieres mostrar el primero
      : null;

    _rutaCertificado = null; 
    _telefono = TextEditingController(text: widget.telefono);
    _horariolunesviernes = TextEditingController(text: widget.horariolunesviernes);
    _cierrelunesviernes = TextEditingController(text: widget.cierrelunesviernes);
    _horariosabado = TextEditingController(text: widget.horariosabado);
    _cierresabado = TextEditingController(text: widget.cierresabado);
    _horariodomingo = TextEditingController(text: widget.horariodomingo ?? "");
    _cierredomingo = TextEditingController(text: widget.cierredomingo ?? "");
    _metodopago = TextEditingController(text: widget.metodopago ?? ""); // ✅


    _abreDomingo = widget.horariodomingo != null && widget.horariodomingo!.isNotEmpty;

    // ✅ Tipos de pago
    _tipoPagoSeleccionado = [];
    if (widget.metodopago != null && widget.metodopago!.isNotEmpty) {
      _tipoPagoSeleccionado =
          widget.metodopago!.split(",").map((e) => e.trim()).toList();
    }

    _imagenBase64 = widget.imagen;
  }

  @override
  void dispose() {
    _horariolunesviernes.dispose();
    _cierrelunesviernes.dispose();
    _horariosabado.dispose();
    _cierresabado.dispose();
    _horariodomingo.dispose();
    _cierredomingo.dispose();
    super.dispose();
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



  Future<void> actualizarVeterinaria() async {
    // 🔧 Función para formatear cualquier tipo de hora (con o sin AM/PM)
    String formatearHoraFlexible(String horaTexto) {
      try {
        // Si ya tiene segundos → la devolvemos igual
        if (horaTexto.contains(":") && horaTexto.split(":").length == 3) {
          return horaTexto;
        }

        // Si es tipo "5:30 p. m." o "5:30 PM"
        if (horaTexto.toLowerCase().contains("m")) {
          final partes = horaTexto.split(RegExp(r'[: ]'));
          int hora = int.parse(partes[0]);
          int minuto = int.parse(partes[1]);
          String periodo = horaTexto.toLowerCase().contains('p') ? 'PM' : 'AM';

          if (periodo == 'PM' && hora != 12) hora += 12;
          if (periodo == 'AM' && hora == 12) hora = 0;

          return "${hora.toString().padLeft(2, '0')}:${minuto.toString().padLeft(2, '0')}:00";
        }

        // Si es tipo "09:00"
        final partes = horaTexto.split(":");
        if (partes.length == 2) {
          return "${partes[0].padLeft(2, '0')}:${partes[1].padLeft(2, '0')}:00";
        }
      } catch (_) {}
      return "00:00:00";
    }

    // 🕐 FORMATEO DE HORAS DE LUNES A VIERNES
    String horaAperturaLV = formatearHoraFlexible(
      _horariolunesviernes.text.isNotEmpty
          ? _horariolunesviernes.text
          : widget.horariolunesviernes,
    );

    String horaCierreLV = formatearHoraFlexible(
      _cierrelunesviernes.text.isNotEmpty
          ? _cierrelunesviernes.text
          : widget.cierrelunesviernes,
    );

    // 🕐 FORMATEO DE HORAS DEL SÁBADO
    String horaAperturaSab = formatearHoraFlexible(
      _horariosabado.text.isNotEmpty
          ? _horariosabado.text
          : widget.horariosabado,
    );

    String horaCierreSab = formatearHoraFlexible(
      _cierresabado.text.isNotEmpty
          ? _cierresabado.text
          : widget.cierresabado,
    );

    // 🕐 FORMATEO DE HORAS DEL DOMINGO (solo si abre)
    String? horaAperturaDom = _abreDomingo
        ? (_horariodomingo.text.isNotEmpty
            ? formatearHoraFlexible(_horariodomingo.text)
            : (widget.horariodomingo != null && widget.horariodomingo!.isNotEmpty
                ? formatearHoraFlexible(widget.horariodomingo!)
                : null))
        : null;

    String? horaCierreDom = _abreDomingo
        ? (_cierredomingo.text.isNotEmpty
            ? formatearHoraFlexible(_cierredomingo.text)
            : (widget.cierredomingo != null && widget.cierredomingo!.isNotEmpty
                ? formatearHoraFlexible(widget.cierredomingo!)
                : null))
        : null;
        
    String textoTarifa = _tarifa.text.replaceAll('.', '');
    double tarifaDecimal = double.parse(textoTarifa);
    // 🖨️ Verificación antes de enviar
    print("🕐 Lunes-Viernes: $horaAperturaLV → $horaCierreLV");
    print("🕐 Sábado: $horaAperturaSab → $horaCierreSab");
    print("🕐 Domingo: $horaAperturaDom → $horaCierreDom");

    final url = Uri.parse("http://localhost:5000/actualizarPaseador");

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id_paseador": widget.id_paseador,
        "nombre": _nombrePaseador.text,
        "apellido": _apellidoPaseador.text,
        "cedulaUsuario": _cedula.text,
        "imagen": _imagenBase64?.isNotEmpty == true ? _imagenBase64 : (widget.imagen ?? ""),
        "tarifa": tarifaDecimal.toStringAsFixed(2),
        "descripcion": _descripcion.text.isNotEmpty ? _descripcion.text : "",
        "experiencia": _experiencia.text,
        "direccion": _direccion.text,
        "telefono": _telefono.text,
        "horariolunesviernes": horaAperturaLV ?? "00:00:00",
        "cierrelunesviernes": horaCierreLV ?? "00:00:00",
        "horariosabado": horaAperturaSab ?? "00:00:00",
        "cierrehorasabado": horaCierreSab ?? "00:00:00",
        "horariodomingos": _abreDomingo ? horaAperturaDom : null,
        "cierredomingos": _abreDomingo ? horaCierreDom : null,
        "metodopago": _tipoPagoSeleccionado.isNotEmpty ? _tipoPagoSeleccionado.join(", ") : "",
        "certificado": _certificadoBytes != null ? base64Encode(_certificadoBytes!) : "",
      }),
    );

    print("🛰️ Código: ${response.statusCode}");
    print("📦 Respuesta: ${response.body}");

    if (response.statusCode == 200) {
      mostrarMensajeFlotante(
        context,
        "✅ Perfil de paseador editado correctamente",
        colorFondo: const Color.fromARGB(255, 243, 243, 243),
        colorTexto: const Color.fromARGB(255, 0, 0, 0),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PerfilPaseadorScreen(id_paseador: widget.id_paseador),
        ),
      );
    } else {
      mostrarMensajeFlotante(
        context,
        "❌ Error: No se pudo editar lel perfil de paseador",
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
        Positioned.fill(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ),
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
                    '¿Desea editar su veterinaria?',
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
                      ElevatedButton.icon(
                        onPressed: () {
                          overlayEntry?.remove();
                          actualizarVeterinaria(); // ✅ Se llama directo
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

  Overlay.of(context).insert(overlayEntry);
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
          // Fondo con imagen y blur
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/Tienda.jpeg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Row superior: menú y iconos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: SizedBox(
                            width: 24,
                            height: 24,
                            child: Image.asset('assets/Menu.png')),
                        onPressed: () {},
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {},
                            child: SizedBox(
                                width: 24,
                                height: 24,
                                child: Image.asset('assets/Perfil.png')),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {},
                            child: SizedBox(
                                width: 24,
                                height: 24,
                                child: Image.asset('assets/Calendr.png')),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {},
                            child: SizedBox(
                                width: 24,
                                height: 24,
                                child: Image.asset('assets/Campana.png')),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Título
                  const Center(
                    child: Text(
                      "Editar Tienda",
                      style: TextStyle(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Formulario
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
                                        backgroundImage: kIsWeb
                                        ? (_webImagen != null
                                            ? MemoryImage(_webImagen!)
                                            : (_imagenBase64 != null && _imagenBase64!.isNotEmpty
                                                ? MemoryImage(base64Decode(_imagenBase64!))
                                                : const AssetImage('assets/usuario.png') as ImageProvider))
                                        : (_imagen != null
                                            ? FileImage(_imagen!)
                                            : (_imagenBase64 != null && _imagenBase64!.isNotEmpty
                                                ? MemoryImage(base64Decode(_imagenBase64!))
                                                : const AssetImage('assets/usuario.png') as ImageProvider)),
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
                                  "Nombre del paseador", "assets/Nombre.png", _nombrePaseador, "Ej: Pet Paradise", soloLetras: true),
                              _campoTextoSimple(
                                "Apellido del paseador",
                                "assets/formato-de-texto.png",
                                _apellidoPaseador,
                                "Ej: Mendez",
                                soloLetras: true,  
                              ),
                              _campoTextoSimple("Cédula", "assets/cedula11.png", _cedula, "Ej: 1115574887", soloNumeros: true),
                          
                              _campoHoraApertura(context),
                              _campoHoraCierre(context),
                              _campoHoraAperturaSabado(context),
                              _campoHoraCierreSabado(context),
                              _switchDiaCerrado("¿Esta disponible los domingos?", _abreDomingo,
                                  (val) => setState(() => _abreDomingo = val)),
                              if (_abreDomingo) ...[
                                _campoHoraAperturaDomingo(context),
                                _campoHoraCierreDomingo(context),
                              ],
                              _campoTextoSimple("Teléfono", "assets/Telefono.png", _telefono, "Ej: 3001234567", soloNumeros: true,),
                              _campoTextoSimple(
                                  "Dirección", "assets/Ubicacion.png", _direccion, "Ej: Calle 123 #45-67", esDireccion: true,),

                              _campoTextoSimple(
                                "Experiencia",
                                "assets/sombrero.png",
                                _experiencia,
                                "Ej: 5 años de servicio",
                                esDireccion: true,
                              ),

                              _campoTextoSimple(
                                "Tarifa por hora",
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
                              _campoDescripcion("Descripción", "assets/Descripcion.png", _descripcion),

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

                  // Botones Cancelar / Guardar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: SizedBox(
                            width: 24,
                            height: 24,
                            child: Image.asset('assets/cancelar.png')),
                        label: const Text("Cancelar"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton.icon(
                        onPressed: () => mostrarConfirmacionRegistro(context),
                        icon: SizedBox(width: 24, height: 24, child: Image.asset('assets/Editar.png')),
                        label: const Text("Editar"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
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
    // Aquí puedes seguir agreg

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
      bool soloVer = false
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
            enabled: !soloVer, // 👈 Desactiva edición si soloVer = true
            readOnly: soloVer, // 👈 Evita que se abra teclado
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
            hintText: "Digite descripcion...",
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



  Widget _campoHoraApertura(BuildContext context) {
    return _campoHora(
      context,
      "Hora disponibilidad Lunes-Viernes",
      _horariolunesviernes,
      (picked) => setState(() =>
          _horariolunesviernes.text = picked.format(context)),
      "assets/Hora.png",
      "Seleccione la hora de inicio de su disponibilidad",
    );
  }

  Widget _campoHoraCierre(BuildContext context) {
    return _campoHora(
      context,
      "Hora de cierre Lunes-Viernes",
      _cierrelunesviernes,
      (picked) =>
          setState(() => _cierrelunesviernes.text = picked.format(context)),
      "assets/Hora.png",
      "Hora de finalización del servicio",
    );
  }

  Widget _campoHoraAperturaSabado(BuildContext context) {
    return _campoHora(
      context,
      "Hora disponibilidad sábado",
      _horariosabado,
      (picked) =>
          setState(() => _horariosabado.text = picked.format(context)),
      "assets/Hora.png",
      "Seleccione la hora de inicio de su disponibilidad",
    );
  }

  Widget _campoHoraCierreSabado(BuildContext context) {
    return _campoHora(
      context,
      "Hora cierre sábado",
      _cierresabado,
      (picked) =>
          setState(() => _cierresabado.text = picked.format(context)),
      "assets/Hora.png",
      "Hora de finalización del servicio",
    );
  }

  Widget _campoHoraAperturaDomingo(BuildContext context) {
    return _campoHora(
      context,
      "Hora disponibilidad Domingo",
      _horariodomingo,
      (picked) =>
          setState(() => _horariodomingo.text = picked.format(context)),
      "assets/Hora.png",
      "Seleccione la hora de inicio de su disponibilidad",
    );
  }

  Widget _campoHoraCierreDomingo(BuildContext context) {
    return _campoHora(
      context,
      "Hora cierre Domingo",
      _cierredomingo,
      (picked) =>
          setState(() => _cierredomingo.text = picked.format(context)),
      "assets/Hora.png",
      "Hora de finalización del servicio",
    );
  }


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

  Widget _switchDiaCerrado(String texto, bool valor, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(texto, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        Switch(
          value: valor,
          onChanged: onChanged,
          activeColor: Colors.green,
        ),
      ],
    );
  }

    Widget _campoHora(
      BuildContext context,
      String etiqueta,
      TextEditingController controller,
      Function(TimeOfDay) onTimeSelected,
      String iconoPath,
      String hintText,
    ) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            readOnly: true,
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
            onTap: () async {
              TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (picked != null) {
                onTimeSelected(picked);
              }
            },
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
            List<String> _seleccionTemporal = List.from(_tipoPagoSeleccionado);

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
                              value: _seleccionTemporal.contains(opcion),
                              title: Text(opcion),
                              onChanged: (bool? valor) {
                                setStateSB(() {
                                  if (valor == true) {
                                    _seleccionTemporal.add(opcion);
                                  } else {
                                    _seleccionTemporal.remove(opcion);
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
                      onPressed: () => Navigator.pop(context, _seleccionTemporal),
                      child: const Text("Aceptar"),
                    ),
                  ],
                );
              },
            );

            if (resultado != null) {
              setState(() {
                _tipoPagoSeleccionado = resultado;
                _metodopago.text = _tipoPagoSeleccionado.join(", "); // 🔥 sincroniza el texto
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
}
