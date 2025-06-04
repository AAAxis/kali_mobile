// meal_analysis.dart
// Combined from models.dart and openai.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- models.dart content ---

class Meal {
  final String id;
  final Map<String, String>? mealNameMap;
  final Map<String, List<String>>? ingredientsMap;
  final String name;
  final double calories;
  final DateTime timestamp;
  final String? imageUrl;
  final Map<String, double> macros;
  final bool isFavorite;
  final String? healthiness;
  final bool uploaded;
  final bool isAnalyzing;
  final bool analysisFailed;
  final bool isUploading;
  final String? source;

  Meal({
    required this.id,
    this.mealNameMap,
    this.ingredientsMap,
    required this.name,
    required this.calories,
    required this.timestamp,
    this.imageUrl,
    required this.macros,
    this.isFavorite = false,
    this.healthiness,
    this.uploaded = false,
    this.isAnalyzing = false,
    this.analysisFailed = false,
    this.isUploading = false,
    this.source,
  });

  String getMealName(String locale) => mealNameMap?[locale] ?? mealNameMap?['en'] ?? name;
  List<String> getIngredients(String locale) => ingredientsMap?[locale] ?? ingredientsMap?['en'] ?? [];

  factory Meal.fromJson(Map<String, dynamic> json) {
    DateTime parseTimestamp(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          print('Error parsing date string: $value');
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    Map<String, String>? mealNameMap;
    if (json['mealName'] is Map) {
      mealNameMap = Map<String, String>.from(json['mealName']);
    }
    Map<String, List<String>>? ingredientsMap;
    if (json['ingredients'] is Map) {
      ingredientsMap = Map<String, List<String>>.fromEntries(
        (json['ingredients'] as Map).entries.map((e) => MapEntry(e.key, List<String>.from(e.value))),
      );
    }

    String resolvedName = json['name'] ??
      (json['mealName'] is String
        ? json['mealName']
        : (json['mealName'] is Map
            ? (json['mealName']['en'] ?? (json['mealName'] as Map).values.first ?? 'Unknown Meal')
            : 'Unknown Meal'));

    return Meal(
      id: json['id'] ?? json['mealId'] ?? '',
      mealNameMap: mealNameMap,
      ingredientsMap: ingredientsMap,
      name: resolvedName,
      calories: (json['calories'] ?? json['estimatedCalories'] ?? 0).toDouble(),
      timestamp: parseTimestamp(
        json['timestamp'] ?? json['date'] ?? json['createdAt'],
      ),
      imageUrl: json['imageUrl'],
      macros: {
        'proteins': (json['macros']?['proteins'] ?? 0).toDouble(),
        'carbs': (json['macros']?['carbs'] ?? 0).toDouble(),
        'fats': (json['macros']?['fats'] ?? 0).toDouble(),
      },
      isFavorite: json['isFavorite'] ?? false,
      healthiness: json['healthiness'] ?? 'Unknown',
      uploaded: json['uploaded'] ?? false,
      isAnalyzing: json['isAnalyzing'] ?? false,
      isUploading: json['isUploading'] ?? false,
      analysisFailed: json['analysisFailed'] ?? false,
      source: json['source'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mealName': mealNameMap ?? name,
      'ingredients': ingredientsMap,
      'calories': calories,
      'date': timestamp.toIso8601String(),
      'imageUrl': imageUrl,
      'macros': macros,
      'isFavorite': isFavorite,
      'healthiness': healthiness,
      'uploaded': uploaded,
      'isAnalyzing': isAnalyzing,
      'isUploading': isUploading,
      'analysisFailed': analysisFailed,
      'source': source,
    };
  }

  factory Meal.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseTimestamp(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          print('Error parsing date string: $value');
          return DateTime.now();
        }
      }
      return DateTime.now();
    }
    Map<String, String>? mealNameMap;
    if (data['mealName'] is Map) {
      mealNameMap = Map<String, String>.from(data['mealName']);
    }
    Map<String, List<String>>? ingredientsMap;
    if (data['ingredients'] is Map) {
      ingredientsMap = Map<String, List<String>>.fromEntries(
        (data['ingredients'] as Map).entries.map((e) => MapEntry(e.key, List<String>.from(e.value))),
      );
    }
    String resolvedName = data['name'] ??
      (data['mealName'] is String
        ? data['mealName']
        : (data['mealName'] is Map
            ? (data['mealName']['en'] ?? (data['mealName'] as Map).values.first ?? 'Unknown Meal')
            : 'Unknown Meal'));
    return Meal(
      id: id,
      mealNameMap: mealNameMap,
      ingredientsMap: ingredientsMap,
      name: resolvedName,
      calories: (data['calories'] ?? 0).toDouble(),
      timestamp: parseTimestamp(
        data['timestamp'] ?? data['date'] ?? data['createdAt'],
      ),
      imageUrl: data['imageUrl'],
      macros: Map<String, double>.from(data['macros'] ?? {}),
      isFavorite: data['isFavorite'] ?? false,
      healthiness: data['healthiness'],
      uploaded: data['uploaded'] ?? false,
      isAnalyzing: data['isAnalyzing'] ?? false,
      analysisFailed: data['analysisFailed'] ?? false,
      isUploading: data['isUploading'] ?? false,
      source: data['source'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mealName': mealNameMap ?? name,
      'ingredients': ingredientsMap,
      'calories': calories,
      'timestamp': Timestamp.fromDate(timestamp),
      'imageUrl': imageUrl,
      'macros': macros,
      'isFavorite': isFavorite,
      'healthiness': healthiness,
      'uploaded': uploaded,
      'isAnalyzing': isAnalyzing,
      'analysisFailed': analysisFailed,
      'isUploading': isUploading,
      'source': source,
    };
  }

