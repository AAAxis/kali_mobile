import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class UploadService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  
  /// Upload an image file to Firebase Storage
  static Future<String> uploadImage(File imageFile) async {
    try {
      print('📤 Starting image upload to Firebase Storage...');
      
      // Generate a unique filename
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final String filePath = 'images/$fileName';
      
      print('📤 Uploading to path: $filePath');
      
      // Create a reference to the file location in Firebase Storage
      final Reference storageRef = _storage.ref().child(filePath);
      
      // Set metadata (optional)
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploaded_at': DateTime.now().toIso8601String(),
        },
      );
      
      // Upload the file
      final UploadTask uploadTask = storageRef.putFile(imageFile, metadata);
      
      // Monitor upload progress (optional)
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('📤 Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });
      
      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      
      // Get the download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ Image uploaded successfully to Firebase Storage: $downloadUrl');
      return downloadUrl;
      
    } catch (e) {
      print('❌ Error uploading image to Firebase Storage: $e');
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

  /// Delete an image from Firebase Storage using its URL
  static Future<void> deleteImage(String downloadUrl) async {
    try {
      print('🗑️ Deleting image from Firebase Storage...');
      
      // Get reference from download URL
      final Reference ref = _storage.refFromURL(downloadUrl);
      
      // Delete the file
      await ref.delete();
      
      print('✅ Image deleted successfully from Firebase Storage');
    } catch (e) {
      print('❌ Error deleting image from Firebase Storage: $e');
      rethrow;
    }
  }

  /// Get metadata for an uploaded image
  static Future<FullMetadata> getImageMetadata(String downloadUrl) async {
    try {
      final Reference ref = _storage.refFromURL(downloadUrl);
      return await ref.getMetadata();
    } catch (e) {
      print('❌ Error getting image metadata: $e');
      rethrow;
    }
  }

  /// Upload multiple images in parallel
  static Future<List<String>> uploadMultipleImages(List<File> imageFiles) async {
    try {
      print('📤 Starting upload of ${imageFiles.length} images...');
      
      final List<Future<String>> uploadFutures = imageFiles.map((file) => uploadImage(file)).toList();
      final List<String> downloadUrls = await Future.wait(uploadFutures);
      
      print('✅ All ${imageFiles.length} images uploaded successfully');
      return downloadUrls;
    } catch (e) {
      print('❌ Error uploading multiple images: $e');
      rethrow;
    }
  }
} 