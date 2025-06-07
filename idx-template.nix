# To learn more about how to use Nix to configure your environment
# see: https://firebase.google.com/docs/studio/customize-workspace
{ pkgs, ... }: {
  # Which nixpkgs channel to use.
  channel = "stable-24.05"; # or "unstable"
  # Use https://search.nixos.org/packages to find packages
  packages = [
    pkgs.python3
    pkgs.git
    pkgs.python3Packages.pip
    pkgs.python3Packages.virtualenv
  ];
  # Sets environment variables in the workspace
  env = {
    PYTHONPATH = ".";
  };
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

    # Create the output directory
    mkdir -p "$out"

    # Clone the repository
    git clone https://github.com/rajgundluru/chatterbox-template.git "$out"
    
    # Create .idx directory and copy dev.nix
    mkdir -p "$out/.idx"
    cp ${./dev.nix} "$out/.idx/dev.nix"
    install --mode u+rw ${./dev.nix} "$out/.idx/dev.nix"
    install --mode u+rwx ${./devserver.sh} "$out/devserver.sh"
    
    # Set up Python environment
    cd "$out"
    python -m venv .venv
    source .venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    
    # Make all files writable
    chmod -R u+w "$out"
  '';
}
