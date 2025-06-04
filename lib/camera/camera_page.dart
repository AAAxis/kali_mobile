import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class CameraScreen extends StatefulWidget {
  final CameraController? preInitializedController;
  
  const CameraScreen({
    super.key, 
    this.preInitializedController,
  });

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with TickerProviderStateMixin {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  late AnimationController _slideAnimationController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _progressAnimationController;
  bool _isInitialized = false;
  bool _isCapturing = false;
  
  // Progress states
  String _currentStep = "Ready to scan";
  double _progressValue = 0.0;

  @override
  void initState() {
    super.initState();
    
    // Setup slide animation for bottom sheet effect
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    // Setup progress animation
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000), // Default duration, will be adjusted per step
      vsync: this,
    );
    
    _initializeCamera();
    
    // Start slide animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _slideAnimationController.forward();
    });
  }

  Future<void> _initializeCamera() async {
    try {
      if (widget.preInitializedController != null && 
          widget.preInitializedController!.value.isInitialized) {
        // Use pre-initialized controller
        _controller = widget.preInitializedController;
        setState(() {
          _isInitialized = true;
          _currentStep = "Ready to scan";
          _progressValue = 0.0;
        });
        print('✅ Using pre-initialized camera controller');
      } else {
        // Fallback to normal initialization with progress animation
        setState(() {
          _currentStep = "Initializing camera";
          _progressValue = 0.2;
        });
        
        final cameras = await availableCameras();
        final firstCamera = cameras.first;

        setState(() {
          _currentStep = "Setting up camera";
          _progressValue = 0.5;
        });

        _controller = CameraController(
          firstCamera,
          ResolutionPreset.high,
        );

        _initializeControllerFuture = _controller!.initialize();
        await _initializeControllerFuture;
        
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _currentStep = "Ready to scan";
            _progressValue = 0.0;
          });
        }
        print('✅ Camera initialized normally');
      }
    } catch (e) {
      print('❌ Error initializing camera: $e');
      setState(() {
        _currentStep = "Camera error";
        _progressValue = 0.0;
      });
    }
  }

  Future<void> _animateProgressSteps() async {
    final steps = [
      {"text": "Capturing image", "progress": 0.15, "mainText": "Taking Photo", "nextText": "Processing", "duration": 800},
      {"text": "Processing food", "progress": 0.35, "mainText": "Analyzing Image", "nextText": "Identifying Food", "duration": 2800},
      {"text": "Analyzing nutrition", "progress": 0.55, "mainText": "Testing Food", "nextText": "Checking Nutrients", "duration": 3500},
      {"text": "Calculating macros", "progress": 0.75, "mainText": "Calculating Macros", "nextText": "Checking Carbs", "duration": 3200},
      {"text": "Almost done", "progress": 0.90, "mainText": "Finalizing Results", "nextText": "Complete", "duration": 2500},
    ];
    
    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];
      if (!mounted || !_isCapturing) return;
      
      // Add slight delay before starting each step for natural feel
      if (i > 0) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
      
      setState(() {
        _currentStep = step["text"] as String;
        _progressValue = step["progress"] as double;
      });
      
      // Animate progress bar smoothly over a longer duration
      _progressAnimationController.duration = Duration(milliseconds: (step["duration"] as int) ~/ 3);
      _progressAnimationController.reset();
      await _progressAnimationController.forward();
      
      // Wait for the realistic analysis time for this step
      await Future.delayed(Duration(milliseconds: step["duration"] as int));
    }
  }

  @override
  void dispose() {
    _slideAnimationController.dispose();
    _progressAnimationController.dispose();
    // Only dispose if it's not the pre-initialized controller
    if (widget.preInitializedController == null) {
      _controller?.dispose();
    }
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) {
      return;
    }

    try {
      setState(() {
        _isCapturing = true;
      });
      
      // Start progress animation
      _animateProgressSteps();
      
      final XFile image = await _controller!.takePicture();
      
      // Complete progress
      setState(() {
        _currentStep = "Complete!";
        _progressValue = 1.0;
      });
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Animate out before returning result
      await _slideAnimationController.reverse();
      
      // Return the captured image file to the previous screen
      if (mounted) {
        Navigator.of(context).pop(File(image.path));
      }
    } catch (e) {
      print('Error taking picture: $e');
      setState(() {
        _currentStep = "Error occurred";
        _progressValue = 0.0;
        _isCapturing = false;
      });
    }
  }

  Future<void> _openGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        // Animate out before returning result
        await _slideAnimationController.reverse();
        
        // Return the selected image file to the previous screen
        if (mounted) {
          Navigator.of(context).pop(File(image.path));
        }
      }
    } catch (e) {
      print('Error opening gallery: $e');
    }
  }

  Future<void> _closeCamera() async {
    await _slideAnimationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
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
      backgroundColor: Colors.transparent,
      body: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.r),
              topRight: Radius.circular(20.r),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.r),
              topRight: Radius.circular(20.r),
            ),
            child: Stack(
              children: [
                // Camera preview - no spinner, just black background until initialized
                _isInitialized && _controller != null
                    ? SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: CameraPreview(_controller!),
                      )
                    : Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.black,
                      ),
                SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Close button and animated progress bar
                      Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: _isCapturing ? null : _closeCamera,
                              child: Container(
                                width: 40.w,
                                height: 40.h,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: _isCapturing ? Colors.grey : Colors.white,
                                  size: 24.w,
                                ),
                              ),
                            ),
                            Expanded(child: SizedBox()),
                          ],
                        ),
                      ),
                      AnimatedProgressBar(
                        value: _progressValue,
                        currentStep: _currentStep,
                        isCapturing: _isCapturing,
                      ),
                      // Padding(
                      //   padding: EdgeInsets.only(),
                      //   child: Row(
                      //     crossAxisAlignment: CrossAxisAlignment.start,
                      //     children: [
                      //       Text(
                      //         "Thinking",
                      //         style: GoogleFonts.inter(
                      //           color: Colors.white.withValues(alpha: 0.70),
                      //           fontSize: 11.sp,
                      //           fontWeight: FontWeight.w500,
                      //         ),
                      //       ),
                      //       SizedBox(
                      //         width: 77.w,
                      //       ),
                      //       Text(
                      //         "Testing Food",
                      //         style: GoogleFonts.inter(
                      //           color: Colors.white,
                      //           fontSize: 17.sp,
                      //           fontWeight: FontWeight.w500,
                      //         ),
                      //       ),
                      //       SizedBox(
                      //         width: 34.w,
                      //       ),
                      //       Text(
                      //         "Checking Carbs",
                      //         style: GoogleFonts.inter(
                      //           color: Colors.white.withValues(alpha: 0.70),
                      //           fontSize: 11.sp,
                      //           fontWeight: FontWeight.w500,
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // )
                      // checking protein
                      // Container(
                      //   alignment: Alignment.center,
                      //   height: 50.h,
                      //   width: 241.w,
                      //   decoration: BoxDecoration(
                      //     borderRadius: BorderRadius.circular(44.r),
                      //     color: Color(0xffFEFEFE),
                      //   ),
                      //   margin: EdgeInsets.only(top: 46.h, left: 27.w),
                      //   padding: EdgeInsets.only(left: 13.9.w),
                      //   child: Row(
                      //     children: [
                      //       Image.asset(
                      //         "assets/checkProteinImage.png",
                      //         height: 32.48.h,
                      //         width: 32.48.w,
                      //       ),
                      //       Text(
                      //         "Checking Protein",
                      //         style: GoogleFonts.inter(
                      //           fontSize: 22.sp,
                      //           fontWeight: FontWeight.w400,
                      //         ),
                      //       )
                      //     ],
                      //   ),
                      // ),
                      // progress bar

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
                      // Commented out the 3 buttons: Barcode, Scan Food, Menu
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
                        onCapturePressed: _takePicture,
                        onGalleryPressed: _openGallery,
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
  final VoidCallback? onCapturePressed;
  final VoidCallback? onGalleryPressed;
  
  const MainCameraButtonsWidget({
    super.key, 
    this.onCapturePressed,
    this.onGalleryPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(top: 49.h, left: 53.w, right: 48.w, bottom: 78.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Image.asset(
            "assets/flashIcon.png",
            height: 34.h,
            width: 34.w,
          ),
          SizedBox(width: 96.w),
          GestureDetector(
            onTap: onCapturePressed ?? () {
              // Default behavior - do nothing if no callback provided
              print('Camera capture pressed but no callback provided');
            },
            child: Image.asset(
              "assets/cameraButtonIcon.png",
              height: 75.h,
              width: 75.w,
            ),
          ),
          SizedBox(width: 77.w),
          GestureDetector(
            onTap: onGalleryPressed ?? () async {
              // Default gallery functionality
              final picker = ImagePicker();
              final XFile? image = await picker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                Navigator.of(context).pop(File(image.path));
              }
            },
            child: Image.asset(
              "assets/galleryIcon.png",
              height: 55.h,
              width: 55.w,
            ),
          )
        ],
      ),
    );
  }
}

