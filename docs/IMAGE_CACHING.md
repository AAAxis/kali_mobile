# Image Caching System

This app includes a comprehensive image caching system that automatically handles both network and local image caching to improve performance and reduce data usage.

## Features

- **Two-level caching**: Memory cache for instant loading and disk cache for offline access
- **Automatic management**: Configurable cache size limits and automatic cleanup
- **Universal support**: Works with both network URLs and local file paths
- **Smart fallbacks**: Graceful error handling with customizable placeholder and error widgets
- **Easy to use**: Simple widgets and service methods

## Quick Start

### Using the CachedImage Widget (Recommended)

The easiest way to use cached images is with the `CachedImage` widget:

```dart
import '../widgets/cached_image.dart';

// Basic usage
CachedImage(
  imageSource: 'https://example.com/image.jpg',
  width: 200,
  height: 200,
)

// Profile image
CachedImage.profile(
  imageSource: profileImageUrl,
  size: 48,
)

// Meal image
CachedImage.meal(
  imageSource: mealImageUrl,
  width: 120,
  height: 120,
)

// Thumbnail
CachedImage.thumbnail(
  imageSource: imageUrl,
  size: 64,
)
```

### Using the ImageCacheService Directly

For more control, use the service directly:

```dart
import '../services/image_cache_service.dart';

// Get cached image widget
Widget image = ImageCacheService.getCachedImage(
  imageUrl,
  width: 200,
  height: 200,
  fit: BoxFit.cover,
  placeholder: Container(
    color: Colors.grey[100],
    child: CircularProgressIndicator(),
  ),
  errorWidget: Icon(Icons.error),
);
```

## Configuration

The cache system is automatically configured with sensible defaults:

- **Memory cache**: 50 images maximum
- **Disk cache**: 100 images maximum  
- **Cache duration**: 30 days
- **Automatic cleanup**: Runs on app start and when limits are exceeded

### Cache Settings

You can modify cache settings in `lib/services/image_cache_service.dart`:

```dart
static const int maxMemoryCacheSize = 50;
static const int maxDiskCacheSize = 100;
static const Duration cacheDuration = Duration(days: 30);
```

## Advanced Usage

### Preloading Images

```dart
// Preload single image
await ImageCacheService.preloadImage('https://example.com/image.jpg');

// Preload multiple images
await ImageCacheService.preloadImages([
  'https://example.com/image1.jpg',
  'https://example.com/image2.jpg',
]);
```

### Cache Management

```dart
// Get cache statistics
final stats = await ImageCacheService.getCacheStats();
print('Memory cache: ${stats['memoryCount']} images');
print('Disk cache: ${stats['diskCount']} images (${stats['diskSizeMB']} MB)');

// Clear all caches
await ImageCacheService.clearAllCaches();
```

### Custom Placeholders and Error Widgets

```dart
CachedImage(
  imageSource: imageUrl,
  placeholder: Container(
    width: 200,
    height: 200,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        Text('Loading...'),
      ],
    ),
  ),
  errorWidget: Container(
    width: 200,
    height: 200,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 48),
        Text('Failed to load image'),
      ],
    ),
  ),
)
```

## Performance Tips

1. **Use appropriate sizes**: Specify width and height to avoid unnecessary scaling
2. **Preload important images**: Use preloading for images that will be needed soon
3. **Use factory constructors**: `CachedImage.profile()`, `CachedImage.meal()`, etc. have optimized defaults
4. **Monitor cache usage**: Check cache stats periodically in development

## Migration from Image.network/Image.file

### Before (Image.network):
```dart
Image.network(
  imageUrl,
  width: 200,
  height: 200,
  fit: BoxFit.cover,
  loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return CircularProgressIndicator();
  },
  errorBuilder: (context, error, stackTrace) {
    return Icon(Icons.error);
  },
)
```

### After (CachedImage):
```dart
CachedImage(
  imageSource: imageUrl,
  width: 200,
  height: 200,
  fit: BoxFit.cover,
  placeholder: CircularProgressIndicator(),
  errorWidget: Icon(Icons.error),
)
```

### Benefits:
- ✅ Automatic caching (memory + disk)
- ✅ Works with both network URLs and local files
- ✅ Better performance on repeated loads
- ✅ Offline support for previously loaded images
- ✅ Automatic cache management
- ✅ Reduced data usage

## Troubleshooting

### Images not loading
1. Check network connectivity for remote URLs
2. Verify file paths for local images
3. Check console for error messages
4. Clear cache if corruption is suspected

### High memory usage
1. Reduce `maxMemoryCacheSize` if needed
2. Use appropriate image sizes
3. Clear cache periodically in long-running apps

### Cache not working
1. Ensure `ImageCacheService.initialize()` is called in `main()`
2. Check device storage permissions
3. Verify cache directory creation in logs

## File Locations

- **Main service**: `lib/services/image_cache_service.dart`
- **Widget wrapper**: `lib/widgets/cached_image.dart`
- **Initialization**: `lib/main.dart` (in `main()` function)

## Dependencies

The image caching system requires these dependencies:
- `crypto: ^3.0.3` (for cache key generation)
- `path_provider: ^2.1.2` (for cache directory)
- `shared_preferences: ^2.2.2` (for cache metadata)
- `http: ^1.1.2` (for network image downloads)

These are already included in your `pubspec.yaml`. 