import 'package:flutter/material.dart';
import 'rol.dart';
import 'iniciarsesion.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'iniciarsesion.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'codigocontrasena.dart';


final TextEditingController correoController = TextEditingController();

class RecuperarCuentaPage extends StatefulWidget {
  const RecuperarCuentaPage({super.key});

  @override
  State<RecuperarCuentaPage> createState() => _RecuperarCuentaPageState();
}

class _RecuperarCuentaPageState extends State<RecuperarCuentaPage>{

  Future<void> recuperarCuenta() async {
    if (correoController.text.trim().isEmpty) {
      mostrarMensajeFlotante(
        context,
        "❌ Por favor ingresa tu correo",
        colorFondo: const Color.fromARGB(255, 250, 180, 180),
        colorTexto: Colors.black,
      );
      return;
    }
    
    mostrarLoading(context);
    final url = Uri.parse("http://localhost:5000/recuperarcontrasena");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "correo": correoController.text,
      }),
    );

    ocultarLoading(context);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final usuario = data["usuario"];
      final rol = usuario["rol"]; // si lo necesitas

      mostrarMensajeFlotante(
        context,
        "✅ Correo encontrado. Enviando código...",
        colorFondo: const Color.fromARGB(255, 203, 250, 203),
        colorTexto: Colors.black,
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecuperarCuentaCodigo(correo: correoController.text, rol: rol),
        ),
      );

    }
    else if (response.statusCode == 404) {
      mostrarMensajeFlotante(
        context,
        "❌ Correo no encontrado",
        colorFondo: const Color.fromARGB(255, 250, 180, 180),
        colorTexto: Colors.black,
      );
    }
    else {
      mostrarMensajeFlotante(
        context,
        "❌ Error inesperado en el servidor",
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
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/inicio.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: Container(color: Colors.black.withOpacity(0.2)),
                  ),
                  const Text(
                    "Recuperar contraseña",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(2, 2),
                          color: Colors.black,
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // LOGO
                  Image.asset(
                    "assets/Logo_Tienda_de_Accesorios_para_Mascotas_Alegre_Café_y_Rosa-removebg-preview.png",
                    width: 200,
                    height: 200,
                  ),
                  const SizedBox(height: 20),

                  const Text(
                            "Introduce tu correo para enviarte un\ncódigo de recuperación de contraseña",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              
                            ),
                          ),
                  const SizedBox(height: 20),
                  Form(
                    child: Container(
                      width: 350,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 170, 159, 159).withOpacity(0.6),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(255, 142, 131, 131).withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                  
                          _campoTexto(
                            "Correo electrónico",
                            Image.asset('assets/gmail.png'),
                            correoController,
                            tipo: 'correo',
                          ),
                          const SizedBox(height: 5),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // BOTÓN ENVIAR
                  SizedBox(
                    width: 150,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        recuperarCuenta();
                      },
                      icon: Image.asset(
                        'assets/llave.png',
                        width: 24,
                        height: 24,
                      ),
                      label: const Text(
                        "Enviar código",
                        style: TextStyle(
                          fontWeight: FontWeight.bold, // 🔹 hace la letra más gruesa
                          shadows: [                     // 🔹 agrega sombra al texto
                            Shadow(
                              offset: Offset(1, 1),     // posición de la sombra
                              blurRadius: 2,             // difuminado
                              color: Colors.black45,     // color de la sombra
                            ),
                          ],
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 6, // 🔹 sombra del botón
                        shadowColor: Colors.black45,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // TEXTOS INFERIORES
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Rol1Screen()),
                        );
                      },
                      child: Text(
                        "¿No tienes cuenta? Crear cuenta",
                        style: TextStyle(
                          color: Color.fromARGB(255, 251, 62, 45),
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
                  const SizedBox(height: 8),

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

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

  // 🔹 Campo de texto con validación y estilo visual
Widget _campoTexto(String label, Widget icono, TextEditingController controller, {String tipo = 'texto'}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
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

      TextFormField(
        controller: controller,

        // usar `tipo` para elegir teclado
        keyboardType: tipo == 'num'
            ? TextInputType.number
            : (tipo == 'correo' ? TextInputType.emailAddress : TextInputType.text),

        // inputFormatters por tipo (incluye filtro para correo)
        inputFormatters: [
          if (tipo == 'num') FilteringTextInputFormatter.digitsOnly,
          if (tipo == 'letras')
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
          if (tipo == 'correo')
            // permite letras, números, @ . _ - (ajusta si quieres más símbolos)
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._\-]')),
        ],

        // longitud según label (puedes adaptar a la lógica que prefieras)
        maxLength: (label.toLowerCase().contains("cédula") || label.toLowerCase().contains("cedula") || label.toLowerCase().contains("teléfono") || label.toLowerCase().contains("telefono")) ? 10 : null,

        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: "ej: romero@gmail.com",
          prefixIcon: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(width: 24, height: 24, child: icono),
          ),
          counterText: "",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),

        validator: (valor) {
          if (valor == null || valor.isEmpty) {
            return 'Por favor ingresa $label';
          }

          if (tipo == 'num' && !RegExp(r'^[0-9]+$').hasMatch(valor)) {
            return 'Solo se permiten números';
          }

          if (tipo == 'letras' && !RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(valor)) {
            return 'Solo se permiten letras';
          }

          if (tipo == 'correo' &&
              !RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$').hasMatch(valor)) {
            return 'Ingrese un correo válido';
          }

          if ((label.toLowerCase().contains("teléfono") || label.toLowerCase().contains("telefono")) && valor.length != 10) {
            return 'El número de teléfono debe tener exactamente 10 dígitos';
          }

          return null;
        },
      ),
    ],
  );
}

