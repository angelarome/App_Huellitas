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
import 'tiendas.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class MilesFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {

    final numericString = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final number = int.tryParse(numericString);
    if (number == null) return newValue;

    final formatter = NumberFormat('#,###');
    final newText = formatter.format(number);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class AgregarReservaScreen extends StatefulWidget {
  final int id_dueno;
  final int idtienda;
  final int idProducto;
  final Uint8List? foto;
  final String nombre;
  final String descripcion;
  final double precio;
  final int cantidad_disponible;

  const AgregarReservaScreen({super.key, required this.id_dueno, required this.idtienda, required this.idProducto, this.foto, required this.nombre, required this.descripcion, required this.precio, required this.cantidad_disponible});

  @override
  State<AgregarReservaScreen> createState() => _AgregarReservaScreenState();
}

class _AgregarReservaScreenState extends State<AgregarReservaScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _telefono = TextEditingController();
  final TextEditingController _direccion = TextEditingController();
  final TextEditingController _descripcion= TextEditingController();

  int cantidadSeleccionada = 1;
  late double precioUnitario;
  late TextEditingController _totalController;


  List<String> _tipoPagoSeleccionado = [];
  TextEditingController _fechaHoraController = TextEditingController();
  TextEditingController _fechaHoraVencimientoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    DateTime ahora = DateTime.now();

    // Formatear la fecha y hora
    String fechaHoraFormateada = DateFormat('yyyy-MM-dd HH:mm').format(ahora);

    // Asignar al TextEditingController
    _fechaHoraController.text = fechaHoraFormateada;
    _setFechaVencimiento();
    
    precioUnitario = widget.precio ?? 0;

    // Formatear con separador de miles y sin decimales
    final precioFormateado = NumberFormat("#,##0", "es_CO").format(precioUnitario);

    _totalController = TextEditingController(text: precioFormateado);
  }


  void _setFechaVencimiento() {
    final fechaActual = DateTime.now();
    final fechaVencimiento = fechaActual.add(const Duration(days: 1)); // sumar 1 día
    final fechaFormateada = 
        "${fechaVencimiento.year}-"
        "${fechaVencimiento.month.toString().padLeft(2,'0')}-"
        "${fechaVencimiento.day.toString().padLeft(2,'0')} "
        "${fechaVencimiento.hour.toString().padLeft(2,'0')}:"
        "${fechaVencimiento.minute.toString().padLeft(2,'0')}";

    _fechaHoraVencimientoController.text = fechaFormateada;
  }

  Future<void> registrarReserva() async {
    if (_tipoPagoSeleccionado.isEmpty) {
      mostrarMensajeFlotante(
        context,
        "❌ Por favor selecciona un método de pago",
        colorFondo: Colors.white,
        colorTexto: Colors.redAccent,
      );
      return; // Salir de la función si no hay pago seleccionado
    }
    try {
      String totalText = _totalController.text.replaceAll(',', '').replaceAll('.', '');
      final total = double.tryParse(totalText) ?? 0.0;
      final fechaReserva = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.parse(_fechaHoraController.text));
      final fechaVencimiento = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.parse(_fechaHoraVencimientoController.text));
      final url = Uri.parse("https://apphuellitas-production.up.railway.app/registrarReserva");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id_dueno": widget.id_dueno,
          "id_producto": widget.idProducto,
          "id_tienda": widget.idtienda,
          "cantidad": cantidadSeleccionada,
          "fecha_reserva": fechaReserva,
          "fecha_finalizado": fechaVencimiento,
          "total": total,
          "metodopago": _tipoPagoSeleccionado.join(", "),
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        mostrarMensajeFlotante(
          context,
          "✅ Reserva registrada correctamente",
          colorFondo: const Color.fromARGB(255, 186, 237, 150), // verde bonito
          colorTexto: const Color.fromARGB(255, 0, 0, 0),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TiendaScreen(id_dueno: widget.id_dueno, idtienda: widget.idtienda),
          ),
        );


      } else {
        mostrarMensajeFlotante(
          context,
          "❌ Error al registrar la reserva (${response.statusCode})",
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
                  "Realizar reserva",
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
                          Text(
                              "Producto",
                              style: TextStyle(
                                fontSize: 28,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                              ),
                            ),
                          
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                _tarjetaCatalogo(), // tu tarjeta
                                const SizedBox(height: 5),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Fecha de la reserva",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(255, 255, 255, 255),
                                      ),
                                    ),
                                    const SizedBox(height: 8), // separación entre el texto y el cajón
                                    TextField(
                                      controller: _fechaHoraController,
                                      readOnly: true,
                                      style: const TextStyle(color: Colors.black), // texto negro
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white, // fondo blanco
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Colors.grey),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Colors.grey),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Colors.blue),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Vencimiento de la reserva",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(255, 255, 255, 255),
                                      ),
                                    ),
                                    const SizedBox(height: 8), // separación entre el texto y el cajón
                                    TextField(
                                      controller: _fechaHoraVencimientoController,
                                      readOnly: true,
                                      style: const TextStyle(color: Colors.black), // texto negro
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white, // fondo blanco
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Colors.grey),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Colors.grey),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Colors.blue),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),
                                _campoSeleccionUnica(
                                  "Tipo de pago",
                                  "assets/Pago.png",
                                  ["Efectivo", "Tarjeta débito / crédito", "PSE", "Nequi", "Daviplata"],
                                ),
                                _campoTextoSimple(
                                  "Total a pagar",
                                  "assets/precio.png",
                                  _totalController,
                                  "Total",
                                  formatoMiles: true,
                                  readOnly: true,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

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
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(width: 20),
                              ElevatedButton.icon(
                                onPressed: () {
                                  registrarReserva();
                                },
                                icon: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Image.asset('assets/reserva.png')),
                                label: const Text("Reservar"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
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
            ],
          ),
        ),
      ),
    ],
  ),


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
      filtros.add(FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9áéíóúÁÉÍÓÚñÑ\s#\-\.,]')));
    } else if (formatoMiles) {
      // ✅ Formatear con puntos de miles automáticamente
      filtros.add(MilesFormatter());
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
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 234, 234, 234)),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: formatoMiles || soloNumeros ? TextInputType.number : TextInputType.text,
          inputFormatters: filtros,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: const Color.fromARGB(255, 242, 240, 240)),
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


  Widget _campoSeleccionUnica(String etiqueta, String iconoPath, List<String> opciones) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(etiqueta, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      const SizedBox(height: 4),
      GestureDetector(
        onTap: () async {
          String? seleccionada = _tipoPagoSeleccionado.isNotEmpty ? _tipoPagoSeleccionado.first : null;

          final resultado = await showDialog<String>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Center(
                  child: Text(
                    "Selecciona $etiqueta",
                    style: const TextStyle(
                      color: Color.fromARGB(255, 8, 8, 8),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                content: StatefulBuilder(
                  builder: (context, setStateSB) {
                    return SingleChildScrollView(
                      child: Column(
                        children: opciones.map((opcion) {
                          return RadioListTile<String>(
                            value: opcion,
                            groupValue: seleccionada,
                            title: Text(opcion),
                            activeColor: const Color.fromARGB(255, 46, 140, 202),
                            onChanged: (valor) {
                              setStateSB(() {
                                seleccionada = valor;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
                actionsAlignment: MainAxisAlignment.center,
                actions: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, null),
                    icon: SizedBox(width: 20, height: 20, child: Image.asset('assets/cancelar.png')),
                    label: const Text("Cancelar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, seleccionada),
                    icon: SizedBox(width: 20, height: 20, child: Image.asset('assets/Correcto.png')),
                    label: const Text("Aceptar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              );
            },
          );

          if (resultado != null) {
            setState(() {
              _tipoPagoSeleccionado = [resultado]; // solo un elemento
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
                  _tipoPagoSeleccionado.isEmpty ? "Seleccione el tipo de pago" : _tipoPagoSeleccionado.first,
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

  Widget _tarjetaCatalogo() {
    final nombreOriginal = widget.nombre ?? "Sin nombre";
    final nombre = nombreOriginal.isNotEmpty
        ? nombreOriginal[0].toUpperCase() + nombreOriginal.substring(1).toLowerCase()
        : "Sin nombre";
    final descripcion = widget.descripcion ?? "Sin descripción";
    final disponibles = widget.cantidad_disponible?.toString() ?? "N/A";
    final int maxCantidad = widget.cantidad_disponible ?? 0;

    final precioNumero = widget.precio ?? 0;
    final precioFormateado = "\$${NumberFormat("#,##0", "es_CO").format(precioNumero)}";

    Uint8List? foto = widget.foto;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 246, 245, 245),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black26)],
        border: Border.all(color: const Color.fromARGB(255, 131, 123, 99), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: foto != null
                    ? Image.memory(foto, width: 90, height: 90, fit: BoxFit.cover)
                    : Image.asset("assets/perfilshop.png",
                        width: 90, height: 90, fit: BoxFit.cover),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(descripcion, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 4),
                    Text("Disponibles: $disponibles",
                        style: const TextStyle(fontSize: 14, color: Colors.black)),
                    Text(
                      precioFormateado,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (cantidadSeleccionada > 1) cantidadSeleccionada--; // restar
                        _totalController.text = NumberFormat("#,##0", "es_CO")
                            .format(cantidadSeleccionada * precioUnitario);
                      });
                    },
                    child: Container(
                      width: 35,
                      alignment: Alignment.center,
                      child: const Text("-", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Container(width: 1, height: 22, color: const Color.fromARGB(255, 131, 123, 99)),
                  // Mostrar cantidad
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Text("$cantidadSeleccionada", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  Container(width: 1, height: 22, color: const Color.fromARGB(255, 131, 123, 99)),
                  // Botón sumar
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (cantidadSeleccionada < maxCantidad) cantidadSeleccionada++; // sumar
                        _totalController.text = NumberFormat("#,##0", "es_CO")
                            .format(cantidadSeleccionada * precioUnitario);
                      });
                    },
                    child: Container(
                      width: 35,
                      alignment: Alignment.center,
                      child: const Text("+", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void guardarCantidad() {
    cantidadSeleccionada = cantidadSeleccionada;
  }


}