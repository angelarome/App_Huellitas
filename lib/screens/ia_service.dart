import 'dart:convert';
import 'package:http/http.dart' as http;

class IaService {
  static const String _apiKey = "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";
  static const String _url = "https://api.groq.com/openai/v1/chat/completions";

  static Future<String> enviarMensaje(String mensaje) async {
    final response = await http.post(
      Uri.parse(_url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $_apiKey",
      },
      body: jsonEncode({
        "model": "openai/gpt-oss-120b",
        "messages": [
          {"role": "user", "content": mensaje}
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["choices"][0]["message"]["content"];
    } else {
      return "Error: ${response.body}";
    }
  }
}
