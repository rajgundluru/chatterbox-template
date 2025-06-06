# To learn more about how to use Nix to configure your environment
# see: https://firebase.google.com/docs/studio/customize-workspace
{ pkgs, ... }: {
  # Which nixpkgs channel to use.
  channel = "stable-24.05"; # or "unstable"
  # Use https://search.nixos.org/packages to find packages
  packages = [
    pkgs.python3
  ];
  # Sets environment variables in the workspace
  env = {};
  idx = {
    # Search for the extensions you want on https://open-vsx.org/ and use "publisher.id"
    extensions = [
      "ms-python.python"
    ];
    workspace = {
      # Runs when a workspace is first created with this `dev.nix` file
      onCreate = { 
        install =
          "python -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt";
        # Open editors for the following files by default, if they exist:
        default.openFiles = [ "README.md" "src/index.html" "main.py" ];
      };
      # To run something each time the workspace is (re)started, use the `onStart` hook
    };
    # Enable previews and customize configuration
    previews = {
      enable = true;
      previews = {
        web = {
          command = [ "python" "main.py" ];
          env = { PORT = "$PORT"; };
          manager = "web";
        };
      };
    };
  };
  # Bootstrap script that runs when the template is first created
  bootstrap = ''
    #!/usr/bin/env bash
    set -euo pipefail

    # Make sure the src directory exists
    mkdir -p src

    # Create initial files
    cat > requirements.txt << 'EOF'
    chatterbox-tts>=0.1.0
    flask>=2.0.0
    torch>=2.0.0
    torchaudio>=2.0.0
    EOF

    cat > src/index.html << 'EOF'
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Text to Speech</title>
        <link rel="stylesheet" href="style.css">
    </head>
    <body>
        <div class="container">
            <h1>Text to Speech Converter</h1>
            <textarea id="text-input" placeholder="Enter text to convert to speech..."></textarea>
            <button id="generate-btn">Generate Audio</button>
            <audio id="audio-player" controls></audio>
        </div>
        <script src="script.js"></script>
    </body>
    </html>
    EOF

    cat > src/style.css << 'EOF'
    body {
        font-family: sans-serif;
        display: flex;
        justify-content: center;
        align-items: center;
        min-height: 100vh;
        background-color: #f4f4f4;
        margin: 0;
    }

    .container {
        background-color: #fff;
        padding: 30px;
        border-radius: 8px;
        box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
        text-align: center;
    }

    h1 {
        color: #333;
        margin-bottom: 20px;
    }

    textarea {
        width: 90%;
        min-height: 100px;
        padding: 10px;
        margin-bottom: 20px;
        border: 1px solid #ddd;
        border-radius: 4px;
        font-size: 16px;
    }

    button {
        background-color: #007bff;
        color: white;
        border: none;
        padding: 10px 20px;
        font-size: 16px;
        border-radius: 4px;
        cursor: pointer;
        transition: background-color 0.3s ease;
    }

    button:hover {
        background-color: #0056b3;
    }

    audio {
        width: 100%;
        margin-top: 20px;
    }
    EOF

    cat > src/script.js << 'EOF'
    document.addEventListener('DOMContentLoaded', () => {
        const textInput = document.getElementById('text-input');
        const generateBtn = document.getElementById('generate-btn');
        const audioPlayer = document.getElementById('audio-player');

        generateBtn.addEventListener('click', async () => {
            const text = textInput.value.trim();
            if (!text) {
                alert("Please enter some text.");
                return;
            }

            try {
                const response = await fetch('/generate_audio', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({ text: text }),
                });

                if (!response.ok) {
                    throw new Error(`HTTP error! status: ${response.status}`);
                }

                const data = await response.json();

                if (data.audio_file_path) {
                    audioPlayer.src = data.audio_file_path;
                    audioPlayer.play();
                } else if (data.error) {
                    alert("Error generating audio: " + data.error);
                } else {
                    alert("Unknown response from server.");
                }
            } catch (error) {
                console.error("Error generating audio:", error);
                alert("Failed to generate audio. Check the console for details.");
            }
        });
    });
    EOF

    cat > main.py << 'EOF'
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

    # Load the TTS model
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
            return jsonify({"error": f"Text is too long. Maximum length is {MAX_TEXT_LENGTH} characters."}), 400

        try:
            print(f"Generating audio for text (first 50 chars): {text[:50]}...")
            wav = model.generate(text)
            output_filename = "generated_audio.wav"
            output_filepath = os.path.join(os.getcwd(), output_filename)

            ta.save(output_filepath, wav, model.sr)
            print(f"Audio saved to {output_filepath}")

            return jsonify({"audio_file_path": f"/{output_filename}"})
        except Exception as e:
            print(f"Error generating audio: {e}. Text was: {text}")
            return jsonify({"error": f"Failed to generate audio: {str(e)}"}), 500

    @app.route('/<path:filename>')
    def serve_audio(filename):
        return send_from_directory('.', filename)

    if __name__ == '__main__':
        print("Starting Flask app...")
        app.run(host='0.0.0.0', port=8080, debug=True)
    EOF

    # Create virtual environment and install dependencies
    python -m venv .venv
    source .venv/bin/activate
    pip install -r requirements.txt

    # Create .idx directory and dev.nix file
    mkdir -p .idx
    cat > .idx/dev.nix << 'EOF'
    { pkgs }: {
      packages = [ pkgs.python3 ];
      idx = {
        extensions = [ "ms-python.python" ];
        workspace = {
          onCreate = {
            install = "python -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt";
            default.openFiles = [ "README.md" "src/index.html" "main.py" ];
          };
        };
        previews = {
          enable = true;
          previews = {
            web = {
              command = [ "python" "main.py" ];
              env = { PORT = "$PORT"; };
              manager = "web";
            };
          };
        };
      };
    }
    EOF
  '';
}
