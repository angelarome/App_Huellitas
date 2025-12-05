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

class AgregarPedidoScreen extends StatefulWidget {
  final int id_dueno;
  final int idtienda;
  final List<Map<String, dynamic>> carrito;

  const AgregarPedidoScreen({super.key, required this.id_dueno, required this.idtienda, required this.carrito});

  @override
  State<AgregarPedidoScreen> createState() => _AgregarPedidoScreenState();
}

class _AgregarPedidoScreenState extends State<AgregarPedidoScreen> {
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> carrito = [];
  final TextEditingController _telefono = TextEditingController();
  final TextEditingController _direccion = TextEditingController();

  late double precioUnitario;
  late TextEditingController _totalController;

  TextEditingController _fechaHoraController = TextEditingController();
  List<String> _tipoPagoSeleccionado = [];


 @override
  void initState() {
    super.initState();
    DateTime ahora = DateTime.now();

    // Formatear la fecha y hora
    String fechaHoraFormateada = DateFormat('yyyy-MM-dd HH:mm:ss').format(ahora);

    // Asignar al TextEditingController
    _fechaHoraController.text = fechaHoraFormateada;
    carrito = widget.carrito.map((producto) {
      producto['cantidadSeleccionada'] ??= 1;
      producto['cantidad_disponible'] ??= 10; // máximo por defecto si no viene
      return producto;
    }).toList();
    _totalController = TextEditingController();
    _actualizarTotal();
  }
  void _actualizarTotal() {
    double total = 0;
    for (var producto in carrito) {
      total += (producto["precio"] ?? 0) * (producto["cantidadSeleccionada"] ?? 1);
    }
    _totalController.text = NumberFormat("#,##0", "es_CO").format(total);
  }

