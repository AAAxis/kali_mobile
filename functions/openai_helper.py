import os
import json
import requests
import re
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Get API key from environment variables
api_key = os.environ.get("OPENAI_API_KEY", "")
open_router_api_key = os.environ.get("OPENROUTER_API_KEY", "")

if api_key and len(api_key) > 10:
    print("🔑 OpenAI API key loaded successfully")
else:
    print("❌ OpenAI API key not configured or invalid")
    print("📝 Please set OPENAI_API_KEY in your .env file")
    print("📝 Get your key from: https://platform.openai.com/api-keys")

if open_router_api_key and len(open_router_api_key) > 10:
    print("🔑 OpenRouter API key loaded successfully")
else:
    print("❌ OpenRouter API key not configured or invalid")
    print("📝 Please set OPENROUTER_API_KEY in your .env file")
    print("📝 Get your key from: https://openrouter.ai/keys")

def analyze_image_with_openai(image_url=None, prompt=None, image_base64=None):
    """
    Analyze an image using OpenAI's Vision capabilities
    
    Args:
        image_url (str, optional): URL of the image to analyze
        prompt (str): Instructions for the analysis
        image_base64 (str, optional): Base64 encoded image data
        
    Returns:
        str or dict: The analysis result from OpenAI
    """
    try:
        print(f"🔍 Starting OpenAI Vision API call...")
        print(f"🔍 API key configured: {'Yes' if api_key and len(api_key) > 10 else 'No/Invalid'}")
        print(f"🔍 API key length: {len(api_key) if api_key else 0}")
        
        if image_url:
            print(f"🔍 Image URL: {image_url[:100]}..." if len(image_url) > 100 else f"🔍 Image URL: {image_url}")
        if image_base64:
            print(f"🔍 Image base64: {len(image_base64)} characters")
        
        if not api_key:
            error_msg = "OpenAI API key not configured in environment variables"
            print(f"❌ {error_msg}")
            return {"error": error_msg}
        
        if len(api_key) < 20:  # OpenAI keys are typically much longer
            error_msg = f"OpenAI API key appears to be invalid (too short: {len(api_key)} characters)"
            print(f"❌ {error_msg}")
            return {"error": error_msg}
        
        # Validate image input
        if not image_url and not image_base64:
            error_msg = "Either image_url or image_base64 must be provided"
            print(f"❌ {error_msg}")
            return {"error": error_msg}
        
        if image_url and not image_url.startswith(('http://', 'https://')):
            error_msg = f"Invalid image URL format: {image_url}"
            print(f"❌ {error_msg}")
            return {"error": error_msg}
        
        # Manually construct the API request instead of using the client library
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}"
        }
        
        # Prepare image content based on input type
        if image_base64:
            image_content = {
                "type": "image_url",
                "image_url": {"url": f"data:image/jpeg;base64,{image_base64}"}
            }
            print(f"🔍 Using base64 image data")
        else:
            image_content = {
                "type": "image_url",
                "image_url": {"url": image_url}
            }
            print(f"🔍 Using image URL")

        payload = {
            "model": "gpt-4o-mini",
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": prompt},
                        image_content
                    ]
                }
            ],
            "max_tokens": 1000
        }
        
        print(f"🚀 Making OpenAI API request...")
        print(f"🚀 Model: {payload['model']}")
        print(f"🚀 Max tokens: {payload['max_tokens']}")
        
        response = requests.post(
            "https://api.openai.com/v1/chat/completions",
            headers=headers,
            json=payload,
            timeout=30  # Add timeout
        )
        
        print(f"📥 OpenAI API response status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ OpenAI API call successful")
            if "choices" in result and len(result["choices"]) > 0:
                content = result["choices"][0]["message"]["content"]
                print(f"✅ Got content from OpenAI (length: {len(content)})")
                return content
            else:
                error_msg = "No content in OpenAI response"
                print(f"❌ {error_msg}")
                print(f"❌ Full response: {result}")
                return {"error": error_msg}
        else:
            error_msg = f"OpenAI API call failed with status {response.status_code}"
            print(f"❌ {error_msg}")
            print(f"❌ Response text: {response.text}")
            
            # Parse common OpenAI errors
            try:
                error_data = response.json()
                if "error" in error_data:
                    openai_error = error_data["error"]
                    if isinstance(openai_error, dict):
                        error_type = openai_error.get("type", "unknown")
                        error_message = openai_error.get("message", "Unknown error")
                        error_code = openai_error.get("code", "unknown")
                        
                        print(f"❌ OpenAI Error Type: {error_type}")
                        print(f"❌ OpenAI Error Message: {error_message}")
                        print(f"❌ OpenAI Error Code: {error_code}")
                        
                        return {"error": f"OpenAI API Error ({error_type}): {error_message}"}
            except:
                pass
            
            return {"error": f"API call failed with status {response.status_code}: {response.text[:200]}"}
        
    except requests.exceptions.Timeout:
        error_msg = "OpenAI API request timed out after 30 seconds"
        print(f"❌ {error_msg}")
        return {"error": error_msg}
    except requests.exceptions.ConnectionError:
        error_msg = "Failed to connect to OpenAI API - network connection error"
        print(f"❌ {error_msg}")
        return {"error": error_msg}
    except Exception as e:
        error_msg = f"Unexpected error in OpenAI Vision API call: {str(e)}"
        print(f"❌ {error_msg}")
        print(f"❌ Error type: {type(e).__name__}")
        return {"error": error_msg}

