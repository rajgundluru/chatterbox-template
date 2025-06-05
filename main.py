from flask import Flask, request, jsonify, send_from_directory
import torchaudio as ta
from chatterbox.tts import ChatterboxTTS
import torch
import os

# --- Start of monkeypatch ---
_original_torch_load = torch.load
def patched_torch_load(*args, **kwargs):
    kwargs['map_location'] = torch.device('cpu')
    return _original_torch_load(*args, **kwargs)
torch.load = patched_torch_load
# --- End of monkeypatch ---

app = Flask(__name__)

# Load the TTS model (do this once when the app starts)
# Ensure the model is loaded with device="cpu" if not using a GPU
try:
    print("Loading ChatterboxTTS model...")
    model = ChatterboxTTS.from_pretrained(device="cpu")
    print("Model loaded successfully.")
except Exception as e:
    print(f"Error loading model: {e}")
    model = None

@app.route('/')
def serve_index():
    return send_from_directory('src', 'index.html')

@app.route('/style.css')
def serve_style():
    return send_from_directory('src', 'style.css')

@app.route('/script.js')
def serve_script():
    return send_from_directory('src', 'script.js')

# Define a maximum character limit for the input text
MAX_TEXT_LENGTH = 500

@app.route('/generate_audio', methods=['POST'])
def generate_audio():
    if model is None:
        return jsonify({"error": "TTS model not loaded"}), 500

    data = request.get_json()
    text = data.get('text')

    if not text:
        return jsonify({"error": "No text provided"}), 400

    if len(text) > MAX_TEXT_LENGTH:
        # Option 1: Truncate the text
        # text = text[:MAX_TEXT_LENGTH]
        # print(f"Input text truncated to {MAX_TEXT_LENGTH} characters.")
        
        # Option 2: Return an error for overly long text
        return jsonify({"error": f"Text is too long. Maximum length is {MAX_TEXT_LENGTH} characters."}), 400

    try:
        print(f"Generating audio for text (first 50 chars): {text[:50]}...")
        wav = model.generate(text) # This is where the original error likely occurred
        output_filename = "generated_audio.wav"
        output_filepath = os.path.join(os.getcwd(), output_filename)

        ta.save(output_filepath, wav, model.sr)
        print(f"Audio saved to {output_filepath}")

        return jsonify({"audio_file_path": f"/{output_filename}"})
    except IndexError as ie:
        # Catching IndexError specifically if it persists
        print(f"IndexError during audio generation: {ie}. Text was: {text}")
        return jsonify({"error": "Failed to generate audio due to an internal indexing issue. Try shorter or simpler text."}), 500
    except Exception as e:
        print(f"Error generating audio: {e}. Text was: {text}")
        return jsonify({"error": f"Failed to generate audio: {str(e)}"}), 500

@app.route('/<path:filename>')
def serve_audio(filename):
    return send_from_directory('.', filename)

if __name__ == '__main__':
    print("Starting Flask app...")
    app.run(host='0.0.0.0', port=8080, debug=True)

# torch.load = _original_torch_load
