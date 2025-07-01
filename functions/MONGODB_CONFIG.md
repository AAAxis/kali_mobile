# MongoDB Configuration Guide

This document explains how to configure MongoDB for the Kali Mobile Firebase Functions.

## Environment Variables

Create a `.env` file in the `functions/` directory with the following variables:

### Required Variables

```bash
# OpenAI API Configuration
OPENAI_API_KEY=your_openai_api_key_here
OPENROUTER_API_KEY=your_openrouter_api_key_here

# MongoDB Configuration
MONGODB_DB=kali_mobile
```

### Optional Variables

```bash
# MongoDB Authentication (if using authenticated MongoDB)
MONGO_INITDB_ROOT_USERNAME=your_username
MONGO_INITDB_ROOT_PASSWORD=your_password
MONGO_HOST=localhost
MONGO_PORT=27017
MONGO_DB_NAME=admin
MONGODB_AUTH_MECHANISM=SCRAM-SHA-1

# MongoDB Collections (will use defaults if not set)
MONGODB_INGREDIENTS_COLLECTION=ingredients
MONGODB_VALIDATION_ERRORS_COLLECTION=validation_errors
MONGODB_MEAL_ANALYSIS_COLLECTION=meal_analysis
MONGODB_INGREDIENT_NAMES_COLLECTION=ingredient_names_v5
MONGODB_NORMALIZED_INGREDIENTS_COLLECTION=normalized_ingredients_v5
MONGODB_INGREDIENTS_NUTRITION_COLLECTION=ingredients_nutrition_v5
MONGODB_INGREDIENT_CATEGORIES_COLLECTION=ingredient_categories_v5

# MongoDB Connection Settings (will use defaults if not set)
MONGODB_CONNECT_TIMEOUT_MS=5000
MONGODB_SERVER_SELECTION_TIMEOUT_MS=5000
MONGODB_SOCKET_TIMEOUT_MS=20000
MONGODB_MAX_POOL_SIZE=10
MONGODB_MIN_POOL_SIZE=1
```

## Configuration Examples

### Local MongoDB (No Authentication)

```bash
MONGODB_DB=kali_mobile
MONGO_HOST=localhost
MONGO_PORT=27017
```

### Local MongoDB with Authentication

```bash
MONGODB_DB=kali_mobile
MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD=password123
MONGO_HOST=localhost
MONGO_PORT=27017
MONGO_DB_NAME=admin
```

### MongoDB Atlas (Cloud Hosted)

```bash
MONGODB_DB=kali_mobile
MONGO_INITDB_ROOT_USERNAME=your_username
MONGO_INITDB_ROOT_PASSWORD=your_password
MONGO_HOST=cluster.mongodb.net
MONGO_PORT=27017
MONGO_DB_NAME=admin
```

### MongoDB Atlas with Connection String (Alternative)

If you prefer to use a direct connection string, you can still set:
```bash
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/kali_mobile?retryWrites=true&w=majority
MONGODB_DB=kali_mobile
```

## Collections

The application uses the following MongoDB collections:

- `ingredients` - Stores ingredient data from meal analysis
- `validation_errors` - Stores validation errors for manual review
- `meal_analysis` - Stores complete meal analysis results
- `ingredient_names_v5` - Stores ingredient names and metadata
- `normalized_ingredients_v5` - Stores normalized ingredient data
- `ingredients_nutrition_v5` - Stores nutrition information
- `ingredient_categories_v5` - Stores ingredient categories

## Testing Configuration

Run the test script to verify your MongoDB configuration:

```bash
cd functions
python test_mongodb.py
```

This will test:
- Environment variable loading
- MongoDB connection
- Validation functions
- Save functions (if MongoDB is available)

## Troubleshooting

### Connection Issues

1. **Connection refused**: Make sure MongoDB is running
2. **Authentication failed**: Check username/password
3. **Timeout**: Increase timeout values in environment variables

### Environment Variables Not Loading

1. Make sure `.env` file is in the `functions/` directory
2. Check that `python-dotenv` is installed
3. Verify file permissions

### Collection Access Issues

1. Check if collections exist in your MongoDB database
2. Verify user permissions for the database
3. Check collection names in environment variables 