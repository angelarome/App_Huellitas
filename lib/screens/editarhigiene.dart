import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:http/http.dart' as http; 
import 'dart:convert';
import 'higiene.dart';  

class EditarCuidadoScreen extends StatefulWidget {
  final int idMascota;
  final int id_higiene;
  final String nombreMascota;
  final String frecuencia;
  final String notas;
  final String tipo;
  final String hora;
  final String fecha;

  const EditarCuidadoScreen({super.key, required this.idMascota, required this.id_higiene, required this.nombreMascota, required this.frecuencia, required this.notas, required this.tipo, required this.hora, required this.fecha});


  @override
  State<EditarCuidadoScreen> createState() => _EditarCuidadoScreenState();
}

class _EditarCuidadoScreenState extends State<EditarCuidadoScreen> {
  DateTime? _fecha;
  TimeOfDay? _horaSeleccionada;

  String? _tipoSeleccionado;
  String? _frecuenciaSeleccionada;

  TextEditingController _nombreMascotaController = TextEditingController();
  TextEditingController _frecuenciaController = TextEditingController();
  TextEditingController _notasController = TextEditingController();
  TextEditingController _tipoController = TextEditingController();
  TextEditingController _horaController = TextEditingController();
  TextEditingController _fechaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 👇 Inicializamos el controlador con el nombre que vino desde la otra pantalla
    _nombreMascotaController = TextEditingController(text: widget.nombreMascota);
    _frecuenciaController = TextEditingController(text: widget.frecuencia);
    _notasController = TextEditingController(text: widget.notas);
    _tipoController = TextEditingController(text: widget.tipo);
    _horaController = TextEditingController(text: widget.hora);
    _fechaController = TextEditingController(text: widget.fecha);
    // Inicializar las variables para los Dropdown con los valores actuales
    _tipoSeleccionado = _tipoController.text.isNotEmpty ? _tipoController.text : null;
    _frecuenciaSeleccionada = _frecuenciaController.text.isNotEmpty ? _frecuenciaController.text : null;

  }

  @override
  void dispose() {
    _nombreMascotaController.dispose();
    super.dispose();
  }

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
                      '¿Deseas editar ${_tipoSeleccionado}?',
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
                        ElevatedButton(
                          onPressed: () {
                            overlayEntry?.remove();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 202, 65, 65),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'No',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                        // ✅ Botón "Sí"
                        ElevatedButton(
                          onPressed: () {
                            overlayEntry?.remove();
                            actualizar_higiene(); // 👉 Llama a la función que hace el registro
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Sí',
                            style: TextStyle(color: Colors.white, fontSize: 16),
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

  Future<void> actualizar_higiene() async {
    // 🗓️ FECHA — siempre se formatea (aunque no se cambie)
    String fecha;
    if (_fecha != null) {
      // Si el usuario elige nueva fecha
      fecha = "${_fecha!.year.toString().padLeft(4, '0')}-"
              "${_fecha!.month.toString().padLeft(2, '0')}-"
              "${_fecha!.day.toString().padLeft(2, '0')}";
    } else {
      // Si no elige nueva, formateamos la del widget
      try {
        // Si viene en formato "DD/MM/YYYY"
        List<String> partes = widget.fecha.split('/');
        if (partes.length == 3) {
          fecha =
              "${partes[2].padLeft(4, '0')}-${partes[1].padLeft(2, '0')}-${partes[0].padLeft(2, '0')}";
        } else {
          // Si ya viene como YYYY-MM-DD, la dejamos igual
          fecha = widget.fecha;
        }
      } catch (_) {
        fecha = widget.fecha;
      }
    }

    // ⏰ HORA — también siempre se formatea
    String hora;
    if (_horaSeleccionada != null) {
      // Si el usuario cambia la hora
      hora = _horaSeleccionada!.hour.toString().padLeft(2, '0') + ":" +
            _horaSeleccionada!.minute.toString().padLeft(2, '0') + ":00";
    } else {
      // Si no cambia, formateamos la del widget (por si no tiene segundos)
      try {
        // Si viene como HH:mm
        List<String> partesHora = widget.hora.split(':');
        if (partesHora.length == 2) {
          hora =
              "${partesHora[0].padLeft(2, '0')}:${partesHora[1].padLeft(2, '0')}:00";
        } else {
          // Si ya tiene segundos
          hora = widget.hora;
        }
      } catch (_) {
        hora = widget.hora;
      }
    }

    final url = Uri.parse("http://localhost:5000/actualizar_higiene");

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        
        body: jsonEncode({
          "id_higiene": widget.id_higiene,
          "frecuencia": _frecuenciaSeleccionada ?? widget.frecuencia,
          "notas": _notasController.text.isNotEmpty ? _notasController.text : widget.notas,
          "tipo": _tipoSeleccionado ?? widget.tipo,
          "fecha": fecha.isNotEmpty ? fecha : widget.fecha,
          "hora": hora.isNotEmpty ? hora : widget.hora,
        }),
      );
      if (response.statusCode == 200) {
        mostrarMensajeFlotante(
          context,
          "✅ Higiene actualizado correctamente",
          colorFondo: const Color.fromARGB(255, 243, 243, 243), // verde bonito
          colorTexto: const Color.fromARGB(255, 0, 0, 0),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HigieneScreen(
            id: widget.idMascota,
          ),
        ),
      );
      } else {
        mostrarMensajeFlotante(
          context,
          "❌ Error: No se pudo actualizar la higiene",
          colorFondo: Colors.white,
          colorTexto: Colors.redAccent,

        );
      }
    } catch (e) {
      mostrarMensajeFlotante(
        context,
        "❌ Error al actualizar higiene: $e",
      );
    }
  }
    

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () {
          // Acción de IA
        },
        child: Image.asset('assets/inteligent.png', width: 36, height: 36, fit: BoxFit.contain),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/Invierno.jpg"),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: SizedBox(width: 24, height: 24, child: Image.asset('assets/Menu.png')),
                        onPressed: () {},
                      ),
                      Row(
                        children: [
                          SizedBox(width: 24, height: 24, child: Image.asset('assets/Calendr.png')),
                          const SizedBox(width: 10),
                          SizedBox(width: 24, height: 24, child: Image.asset('assets/Campana.png')),
                        ],
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: IconButton(
                        icon: Image.asset('assets/devolver5.png', width: 24, height: 24),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      "Editar cuidado",
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

                          _dropdownConEtiqueta(
                            "Tipo",
                            _icono("assets/Etiqueta.png"),
                            ["Baño", "Peluquería", "Manicure", "Cambio de arenero"],
                            "Seleccione tipo de cuidado",
                            _tipoSeleccionado,
                            (val) => setState(() => _tipoSeleccionado = val),
                          ),

                          _campoFecha(context),
                          _campoHora(context),

                          _dropdownConEtiqueta(
                            "Frecuencia",
                            _icono("assets/Frecuencia.png"),
                            ["Diario", "Semanal", "Mensual", "Anual"],
                            "Seleccione frecuencia",
                            _frecuenciaSeleccionada,
                            (val) => setState(() => _frecuenciaSeleccionada = val),
                          ),


                          _campoNotas("Notas", "assets/Notas.png", controller: _notasController),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
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
                          actualizar_higiene();
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

  Widget _icono(String assetPath) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(width: 24, height: 24, child: Image.asset(assetPath)),
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
        const Text(
          "Fecha",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
                  data: ThemeData.dark().copyWith(
                    colorScheme: ColorScheme.dark(primary: Colors.blue[700]!),
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


  Widget _campoNotas(String etiqueta, String assetPath, {TextEditingController? controller, String? hintText}) {
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
        controller: _notasController,
        maxLines: 4,
        keyboardType: TextInputType.multiline,
        decoration: InputDecoration(
          hintText: "Edite la nota",
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


  Widget _campoHora(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Hora",
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      const SizedBox(height: 4),
      GestureDetector(
        onTap: () async {
          final TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
            builder: (context, child) {
              return Theme(
                data: ThemeData.dark().copyWith(
                  timePickerTheme: TimePickerThemeData(
                    backgroundColor: Colors.blue[700],
                    hourMinuteTextColor: Colors.white,
                    dialHandColor: Colors.white,
                    dialTextColor: Colors.white,
                    entryModeIconColor: Colors.white,
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