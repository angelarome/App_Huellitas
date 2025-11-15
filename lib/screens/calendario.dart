import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:ui';

class CalendarioEventosScreen extends StatefulWidget {
  const CalendarioEventosScreen({super.key});

  @override
  State<CalendarioEventosScreen> createState() => _CalendarioEventosScreenState();
}

class _CalendarioEventosScreenState extends State<CalendarioEventosScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 85, 151, 227),
        onPressed: () {
          // TODO: Acción de chat
        },
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
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),

          // Contenido
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado con íconos
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

                  // Título
                  const Center(
                    child: Text(
                      "Calendario",
                      style: TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tarjeta blanca con calendario interactivo
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(235, 255, 255, 255),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black26)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TableCalendar(
                          locale: 'es_ES', //  Idioma español
                          focusedDay: _focusedDay,
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          calendarFormat: CalendarFormat.month,
                          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                          calendarStyle: const CalendarStyle(
                            todayDecoration: BoxDecoration(
                              color: Colors.blueAccent, // dia actual
                              shape: BoxShape.circle,
                            ),
                            selectedDecoration: BoxDecoration(
                              color: Colors.brown, // dia de eleccion
                              shape: BoxShape.circle,
                            ),
                            weekendTextStyle: TextStyle(color: Colors.red),
                          ),
                          daysOfWeekStyle: const DaysOfWeekStyle(
                            weekendStyle: TextStyle(color: Colors.red),
                          ),
                          headerStyle: const HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Próximos eventos
                        const Text(
                          "Próximos eventos",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 56, 143, 201),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color.fromARGB(255, 131, 123, 99), width: 2),
                          ),
                          child: Row(
                            children: [
                              Image.asset('assets/vacuna.png', width: 40, height: 40),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    "Vacuna",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "23 de Octubre",
                                    style: TextStyle(fontSize: 16, color: Colors.white),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "10:00 a.m",
                                    style: TextStyle(fontSize: 16, color: Colors.white),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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