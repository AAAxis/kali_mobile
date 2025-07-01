# Environment Setup for Firebase Functions

This document outlines the required environment variables for the Firebase Functions to work properly.

## Required Environment Variables

Create a `.env` file in the `functions/` directory with the following variables:

### OpenAI API Configuration
```
OPENAI_API_KEY=your_openai_api_key_here
OPENROUTER_API_KEY=your_openrouter_api_key_here
```

### MongoDB Configuration
```
MONGO_INITDB_ROOT_USERNAME=your_mongodb_username
MONGO_INITDB_ROOT_PASSWORD=your_mongodb_password
MONGO_HOST=localhost
MONGO_PORT=27017
MONGO_DB_NAME=admin
MONGODB_DB=kali_mobile
```

### Optional MongoDB Configuration
```
MONGODB_AUTH_MECHANISM=SCRAM-SHA-1
MONGODB_CONNECT_TIMEOUT_MS=5000
MONGODB_SERVER_SELECTION_TIMEOUT_MS=5000
MONGODB_SOCKET_TIMEOUT_MS=20000
MONGODB_MAX_POOL_SIZE=10
MONGODB_MIN_POOL_SIZE=1
```

### MongoDB Collection Names (optional - defaults will be used if not set)
```
MONGODB_INGREDIENTS_COLLECTION=ingredients
MONGODB_VALIDATION_ERRORS_COLLECTION=validation_errors
MONGODB_MEAL_ANALYSIS_COLLECTION=meal_analysis
MONGODB_INGREDIENT_NAMES_COLLECTION=ingredient_names_v5
MONGODB_NORMALIZED_INGREDIENTS_COLLECTION=normalized_ingredients_v5
MONGODB_INGREDIENTS_NUTRITION_COLLECTION=ingredients_nutrition_v5
MONGODB_INGREDIENT_CATEGORIES_COLLECTION=ingredient_categories_v5
```

## Getting API Keys

1. **OpenAI API Key**: Get from https://platform.openai.com/api-keys
2. **OpenRouter API Key**: Get from https://openrouter.ai/keys
3. **MongoDB**: Set up a MongoDB instance and create user credentials

## Installation Steps

1. Install dependencies:
   ```bash
   cd functions
   pip install -r requirements.txt
   ```

2. Create `.env` file with your actual values

3. Test the setup:
   ```bash
   python test_mongodb.py
   ```

## Notes

- The functions will work without MongoDB if you don't need data persistence
- OpenAI API is required for image analysis functionality
- OpenRouter API is used as an alternative to OpenAI for some operations 