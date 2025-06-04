import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';

class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  // Memory cache for quick access
  static final Map<String, Uint8List> _memoryCache = {};
  static final Map<String, Widget> _widgetCache = {};
  
  // Cache settings
  static const int maxMemoryCacheSize = 50; // Maximum number of images in memory
  static const int maxDiskCacheSize = 100; // Maximum number of images on disk
  static const Duration cacheDuration = Duration(days: 30); // Cache expiry
  
  // Directory for cached images
  static Directory? _cacheDirectory;
  
  /// Initialize the cache service
  static Future<void> initialize() async {
    try {
      final directory = await getApplicationCacheDirectory();
      _cacheDirectory = Directory(path.join(directory.path, 'image_cache'));
      
      if (!await _cacheDirectory!.exists()) {
        await _cacheDirectory!.create(recursive: true);
      }
      
      // Clean up old cache files
      await _cleanupOldCacheFiles();
      
      print('✅ Image cache service initialized');
    } catch (e) {
      print('❌ Error initializing image cache service: $e');
    }
  }
  
  /// Generate a cache key from URL or file path
  static String _generateCacheKey(String source) {
    return md5.convert(utf8.encode(source)).toString();
  }
  
  /// Get cached file path
  static String _getCacheFilePath(String cacheKey) {
    return path.join(_cacheDirectory!.path, '$cacheKey.jpg');
  }
  
  /// Check if image exists in memory cache
  static bool isInMemoryCache(String source) {
    final cacheKey = _generateCacheKey(source);
    return _memoryCache.containsKey(cacheKey);
  }
  
  /// Check if image exists in disk cache
  static Future<bool> isInDiskCache(String source) async {
    if (_cacheDirectory == null) return false;
    
    final cacheKey = _generateCacheKey(source);
    final cachedFile = File(_getCacheFilePath(cacheKey));
    
    if (!await cachedFile.exists()) return false;
    
    // Check if cache is still valid
    final stat = await cachedFile.stat();
    final age = DateTime.now().difference(stat.modified);
    
    if (age > cacheDuration) {
      await cachedFile.delete();
      return false;
    }
    
    return true;
  }
  
  /// Get image data from memory cache
  static Uint8List? getFromMemoryCache(String source) {
    final cacheKey = _generateCacheKey(source);
    return _memoryCache[cacheKey];
  }
  
  /// Get image data from disk cache
  static Future<Uint8List?> getFromDiskCache(String source) async {
    if (!await isInDiskCache(source)) return null;
    
    try {
      final cacheKey = _generateCacheKey(source);
      final cachedFile = File(_getCacheFilePath(cacheKey));
      return await cachedFile.readAsBytes();
    } catch (e) {
      print('❌ Error reading from disk cache: $e');
      return null;
    }
  }
  
  /// Store image data in memory cache
  static void storeInMemoryCache(String source, Uint8List data) {
    final cacheKey = _generateCacheKey(source);
    
    // If memory cache is full, remove oldest entry
    if (_memoryCache.length >= maxMemoryCacheSize) {
      final firstKey = _memoryCache.keys.first;
      _memoryCache.remove(firstKey);
      _widgetCache.remove(firstKey);
    }
    
    _memoryCache[cacheKey] = data;
  }
  
  /// Store image data in disk cache
  static Future<void> storeInDiskCache(String source, Uint8List data) async {
    if (_cacheDirectory == null) return;
    
    try {
      final cacheKey = _generateCacheKey(source);
      final cachedFile = File(_getCacheFilePath(cacheKey));
      await cachedFile.writeAsBytes(data);
      
      // Update cache metadata
      await _updateCacheMetadata(cacheKey);
      
      // Clean up if disk cache is too large
      await _cleanupDiskCache();
    } catch (e) {
      print('❌ Error storing in disk cache: $e');
    }
  }
  
  /// Download and cache network image
  static Future<Uint8List?> _downloadAndCacheImage(String imageUrl) async {
    try {
      print('📥 Downloading image: $imageUrl');
      
      final response = await http.get(
        Uri.parse(imageUrl),
        headers: {
          'User-Agent': 'KaliAI/1.0',
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.bodyBytes;
        
        // Store in both memory and disk cache
        storeInMemoryCache(imageUrl, data);
        await storeInDiskCache(imageUrl, data);
        
        print('✅ Image downloaded and cached: ${data.length} bytes');
        return data;
      } else {
        print('❌ Failed to download image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error downloading image: $e');
      return null;
    }
  }
  
  /// Get cached widget for display
  static Widget? getCachedWidget(String source, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    final cacheKey = _generateCacheKey(source);
    return _widgetCache[cacheKey];
  }
  
  /// Store widget in cache
  static void storeCachedWidget(String source, Widget widget) {
    final cacheKey = _generateCacheKey(source);
    
    // If widget cache is full, remove oldest entry
    if (_widgetCache.length >= maxMemoryCacheSize) {
      final firstKey = _widgetCache.keys.first;
      _widgetCache.remove(firstKey);
    }
    
    _widgetCache[cacheKey] = widget;
  }
  
  /// Get cached image widget with automatic caching
  static Widget getCachedImage(
    String source, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Widget? placeholder,
    Widget? errorWidget,
    bool useMemoryCache = true,
    bool useDiskCache = true,
  }) {
    // Check if we have a cached widget first
    final cachedWidget = getCachedWidget(source);
    if (cachedWidget != null && useMemoryCache) {
      return cachedWidget;
    }
    
    // Determine if it's a network URL or local file
    final isNetworkImage = source.startsWith('http://') || source.startsWith('https://');
    
    if (isNetworkImage) {
      return _buildNetworkCachedImage(
        source,
        fit: fit,
        width: width,
        height: height,
        placeholder: placeholder,
        errorWidget: errorWidget,
        useMemoryCache: useMemoryCache,
        useDiskCache: useDiskCache,
      );
    } else {
      return _buildLocalCachedImage(
        source,
        fit: fit,
        width: width,
        height: height,
        placeholder: placeholder,
        errorWidget: errorWidget,
        useMemoryCache: useMemoryCache,
      );
    }
  }
  
  /// Build network cached image widget
  static Widget _buildNetworkCachedImage(
    String imageUrl, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Widget? placeholder,
    Widget? errorWidget,
    bool useMemoryCache = true,
    bool useDiskCache = true,
  }) {
    return FutureBuilder<Uint8List?>(
      future: _getNetworkImageData(imageUrl, useMemoryCache: useMemoryCache, useDiskCache: useDiskCache),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return placeholder ?? _buildLoadingPlaceholder(width, height);
        }
        
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return errorWidget ?? _buildErrorWidget(width, height);
        }
        
        final imageWidget = Image.memory(
          snapshot.data!,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (context, error, stackTrace) {
            return errorWidget ?? _buildErrorWidget(width, height);
          },
        );
        
        // Cache the widget for future use
        if (useMemoryCache) {
          storeCachedWidget(imageUrl, imageWidget);
        }
        
        return imageWidget;
      },
    );
  }
  
  /// Build local cached image widget
  static Widget _buildLocalCachedImage(
    String filePath, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Widget? placeholder,
    Widget? errorWidget,
    bool useMemoryCache = true,
  }) {
    return FutureBuilder<Uint8List?>(
      future: _getLocalImageData(filePath, useMemoryCache: useMemoryCache),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return placeholder ?? _buildLoadingPlaceholder(width, height);
        }
        
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return errorWidget ?? _buildErrorWidget(width, height);
        }
        
        final imageWidget = Image.memory(
          snapshot.data!,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (context, error, stackTrace) {
            return errorWidget ?? _buildErrorWidget(width, height);
          },
        );
        
        // Cache the widget for future use
        if (useMemoryCache) {
          storeCachedWidget(filePath, imageWidget);
        }
        
        return imageWidget;
      },
    );
  }
  
  /// Get network image data with caching
  static Future<Uint8List?> _getNetworkImageData(
    String imageUrl, {
    bool useMemoryCache = true,
    bool useDiskCache = true,
  }) async {
    // Check memory cache first
    if (useMemoryCache) {
      final memoryData = getFromMemoryCache(imageUrl);
      if (memoryData != null) {
        print('📦 Image loaded from memory cache');
        return memoryData;
      }
    }
    
    // Check disk cache
    if (useDiskCache) {
      final diskData = await getFromDiskCache(imageUrl);
      if (diskData != null) {
        print('💾 Image loaded from disk cache');
        // Also store in memory cache for faster access
        if (useMemoryCache) {
          storeInMemoryCache(imageUrl, diskData);
        }
        return diskData;
      }
    }
    
    // Download and cache
    return await _downloadAndCacheImage(imageUrl);
  }
  
  /// Get local image data with caching
  static Future<Uint8List?> _getLocalImageData(
    String filePath, {
    bool useMemoryCache = true,
  }) async {
    try {
      // Check memory cache first
      if (useMemoryCache) {
        final memoryData = getFromMemoryCache(filePath);
        if (memoryData != null) {
          print('📦 Local image loaded from memory cache');
          return memoryData;
        }
      }
      
      final file = File(filePath);
      if (!await file.exists()) {
        print('❌ Local file does not exist: $filePath');
        return null;
      }
      
      final data = await file.readAsBytes();
      
      // Store in memory cache
      if (useMemoryCache) {
        storeInMemoryCache(filePath, data);
      }
      
      print('📱 Local image loaded from file');
      return data;
    } catch (e) {
      print('❌ Error loading local image: $e');
      return null;
    }
  }
  
  /// Build loading placeholder
  static Widget _buildLoadingPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[100],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
        ),
      ),
    );
  }
  
  /// Build error widget
  static Widget _buildErrorWidget(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Icon(
        Icons.broken_image,
        color: Colors.grey,
        size: 32,
      ),
    );
  }
  
  /// Update cache metadata for cleanup
  static Future<void> _updateCacheMetadata(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metadata = prefs.getStringList('image_cache_metadata') ?? [];
      
      // Remove existing entry if present
      metadata.removeWhere((entry) => entry.startsWith('$cacheKey:'));
      
      // Add new entry with timestamp
      metadata.add('$cacheKey:${DateTime.now().millisecondsSinceEpoch}');
      
      await prefs.setStringList('image_cache_metadata', metadata);
    } catch (e) {
      print('❌ Error updating cache metadata: $e');
    }
  }
  
  /// Clean up old cache files
  static Future<void> _cleanupOldCacheFiles() async {
    if (_cacheDirectory == null) return;
    
    try {
      final now = DateTime.now();
      final files = await _cacheDirectory!.list().toList();
      
      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          final age = now.difference(stat.modified);
          
          if (age > cacheDuration) {
            await file.delete();
            print('🗑️ Deleted expired cache file: ${path.basename(file.path)}');
          }
        }
      }
    } catch (e) {
      print('❌ Error cleaning up old cache files: $e');
    }
  }
  
  /// Clean up disk cache when it gets too large
  static Future<void> _cleanupDiskCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metadata = prefs.getStringList('image_cache_metadata') ?? [];
      
      if (metadata.length <= maxDiskCacheSize) return;
      
      // Sort by timestamp (oldest first)
      metadata.sort((a, b) {
        final timestampA = int.parse(a.split(':')[1]);
        final timestampB = int.parse(b.split(':')[1]);
        return timestampA.compareTo(timestampB);
      });
      
      // Remove oldest files
      final filesToRemove = metadata.take(metadata.length - maxDiskCacheSize);
      for (final entry in filesToRemove) {
        final cacheKey = entry.split(':')[0];
        final filePath = _getCacheFilePath(cacheKey);
        final file = File(filePath);
        
        if (await file.exists()) {
          await file.delete();
          print('🗑️ Deleted old cache file: $cacheKey');
        }
      }
      
      // Update metadata
      final remainingMetadata = metadata.skip(metadata.length - maxDiskCacheSize).toList();
      await prefs.setStringList('image_cache_metadata', remainingMetadata);
      
    } catch (e) {
      print('❌ Error cleaning up disk cache: $e');
    }
  }
  
  /// Clear all caches
  static Future<void> clearAllCaches() async {
    try {
      // Clear memory cache
      _memoryCache.clear();
      _widgetCache.clear();
      
      // Clear disk cache
      if (_cacheDirectory != null && await _cacheDirectory!.exists()) {
        final files = await _cacheDirectory!.list().toList();
        for (final file in files) {
          if (file is File) {
            await file.delete();
          }
        }
      }
      
      // Clear metadata
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('image_cache_metadata');
      
      print('✅ All image caches cleared');
    } catch (e) {
      print('❌ Error clearing caches: $e');
    }
  }
  
  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final memoryCount = _memoryCache.length;
      final widgetCount = _widgetCache.length;
      
      int diskCount = 0;
      int diskSizeBytes = 0;
      
      if (_cacheDirectory != null && await _cacheDirectory!.exists()) {
        final files = await _cacheDirectory!.list().toList();
        for (final file in files) {
          if (file is File) {
            diskCount++;
            final stat = await file.stat();
            diskSizeBytes += stat.size;
          }
        }
      }
      
      return {
        'memoryCount': memoryCount,
        'widgetCount': widgetCount,
        'diskCount': diskCount,
        'diskSizeBytes': diskSizeBytes,
        'diskSizeMB': (diskSizeBytes / (1024 * 1024)).toStringAsFixed(2),
      };
    } catch (e) {
      print('❌ Error getting cache stats: $e');
      return {};
    }
  }
  
  /// Preload image into cache
  static Future<void> preloadImage(String source) async {
    if (source.startsWith('http://') || source.startsWith('https://')) {
      await _getNetworkImageData(source);
    } else {
      await _getLocalImageData(source);
    }
  }
  
  /// Preload multiple images
  static Future<void> preloadImages(List<String> sources) async {
    final futures = sources.map((source) => preloadImage(source));
    await Future.wait(futures);
  }
} 