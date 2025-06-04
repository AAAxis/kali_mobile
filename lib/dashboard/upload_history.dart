import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'details.dart';
import 'dart:io';
import 'dashboard.dart';
import 'package:vibration/vibration.dart';
import '../meal_analysis.dart';
import 'package:image_picker/image_picker.dart';

class MealHistory extends StatefulWidget {
  final List<Meal> meals;
  final Function(String)? onDelete;
  final VoidCallback? onAddMeal;
  final Future<void> Function()? onRefresh;
  final void Function(List<Meal>)? updateMeals;

  const MealHistory({
    Key? key,
    required this.meals,
    this.onDelete,
    this.onAddMeal,
    this.onRefresh,
    this.updateMeals,
  }) : super(key: key);

  @override
  State<MealHistory> createState() => _MealHistoryState();
}

class _MealHistoryState extends State<MealHistory> {
  String _filter = 'Recent';

  List<Meal> get _filteredMeals {
    List<Meal> meals = List<Meal>.from(widget.meals);
    switch (_filter) {
      case 'Favorites':
        meals = meals.where((m) => m.isFavorite).toList();
        break;
      case 'Recent':
      default:
        meals.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        break;
    }
    return meals;
  }

  Future<void> _handleRefresh() async {
    // No-op: refresh is now handled by the parent dashboard
  }

  BoxDecoration _commonBoxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.07),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  BoxDecoration _welcomeBoxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.grey[300]!, width: 1.0),
    );
  }

  // Helper method to build meal image widget based on URL type
  Widget _buildMealImage(String imageUrl) {
    // Check if it's a local file path or network URL
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      // Network image
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Error loading network image: $error');
          return Container(
            color: Colors.grey[200],
            child: const Icon(
              Icons.broken_image,
              color: Colors.grey,
              size: 32,
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[100],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
              ),
            ),
          );
        },
      );
    } else {
      // Local file path
      final file = File(imageUrl);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('❌ Error loading local image: $error');
            return Container(
              color: Colors.grey[200],
              child: const Icon(
                Icons.broken_image,
                color: Colors.grey,
                size: 32,
              ),
            );
          },
        );
      } else {
        print('❌ Local file does not exist: $imageUrl');
        return Container(
          color: Colors.grey[200],
          child: const Icon(
            Icons.photo,
            color: Colors.grey,
            size: 32,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Building MealHistory with ${widget.meals.length} meals");

    return Center(
      child: SizedBox(
        width: 354, // Match WelcomeSection/macrosRowWidth
        child: ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_filteredMeals.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'dashboard.no_meals'.tr(),
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredMeals.length,
                    itemBuilder: (context, index) {
                      final meal = _filteredMeals[index];
                      // Debug print for meal fields
                      print(
                        "Meal at index $index: name=${meal.name}, id=${meal.id}, fields available=${meal.toJson().keys}",
                      );
                      final macros = meal.macros;

                      if (meal.isAnalyzing) {
                        return Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 4,
                          ),
                          decoration: _welcomeBoxDecoration(),
                          height: 120,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child:
                                    meal.imageUrl != null
                                        ? Image.file(
                                          File(meal.imageUrl!),
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        )
                                        : Container(
                                          width: 120,
                                          height: 120,
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons.photo,
                                            color: Colors.grey,
                                            size: 32,
                                          ),
                                        ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Analyzing...',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(fontSize: 17),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 2,
                                      child: LinearProgressIndicator(
                                        backgroundColor: Colors.white,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.blue,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                          ),
                        );
                      }

                      if (meal.analysisFailed) {
                        return ListTile(
                          leading:
                              meal.imageUrl != null
                                  ? Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      image: DecorationImage(
                                        image: FileImage(File(meal.imageUrl!)),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )
                                  : Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: Colors.grey[200],
                                    ),
                                    child: const Icon(
                                      Icons.photo,
                                      color: Colors.grey,
                                      size: 32,
                                    ),
                                  ),
                          title: const Text('Analysis failed'),
                          subtitle: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.red),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () {
                                  // Retry analysis
                                  final dashboardState =
                                      context
                                          .findAncestorStateOfType<
                                            DashboardScreenState
                                          >();
                                  if (dashboardState != null) {
                                    pickAndAnalyzeImage(
                                      picker: dashboardState.picker,
                                      meals: dashboardState.meals,
                                      updateMeals: (updatedMeals) {
                                        dashboardState.setState(() {
                                          dashboardState.meals = updatedMeals;
                                        });
                                      },
                                      context: context,
                                      retryMeal: meal,
                                      source: ImageSource.camera,
                                    );
                                  }
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      return Dismissible(
                        key: Key(meal.id),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.red),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog<bool>(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: Text(
                                        'dashboard.delete_analysis'.tr(),
                                      ),
                                      content: Text(
                                        'dashboard.delete_confirm'.tr(),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, false),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.black,
                                          ),
                                          child: Text('dashboard.cancel'.tr()),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, true),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          child: Text('dashboard.delete'.tr()),
                                        ),
                                      ],
                                    ),
                              ) ??
                              false;
                        },
                        onDismissed: (direction) {
                          if (widget.onDelete != null) {
                            widget.onDelete!(meal.id);
                          }
                        },
                        child: GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => AnalysisDetailsScreen(
                                      analysisId: meal.id,
                                    ),
                              ),
                            );
                            // After returning, reload meals in dashboard
                            final dashboardState =
                                context
                                    .findAncestorStateOfType<
                                      DashboardScreenState
                                    >();
                            if (dashboardState != null) {
                              dashboardState.loadMealsFromFirebase();
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            decoration: _welcomeBoxDecoration(),
                            height: 122, // Increased by 2px to fix overflow
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child:
                                      meal.imageUrl != null &&
                                              meal.imageUrl!.isNotEmpty
                                          ? LayoutBuilder(
                                            builder: (context, constraints) {
                                              final size =
                                                  constraints.maxHeight;
                                              return SizedBox(
                                                width: size,
                                                height: size,
                                                child: _buildMealImage(meal.imageUrl!),
                                              );
                                            },
                                          )
                                          : LayoutBuilder(
                                            builder: (context, constraints) {
                                              final size =
                                                  constraints.maxHeight;
                                              return Container(
                                                width: size,
                                                height: size,
                                                color: Colors.grey[200],
                                                child: const Icon(
                                                  Icons.photo,
                                                  color: Colors.grey,
                                                  size: 32,
                                                ),
                                              );
                                            },
                                          ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                meal.getMealName(Localizations.localeOf(context).languageCode),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(fontSize: 17),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                right: 8,
                                              ),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  DateFormat(
                                                    'HH:mm',
                                                  ).format(meal.timestamp),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Image.asset(
                                              'images/calories.png',
                                              width: 20,
                                              height: 20,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${meal.calories.toStringAsFixed(0)} ${'common.calories'.tr()}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Image.asset(
                                              'images/protein.png',
                                              width: 18,
                                              height: 18,
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              '${macros['proteins']?.toStringAsFixed(0) ?? 0}g',
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Image.asset(
                                              'images/carbs.png',
                                              width: 18,
                                              height: 18,
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              '${macros['carbs']?.toStringAsFixed(0) ?? 0}g',
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Image.asset(
                                              'images/fat.png',
                                              width: 18,
                                              height: 18,
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              '${macros['fats']?.toStringAsFixed(0) ?? 0}g',
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
