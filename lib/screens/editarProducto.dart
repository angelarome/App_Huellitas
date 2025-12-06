import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'mitienda2.dart';

class MilesFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern('es_CO');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // eliminamos puntos previos para procesar solo dígitos
    String digitsOnly = newValue.text.replaceAll('.', '').replaceAll(',', '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // evitar que se rompa con entradas no numéricas
    if (!RegExp(r'^\d+$').hasMatch(digitsOnly)) {
      return oldValue;
    }

    try {
      final int value = int.parse(digitsOnly);
      final String newText = _formatter.format(value);

      // colocamos el cursor al final (simple y seguro)
      return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    } catch (_) {
      return oldValue;
    }
  }
}

class ProductoMascotaEditarScreen extends StatefulWidget {
  final int idtienda;
  final int idproducto;
  final String nombre;
  final double precio;
  final int cantidad;
  final String imagen;
  final String? descripcion;

  const ProductoMascotaEditarScreen({super.key, required this.idtienda,  required this.idproducto, required this.nombre, required this.precio, required this.cantidad, required this.imagen, required this.descripcion});

  @override
  State<ProductoMascotaEditarScreen> createState() => _ProductoMascotaEditarScreen();
}

class _ProductoMascotaEditarScreen extends State<ProductoMascotaEditarScreen> {
  final _formKey = GlobalKey<FormState>();

  // 🧩 Variables para imagen
  File? _imagen; // para móvil
  Uint8List? _webImagen; // para web
  String? _imagenBase64; // imagen lista para enviar al backend

  // 🧍‍♀️ Controladores de texto
  late TextEditingController descripcionController;
  late TextEditingController nombreController;
  late TextEditingController tarifaController;
  late TextEditingController cantidadController;

