import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../env/env.dart';

typedef UploadResult = ({String url, String publicId});

class CloudinaryService {
  static const _baseUrl = 'https://api.cloudinary.com/v1_1';

  static Future<UploadResult?> uploadImage(
    File imageFile, {
    String folder = 'donasibuku/books',
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/${Env.cloudinaryCloudName}/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = Env.cloudinaryUploadPreset
      ..fields['folder'] = folder
      ..files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 200) {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return (
        url: json['secure_url'] as String,
        publicId: json['public_id'] as String,
      );
    }
    return null;
  }
}
