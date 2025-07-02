import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'compression_service.dart';

class OpenAIService {
  // Use Firebase Functions HTTP endpoints
  
  /// Analyze meal image using Firebase Functions with URL
  static Future<Map<String, dynamic>> analyzeMealImage({
    required String imageUrl,
    required String imageName,
    String? apiKey,
  }) async {
    try {
      print('🔥 Starting Firebase Functions analysis for image: $imageName');
      
      
      // Get the function URL - you'll need to replace with your actual project URL
      final functionUrl = 'https://analyze-refrigerator-7jk47pqmda-uc.a.run.app';
      
      // Prepare the request payload to match your function's expected format
      final requestData = {
        "image_url": imageUrl,
        "image_name": imageName,
        "function_info": {
          "source": "flutter_app",
          "timestamp": DateTime.now().toIso8601String(),
        }
      };
      
      print('🔥 Calling Firebase Function at: $functionUrl');
      
      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestData),
      );
      
      print('🔥 Firebase Function response status: ${response.statusCode}');
      print('🔥 Firebase Function response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        print('✅ Firebase Functions analysis completed successfully');
        print('🔍 Response data keys: ${responseData.keys}');
        
        // Check if the response contains an error
        if (responseData.containsKey('error')) {
          print('❌ Firebase Function returned an error: ${responseData['error']}');
          throw Exception('Firebase Function error: ${responseData['error']}');
        }
        
        return _transformFirebaseResponse(responseData);
      } else {
        throw Exception('Firebase Function returned status ${response.statusCode}: ${response.body}');
      }
      
    } catch (e) {
      print('❌ Error in Firebase Functions analysis: $e');
      rethrow;
    }
  }

  /// Analyze meal image using base64 encoding with Firebase Functions
  static Future<Map<String, dynamic>> analyzeMealImageBase64({
    required File imageFile,
    required String imageName,
    String? apiKey,
  }) async {
    try {
      print('🔥 Starting Firebase Functions analysis with base64 for image: $imageName');
      
      // Compress the image before base64 encoding
      print('🗜️ Compressing image for Firebase Functions...');
      final compressedFile = await CompressionService.aggressiveCompress(imageFile);
      
      // Check if compressed file is suitable for base64
      final isSuitable = await CompressionService.isSuitableForBase64(compressedFile, maxSizeKB: 400);
      if (!isSuitable) {
        print('⚠️ Image still too large after compression, may cause issues');
      }
      
      // Read and encode compressed image file as base64
      final imageBytes = await compressedFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      
      print('🔥 Image compressed and encoded as base64, size: ${base64Image.length} characters');
      print('📏 Compressed file size: ${await compressedFile.length()} bytes');
      
      // Your Firebase Function is an HTTP function, so we need to call it via HTTP
      final functionUrl = 'https://analyze-refrigerator-7jk47pqmda-uc.a.run.app';
      
      // Prepare the request payload to match your function's expected format
      final requestData = {
        "image_base64": base64Image,
        "image_name": imageName,
        "function_info": {
          "source": "flutter_app_base64",
          "timestamp": DateTime.now().toIso8601String(),
        }
      };
      
      print('🔥 Calling Firebase Function with base64 data...');
      
      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestData),
      );
      
      print('🔥 Firebase Function response status: ${response.statusCode}');
      print('🔥 Firebase Function response body: ${response.body}');
      
      // Clean up temporary compressed file
      try {
        if (compressedFile.path != imageFile.path) {
          await compressedFile.delete();
        }
      } catch (e) {
        print('⚠️ Could not delete temporary compressed file: $e');
      }
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        print('✅ Firebase Functions base64 analysis completed successfully');
        print('🔍 Response data keys: ${responseData.keys}');
        
        // Check if the response contains an error
        if (responseData.containsKey('error')) {
          print('❌ Firebase Function returned an error: ${responseData['error']}');
          throw Exception('Firebase Function error: ${responseData['error']}');
        }
        
        return _transformFirebaseResponse(responseData);
      } else {
        throw Exception('Firebase Function returned status ${response.statusCode}: ${response.body}');
      }
      
    } catch (e) {
      print('❌ Error in Firebase Functions base64 analysis: $e');
      rethrow;
    }
  }
  
  /// Transform Firebase Function response to match the expected format in your app
  static Map<String, dynamic> _transformFirebaseResponse(Map<String, dynamic> firebaseResponse) {
    // Your Firebase Function now returns English-only data:
    // {
    //   'mealName': 'English meal name',
    //   'estimatedCalories': number,
    //   'macros': {'proteins': 'Xg', 'carbohydrates': 'Xg', 'fats': 'Xg'},
    //   'ingredients': ['ingredient1', 'ingredient2', ...],
    //   'healthiness': 'healthy|medium|unhealthy',
    //   'health_assessment': 'text',
    //   'source': 'url'
    // }
    
    try {
      // Transform to match your app's expected format with English-only data
      // Translation will be handled client-side using your translation services
      final englishMealName = firebaseResponse['mealName'] ?? 'Unknown Meal';
      final englishIngredients = firebaseResponse['ingredients'] ?? ['Unknown ingredients'];
      final englishHealthAssessment = firebaseResponse['health_assessment'] ?? 'No assessment available';
      
      final transformed = <String, dynamic>{
        'mealName': englishMealName, // Store only English string, translate on frontend
        'calories': _parseCalories(firebaseResponse['estimatedCalories']),
        'macros': _parseMacros(firebaseResponse['macros']),
        'ingredients': List<String>.from(englishIngredients), // Store only English list, translate on frontend
        'healthiness': firebaseResponse['healthiness'] ?? 'N/A',
        'healthiness_explanation': englishHealthAssessment, // Store only English string, translate on frontend
        'source': firebaseResponse['source'] ?? 'https://fdc.nal.usda.gov/',
        
        // Add additional fields that your app expects
        'nutrients': {
          'fiber': 0.0,
          'sugar': 0.0,
          'sodium': 0.0,
          'potassium': 0.0,
          'vitamin_c': 0.0,
          'calcium': 0.0,
          'iron': 0.0
        },
        'portion_size': 'medium',
        'meal_type': 'unknown',
        'cooking_method': 'unknown',
        'allergens': <String>[],
        'dietary_tags': <String>[],
        
        // Parse detailed ingredients if available
        'detailedIngredients': _parseDetailedIngredients(firebaseResponse['detailedIngredients']),
      };
      
      print('🔄 Transformed Firebase response successfully (English-only)');
      return transformed;
      
    } catch (e) {
      print('❌ Error transforming Firebase response: $e');
      // Return a safe fallback
      return {
        'mealName': 'Analysis Error', // Store only English string
        'calories': 200.0,
        'macros': {'proteins': 10.0, 'carbs': 25.0, 'fats': 8.0},
        'ingredients': ['Analysis failed'], // Store only English list
        'healthiness': 'N/A',
        'healthiness_explanation': 'Analysis failed', // Store only English string
        'source': 'https://fdc.nal.usda.gov/',
        'nutrients': {
          'fiber': 0.0,
          'sugar': 0.0,
          'sodium': 0.0,
          'potassium': 0.0,
          'vitamin_c': 0.0,
          'calcium': 0.0,
          'iron': 0.0
        },
        'portion_size': 'medium',
        'meal_type': 'unknown',
        'cooking_method': 'unknown',
        'allergens': <String>[],
        'dietary_tags': <String>[],
      };
    }
  }
  
  /// Parse calories from Firebase response
  static double _parseCalories(dynamic calories) {
    if (calories is num) {
      final caloriesValue = calories.toDouble();
      // If calories is 0, provide a reasonable default
      if (caloriesValue == 0) {
        print('⚠️ Calories from Firebase is 0, using default 200');
        return 200.0;
      }
      return caloriesValue;
    }
    if (calories is String) {
      final parsed = double.tryParse(calories) ?? 0.0;
      if (parsed == 0) {
        print('⚠️ Parsed calories is 0, using default 200');
        return 200.0;
      }
      return parsed;
    }
    print('⚠️ Invalid calories format, using default 200');
    return 200.0;
  }
  
  /// Parse macros from Firebase response (handles "Xg" format)
  static Map<String, double> _parseMacros(dynamic macros) {
    final result = <String, double>{
      'proteins': 0.0,
      'carbs': 0.0,
      'fats': 0.0,
    };
    
    if (macros is Map) {
      final macrosMap = Map<String, dynamic>.from(macros);
      
      // Handle "Xg" format from Firebase Functions
      result['proteins'] = _parseGramValue(macrosMap['proteins']);
      result['carbs'] = _parseGramValue(macrosMap['carbohydrates'] ?? macrosMap['carbs']);
      result['fats'] = _parseGramValue(macrosMap['fats']);
    }
    
    return result;
  }
  
  /// Parse gram values that come as "Xg" strings
  static double _parseGramValue(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      // Remove 'g' suffix and parse
      final cleanValue = value.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleanValue) ?? 0.0;
    }
    return 0.0;
  }
  
  /// Parse detailed ingredients from Firebase response
  static List<Map<String, dynamic>>? _parseDetailedIngredients(dynamic detailedIngredients) {
    if (detailedIngredients is List) {
      return detailedIngredients.map((ingredient) {
        if (ingredient is Map) {
          final ingredientMap = Map<String, dynamic>.from(ingredient);
          return {
            'name': ingredientMap['name'] ?? 'Unknown',
            'grams': (ingredientMap['grams'] ?? 100).toDouble(),
            'calories': (ingredientMap['calories'] ?? 0).toDouble(),
            'proteins': (ingredientMap['proteins'] ?? 0).toDouble(),
            'carbs': (ingredientMap['carbs'] ?? 0).toDouble(),
            'fats': (ingredientMap['fats'] ?? 0).toDouble(),
          };
        }
        return <String, dynamic>{
          'name': 'Unknown',
          'grams': 100.0,
          'calories': 0.0,
          'proteins': 0.0,
          'carbs': 0.0,
          'fats': 0.0,
        };
      }).toList();
    }
    return null;
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
        print('❌ Firebase Functions URL analysis attempt $attempts failed: $e');
        
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
          print('❌ Max Firebase Functions analysis retries exceeded');
          rethrow;
        }
        
        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
    
    throw Exception('Firebase Functions analysis failed after $maxRetries attempts');
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
        print('❌ Firebase Functions base64 analysis attempt $attempts failed: $e');
        
        if (attempts >= maxRetries) {
          print('❌ Max Firebase Functions base64 analysis retries exceeded');
          rethrow;
        }
        
        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
    
    throw Exception('Firebase Functions base64 analysis failed after $maxRetries attempts');
  }
} 