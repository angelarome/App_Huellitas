import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:http/http.dart' as http; 
import 'dart:convert';  
import 'dart:typed_data';
import 'package:dropdown_button2/dropdown_button2.dart';

class Solicitudes extends StatefulWidget {
  final int id_dueno;
  const Solicitudes({super.key, required this.id_dueno});

  @override
  State<Solicitudes> createState() => _SolicitudesState();
}

class _SolicitudesState extends State<Solicitudes> {
  List<Map<String, dynamic>> solicitudes = [];
  bool cargandoSolicitudes = false;
  List<String> nombresMascotas = ["Cargando..."];
  List<Map<String, dynamic>> mascotas = [];
  String? _nombreMascota; 
  String? _idMascota;

  final List<String> tiposRelacion = [
    "Mamá",
    "Papá",
    "Tío",
    "Hermano",
    "Primo",
    "Abuelo",
    "Abuela",
    "Amigo",
    "Padrino",
    "Madrina",
    "Otro"
  ];

  String? _tipoRelacion;
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _obtenerSolicitudes();
    _obtenerMascotas();
  }

  Future<void> _obtenerMascotas() async {
    setState(() => cargando = true);

    final url = Uri.parse("https://apphuellitas-production.up.railway.app/mascotas");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_dueno": widget.id_dueno}),
    );

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);

      final List mascotasJson = data["mascotas"] ?? [];

      setState(() {
        mascotas = mascotasJson
            .map<Map<String, dynamic>>((m) => Map<String, dynamic>.from(m))
            .toList();

        nombresMascotas = mascotas
            .map((m) => m["nombre"].toString())
            .toList();

        // NO asignamos automáticamente la primera mascota
        _nombreMascota = null;

        cargando = false;

      });
    } else {
      setState(() => cargando = false);
      print("❌ Error al obtener mascotas: ${response.statusCode}");
    }
  }

  Future<void> _obtenerSolicitudes() async {
    setState(() => cargandoSolicitudes = true);

    try {
      final url = Uri.parse("https://apphuellitas-production.up.railway.app/obtener_solicitudes");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id_dueno": widget.id_dueno}),
      );

      if (response.statusCode != 200) {
        print("❌ Error HTTP: ${response.statusCode}");
        return;
      }

      final data = jsonDecode(response.body);

      // Ahora data es un Map con la clave "solicitudes"
      if (data == null || data["solicitudes"] == null) {
        return;
      }

      final List solicitudesJson = data["solicitudes"];


      final nuevasSolicitudes = solicitudesJson.map<Map<String, dynamic>>((m) {
        final item = Map<String, dynamic>.from(m);

        final imagenBase64 = item["imagen_mascota"];

        if (imagenBase64 != null && imagenBase64.toString().isNotEmpty) {
          try {
            item["imagen_mascota_bytes"] = base64Decode(imagenBase64);
          } catch (_) {
            print("❌ Error decodificando imagen de la mascota ID: ${item['id_mascota']}");
            item["imagen_mascota_bytes"] = null;
          }
        } else {
          item["imagen_mascota_bytes"] = null;
        }

        return item;
      }).toList();

      setState(() {
        solicitudes = nuevasSolicitudes;
      });

    } catch (e) {
      print("❌ Error inesperado al obtener solicitudes: $e");
    } finally {
      if (mounted) {
        setState(() => cargandoSolicitudes = false);
      }
    }
  }

  Future<void> enviar_solicitud(idMascota, idPersona) async {
    if (_nombreMascota == null ||
      _nombreMascota == "Cargando..." ||
      _tipoRelacion == null 
      ) {
      mostrarMensajeFlotante(
        context,
        "⚠️ Por favor complete todos los campos obligatorios.",
        colorFondo: Colors.white,
        colorTexto: Colors.redAccent,
      );
      return;
    }
    final url = Uri.parse("https://apphuellitas-production.up.railway.app/enviar_solicitud");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        
        body: jsonEncode({
          "id_mascota": idMascota,
          "id_dueno": widget.id_dueno,
          "id_persona": idPersona,
          "tipo_relacion": _tipoRelacion,
        }),
      );
      if (response.statusCode == 200) {
        mostrarMensajeFlotante(
          context,
          "✅ Solicitud enviada correctamente",
          colorFondo: const Color.fromARGB(255, 243, 243, 243),
          colorTexto: const Color.fromARGB(255, 0, 0, 0),
        );

        // Limpiar selección de fecha y hora
        setState(() {
          _nombreMascota = null;
          _tipoRelacion = null;
        });
        await _obtenerSolicitudes();

      } else {
        mostrarMensajeFlotante(
          context,
          "❌ Error: No se pudo enviar la solicitud",
          colorFondo: Colors.white,
          colorTexto: Colors.redAccent,

        );
        
      }
    } catch (e) {
      mostrarMensajeFlotante(
        context,
        "❌ Error al enviar solicitud: $e",
      );
    }
  }

  Future<void> cancelarSolicitud(int id_solicitud) async {
    final url = Uri.parse("https://apphuellitas-production.up.railway.app/cancelar_solicitud");

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id_solicitud": id_solicitud,
      }),
    );

    if (response.statusCode == 200) {
      mostrarMensajeFlotante(
        context,
        "✅ Solicitud cancelada correctamente",
        colorFondo: const Color.fromARGB(255, 243, 243, 243),
        colorTexto: const Color.fromARGB(255, 0, 0, 0),
      );

      await _obtenerSolicitudes();
      
    } else {
      mostrarMensajeFlotante(
        context,
        "❌ Error: No se pudo cancelar la solicitud",
        colorFondo: Colors.white,
        colorTexto: Colors.redAccent,
      );
    }
  }

  Future<void> AceptarSolicitud(int id_solicitud, int id_mascota, int id_dueno) async {
    final url = Uri.parse("https://apphuellitas-production.up.railway.app/aceptar_solicitud");

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id_solicitud": id_solicitud,
        "id_mascota": id_mascota,
        "id_dueno": id_dueno,
      }),
    );

    if (response.statusCode == 200) {
      mostrarMensajeFlotante(
        context,
        "✅ Solicitud aceptada correctamente",
        colorFondo: const Color.fromARGB(255, 243, 243, 243),
        colorTexto: const Color.fromARGB(255, 0, 0, 0),
      );

      await _obtenerSolicitudes();
      
    } else {
      mostrarMensajeFlotante(
        context,
        "❌ Error: No se pudo aceptar la solicitud",
        colorFondo: Colors.white,
        colorTexto: Colors.redAccent,
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

  String capitalizar(String texto) {
    if (texto.isEmpty) return texto;
    return texto[0].toUpperCase() + texto.substring(1);
  }
  @override
    Widget build(BuildContext context) {
    return Scaffold(
    floatingActionButton: FloatingActionButton(
    backgroundColor: const Color.fromARGB(255, 81, 68, 46),
    onPressed: () {},
    child: Image.asset('assets/inteligent.png', width: 36, height: 36),
    ),
    body: Stack(
    children: [
    // Fondo
    Container(
    decoration: const BoxDecoration(
    image: DecorationImage(
    image: AssetImage("assets/hut-9582608_1280.jpg"),
    fit: BoxFit.cover,
    ),
    ),
    ),

      // Difuminado
      BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          color: Colors.black.withOpacity(0.3),
        ),
      ),

      // Contenido principal
      SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Image.asset('assets/Menu.png', width: 24, height: 24),
                    onPressed: () {},
                  ),
                  Row(
                    children: [
                      Image.asset('assets/Calendr.png', width: 24, height: 24),
                      const SizedBox(width: 10),
                      Image.asset('assets/Campana.png', width: 24, height: 24),
                      const SizedBox(width: 10),
                      Image.asset('assets/Perfil.png', width: 24, height: 24),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Flecha
              Image.asset(
                'assets/devolver5.png',
                width: 30,
                height: 30,
              ),

              const SizedBox(height: 10),

              // Título
              const Center(
                child: Text(
                  "Compartir mascota",
                  style: TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(blurRadius: 4, color: Colors.black),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Lista de solicitudes
              solicitudes.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Container(
                        height: 200,
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 120),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(187, 255, 255, 255),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color.fromARGB(255, 180, 179, 176),
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(1, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              "assets/correo.png",
                              width: 70,
                              height: 70,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "No tienes solicitudes",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: solicitudes.map((solicitud) {
                        final Uint8List? imagenBytes = solicitud["imagen_mascota_bytes"];
                        final esMiSolicitud = solicitud["id_remitente"] == widget.id_dueno;

                        // Estado de la solicitud
                        final estado = solicitud["estado"]?.toString().toLowerCase() ?? "";

                        // Botones según estado
                        Widget botones;
                        if (estado == "aceptada") {
                          // 👉 Si ya está aceptada, no mostrar botones
                          botones = const SizedBox(); 
                        } 
                        else if (estado == "cancelada") {
                          botones = Center(
                            child: ElevatedButton.icon(
                            onPressed: () {
                              _mostrarModalsolicitud(widget.id_dueno);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 33, 138, 184),
                              foregroundColor: Colors.white,
                            ),
                            // Aquí pones tu icono personalizado
                            icon: Image.asset(
                              "assets/correo.png",
                              width: 24,
                              height: 24,
                            ),
                            label: const Text("Enviar solicitud"),
                          ),
                          );
                        } else if (esMiSolicitud) {
                          botones = Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  cancelarSolicitud(solicitud["id_solicitud"]);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                icon: Image.asset(
                                  "assets/Cancelar.png",
                                  width: 20,
                                  height: 20,
                                ),
                                label: const Text("Cancelar"),
                              ),
                            ],
                          );
                        } else {
                          botones = Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  AceptarSolicitud(solicitud["id_solicitud"], solicitud["id_mascota"], widget.id_dueno);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(255, 33, 138, 184),
                                  foregroundColor: Colors.white,
                                ),
                                icon: Image.asset(
                                  "assets/correo.png",
                                  width: 20,
                                  height: 20,
                                ),
                                label: const Text("Aceptar"),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                onPressed: () {
                                  cancelarSolicitud(solicitud["id_solicitud"]);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                icon: Image.asset(
                                  "assets/Cancelar.png",
                                  width: 20,
                                  height: 20,
                                ),
                                label: const Text("Cancelar"),
                              ),
                            ],
                          );
                        }

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(187, 255, 255, 255),
                            border: Border.all(
                              color: const Color.fromARGB(255, 180, 179, 176),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 45,
                                backgroundImage: imagenBytes != null
                                    ? MemoryImage(imagenBytes)
                                    : const AssetImage("assets/usuario.png") as ImageProvider,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Nombre completo del dueño
                                    Text(
                                      capitalizar(solicitud["nombre"] ?? "Sin nombre") + " " +
                                          capitalizar(solicitud["apellido"] ?? ""),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 3),

                                    // Mascota
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          const TextSpan(
                                            text: "Mascota: ",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          TextSpan(
                                            text: capitalizar(solicitud["nombre_mascota"] ?? "Sin nombre"),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 3),

                                    // Parentesco
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          const TextSpan(
                                            text: "Parentesco: ",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          TextSpan(
                                            text: capitalizar(solicitud["parentesco"]?.toString() ?? "Sin parentesco"),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 3),

                                    // Estado
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          const TextSpan(
                                            text: "Estado: ",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          TextSpan(
                                            text: capitalizar(solicitud["estado"] ?? "Sin estado"),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // Botones según estado
                                    botones,
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
      ),
    ],
  ),

  );
  }

  void _mostrarModalsolicitud(int id_persona) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Enviar solicitud",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    nombresMascotas.isEmpty
                      ? const Text("No tienes mascotas registradas")
                      : ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 85), // Altura máxima del dropdown
                          child: _dropdownConEtiqueta(
                            "Nombre Mascota",
                            _icono("assets/Nombre.png"),
                            nombresMascotas,
                            "Seleccione la mascota",
                            _nombreMascota,
                            (val) {
                              setState(() {
                                _nombreMascota = val;

                                final mascota = mascotas.cast<Map<String, dynamic>>().firstWhere(
                                  (m) => m["nombre"] == val,
                                  orElse: () => <String, dynamic>{},
                                );
                                _idMascota = mascota.isNotEmpty ? mascota["id_mascotas"].toString() : null;
                              });
                            },
                          ),
                        ),

                    const SizedBox(height: 10),
                    _dropdownConEtiqueta(
                      "Relación",
                      _icono("assets/cuidado-de-mascotas-sinfondo.png"), // Cambia por un icono apropiado
                      tiposRelacion,
                      "Seleccione la relación",
                      _tipoRelacion,
                      (val) {
                        setState(() {
                          _tipoRelacion = val;
                        });
                      },
                    ),

                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: Image.asset(
                            "assets/cancelar.png",
                            height: 24,
                            width: 24,
                          ),
                          label: const Text("Cancelar"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await enviar_solicitud(_idMascota, id_persona);
                            Navigator.pop(context);
                          
                          },
                          icon: Image.asset(
                            "assets/correo.png",
                            height: 24,
                            width: 24,
                          ),
                          label: const Text("Enviar"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 33, 138, 184),
                            foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _icono(String assetPath) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(width: 24, height: 24, child: Image.asset(assetPath)),
    );
  }

  Widget _dropdownConEtiqueta(
    String etiqueta,
    Widget icono,
    List<String>? opciones,
    String hintText,
    String? valorActual,
    Function(String?)? onChanged,
  ) {
    final listaSegura =
        (opciones == null || opciones.isEmpty) ? ["Sin opciones"] : opciones;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 46, 45, 45),
          ),
        ),
        const SizedBox(height: 2),
        DropdownButtonFormField2<String>(
          value: valorActual, 
          decoration: InputDecoration(
            hintText: hintText, // esto se mostrará si valorActual es null
            hintStyle: TextStyle(color: Colors.grey[800]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 12,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: icono,
              ),
            ),
          ),
          
          items: listaSegura.map((opcion) {
            return DropdownMenuItem(
              value: opcion,
              child: Text(opcion),
            );
          }).toList(),
          onChanged: onChanged,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

}