  @override
  void initState() {
    super.initState();
    nombreController = TextEditingController(text: widget.nombre);
    descripcionController = TextEditingController(text: widget.descripcion);
    cantidadController = TextEditingController(text: widget.cantidad.toString());
    final tarifaNumero = double.tryParse(widget.precio.toString().replaceAll(',', '')) ?? 0;
    final tarifaFormateada = NumberFormat("#,##0", "es_CO").format(tarifaNumero);
    _imagenBase64 = widget.imagen;
    tarifaController = TextEditingController(text: tarifaFormateada);
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
        mostrarMensajeFlotante(
          context,
          "❌ Error inesperado: ${e.toString()}",
          colorFondo: Colors.white,
          colorTexto: Colors.redAccent,
        );
      }
    }
  }


  // ✅ Función principal para actualizar producto
  Future<void> actualizarProducto() async {
    List<String> camposFaltantes = [];

    // Nombre del producto
    if (nombreController.text.trim().isEmpty) {
      camposFaltantes.add("Nombre del producto");
    }

    // Tarifa
    if (tarifaController.text.trim().isEmpty) {
      camposFaltantes.add("Precio");
    }

    // Cantidad
    if (cantidadController.text.trim().isEmpty) {
      camposFaltantes.add("Cantidad disponible");
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
      String textoTarifa = tarifaController.text.replaceAll('.', '');
      double tarifaDecimal = double.parse(textoTarifa);

      final url = Uri.parse("https://apphuellitas-production.up.railway.app/actualizarProducto");

      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "idproducto": widget.idproducto,
          "tienda_id": widget.idtienda,
          "nombre": nombreController.text,
          "precio": tarifaDecimal,
          "cantidad": cantidadController.text,
          "descripcion": descripcionController.text.trim().isEmpty ? "" : descripcionController.text.trim(),
          "imagen":_imagenBase64 != null && _imagenBase64!.isNotEmpty
              ? _imagenBase64
              : widget.imagen,
        }),
      );

      if (response.statusCode == 200) {
        mostrarMensajeFlotante(
          context,
          "✅ Producto editada correctamente",
          colorFondo: const Color.fromARGB(255, 243, 243, 243),
          colorTexto: const Color.fromARGB(255, 0, 0, 0),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PerfilTiendaScreen(idtienda: widget.idtienda),
          ),
        );
      } else {
        mostrarMensajeFlotante(
          context,
          "❌ Error: No se pudo editar el producto",
          colorFondo: Colors.white,
          colorTexto: Colors.redAccent,
        );
      }
    }

  

  void mostrarConfirmacionRegistro(BuildContext context, VoidCallback registrarProducto) {
  OverlayEntry? overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => Stack(
      children: [
        // 🔹 Fondo semitransparente
        Positioned.fill(
          child: GestureDetector(
            onTap: () {}, // Evita que se cierre al tocar fuera
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ),
          ),
        ),

        // 🔹 Cuadro del mensaje
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
                    '¿Deseas registrar este producto?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 25),

                  // 🔹 Botones
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // ❌ Botón "No"
                      ElevatedButton.icon(
                        onPressed: () {
                          overlayEntry?.remove();
                        },
                        icon: SizedBox(
                          width: 24,
                          height: 24,
                          child: Image.asset('assets/cancelar.png'),
                        ),
                        label: const Text(
                          'No',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 202, 65, 65),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      // ✅ Botón "Sí"
                      ElevatedButton.icon(
                        onPressed: () {
                          overlayEntry?.remove();
                          registrarProducto(); // 👉 Llama a la función pasada
                        },
                        icon: SizedBox(
                          width: 24,
                          height: 24,
                          child: Image.asset('assets/Correcto.png'),
                        ),
                        label: const Text(
                          'Sí',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

  // 👇 Inserta el overlay
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
        child: Image.asset('assets/inteligent.png', width: 36, height: 36), // Icono de la IA , fit: BoxFit.contain
      ),

      body: Stack(
        children: [
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
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: SizedBox(width: 24,height: 24, child: Image.asset('assets/Menu.png'),
                        ),
                        onPressed: () {},
                      ),
                      Row(
                        children: [
                          SizedBox(width: 24,height: 24, child: Image.asset('assets/Perfil.png'),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(width: 24,height: 24, child: Image.asset('assets/Calendr.png'),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(width: 24,height: 24, child: Image.asset('assets/Campana.png'),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const Center(
                    child: Text(
                      "Producto",
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
                        color: Colors.blue[700],
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black26)],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // 👇 Bloque de la imagen circular con cámara
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
                                      onTap: _seleccionarImagen, // 👈 También aquí
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

                            // 👇 Campos del formulario
                            _campoTextoConEtiqueta(
                              "Nombre",
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Image.asset('assets/productonombre.png'),
                                ),
                              ),
                              nombreController, "Digite nombre del producto", tipo:TextInputType.text,
                            ),
                            _campoTextoConEtiqueta(
                              "Precio",
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Image.asset('assets/precio.png'),
                                ),
                              ),
                              tarifaController, "Digite el precio del producto",
                              tipo: TextInputType.number,
                              formatoMiles: true,
                            ),
                            _campoTextoConEtiqueta(
                              "Cantidad disponible",
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Image.asset('assets/cantidadp.png'),
                                ),
                              ),
                              cantidadController, "Digite la cantidad disponible",
                              tipo: TextInputType.number,
                            ),
                            _campoDescripcion("Descripción", "assets/descripcion.png", descripcionController),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PerfilTiendaScreen(idtienda: widget.idtienda),
                            ),
                          );
                        },
                        icon: SizedBox(width: 24,height: 24, child: Image.asset('assets/cancelar.png'), // icono de eliminar
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
                      onPressed: () {
                          mostrarConfirmacionRegistro(context, actualizarProducto); // 👈 Muestra el mensaje en lugar de registrar directo
                        },
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
              ],
            ),
          ),
        ),
      ],
    ),
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
        decoration: InputDecoration(
          hintText: "Descripcion del producto",
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

  Widget _campoTextoConEtiqueta(
    String etiqueta,
    dynamic icono,
    TextEditingController controller,
    String hintText, {
    TextInputType tipo = TextInputType.text,
    bool formatoMiles = false,
  }) {
    final Widget iconoWidget = icono is IconData ? Icon(icono) : icono;

    // creamos la lista final de formatters
    final List<TextInputFormatter> formatters = <TextInputFormatter>[];

    // si es para texto (nombre): permitir solo letras y espacios
    if (tipo == TextInputType.text) {
      formatters.add(
        FilteringTextInputFormatter.allow(
          RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚüÜñÑ\s]'),
        ),
      );
    }

    // si es numérico o queremos formato de miles, al menos permitir dígitos
    if (tipo == TextInputType.number || formatoMiles) {
      formatters.add(FilteringTextInputFormatter.digitsOnly);
    }

    // si pedimos formato de miles, agregamos nuestro formateador personalizado
    if (formatoMiles) {
      formatters.add(MilesFormatter());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: tipo,
          inputFormatters: formatters, // aquí aplicamos todos los formatters juntos
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[800]),
            prefixIcon: iconoWidget,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
  String? valorSeleccionado;

  Widget _dropdownConEtiqueta(
    String etiqueta,
    String? valorActual,
    List<String> opciones,
    String hintText,
    Function(String?) onChanged,
    String? Function(String?)? getIconPath,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Theme(
          data: Theme.of(context).copyWith(
            canvasColor: Colors.white, // ✅ Fondo blanco del menú desplegable
          ),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey[800]),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: Image.asset(
                    getIconPath != null
                        ? getIconPath(valorActual ?? "") ?? 'assets/Especie.png'
                        : 'assets/Especie.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            value: valorActual,
            items: opciones.map((opcion) {
              return DropdownMenuItem(
                value: opcion,
                child: Text(
                  opcion,
                  style: const TextStyle(
                    color: Colors.black, // ✅ Letras negras
                    fontSize: 16,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

