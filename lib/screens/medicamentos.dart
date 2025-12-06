import 'package:flutter/material.dart';
import 'dart:ui'; // Para aplicar desenfoque si lo necesitas más adelante
import 'package:http/http.dart' as http; 
import 'dart:convert';  
import 'añadirmedicamento.dart';
import 'tarjetamedicamento.dart';
class MedicamentosScreen extends StatefulWidget {
  
  final int id;

  const MedicamentosScreen({super.key, required this.id});
  @override
  State<MedicamentosScreen> createState() => _MedicamentosScreenState();
  
}

class _MedicamentosScreenState extends State<MedicamentosScreen> {
  bool _confirmado = false;
  List<Map<String, dynamic>> _medicamento = [];

  bool _menuAbierto = false; // 👈 define esto en tu StatefulWidget

  void _toggleMenu() {
    setState(() {
      _menuAbierto = !_menuAbierto;
    });
  }

  @override
  void initState() {
    super.initState();
    _obtenerMedicamentos(); // Llamamos a la API apenas se abre la pantalla
  }


  Future<void> _obtenerMedicamentos() async {
    final url = Uri.parse("https://apphuellitas-production.up.railway.app/medicamento");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_mascota": widget.id}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List medicamentoJson = data["medicamento"] ?? [];

      setState(() {
        _medicamento = List<Map<String, dynamic>>.from(medicamentoJson);
      });
    } else {
        print("Error al obtener higiene: ${response.statusCode}");
    }
  }

  String _getImagenHigiene(String? tipo) {
    switch (tipo) {
      case "Vacuna":
        return "assets/Gatoinyeccion.png";
      case "Desparasitación":
        return "assets/purgante.png";
      case "Inyección":
        return "assets/Gatoinyeccion.png";
      case "Antipulgas":
        return "assets/pulgas.png";
      case "Medicamentos":
        return "assets/medigeneral.png";
      case "Vitaminas y suplementos":
        return "assets/vitamina.png";
      default:
        return "assets/usuario.png"; // Imagen por defecto si no coincide
    }
  }

 Color _getColorMedicamentos(String? tipo) {
    switch (tipo) {
      case "Vacuna":
        return const Color.fromARGB(255, 72, 176, 224);
      case "Inyección":
        return const Color.fromARGB(255, 42, 194, 214);
      case "Antipulgas":
        return const Color.fromARGB(255, 248, 121, 133);
      case "Medicamentos":
        return const Color.fromARGB(255, 245, 133, 99);
      case "Desparasitación":
        return const Color.fromARGB(255, 202, 191, 86);
      case "Vitaminas y suplementos":
        return const Color.fromARGB(255, 75, 211, 111);
      default:
        return Colors.grey.shade300;
    }
  }

  Color _getBorderColorMedicamentos(String? tipo) {
    switch (tipo) {
      case "Vacuna":
        return const Color(0xFF0288D1);
      case "Inyección":
        return const Color(0xFF0097A7);
      case "Antipulgas":
        return const Color.fromARGB(255, 229, 56, 56);
      case "Medicamentos":
        return const Color(0xFFD84315);
      case "Desparasitación":
        return const Color.fromARGB(255, 201, 165, 75);
      case "Vitaminas y suplementos":
        return const Color.fromARGB(255, 61, 176, 92);
      default:
        return Colors.grey.shade700;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Botón flotante de chat
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () {
          // TODO: Acción de chat
        },
        child: Image.asset('assets/inteligent.png', width: 36, height: 36),
      ),

      body: Stack(
        children: [
          // 🌄 Imagen de fondo
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
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),

          // 🕶️ Capa oscura para contraste
          Container(
            color: Colors.black.withOpacity(0.3),
          ),

          // Contenido principal
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
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
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Image.asset('assets/Perfil.png'),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Image.asset('assets/Calendr.png'),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Image.asset('assets/Campana.png'),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Ícono de devolver alineado con menú
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

                  Center(
                    child: Stack(
                    children: [
                    // Texto delineado negro
                    Text(
                    "Medicamentos",
                    style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 3
                    ..color = Colors.black,
                    ),
                    ),
                    // Texto blanco encima
                    Text(
                    "Medicamentos",
                    style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    ),
                    ),
                    ],
                    ),
                    ),
                  const SizedBox(height: 30),

                  Column(
                    children: [
                      if (_medicamento.isEmpty)
                        Center(
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.85,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(235, 233, 222, 218),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(blurRadius: 6, color: Colors.black26)
                              ],
                            ),
                            child: Column(
                              children: [
                                Image.asset(
                                  "assets/medi.png",
                                  height: 100,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.error,
                                        size: 80, color: Colors.red);
                                  },
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  "Añade el primer medicamento y lleva el control fácilmente",
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.black),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                     else
                      Column(
                        children: _medicamento.map((item) {
                          return GestureDetector(
                            onTap: () {
                            
                              Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TarjetaMedicamentoScreen(idMascota: widget.id, id_medicamento: item["id_medicamento"], frecuencia: item["frecuencia"], dias_personalizados: item["dias_personalizados"], notas: item["descripcion"] ?? "", tipo: item["tipo"], unidad: item["unidad"], dosis: double.tryParse(item["dosis"].toString()) ?? 0.0, hora: item["hora"], fecha: item["fecha"]),
                              ),
                            );
                            },
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.9,
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(187, 255, 255, 255),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(blurRadius: 6, color: Colors.black26),
                                ],
                              ),
                              child: Container(
                                width: double.infinity,
                                height: 150,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _getColorMedicamentos(item["tipo"]),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _getBorderColorMedicamentos(item["tipo"]),
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.asset(
                                        _getImagenHigiene(item["tipo"]),
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            (item["tipo"] ?? "Sin tipo").toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              shadows: [
                                                Shadow(
                                                  offset: Offset(1.5, 1.5),
                                                  color: Colors.black,
                                                  blurRadius: 2,
                                                ),
                                                Shadow(
                                                  offset: Offset(-1.5, -1.5),
                                                  color: Colors.black,
                                                  blurRadius: 2,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Image.asset('assets/Hora.png',
                                                  width: 20, height: 20),
                                              const SizedBox(width: 8),
                                              Text(
                                                item['hora'] ?? "Sin hora",
                                                style: const TextStyle(fontSize: 16, color: Color.fromARGB(255, 37, 36, 36)),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Image.asset('assets/Calendr.png',
                                                  width: 20, height: 20),
                                              const SizedBox(width: 8),
                                              Text(
                                                item['fecha'] ?? "Sin fecha",
                                                style: const TextStyle(fontSize: 16, color: Color.fromARGB(255, 37, 36, 36)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),


                      const SizedBox(height: 30),

                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AgregarCuidadoScreen(idMascota: widget.id),
                              ),
                            );
                          },
                          icon: Image.asset(
                            'assets/agregar.png', // 🐾 tu imagen personalizada
                            width: 28,  // ajusta el tamaño a tu gusto
                            height: 28,
                          ),
                          label: Stack(
                            children: [
                              // 🔹 Texto negro (borde)
                              Text(
                                "Añadir Medicamento",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  foreground: Paint()
                                    ..style = PaintingStyle.stroke
                                    ..strokeWidth = 2
                                    ..color = Colors.black,
                                ),
                              ),
                              // 🔹 Texto blanco encima
                              const Text(
                                "Añadir Medicamento",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(235, 233, 222, 218),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
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
}
