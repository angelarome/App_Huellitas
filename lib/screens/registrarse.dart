import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'iniciarsesion.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '1pantalla.dart';
import 'package:flutter/foundation.dart' show kIsWeb;


class RegistroUsuarioPage extends StatefulWidget {
  const RegistroUsuarioPage({super.key});

  @override
  State<RegistroUsuarioPage> createState() => _RegistroUsuarioPageState();
}

class _RegistroUsuarioPageState extends State<RegistroUsuarioPage> {
  final _formKey = GlobalKey<FormState>();

  // 🧩 Variables para imagen
  File? _imagen; // para móvil
  Uint8List? _webImagen; // para web
  String? _imagenBase64; // imagen lista para enviar al backend

  // 🧍‍♀️ Controladores de texto
  final TextEditingController cedulaController = TextEditingController();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController apellidoController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  final TextEditingController correoController = TextEditingController();
  final TextEditingController direccionController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmarController = TextEditingController();

  bool _ocultarPassword = true;
  bool _ocultarConfirmar = true;

  // ✅ Cargar imagen por defecto apenas se abra la pantalla
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

  // 📨 Método para registrar usuario
  Future<void> registrarUsuario() async {
    if (passwordController.text != confirmarController.text) {
      mostrarMensajeFlotante(
          context,
          "❌ Las contraseñas no coinciden",
        );
      return;
    }

    final url = Uri.parse("http://localhost:5000/registrar");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "cedula": cedulaController.text,
        "nombre": nombreController.text,
        "apellido": apellidoController.text,
        "telefono": telefonoController.text,
        "correo": correoController.text,
        "direccion": direccionController.text,
        "contrasena": confirmarController.text,
        "imagen": _imagenBase64, // 👈 Siempre hay imagen (por defecto o elegida)
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      print('✅ Registro exitoso: ${data["mensaje"]}');
      print('👤 Usuario: ${data["usuario"]}');
      final usuario = data["usuario"]; 
      final id = usuario["id_dueno"];// 👈 Aquí viene el usuario completo
      final cedula = usuario["cedula"];
      final nombre = usuario["nombre"]; // 👈 Sacamos el nombre
      final apellido = usuario["apellido"]; 
      final telefono = usuario["telefono"]; 
      final direccion = usuario["direccion"]; 
      final foto = usuario["foto_perfil"]; // 👈 Sacamos la foto

      final Uint8List bytes = base64Decode(foto);

      // ✅ Redirige a la pantalla principal y le pasa el nombre
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Pantalla1(id: id, cedula: cedula, nombreUsuario: nombre, apellidoUsuario: apellido, telefono: telefono, direccion: direccion, fotoPerfil: bytes),
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
          "❌ Error al registrarse",
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo con imagen
          Image.asset(
            'assets/inicio.png',
            fit: BoxFit.cover,
          ),

          // Desenfoque suave del fondo
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),

          // Contenido principal
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Registro",
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
                const SizedBox(height: 25),

                // Contenedor con el formulario
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
                                            : const AssetImage('assets/usuario.png')),
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

                            const SizedBox(height: 20),

                            _campoTexto("Nombre", Image.asset('assets/Nombre.png'), nombreController, tipo: 'letras'),
                            const SizedBox(height: 10),
                            _campoTexto("Apellido", Image.asset('assets/formato-de-texto.png'), apellidoController, tipo: 'letras'),
                            const SizedBox(height: 10),

                            Row(
                              children: [
                                Expanded(child: _campoTexto("Cédula", Image.asset('assets/cedula11.png'), cedulaController, tipo: 'num')),
                                const SizedBox(width: 10),
                                Expanded(child: _campoTexto("Teléfono", Image.asset('assets/Telefono.png'), telefonoController, tipo: 'num')),
                              ],
                            ),

                            const SizedBox(height: 10),
                            _campoTexto("Dirección", Image.asset('assets/Ubicacion.png'), direccionController),
                            const SizedBox(height: 10),
                            _campoTexto("Correo", Image.asset('assets/gmail.png'), correoController, tipo: 'correo'),
                            const SizedBox(height: 10),

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

                            // 🔹 Botón de registro
                            ElevatedButton.icon(
                              onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                registrarUsuario();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("⚠️ Por favor completa todos los campos correctamente")),
                                );
                              }
                            },
                              icon: SizedBox(
                                width: 30,
                                height: 30,
                                child: Image.asset('assets/agregar 1.png'),
                              ),
                              label: const Text(
                                'Registrarse',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(1.5, 1.5),
                                      color: Colors.black,
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                                elevation: 6,
                              ),
                            ),

                            const SizedBox(height: 5),

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
                          ],
                        ),
                      ),
                    ),

                    // Capa de ruido decorativa
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _NoisePainter(0.06),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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

// 🔹 (solo decorativo) - tu clase de ruido
class _NoisePainter extends CustomPainter {
  final double intensity;
  _NoisePainter(this.intensity);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(intensity);
    for (int i = 0; i < size.width * size.height * intensity; i++) {
      final dx = (size.width * (i % 100) / 100);
      final dy = (size.height * (i / 100) % 100) / 100;
      canvas.drawCircle(Offset(dx, dy), 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
