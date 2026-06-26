#!/bin/bash

while true; do
    echo "1) Install dependencies"
    echo "2) Build (client + PHP server)"
    echo "3) Exit"
    echo "4) Build HTML5 client only"
    echo "5) Build PHP backend only"
    echo "6) Build JS/serverless backend only"
    echo "7) Run locally: HTML5 client + PHP backend   (http://127.0.0.1:8080)"
    echo "8) Run locally: HTML5 client + JS backend     (http://127.0.0.1:8080)"
    read -p "Choose an option: " choice
    case $choice in
        1)
            echo "Installing dependencies..."

            # Detect OS and install dependencies accordingly
            if [[ "$OSTYPE" == "linux-gnu"* ]]; then
                echo "Detected Linux. Installing dependencies using apt-get..."
                sudo apt-get update
                sudo apt-get install -y npm haxe lxi
            elif [[ "$OSTYPE" == "darwin"* ]]; then
                echo "Detected macOS. Installing dependencies using brew..."
                brew install node haxe lxi
            else
                echo "Unsupported OS. Please install dependencies manually."
            fi

            # Restore the exact, mutually-compatible Haxe libraries pinned in
            # haxe_libraries/*.hxml (HaxeUI + the tink stack, at versions that
            # build on Haxe 5.0.0-preview.1). Much more reliable than installing
            # "latest" of each, which pulls incompatible versions.
            npx lix download
            ;;
        2)
            echo "Building project (client + PHP server)..."
            npx haxe build.hxml
            ;;
        4)
            echo "Building HTML5 client only..."
            npx haxe build.client.hxml
            ;;
        5)
            echo "Building PHP backend only..."
            npx haxe build.server.php.hxml
            ;;
        6)
            echo "Building JS/serverless backend only..."
            npx haxe build.server.js.hxml
            ;;
        7)
            echo "Building client + PHP backend..."
            npx haxe build.client.hxml && npx haxe build.server.php.hxml || continue
            echo "Serving on http://127.0.0.1:8080  (Ctrl+C to stop)"
            php -S 127.0.0.1:8080 tools/dev-router-php.php
            ;;
        8)
            echo "Building client + JS dev server..."
            mkdir -p deploy/local
            npx haxe build.client.hxml && npx haxe build.devserver.node.hxml || continue
            echo "Serving on http://127.0.0.1:8080  (Ctrl+C to stop)"
            PORT=8080 WWW_DIR=deploy/www/html5 node deploy/local/devserver.js
            ;;
        3)
            exit 0
            ;;
        *)
            echo "Invalid option. Please choose a valid option."
            ;;
    esac
done