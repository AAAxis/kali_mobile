import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'compression_service.dart';

class OpenAIService {
  static const String _baseUrl = 'https://api.theholylabs.com';
  
  /// Analyze meal image using OpenAI vision API with URL
  static Future<Map<String, dynamic>> analyzeMealImage({
    required String imageUrl,
    required String imageName,
    String? apiKey,
  }) async {
    try {
      print('🤖 Starting OpenAI analysis for image: $imageName');
      
      final uri = Uri.parse('$_baseUrl/api/openai');
      
      // Prepare the request payload
      final requestBody = {
        "model": "gpt-4o-mini",
        "messages": [
          {
            "role": "user",
            "content": [
              {
                "type": "text",
                "text": _getAnalysisPrompt(),
              },
              {
                "type": "image_url",
                "image_url": {
                  "url": imageUrl,
                }
              }
            ]
          }
        ],
        "max_tokens": 1500,
        "response_format": {"type": "json_object"}
      };
      
      // Prepare headers
      final headers = {
        'Content-Type': 'application/json',
      };
      
      // Add API key if provided
      if (apiKey != null) {
        headers['X-API-Key'] = apiKey;
      }
      
      print('🤖 Sending request to OpenAI API...');
      
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(requestBody),
      );
      
      print('🤖 OpenAI response status: ${response.statusCode}');
      print('🤖 OpenAI response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Extract the content from OpenAI response
        if (responseData['choices'] != null && 
            responseData['choices'].isNotEmpty &&
            responseData['choices'][0]['message'] != null &&
            responseData['choices'][0]['message']['content'] != null) {
          
          final contentString = responseData['choices'][0]['message']['content'];
          final analysisResult = jsonDecode(contentString);
          
          print('✅ OpenAI analysis completed successfully');
          return analysisResult;
        } else {
          throw Exception('Invalid response format from OpenAI');
        }
      } else {
        final errorMessage = 'OpenAI API request failed with status: ${response.statusCode}';
        print('❌ $errorMessage');
        throw Exception(errorMessage);
      }
      
    } catch (e) {
      print('❌ Error in OpenAI analysis: $e');
      rethrow;
    }
  }

  /// Analyze meal image using base64 encoding (fallback method) with compression
  static Future<Map<String, dynamic>> analyzeMealImageBase64({
    required File imageFile,
    required String imageName,
    String? apiKey,
  }) async {
    try {
      print('🤖 Starting OpenAI analysis with base64 for image: $imageName');
      
      // Compress the image before base64 encoding
      print('🗜️ Compressing image for API...');
      final compressedFile = await CompressionService.aggressiveCompress(imageFile);
      
      // Check if compressed file is suitable for base64
      final isSuitable = await CompressionService.isSuitableForBase64(compressedFile, maxSizeKB: 400);
      if (!isSuitable) {
        print('⚠️ Image still too large after compression, may cause issues');
      }
      
      final uri = Uri.parse('$_baseUrl/api/openai');
      
      // Read and encode compressed image file as base64
      final imageBytes = await compressedFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      
      // Determine MIME type - always use JPEG after compression
      String mimeType = 'image/jpeg';
      
      print('🤖 Image compressed and encoded as base64, size: ${base64Image.length} characters');
      print('📏 Compressed file size: ${await compressedFile.length()} bytes');
      
      // Prepare the request payload with base64 image
      final requestBody = {
        "model": "gpt-4o-mini",
        "messages": [
          {
            "role": "user",
            "content": [
              {
                "type": "text",
                "text": _getAnalysisPrompt(),
              },
              {
                "type": "image_url",
                "image_url": {
                  "url": "data:$mimeType;base64,$base64Image",
                }
              }
            ]
          }
        ],
        "max_tokens": 1500,
        "response_format": {"type": "json_object"}
      };
      
      // Prepare headers
      final headers = {
        'Content-Type': 'application/json',
      };
      
      // Add API key if provided
      if (apiKey != null) {
        headers['X-API-Key'] = apiKey;
      }
      
      print('🤖 Sending compressed base64 request to OpenAI API...');
      
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(requestBody),
      );
      
      print('🤖 OpenAI response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Extract the content from OpenAI response
        if (responseData['choices'] != null && 
            responseData['choices'].isNotEmpty &&
            responseData['choices'][0]['message'] != null &&
            responseData['choices'][0]['message']['content'] != null) {
          
          final contentString = responseData['choices'][0]['message']['content'];
          final analysisResult = jsonDecode(contentString);
          
          print('✅ OpenAI compressed base64 analysis completed successfully');
          
          // Clean up temporary compressed file
          try {
            if (compressedFile.path != imageFile.path) {
              await compressedFile.delete();
            }
          } catch (e) {
            print('⚠️ Could not delete temporary compressed file: $e');
          }
          
          return analysisResult;
        } else {
          throw Exception('Invalid response format from OpenAI');
        }
      } else {
        // Print response body for debugging if not 200
        print('🤖 OpenAI error response body: ${response.body}');
        final errorMessage = 'OpenAI API request failed with status: ${response.statusCode}';
        print('❌ $errorMessage');
        throw Exception(errorMessage);
      }
      
    } catch (e) {
      print('❌ Error in OpenAI base64 analysis: $e');
      rethrow;
    }
  }
  
  /// Get the analysis prompt for meal image analysis
  static String _getAnalysisPrompt() {
    return """
Analyze this meal image and provide detailed nutritional information in JSON format with the following structure:

{
  "mealName": {
    "en": "English meal name",
    "ru": "Russian meal name",
    "he": "Hebrew meal name"
  },
  "calories": number (estimated total calories),
  "macros": {
    "proteins": number (grams),
    "carbs": number (grams), 
    "fats": number (grams)
  },
  "ingredients": {
    "en": ["ingredient1", "ingredient2", ...],
    "ru": ["ингредиент1", "ингредиент2", ...],
    "he": ["רכיב1", "רכיב2", ...]
  },
  "nutrients": {
    "fiber": number (grams),
    "sugar": number (grams),
    "sodium": number (mg),
    "potassium": number (mg),
    "vitamin_c": number (mg),
    "calcium": number (mg),
    "iron": number (mg)
  },
  "healthiness": "healthy|medium|unhealthy",
  "healthiness_explanation": {
    "en": "English explanation",
    "ru": "Russian explanation", 
    "he": "Hebrew explanation"
  },
  "portion_size": "small|medium|large",
  "meal_type": "breakfast|lunch|dinner|snack",
  "cooking_method": "grilled|fried|baked|raw|steamed|etc",
  "allergens": ["gluten", "dairy", "nuts", "etc"],
  "dietary_tags": ["vegetarian", "vegan", "keto", "low-carb", "etc"]
}

Provide accurate nutritional estimates based on visible ingredients and portion sizes. Be as detailed and accurate as possible. Make sure to provide translations in Hebrew (he), English (en), and Russian (ru) for all multilingual fields.
""";
  }
  
  /// Analyze meal image with retry logic and fallback to base64
  static Future<Map<String, dynamic>> analyzeMealImageWithRetry({
    required String imageUrl,
    required String imageName,
    File? imageFile,
    String? apiKey,
    int maxRetries = 3,
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        // First try with URL
        return await analyzeMealImage(
          imageUrl: imageUrl,
          imageName: imageName,
          apiKey: apiKey,
        );
      } catch (e) {
        attempts++;
        print('❌ OpenAI URL analysis attempt $attempts failed: $e');
        
        // If we have a local file and this is our last attempt with URL, try base64
        if (imageFile != null && imageFile.existsSync() && attempts == maxRetries) {
          print('🔄 Falling back to base64 analysis...');
          try {
            return await analyzeMealImageBase64(
              imageFile: imageFile,
              imageName: imageName,
              apiKey: apiKey,
            );
          } catch (base64Error) {
            print('❌ Base64 analysis also failed: $base64Error');
            throw Exception('Both URL and base64 analysis failed. URL error: $e, Base64 error: $base64Error');
          }
        }
        
        if (attempts >= maxRetries) {
          print('❌ Max OpenAI analysis retries exceeded');
          rethrow;
        }
        
        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
    
    throw Exception('OpenAI analysis failed after $maxRetries attempts');
  }

  /// Analyze meal image using only base64 (for when we want to bypass URL issues)
  static Future<Map<String, dynamic>> analyzeMealImageBase64WithRetry({
    required File imageFile,
    required String imageName,
    String? apiKey,
    int maxRetries = 3,
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await analyzeMealImageBase64(
          imageFile: imageFile,
          imageName: imageName,
          apiKey: apiKey,
        );
      } catch (e) {
        attempts++;
        print('❌ OpenAI base64 analysis attempt $attempts failed: $e');
        
        if (attempts >= maxRetries) {
          print('❌ Max OpenAI base64 analysis retries exceeded');
          rethrow;
        }
        
        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
    
    throw Exception('OpenAI base64 analysis failed after $maxRetries attempts');
  }
} 