import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:http/http.dart' as http; 
import 'dart:convert';
import 'higiene.dart';  
import 'package:flutter/services.dart';
import 'medicamentos.dart';
import 'dart:typed_data';
import 'compartirmascota.dart';
import 'calendario.dart';
import 'menu_lateral.dart';
import 'perfil_mascota.dart';

class EditarMedicamentoScreen extends StatefulWidget {
  final int idMascota;
  final int id_medicamento;
  final String nombreMascota;
  final String frecuencia;
  final String dias_personalizados;
  final String notas;
  final String tipo;
  final String unidad;
  final double dosis;
  final String hora;
  final String fecha;
  final int id_dueno;
  final Uint8List? fotoMascota;

  const EditarMedicamentoScreen({super.key, required this.idMascota, required this.id_medicamento, required this.nombreMascota, required this.frecuencia, required this.dias_personalizados, required this.notas, required this.tipo, required this.unidad, required this.dosis, required this.hora, required this.fecha, required this.id_dueno, required this.fotoMascota});


  @override
  State<EditarMedicamentoScreen> createState() => _EditarMedicamentoScreenState();
}

class _EditarMedicamentoScreenState extends State<EditarMedicamentoScreen> {
  DateTime? _fecha;
  TimeOfDay? _horaSeleccionada;

  String? _tipoSeleccionado;
  String? _frecuenciaSeleccionada;
  String? unidadSeleccionada;

  Map<String, bool> diasSemana = {
    "Lun": false,
    "Mar": false,
    "Mié": false,
    "Jue": false,
    "Vie": false,
    "Sáb": false,
    "Dom": false,
  };
  
  final notasController = TextEditingController();
  TextEditingController _nombreMascotaController = TextEditingController();
  final TextEditingController frecuenciaPersonalizadaController = TextEditingController();
  final TextEditingController dosisController = TextEditingController();
  List<Map<String, dynamic>> mascotas = [];

  bool _menuAbierto = false; // 👈 define esto en tu StatefulWidget

