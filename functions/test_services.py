import requests
from .utils import process_ingredient_nutrition_data
from .service import analyze_meal_image_v1_service
from firebase_functions import https_fn

BASE_URL = "http://127.0.0.1:8000"

def test_analyze_meal_image_v1():
    url = f"{BASE_URL}/analyze_meal_image_v1"
    payload = {
        "image_url": "https://example.com/image.jpg",
        "image_base64": "",
        "image_name": "test.jpg",
        "function_info": {}
    }
    r = requests.post(url, json=payload)
    print("analyze_meal_image_v1:", r.status_code, r.json())

def test_analyze_meal_image_v2():
    url = f"{BASE_URL}/analyze_meal_image_v2"
    payload = {
        "image_url": "https://example.com/image.jpg",
        "image_base64": "",
        "image_name": "test.jpg"
    }
    r = requests.post(url, json=payload)
    print("analyze_meal_image_v2:", r.status_code, r.json())

def test_analyze_refrigerator():
    url = f"{BASE_URL}/analyze_refrigerator"
    payload = {
        "images": ["https://example.com/fridge1.jpg", "https://example.com/fridge2.jpg"]
    }
    r = requests.post(url, json=payload)
    print("analyze_refrigerator:", r.status_code, r.json())

def test_analyze_invoice():
    url = f"{BASE_URL}/analyze_invoice"
    payload = {
        "images": ["https://example.com/invoice1.jpg"]
    }
    r = requests.post(url, json=payload)
    print("analyze_invoice:", r.status_code, r.json())

def test_get_recipe():
    url = f"{BASE_URL}/get_recipe"
    params = {
        "ingredient": "chicken",
        "diet": "keto"
    }
    r = requests.get(url, params=params)
    print("get_recipe:", r.status_code, r.json())

@https_fn.on_request()
def my_function(request):
    ...

if __name__ == "__main__":
    test_analyze_meal_image_v1()
    test_analyze_meal_image_v2()
    test_analyze_refrigerator()
    test_analyze_invoice()
    test_get_recipe()