  Meal copyWith({
    String? id,
    Map<String, String>? mealNameMap,
    Map<String, List<String>>? ingredientsMap,
    String? name,
    double? calories,
    DateTime? timestamp,
    String? imageUrl,
    Map<String, double>? macros,
    bool? isFavorite,
    String? healthiness,
    bool? uploaded,
    bool? isAnalyzing,
    bool? isUploading,
    bool? analysisFailed,
    String? source,
  }) {
    return Meal(
      id: id ?? this.id,
      mealNameMap: mealNameMap ?? this.mealNameMap,
      ingredientsMap: ingredientsMap ?? this.ingredientsMap,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      timestamp: timestamp ?? this.timestamp,
      imageUrl: imageUrl ?? this.imageUrl,
      macros: macros ?? this.macros,
      isFavorite: isFavorite ?? this.isFavorite,
      healthiness: healthiness ?? this.healthiness,
      uploaded: uploaded ?? this.uploaded,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      isUploading: isUploading ?? this.isUploading,
      analysisFailed: analysisFailed ?? this.analysisFailed,
      source: source ?? this.source,
    );
  }

  static Future<void> saveToFirestore(Meal meal, String userId) async {
    await FirebaseFirestore.instance
        .collection('analyzed_meals')
        .doc(meal.id)
        .set({
          ...meal.toMap(),
          'userId': userId,
        });
  }

  // Load meals from local storage for non-authenticated users
  static Future<List<Meal>> loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mealsJson = prefs.getStringList('local_meals') ?? [];
      
      final meals = mealsJson.map((mealJson) {
        try {
          final mealData = jsonDecode(mealJson) as Map<String, dynamic>;
          return Meal.fromJson(mealData);
        } catch (e) {
          print('❌ Error parsing local meal: $e');
          return null;
        }
      }).where((meal) => meal != null).cast<Meal>().toList();
      
      // Sort by timestamp (newest first)
      meals.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      print('✅ Loaded ${meals.length} meals from local storage');
      return meals;
    } catch (e) {
      print('❌ Error loading meals from local storage: $e');
      return [];
    }
  }

  // Delete meal from local storage
  static Future<void> deleteFromLocalStorage(String mealId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mealsJson = prefs.getStringList('local_meals') ?? [];
      
      // Filter out the meal with the given ID
      final updatedMealsJson = mealsJson.where((mealJson) {
        try {
          final mealData = jsonDecode(mealJson) as Map<String, dynamic>;
          return mealData['id'] != mealId;
        } catch (e) {
          return true; // Keep malformed entries for now
        }
      }).toList();
      
      await prefs.setStringList('local_meals', updatedMealsJson);
      print('✅ Deleted meal $mealId from local storage');
    } catch (e) {
      print('❌ Error deleting meal from local storage: $e');
    }
  }
}

class MealAnalysis {
  final String? id;
  final String userId;
  final String mealId;
  final String mealName;
  final String imageUrl;
  final String confidence;
  final double estimatedCalories;
  final Map<String, double> macros;
  final List<String> ingredients;
  final List<String> nutrients;
  final String healthiness;
  final List<String> recommendations;
  final String additionalNotes;
  final DateTime date;

  MealAnalysis({
    this.id,
    required this.userId,
    required this.mealId,
    required this.mealName,
    required this.imageUrl,
    required this.confidence,
    required this.estimatedCalories,
    required this.macros,
    required this.ingredients,
    required this.nutrients,
    required this.healthiness,
    required this.recommendations,
    required this.additionalNotes,
    required this.date,
  });

