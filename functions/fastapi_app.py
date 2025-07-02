# from fastapi import FastAPI, Request, HTTPException
# from fastapi.responses import JSONResponse
# from fastapi.middleware.cors import CORSMiddleware

# import os
# from dotenv import load_dotenv

# # Always load .env from the project root
# project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# dotenv_path = os.path.join(project_root, '.env')
# load_dotenv(dotenv_path)

# # Debug: Print the loaded API keys (masking for security)
# def mask_key(key):
#     if not key or len(key) < 8:
#         return key
#     return key[:4] + '...' + key[-4:]

# print("OPENAI_API_KEY:", mask_key(os.getenv("OPENAI_API_KEY")))
# print("OPENROUTER_API_KEY:", mask_key(os.getenv("OPENROUTER_API_KEY")))

# from functions.service import (
#     analyze_meal_image_v1_service,
#     analyze_meal_image_v2_service,
#     analyze_refrigerator_service,
#     analyze_invoice_service,
#     get_recipe_service
# )
# from .utils import process_ingredient_nutrition_data

# app = FastAPI()

# # Allow CORS for local development
# app.add_middleware(
#     CORSMiddleware,
#     allow_origins=["*"],
#     allow_credentials=True,
#     allow_methods=["*"],
#     allow_headers=["*"],
# )

# @app.post("/analyze_meal_image_v1")
# async def analyze_meal_image_v1(request: Request):
#     data = await request.json()
#     image_url = data.get('image_url')
#     image_base64 = data.get('image_base64')
#     image_name = data.get('image_name', 'unknown.jpg')
#     function_info = data.get('function_info', {})
#     service_result = analyze_meal_image_v1_service(
#         image_url=image_url,
#         image_base64=image_base64,
#         image_name=image_name,
#         function_info=function_info
#     )
#     if 'error' in service_result:
#         raise HTTPException(status_code=400, detail=service_result['error'])
#     return JSONResponse(content=service_result['result'])

# @app.post("/analyze_meal_image_v2")
# async def analyze_meal_image_v2(request: Request):
#     data = await request.json()
#     image_url = data.get('image_url')
#     image_base64 = data.get('image_base64')
#     image_name = data.get('image_name', 'unknown')
#     service_result = analyze_meal_image_v2_service(
#         image_url=image_url,
#         image_base64=image_base64,
#         image_name=image_name
#     )
#     if 'error' in service_result:
#         raise HTTPException(status_code=400, detail=service_result['error'])
#     return JSONResponse(content=service_result['result'])

# @app.post("/analyze_refrigerator")
# async def analyze_refrigerator(request: Request):
#     data = await request.json()
#     images = data.get('images', [])
#     service_result = analyze_refrigerator_service(images)
#     if 'error' in service_result:
#         raise HTTPException(status_code=400, detail=service_result['error'])
#     return JSONResponse(content=service_result['result'])

# @app.post("/analyze_invoice")
# async def analyze_invoice(request: Request):
#     data = await request.json()
#     images = data.get('images', [])
#     service_result = analyze_invoice_service(images)
#     if 'error' in service_result:
#         raise HTTPException(status_code=400, detail=service_result['error'])
#     return JSONResponse(content=service_result['result'])

# @app.get("/get_recipe")
# async def get_recipe(request: Request):
#     params = dict(request.query_params)
#     service_result = get_recipe_service(params)
#     if 'error' in service_result:
#         raise HTTPException(status_code=500, detail=service_result['error'])
#     return JSONResponse(content=service_result['result'])

# # For local run: uvicorn functions.fastapi_app:app --reload



# if __name__ == "__main__":
#     # if os.getenv("ENV", "dev") == "dev":
#     # os.system("uvicorn main:app --host 0.0.0.0 --port 8091 --reload")
#     # else:
#         uvicorn.run(
#             "fastapi_app:app",
#             host=os.getenv('SERVER_HOST', '0.0.0.0'),
#             port=int(os.getenv('SERVER_PORT', 8091)),
#             loop="uvloop",
#             limit_concurrency=1000,
#             backlog=2048,
#             workers=1,
#             reload=True,  # Enables hot reload (use only in development)
#             log_level="debug"
#         )