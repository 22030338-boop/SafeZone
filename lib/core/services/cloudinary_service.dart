
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  // Reemplazar por el Cloud Name de tu cuenta.
  static const String cloudName = 'dvbfopm4';

  // Nombre del preset creado en Cloudinary.
  static const String uploadPreset = 'safezone_unsigned';

  // Límite de tamaño para esta aplicación.
  static const int maxFileSize = 10 * 1024 * 1024;

  /// Sube una imagen o video a Cloudinary.
  ///
  /// Retorna la URL segura del archivo.
  static Future<String> uploadFile(XFile file) async {
    final extension = file.name.split('.').last.toLowerCase();

    const imageFormats = [
      'jpg',
      'jpeg',
      'png',
      'webp',
    ];

    const videoFormats = [
      'mp4',
    ];

    String resourceType;

    if (imageFormats.contains(extension)) {
      resourceType = 'image';
    } else if (videoFormats.contains(extension)) {
      resourceType = 'video';
    } else {
      throw Exception('Formato de archivo no permitido.');
    }

    final fileSize = await file.length();

    if (fileSize > maxFileSize) {
      throw Exception('El archivo supera el límite de 10 MB.');
    }

    if (fileSize == 0) {
      throw Exception('El archivo está vacío.');
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/'
      '$cloudName/$resourceType/upload',
    );

    final request = http.MultipartRequest('POST', uri);

    request.fields['upload_preset'] = uploadPreset;

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: file.name,
      ),
    );

    final streamedResponse = await request.send();

    final response = await http.Response.fromStream(
      streamedResponse,
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final secureUrl = data['secure_url'];

      if (secureUrl == null) {
        throw Exception('Cloudinary no devolvió una URL.');
      }

      return secureUrl.toString();
    }

    throw Exception(
      data['error']?['message'] ??
      'Error al subir el archivo a Cloudinary.',
    );
  }
}
