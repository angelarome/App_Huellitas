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
import 'documentos.dart';


class AgregarDocumentoScreen extends StatefulWidget {
  final int id;
  const AgregarDocumentoScreen({super.key, required this.id});

  @override
  State<AgregarDocumentoScreen> createState() => _AgregarDocumentoScreenState();
}

class _AgregarDocumentoScreenState extends State<AgregarDocumentoScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreDocumento = TextEditingController();

  Uint8List? _certificadoBytes;
  String? _rutaCertificado;


  Future<void> registrarDocumento() async {
    
    if (_nombreDocumento.text.isEmpty || 
    (_certificadoBytes == null && (_rutaCertificado == null || _rutaCertificado!.isEmpty))) {
      mostrarMensajeFlotante(
        context,
        "⚠️ Por favor complete todos los campos obligatorios.",
        colorFondo: Colors.white,
        colorTexto: Colors.redAccent,
      );
      return;
    }

    try {
      // 🌐 URL del backend
      final url = Uri.parse("http://localhost:5000/registrarDocumento");
      
      // 🧠 Datos a enviar
      final body = {
        "id_mascota": widget.id,
        "nombre_documento": _nombreDocumento.text,
        "certificado": _certificadoBytes != null ? base64Encode(_certificadoBytes!) : "",
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

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AgregarDocumentosScreen(id: widget.id),
          ),
        );


      } else {
        mostrarMensajeFlotante(
          context,
          "❌ Error al registrar el documento (${response.statusCode})",
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
                      '¿Deseas guardar este documento?',
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
                            registrarDocumento(); // 👉 Llama a la función que hace el registro
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
              image: AssetImage("assets/fondodocumentos.jpg"),
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
                    "Mi documento",
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

                            _campoTextoSimple(
                              "Nombre del documento",
                              "assets/documentos.png",
                              _nombreDocumento,
                              "Ej: Carnet de vacunas",
                              soloLetras: true,
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
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AgregarDocumentosScreen(id: widget.id),
                          ),
                        );
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

}