class AnimatedProgressBar extends StatefulWidget {
  final double value;
  final String currentStep;
  final bool isCapturing;

  const AnimatedProgressBar({
    super.key,
    required this.value,
    required this.currentStep,
    required this.isCapturing,
  });

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar> 
    with TickerProviderStateMixin {
  late AnimationController _textAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  String _mainText = "Ready";
  String _nextText = "to scan";

  @override
  void initState() {
    super.initState();
    _textAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _updateStatusTexts();
    _textAnimationController.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep != widget.currentStep) {
      _animateTextChange();
    }
  }

  void _updateStatusTexts() {
    switch (widget.currentStep) {
      case "Capturing image":
        _mainText = "Taking Photo";
        _nextText = "Processing";
        break;
      case "Processing food":
        _mainText = "Analyzing Image";
        _nextText = "Identifying Food";
        break;
      case "Analyzing nutrition":
        _mainText = "Testing Food";
        _nextText = "Checking Nutrients";
        break;
      case "Calculating macros":
        _mainText = "Calculating Macros";
        _nextText = "Checking Carbs";
        break;
      case "Almost done":
        _mainText = "Finalizing Results";
        _nextText = "Complete";
        break;
      case "Complete!":
        _mainText = "Analysis Complete";
        _nextText = "Success!";
        break;
      default:
        _mainText = "Ready";
        _nextText = "to scan";
    }
  }

