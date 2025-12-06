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

class Editartienda extends StatefulWidget {
  final int idtienda;
  final String imagen;
  final String cedulaUsuario;
  final String nombreTienda;
  final String? descripcion;
  final String direccion;
  final String telefono;
  final String domicilio; // "Sí" o "No"
  final String horariolunesviernes;
  final String cierrelunesviernes;
  final String horariosabado;
  final String cierresabado;
  final String? horariodomingo;
  final String? cierredomingo;
  final String metodopago; // 👈 ahora lista (si viene algo como ["Efectivo", "Nequi"])
  final String departamento;
  final String ciudad; 

  const Editartienda({
    super.key,
    required this.idtienda,
    required this.imagen,
    required this.cedulaUsuario,
    required this.nombreTienda,
    required this.descripcion,
    required this.direccion,
    required this.telefono,
    required this.domicilio,
    required this.horariolunesviernes,
    required this.cierrelunesviernes,
    required this.horariosabado,
    required this.cierresabado,
    required this.horariodomingo,
    required this.cierredomingo,
    required this.metodopago,
    required this.departamento,
    required this.ciudad,
  });

  @override
  State<Editartienda> createState() => _EditartiendaState();
}

class _EditartiendaState extends State<Editartienda> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nombreTienda;
  late TextEditingController _cedula;
  late TextEditingController _telefono;
  late TextEditingController _direccion;
  late TextEditingController _descripcion;
  late TextEditingController _horariolunesviernes;
  late TextEditingController _cierrelunesviernes;
  late TextEditingController _horariosabado;
  late TextEditingController _cierresabado;
  late TextEditingController _horariodomingo;
  late TextEditingController _cierredomingo;
  late TextEditingController _metodopago;

  bool _abreDomingo = false;
  String? _domicilioSeleccionado; // "Sí" o "No"
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
  @override
  void initState() {
    super.initState();

    _nombreTienda = TextEditingController(text: widget.nombreTienda);
    _cedula = TextEditingController(text: widget.cedulaUsuario);
    _descripcion = TextEditingController(text: widget.descripcion ?? "");
    _direccion = TextEditingController(text: widget.direccion);
    _telefono = TextEditingController(text: widget.telefono);
    _horariolunesviernes = TextEditingController(text: widget.horariolunesviernes);
    _cierrelunesviernes = TextEditingController(text: widget.cierrelunesviernes);
    _horariosabado = TextEditingController(text: widget.horariosabado);
    _cierresabado = TextEditingController(text: widget.cierresabado);
    _horariodomingo = TextEditingController(text: widget.horariodomingo ?? "");
    _cierredomingo = TextEditingController(text: widget.cierredomingo ?? "");
    _metodopago = TextEditingController(text: widget.metodopago ?? ""); // ✅


    _domicilioSeleccionado = widget.domicilio;
    departamentoSeleccionado = widget.departamento;
    ciudadSeleccionada = widget.ciudad;

    _abreDomingo = widget.horariodomingo != null && widget.horariodomingo!.isNotEmpty;

    // ✅ Tipos de pago
    _tipoPagoSeleccionado = [];
    if (widget.metodopago != null && widget.metodopago!.isNotEmpty) {
      _tipoPagoSeleccionado =
          widget.metodopago!.split(",").map((e) => e.trim()).toList();
    }

    _imagenBase64 = widget.imagen;
  }

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


  Future<void> actualizarTienda() async {
    List<String> camposFaltantes = [];

    // Nombre
    if (_nombreTienda.text.trim().isEmpty) {
      camposFaltantes.add("Nombre de la tienda");
    }

    // Cédula
    if (_cedula.text.trim().isEmpty) {
      camposFaltantes.add("Cédula");
    }

    // Dirección
    if (_direccion.text.trim().isEmpty) {
      camposFaltantes.add("Dirección");
    }

    // Teléfono
    if (_telefono.text.trim().isEmpty) {
      camposFaltantes.add("Teléfono");
    }

    // Domicilio
    if (_domicilioSeleccionado == null ||
        _domicilioSeleccionado!.trim().isEmpty) {
      camposFaltantes.add("Domicilio");
    }

    if (departamentoSeleccionado == null ||
        departamentoSeleccionado!.trim().isEmpty) {
      camposFaltantes.add("Departamento");
    }

    if (ciudadSeleccionada == null ||
        ciudadSeleccionada!.trim().isEmpty) {
      camposFaltantes.add("Ciudad");
    }

    // Horarios lunes a viernes
    if (_horariolunesviernes.text.trim().isEmpty) {
      camposFaltantes.add("Horario Lunes-Viernes (Apertura)");
    }
    if (_cierrelunesviernes.text.trim().isEmpty) {
      camposFaltantes.add("Horario Lunes-Viernes (Cierre)");
    }

    // Horarios sábado
    if (_horariosabado.text.trim().isEmpty) {
      camposFaltantes.add("Horario Sábado (Apertura)");
    }
    if (_cierresabado.text.trim().isEmpty) {
      camposFaltantes.add("Horario Sábado (Cierre)");
    }

    // Horarios domingo (solo si abre)
    if (_abreDomingo && _horariodomingo.text.trim().isEmpty) {
      camposFaltantes.add("Horario Domingo (Apertura)");
    }
    if (_abreDomingo && _cierredomingo.text.trim().isEmpty) {
      camposFaltantes.add("Horario Domingo (Cierre)");
    }

    // Tipo de pago
    if (_tipoPagoSeleccionado.isEmpty) {
      camposFaltantes.add("Tipo de pago");
    }

    // Imagen
    if (_imagenBase64 == null || _imagenBase64!.isEmpty) {
      camposFaltantes.add("Imagen de la tienda");
    }

    // Mostrar mensaje si faltan campos
    if (camposFaltantes.isNotEmpty) {
      mostrarMensajeFlotante(
        context,
        "⚠️ Faltan campos: ${camposFaltantes.join(', ')}",
        colorFondo: Colors.white,
        colorTexto: Colors.redAccent,
      );
      return;
    }

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

    mostrarLoading(context);
    final url = Uri.parse("https://apphuellitas-production.up.railway.app/actualizarTienda");

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id": widget.idtienda,
        "cedulaUsuario": widget.cedulaUsuario,
        "imagen": _imagenBase64 != null && _imagenBase64!.isNotEmpty
            ? _imagenBase64
            : widget.imagen,
        "nombre_negocio": _nombreTienda.text,
        "descripcion": _descripcion.text.isNotEmpty ? _descripcion.text : "",
        "direccion": _direccion.text,
        "telefono": _telefono.text,
        "domicilio": _domicilioSeleccionado ?? "",
        "horariolunesviernes": horaAperturaLV,
        "cierrelunesviernes": horaCierreLV,
        "horariosabado": horaAperturaSab,
        "cierrehorasabado": horaCierreSab,
        "horariodomingos": _abreDomingo ? horaAperturaDom : null,
        "cierredomingos": _abreDomingo ? horaCierreDom : null,
        "metodopago": _tipoPagoSeleccionado.join(", "),
        "departamento": departamentoSeleccionado ?? "",
        "ciudad": ciudadSeleccionada ?? "",
      }),
    );

    ocultarLoading(context);
    if (response.statusCode == 200) {
      mostrarMensajeFlotante(
        context,
        "✅ Tienda editada correctamente",
        colorFondo: const Color.fromARGB(255, 243, 243, 243),
        colorTexto: const Color.fromARGB(255, 0, 0, 0),
      );

      final data = jsonDecode(response.body);
      final tienda = data["mitienda"];
      final cedula = tienda["cedulaUsuario"];

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PerfilTiendaScreen(idtienda: widget.idtienda),
        ),
      );
    } else {
      mostrarMensajeFlotante(
        context,
        "❌ Error: No se pudo editar la tienda",
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
                    '¿Desea editar su tienda?',
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
                          actualizarTienda(); // ✅ Se llama directo
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
                image: AssetImage("assets/descarga.jpeg"),
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
                                  "Nombre de la tienda", "assets/Nombre.png", _nombreTienda, "Ej: Pet Paradise", tipo: "nombre"),
                              _campoTextoSimple(
                                  "Cedula", "assets/cedula11.png", _cedula, "Ej: 1115574887", tipo: "telefono"),    
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
                              _campoTextoSimple("Teléfono", "assets/Telefono.png", _telefono, "Ej: 3001234567", tipo: "telefono"),

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
                                  "Dirección", "assets/Ubicacion.png", _direccion, "Ej: Calle 123 #45-67", tipo: "direccion"),

                              _dropdownConEtiqueta(
                                "Domicilio",
                                _icono("assets/domicilio.png"),
                                ["Si", "No"],
                                "Seleccione si tiene domicilio",
                                _domicilioSeleccionado,
                                (val) => setState(() => _domicilioSeleccionado = val),
                              ),

                              _campoMultiSeleccion(
                                "Tipo de pago",
                                "assets/Pago.png",
                                ["Efectivo", "Tarjeta débito / crédito", "PSE", "Nequi", "Daviplata"],
                              ),
                              _campoDescripcion("Descripción", "assets/Descripcion.png", _descripcion),
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
    String tipo = "texto", // "nombre", "telefono", "direccion"
  }) {
    TextInputType teclado = TextInputType.text;
    List<TextInputFormatter> inputFormatters = [];

    // Configuración según tipo
    switch (tipo) {
      case "nombre":
        // Solo letras y espacios
        inputFormatters = [
          FilteringTextInputFormatter.allow(RegExp(r"[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]")),
        ];
        teclado = TextInputType.name;
        break;
      case "telefono":
        // Solo números
        inputFormatters = [
          FilteringTextInputFormatter.digitsOnly,
        ];
        teclado = TextInputType.phone;
        break;
      case "direccion":
        // Letras, números, espacios y algunos símbolos como # , .
        inputFormatters = [
          FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z0-9\s\#\.,\-]"))
        ];
        teclado = TextInputType.streetAddress;
        break;
      default:
        inputFormatters = [];
        teclado = TextInputType.text;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: teclado,
          inputFormatters: inputFormatters,
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
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
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
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(r"[a-zA-Z0-9 áéíóúÁÉÍÓÚñÑ.,()\-_/º°!?\s]"),
            ),
          ],
          decoration: InputDecoration(
            hintText: "Ej: Ofrecemos comida, juguetes, camas y accesorios de calidad.",
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
      "Hora de apertura Lunes-Viernes",
      _horariolunesviernes,
      (picked) => setState(() =>
          _horariolunesviernes.text = picked.format(context)),
      "assets/Hora.png",
      "Seleccione la hora de apertura",
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
      "Seleccione la hora de cierre",
    );
  }

  Widget _campoHoraAperturaSabado(BuildContext context) {
    return _campoHora(
      context,
      "Hora apertura sábado",
      _horariosabado,
      (picked) =>
          setState(() => _horariosabado.text = picked.format(context)),
      "assets/Hora.png",
      "Seleccione la hora de apertura",
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
      "Seleccione la hora de cierre",
    );
  }

  Widget _campoHoraAperturaDomingo(BuildContext context) {
    return _campoHora(
      context,
      "Hora apertura Domingo",
      _horariodomingo,
      (picked) =>
          setState(() => _horariodomingo.text = picked.format(context)),
      "assets/Hora.png",
      "Seleccione la hora de apertura",
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
      "Seleccione la hora de cierre",
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
            builder: (context, child) {
              return Theme(
                data: ThemeData(
                  useMaterial3: true,
                  colorScheme: ColorScheme.light(
                    primary: Color(0xFF3A97F5), 
                    onPrimary: Colors.white,     // Texto blanco en selección
                    surface: Colors.white,       // Fondo blanco del reloj
                    onSurface: Colors.black87,   // Texto normal
                  ),
                  timePickerTheme: TimePickerThemeData(

                    dialHandColor: Color(0xFF3A97F5),    // Manecilla celeste
                    dialTextColor: Colors.black,         // Números negros
                  ),
                ),
                child: child!,
              );
            },
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
