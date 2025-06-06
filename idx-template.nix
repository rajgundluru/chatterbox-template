# To learn more about how to use Nix to configure your environment
# see: https://firebase.google.com/docs/studio/customize-workspace
{ pkgs, ... }: {
  # Which nixpkgs channel to use.
  channel = "stable-24.05"; # or "unstable"
  # Use https://search.nixos.org/packages to find packages
  packages = [
    pkgs.python3
    pkgs.git
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

    # Create a temporary directory
    TEMP_DIR=$(mktemp -d)
    
    # Clone the repository into the temporary directory
    git clone https://github.com/rajgundluru/chatterbox-template.git "$TEMP_DIR"
    
    # Copy all files from the temporary directory to the output directory
    # Excluding .git directory
    cp -r "$TEMP_DIR"/* "$out/"
    cp -r "$TEMP_DIR"/.[!.]* "$out/" 2>/dev/null || true
    
    # Clean up the temporary directory
    rm -rf "$TEMP_DIR"
    
    # Create virtual environment and install dependencies
    cd "$out"
    python -m venv .venv
    source .venv/bin/activate
    pip install -r requirements.txt

    # Create .idx directory and dev.nix file
    mkdir -p "$out/.idx"
    cat > "$out/.idx/dev.nix" << 'EOF'
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
              env = { PORT = "$PORT" };
              manager = "web";
            };
          };
        };
      };
    }
    EOF
  '';
}
