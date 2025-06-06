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

    # Clone the repository
    git clone https://github.com/rajgundluru/chatterbox-template.git .
    
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