  Future<void> registrarPedido() async {
      // Lista de campos a validar
    final camposFaltantes = <String>[];

    // Validar dirección
    if (_direccion.text.trim().isEmpty) {
      camposFaltantes.add("dirección");
    }

    // Validar método de pago
    if (_tipoPagoSeleccionado.isEmpty) {
      camposFaltantes.add("método de pago");
    }

    if (camposFaltantes.isNotEmpty) {
      final mensaje = "⚠️ Por favor completa: ${camposFaltantes.join(", ")}";
      mostrarMensajeFlotante(
        context,
        mensaje,
        colorFondo: Colors.white,
        colorTexto: Colors.redAccent,
      );
      return;
    }

    try {
      String totalText = _totalController.text.replaceAll(',', '').replaceAll('.', '');
      final total = double.tryParse(totalText) ?? 0.0;
      final fechaReserva = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.parse(_fechaHoraController.text));
      final url = Uri.parse("http://localhost:5000/registrarPedido");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id_dueno": widget.id_dueno,
          "id_tienda": widget.idtienda,
          "total": total,
          "metodopago": _tipoPagoSeleccionado.join(", "),
          "productos": carrito, 
          "fecha": fechaReserva, 
          "direccion": _direccion.text, 
          
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        mostrarMensajeFlotante(
          context,
          "✅ Pedido registrado correctamente",
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
          "❌ Error al registrar el pedido (${response.statusCode})",
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
                  "Realizar pedido",
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
                                Column(
                                  children: [
                                    _listaProductos(), // ✅ Llamada correcta
                                  ],
                                ),
                                const SizedBox(height: 5),

                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Fecha",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 5),

                                    TextField(
                                      controller: _fechaHoraController,
                                      readOnly: true,
                                      style: const TextStyle(color: Colors.black),
                                      decoration: InputDecoration(
                                        prefixIcon: Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Image.asset(
                                            "assets/Calendario1.png",
                                            width: 24,
                                            height: 24,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
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
                                
                                _campoTextoSimple(
                                  "Dirección",
                                  "assets/Ubicacion.png",
                                  _direccion,
                                  "ej: Sevilla Valle, cr 51 #56-90",
                                  esDireccion: true,
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
                                  registrarPedido();
                                },
                                icon: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Image.asset('assets/catalogo.png')),
                                label: const Text("Pedir"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(255, 57, 172, 31),
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
            hintStyle: TextStyle(color: const Color.fromARGB(255, 133, 129, 129)),
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

 Widget _listaProductos() {
  // 🔹 Si no hay productos, mostramos un mensaje
  if (carrito.isEmpty) {
    return Container(
      key: const ValueKey("cesta_vacia"),
      width: MediaQuery.of(context).size.width * 0.9,
      constraints: const BoxConstraints(minHeight: 150),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black26)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset("assets/catalogo.png", width: 60, height: 60),
          const SizedBox(height: 20),
          const Text(
            "No tienes productos en la cesta",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 🔹 Agrupamos productos por idproducto para que no se dupliquen
  final Map<String, Map<String, dynamic>> productosUnicos = {};

  for (var producto in carrito) {
    final id = producto['idproducto'].toString();
    if (productosUnicos.containsKey(id)) {
      productosUnicos[id]!['cantidadSeleccionada'] += producto['cantidadSeleccionada'] ?? 1;
    } else {
      producto['cantidadSeleccionada'] = producto['cantidadSeleccionada'] ?? 1;
      productosUnicos[id] = producto; // <-- aquí no usamos Map.from(), mantenemos la referencia
    }
  }

  // 🔹 Construimos las tarjetas de productos
  return Column(
    key: const ValueKey("cesta_con_productos"),
    children: productosUnicos.values.map<Widget>((producto) {
      final nombreOriginal = producto["nombre"] ?? "Sin nombre";
      final nombre = nombreOriginal.isNotEmpty
          ? nombreOriginal[0].toUpperCase() + nombreOriginal.substring(1).toLowerCase()
          : "Sin nombre";
      final descripcion = producto["descripcion"] ?? "Sin descripción";
      final disponibles = producto["cantidad_disponible"]?.toString() ?? "N/A";
      final int maxCantidad = producto["cantidad_disponible"] ?? 10;
      final precioNumero = producto["precio"] ?? 0;
      final precioFormateado = "\$${NumberFormat("#,##0", "es_CO").format(precioNumero)}";
      Uint8List? foto = producto["foto"];

      return StatefulBuilder(
        builder: (context, setState) {
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
                    // Imagen del producto
                    ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: foto != null
                          ? Image.memory(foto, width: 90, height: 90, fit: BoxFit.cover)
                          : Image.asset("assets/perfilshop.png", width: 90, height: 90, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 16),
                    // Información del producto
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(descripcion, style: const TextStyle(fontSize: 14)),
                          const SizedBox(height: 4),
                          Text("Disponibles: $disponibles", style: const TextStyle(fontSize: 14, color: Colors.black)),
                          Text(precioFormateado, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    // Selector de cantidad
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Botón -
                        InkWell(
                          onTap: () {
                            if (producto['cantidadSeleccionada'] > 1) {
                              setState(() {
                                producto['cantidadSeleccionada']--;
                              });
                              _actualizarTotal();
                            }
                          },
                          child: Container(
                            width: 35,
                            height: 35,
                            alignment: Alignment.center,
                            child: const Text("-", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        Container(width: 1, height: 22, color: const Color.fromARGB(255, 131, 123, 99)),
                        // Cantidad
                        Container(
                          width: 40,
                          alignment: Alignment.center,
                          child: Text("${producto['cantidadSeleccionada']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                        Container(width: 1, height: 22, color: const Color.fromARGB(255, 131, 123, 99)),
                        // Botón +
                        InkWell(
                          onTap: () {
                            if (producto['cantidadSeleccionada'] < maxCantidad) {
                              setState(() {
                                producto['cantidadSeleccionada']++;
                              });
                              _actualizarTotal();
                            }
                          },
                          child: Container(
                            width: 35,
                            height: 35,
                            alignment: Alignment.center,
                            child: const Text("+", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    }).toList(),
  );
}

}

