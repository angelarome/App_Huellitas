import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http; 
import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:async';
import 'calendario.dart';
import 'compartirmascota.dart';
import 'menu_lateral.dart';

class UbicacionScreen extends StatefulWidget {
  final int idMascota;
  final int id_dueno;
  const UbicacionScreen({super.key, required this.idMascota, required this.id_dueno});

  @override
  State<UbicacionScreen> createState() => _UbicacionScreenState();
}

class _UbicacionScreenState extends State<UbicacionScreen> {
  LatLng _ultimaPosicion = LatLng(4.65, -74.05);
  Timer? _timer;
  List<Map<String, dynamic>> _collar = [];
  List<Map<String, dynamic>> _ubicacion = [];
  final TextEditingController codigoCtrl = TextEditingController();
  final TextEditingController latCtrl = TextEditingController();
  final TextEditingController lngCtrl = TextEditingController();
  final MapController _mapController = MapController();
  bool _menuAbierto = false;

  void _toggleMenu() {
    setState(() {
      _menuAbierto = !_menuAbierto;
    });
  }

 @override
  void initState() {
    super.initState();

    // después de que se construya el primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(_ultimaPosicion, 15); // centro y zoom inicial
    });

    _obtenerCollar();
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _obtenerUbicacion();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); 
    super.dispose();
  }

  Future<void> _obtenerCollar() async {
    final url = Uri.parse("https://apphuellitas-production.up.railway.app/collar");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_mascota": widget.idMascota}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List collarJson = data["collar"] ?? [];

      if (collarJson.isEmpty) {
        // 👉 Si no viene nada, mostramos el formulario
        _mostrarFormularioRegistroCollar();
      } else {
        setState(() {
          _collar = List<Map<String, dynamic>>.from(collarJson);
          
        });
      }
    } else {
      print("Error al obtener collar: ${response.statusCode}");
    }
  }

  Future<void> _guardarCollar(BuildContext bottomSheetContext) async {
    String codigo = codigoCtrl.text.trim();
    String lat = latCtrl.text.trim();
    String lng = lngCtrl.text.trim();

    // Validaciones
    if (codigo.isEmpty) {
      mostrarMensajeFlotante(
          context,
          "⚠️ Por favor ingresa el código único del collar",
          colorFondo: const Color.fromARGB(255, 243, 243, 243), // verde bonito
          colorTexto: const Color.fromARGB(255, 0, 0, 0),
        );
      return;
    }

    if (lat.isEmpty || double.tryParse(lat) == null) {
       mostrarMensajeFlotante(
          context,
          "⚠️ Por favor ingresa una latitud válida",
          colorFondo: const Color.fromARGB(255, 243, 243, 243), // verde bonito
          colorTexto: const Color.fromARGB(255, 0, 0, 0),
        );
      return;
    }

    if (lng.isEmpty || double.tryParse(lng) == null) {
      mostrarMensajeFlotante(
          context,
          "⚠️ Por favor ingresa una longitud válida",
          colorFondo: const Color.fromARGB(255, 243, 243, 243), // verde bonito
          colorTexto: const Color.fromARGB(255, 0, 0, 0),
        );

      return;
    }

    final latFloat = double.tryParse(lat);
    final lngFloat = double.tryParse(lng);
    
    final url = Uri.parse("https://apphuellitas-production.up.railway.app/registrar_collar");
    
    
    final body = {
      "id_mascota": widget.idMascota,
      "codigo_unico": codigo,
      "latitud": latFloat.toString(),
      "longitud": lngFloat.toString(),
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        Navigator.pop(bottomSheetContext); 
        _obtenerCollar();
      } else {
        mostrarMensajeFlotante(
          context,
          "⚠️ Error al guardar collar: ${response.statusCode}",
          colorFondo: Colors.white,
          colorTexto: Colors.redAccent,
        );
        
      }
    } catch (e) {
      print("Error al guardar collar: $e");
      mostrarMensajeFlotante(
          context,
          "⚠️ Error al guardar collar: $e.",
          colorFondo: Colors.white,
          colorTexto: Colors.redAccent,
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

  Future<void> _obtenerUbicacion() async {
    final url = Uri.parse("https://apphuellitas-production.up.railway.app/ubicacion");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_mascota": widget.idMascota}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List ubicacionJson = data["ubicacion"] ?? [];

      if (ubicacionJson.isNotEmpty) {
        final lat = double.tryParse(ubicacionJson.last["latitud"].toString()) ?? 4.65;
        final lng = double.tryParse(ubicacionJson.last["longitud"].toString()) ?? -74.05;

        setState(() {
          _ultimaPosicion = LatLng(lat, lng);

          _mapController.move(_ultimaPosicion, _mapController.zoom);
        });
      }
    } else {
      print("Error al obtener ubicación: ${response.statusCode}");
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
        children: [
          // Mapa ocupando todo el fondo
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              interactiveFlags: InteractiveFlag.all,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: "com.huellitas.app",
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 40,
                    height: 40,
                    point: _ultimaPosicion,
                    child: const Icon(
                      Icons.pets,
                      size: 40,
                      color: Color.fromARGB(255, 32, 219, 97),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Barra superior personalizada
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  
                  _barraSuperiorConAtras(context),
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
  
  Widget _iconoTop(String asset, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(width: 24, height: 24, child: Image.asset(asset)),
    );
  }


 void _mostrarFormularioRegistroCollar() {
  // InputFormatters
  final codigoFormatter = FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]'));
  final decimalFormatter = FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*'));

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (bottomSheetContext) { // context del BottomSheet
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 25,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TÍTULO
            Center(
              child: Text(
                "Registrar Collar",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 25),

            // CÓDIGO ÚNICO
            Text("Código único del collar",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: codigoCtrl,
              inputFormatters: [codigoFormatter],
              decoration: InputDecoration(
                hintText: "Ej: COL123",
                prefixIcon: Padding(
                  padding: EdgeInsets.all(10),
                  child: Image.asset("assets/collar-de-perro.png", width: 20, height: 20),
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // LATITUD
            Text("Latitud",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: latCtrl,
              keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
              inputFormatters: [decimalFormatter],
              decoration: InputDecoration(
                hintText: "Ej: 4.710989",
                prefixIcon: Padding(
                  padding: EdgeInsets.all(10),
                  child: Image.asset("assets/gps.png", width: 20, height: 20),
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // LONGITUD
            Text("Longitud",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: lngCtrl,
              keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
              inputFormatters: [decimalFormatter],
              decoration: InputDecoration(
                hintText: "Ej: -74.072092",
                prefixIcon: Padding(
                  padding: EdgeInsets.all(10),
                  child: Image.asset("assets/gps.png", width: 20, height: 20),
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 25),

            // BOTÓN GUARDAR
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _guardarCollar(bottomSheetContext),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/Correcto.png',
                      height: 22,
                      width: 22,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Guardar",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  );
}


}