  @override
  void initState() {
    super.initState();
    
    _nombreMascotaController.text = widget.nombreMascota;
    notasController.text = widget.notas;
    dosisController.text = widget.dosis.toString();
    frecuenciaPersonalizadaController.text = widget.dias_personalizados;

    // Frecuencia, tipo, unidad → son dropdown (String)
    _frecuenciaSeleccionada = widget.frecuencia;
    _tipoSeleccionado = widget.tipo;
    unidadSeleccionada = widget.unidad;

    // Fecha → convertir a DateTime
    _fecha = DateTime.tryParse(widget.fecha);

    // Hora → convertir a TimeOfDay
    final partesHora = widget.hora.split(":");
    _horaSeleccionada = TimeOfDay(
      hour: int.parse(partesHora[0]),
      minute: int.parse(partesHora[1]),
    );

    if (widget.dias_personalizados.isNotEmpty) {
      final dias = widget.dias_personalizados.split(",");

      for (var dia in dias) {
        final diaLimpio = dia.trim(); // <-- esto limpia espacios

        if (diasSemana.containsKey(diaLimpio)) {
          diasSemana[diaLimpio] = true;
        }
      }
    }
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
                            _editarMedicamento(); // 👉 Llama a la función que hace el registro
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


  Future<void> _editarMedicamento() async {
    List<String> camposFaltantes = [];

    // Dosis
    if (dosisController.text.trim().isEmpty || (widget.dosis == null || widget.dosis.toString().trim().isEmpty)) {
      camposFaltantes.add("Dosis");
    }

    // Frecuencia
    if (_frecuenciaSeleccionada == null || (widget.frecuencia?.trim() ?? '').isEmpty) {
      camposFaltantes.add("Frecuencia");
    }

    // Tipo
    if (_tipoSeleccionado == null || (widget.tipo?.trim() ?? '').isEmpty) {
      camposFaltantes.add("Tipo");
    }

    // Unidad
    if (unidadSeleccionada == null || (widget.unidad?.trim() ?? '').isEmpty) {
      camposFaltantes.add("Unidad");
    }

    // Fecha
    if (_fecha == null || (widget.fecha?.trim() ?? '').isEmpty) {
      camposFaltantes.add("Fecha");
    }

    // Hora
    if (_horaSeleccionada == null || (widget.hora?.trim() ?? '').isEmpty) {
      camposFaltantes.add("Hora");
    }

    // Mostrar mensaje si faltan campos
    if (camposFaltantes.isNotEmpty) {
      mostrarMensajeFlotante(
        context,
        "⚠️ Faltan campos: ${camposFaltantes.join(", ")}",
        colorFondo: Colors.white,
        colorTexto: Colors.redAccent,
      );
      return;
    }
    // Evita errores con el controlador
    String? notas = notasController.text.isEmpty ? null : notasController.text;

    // Formatear fecha (YYYY-MM-DD)
    String fecha = "${_fecha!.year.toString().padLeft(4, '0')}-"
                  "${_fecha!.month.toString().padLeft(2, '0')}-"
                  "${_fecha!.day.toString().padLeft(2, '0')}";

    // Formatear hora (HH:mm:ss)
    String hora = _horaSeleccionada!.hour.toString().padLeft(2, '0') + ":" +
                  _horaSeleccionada!.minute.toString().padLeft(2, '0') + ":00";

    String dias = frecuenciaPersonalizadaController.text;  

    final url = Uri.parse("https://apphuellitas-production.up.railway.app/editarMedicamento");

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id_mascota": widget.idMascota,
          "id_medicamento": widget.id_medicamento,
          "frecuencia": _frecuenciaSeleccionada == "Personalizada"
            ? "Personalizada"
            : _frecuenciaSeleccionada,
          "dosis": double.tryParse(dosisController.text),
          "unidad": unidadSeleccionada,
          "notas": notas,
          "tipo": _tipoSeleccionado,
          "dias_personalizados": dias.isNotEmpty ? dias : "",
          "fecha": fecha,
          "hora": hora,

          if (_frecuenciaSeleccionada == "Personalizada")
            "dias_personalizados": dias,

        }),
      );

      if (response.statusCode == 201) {
        mostrarMensajeFlotante(
          context,
          "✅ Medicamento editado correctamente",
          colorFondo: const Color.fromARGB(255, 186, 237, 150), // verde bonito
          colorTexto: const Color.fromARGB(255, 0, 0, 0),
        );

        // Redirigir a la pantalla principal de higiene
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MedicamentosScreen(id: widget.idMascota, id_dueno: widget.id_dueno, nombreMascota: widget.nombreMascota, fotoMascota: widget.fotoMascota),
          ),
        );
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

  final Map<String, String> iconosEspecie = {
    "ml": "assets/gotass.png",
    "mg": "assets/frasco-de-pastillas.png",
    "g": "assets/escala-de-justicia.png",
    "gotas": "assets/gotero-de-tinta.png",
    "pasta": "assets/pasta.png",
    "spray": "assets/rociar.png",
    "cucharada": "assets/cuchara.png",
  };

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
                  _barraSuperiorConAtras(context),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      "Añadir medicamento",
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
                            ["Vacuna", "Inyección", "Antipulgas", "Medicamentos", "Desparasitación", "Vitaminas y suplementos"],
                            "Seleccione tipo de medicamento",
                            _tipoSeleccionado,
                            (val) => setState(() => _tipoSeleccionado = val),
                          ),

                          Row(
                            children: [
                              Expanded(
                                child: _campoTextoConEtiquetaa(
                                  "Dosis",
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: SizedBox(width: 24, height: 24, child: Image.asset('assets/grafico.png')),
                                  ),
                                  dosisController,
                                  tipo: 'num',
                                  hintText: "Digite la dosis",
                                ),
                              ),

                              const SizedBox(width: 10), // espacio entre los dos

                              Expanded(
                                child: _dropdownConEtiquetaa(
                                  "Unidad",
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: SizedBox(
                                      width: 15,
                                      height: 15,
                                      child: Image.asset(
                                        unidadSeleccionada != null
                                            ? iconosEspecie[unidadSeleccionada!]!
                                            : 'assets/medicamentoss.png',
                                      ),
                                    ),
                                  ),
                                  ["ml", "mg", "g", "gotas", "pasta", "spray", "cucharada"],
                                  "Seleccione",
                                  valorInicial: unidadSeleccionada,
                                  onChanged: (valor) {
                                    setState(() {
                                      unidadSeleccionada = valor;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),

                          _campoFecha(context),
                          _campoHora(context),

                          _dropdownConEtiqueta(
                            "Frecuencia",
                            _icono("assets/Frecuencia.png"),
                            ["Diario", "Semanal", "Quincenal", "Mensual", "Cada 3 meses", "Una sola vez", "Personalizada"],
                            "Seleccione frecuencia",
                            _frecuenciaSeleccionada,
                            (val) => setState(() => _frecuenciaSeleccionada = val),
                          ),
                          if (_frecuenciaSeleccionada == "Personalizada") ...[
                            const SizedBox(height: 10),
                            _seleccionarDias(),   // ⬅️ Llamas al widget que muestra los días
                          ],
                          const SizedBox(height: 10),
                          _campoNotas("Notas", "assets/Notas.png", notasController),
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
                          // Cancelar
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
                          mostrarConfirmacionRegistro(context, _editarMedicamento); // 👈 Muestra el mensaje en lugar de registrar directo
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
          if (_menuAbierto)
            MenuLateralAnimado(onCerrar: _toggleMenu, id: widget.id_dueno),
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

  Widget _seleccionarDias() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Seleccione los días",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        const SizedBox(height: 10),

        Wrap(
          runSpacing: 12, 
          spacing: 10,
          children: diasSemana.keys.map((dia) {
            final bool seleccionado = diasSemana[dia]!;

            return ChoiceChip(
              label: Text(dia),
              selected: seleccionado,
              selectedColor: Colors.green.shade300,
              onSelected: (val) {
                setState(() {
                  diasSemana[dia] = val;

                  // Guardar en controller
                  List<String> seleccionados = diasSemana.entries
                      .where((e) => e.value)
                      .map((e) => e.key)
                      .toList();

                  frecuenciaPersonalizadaController.text = seleccionados.join(", ");
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _barraSuperior(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: SizedBox(
            width: 24,
            height: 24,
            child: Image.asset('assets/Menu.png'),
          ),
          onPressed: _toggleMenu,
        ),
        Row(
          children: [
            _iconoTop("assets/Perfil.png", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ListVaciaCompartirScreen(id_dueno: widget.id_dueno),
                ),
              );
            }),
            const SizedBox(width: 10),
            _iconoTop("assets/Calendr.png", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CalendarioEventosScreen(id_dueno: widget.id_dueno),
                ),
              );
            }),
            const SizedBox(width: 10),
            _iconoTop("assets/Campana.png", () {}),
          ],
        )

        
      ],
    );
  }

  Widget _iconoTop(String asset, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(width: 24, height: 24, child: Image.asset(asset)),
    );
  }

  Widget _barraSuperiorConAtras(BuildContext context) {
    return Column(
    crossAxisAlignment: CrossAxisAlignment.start, // alinear a la izquierda
    children: [
      _barraSuperior(context), // tu barra original

      // Tu botón de volver, justo debajo
      
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
    ],
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

  Widget _campoTextoConEtiquetaa(
    String etiqueta, 
    Widget iconoWidget, 
    TextEditingController controller, {
    String hintText = '',
    String tipo = 'texto', // 'texto', 'num' o 'letras'
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
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

  Widget _campoNotas(String etiqueta, String assetPath, TextEditingController controller) {
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
        maxLines: 4,
        controller: controller,
        keyboardType: TextInputType.multiline,
        decoration: InputDecoration(
          hintText: "Escriba una nota detallada",
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