  factory MealAnalysis.fromMap(Map<String, dynamic> data, String id) {
    return MealAnalysis(
      id: id,
      userId: data['userId'] ?? '',
      mealId: data['mealId'] ?? '',
      mealName: data['mealName'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      confidence: data['confidence'] ?? '',
      estimatedCalories: (data['estimatedCalories'] ?? 0).toDouble(),
      macros: {
        'proteins': (data['macros']?['proteins'] ?? 0.0).toDouble(),
        'carbs': (data['macros']?['carbs'] ?? 0.0).toDouble(),
        'fats': (data['macros']?['fats'] ?? 0.0).toDouble(),
      },
      ingredients: List<String>.from(data['ingredients'] ?? []),
      nutrients: List<String>.from(data['nutrients'] ?? []),
      healthiness: data['healthiness'] ?? '',
      recommendations: List<String>.from(data['recommendations'] ?? []),
      additionalNotes: data['additionalNotes'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'mealId': mealId,
      'mealName': mealName,
      'imageUrl': imageUrl,
      'confidence': confidence,
      'estimatedCalories': estimatedCalories,
      'macros': macros,
      'ingredients': ingredients,
      'nutrients': nutrients,
      'healthiness': healthiness,
      'recommendations': recommendations,
      'additionalNotes': additionalNotes,
      'date': Timestamp.fromDate(date),
    };
  }
}

class MealAnalysisResult {
  final String id;
  final String mealId;
  final Map<String, String> mealNameMap;
  final Map<String, List<String>> ingredientsMap;
  final String? imageUrl;
  final String confidence;
  final double estimatedCalories;
  final Map<String, double> macros;
  final List<String> nutrients;
  final String healthiness;
  final List<String> recommendations;
  final String additionalNotes;
  final DateTime date;
  final String? source;

  MealAnalysisResult({
    required this.id,
    required this.mealId,
    required this.mealNameMap,
    required this.ingredientsMap,
    this.imageUrl,
    required this.confidence,
    required this.estimatedCalories,
    required this.macros,
    required this.nutrients,
    required this.healthiness,
    required this.recommendations,
    required this.additionalNotes,
    required this.date,
    this.source,
  });

  String getMealName(String locale) => mealNameMap[locale] ?? mealNameMap['en'] ?? '';
  List<String> getIngredients(String locale) => ingredientsMap[locale] ?? ingredientsMap['en'] ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mealId': mealId,
      'mealName': mealNameMap,
      'ingredients': ingredientsMap,
      'imageUrl': imageUrl,
      'confidence': confidence,
      'estimatedCalories': estimatedCalories,
      'macros': macros,
      'nutrients': nutrients,
      'healthiness': healthiness,
      'recommendations': recommendations,
      'additionalNotes': additionalNotes,
      'date': date.toIso8601String(),
      'source': source,
    };
  }

  factory MealAnalysisResult.fromJson(Map<String, dynamic> json) {
    return MealAnalysisResult(
      id: json['id'] as String,
      mealId: json['mealId'] as String,
      mealNameMap: Map<String, String>.from(json['mealName'] as Map),
      ingredientsMap: Map<String, List<String>>.fromEntries(
        (json['ingredients'] as Map).entries.map((e) => MapEntry(e.key, List<String>.from(e.value))),
      ),
      imageUrl: json['imageUrl'] as String?,
      confidence: json['confidence'] as String,
      estimatedCalories: (json['estimatedCalories'] as num).toDouble(),
      macros: Map<String, double>.from(json['macros'] as Map),
      nutrients: List<String>.from(json['nutrients'] as List),
      healthiness: json['healthiness'] as String,
      recommendations: List<String>.from(json['recommendations'] as List),
      additionalNotes: json['additionalNotes'] as String,
      date: DateTime.parse(json['date'] as String),
      source: json['source'] as String?,
    );
  }

  Future<void> saveToFirestore(String userId) async {
    final meal = Meal(
      id: id,
      mealNameMap: mealNameMap,
      ingredientsMap: ingredientsMap,
      name: getMealName('en'),
      calories: estimatedCalories,
      timestamp: date,
      imageUrl: imageUrl,
      macros: macros,
      isAnalyzing: false,
      isUploading: false,
      analysisFailed: false,
      source: source,
    );
    await Meal.saveToFirestore(meal, userId);
  }

  // Save to local storage for non-authenticated users
  Future<void> saveToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing local meals
      final existingMealsJson = prefs.getStringList('local_meals') ?? [];
      
      // Convert this analysis result to a meal
      final meal = Meal(
        id: id,
        mealNameMap: mealNameMap,
        ingredientsMap: ingredientsMap,
        name: getMealName('en'),
        calories: estimatedCalories,
        timestamp: date,
        imageUrl: imageUrl,
        macros: macros,
        isAnalyzing: false,
        isUploading: false,
        analysisFailed: false,
        source: source,
      );
      
      // Add new meal to the list
      existingMealsJson.add(jsonEncode(meal.toJson()));
      
      // Save back to SharedPreferences
      await prefs.setStringList('local_meals', existingMealsJson);
      
      print('✅ Meal saved to local storage: ${meal.name}');
    } catch (e) {
      print('❌ Error saving meal to local storage: $e');
    }
  }
}

// --- openai.dart content ---

class ImageService {
  static final _storage = FirebaseStorage.instance;
  static const _functionUrl =
      'https://analyze-meal-image-7jk47pqmda-uc.a.run.app';
  