def analyze_image_with_openrouter(image_url=None, image_base64=None, prompt=None):
    """
    Analyze an image using OpenAI or Gemini Vision capabilities via OpenRouter.
    Requires either `image_url` or `image_base64`.
    """
    try:
        api_key = os.environ.get("OPENROUTER_API_KEY")
        if not api_key:
            raise Exception("OpenRouter API key not configured")

        # Prepare image content
        if image_url:
            image_content = {"type": "image_url", "image_url": {"url": image_url}}
        elif image_base64:
            image_content = {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{image_base64}"}}
        else:
            raise Exception("Either image_url or image_base64 must be provided")

        content = []

        if prompt:
            content.append({
                "type": "text",
                "text": prompt
            })

        content.append(image_content)

        # Prepare the request payload
        payload = {
            "model": "google/gemini-2.5-flash-preview",
            "messages": [
                {
                    "role": "user",
                    "content": content
                }
            ],
            "temperature": 0,
            "response_format": "json"
        }

        print("🤖 Making OpenRouter API request...")

        try:
            response = requests.post(
                'https://openrouter.ai/api/v1/chat/completions',
                headers={
                    'Authorization': f'Bearer {api_key}',
                    'Content-Type': 'application/json'
                },
                json=payload,
                timeout=60
            )
        except Exception as e:
            print(f"❌ Error in API call: {str(e)}")
            return {"error": str(e)}

        print(f"🤖 OpenRouter API response status: {response.status_code}")

        if response.status_code == 200:
            result = response.json()
            content = result['choices'][0]['message']['content']

            # 🔧 Clean up markdown wrapping
            if content.startswith("```json"):
                content = re.sub(r"^```json\s*|\s*```$", "", content.strip())
            elif content.startswith("```"):
                content = re.sub(r"^```\s*|\s*```$", "", content.strip())

            try:
                analysis_result = json.loads(content)
                print("✅ Successfully parsed OpenAI response")
                return analysis_result
            except json.JSONDecodeError as e:
                print(f"❌ Error parsing JSON: {e}")
                print(f"Raw content: {content}")
                return {"error": "Invalid JSON format", "raw_content": content}
        else:
            error_msg = f"OpenRouter API error: {response.status_code} - {response.text}"
            print(f"❌ {error_msg}")
            return {"error": error_msg}

    except Exception as e:
        error_msg = f"❌ Fatal error: {str(e)}"
        print(error_msg)
        return {"error": error_msg} 