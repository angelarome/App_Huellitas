import 'package:flutter/material.dart';
import 'dart:ui';

// 🔹 Importa ChatBubble
import 'chat_bubble.dart';

// 🔹 Importa IaService
import 'ia_service.dart';


class IaMascotasScreen extends StatefulWidget {
  const IaMascotasScreen({super.key});

  @override
  State<IaMascotasScreen> createState() => _IaMascotasScreenState();
}

class _IaMascotasScreenState extends State<IaMascotasScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _mensajes = [];

  bool _cargando = false;

  Future<void> _enviarMensaje() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;

    setState(() {
      _mensajes.add({"texto": texto, "esUsuario": true});
      _controller.clear();
      _cargando = true;
    });

    try {
      final respuesta = await IaService.enviarMensaje(texto);
      setState(() {
        _mensajes.add({"texto": respuesta, "esUsuario": false});
      });
    } catch (e) {
      setState(() {
        _mensajes.add({"texto": "Error al conectar con la IA 😔", "esUsuario": false});
      });
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/inicio.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),

          SafeArea(
            child: Stack(
              children: [
                // Botón volver
                Positioned(
                  top: 16,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Image.asset("assets/devolver5.png", width: 40, height: 40),
                  ),
                ),

                // Tarjeta principal
                Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.95,
                    height: MediaQuery.of(context).size.height * 0.75,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black26)],
                    ),
                    child: Column(
                      children: [
                        // Encabezado
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[700],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Image.asset("assets/asistenterobot.png", width: 30, height: 30),
                              const SizedBox(width: 8),
                              const Text(
                                "FirulAI",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Chat
                        Expanded(
                          child: ListView(
                            children: [
                              for (final msg in _mensajes)
                                ChatBubble(message: msg["texto"], isUser: msg["esUsuario"]),
                              if (_cargando)
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.blue[700],
                                        radius: 16,
                                        child: Icon(Icons.pets, color: Colors.white, size: 16),
                                      ),
                                      SizedBox(width: 8),
                                      Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                            SizedBox(width: 8),
                                            Text("FirulAI está escribiendo... 🐶"),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Campo de texto
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                decoration: InputDecoration(
                                  hintText: "Pregunta lo que quieras 🐾",
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_upward, color: Colors.white),
                                onPressed: _enviarMensaje,
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
          ),
        ],
      ),
    );
  }
}
