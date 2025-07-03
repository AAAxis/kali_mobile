import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../dashboard/details_screen.dart';
import '../../models/meal_model.dart';
import 'package:vibration/vibration.dart';
import '../../../core/services/openai_service.dart';
import '../../../core/services/upload_service.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CameraScreen extends StatefulWidget {
  final List<Meal>? meals;
  final Function(List<Meal>)? updateMeals;

  const CameraScreen({
    Key? key,
    this.meals,
    this.updateMeals,
  }) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  bool _isFlashOn = false;
  bool _isPermissionGranted = false;
  String? _capturedImagePath;

  late AnimationController _captureAnimationController;
  late AnimationController _flashAnimationController;
  late Animation<double> _captureAnimation;
  late Animation<double> _flashAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    _checkPermissionsAndInitialize();
  }

  Future<void> _checkPermissionsAndInitialize() async {
    // Add a small delay to ensure the widget is fully mounted
    await Future.delayed(const Duration(milliseconds: 100));
    await _requestCameraPermissionAndInitialize();
  }

  Future<void> _requestCameraPermissionAndInitialize() async {
    try {
      print('🔍 Initializing camera directly...');
      await _initializeCamera();
    } catch (e) {
      print('❌ Error initializing camera: $e');
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _initializeAnimations() {
    _captureAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _flashAnimationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _captureAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _captureAnimationController,
      curve: Curves.easeInOut,
    ));

    _flashAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flashAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeCamera() async {
    try {
      print('📷 Initializing camera...');

      // Add a small delay to ensure proper initialization
      await Future.delayed(const Duration(milliseconds: 200));

      // Get available cameras
      _cameras = await availableCameras();
      print('📱 Found ${_cameras?.length ?? 0} cameras');
      
      if (_cameras == null || _cameras!.isEmpty) {
        print('❌ No cameras available on device');
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }

      // Initialize camera controller with more robust settings
      final camera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );
      
      print('📸 Using camera: ${camera.name}');

      final status = await Permission.camera.request();
      if (status.isGranted) {
        setState(() => _isPermissionGranted = true);
        
        _controller = CameraController(
          camera,
          ResolutionPreset.medium, // Use medium instead of high for better compatibility
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        print('🔧 Initializing camera controller...');
        await _controller!.initialize();
        
        // Verify camera is actually working
        if (!_controller!.value.isInitialized) {
          throw Exception('Camera failed to initialize properly');
        }
        
        print('✅ Camera controller initialized successfully');
        
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
          print('🎯 Camera UI updated');
        }
      }
    } catch (e) {
      print('❌ Error initializing camera: $e');
      print('❌ Error details: ${e.runtimeType}');
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final newFlashMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
      await _controller!.setFlashMode(newFlashMode);
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      print('Error toggling flash: $e');
    }
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) {
      return;
    }

    try {
      setState(() {
        _isCapturing = true;
      });

      // Haptic feedback
      try {
        if (await Vibration.hasVibrator() == true) {
          Vibration.vibrate(duration: 50);
        }
      } catch (e) {
        // Ignore vibration errors
      }

      // Capture animation
      _captureAnimationController.forward().then((_) {
        _captureAnimationController.reverse();
      });

      // Flash animation for visual feedback
      _flashAnimationController.forward().then((_) {
        _flashAnimationController.reverse();
      });

      // Set flash mode for capture
      if (_isFlashOn) {
        await _controller!.setFlashMode(FlashMode.always);
      }

      final XFile image = await _controller!.takePicture();

      // Reset flash mode
      if (_isFlashOn) {
        await _controller!.setFlashMode(FlashMode.torch);
      }

      if (mounted) {
        // Navigate back and start analysis
        print('📸 Photo captured: ${image.path}');
        Navigator.of(context).pop();
        
        // Start meal analysis
        if (widget.updateMeals != null && widget.meals != null) {
          print('📸 Starting analysis for camera image...');
          await analyzeImageFile(image.path);
          print('📸 Camera image analysis completed');
        } else {
          print('❌ updateMeals or meals is null');
        }
      }
    } catch (e) {
      print('Error capturing photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture photo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      print('📱 _pickFromGallery called');
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null && mounted) {
        print('📱 Image selected from gallery: ${image.path}');
        Navigator.of(context).pop();
        
        if (widget.updateMeals != null && widget.meals != null) {
          print('📱 Starting analysis for gallery image...');
          await analyzeImageFile(image.path);
          print('📱 Gallery image analysis completed');
        } else {
          print('❌ updateMeals or meals is null');
        }
      } else {
        print('📱 No image selected from gallery');
      }
    } catch (e) {
      print('Error picking from gallery: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick from gallery: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> analyzeImageFile(String imagePath) async {
    try {
      setState(() {
        _isCapturing = true;
      });

      // Upload image and get URL
      final imageUrl = await UploadService.uploadImage(imagePath);
      
      // Analyze image with OpenAI
      final analysis = await OpenAIService.analyzeImage(imageUrl);
      
      if (analysis != null) {
        await _handleAnalysisResult(analysis);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error analyzing image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _handleAnalysisResult(Map<String, dynamic> analysis) async {
    final newMeal = Meal(
      id: const Uuid().v4(),
      userId: FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
      timestamp: DateTime.now(),
      name: analysis['name'] ?? 'Unknown Meal',
      calories: analysis['calories']?.toDouble() ?? 0.0,
      protein: analysis['protein']?.toDouble() ?? 0.0,
      carbs: analysis['carbs']?.toDouble() ?? 0.0,
      fat: analysis['fat']?.toDouble() ?? 0.0,
      imageUrl: _capturedImagePath,
    );

    if (widget.meals != null) {
      final updatedMeals = [...widget.meals!, newMeal];
      await Meal.saveToLocalStorage(updatedMeals);
      
      if (widget.updateMeals != null) {
        widget.updateMeals!(updatedMeals);
      }
    }

    if (mounted) {
      Navigator.pop(context); // Return to previous screen
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _captureAnimationController.dispose();
    _flashAnimationController.dispose();
    super.dispose();
  }

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized || _controller == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_controller!),
        
        // Flash overlay for capture feedback
        AnimatedBuilder(
          animation: _flashAnimation,
          builder: (context, child) {
            return Container(
              color: Colors.white.withOpacity(_flashAnimation.value * 0.8),
            );
          },
        ),
        
        // Camera overlay with guides
        CustomPaint(
          painter: CameraOverlayPainter(
            Colors.white,
          ),
          size: Size.infinite,
        ),
      ],
    );
  }

  Widget _buildTopControls() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Close button
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            
            // Flash toggle
            GestureDetector(
                onTap: _toggleFlash,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isFlashOn ? Icons.flash_on : Icons.flash_off,
                    color: _isFlashOn ? Colors.yellow : Colors.white,
                    size: 24,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Gallery button
              GestureDetector(
                onTap: _pickFromGallery,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              
              // Capture button
              GestureDetector(
                onTap: _isCapturing ? null : _capturePhoto,
                child: AnimatedBuilder(
                  animation: _captureAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _captureAnimation.value,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 4,
                          ),
                        ),
                        child: _isCapturing
                            ? const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt,
                                color: Colors.black,
                                size: 32,
                              ),
                      ),
                    );
                  },
                ),
              ),
              
              // Placeholder to maintain layout balance
              Container(
                width: 56,
                height: 56,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPermissionGranted) {
      return const Center(child: Text('Camera permission not granted'));
    }

    if (!_isCameraInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildCameraPreview(),
          _buildTopControls(),
          _buildBottomControls(),
        ],
      ),
    );
  }
}

class CameraOverlayPainter extends CustomPainter {
  final Color color;

  CameraOverlayPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final rectSize = size.width * 0.7;
    final rect = Rect.fromCenter(
      center: center,
      width: rectSize,
      height: rectSize * 0.75,
    );

    // Draw corner brackets
    final cornerLength = 20.0;
    
    // Top-left corner
    canvas.drawLine(
      Offset(rect.left, rect.top + cornerLength),
      Offset(rect.left, rect.top),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left + cornerLength, rect.top),
      paint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(rect.right - cornerLength, rect.top),
      Offset(rect.right, rect.top),
      paint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.top + cornerLength),
      paint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(rect.left, rect.bottom - cornerLength),
      Offset(rect.left, rect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.left + cornerLength, rect.bottom),
      paint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(rect.right - cornerLength, rect.bottom),
      Offset(rect.right, rect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom - cornerLength),
      Offset(rect.right, rect.bottom),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 