  // Note: This service supports both authenticated and non-authenticated users
  // - Authenticated users: Images are uploaded to Firebase Storage and URL is sent to cloud function
  // - Non-authenticated users: Attempts anonymous upload to Firebase Storage, with base64 fallback
  // - If anonymous upload fails, returns helpful error message asking user to sign in

  static Future<Map<String, String>> _getDeviceInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'anonymous_user';

    String deviceId;
    if (Platform.isAndroid) {
      deviceId = 'Android';
    } else if (Platform.isIOS) {
      deviceId = 'iOS';
    } else {
      deviceId = 'Unknown Device';
    }

    final version = const String.fromEnvironment(
      'APP_VERSION',
      defaultValue: '2.4',
    );

    return {'device_id': deviceId, 'version': version, 'email': email};
  }

  static Future<String> _uploadImage(File imageFile, String userId) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'meal_images/$userId/$timestamp.jpg';

    try {
      print('[Storage] Starting image upload to Firebase Storage');
      print('[Storage] Upload path: $path');

      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = ref.putFile(imageFile, metadata);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('[Storage] Upload progress: ${progress.toStringAsFixed(1)}%');
      });

      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();
      print('[Storage] Image uploaded successfully. URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('[Storage] Error uploading image: $e');
      rethrow;
    }
  }

  static Future<String> _uploadImageAnonymously(File imageFile) async {
    // Try Firebase Storage first (might work if configured for anonymous access)
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'meal_images/anonymous/$timestamp.jpg';

      print('[Storage] Attempting anonymous upload to Firebase Storage');
      print('[Storage] Upload path: $path');

      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': 'anonymous',
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = ref.putFile(imageFile, metadata);
      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();
      print('[Storage] ✅ Anonymous Firebase upload successful: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('[Storage] ❌ Firebase anonymous upload failed: $e');
      
      // Fallback: Try a temporary image hosting service
      try {
        return await _uploadToTemporaryService(imageFile);
      } catch (e2) {
        print('[Storage] ❌ Temporary service upload also failed: $e2');
        rethrow;
      }
    }
  }

  static Future<String> _uploadToTemporaryService(File imageFile) async {
    // Use a free temporary image hosting service like imgbb, imgur, or similar
    // For now, we'll throw an error to indicate this needs implementation
    print('[Storage] ⚠️ Temporary image hosting not implemented yet');
    throw Exception('Temporary image hosting service not available. Please sign in for full functionality.');
  }

  static Future<MealAnalysisResult> processAndAnalyzeImage(
    File imageFile, {
    String? storageUrl,
  }) async {
    String? imageUrlToUse;
    try {
      print('[ImageService] Starting image processing');
      print('[ImageService] Input image path: ${imageFile.path}');
      print('[ImageService] Image exists: ${await imageFile.exists()}');
      print('[ImageService] Image size: ${await imageFile.length()} bytes');

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('[ImageService] ✅ User authenticated: ${user.uid}');
        print('[ImageService] ✅ Will proceed with cloud function analysis');
      } else {
        print('[ImageService] ⚠️ User not authenticated - will try anonymous upload or base64 fallback');
      }

      if (storageUrl != null && storageUrl.isNotEmpty) {
        imageUrlToUse = storageUrl;
        print('[ImageService] Using provided storage URL: $imageUrlToUse');
      } else if (user != null) {
        print(
          '[ImageService] No valid storageUrl provided, uploading image...',
        );
        imageUrlToUse = await _uploadImage(imageFile, user.uid);
        print('[ImageService] Image uploaded, URL: $imageUrlToUse');
      } else {
        // For non-authenticated users, we'll upload to a temporary storage or use a different approach
        print('[ImageService] ⚠️ User not authenticated - will try alternative upload method');
        try {
          // Try to upload without authentication (this might work for some storage services)
          imageUrlToUse = await _uploadImageAnonymously(imageFile);
          print('[ImageService] ✅ Anonymous upload successful: $imageUrlToUse');
        } catch (e) {
          print('[ImageService] ❌ Anonymous upload failed: $e');
          // For now, we'll return a helpful error message
          return _getDefaultAnalysisResult(
            'Please sign in to analyze your meals. Anonymous meal analysis is not currently available.',
            imageFile.path,
          );
        }
      }

      final deviceInfo = await _getDeviceInfo();
      final Map<String, dynamic> payload = {
        'image_name': basename(imageFile.path),
        'function_info': {
          'name': 'analyze_meal_image',
          'version': deviceInfo['version'],
          'device': deviceInfo['device_id'],
          'user': deviceInfo['email'],
        },
      };

      // Handle image data based on authentication status
      if (imageUrlToUse != null) {
        // User has image URL (either authenticated or anonymous upload worked)
        payload['image_url'] = imageUrlToUse;
        print('[ImageService] Using image URL: $imageUrlToUse');
      } else {
        // Fallback: send image as base64 (requires cloud function update)
        print('[ImageService] Converting image to base64 for cloud function');
        try {
          final imageBytes = await imageFile.readAsBytes();
          final base64Image = base64Encode(imageBytes);
          payload['image_data'] = base64Image;
          payload['image_format'] = 'jpg';
          print('[ImageService] Image converted to base64 (${base64Image.length} characters)');
          print('[ImageService] ⚠️ Note: Cloud function must support image_data field for this to work');
        } catch (e) {
          print('[ImageService] ❌ Error converting image to base64: $e');
          throw Exception('Failed to process image for analysis: $e');
        }
      }

      print('[ImageService] 🚀 Sending request to: $_functionUrl');
      print('[ImageService] 📤 Payload: ${json.encode(payload)}');
      print('[ImageService] ⏱️ Starting HTTP request with 30-second timeout...');

      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          print('[ImageService] ⏰ Request timed out after 30 seconds');
          print('[ImageService] ⏰ This usually means the cloud function is taking too long to process the OpenAI API call');
          throw Exception('Cloud function request timed out after 30 seconds');
        },
      );

      print('[ImageService] ✅ HTTP request completed successfully');

      print('[ImageService] 📥 API response status: ${response.statusCode}');
      print('[ImageService] 📥 API response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;

        if (responseData.containsKey('error')) {
          print(
            '[ImageService] API returned error in 200 response: ${responseData['error']}',
          );

          if (responseData.containsKey('fallback_analysis')) {
            print('[ImageService] Using fallback analysis provided by API');
            return _parseAnalysisResponse(
              responseData['fallback_analysis'],
              imageUrlToUse ?? imageFile.path,
            );
          } else {
            throw Exception('API returned error: ${responseData['error']}');
          }
        }

        return _parseAnalysisResponse(responseData, imageUrlToUse ?? imageFile.path);
      } else if (response.statusCode == 403) {
        print(
          '[ImageService] ❌ Authentication error (403): Cloud function access denied',
        );
        return _getDefaultAnalysisResult(
          'Cloud function authentication error: The service may need to be redeployed',
          imageUrlToUse ?? imageFile.path,
        );
      } else {
        print(
          '[ImageService] ❌ Error in API communication: ${response.statusCode} - ${response.body}',
        );
        throw Exception(
          'API call failed with status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      print('[ImageService] ❌ CRITICAL ERROR processing image: $e');
      print('[ImageService] ❌ Stack trace: $stackTrace');
      
      // Determine the final image URL for the error response
      String? finalImageUrl = imageUrlToUse;
      if (finalImageUrl == null && storageUrl != null && storageUrl.isNotEmpty) {
        finalImageUrl = storageUrl;
      } else if (finalImageUrl == null && imageFile.existsSync()) {
        finalImageUrl = imageFile.path;
      }

      // Check if this is a timeout error
      if (e.toString().contains('timed out') || e.toString().contains('timeout')) {
        print('[ImageService] ⏰ Cloud function timeout detected - this is likely due to OpenAI API delays');
        return _getDefaultAnalysisResult(
          'Cloud function timed out. The AI analysis service may be experiencing high load. Please try again in a few moments.',
          finalImageUrl,
        );
      }

      return _getDefaultAnalysisResult(e.toString(), finalImageUrl);
    }
  }

  static double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final numericString = value.replaceAll(RegExp(r'[^0-9.]'), '');
      try {
        return double.parse(numericString);
      } catch (e) {
        print('[ImageService] Error parsing double from string "$value": $e');
        return 0.0;
      }
    }
    print(
      '[ImageService] Unexpected type for double parsing: ${value.runtimeType}',
    );
    return 0.0;
  }

  static MealAnalysisResult _parseAnalysisResponse(
    Map<String, dynamic> response,
    String? imageUrl,
  ) {
    try {
      print('[ImageService] Parsing API response. Image URL: $imageUrl');

      final data = response['data'] ?? response;

      final String parsedMealId =
          data['mealId']?.toString() ??
          data['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString();
      final String parsedId = data['id']?.toString() ?? parsedMealId;

      final Map<String, String> mealNameMap = data['mealName'] != null
          ? Map<String, String>.from(data['mealName'])
          : {'en': data['mealName']?.toString() ?? 'Unknown Meal'};
      final Map<String, List<String>> ingredientsMap = data['ingredients'] != null
          ? Map<String, List<String>>.fromEntries(
              (data['ingredients'] as Map).entries.map((e) => MapEntry(e.key, List<String>.from(e.value))))
          : {'en': (data['ingredients'] as List<dynamic>? ?? []).map((i) => i.toString()).toList()};

      final estimatedCalories = _safeDouble(data['estimatedCalories']);
      final healthiness = data['healthiness'] as String? ?? 'N/A';
      final source = data['source'] as String? ?? 'API';
      final confidence = data['confidence'] as String? ?? 'N/A';
      final additionalNotes = data['additionalNotes'] as String? ?? '';

      final macrosData = data['macros'] as Map<String, dynamic>? ?? {};
      final macros = {
        'proteins': _safeDouble(macrosData['proteins']),
        'carbs': _safeDouble(macrosData['carbs'] ?? macrosData['carbohydrates']),
        'fats': _safeDouble(macrosData['fats']),
      };

      final recommendationsList =
          (data['recommendations'] as List<dynamic>?)?.map((item) => item.toString()).toList() ?? [];

      final nutrientsRaw = data['nutrients'] as List<dynamic>? ?? [];
      final List<String> nutrientsList =
          nutrientsRaw.map((item) {
            if (item is Map<String, dynamic>) {
              final name = item['name'] ?? 'Unknown Nutrient';
              final amount = _safeDouble(item['amount']);
              final unit = item['unit'] ?? '';
              final dv = _safeDouble(item['percentOfDailyNeeds']);
              return '$name: $amount $unit (${dv.toStringAsFixed(0)}% DV)';
            }
            return item.toString();
          }).toList();

      final timestamp =
          data['timestamp'] != null
              ? DateTime.tryParse(data['timestamp'] as String) ?? DateTime.now()
              : DateTime.now();

      return MealAnalysisResult(
        id: parsedId,
        mealId: parsedMealId,
        mealNameMap: mealNameMap,
        ingredientsMap: ingredientsMap,
        estimatedCalories: estimatedCalories,
        macros: macros,
        date: timestamp,
        imageUrl: imageUrl ?? '',
        healthiness: healthiness,
        recommendations: recommendationsList,
        source: source,
        nutrients: nutrientsList,
        confidence: confidence,
        additionalNotes: additionalNotes,
      );
    } catch (e, stackTrace) {
      print('[ImageService] Error parsing analysis response: $e');
      print('[ImageService] Stack trace for parsing error: $stackTrace');
      print('[ImageService] Response causing parsing error: $response');
      return _getDefaultAnalysisResult('Error parsing response: $e', imageUrl);
    }
  }

  static MealAnalysisResult _getDefaultAnalysisResult(
    String errorMessage,
    String? imageUrl,
  ) {
    print(
      '[ImageService] ⚠️ Creating ERROR analysis result due to error: $errorMessage',
    );
    print('[ImageService] ⚠️ This is an ERROR fallback, not sample data');
    final defaultId = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      print('[ImageService] Error logged: $errorMessage');
    } catch (e) {
      print('[ImageService] Failed to log error analytics: $e');
    }

    String mealName = 'Analysis Failed';
    String additionalNotes = '';
    if (errorMessage.contains('403') || errorMessage.contains('Forbidden')) {
      mealName = 'Service Temporarily Unavailable';
      additionalNotes =
          'The meal analysis service is currently experiencing issues. Please try again later.';
    } else if (errorMessage.contains('timed out') || errorMessage.contains('timeout')) {
      mealName = 'Analysis Timed Out';
      additionalNotes =
          'The AI analysis service is experiencing high load. Please try again in a few moments.';
    } else if (errorMessage.contains('network') || errorMessage.contains('connection')) {
      mealName = 'Network Error';
      additionalNotes =
          'Unable to connect to the analysis service. Please check your internet connection and try again.';
    } else if (errorMessage.contains('sign in') || errorMessage.contains('Anonymous')) {
      mealName = 'Sign In Required';
      additionalNotes =
          'Please sign in to your account to analyze meals with AI. This feature requires authentication.';
    }

    return MealAnalysisResult(
      id: defaultId,
      mealId: defaultId,
      mealNameMap: {'en': mealName},
      ingredientsMap: {'en': [errorMessage.length > 200 ? errorMessage.substring(0, 200) : errorMessage]},
      estimatedCalories: 0,
      macros: {'proteins': 0, 'carbs': 0, 'fats': 0},
      date: DateTime.now(),
      imageUrl: imageUrl ?? '',
      healthiness: 'N/A',
      recommendations: [
        errorMessage.length > 200
            ? errorMessage.substring(0, 200)
            : errorMessage,
      ],
      source: 'Error',
      nutrients: [],
      confidence: 'N/A',
      additionalNotes:
          additionalNotes.isEmpty ? 'Error: $errorMessage' : additionalNotes,
    );
  }

  static MealAnalysisResult _getDefaultAnalysisForNonAuthUser(String imagePath) {
    print('[ImageService] 🎭 Creating SAMPLE analysis for non-authenticated user');
    print('[ImageService] 🎭 This is NOT real AI analysis - just sample data');
    final defaultId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Generate some realistic sample data for testing
    final sampleMeals = [
      {
        'name': {'en': 'Mixed Salad', 'he': 'סלט מעורב', 'ru': 'Смешанный салат'},
        'ingredients': {
          'en': ['Lettuce', 'Tomatoes', 'Cucumber', 'Olive oil'],
          'he': ['חסה', 'עגבניות', 'מלפפון', 'שמן זית'],
          'ru': ['Салат', 'Помидоры', 'Огурец', 'Оливковое масло']
        },
        'calories': 150.0,
        'proteins': 3.0,
        'carbs': 12.0,
        'fats': 11.0,
        'healthiness': 'healthy'
      },
      {
        'name': {'en': 'Grilled Chicken', 'he': 'עוף צלוי', 'ru': 'Жареная курица'},
        'ingredients': {
          'en': ['Chicken breast', 'Herbs', 'Olive oil'],
          'he': ['חזה עוף', 'עשבי תיבול', 'שמן זית'],
          'ru': ['Куриная грудка', 'Травы', 'Оливковое масло']
        },
        'calories': 250.0,
        'proteins': 35.0,
        'carbs': 2.0,
        'fats': 12.0,
        'healthiness': 'healthy'
      },
      {
        'name': {'en': 'Pasta with Sauce', 'he': 'פסטה ברטב', 'ru': 'Паста с соусом'},
        'ingredients': {
          'en': ['Pasta', 'Tomato sauce', 'Cheese', 'Herbs'],
          'he': ['פסטה', 'רטב עגבניות', 'גבינה', 'עשבי תיבול'],
          'ru': ['Паста', 'Томатный соус', 'Сыр', 'Травы']
        },
        'calories': 420.0,
        'proteins': 15.0,
        'carbs': 65.0,
        'fats': 12.0,
        'healthiness': 'medium'
      }
    ];
    
    // Randomly select a sample meal for variety
    final random = DateTime.now().millisecond % sampleMeals.length;
    final selectedMeal = sampleMeals[random];
    
    return MealAnalysisResult(
      id: defaultId,
      mealId: defaultId,
      mealNameMap: Map<String, String>.from(selectedMeal['name'] as Map),
      ingredientsMap: Map<String, List<String>>.from(
        (selectedMeal['ingredients'] as Map).map((key, value) => 
          MapEntry(key, List<String>.from(value))
        )
      ),
      estimatedCalories: selectedMeal['calories'] as double,
      macros: {
        'proteins': selectedMeal['proteins'] as double,
        'carbs': selectedMeal['carbs'] as double,
        'fats': selectedMeal['fats'] as double,
      },
      date: DateTime.now(),
      imageUrl: imagePath,
      healthiness: selectedMeal['healthiness'] as String,
      recommendations: [
        'This is a sample analysis for demonstration purposes.',
        'Sign in to get detailed AI-powered meal analysis.',
      ],
      source: 'Sample',
      nutrients: [
        'Vitamin C: 15mg (17% DV)',
        'Fiber: 3g (12% DV)',
        'Iron: 2mg (11% DV)',
      ],
      confidence: 'Sample',
      additionalNotes: 'This is a sample meal analysis. Sign in to get accurate AI-powered analysis of your meals.',
    );
  }

  static Future<String> uploadProfileImage(File imageFile, String userId) {
    return _uploadImage(imageFile, userId);
  }
}

