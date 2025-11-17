
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
import 'cambiarcontrasena.dart';
import 'dart:async';

class RecuperarCuentaCodigo extends StatefulWidget {
  final String correo;
  final String rol;
  
  const RecuperarCuentaCodigo({
    super.key,
    required this.correo,
    required this.rol
  });

  @override
  State<RecuperarCuentaCodigo> createState() => _RecuperarCuentaCodigoState();
}

class _RecuperarCuentaCodigoState extends State<RecuperarCuentaCodigo> {
  int _segundosRestantes = 120; // 2 minutos
  Timer? _timer;
  bool _puedeReenviar = false;

  @override
  void initState() {
    super.initState();
    _iniciarTemporizador();
  }

  void _iniciarTemporizador() {
    _puedeReenviar = false;
    _segundosRestantes = 60;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_segundosRestantes > 0) {
        setState(() {
          _segundosRestantes--;
        });
      } else {
        setState(() {
          _puedeReenviar = true;
        });
        _timer?.cancel();
      }
    });
  }

  String _formatearTiempo(int segundos) {
    final minutos = segundos ~/ 60;
    final segs = segundos % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segs.toString().padLeft(2, '0')}';
  }

  Future<void> _reenviarCodigo() async {
    mostrarLoading(context);
    final url = Uri.parse("http://localhost:5000/recuperarcontrasena");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "correo": widget.correo,
      }),
    );

    ocultarLoading(context);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final usuario = data["usuario"];

      mostrarMensajeFlotante(
        context,
        "✅ Enviando código...",
        colorFondo: const Color.fromARGB(255, 203, 250, 203),
        colorTexto: Colors.black,
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
        colorFondo: const Color.fromARGB(255, 250, 180, 180),
        colorTexto: Colors.black,
      );
    }

    print("Código reenviado");
    _iniciarTemporizador(); // Reinicia la cuenta regresiva
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String obtenerCodigoIngresado() {
    return codigoControllers.map((c) => c.text).join();
  }


  Future<void> buscarcodigo() async {
    mostrarLoading(context);
    if (obtenerCodigoIngresado().length != 6) {
      mostrarMensajeFlotante(
        context,
        "Ingresa los 6 dígitos del código",
      );
      return;
    }
    final url = Uri.parse("http://localhost:5000/codigo");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "correo": widget.correo,
      }),
    );

    ocultarLoading(context);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final String codigo = data["codigo"];          
      final expiracionStr = data["expiracion"];
      final expiracion = DateTime.parse(expiracionStr);


      final DateTime ahora = DateTime.now();

      if (ahora.isAfter(expiracion)) {
        mostrarMensajeFlotante(context, "❌ Código vencido",
        colorFondo: const Color.fromARGB(255, 250, 180, 180),
        colorTexto: Colors.black);
        return;
      }

      final String codigoIngresado = obtenerCodigoIngresado();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecuperarCuentaPage(correo: widget.correo, rol: widget.rol),
        ),
      );
    }
    else if (response.statusCode == 404) {
      mostrarMensajeFlotante(
        context,
        "❌ Codigo incorrecto",
        colorFondo: const Color.fromARGB(255, 250, 180, 180),
        colorTexto: Colors.black,
      );
    }
    else {
      mostrarMensajeFlotante(
        context,
        "❌ Error inesperado en el servidor",
        colorFondo: const Color.fromARGB(255, 250, 180, 180),
        colorTexto: Colors.black,
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

  final List<TextEditingController> codigoControllers =
    List.generate(6, (index) => TextEditingController());

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
                    "Introduce el código que te enviamos a\ntu correo para recuperar la contraseña",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Form(
                    child: Container(
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
                          _campoCodigo(),
                          const SizedBox(height: 20),
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
                        buscarcodigo();
                      },
                      icon: Image.asset(
                        'assets/llave.png',
                        width: 24,
                        height: 24,
                      ),
                      label: const Text("Verificar código"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                    // Botón Reenviar Código
                  TextButton(
                      onPressed: _puedeReenviar ? _reenviarCodigo : null,
                      style: TextButton.styleFrom(
                        foregroundColor: _puedeReenviar ? Colors.white : Colors.grey, 
                      ),
                      child: _puedeReenviar
                          ? const Text("Reenviar código")
                          : Text("Reenviar en ${_formatearTiempo(_segundosRestantes)}"),
                    ),
                  ],
              ),
            ),
          ),
        ),
      ),
    );
  }



Widget _campoCodigo() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Código de verificación",
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
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(6, (index) {
          return SizedBox(
            width: 45,
            child: TextFormField(
              controller: codigoControllers[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                counterText: "",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (value) {
                if (value.length == 1 && index < 5) {
                  FocusScope.of(context).nextFocus();
                }
                if (value.isEmpty && index > 0) {
                  FocusScope.of(context).previousFocus();
                }
              },
            ),
          );
        }),
      ),
    ],
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

}