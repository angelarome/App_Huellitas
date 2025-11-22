import 'package:flutter/material.dart';
import 'registrarse.dart';
import 'agregarveterinaria.dart';
import 'agregarveterinaria.dart';
import 'agregartienda.dart';
import 'agregarpaseador.dart';
import 'dart:ui';

class Rol1Screen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          
          
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                
                image: AssetImage('assets/inicio.png'), // ← Ruta editable
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.3),
                  BlendMode.darken,
                ),
              ),
            ),
          ),

          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
          
          // Botones superiores: Devolver y Ayuda
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Image.asset(
                    'assets/devolver5.png',
                    width: 32,
                    height: 32,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: Colors.white,
                          title: Text(
                            '¿Qué significan los roles?',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          content: SingleChildScrollView(
                            child: Text(
                              'Los roles representan el papel que desea desempeñar el usuario en la App Huellitas.\n\n'
                              '🐶 Dueño: Usuario normal donde se podrán crear recordatorios como baños, manicure, paseos, citas, etc.\n\n'
                              '🩺 Veterinaria: Para los usuarios que tengan una veterinaria, se podrá agregar una veterinaria con su respetiva información.\n\n'
                              '🛍️ Tienda: Para aquellos usuarios que tengan una tienda que venda productos para mascotas, se podrá agregar con su respetiva información.\n\n'
                              '🚶 Paseador: Para aquellos usuarios que deseen trabajar como paseadores, se podrán registrar y utilizar los servicios correspondientes.',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          actions: [
                            TextButton(
                              child: Text('Cerrar'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Image.asset(
                    'assets/ayudar.jpg',
                    width: 32,
                    height: 32,
                  ),
                ),
              ],
            ),
          ),

          // Contenido centrado
          SizedBox.expand(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // ← Centrado vertical
                  children: [
                    SizedBox(height: 20), // Espacio para subir el texto
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¡Elige tu perfil en Huellitas!',
                          style: TextStyle(
                            fontSize: 30,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8), // Espacio entre texto e ícono
                        Image.asset(
                          'assets/huella.png', // si el icono es muy grande se le puede bajar al tamaño o borrar el icono y a lado del texto pegar esto == 🐾
                          width: 40, 
                          height: 40,
                        ),
                      ],
                    ),
                    SizedBox(height: 40),
                    ServicioButton(
                      color: Colors.lightBlue,
                      text: 'Dueño',
                      iconPath: 'assets/Mismascotas.png',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RegistroUsuarioPage()),
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    ServicioButton(
                      color: Colors.green,
                      text: 'Veterinaria',
                      iconPath: 'assets/Medico.png',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AgregarVeterinariaScreen()),
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    ServicioButton(
                      color: Colors.purpleAccent,
                      text: 'Tienda',
                      iconPath: 'assets/Mitienda.png',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AgregarTiendaScreen()),
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    ServicioButton(
                      color: Colors.redAccent,
                      text: 'Paseador',
                      iconPath: 'assets/paseador-de-perros.png',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Agregarpaseador()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ServicioButton extends StatelessWidget {
  final Color color;
  final String text;
  final String iconPath;
  final VoidCallback onPressed;

  const ServicioButton({
    required this.color,
    required this.text,
    required this.iconPath,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: Size(double.infinity, 80), // tamaño tarjeta
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
      onPressed: onPressed,
      child: Row(
        children: [
          Image.asset(
            iconPath,
            width: 45, // tamaño icono
            height: 45,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.white, fontSize: 22), // tamaño texto
            ),
          ),
        ],
      ),
    );
  }
}