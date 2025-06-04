import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'macro_item.dart';
import 'neutrition_item_screen.dart';

class ScanCompletedScreen extends StatefulWidget {
  const ScanCompletedScreen({super.key});

  @override
  State<ScanCompletedScreen> createState() => _ScanCompletedScreenState();
}

class _ScanCompletedScreenState extends State<ScanCompletedScreen> {
  double _imageTop = 0.0;
  final double _slideDistance = 230.0;

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (details.delta.dy > 0) {
      setState(() {
        _imageTop = _slideDistance;
      });
    } else if (details.delta.dy < 0) {
      setState(() {
        _imageTop = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onVerticalDragUpdate: _onVerticalDragUpdate,
          child: Container(
            height: double.infinity,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30.r),
                      topRight: Radius.circular(30.r),
                    ),
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.35,
                      width: double.infinity,
                      color: Colors.white,
                      child: Stack(
                        children: [
                          // 🖊️ Diagonal black line
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _DiagonalLinePainter(),
                            ),
                          ),
                          // 📝 Diagonal debug text
                          Align(
                            alignment: Alignment.center,
                            child: Transform.translate(
                              offset: Offset(0, -50),
                              child: Transform.rotate(
                                angle: 0.785, // 45 degrees in radians
                                child: Text(
                                  'Starts White opaque 20%,\n'
                                      'turns transparent on scroll complete\n'
                                      'Scroll range = 22% viewport height',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        ],
                      ),
                    ),
                  ),
                ),



                AnimatedPositioned(
                  duration: Duration(milliseconds: 200),
                  top: _imageTop,
                  left: 0,
                  right: 0,
                  child: Stack(
                    children: [
                      Image.asset(
                        'assets/burger2.png',
                        fit: BoxFit.contain,
                        // height: MediaQuery.of(context).size.height,
                      ),
                      // Top Left Back Button
                      Positioned(
                        top: 16,
                        left: 16,
                        child: IconButton(
                          icon: Image.asset('assets/Back.png',
                              width: 50, height: 50),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),

                      // Top Right Refresh Button
                      Positioned(
                        top: 16,
                        right: 20,
                        child: IconButton(
                          icon: Image.asset('assets/Reset.png',
                              width: 50, height: 50, color: Colors.white),
                          onPressed: () {
                            // Refresh logic
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Right Edit Button
                Positioned(
                  bottom: 450,
                  right: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.black87,
                    radius: 24,
                    child: IconButton(
                      icon: Image.asset('assets/Edit.png',
                          width: 24, height: 24, color: Colors.white),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          builder: (context) => const _EditBottomSheet(),
                        );
                      },
                    ),
                  ),
                ),

                // Info Panel
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  top: MediaQuery.of(context).size.height * 0.45,
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30.r),
                            topRight: Radius.circular(30.r),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Double Cheese Burger",
                                style: TextStyle(
                                    fontSize: 32.sp,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Image.asset('assets/Image.png',
                                        width: 24, height: 24),
                                    const SizedBox(width: 6),
                                    Text("720 calories",
                                        style: TextStyle(
                                            fontSize: 24.sp,
                                            color: Colors.black,
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Rich in Vitamins\n',
                                        style: TextStyle(
                                          fontSize: 17.sp,
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'B12, B6',
                                        style: TextStyle(
                                          fontSize: 24.sp,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.right,
                                )
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: const [
                                NutrientItem(
                                    label: "Protein",
                                    value: "70g",
                                    imagePath: "assets/Protein.png"),
                                NutrientItem(
                                    label: "Carbs",
                                    value: "70g",
                                    imagePath: "assets/Carb.png"),
                                NutrientItem(
                                    label: "Fats",
                                    value: "70g",
                                    imagePath: "assets/Fat.png"),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Text("😄",
                                    style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 6),
                                Text("Good For Building Muscle !",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15.sp)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text:
                                        'Beef is a complete protein,\nit contains all nine essential amino acids.\nEating more beef will help you ',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.grey[700],
                                      height: 1.4,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Get Stronger!',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          color: Colors.black,
                          padding: EdgeInsets.symmetric(
                              horizontal: 20.w, vertical: 16.h),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Nutrients:",
                                    style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                                const SizedBox(height: 4),
                                Text(
                                  "B12 | Iron 0.4g | Zinc 0.2g | Selenium 0.03g | Niacin 0.01g\n"
                                  "Mg 0.8g | Na 2g | Potassium 0.9g | Calcium 1g",
                                  style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.white70,
                                      height: 1.4),
                                ),
                                const SizedBox(height: 16),
                                Text("Ingredients:",
                                    style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                                const SizedBox(height: 4),
                                Text(
                                  "Ground Beef | Cheddar | Pickles | Onions | Lettuce | Bread",
                                  style: TextStyle(
                                      fontSize: 14.sp, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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


}
class _DiagonalLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1;


    final start = Offset(size.width * 0.05, size.height * 0.25);

    final end = Offset(size.width * 0.95, size.height * 0.95);

    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
class _EditBottomSheet extends StatelessWidget {
  const _EditBottomSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset('assets/burger2.png', width: 90, height: 90, fit: BoxFit.cover),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:  [
                      Text("Double Cheese Burger", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Row(
                        children: [
                        Image.asset("assets/Image.png",height: 23, width: 23,),
                          SizedBox(width: 4),
                          Text("720 calories", style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children:  [
                MacroItem(image: 'assets/Protein.png', label: 'Protein', value: '70g'),
                MacroItem(image: 'assets/Carb.png', label: 'Carbs', value: '70g'),
                MacroItem(image: 'assets/Fat.png', label: 'Fats', value: '70g'),
              ],
            ),
            const SizedBox(height: 24),
            const Text("Ingredients:", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
            const SizedBox(height: 12),
            _gridOfFields(rows: 3, columns: 3),
            const SizedBox(height: 24),
            const Text("Nutrients:", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
            const SizedBox(height: 12),
            _gridOfFields(rows: 4, columns: 3),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("UPDATE RESULTS", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _gridOfFields({required int rows, required int columns}) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(rows * columns, (index) {
        return SizedBox(
          width: 114,
          child: TextFormField(
            decoration: InputDecoration(
              hintText: 'Text line here',
              filled: true,
              fillColor: Colors.grey[200],
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        );
      }),
    );
  }
}





