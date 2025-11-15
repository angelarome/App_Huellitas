import 'dart:convert';
import 'package:http/http.dart' as http;

class IaService {
  static const String _url = "http://localhost:5000/chat";

  static Future<String> enviarMensaje(String mensaje) async {
    try {
      print('🤖 Enviando mensaje a FirulAI: $mensaje');
      
      final response = await http.post(
        Uri.parse(_url),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({"mensaje": mensaje}),
      ).timeout(Duration(seconds: 50)); // segundos para que ia responda

      print('📨 Respuesta HTTP: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data.containsKey("respuesta")) {
          print('✅ Respuesta recibida de FirulAI');
          return data["respuesta"];
        } else if (data.containsKey("error")) {
          print('❌ Error en la respuesta: ${data["error"]}');
          return "❌ FirulAI tiene un problema: ${data["error"]}";
        } else {
          return "❌ Respuesta inesperada de FirulAI";
        }
      } else {
        final errorData = jsonDecode(response.body);
        return "❌ Error del servidor: ${errorData['error'] ?? 'Código ${response.statusCode}'}";
      }
    } on http.ClientException catch (e) {
      print('🌐 Error de conexión: $e');
      return "🔌 No se pudo conectar con FirulAI. Verifica que:\n• Flask esté corriendo (python app.py)\n• Ollama esté ejecutándose (ollama serve)";
    } on Exception catch (e) {
      print('💥 Error general: $e');
      return "😔 Ocurrió un error inesperado: $e";
    }
  }

  // 🔥 NUEVO: Método para verificar el estado
  static Future<Map<String, dynamic>> verificarEstadoOllama() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:5000/ollama-status"),
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"status": "error", "message": "No se pudo verificar el estado"};
      }
    } catch (e) {
      return {"status": "error", "message": "Error de conexión: $e"};
    }
  }
}