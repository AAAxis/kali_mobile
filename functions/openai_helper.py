import os
import json
import requests
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Get API key from environment
api_key = os.environ.get("OPENAI_API_KEY", "")

def analyze_image_with_vision(image_url, prompt):
    """
    Analyze an image using OpenAI's Vision capabilities
    
    Args:
        image_url (str): URL of the image to analyze
        prompt (str): Instructions for the analysis
        
    Returns:
        str or dict: The analysis result from OpenAI
    """
    try:
        if not api_key:
            return {"error": "OpenAI API key not configured"}
        
        # Manually construct the API request instead of using the client library
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}"
        }
        
        payload = {
            "model": "gpt-4o-mini",
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": prompt},
                        {
                            "type": "image_url",
                            "image_url": {"url": image_url}
                        }
                    ]
                }
            ],
            "max_tokens": 1000
        }
        
        response = requests.post(
            "https://api.openai.com/v1/chat/completions",
            headers=headers,
            json=payload
        )
        
        if response.status_code == 200:
            result = response.json()
            if "choices" in result and len(result["choices"]) > 0:
                return result["choices"][0]["message"]["content"]
            return {"error": "No content in response"}
        else:
            return {"error": f"API call failed with status {response.status_code}: {response.text}"}
        
    except Exception as e:
        print(f"Error in OpenAI Vision API call: {str(e)}")
        return {"error": str(e)} 