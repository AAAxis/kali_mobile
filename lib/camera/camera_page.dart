import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with TickerProviderStateMixin {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isFlashOn = false;
  bool _isCapturing = false;
  
  // Animation controller for progress bar
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;
  bool _isProcessing = false;
  File? _capturedImage; // Store the captured image

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    
    // Initialize animation controller
    _progressAnimationController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // Listen for animation completion
    _progressAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Return the captured image when animation completes
        if (mounted && _capturedImage != null) {
          Navigator.of(context).pop(_capturedImage);
        }
      }
    });
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.high,
    );

    _initializeControllerFuture = _controller!.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller != null && _controller!.value.isInitialized) {
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
      await _controller!.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
    }
  }

  Future<void> _captureImage() async {
    if (_controller != null && _controller!.value.isInitialized && !_isCapturing && !_isProcessing) {
      setState(() {
        _isCapturing = true;
      });

      try {
        final XFile image = await _controller!.takePicture();
        
        // Store the captured image
        _capturedImage = File(image.path);
        
        // Show snack bar message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Hold still, we working on image',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.black.withOpacity(0.8),
            duration: Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Start processing animation
        setState(() {
          _isCapturing = false;
          _isProcessing = true;
        });
        
        // Start the 5-second animation
        _progressAnimationController.forward();
        
        // Navigation will be handled by animation completion listener
        
      } catch (e) {
        print('Error capturing image: $e');
        // Show error message to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture image: $e')),
        );
        setState(() {
          _isCapturing = false;
          _isProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(
      context,
      designSize: const Size(438, 950),
      minTextAdapt: true,
      splitScreenMode: true,
    );

    return Scaffold(
      body: Stack(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: CameraPreview(_controller!),
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Close button
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 24.w,
                          ),
                        ),
                      ),
                      // Flash button
                      GestureDetector(
                        onTap: _toggleFlash,
                        child: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isFlashOn ? Icons.flash_on : Icons.flash_off,
                            color: Colors.white,
                            size: 24.w,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                CustomProgressBar(
                  animation: _progressAnimation,
                  isProcessing: _isProcessing,
                ),
                Center(
                  child: Container(
                    margin: EdgeInsets.only(top: 102.h),
                    width: 300.w,
                    height: 300.h,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(10.r),
                                  ),
                                  border: Border(
                                    top: BorderSide(
                                        color: Colors.white, width: 2.w),
                                    left: BorderSide(
                                        color: Colors.white, width: 2.w),
                                  ),
                                ),
                                width: 66.w,
                                height: 66.h),
                            Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(10.r),
                                  ),
                                  border: Border(
                                    top: BorderSide(
                                        color: Colors.white, width: 2.w),
                                    right: BorderSide(
                                        color: Colors.white, width: 2.w),
                                  ),
                                ),
                                width: 66.w,
                                height: 66.h),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(10.r),
                                  ),
                                  border: Border(
                                    bottom: BorderSide(
                                        color: Colors.white, width: 2.w),
                                    left: BorderSide(
                                        color: Colors.white, width: 2.w),
                                  ),
                                ),
                                width: 66.w,
                                height: 66.h),
                            Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    bottomRight: Radius.circular(10.r),
                                  ),
                                  border: Border(
                                    bottom: BorderSide(
                                        color: Colors.white, width: 2.w),
                                    right: BorderSide(
                                        color: Colors.white, width: 2.w),
                                  ),
                                ),
                                width: 66.w,
                                height: 66.h),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SizedBox(),
                ),
                // Temporarily disabled - will be used later
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                //   crossAxisAlignment: CrossAxisAlignment.center,
                //   children: [
                //     containerButton(
                //         assetName: "assets/barCodeIcon.png",
                //         onTap: () {},
                //         text: "Barcode"),
                //     containerButton(
                //         assetName: "assets/scanFoodIcon.png",
                //         onTap: () {},
                //         text: "Scan Food"),
                //     containerButton(
                //         assetName: "assets/menuIcon.png",
                //         onTap: () {},
                //         text: "Menu"),
                //   ],
                // ),
                MainCameraButtonsWidget(
                  onCapturePressed: _captureImage,
                  isCapturing: _isCapturing,
                  isProcessing: _isProcessing,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(
      {required String iconPath, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40.w,
        height: 40.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Center(
          child: SvgPicture.asset(
            iconPath,
            width: 24.w,
            height: 24.h,
          ),
        ),
      ),
    );
  }
}

class CustomProgressBar extends StatelessWidget {
  final Animation<double> animation;
  final bool isProcessing;

  const CustomProgressBar({
    super.key,
    required this.animation,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Column(
          children: [
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(20.r)),
                  color: Color(0xffF4F4F4)),
              margin: EdgeInsets.only(
                left: 39.w,
                top: 35.h,
                right: 35.w,
                bottom: 13.h,
              ),
              height: 7.h,
              width: 347.w,
              child: LinearProgressIndicator(
                borderRadius: BorderRadius.all(Radius.circular(20.r)),
                value: animation.value,
                backgroundColor: Color(0xff6B6B6B).withValues(alpha: 0.70),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 43.w, right: 35.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isProcessing ? "Processing" : "Thinking",
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.70),
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(
                    width: 77.w,
                  ),
                  Text(
                    isProcessing ? "Analyzing Food" : "Testing Food",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(
                    width: 34.w,
                  ),
                  Text(
                    isProcessing ? "Finalizing" : "Checking Carbs",
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.70),
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

Widget containerButton(
    {required String assetName,
    required Function() onTap,
    required String text}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      alignment: Alignment.center,
      width: 102.w,
      height: 95.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            assetName,
            height: 44.h,
            width: 44.w,
          ),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          )
        ],
      ),
    ),
  );
}

class MainCameraButtonsWidget extends StatelessWidget {
  final Function() onCapturePressed;
  final bool isCapturing;
  final bool isProcessing;

  const MainCameraButtonsWidget({
    super.key,
    required this.onCapturePressed,
    required this.isCapturing,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(top: 49.h, left: 53.w, right: 48.w, bottom: 78.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SizedBox(width: 96.w),
          GestureDetector(
            onTap: (isCapturing || isProcessing) ? null : onCapturePressed,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  "assets/cameraButtonIcon.png",
                  height: 75.h,
                  width: 75.w,
                ),
                if (isCapturing)
                  SizedBox(
                    width: 50.w,
                    height: 50.h,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                if (isProcessing)
                  SizedBox(
                    width: 50.w,
                    height: 50.h,
                    child: CircularProgressIndicator(
                      color: Colors.green,
                      strokeWidth: 3,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 77.w),
          GestureDetector(
            onTap: (isCapturing || isProcessing) ? null : () => Navigator.of(context).pop(),
            child: Opacity(
              opacity: (isCapturing || isProcessing) ? 0.5 : 1.0,
              child: Image.asset(
                "assets/galleryIcon.png",
                height: 55.h,
                width: 55.w,
              ),
            ),
          )
        ],
      ),
    );
  }
}
