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
  final String correo;
  const RecuperarCuentaPage({super.key, required this.correo});

  @override
  State<RecuperarCuentaPage> createState() => _RecuperarCuentaPageState();
}

class _RecuperarCuentaPageState extends State<RecuperarCuentaPage>{
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmarController = TextEditingController();

  bool _ocultarPassword = true;
  bool _ocultarConfirmar = true;
  
  Future<void> recuperarCuenta() async {
    final url = Uri.parse("http://localhost:5000/recuperarcontrasena");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "correo": correoController.text,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final usuario = data["usuario"];
      final rol = usuario["rol"]; // si lo necesitas

      mostrarMensajeFlotante(
        context,
        "Correo encontrado. Enviando código...",
        colorFondo: const Color.fromARGB(255, 214, 255, 214),
        colorTexto: Colors.black,
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecuperarCuentaCodigo(correo: correoController.text),
        ),
      );

    }
    else if (response.statusCode == 404) {
      mostrarMensajeFlotante(
        context,
        "❌ Correo no encontrado",
        colorFondo: const Color.fromARGB(255, 243, 243, 243),
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
                        color: const Color.fromARGB(255, 251, 81, 81).withOpacity(0.95),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(255, 189, 27, 27).withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                  
                          _campoPassword(
                            "Contraseña",
                            controller: passwordController,
                            ocultar: _ocultarPassword,
                            onToggle: () {
                              setState(() => _ocultarPassword = !_ocultarPassword);
                            },
                            icono: Image.asset('assets/candado.png'),
                          ),
                          const SizedBox(height: 10),
                          _campoPassword(
                            "Confirmar contraseña",
                            controller: confirmarController, 
                            ocultar: _ocultarConfirmar,
                            onToggle: () {
                              setState(() => _ocultarConfirmar = !_ocultarConfirmar);
                            },
                            icono: Image.asset('assets/candado.png'),
                          ),

                          const SizedBox(height: 25),
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
                        'assets/correo.png',
                        width: 24,
                        height: 24,
                      ),
                      label: const Text(
                        "Enviar enlace",
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



