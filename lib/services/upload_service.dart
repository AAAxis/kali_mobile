import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class UploadService {
  static const String _baseUrl = 'https://api.theholylabs.com';
  
  /// Upload an image file to the backend
  static Future<String> uploadImage(File imageFile) async {
    try {
      print('📤 Starting image upload...');
      
      final uri = Uri.parse('$_baseUrl/upload');
      final request = http.MultipartRequest('POST', uri);
      
      // Add the image file to the request
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      );
      request.files.add(multipartFile);
      
      print('📤 Sending upload request to: $uri');
      
      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('📤 Upload response status: ${response.statusCode}');
      print('📤 Upload response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final fileUrl = responseData['file_url'] as String;
        print('✅ Image uploaded successfully: $fileUrl');
        return fileUrl;
      } else {
        final errorMessage = 'Upload failed with status: ${response.statusCode}';
        print('❌ $errorMessage');
        throw Exception(errorMessage);
      }
      
    } catch (e) {
      print('❌ Error uploading image: $e');
      rethrow;
    }
  }
  
  /// Upload image with retry logic
  static Future<String> uploadImageWithRetry(File imageFile, {int maxRetries = 3}) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await uploadImage(imageFile);
      } catch (e) {
        attempts++;
        print('❌ Upload attempt $attempts failed: $e');
        
        if (attempts >= maxRetries) {
          print('❌ Max upload retries exceeded');
          rethrow;
        }
        
        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
    
    throw Exception('Upload failed after $maxRetries attempts');
  }
} 