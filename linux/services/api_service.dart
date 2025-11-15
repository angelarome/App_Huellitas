import 'dart:convert';
import 'dart:ffi';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://localhost:5000";

  static Future<List<dynamic>> getUsuarios() async {
    final response = await http.get(Uri.parse("$baseUrl/usuarios"));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al obtener usuarios");
    }
  }

  // Registrar un nuevo usuario
  static Future<Map<String, dynamic>> registrarUsuario({
    required String cedula,
    required String nombre,
    required String apellido,
    required String telefono,
    required String correo,
    required String direccion,
    required String contrasena,
    String? imagenBase64,
  }) async {
    final url = Uri.parse("$baseUrl/registrar");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "cedula": cedula,
        "nombre": nombre,
        "apellido": apellido,
        "telefono": telefono,
        "correo": correo,
        "direccion": direccion,
        "contrasena": contrasena,
        "imagen": imagenBase64,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body)["usuario"];
    } else {
      throw Exception("Error al obtener usuarios");
    }
  }

  
  static Future<Map<String, dynamic>?> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    final url = Uri.parse("$baseUrl/login");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "correo": correo,
        "contrasena": contrasena,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)["usuario"];
    } else {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> RecuperarContrasena({
    required String correo,
  }) async {
    final url = Uri.parse("$baseUrl/recuperarcontrasena");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "correo": correo
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)["usuario"];
    } else {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> ObtenerCodigo({
    required String correo,
  }) async {
    final url = Uri.parse("$baseUrl/codigo");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"correo": correo}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // <-- devuelve todo el mapa
    } else {
      return null;
    }
  }


  static Future<bool> actualizarImagen({
    required int id,
    required String imagenBase64,
  }) async {
    final url = Uri.parse("$baseUrl/actualizar_imagen");

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id": id,
        "foto_perfil": imagenBase64,
      }),
    );

    return response.statusCode == 200;
  }

  static Future<bool> actualizar_imagen_mascota({
    required String idMascota,
    required String imagenBase64,
  }) async {
    final url = Uri.parse("$baseUrl/actualizar_imagen_mascota");

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "idMascota": idMascota,
        "fotoMascota": imagenBase64,
      }),
    );

    return response.statusCode == 200;
  }

  // Registrar un nuevo usuario
  static Future<Map<String, dynamic>> registrarMascota({
    required String nombre,
    required String apellido,
    required String raza,
    required String genero,
    required String peso,
    required String especie,
    DateTime? fechaNacimiento, 
    String? imagenBase64,
    required String esterilizado,
    required int id_dueno
  }) async {
    final url = Uri.parse("$baseUrl/registrarMascota");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "nombre": nombre,
        "apellido": apellido,
        "raza": raza,
        "genero": genero,
        "peso": peso,
        "especie": especie,
        "fecha_nacimiento": fechaNacimiento?.toIso8601String(),
        "imagen": imagenBase64,
        "esterilizado": esterilizado,
        "id_dueno": id_dueno,
      }),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body)["mascota"];
    } else {
      throw Exception("Error al registrar mascota");
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerMascotas({
    required int id_dueno,
  }) async {
    final url = Uri.parse("$baseUrl/mascotas");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_dueno": id_dueno}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List mascotas = data["mascotas"] ?? [];
      // Convertimos cada elemento a Map<String, dynamic>
      return mascotas.map<Map<String, dynamic>>((m) => Map<String, dynamic>.from(m)).toList();
    } else {
      // Retornamos lista vacía si no hay datos o error
      return [];
    }
  }


  static Future<List<Map<String, dynamic>>> obtenerHigiene({
    required int id,
  }) async {
    final url = Uri.parse("$baseUrl/higiene");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_mascota": id}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List higiene = data["higiene"] ?? [];
      // Convertimos cada elemento a Map<String, dynamic>
      return higiene.map<Map<String, dynamic>>((h) => Map<String, dynamic>.from(h)).toList();
    } else {
      // Retornamos lista vacía si no hay datos o error
      return [];
    }
  }
  
  static Future<Map<String, dynamic>> registrarHigiene({
    required String id,
    required String frecuencia,
    required String notas,
    required String tipo,
    required String fecha,
    required String hora,
  }) async {
    final url = Uri.parse("$baseUrl/registrarHigiene");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id": id,
        "frecuencia": frecuencia,
        "notas": notas,
        "tipo": tipo,
        "fecha": fecha,
        "hora": hora,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body)["higiene"];
    } else {
      throw Exception("Error al registrar higiene");
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerMascotasPorId({required int id_mascota}) async {
    final url = Uri.parse("$baseUrl/obtenermascota");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_mascota": id_mascota}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List mascotas = data["mascotas"] ?? [];
      // Convertimos todos los elementos a Map<String, dynamic>
      return mascotas.map<Map<String, dynamic>>(
        (m) => Map<String, dynamic>.from(m),
      ).toList();
    } else {
      return []; // Retornamos lista vacía si hay error
    }
  }


  static Future<bool> eliminarHigiene({
  required String idMascota,
  required String idHigiene,
  }) async {
    final url = Uri.parse("$baseUrl/eliminar_higiene");

    final response = await http.delete(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "idMascota": idMascota,
        "idHigiene": idHigiene,
      }),
    );

    // Retorna true si se eliminó correctamente (HTTP 200)
    return response.statusCode == 200;
  }

  static Future<bool> actualizar_higiene({
    required String idHigiene,
    required String frecuencia,
    required String notas,
    required String tipo,
    required String fecha,
    required String hora,
  }) async {
    final url = Uri.parse("$baseUrl/actualizar_higiene");

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id_higiene": idHigiene,
        "frecuencia": frecuencia,
        "notas": notas,
        "tipo": tipo,
        "fecha": fecha,
        "hora": hora,
          
      }),

    );
    

    return response.statusCode == 200;
  }

  static Future<List<Map<String, dynamic>>> obtenerMiTienda({
    required int id,
  }) async {
    final url = Uri.parse("$baseUrl/mitienda");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id": id}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List tienda = data["tienda"] ?? [];
      // Convertimos cada elemento a Map<String, dynamic>
      return tienda.map<Map<String, dynamic>>((h) => Map<String, dynamic>.from(h)).toList();
    } else {
      // Retornamos lista vacía si no hay datos o error
      return [];
    }
  }
  
  static Future<Map<String, dynamic>> registrarTienda({
    required String cedulaUsuario,
    required String imagen,
    required String nombre_negocio,
    required String descripcion,
    required String direccion,
    required String telefono,
    required String domicilio,
    required String horariolunesviernes,
    required String cierrelunesviernes,
    required String horariosabado,
    required String cierrehorasabado,
    required String horariodomingos,
    required String cierredomingos,
    required String metodopago,
    required String correo,
    required String contrasena,
  }) async {
    final url = Uri.parse("$baseUrl/registrarTienda");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "cedulaUsuario": cedulaUsuario,
        "imagen": imagen, 
        "nombre_negocio": nombre_negocio,
        "descripcion": descripcion,
        "direccion": direccion, 
        "telefono": telefono,
        "domicilio": domicilio,
        "horariolunesviernes": horariolunesviernes,
        "cierrelunesviernes": cierrelunesviernes,
        "horariosabado": horariosabado,
        "cierrehorasabado": cierrehorasabado,
        "horariodomingos": horariodomingos,
        "cierredomingos": cierredomingos,
        "metodopago": metodopago,
        "correo": correo,
        "contrasena": contrasena,

      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body)["mitienda"];
    } else {
      throw Exception("Error al registrar tienda");
    }

    
  }

  static Future<bool> actualizar_imagen_tienda({
    required int id,
    required String imagenBase64,
  }) async {
    final url = Uri.parse("$baseUrl/actualizar_imagen_tienda");

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id": id,
        "imagen": imagenBase64,
      }),
    );

    return response.statusCode == 200;
  }

  static Future<List<Map<String, dynamic>>> obtenerComentarios({
    required String id_tienda,
  }) async {
    final url = Uri.parse("$baseUrl/comentariosTienda");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_tienda": id_tienda}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List calificacion= data["calificacion"] ?? [];
      // Convertimos cada elemento a Map<String, dynamic>
      return calificacion.map<Map<String, dynamic>>((calificacion) => Map<String, dynamic>.from(calificacion)).toList();
    } else {
      // Retornamos lista vacía si no hay datos o error
      return [];
    }
  
  }

  static Future<List<Map<String, dynamic>>> obtenerUsuario({
    required int id_dueno,
  }) async {
    final url = Uri.parse("$baseUrl/obtenerUsuario");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_dueno": id_dueno}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List usuario = data["usuario"] ?? [];
      // Convertimos cada elemento a Map<String, dynamic>
      return usuario.map<Map<String, dynamic>>((m) => Map<String, dynamic>.from(m)).toList();
    } else {
      // Retornamos lista vacía si no hay datos o error
      return [];
    }
  }
  
  static Future<Map<String, dynamic>> obtenerPromedioTienda(int idTienda) async {
    final url = Uri.parse("$baseUrl/promedioTienda");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id_tienda": idTienda}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          "promedio": (data["promedio"] ?? 0).toDouble(),
          "total": data["total"] ?? 0
        };
      } else {
        return {"promedio": 0.0, "total": 0};
      }
    } catch (e) {
      print("Error al obtener promedio: $e");
      return {"promedio": 0.0, "total": 0};
    }
  }

  static Future<bool> like_comentario({
    required String id,
    required String like,
  }) async {
    final url = Uri.parse("$baseUrl/likeComentario");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id": id,
        "like": like,
      }),
    );

    return response.statusCode == 200;
  }

  static Future<List<Map<String, dynamic>>> obtenerMipaseador({
    required int id_paseador
  }) async {
    final url = Uri.parse("$baseUrl/mipaseador");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_paseador": id_paseador}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List paseador = data["paseador"] ?? [];
      // Convertimos cada elemento a Map<String, dynamic>
      return paseador.map<Map<String, dynamic>>((h) => Map<String, dynamic>.from(h)).toList();
    } else {
      // Retornamos lista vacía si no hay datos o error
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerTienda(
  ) async {
    final response = await http.get(Uri.parse("$baseUrl/tiendas"));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List tienda = data["tienda"] ?? [];
      // Convertimos cada elemento a Map<String, dynamic>
      return tienda.map<Map<String, dynamic>>((h) => Map<String, dynamic>.from(h)).toList();
    } else {
      // Retornamos lista vacía si no hay datos o error
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerVeterinaria(
  ) async {
    final response = await http.get(Uri.parse("$baseUrl/veterinarias"));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List tienda = data["veterinaria"] ?? [];
      // Convertimos cada elemento a Map<String, dynamic>
      return tienda.map<Map<String, dynamic>>((h) => Map<String, dynamic>.from(h)).toList();
    } else {
      // Retornamos lista vacía si no hay datos o error
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerPaseadores(
  ) async {
    final response = await http.get(Uri.parse("$baseUrl/paseadores"));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List tienda = data["paseador"] ?? [];
      // Convertimos cada elemento a Map<String, dynamic>
      return tienda.map<Map<String, dynamic>>((h) => Map<String, dynamic>.from(h)).toList();
    } else {
      // Retornamos lista vacía si no hay datos o error
      return [];
    }
  }

  static Future<Map<String, dynamic>> registrarVeterinaria({
    required String cedulaUsuario,
    required String imagen,
    required String nombre_veterinaria,
    required String descripcion,
    required String experiencia,
    required String direccion,
    required String telefono,
    required String domicilio,
    required String horariolunesviernes,
    required String cierrelunesviernes,
    required String horariosabado,
    required String cierrehorasabado,
    required String horariodomingos,
    required String cierredomingos,
    required String metodopago,
    required String certificado,
    required String tarifa,
    required String correo,
    required String contrasena,
  }) async {
    final url = Uri.parse("$baseUrl/registrarVeterinaria");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "cedulaUsuario": cedulaUsuario,
        "imagen": imagen, 
        "nombre_veterinaria": nombre_veterinaria,
        "descripcion": descripcion,
        "experiencia": experiencia,
        "direccion": direccion,
        "telefono": telefono,
        "domicilio": domicilio,
        "horariolunesviernes": horariolunesviernes,
        "cierrelunesviernes": cierrelunesviernes,
        "horariosabado": horariosabado,
        "cierrehorasabado": cierrehorasabado,
        "horariodomingos": horariodomingos,
        "cierredomingos": cierredomingos,
        "metodopago": metodopago,
        "certificado": certificado,
        "tarifa": tarifa,
        "correo": correo,
        "contrasena": contrasena,

      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body)["miveterinaria"];
    } else {
      throw Exception("Error al registrar veterinaria");
    }

    
  }

  static Future<List<Map<String, dynamic>>> obtenerMiVetenaria({
    required String id,
  }) async {
    final url = Uri.parse("$baseUrl/miveterinaria");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id": id}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List veterinaria = data["veterinaria"] ?? [];
      // Convertimos cada elemento a Map<String, dynamic>
      return veterinaria.map<Map<String, dynamic>>((h) => Map<String, dynamic>.from(h)).toList();
    } else {
      // Retornamos lista vacía si no hay datos o error
      return [];
    }
  }

  static Future<bool> actualizar_imagen_veterinaria({
    required int id,
    required String imagenBase64,
  }) async {
    final url = Uri.parse("$baseUrl/actualizar_imagen_veterinaria");

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id": id,
        "imagen": imagenBase64,
      }),
    );

    return response.statusCode == 200;
  }

  static Future<List<Map<String, dynamic>>> obtener_comentariosVeterinaria({
    required String id,
  }) async {
    final url = Uri.parse("$baseUrl/comentariosVeterinaria");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_veterinaria": id}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List calificacion= data["calificacion"] ?? [];
      // Convertimos cada elemento a Map<String, dynamic>
      return calificacion.map<Map<String, dynamic>>((calificacion) => Map<String, dynamic>.from(calificacion)).toList();
    } else {
      // Retornamos lista vacía si no hay datos o error
      return [];
    }
  
  }

  
  static Future<Map<String, dynamic>> promedio_veterinaria(int id) async {
    final url = Uri.parse("$baseUrl/promedioVeterinaria");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id_veterinaria": id}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          "promedio": (data["promedio"] ?? 0).toDouble(),
          "total": data["total"] ?? 0
        };
      } else {
        return {"promedio": 0.0, "total": 0};
      }
    } catch (e) {
      print("Error al obtener promedio: $e");
      return {"promedio": 0.0, "total": 0};
    }
  }

  static Future<bool> like_comentarioVeterinaria({
    required String id,
    required String like,
  }) async {
    final url = Uri.parse("$baseUrl/likeComentarioVeterinaria");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id": id,
        "like": like,
      }),
    );

    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> registrarProducto({
    required Int tienda_id,
    required String nombre,
    required String precio,
    required String cantidad,
    required String descripcion,
    required String imagen,
  }) async {
    final url = Uri.parse("$baseUrl/registrarProducto");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "tienda_id": tienda_id,
        "nombre": nombre,
        "precio": precio,
        "cantidad": cantidad,
        "descripcion": descripcion,
        "imagen": imagen,

      }),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body)["producto"];
    } else {
      throw Exception("Error al registrar producto");
    }
  }


  static Future<List<Map<String, dynamic>>> obtenerProductos({
    required int id_tienda,
  }) async {
    final url = Uri.parse("$baseUrl/misproductos");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_tienda": id_tienda}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List producto = data["producto"] ?? [];
      // Convertimos cada elemento a Map<String, dynamic>
      return producto.map<Map<String, dynamic>>((h) => Map<String, dynamic>.from(h)).toList();
    } else {
      // Retornamos lista vacía si no hay datos o error
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerCitas_veterinaria({
    required int id_veterinaria,
  }) async {
    final url = Uri.parse("$baseUrl/citasVeterinaria");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_veterinaria": id_veterinaria}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List citas = data["citas"] ?? [];
      // Convertimos cada elemento a Map<String, dynamic>
      return citas.map<Map<String, dynamic>>((h) => Map<String, dynamic>.from(h)).toList();
    } else {
      // Retornamos lista vacía si no hay datos o error
      return [];
    }
  }

  static Future<bool> aceptar_cita_medica({
    required int id,
    required String fecha,
    required String hora,
  }) async {
    final url = Uri.parse("$baseUrl/aceptar_cita_medica");

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id": id,
        "fecha": fecha,
        "hora": hora,
      }),
    );

    return response.statusCode == 200;
  }

  static Future<bool> cancelar_cita_medica({
    required int id,
  }) async {
    final url = Uri.parse("$baseUrl/cancelar_cita_medica");

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id": id,
      }),
    );

    return response.statusCode == 200;
  }

  static Future<bool> actualizar_tienda({
    required int id,
    required String cedulaUsuario,
    required String imagen,
    required String nombre_negocio,
    required String descripcion,
    required String direccion,
    required String telefono,
    required String domicilio,
    required String horariolunesviernes,
    required String cierrelunesviernes,
    required String horariosabado,
    required String cierrehorasabado,
    String? horariodomingos, // ⬅️ ahora puede ser null
    String? cierredomingos,  // ⬅️ ahora puede ser null
    required String metodopago,
  }) async {
    final url = Uri.parse("$baseUrl/actualizarTienda");

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id": id,
        "cedulaUsuario": cedulaUsuario,
        "imagen": imagen, 
        "nombre_negocio": nombre_negocio,
        "descripcion": descripcion,
        "telefono": telefono,
        "domicilio": domicilio,
        "horariolunesviernes": horariolunesviernes,
        "cierrelunesviernes": cierrelunesviernes,
        "horariosabado": horariosabado,
        "cierrehorasabado": cierrehorasabado,
        "horariodomingos": horariodomingos,
        "cierredomingos": cierredomingos,
        "metodopago": metodopago,       
      }),

    );
    

    return response.statusCode == 200;
  }

  static Future<bool> actualizar_veterinaria({
    required String id,
    required String cedulaUsuario,
    required String imagen,
    required String nombre_veterinaria,
    required String descripcion,
    required String experiencia,
    required String direccion,
    required String telefono,
    required String domicilio,
    required String horariolunesviernes,
    required String cierrelunesviernes,
    required String horariosabado,
    required String cierrehorasabado,
    String? horariodomingos, // ⬅️ ahora puede ser null
    String? cierredomingos,  // ⬅️ ahora puede ser null
    required String metodopago,
    required String certificado,
    required String tarifa,
  }) async {
    final url = Uri.parse("$baseUrl/actualizarVeterinaria");

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id": id,
        "cedulaUsuario": cedulaUsuario,
        "imagen": imagen, 
        "nombre_veterinaria": nombre_veterinaria,
        "descripcion": descripcion,
        "experiencia": experiencia,
        "direccion": direccion,
        "telefono": telefono,
        "domicilio": domicilio,
        "horariolunesviernes": horariolunesviernes,
        "cierrelunesviernes": cierrelunesviernes,
        "horariosabado": horariosabado,
        "cierrehorasabado": cierrehorasabado,
        "horariodomingos": horariodomingos,
        "cierredomingos": cierredomingos,
        "metodopago": metodopago,
        "certificado": certificado,
        "tarifa": tarifa,      
      }),

    );
    
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> registrarPaseador({
    required String nombre,
    required String apellido,
    required String cedulaUsuario,
    required String imagen,
    required String descripcion,
    required String experiencia,
    required String direccion,
    required String telefono,
    required String horariolunesviernes,
    required String cierrelunesviernes,
    required String horariosabado,
    required String cierrehorasabado,
    required String horariodomingos,
    required String cierredomingos,
    required String metodopago,
    required String certificado,
    required String tarifa,
    required String correo,
    required String contrasena

  }) async {
    final url = Uri.parse("$baseUrl/registrarPaseador");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "nombre": nombre,
        "apellido": apellido, 
        "cedulaUsuario": cedulaUsuario,
        "imagen": imagen, 
        "descripcion": descripcion,
        "experiencia": experiencia,
        "direccion": direccion,
        "telefono": telefono,
        "horariolunesviernes": horariolunesviernes,
        "cierrelunesviernes": cierrelunesviernes,
        "horariosabado": horariosabado,
        "cierrehorasabado": cierrehorasabado,
        "horariodomingos": horariodomingos,
        "cierredomingos": cierredomingos,
        "metodopago": metodopago,
        "certificado": certificado,
        "tarifa": tarifa,
        "correo": correo,
        "contrasena": contrasena,

      }),
    );


    if (response.statusCode == 201) {
      return jsonDecode(response.body)["mipaseador"];
    } else {
      throw Exception("Error al registrar paseador");
    }

    
  }


  static Future<bool> actualizar_imagen_paseador({
    required int id_paseador,
    required String imagenBase64,
  }) async {
    final url = Uri.parse("$baseUrl/actualizar_imagen_paseador");

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id_paseador": id_paseador,
        "imagen": imagenBase64,
      }),
    );

    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> promedio_paseador(int id_paseador) async {
    final url = Uri.parse("$baseUrl/promedioPaseador");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id_paseador": id_paseador}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          "promedio": (data["promedio"] ?? 0).toDouble(),
          "total": data["total"] ?? 0
        };
      } else {
        return {"promedio": 0.0, "total": 0};
      }
    } catch (e) {
      print("Error al obtener promedio: $e");
      return {"promedio": 0.0, "total": 0};
    }
  }

  static Future<List<Map<String, dynamic>>> obtener_comentariosPaseador({
    required int id_paseador,
  }) async {
    final url = Uri.parse("$baseUrl/comentariosPaseador");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_paseador": id_paseador}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List calificacion= data["calificacion"] ?? [];
      // Convertimos cada elemento a Map<String, dynamic>
      return calificacion.map<Map<String, dynamic>>((calificacion) => Map<String, dynamic>.from(calificacion)).toList();
    } else {
      // Retornamos lista vacía si no hay datos o error
      return [];
    }
  
  }

  static Future<bool> like_comentarioPaseador({
    required String id,
    required String like,
  }) async {
    final url = Uri.parse("$baseUrl/likeComentarioPaseador");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id": id,
        "like": like,
      }),
    );

    return response.statusCode == 200;
  }

  static Future<List<Map<String, dynamic>>> obtenerCitas_Paseador({
    required int id_paseador,
  }) async {
    final url = Uri.parse("$baseUrl/paseosPaseador");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_paseador": id_paseador}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List citas = data["paseos"] ?? [];
      // Convertimos cada elemento a Map<String, dynamic>
      return citas.map<Map<String, dynamic>>((h) => Map<String, dynamic>.from(h)).toList();
    } else {
      // Retornamos lista vacía si no hay datos o error
      return [];
    }
  }

  static Future<bool> aceptar_paseo({
    required int id
  }) async {
    final url = Uri.parse("$baseUrl/aceptar_paseo");

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id": id
      }),
    );

    return response.statusCode == 200;
  }

  static Future<bool> cancelar_paseo({
    required int id,
  }) async {
    final url = Uri.parse("$baseUrl/cancelar_paseo");

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id": id,
      }),
    );

    return response.statusCode == 200;
  }


  static Future<bool> actualizar_paseador({
    required int id_paseador,
    required String nombre,
    required String apellido,
    required String cedulaUsuario,
    required String imagen,
    required String tarifa,
    required String descripcion,
    required String experiencia,
    required String direccion,
    required String telefono,
    required String horariolunesviernes,
    required String cierrelunesviernes,
    required String horariosabado,
    required String cierrehorasabado,
    String? horariodomingos, // ⬅️ ahora puede ser null
    String? cierredomingos,  // ⬅️ ahora puede ser null
    required String metodopago,
    required String certificado,

  }) async {
    final url = Uri.parse("$baseUrl/actualizarPaseador");

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id_paseador": id_paseador,
        "nombre": nombre, 
        "apellido": apellido,
        "cedulaUsuario": cedulaUsuario,
        "imagen": imagen, 
        "descripcion": descripcion,
        "experiencia": experiencia,
        "direccion": direccion,
        "telefono": telefono,
        "horariolunesviernes": horariolunesviernes,
        "cierrelunesviernes": cierrelunesviernes,
        "horariosabado": horariosabado,
        "cierrehorasabado": cierrehorasabado,
        "horariodomingos": horariodomingos,
        "cierredomingos": cierredomingos,
        "metodopago": metodopago,
        "certificado": certificado,
        "tarifa": tarifa,      
      }),

    );
    
    return response.statusCode == 200;
  }

  
  static Future<Map<String, dynamic>?> eliminar_producto({required int id_producto, required int id_tienda}) async {
    final url = Uri.parse("$baseUrl/eliminarProducto");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_producto": id_producto, "id_tienda": id_tienda}),
    );

    if (response.statusCode == 200) {

      return jsonDecode(response.body);
    } else {

      return null;
    }
  }

  static Future<bool> actualizar_producto({
    required int idproducto,
    required int tienda_id,
    required String nombre,
    required String precio,
    required String cantidad,
    required String descripcion,
    required String imagen,
  }) async {
    final url = Uri.parse("$baseUrl/actualizarProducto");

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "idproducto": idproducto,
        "tienda_id": tienda_id,
        "nombre": nombre,
        "precio": precio,
        "cantidad": cantidad,
        "descripcion": descripcion,
        "imagen": imagen    
      }),

    );
    
    return response.statusCode == 200;
  }



}





