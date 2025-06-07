from flask import Flask, request, jsonify, send_from_directory
import torchaudio as ta
from chatterbox.tts import ChatterboxTTS
import torch
import os
import tempfile

# --- Start of monkeypatch ---
# This patch is necessary to load a CUDA-trained model on a CPU.
_original_torch_load = torch.load
def patched_torch_load(*args, **kwargs):
    kwargs['map_location'] = torch.device('cpu')
    return _original_torch_load(*args, **kwargs)
torch.load = patched_torch_load
# --- End of monkeypatch ---

app = Flask(__name__, static_folder='src')

# Load the TTS model (do this once when the app starts)
try:
    print("Loading ChatterboxTTS model...")
    model = ChatterboxTTS.from_pretrained(device="cpu")
    print("Model loaded successfully.")
except Exception as e:
    print(f"CRITICAL: Error loading model: {e}")
    model = None

# --- Static File Serving ---
@app.route('/')
def serve_index():
    return send_from_directory(app.static_folder, 'index.html')

@app.route('/<path:path>')
def serve_static_files(path):
    # Serves script.js, style.css, etc. from the 'src' directory
    return send_from_directory(app.static_folder, path)

# --- Audio Generation ---
MAX_TEXT_LENGTH = 500

@app.route('/generate_audio', methods=['POST'])
def generate_audio():
    if model is None:
        return jsonify({"error": "TTS model is not loaded or failed to load."}), 500

    try:
        # FormData is sent as multipart, so we access fields and files
        text = request.form.get('text')
        exaggeration = float(request.form.get('exaggeration', 1.0))
        temperature = float(request.form.get('temperature', 0.75))
        cfg_weight = float(request.form.get('cfg_weight', 0.5))
        
        audio_prompt_file = request.files.get('audio_prompt')
        audio_prompt_path = None

        if not text:
            return jsonify({"error": "No text provided"}), 400

        if len(text) > MAX_TEXT_LENGTH:
            return jsonify({"error": f"Text is too long. Maximum length is {MAX_TEXT_LENGTH} characters."}), 400
        
        # Save the uploaded audio prompt to a temporary file if it exists
        if audio_prompt_file:
            with tempfile.NamedTemporaryFile(delete=False, suffix='.wav') as temp_audio:
                audio_prompt_file.save(temp_audio.name)
                audio_prompt_path = temp_audio.name
            print(f"Using reference audio from temporary file: {audio_prompt_path}")

        print(f"Generating audio for text: '{text[:50]}...'")
        print(f"With parameters -> Exaggeration: {exaggeration}, Temperature: {temperature}, CFG: {cfg_weight}")

        wav = model.generate(
            text,
            audio_prompt_path=audio_prompt_path,
            exaggeration=exaggeration,
            temperature=temperature,
            cfg_weight=cfg_weight,
        )

        # Clean up the temporary file after generation
        if audio_prompt_path and os.path.exists(audio_prompt_path):
            os.remove(audio_prompt_path)

        output_filename = "generated_audio.wav"
        output_filepath = os.path.join(os.getcwd(), output_filename)

        ta.save(output_filepath, wav, model.sr)
        print(f"Audio saved to {output_filepath}")

        # The client will fetch this file using a separate request
        return jsonify({"audio_file_path": output_filename})

    except Exception as e:
        print(f"ERROR: Failed to generate audio. Reason: {e}")
        import traceback
        traceback.print_exc()
        # Clean up temp file in case of an error during generation
        if 'audio_prompt_path' in locals() and audio_prompt_path and os.path.exists(audio_prompt_path):
            os.remove(audio_prompt_path)
        return jsonify({"error": f"An unexpected error occurred on the server."}), 500

# This route serves the generated audio file
@app.route('/generated_audio.wav')
def serve_audio_file():
    return send_from_directory('.', 'generated_audio.wav', as_attachment=False)

if __name__ == '__main__':
    print("Starting Flask app...")
    app.run(host='0.0.0.0', port=8080, debug=True, threaded=True)