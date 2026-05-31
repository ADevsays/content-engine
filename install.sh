#!/bin/bash

# Configuration
REPO_URL="https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is required but not installed."
    exit 1
fi

# If running from curl directly, clone the repository first
if [ ! -f "docker-compose.yml" ] || [ ! -d "workflows" ]; then
    echo "This script is running outside of the repository directory."
    echo "It will clone the repository from $REPO_URL to proceed."
    if [ "$REPO_URL" = "https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git" ]; then
        read -p "Enter your Git repository URL to clone: " REPO_URL_INPUT
        if [ -n "$REPO_URL_INPUT" ]; then
            REPO_URL="$REPO_URL_INPUT"
        else
            echo "Error: Repository URL is required when executing outside the repo directory."
            exit 1
        fi
    fi
    
    read -p "Enter target directory name [content-engine]: " TARGET_DIR
    TARGET_DIR=${TARGET_DIR:-content-engine}
    
    git clone "$REPO_URL" "$TARGET_DIR"
    cd "$TARGET_DIR" || exit 1
fi

# Determine compose command
COMPOSE_CMD=""
if docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    echo "Docker Compose is required but not installed."
    exit 1
fi

# Interactive .env creation
if [ ! -f .env ]; then
    echo "Creating .env file from .env.example..."
    cp .env.example .env
    
    read -p "Enter your n8n domain [n8n.yourdomain.com]: " DOMAIN_INPUT
    DOMAIN_INPUT=${DOMAIN_INPUT:-n8n.yourdomain.com}
    
    SECURE_KEY=$(openssl rand -hex 16 2>/dev/null || echo "key-$(date +%s)")
    
    sed -i.bak "s|N8N_DOMAIN=.*|N8N_DOMAIN=$DOMAIN_INPUT|" .env
    sed -i.bak "s|N8N_ENCRYPTION_KEY=.*|N8N_ENCRYPTION_KEY=$SECURE_KEY|" .env
    rm -f .env.bak
    
    echo ".env file generated successfully with domain '$DOMAIN_INPUT'."
    
    # Prompt the user to edit their newly created .env file
    if [ -t 0 ]; then
        echo ""
        echo "========================================================================="
        echo "Now you need to configure your API keys (Telegram, Supabase, Notion, etc.)"
        echo "========================================================================="
        read -p "Do you want to edit the '.env' file now to add your tokens? [Y/n]: " EDIT_NOW
        if [[ "$EDIT_NOW" =~ ^[Yy]?$ ]] || [ -z "$EDIT_NOW" ]; then
            if command -v nano &> /dev/null; then
                nano .env
            elif command -v vim &> /dev/null; then
                vim .env
            elif command -v vi &> /dev/null; then
                vi .env
            else
                echo "No terminal text editor found (nano/vim/vi). Please edit the '.env' file manually."
                read -p "Press [Enter] once you have configured your '.env' file to continue..."
            fi
        else
            echo "Skipping direct edit. Make sure to populate '.env' before using the workflows!"
        fi
    fi
else
    echo "Using existing .env file."
fi

echo "Starting n8n..."
$COMPOSE_CMD up -d

CONTAINER_ID=$($COMPOSE_CMD ps -q n8n)
if [ -n "$CONTAINER_ID" ]; then
    echo "Waiting for n8n to initialize..."
    for i in {1..30}; do
        if curl -s -f http://localhost:5678/healthz &> /dev/null; then
            echo "n8n is healthy!"
            break
        fi
        echo -n "."
        sleep 2
    done
    echo ""
else
    echo "Could not find running n8n container."
    exit 1
fi

echo "Importing credentials..."
if [ -f "./credentials.json" ]; then
    docker cp "./credentials.json" "$CONTAINER_ID:/tmp/credentials.json"
    docker exec -u node "$CONTAINER_ID" n8n import:credentials --input="/tmp/credentials.json"
    docker exec -u node "$CONTAINER_ID" rm -f "/tmp/credentials.json"
    echo "Credentials imported successfully!"
else
    echo "No credentials template found."
fi

echo "Importing workflows..."
if [ -d "./workflows" ]; then
    docker cp "./workflows" "$CONTAINER_ID:/tmp/workflows"
    docker exec -u node "$CONTAINER_ID" n8n import:workflow --separate --input="/tmp/workflows"
    docker exec -u node "$CONTAINER_ID" rm -rf "/tmp/workflows"
    echo "Workflows imported successfully!"
else
    echo "No workflows directory found."
fi

echo "Done! Access your n8n instance at https://\$(grep N8N_DOMAIN .env | cut -d '=' -f 2)"
