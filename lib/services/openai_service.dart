import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'compression_service.dart';

class OpenAIService {
  // Update to use Firebase Functions
  static const String _baseUrl = 'https://us-central1-kaliai-6dff9.cloudfunctions.net';
  
  /// Analyze meal image using Firebase Functions
  /// Supports both image URL and base64 data
  static Future<Map<String, dynamic>> analyzeMealImage({
    String? imageUrl,
    File? imageFile,
    required String imageName,
    String? apiKey,
  }) async {
    try {
      print('🤖 Starting Firebase Functions analysis for image: $imageName');
      
      final uri = Uri.parse('$_baseUrl/analyze_meal_image');
      
      // Prepare the request payload for Firebase Functions
      Map<String, dynamic> requestBody = {
        "image_name": imageName,
      };
      
      // Add image data - prefer URL if available, otherwise use base64
      if (imageUrl != null) {
        requestBody["image_url"] = imageUrl;
        print('🔗 Using image URL');
      } else if (imageFile != null) {
        // Compress and encode image as base64
        print('🗜️ Compressing image for base64...');
        final compressedFile = await CompressionService.aggressiveCompress(imageFile);
        final imageBytes = await compressedFile.readAsBytes();
        final base64Image = base64Encode(imageBytes);
        
        requestBody["image_base64"] = base64Image;
        print('📊 Using base64 image, size: ${base64Image.length} characters');
        
        // Clean up temporary compressed file
        try {
          if (compressedFile.path != imageFile.path) {
            await compressedFile.delete();
          }
        } catch (e) {
          print('⚠️ Could not delete temporary compressed file: $e');
        }
      } else {
        throw Exception('Either imageUrl or imageFile must be provided');
      }
      
      // Prepare headers
      final headers = {
        'Content-Type': 'application/json',
      };
      
      print('🤖 Sending request to Firebase Functions...');
      
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(requestBody),
      );
      
      print('🤖 Firebase Functions response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('✅ Firebase Functions analysis completed successfully');
        return responseData;
      } else {
        print('🤖 Firebase Functions error response: ${response.body}');
        final errorMessage = 'Firebase Functions request failed with status: ${response.statusCode}';
        print('❌ $errorMessage');
        throw Exception(errorMessage);
      }
      
    } catch (e) {
      print('❌ Error in Firebase Functions analysis: $e');
      rethrow;
    }
  }
} 