Future<MealAnalysisResult?> pickAndAnalyzeImage({
  required BuildContext context,
  required ImagePicker picker,
  required List<Meal> meals,
  required void Function(List<Meal>) updateMeals,
  required ImageSource source,
  Meal? retryMeal,
  String? userId,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  final uid = userId ?? user?.uid;
  
  final XFile? image = await picker.pickImage(source: source);
  if (image == null) return null;
  
  final file = File(image.path);
  
  // Create immediate meal record with analyzing state
  final tempMealId = DateTime.now().millisecondsSinceEpoch.toString();
  final analyzingMeal = Meal(
    id: tempMealId,
    name: 'Analyzing...',
    calories: 0,
    timestamp: DateTime.now(),
    imageUrl: file.path, // Use local path initially
    macros: {'proteins': 0, 'carbs': 0, 'fats': 0},
    isAnalyzing: true,
    analysisFailed: false,
    uploaded: false,
    source: source == ImageSource.camera ? 'camera' : 'gallery',
  );
  
  // Add analyzing meal to the list immediately
  final updatedMealsWithAnalyzing = [analyzingMeal, ...meals];
  updateMeals(updatedMealsWithAnalyzing);
  
  try {
    // Process and analyze the image
    final analysisResult = await ImageService.processAndAnalyzeImage(file);
    
    // Create final meal with analysis results
    final finalMeal = Meal(
      id: tempMealId, // Keep same ID
      mealNameMap: analysisResult.mealNameMap,
      ingredientsMap: analysisResult.ingredientsMap,
      name: analysisResult.getMealName('en'),
      calories: analysisResult.estimatedCalories,
      timestamp: DateTime.now(),
      imageUrl: analysisResult.imageUrl,
      macros: analysisResult.macros,
      isAnalyzing: false,
      analysisFailed: false,
      uploaded: false,
      healthiness: analysisResult.healthiness,
      source: source == ImageSource.camera ? 'camera' : 'gallery',
    );
    
    // Save to appropriate storage based on authentication status
    if (uid != null) {
      // User is authenticated - save to Firebase
      await analysisResult.saveToFirestore(uid);
      print('✅ Meal saved to Firebase for authenticated user: $uid');
    } else {
      // User is not authenticated - save to local storage
      await analysisResult.saveToLocalStorage();
      print('✅ Meal saved to local storage for non-authenticated user');
    }
    
    // Update the analyzing meal with final results
    final finalMealsList = updatedMealsWithAnalyzing.map((m) => 
      m.id == tempMealId ? finalMeal : m
    ).toList();
    updateMeals(finalMealsList);
    
    return analysisResult;
    
  } catch (e) {
    print('❌ Error during analysis: $e');
    
    // Create failed meal record
    final failedMeal = analyzingMeal.copyWith(
      name: 'Analysis Failed',
      isAnalyzing: false,
      analysisFailed: true,
    );
    
    // Update the analyzing meal with failed state
    final failedMealsList = updatedMealsWithAnalyzing.map((m) => 
      m.id == tempMealId ? failedMeal : m
    ).toList();
    updateMeals(failedMealsList);
    
    return null;
  }
}

Future<void> pickAndAnalyzeImageFromCamera({
  required BuildContext context,
  required ImagePicker picker,
  required List<Meal> meals,
  required void Function(List<Meal>) updateMeals,
  Meal? retryMeal,
}) async {
  await pickAndAnalyzeImage(
    context: context,
    picker: picker,
    meals: meals,
    updateMeals: updateMeals,
    source: ImageSource.camera,
    retryMeal: retryMeal,
  );
}

Future<void> pickAndAnalyzeImageFromGallery({
  required BuildContext context,
  required ImagePicker picker,
  required List<Meal> meals,
  required void Function(List<Meal>) updateMeals,
  Meal? retryMeal,
}) async {
  await pickAndAnalyzeImage(
    context: context,
    picker: picker,
    meals: meals,
    updateMeals: updateMeals,
    source: ImageSource.gallery,
    retryMeal: retryMeal,
  );
}

// New function to analyze image file directly (for custom camera)
Future<MealAnalysisResult?> analyzeImageFile({
  required File imageFile,
  required BuildContext context,
  required List<Meal> meals,
  required void Function(List<Meal>) updateMeals,
  required ImageSource source,
  Meal? retryMeal,
  String? userId,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  final uid = userId ?? user?.uid;
  
  // Create immediate meal record with analyzing state
  final tempMealId = DateTime.now().millisecondsSinceEpoch.toString();
  final analyzingMeal = Meal(
    id: tempMealId,
    name: 'Analyzing...',
    calories: 0,
    timestamp: DateTime.now(),
    imageUrl: imageFile.path, // Use local path initially
    macros: {'proteins': 0, 'carbs': 0, 'fats': 0},
    isAnalyzing: true,
    analysisFailed: false,
    uploaded: false,
    source: source == ImageSource.camera ? 'camera' : 'gallery',
  );
  
  // Add analyzing meal to the list immediately
  final updatedMealsWithAnalyzing = [analyzingMeal, ...meals];
  updateMeals(updatedMealsWithAnalyzing);
  
  try {
    // Process and analyze the image
    final analysisResult = await ImageService.processAndAnalyzeImage(imageFile);
    
    // Create final meal with analysis results
    final finalMeal = Meal(
      id: tempMealId, // Keep same ID
      mealNameMap: analysisResult.mealNameMap,
      ingredientsMap: analysisResult.ingredientsMap,
      name: analysisResult.getMealName('en'),
      calories: analysisResult.estimatedCalories,
      timestamp: DateTime.now(),
      imageUrl: analysisResult.imageUrl,
      macros: analysisResult.macros,
      isAnalyzing: false,
      analysisFailed: false,
      uploaded: false,
      healthiness: analysisResult.healthiness,
      source: source == ImageSource.camera ? 'camera' : 'gallery',
    );
    
    // Save to appropriate storage based on authentication status
    if (uid != null) {
      // User is authenticated - save to Firebase
      await analysisResult.saveToFirestore(uid);
      print('✅ Meal saved to Firebase for authenticated user: $uid');
    } else {
      // User is not authenticated - save to local storage
      await analysisResult.saveToLocalStorage();
      print('✅ Meal saved to local storage for non-authenticated user');
    }
    
    // Update the analyzing meal with final results
    final finalMealsList = updatedMealsWithAnalyzing.map((m) => 
      m.id == tempMealId ? finalMeal : m
    ).toList();
    updateMeals(finalMealsList);
    
    return analysisResult;
    
  } catch (e) {
    print('❌ Error during analysis: $e');
    
    // Create failed meal record
    final failedMeal = analyzingMeal.copyWith(
      name: 'Analysis Failed',
      isAnalyzing: false,
      analysisFailed: true,
    );
    
    // Update the analyzing meal with failed state
    final failedMealsList = updatedMealsWithAnalyzing.map((m) => 
      m.id == tempMealId ? failedMeal : m
    ).toList();
    updateMeals(failedMealsList);
    
    return null;
  }
} 