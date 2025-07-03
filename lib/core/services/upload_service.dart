import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

class UploadService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload an image file to Firebase Storage
  static Future<String> uploadImage(String imagePath) async {
    try {
      final File file = File(imagePath);
      final String fileName = path.basename(file.path);
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String storagePath = 'meal_images/$timestamp-$fileName';

      final Reference ref = _storage.ref().child(storagePath);
      final UploadTask uploadTask = ref.putFile(file);
      final TaskSnapshot snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Failed to upload image');
    }
  }
  
  /// Upload image with retry logic
  static Future<String> uploadImageWithRetry(File imageFile, {int maxRetries = 3}) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await uploadImage(imageFile.path);
      } catch (e) {
        attempts++;
        print('❌ Upload attempt $attempts failed: $e');
        
        if (attempts >= maxRetries) {
          print('❌ Max upload retries exceeded');
          // Return local path as final fallback
          print('🔄 Using local file path as final fallback');
          return imageFile.path;
        }
        
        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
    
    // This should never be reached due to the fallback above
    return imageFile.path;
  }
} 