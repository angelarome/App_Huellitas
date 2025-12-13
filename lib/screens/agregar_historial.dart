import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:http/http.dart' as http; 
import 'dart:convert';
import 'higiene.dart';  
import 'package:flutter/services.dart';
import 'historialClinico.dart';
import 'verhistorial_clinico.dart';
import 'interfazIA.dart';

class AgregarHistorialScreen extends StatefulWidget {
  final int idMascota;
  final int? idVeterinaria;
  final String? nombreVeterinaria;
  const AgregarHistorialScreen({super.key, required this.idMascota, this.idVeterinaria, this.nombreVeterinaria});


  @override
  State<AgregarHistorialScreen> createState() => _AgregarHistorialScreenState();
}

class _AgregarHistorialScreenState extends State<AgregarHistorialScreen> {
  DateTime? _fecha;
  TimeOfDay? _horaSeleccionada;
  
  TextEditingController _nombreMascotaController = TextEditingController();
  late TextEditingController nombre_veterinariaController;
  final pesoController = TextEditingController();
  final motivoController = TextEditingController();
  final diagnosticoController = TextEditingController();
  final tratamientoController = TextEditingController();
  final observacionesController = TextEditingController();
  List<Map<String, dynamic>> mascotas = [];

  bool _menuAbierto = false; // 👈 define esto en tu StatefulWidget

  void mostrarConfirmacionRegistro(BuildContext context, VoidCallback onConfirmar) {
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
                      '¿Deseas registrar este historial clínico?',
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
                            _registrarHistorial(); // 👉 Llama a la función que hace el registro
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


  void _toggleMenu() {
    setState(() {
      _menuAbierto = !_menuAbierto;
    });
  }

  @override
  void initState() {
    super.initState();
    obtenerMascotasPorId(); // Llamamos a la API apenas se abre la pantalla
    nombre_veterinariaController = TextEditingController(
      text: widget.nombreVeterinaria?.isNotEmpty == true ? widget.nombreVeterinaria! : '',
    );
  }

  Future<void> obtenerMascotasPorId() async {
    final url = Uri.parse("https://apphuellitas-production.up.railway.app/obtenermascota");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_mascota": widget.idMascota}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List mascotasJson = data["mascotas"] ?? [];

      setState(() {
        mascotas = List<Map<String, dynamic>>.from(mascotasJson);
        _nombreMascotaController.text = mascotas.first["nombre"] ?? "";
      });
    } else {
        print("Error al obtener mascotas: ${response.statusCode}");
    }
  }

