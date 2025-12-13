import 'package:flutter/material.dart';
import 'dart:ui'; // Para aplicar desenfoque si lo necesitas más adelante
import 'mascota.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Para jsonEncode y base64Encode
import 'package:flutter/services.dart';
import 'perfil_mascota.dart';
import 'compartirmascota.dart';
import 'calendario.dart';
import 'menu_lateral.dart';
import '1pantalla.dart';

class MiMascotaScreen extends StatefulWidget {
  final int id_dueno;
  final String cedula;
  final String nombreUsuario;
  final String apellidoUsuario;
  final String telefono;
  final String direccion;
  final Uint8List fotoPerfil;
  final String departamento;
  final String ciudad;

  const MiMascotaScreen({super.key, required this.id_dueno, required this.cedula,
    required this.nombreUsuario,
    required this.apellidoUsuario,
    required this.telefono,
    required this.direccion,
    required this.fotoPerfil,
    required this.departamento,
    required this.ciudad,});

  @override
  _MiMascotaScreenState createState() => _MiMascotaScreenState();
  
}

class _MiMascotaScreenState extends State<MiMascotaScreen> {
  @override
  void initState() {
    super.initState();
    mascotas = [];
    _obtenerMascotas(); // Llamamos a la API apenas se abre la pantalla
  }

  bool _menuAbierto = false; // 👈 define esto en tu StatefulWidget

  void _toggleMenu() {
    setState(() {
      _menuAbierto = !_menuAbierto;
    });
  }

  List<Map<String, dynamic>> mascotas = [];
  bool cargando = true;
  // 🔹 Función para calcular la edad
  String calcularEdad(String fechaStr) {
    final fecha = DateTime.parse(fechaStr);
    final ahora = DateTime.now();
    int edad = ahora.year - fecha.year;
    if (ahora.month < fecha.month || (ahora.month == fecha.month && ahora.day < fecha.day)) {
      edad--;
    }
    return "$edad años";
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
      mascotas = mascotasJson.map<Map<String, dynamic>>((m) {
        if (m["imagen_perfil"] != null && m["imagen_perfil"].isNotEmpty) {
          try {
            m["foto"] = base64Decode(m["imagen_perfil"]);
          } catch (e) {
            print("❌ Error decodificando imagen: $e");
            m["foto"] = null;
          }
        }
        return Map<String, dynamic>.from(m);
      }).toList();
      cargando = false;
    });
  } else {
    setState(() => cargando = false);
    print("Error al obtener mascotas: ${response.statusCode}");
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
        child: Image.asset(
          'assets/inteligent.png',
          width: 36,
          height: 36,
        ),
      ),

      body: Stack(
        children: [
          // 🌄 Imagen de fondo
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/fall-8404115_1280.jpg"),
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

          // 🧱 Contenido principal
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [

                  _barraSuperiorConAtras(context),

                  // Título centrado
                  const Center(
                    child: Text(
                      "Mis Mascotas",
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

                  Column(
                    children: [
                      if (mascotas.isEmpty)
                        // Contenedor de lista vacía
                        Center(
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.85,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(235, 233, 222, 218),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(blurRadius: 6, color: Colors.black26),
                              ],
                            ),
                            child: Column(
                              children: [
                                Image.asset(
                                  "assets/cuidado-de-mascotas-sinfondo.png",
                                  height: 100,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  "Tu lista de mascotas está vacía",
                                  style: TextStyle(fontSize: 18, color: Colors.black),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                    
                        SingleChildScrollView(
                          child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(233, 245, 232, 232),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ...mascotas.map((m) => Container(
                                    margin: const EdgeInsets.symmetric(vertical: 8),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: m["sexo"] == "Macho"
                                          ? const Color.fromARGB(255, 76, 162, 255)
                                          : const Color.fromARGB(255, 255, 105, 180),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: m["sexo"] == "Macho"
                                            ? const Color.fromARGB(255, 28, 106, 190)
                                            : const Color.fromARGB(255, 219, 44, 131),
                                        width: 2,
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(50),
                                          child: m["foto"] != null
                                              ? Image.memory(
                                                  m["foto"],
                                                  width: 70,
                                                  height: 70,
                                                  fit: BoxFit.cover,
                                                )
                                              : const SizedBox(width: 70, height: 70),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                (m["nombre"] ?? "Nombre no disponible")
                                                    .toString()
                                                    .toUpperCase(),
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
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Image.asset(
                                                    m["especies"] == "Perro"
                                                        ? 'assets/Perrocafe.png'
                                                        : m["especies"] == "Gato"
                                                            ? 'assets/gato-negro.png'
                                                            : m["especies"] == "Conejo"
                                                                ? 'assets/conejo1.png'
                                                                : m["especies"] == "Ave"
                                                                    ? 'assets/guacamayo.png'
                                                                    : 'assets/masmascotas.png',
                                                    width: 20,
                                                    height: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    m["especies"] ?? "Especie no disponible",
                                                    style: const TextStyle(fontSize: 16, color: Colors.white),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Image.asset(
                                                    m["sexo"] == "Macho"
                                                        ? 'assets/masculino.png'
                                                        : 'assets/mujer.png',
                                                    width: 20,
                                                    height: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    m["sexo"] ?? "Sexo no disponible",
                                                    style: const TextStyle(fontSize: 16, color: Colors.white),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Image.asset(
                                                    'assets/pastel-de-cumpleanos.png',
                                                    width: 20,
                                                    height: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    m["fecha_nacimiento"] != null
                                                        ? calcularEdad(m["fecha_nacimiento"])
                                                        : "Edad no disponible",
                                                    style: const TextStyle(fontSize: 16, color: Colors.white),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: Image.asset(
                                            'assets/lupa.png',
                                            width: 40,
                                            height: 40,
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ServiciosScreen(
                                                  id_dueno: widget.id_dueno,
                                                  idMascota: m["id_mascotas"] ?? m["id_mascotas"], // o el nombre del campo que uses
                                                  nombreMascota: m["nombre"],
                                                  fotoMascota: m["foto"], // ya está como Uint8List
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  )).toList(),
                            ],
                          ),
                        ),
                  )],
                  ),

                  const SizedBox(height: 20),

                  // Botón Añadir Mascotas
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AgregarMascotaScreen(
                              id_dueno: widget.id_dueno, cedula: widget.cedula, nombreUsuario: widget.nombreUsuario, apellidoUsuario: widget.apellidoUsuario, telefono: widget.telefono, direccion: widget.direccion, fotoPerfil: widget.fotoPerfil, departamento: widget.departamento, ciudad: widget.ciudad
                            ),
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
                            "Añadir Mascotas",
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
                            "Añadir Mascotas",
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
                    )
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Pantalla1(id: widget.id_dueno, cedula: widget.cedula, nombreUsuario: widget.nombreUsuario, apellidoUsuario: widget.apellidoUsuario, telefono: widget.telefono, direccion: widget.direccion, fotoPerfil: widget.fotoPerfil, departamento: widget.departamento, ciudad: widget.ciudad),
                ),
              );
            },
          ),
        ),
      ),
    ],
  );
}
  
}