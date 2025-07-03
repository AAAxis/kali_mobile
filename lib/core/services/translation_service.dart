import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  static const String _baseUrl = 'https://translate.googleapis.com/translate_a/single';
  
  // Static dictionary for common ingredients and meal names
  static const Map<String, Map<String, String>> _ingredientDictionary = {
    // Common Meals & Dishes
    'cheeseburger': {'en': 'cheeseburger', 'he': 'צ\'יזבורגר', 'ru': 'чизбургер'},
    'hamburger': {'en': 'hamburger', 'he': 'המבורגר', 'ru': 'гамбургер'},
    'burger': {'en': 'burger', 'he': 'בורגר', 'ru': 'бургер'},
    'pizza': {'en': 'pizza', 'he': 'פיצה', 'ru': 'пицца'},
    'sandwich': {'en': 'sandwich', 'he': 'כריך', 'ru': 'сэндвич'},
    'pasta': {'en': 'pasta', 'he': 'פסטה', 'ru': 'паста'},
    'salad': {'en': 'salad', 'he': 'סלט', 'ru': 'салат'},
    'soup': {'en': 'soup', 'he': 'מרק', 'ru': 'суп'},
    'sushi': {'en': 'sushi', 'he': 'סושי', 'ru': 'суши'},
    'tacos': {'en': 'tacos', 'he': 'טאקו', 'ru': 'тако'},
    'burrito': {'en': 'burrito', 'he': 'בוריטו', 'ru': 'буррито'},
    'steak': {'en': 'steak', 'he': 'סטייק', 'ru': 'стейк'},
    'chicken wings': {'en': 'chicken wings', 'he': 'כנפי עוף', 'ru': 'куриные крылышки'},
    'french fries': {'en': 'french fries', 'he': 'צ\'יפס', 'ru': 'картофель фри'},
    'fries': {'en': 'fries', 'he': 'צ\'יפס', 'ru': 'картофель фри'},
    'hot dog': {'en': 'hot dog', 'he': 'נקניקייה', 'ru': 'хот-дог'},
    'pancakes': {'en': 'pancakes', 'he': 'פנקייק', 'ru': 'блины'},
    'waffles': {'en': 'waffles', 'he': 'וופל', 'ru': 'вафли'},
    'omelet': {'en': 'omelet', 'he': 'חביתה', 'ru': 'омлет'},
    'omelette': {'en': 'omelette', 'he': 'חביתה', 'ru': 'омлет'},
    'scrambled eggs': {'en': 'scrambled eggs', 'he': 'ביצים מקושקשות', 'ru': 'яичница-болтунья'},
    'fried rice': {'en': 'fried rice', 'he': 'אורז מטוגן', 'ru': 'жареный рис'},
    'noodles': {'en': 'noodles', 'he': 'אטריות', 'ru': 'лапша'},
    'ramen': {'en': 'ramen', 'he': 'ראמן', 'ru': 'рамен'},
    'shawarma': {'en': 'shawarma', 'he': 'שווארמה', 'ru': 'шаурма'},
    'falafel': {'en': 'falafel', 'he': 'פלאפל', 'ru': 'фалафель'},
    'hummus': {'en': 'hummus', 'he': 'חומוס', 'ru': 'хумус'},
    
    // Proteins
    'chicken': {'en': 'chicken', 'he': 'עוף', 'ru': 'курица'},
    'beef': {'en': 'beef', 'he': 'בקר', 'ru': 'говядина'},
    'pork': {'en': 'pork', 'he': 'חזיר', 'ru': 'свинина'},
    'fish': {'en': 'fish', 'he': 'דג', 'ru': 'рыба'},
    'salmon': {'en': 'salmon', 'he': 'סלמון', 'ru': 'лосось'},
    'tuna': {'en': 'tuna', 'he': 'טונה', 'ru': 'тунец'},
    'eggs': {'en': 'eggs', 'he': 'ביצים', 'ru': 'яйца'},
    'egg': {'en': 'egg', 'he': 'ביצה', 'ru': 'яйцо'},
    
    // Vegetables
    'tomato': {'en': 'tomato', 'he': 'עגבנייה', 'ru': 'помидор'},
    'tomatoes': {'en': 'tomatoes', 'he': 'עגבניות', 'ru': 'помидоры'},
    'onion': {'en': 'onion', 'he': 'בצל', 'ru': 'лук'},
    'onions': {'en': 'onions', 'he': 'בצלים', 'ru': 'лук'},
    'garlic': {'en': 'garlic', 'he': 'שום', 'ru': 'чеснок'},
    'potato': {'en': 'potato', 'he': 'תפוח אדמה', 'ru': 'картофель'},
    'potatoes': {'en': 'potatoes', 'he': 'תפוחי אדמה', 'ru': 'картофель'},
    'carrot': {'en': 'carrot', 'he': 'גזר', 'ru': 'морковь'},
    'carrots': {'en': 'carrots', 'he': 'גזר', 'ru': 'морковь'},
    'cucumber': {'en': 'cucumber', 'he': 'מלפפון', 'ru': 'огурец'},
    'lettuce': {'en': 'lettuce', 'he': 'חסה', 'ru': 'салат'},
    'spinach': {'en': 'spinach', 'he': 'תרד', 'ru': 'шпинат'},
    'broccoli': {'en': 'broccoli', 'he': 'ברוקולי', 'ru': 'брокколи'},
    'bell pepper': {'en': 'bell pepper', 'he': 'פלפל מתוק', 'ru': 'болгарский перец'},
    'mushrooms': {'en': 'mushrooms', 'he': 'פטריות', 'ru': 'грибы'},
    'mushroom': {'en': 'mushroom', 'he': 'פטרייה', 'ru': 'гриб'},
    
    // Fruits
    'apple': {'en': 'apple', 'he': 'תפוח', 'ru': 'яблоко'},
    'banana': {'en': 'banana', 'he': 'בננה', 'ru': 'банан'},
    'orange': {'en': 'orange', 'he': 'תפוז', 'ru': 'апельсин'},
    'lemon': {'en': 'lemon', 'he': 'לימון', 'ru': 'лимон'},
    'avocado': {'en': 'avocado', 'he': 'אבוקדו', 'ru': 'авокадо'},
    'strawberry': {'en': 'strawberry', 'he': 'תות', 'ru': 'клубника'},
    'strawberries': {'en': 'strawberries', 'he': 'תותים', 'ru': 'клубника'},
    
    // Grains & Carbs
    'rice': {'en': 'rice', 'he': 'אורז', 'ru': 'рис'},
    'bread': {'en': 'bread', 'he': 'לחם', 'ru': 'хлеб'},
    'flour': {'en': 'flour', 'he': 'קמח', 'ru': 'мука'},
    'oats': {'en': 'oats', 'he': 'שיבולת שועל', 'ru': 'овес'},
    'quinoa': {'en': 'quinoa', 'he': 'קינואה', 'ru': 'киноа'},
    
    // Dairy
    'milk': {'en': 'milk', 'he': 'חלב', 'ru': 'молоко'},
    'cheese': {'en': 'cheese', 'he': 'גבינה', 'ru': 'сыр'},
    'yogurt': {'en': 'yogurt', 'he': 'יוגורט', 'ru': 'йогурт'},
    'butter': {'en': 'butter', 'he': 'חמאה', 'ru': 'масло'},
    
    // Oils & Fats
    'olive oil': {'en': 'olive oil', 'he': 'שמן זית', 'ru': 'оливковое масло'},
    'oil': {'en': 'oil', 'he': 'שמן', 'ru': 'масло'},
    
    // Spices & Seasonings
    'salt': {'en': 'salt', 'he': 'מלח', 'ru': 'соль'},
    'pepper': {'en': 'pepper', 'he': 'פלפל', 'ru': 'перец'},
    'paprika': {'en': 'paprika', 'he': 'פפריקה', 'ru': 'паприка'},
    'cumin': {'en': 'cumin', 'he': 'כמון', 'ru': 'кумин'},
    'oregano': {'en': 'oregano', 'he': 'אורגנו', 'ru': 'орегано'},
    'basil': {'en': 'basil', 'he': 'בזיליקום', 'ru': 'базилик'},
    'parsley': {'en': 'parsley', 'he': 'פטרוזיליה', 'ru': 'петрушка'},
    
    // Nuts & Seeds
    'almonds': {'en': 'almonds', 'he': 'שקדים', 'ru': 'миндаль'},
    'walnuts': {'en': 'walnuts', 'he': 'אגוזי מלך', 'ru': 'грецкие орехи'},
    'sunflower seeds': {'en': 'sunflower seeds', 'he': 'גרעיני חמנייה', 'ru': 'семечки подсолнуха'},
    
    // Legumes & Beans
    'chickpeas': {'en': 'chickpeas', 'he': 'חומציות', 'ru': 'нут'},
    'black beans': {'en': 'black beans', 'he': 'שעועית שחורה', 'ru': 'черная фасоль'},
    'kidney beans': {'en': 'kidney beans', 'he': 'שעועית כליה', 'ru': 'красная фасоль'},
    'lentils': {'en': 'lentils', 'he': 'עדשים', 'ru': 'чечевица'},
    'beans': {'en': 'beans', 'he': 'שעועית', 'ru': 'фасоль'},
    
    // Processing/Analysis Text
    'processing...': {'en': 'Processing...', 'he': 'מעבד...', 'ru': 'Обработка...'},
    'ai is analyzing your meal': {'en': 'AI is analyzing your meal', 'he': 'AI מנתח את הארוחה שלך', 'ru': 'ИИ анализирует вашу еду'},
  };

  // ========== BASIC GOOGLE TRANSLATE METHODS ==========
  
  /// Translate text using Google Translate (free endpoint)
  static Future<String> translateText(String text, String targetLanguage) async {
    try {
      final url = Uri.parse('$_baseUrl?client=gtx&sl=auto&tl=$targetLanguage&q=${Uri.encodeComponent(text)}');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded != null && decoded[0] != null && decoded[0][0] != null) {
          return decoded[0][0][0].toString();
        }
      }
      
      return text; // Return original if translation fails
    } catch (e) {
      print('Translation error: $e');
      return text;
    }
  }

  /// Get language code from locale for Google Translate
  static String getLanguageCode(String locale) {
    switch (locale.toLowerCase()) {
      case 'en':
        return 'en';
      case 'he':
        return 'iw'; // Google Translate uses 'iw' for Hebrew
      case 'ru':
        return 'ru';
      default:
        return 'en';
    }
  }

  /// Batch translate multiple ingredients (more efficient)
  static Future<Map<String, String>> batchTranslateIngredients(
    List<String> ingredients, 
    String targetLanguage
  ) async {
    Map<String, String> translations = {};
    
    // Join ingredients with a delimiter for batch translation
    final combinedText = ingredients.join(' | ');
    final translatedText = await translateText(combinedText, targetLanguage);
    
    // Split back the results
    final translatedParts = translatedText.split(' | ');
    
    for (int i = 0; i < ingredients.length && i < translatedParts.length; i++) {
      translations[ingredients[i]] = translatedParts[i];
    }
    
    return translations;
  }

  // ========== STATIC DICTIONARY METHODS ==========

  /// Translate ingredient using static dictionary
  static String translateIngredientStatic(String ingredient, String targetLanguage) {
    final normalizedIngredient = ingredient.toLowerCase().trim();
    
    // Try exact match first
    if (_ingredientDictionary.containsKey(normalizedIngredient)) {
      return _ingredientDictionary[normalizedIngredient]![targetLanguage] ?? ingredient;
    }
    
    // Try partial match
    for (final entry in _ingredientDictionary.entries) {
      if (normalizedIngredient.contains(entry.key) || entry.key.contains(normalizedIngredient)) {
        return entry.value[targetLanguage] ?? ingredient;
      }
    }
    
    // Return original if no translation found
    return ingredient;
  }

  /// Check if ingredient has static translation
  static bool hasStaticTranslation(String ingredient, String targetLanguage) {
    final normalizedIngredient = ingredient.toLowerCase().trim();
    return _ingredientDictionary.containsKey(normalizedIngredient) &&
           _ingredientDictionary[normalizedIngredient]!.containsKey(targetLanguage);
  }

  // ========== HYBRID TRANSLATION METHODS ==========

  /// Translate ingredient using static dictionary first, then Google Translate as fallback
  static Future<String> translateIngredient(String ingredient, String targetLanguage) async {
    // Try static dictionary first (free and instant)
    final staticTranslation = translateIngredientStatic(ingredient, targetLanguage);
    
    // If we got a translation from static dictionary, use it
    if (staticTranslation != ingredient) {
      return staticTranslation;
    }
    
    // If no static translation found, use Google Translate (for rare ingredients)
    final googleLanguageCode = getLanguageCode(targetLanguage);
    return await translateText(ingredient, googleLanguageCode);
  }

  /// Translate a list of ingredients efficiently using hybrid approach
  static Future<List<String>> translateIngredients(List<String> ingredients, String targetLanguage) async {
    List<String> translatedIngredients = [];
    List<String> needsGoogleTranslation = [];
    List<int> googleTranslationIndices = [];
    
    // First pass: use static dictionary
    for (int i = 0; i < ingredients.length; i++) {
      final ingredient = ingredients[i];
      final staticTranslation = translateIngredientStatic(ingredient, targetLanguage);
      
      if (staticTranslation != ingredient) {
        // Found in static dictionary
        translatedIngredients.add(staticTranslation);
      } else {
        // Need Google Translate
        translatedIngredients.add(ingredient); // placeholder
        needsGoogleTranslation.add(ingredient);
        googleTranslationIndices.add(i);
      }
    }
    
    // Second pass: batch translate remaining ingredients with Google
    if (needsGoogleTranslation.isNotEmpty) {
      try {
        final googleLanguageCode = getLanguageCode(targetLanguage);
        final googleTranslations = await batchTranslateIngredients(
          needsGoogleTranslation, 
          googleLanguageCode
        );
        
        // Replace placeholders with Google translations
        for (int i = 0; i < needsGoogleTranslation.length; i++) {
          final originalIngredient = needsGoogleTranslation[i];
          final translatedIngredient = googleTranslations[originalIngredient] ?? originalIngredient;
          final indexInResult = googleTranslationIndices[i];
          translatedIngredients[indexInResult] = translatedIngredient;
        }
      } catch (e) {
        print('Google Translate failed: $e');
        // Keep original ingredients if Google Translate fails
      }
    }
    
    return translatedIngredients;
  }

  /// Check translation coverage (how many ingredients can be translated statically)
  static double getStaticTranslationCoverage(List<String> ingredients, String targetLanguage) {
    if (ingredients.isEmpty) return 1.0;
    
    int staticTranslations = 0;
    for (final ingredient in ingredients) {
      if (hasStaticTranslation(ingredient, targetLanguage)) {
        staticTranslations++;
      }
    }
    
    return staticTranslations / ingredients.length;
  }

  // ========== MEAL TRANSLATION METHODS ==========

  /// Translate meal analysis result to target language
  static Future<Map<String, dynamic>> translateMealAnalysis(
    Map<String, dynamic> englishAnalysis,
    String targetLanguage,
  ) async {
    if (targetLanguage == 'en') {
      return englishAnalysis; // No translation needed
    }

    try {
      print('🌍 Translating meal analysis to: $targetLanguage');
      
      // Create a copy of the analysis
      final translatedAnalysis = Map<String, dynamic>.from(englishAnalysis);
      
      // Translate meal name
      await _translateMealName(translatedAnalysis, targetLanguage);
      
      // Translate ingredients
      await _translateIngredients(translatedAnalysis, targetLanguage);
      
      // Translate health assessment (optional - could be expensive)
      // await _translateHealthAssessment(translatedAnalysis, targetLanguage);
      
      print('✅ Meal analysis translated successfully');
      return translatedAnalysis;
      
    } catch (e) {
      print('❌ Error translating meal analysis: $e');
      return englishAnalysis; // Return original if translation fails
    }
  }

  /// Translate meal name
  static Future<void> _translateMealName(
    Map<String, dynamic> analysis,
    String targetLanguage,
  ) async {
    if (analysis['mealName'] is Map) {
      final mealNameMap = Map<String, dynamic>.from(analysis['mealName']);
      final englishName = mealNameMap['en'] ?? 'Unknown Meal';
      
      print('🔍 Translating meal name: "$englishName" to $targetLanguage');
      
      // Try to translate the meal name
      final translatedName = await translateIngredient(
        englishName,
        targetLanguage,
      );
      
      print('✅ Translation result: "$englishName" -> "$translatedName"');
      
      mealNameMap[targetLanguage] = translatedName;
      analysis['mealName'] = mealNameMap;
    }
  }

  /// Translate ingredients list
  static Future<void> _translateIngredients(
    Map<String, dynamic> analysis,
    String targetLanguage,
  ) async {
    if (analysis['ingredients'] is Map) {
      final ingredientsMap = Map<String, dynamic>.from(analysis['ingredients']);
      final englishIngredients = List<String>.from(ingredientsMap['en'] ?? []);
      
      if (englishIngredients.isNotEmpty) {
        // Use hybrid translation for ingredients
        final translatedIngredients = await translateIngredients(
          englishIngredients,
          targetLanguage,
        );
        
        ingredientsMap[targetLanguage] = translatedIngredients;
        analysis['ingredients'] = ingredientsMap;
      }
    }
  }

  /// Translate health assessment (optional - can be expensive)
  static Future<void> _translateHealthAssessment(
    Map<String, dynamic> analysis,
    String targetLanguage,
  ) async {
    if (analysis['healthiness_explanation'] is Map) {
      final explanationMap = Map<String, dynamic>.from(analysis['healthiness_explanation']);
      final englishExplanation = explanationMap['en'] ?? '';
      
      if (englishExplanation.isNotEmpty) {
        // Use Google Translate for longer text (this will cost more)
        final translatedExplanation = await translateIngredient(
          englishExplanation,
          targetLanguage,
        );
        
        explanationMap[targetLanguage] = translatedExplanation;
        analysis['healthiness_explanation'] = explanationMap;
      }
    }
  }

  /// Batch translate multiple meal analyses
  static Future<List<Map<String, dynamic>>> translateMealAnalyses(
    List<Map<String, dynamic>> englishAnalyses,
    String targetLanguage,
  ) async {
    if (targetLanguage == 'en') {
      return englishAnalyses; // No translation needed
    }

    final translatedAnalyses = <Map<String, dynamic>>[];
    
    for (final analysis in englishAnalyses) {
      final translated = await translateMealAnalysis(analysis, targetLanguage);
      translatedAnalyses.add(translated);
    }
    
    return translatedAnalyses;
  }

  // ========== UTILITY METHODS ==========

  /// Get all available languages
  static List<String> getAvailableLanguages() {
    return ['en', 'he', 'ru'];
  }

  /// Check if a language is supported
  static bool isLanguageSupported(String languageCode) {
    return getAvailableLanguages().contains(languageCode);
  }

  /// Preload common ingredient translations (call this on app start)
  static Future<void> preloadCommonTranslations() async {
    // This could be used to preload translations for the most common ingredients
    // For now, our static dictionary handles this
    print('✅ Common ingredient translations loaded');
  }
} 