  Future<void> _registrarHistorial() async {

    List<String> errores = [];

    // Hora
    if (_horaSeleccionada == null) {
      errores.add("hora");
    }

    // Fecha
    if (_fecha == null) {
      errores.add("fecha");
    }

    // Nombre veterinaria
    if (nombre_veterinariaController.text.trim().isEmpty) {
      errores.add("nombre de la veterinaria");
    }

    // Peso
    if (pesoController.text.trim().isEmpty) {
      errores.add("peso");
    }

    // Motivo
    if (motivoController.text.trim().isEmpty) {
      errores.add("motivo");
    }

    // Diagnóstico
    if (diagnosticoController.text.trim().isEmpty) {
      errores.add("diagnóstico");
    }

    // Tratamiento
    if (tratamientoController.text.trim().isEmpty) {
      errores.add("tratamiento");
    }

    // Observaciones
    if (observacionesController.text.trim().isEmpty) {
      errores.add("observaciones");
    }


    // --- Mostrar errores ---
    if (errores.isNotEmpty) {
      if (errores.length == 1) {
        mostrarMensajeFlotante(
          context,
          "⚠️ Falta llenar: ${errores.first}.",
          colorFondo: Colors.white,
          colorTexto: Colors.redAccent,
        );
      } else {
        mostrarMensajeFlotante(
          context,
          "⚠️ Faltan: ${errores.join(', ')}.",
          colorFondo: Colors.white,
          colorTexto: Colors.redAccent,
        );
      }
      return;
    }
    // Formatear fecha (YYYY-MM-DD)
    String fecha = "${_fecha!.year.toString().padLeft(4, '0')}-"
                  "${_fecha!.month.toString().padLeft(2, '0')}-"
                  "${_fecha!.day.toString().padLeft(2, '0')}";

    // Formatear hora (HH:mm:ss)
    String hora = _horaSeleccionada!.hour.toString().padLeft(2, '0') + ":" +
                  _horaSeleccionada!.minute.toString().padLeft(2, '0') + ":00";


    final url = Uri.parse("https://apphuellitas-production.up.railway.app/registrarHistorial");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id_mascota": widget.idMascota,
          "id_veterinaria": widget.idVeterinaria,
          "fecha": fecha,
          "hora": hora,
          "nombre_veterinaria": nombre_veterinariaController.text,
          "peso": pesoController.text,
          "motivo": motivoController.text,
          "diagnostico": diagnosticoController.text,
          "tratamiento": tratamientoController.text,
          "observaciones": observacionesController.text,
        }),
      );

      if (response.statusCode == 201) {
        mostrarMensajeFlotante(
          context,
          "✅ Historial clínico registrado correctamente",
          colorFondo: const Color.fromARGB(255, 186, 237, 150), // verde bonito
          colorTexto: const Color.fromARGB(255, 0, 0, 0),
        );

        if (widget.idVeterinaria != null) {
          // Si viene id_veterinaria, ir a la pantalla de veterinaria
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VerHistorialclinico(id: widget.idMascota, id_veterinaria: widget.idVeterinaria, nombreVeterinaria: widget.nombreVeterinaria),
            ),
          );
        } else {
          // Si no, ir al historial clínico
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Historialclinico(id: widget.idMascota),
            ),
          );
        }

      } else {
        final error = jsonDecode(response.body)["error"];
        mostrarMensajeFlotante(
          context,
          "❌ Error: $error",
          colorFondo: Colors.white,
          colorTexto: Colors.redAccent,

        );
      }
    } catch (e) {
      mostrarMensajeFlotante(
        context,
        "❌ Error al conectar con el servidor: $e",
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () {
          
        },
        child: Image.asset('assets/inteligent.png', width: 36, height: 36, fit: BoxFit.contain),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/vete.jpg"),
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
                   
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      "Añadir Historial Clínico",
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
                      constraints: const BoxConstraints(minHeight: 600),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue[700],
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black26)],
                      ),
                      child: Column(
                        children: [
                          _campoTextoConEtiqueta("Mascota", _icono("assets/Nombre.png"), controller: _nombreMascotaController,),

                          _campoFecha(context),
                          _campoHora(context),

                          _campoTextoConEtiquetaa(
                            "Nombre de la Veterinaria",
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SizedBox(width: 24, height: 24, child: Image.asset('assets/veterinaria.png')),
                            ),
                            nombre_veterinariaController,
                            tipo: 'letras',
                            hintText: "ej: Veterinaria Huellitas",
                            enabled: nombre_veterinariaController.text.isEmpty,
                          ),
                          _campoPeso("Peso", "assets/Peso.png", pesoController),

                          _campoTextoConEtiquetaa(
                            "Motivo",
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SizedBox(width: 24, height: 24, child: Image.asset('assets/huellitas.png')),
                            ),
                            motivoController,
                            tipo: 'letras',
                            hintText: "ej: Se rasca mucho",
                          ),

                          _campoTextoGrande(
                            "Diagnóstico",
                            SizedBox(width: 24, height: 24, child: Image.asset("assets/estetoscopio.png")),
                            diagnosticoController,
                            hintText: "ej: Dermatitis alérgica",
                          ),
                          _campoTextoGrande(
                            "Tratamiento",
                            SizedBox(width: 24, height: 24, child: Image.asset("assets/medicamentoss.png")),
                            tratamientoController,
                            hintText: "ej: Antibiótico cada 12 horas por 7 días",
                          ),

                          _campoTextoGrande(
                            "Observaciones",
                            SizedBox(width: 24, height: 24, child: Image.asset("assets/documentos.png")),
                            observacionesController,
                            hintText: "ej: Se recomienda baños medicados una vez por semana.",
                          ),

                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          if (widget.idVeterinaria != null) {
                            // Si viene id_veterinaria, ir a la pantalla de veterinaria
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VerHistorialclinico(id: widget.idMascota, id_veterinaria: widget.idVeterinaria, nombreVeterinaria: widget.nombreVeterinaria),
                              ),
                            );
                          } else {
                            // Si no, ir al historial clínico
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Historialclinico(id: widget.idMascota),
                              ),
                            );
                          }
                        },
                        icon: SizedBox(width: 24, height: 24, child: Image.asset('assets/cancelar.png')),
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
                          mostrarConfirmacionRegistro(context, _registrarHistorial); // 👈 Muestra el mensaje en lugar de registrar directo
                        },
                        icon: SizedBox(width: 24, height: 24, child: Image.asset('assets/Correcto.png')),
                        label: const Text("Añadir"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
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

  Widget _icono(String assetPath) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(width: 24, height: 24, child: Image.asset(assetPath)),
    );
  }

  Widget _dropdownConEtiquetaa(
    String etiqueta,
    Widget iconoWidget,
    List<String> opciones,
    String hintText,
    {String? valorInicial, required Function(String?) onChanged}
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[800]),
            prefixIcon: iconoWidget,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          value: valorInicial,
          items: opciones.map((opcion) {
            return DropdownMenuItem(value: opcion, child: Text(opcion));
          }).toList(),
          onChanged: onChanged,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _campoTextoGrande(
    String titulo,
    Widget icono,
    TextEditingController controller, {
    String hintText = "",
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),

        TextField(
          controller: controller,
          minLines: 4,
          maxLines: 8,
          keyboardType: TextInputType.multiline,
          style: const TextStyle(color: Colors.black),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(r"[a-zA-ZáéíóúÁÉÍÓÚñÑ0-9.,\s]"),
            ),
          ],
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Transform.translate(
              offset: const Offset(0, -40),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(width: 24, height: 24, child: icono),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey),
            contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        )
      ],
    );
  }

  Widget _campoPeso(String etiqueta, String imagePath, TextEditingController controller) {
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
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly, // solo números
          ],
          decoration: InputDecoration(
            hintText: "Digite el peso",
            hintStyle: TextStyle(color: Colors.grey[800]),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(8.0), // margen para que no se vea aplastado
              child: Image.asset(
                imagePath,
                width: 24,
                height: 24,
              ),
            ),
            suffixText: "Kg",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _campoTextoConEtiquetaa(
    String etiqueta, 
    Widget iconoWidget, 
    TextEditingController controller, {
    String hintText = '',
    String tipo = 'texto', // 'texto', 'num' o 'letras'
    bool enabled = true, 
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: tipo == 'num' ? TextInputType.number : TextInputType.text,
          inputFormatters: [
            if (tipo == 'num') FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
            if (tipo == 'letras')
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
          ],
          maxLength: (etiqueta == "Cédula" || etiqueta == "Teléfono") ? 10 : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: hintText.isEmpty ? "Digite $etiqueta" : hintText,
            prefixIcon: iconoWidget,
            counterText: "",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (valor) {
            if (valor == null || valor.isEmpty) {
              return 'Por favor ingresa $etiqueta';
            }
            if (tipo == 'num' && !RegExp(r'^[0-9]+$').hasMatch(valor)) {
              return 'Solo se permiten números';
            }
            if (tipo == 'letras' && !RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(valor)) {
              return 'Solo se permiten letras';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _campoTextoConEtiqueta(String etiqueta, Widget icono, {TextEditingController? controller, String? hintText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[800]),
            prefixIcon: icono,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
      ],
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

  Widget _campoFecha(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
      
            const SizedBox(width: 6),
            const Text(
              "Fecha",
              style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 252, 252, 252)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            builder: (context, child) {
              return Theme(
                data: ThemeData(
                  useMaterial3: true,
                  colorScheme: ColorScheme.light(
                    primary: Color(0xFF3A97F5),   // 🌟 Color celeste (botones, selección)
                    onPrimary: Colors.white,      // Texto dentro de los botones
                    surface: Colors.white,        // Fondo del calendario
                    onSurface: Colors.black87,    // Texto general
                  ),
                  textButtonTheme: TextButtonThemeData(
                    style: TextButton.styleFrom(
                      foregroundColor: Color(0xFF3A97F5), // Color de "Cancelar"
                    ),
                  ),
                ),
                child: child!,
              );
            },
          );
            if (picked != null) {
              setState(() {
                _fecha = picked;
              });
            }
          },
          child: AbsorbPointer(
            child: TextField(
              decoration: InputDecoration(
                hintText: _fecha == null
                    ? "Seleccione la fecha"
                    : "${_fecha!.day}/${_fecha!.month}/${_fecha!.year}",
                hintStyle: TextStyle(color: Colors.grey[800]),

                // 👇 Aquí reemplazamos el ícono por una imagen personalizada
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(8.0), // Ajusta el espacio
                  child: Image.asset(
                    "assets/Calendario.png", // ruta de tu imagen
                    width: 24,
                    height: 24,
                  ),
                ),

                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _campoHora(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Text(
            "Hora",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 255, 255, 255),
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      GestureDetector(
        onTap: () async {
          final TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
            builder: (context, child) {
              return Theme(
                data: ThemeData(
                  useMaterial3: true, // Material 3 más moderno
                  colorScheme: ColorScheme.light(
                    primary: const Color(0xFF3A97F5), // color del círculo del reloj
                    onPrimary: Colors.white, // color del texto dentro del círculo
                    surface: Colors.white, // fondo del diálogo
                    onSurface: Colors.black87, // color del texto fuera del círculo
                  ),
                  textTheme: const TextTheme(
                    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            setState(() {
              _horaSeleccionada = picked;
            });
          }
        },
        child: AbsorbPointer(
          child: TextField(
            decoration: InputDecoration(
              hintText: _horaSeleccionada == null
                  ? "Seleccione la hora"
                  : _horaSeleccionada!.format(context),
              hintStyle: TextStyle(color: Colors.grey[800]),

              // 👇 Aquí reemplazamos el ícono por una imagen personalizada
              prefixIcon: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  "assets/Hora.png", // tu ícono personalizado
                  width: 24,
                  height: 24,
                ),
              ),

              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
    ],
  );
}
}