  void _animateTextChange() async {
    await _textAnimationController.reverse();
    _updateStatusTexts();
    await _textAnimationController.forward();
  }

  @override
  void dispose() {
    _textAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Progress bar
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(20.r)),
            color: Color(0xffF4F4F4),
          ),
          margin: EdgeInsets.only(
            left: 39.w,
            top: 35.h,
            right: 35.w,
            bottom: 13.h,
          ),
          height: 7.h,
          width: 347.w,
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                borderRadius: BorderRadius.all(Radius.circular(20.r)),
                value: widget.value,
                backgroundColor: Color(0xff6B6B6B).withValues(alpha: 0.70),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withValues(alpha: _fadeAnimation.value),
                ),
              );
            },
          ),
        ),
        // Animated status text
        Container(
          margin: EdgeInsets.symmetric(horizontal: 39.w),
          height: 50.h, // Fixed height to prevent jumping
          child: AnimatedBuilder(
            animation: _textAnimationController,
            builder: (context, child) {
              return SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Current step (left)
                      Flexible(
                        flex: 2,
                        child: Text(
                          widget.currentStep,
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.70),
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Main activity (center) - larger and prominent
                      Flexible(
                        flex: 3,
                        child: Center(
                          child: Text(
                            _mainText,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      // Next step (right)
                      Flexible(
                        flex: 2,
                        child: Text(
                          _nextText,
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.70),
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
