import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '1pantalla.dart';
import 'veterinaria2.dart';
import 'mitienda2.dart';
import 'mipaseador2.dart';
import 'inicial1.dart';
import 'dart:typed_data';

class InitScreen extends StatefulWidget {
  const InitScreen({super.key});

  @override
  State<InitScreen> createState() => _InitScreenState();
}

class _InitScreenState extends State<InitScreen> {
  @override
  void initState() {
    super.initState();
    _verificarSesion();
  }

  Future<void> _verificarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final logueado = prefs.getBool('logueado') ?? false;

    if (logueado) {
      // Revisa qué tipo de usuario está logueado
      if (prefs.containsKey('idUsuario')) {
        // Dueño
        final id = prefs.getInt('idUsuario')!;
        // Aquí puedes cargar más datos si los guardaste (nombre, foto, etc.)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Pantalla1(
              id: id,
              cedula: '', // opcional si guardaste
              nombreUsuario: '',
              apellidoUsuario: '',
              telefono: '',
              direccion: '',
              fotoPerfil: Uint8List(0),
              departamento: '',
              ciudad: '',
            ),
          ),
        );
      } else if (prefs.containsKey('idVeterinaria')) {
        final id = prefs.getInt('idVeterinaria')!;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PerfilVeterinariaScreen(id_veterinaria: id),
          ),
        );
      } else if (prefs.containsKey('idTienda')) {
        final id = prefs.getInt('idTienda')!;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PerfilTiendaScreen(idtienda: id),
          ),
        );
      } else if (prefs.containsKey('idPaseador')) {
        final id = prefs.getInt('idPaseador')!;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PerfilPaseadorScreen(id_paseador: id),
          ),
        );
      } else {
        // No hay info, vamos a login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const InicioScreen(),
          ),
        );
      }
    } else {
      // No logueado, vamos a login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const InicioScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
