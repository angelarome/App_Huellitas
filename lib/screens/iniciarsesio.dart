import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'iniciarsesion.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '1pantalla.dart';
import 'rol.dart';
import 'veterinaria2.dart';
import 'mitienda2.dart';
import 'mipaseador2.dart';
import 'recuperarcontrasena.dart';

final TextEditingController correoController = TextEditingController();
final TextEditingController passwordController = TextEditingController();


class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}


class _LoginScreenState extends State<LoginScreen> {
  bool _ocultarPassword = true;

  Future<void> iniciarSesion() async {
    final url = Uri.parse("http://localhost:5000/login");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "correo": correoController.text,
        "contrasena": passwordController.text,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final usuario = data["usuario"];
      final detalles = data["detalles"];
      final rol = usuario["rol"];

      if (rol == "dueno") {
        final id = detalles["id_dueno"];
        final cedula = detalles["cedula"];
        final nombre = detalles["nombre"];
        final apellido = detalles["apellido"];
        final telefono = detalles["telefono"];
        final direccion = detalles["direccion"];
        final foto = detalles["foto_perfil"];

        final Uint8List bytes = base64Decode(foto);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Pantalla1(
              id: id,
              cedula: cedula,
              nombreUsuario: nombre,
              apellidoUsuario: apellido,
              telefono: telefono,
              direccion: direccion,
              fotoPerfil: bytes,
            ),
          ),
        );
      } 
      else if (rol == "veterinaria") {
        final id = detalles["id_veterinaria"];

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PerfilVeterinariaScreen(
              id_veterinaria: id,
            ),
          ),
        );
      }

      else if (rol == "tienda") {
        final idtienda = detalles["idtienda"];

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PerfilTiendaScreen(
              idtienda: idtienda,
            ),
          ),
        );
      }

      else if (rol == "paseador") {
        final id_paseador = detalles["id_paseador"];

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PerfilPaseadorScreen(
              id_paseador: id_paseador,
            ),
          ),
        );
      }

      } else if (response.statusCode == 404) {
        mostrarMensajeFlotante(
          context,
            "⚠️ Correo no encontrado",
            colorFondo: const Color.fromARGB(255, 243, 243, 243),
            colorTexto: const Color.fromARGB(255, 0, 0, 0),
          );
    } else {
      mostrarMensajeFlotante(
          context,
          "❌ Usuario o contraseña incorrectos",
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
                  // Desenfoque suave del fondo
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: Container(color: Colors.black.withOpacity(0.2)),
                  ),

                  const SizedBox(height: 20), 
                  const Text(
                    "Iniciar sesión",
                  style: TextStyle(
                    fontSize: 50,
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
                  const SizedBox(height: 5),

                  // Logo grande
                  Image.asset(
                    "assets/Logo_Tienda_de_Accesorios_para_Mascotas_Alegre_Café_y_Rosa-removebg-preview.png",
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 10),

                  // Contenedor del formulario
                  Container(
                    width: 320,
                    padding: const EdgeInsets.all(20),
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
                        _campoTexto("Correo electrónico", Image.asset('assets/gmail.png'), correoController, tipo: 'correo'),        // Campo de Correo
                        const SizedBox(height: 15),               // Espacio entre campos
                        _campoPassword(
                          "Contraseña",
                          controller: passwordController,
                          ocultar: _ocultarPassword,
                          onToggle: () => setState(() => _ocultarPassword = !_ocultarPassword),
                          icono: Image.asset('assets/candado.png'),
                        ),
                      ],
                    ),
                  ),

                  // Botón
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: iniciarSesion,
                    icon: const Icon(Icons.login, color: Colors.white, size: 30,),
                    label: const Text(
                      "Iniciar sesión",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: Offset(1.5, 1.5),
                            color: Colors.black,
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00AEEF),
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 6,
                    ),
                  ),
                  const SizedBox(height: 5),

                  MouseRegion(
                    cursor: SystemMouseCursors.click, 
                    child: GestureDetector(
                      onTap: () {
                       Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RecuperarCuentaPage()),
                        );
                      },
                      child: const Text(
                        "¿Olvidaste tu contraseña?",
                        style: TextStyle(
                          color: Color(0xFF00AEEF),
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
                  const SizedBox(height: 5),
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

                ],
              ),
            ),
          ),
        ),
      ),
    );
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
          hintText: "Ingrese su $label",
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


  Widget _campoPassword(String label, {
    required bool ocultar,
    required VoidCallback onToggle,
    required TextEditingController controller,
    required Widget icono,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          obscureText: ocultar,
          controller: controller,
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
        ),
      ],
    );
  }
}
