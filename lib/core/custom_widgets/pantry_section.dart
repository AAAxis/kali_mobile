import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../features/pages/dashboard/details_screen.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/translation_service.dart';
import '../../features/models/meal_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class PantrySection extends StatefulWidget {
  final List<Meal> meals;
  final Function(String) onDelete;
  final Future<void> Function() onRefresh;
  final Function(List<Meal>) updateMeals;
  final DateTime? selectedDate;

  const PantrySection({
    Key? key,
    required this.meals,
    required this.onDelete,
    required this.onRefresh,
    required this.updateMeals,
    this.selectedDate,
  }) : super(key: key);

  @override
  State<PantrySection> createState() => _PantrySectionState();
}

class _PantrySectionState extends State<PantrySection> {
  // Removed complex animation variables since we're using LinearProgressIndicator

  @override
  void initState() {
    super.initState();
    // No complex animations needed anymore
  }

  @override
  void didUpdateWidget(PantrySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // No animation reinitialization needed
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Date'),
        content: SizedBox(
          width: 300,
          height: 350,
          child: CalendarDatePicker(
            initialDate: DateTime.now(),
            firstDate: DateTime.now().subtract(const Duration(days: 365)),
            lastDate: DateTime.now(),
            onDateChanged: (date) {
              Navigator.of(context).pop();
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  List<Meal> get _filteredMeals {
    List<Meal> mealsList = List<Meal>.from(widget.meals);
    print('🎬 PantrySection: Total meals received: ${mealsList.length}');
    
    // Debug: Log analyzing meals
    final analyzingMeals = mealsList.where((m) => m.isAnalyzing).toList();
    print('🎬 PantrySection: Analyzing meals: ${analyzingMeals.length}');
    for (var meal in analyzingMeals) {
      print('🎬 PantrySection: Analyzing meal ID: ${meal.id}, isAnalyzing: ${meal.isAnalyzing}');
    }
    
    mealsList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    // If a specific date is selected, show all meals for that date
    // Otherwise, limit to 5 most recent meals
    if (widget.selectedDate == null && mealsList.length > 5) {
      mealsList = mealsList.take(5).toList();
    }
    
    print('🎬 PantrySection: Filtered meals count: ${mealsList.length}');
    return mealsList;
  }

  /// Translate ingredients for display based on current locale
  List<String> _getTranslatedIngredients(Meal meal) {
    final locale = Localizations.localeOf(context).languageCode;
    
    // Get English ingredients from the meal
    final englishIngredients = meal.getIngredients('en');
    
    // If current locale is English, return as-is
    if (locale == 'en') {
      return englishIngredients;
    }
    
    // Translate using static dictionary only (synchronous)
    return englishIngredients.map((ingredient) => 
      TranslationService.translateIngredientStatic(ingredient, locale)
    ).toList();
  }

  /// Get translated meal name
  String _getTranslatedMealName(Meal meal) {
    final locale = Localizations.localeOf(context).languageCode;
    
    // For analyzing meals, show a generic processing message if no meal name available
    if (meal.isAnalyzing) {
      // Check if meal has a name/mealName
      final englishName = meal.getMealName('en');
      if (englishName == 'Unknown' || englishName == 'Unknown Meal' || englishName.isEmpty) {
        return _getProcessingTitle();
      }
      // If it has a name, translate it
      if (locale == 'en') {
        return englishName;
      }
      return TranslationService.translateIngredientStatic(englishName, locale);
    }
    
    final englishName = meal.getMealName('en');
    
    // If meal name is empty, provide a fallback
    if (englishName.isEmpty || englishName == 'Unknown' || englishName == 'Unknown Meal') {
      final fallbackName = 'Analyzed Meal';
      if (locale == 'en') {
        return fallbackName;
      }
      return TranslationService.translateIngredientStatic(fallbackName, locale);
    }
    
    // If current locale is English, return as-is
    if (locale == 'en') {
      return englishName;
    }
    
    // Translate using static dictionary/translation service
    return TranslationService.translateIngredientStatic(englishName, locale);
  }

  /// Get translated processing title
  String _getProcessingTitle() {
    final locale = Localizations.localeOf(context).languageCode;
    const englishTitle = "Processing...";
    
    if (locale == 'en') {
      return englishTitle;
    }
    
    return TranslationService.translateIngredientStatic(englishTitle, locale);
  }

  /// Get translated processing text
  String _getProcessingText() {
    final locale = Localizations.localeOf(context).languageCode;
    const englishText = "AI is analyzing your meal";
    
    if (locale == 'en') {
      return englishText;
    }
    
    return TranslationService.translateIngredientStatic(englishText, locale);
  }

  Widget _buildMealImage(String imageUrl) {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[100],
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          return Container(
            color: Theme.of(context).colorScheme.surface,
            child: Icon(
              Icons.broken_image,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              size: 32,
            ),
          );
        },
        cacheKey: imageUrl.hashCode.toString(), // Use URL hash as cache key
        memCacheHeight: 200,
        memCacheWidth: 200,
      );
    } else {
      final file = File(imageUrl);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Theme.of(context).colorScheme.surface,
              child: Icon(
                Icons.broken_image,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                size: 32,
              ),
            );
          },
        );
      } else {
        return Container(
          color: Theme.of(context).colorScheme.surface,
          child: Icon(
            Icons.photo,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            size: 32,
          ),
        );
      }
    }
  }

  Widget _buildStaticAnalyzingCard(Meal meal) {
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 4,
        horizontal: 0,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      height: 122,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: meal.imageUrl != null && meal.imageUrl!.isNotEmpty
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      final size = constraints.maxHeight;
                      return SizedBox(
                        width: size,
                        height: size,
                        child: _buildMealImage(meal.imageUrl!),
                      );
                    },
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final size = constraints.maxHeight;
                      return Container(
                        width: size,
                        height: size,
                        color: Theme.of(context).colorScheme.surface,
                        child: Icon(
                          Icons.photo,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          size: 32,
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _getTranslatedMealName(meal),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.inverseSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            DateFormat('HH:mm').format(meal.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getProcessingText(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingMealCard(Meal meal) {
    // Use the same static card design since we're now using LinearProgressIndicator
    return _buildStaticAnalyzingCard(meal);
  }

  Widget _buildMealCard(Meal meal) {
    // This method is no longer used since we simplified the analyzing card
    // Just return the static analyzing card
    return _buildStaticAnalyzingCard(meal);
  }

  Future<void> _showAnalysisDetails(Meal meal) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalysisDetailsScreen(analysisId: meal.id),
      ),
    );
    // After returning, refresh meals via callback
    await widget.onRefresh();
  }



  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'dashboard.your_pantry'.tr(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
        
            ],
          ),
          const SizedBox(height: 10),
          
          // Pantry content
          if (_filteredMeals.isEmpty)
            Container(
              height: 180,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
             
                    const SizedBox(height: 12),
                    Text(
                      'dashboard.no_meals'.tr(),
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.6),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              itemCount: _filteredMeals.length,
              itemBuilder: (context, index) {
                final meal = _filteredMeals[index];
                
                // Show animated card for analyzing meals
                if (meal.isAnalyzing) {
                  print('🎬 Displaying analyzing meal card for: ${meal.id}');
                  return _buildAnalyzingMealCard(meal);
                }
                
                final macros = meal.macros;
                
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
                      builder: (context) => AlertDialog(
                        title: Text('dashboard.delete_analysis'.tr()),
                        content: Text('dashboard.delete_confirm'.tr()),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(
                              'dashboard.cancel'.tr(),
                              style: TextStyle(
                                color: Colors.black,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                              'dashboard.delete'.tr(),
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) {
                    widget.onDelete(meal.id);
                  },
                  child: GestureDetector(
                    onTap: () async {
                      await _showAnalysisDetails(meal);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 0,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      height: 122,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: meal.imageUrl != null && meal.imageUrl!.isNotEmpty
                                ? LayoutBuilder(
                                    builder: (context, constraints) {
                                      final size = constraints.maxHeight;
                                      return SizedBox(
                                        width: size,
                                        height: size,
                                        child: _buildMealImage(meal.imageUrl!),
                                      );
                                    },
                                  )
                                : LayoutBuilder(
                                    builder: (context, constraints) {
                                      final size = constraints.maxHeight;
                                      return Container(
                                        width: size,
                                        height: size,
                                        color: Theme.of(context).colorScheme.surface,
                                        child: Icon(
                                          Icons.photo,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                          size: 32,
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _getTranslatedMealName(meal),
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.inverseSurface,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            DateFormat('HH:mm').format(meal.timestamp),
                                            style: TextStyle(
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
                                      Icon(
                                        Icons.local_fire_department,
                                        size: 20,
                                        color: Colors.black,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${meal.calories.toStringAsFixed(0)} ${'common.calories'.tr()}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.normal,
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      ColorFiltered(
                                        colorFilter: ColorFilter.mode(
                                          Colors.blue[400]!,
                                          BlendMode.srcIn,
                                        ),
                                        child: Image.asset(
                                          'images/meat.png',
                                          width: 18,
                                          height: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${macros['proteins']?.toStringAsFixed(0) ?? 0}g',
                                        style: TextStyle(
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
                                      const SizedBox(width: 4),
                                      Text(
                                        '${macros['carbs']?.toStringAsFixed(0) ?? 0}g',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Image.asset(
                                        'images/fats.png',
                                        width: 18,
                                        height: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${macros['fats']?.toStringAsFixed(0) ?? 0}g',
                                        style: TextStyle(
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
    );
  }
} 