@app.route('/api/openai', methods=['POST'])
def proxy_openai():
    try:
        # Directly forward the request to OpenAI
        response = requests.post(
            'https://api.openai.com/v1/chat/completions',
            headers={
                'Authorization': f'Bearer {OPENAI_API_KEY}',
                'Content-Type': 'application/json'
            },
            json=request.json,
            timeout=60
        )

        # Forward the exact response from OpenAI
        return jsonify(response.json()), response.status_code

    except requests.RequestException as e:
        app.logger.error(f"OpenAI API error: {str(e)}")
        return jsonify({"error": "Failed to contact OpenAI API"}), 500
    


@app.route('/upload', methods=['GET', 'POST'])
def upload_file():
    app.logger.info("Received file upload request")
    
    if 'file' not in request.files:
        app.logger.error("No file part in request")
        return jsonify({"error": "No file part"}), 400
    
    file = request.files['file']
    
    if file.filename == '':
        app.logger.error("No selected file")
        return jsonify({"error": "No selected file"}), 400

    # Secure the filename and save the file
    filename = secure_filename(file.filename)
    filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)

    try:
        file.save(filepath)
        app.logger.info(f"File saved at {filepath}")
    except Exception as e:
        app.logger.error(f"Error saving file: {str(e)}")
        return jsonify({"error": "File upload failed"}), 500

    # Construct the file URL
    file_url = f"https://api.theholylabs.com/uploads/{filename}"
    
    return jsonify({
        "message": "File uploaded successfully",
        "file_url": file_url
    }), 200


@app.route('/upload', methods=['GET', 'POST'])
def upload_file():
    app.logger.info("Received file upload request")
    
    if 'file' not in request.files:
        app.logger.error("No file part in request")
        return jsonify({"error": "No file part"}), 400
    
    file = request.files['file']
    
    if file.filename == '':
        app.logger.error("No selected file")
        return jsonify({"error": "No selected file"}), 400

    # Secure the filename and save the file
    filename = secure_filename(file.filename)
    filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)

    try:
        file.save(filepath)
        app.logger.info(f"File saved at {filepath}")
    except Exception as e:
        app.logger.error(f"Error saving file: {str(e)}")
        return jsonify({"error": "File upload failed"}), 500

    # Construct the file URL
    file_url = f"https://api.theholylabs.com/uploads/{filename}"
    
    return jsonify({
        "message": "File uploaded successfully",
        "file_url": file_url
    }), 200
