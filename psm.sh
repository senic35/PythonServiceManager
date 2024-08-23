#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.

# Check if script is run with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo"
    exit 1
fi

# Get the actual user who ran the script with sudo
ACTUAL_USER=$(logname)

# Configuration
CONFIG_FILE="/etc/python_service_manager.conf"
DEFAULT_PYTHON_VERSION="3.8"
DEFAULT_VENV_NAME="venv"

# Load configuration if exists
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Config file not found. Using default settings."
fi

# Function to create and setup virtual environment
setup_venv() {
    local SCRIPT_NAME="$1"
    local VENV_NAME="${2:-$DEFAULT_VENV_NAME}"
    local REQUIREMENTS_FILE="requirements.txt"
    local PYTHON_VERSION="${3:-$DEFAULT_PYTHON_VERSION}"

    # Check if the specified Python version is installed
    if ! command -v python$PYTHON_VERSION &> /dev/null; then
        echo "Python $PYTHON_VERSION is not installed. Please install it and try again."
        exit 1
    fi

    # Create virtual environment if it doesn't exist
    if [ ! -d "$VENV_NAME" ]; then
        echo "Creating virtual environment with Python $PYTHON_VERSION..."
        sudo -u $ACTUAL_USER python$PYTHON_VERSION -m venv "$VENV_NAME"
    fi

    # Activate virtual environment
    source "$VENV_NAME/bin/activate"

    # Install or upgrade pip
    sudo -u $ACTUAL_USER $VENV_NAME/bin/pip install --upgrade pip

    # Install requirements if requirements.txt exists
    if [ -f "$REQUIREMENTS_FILE" ]; then
        echo "Installing requirements..."
        sudo -u $ACTUAL_USER $VENV_NAME/bin/pip install -r "$REQUIREMENTS_FILE"
    fi

    echo "Virtual environment setup complete."
}

# Function to create systemd service file
create_service_file() {
    local SCRIPT_NAME="$1"
    local SERVICE_NAME="${SCRIPT_NAME%.*}"
    local SCRIPT_DIR=$(pwd)
    local SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"
    local VENV_NAME="${2:-$DEFAULT_VENV_NAME}"

    echo "Creating systemd service file..."
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Python Script Service for $SCRIPT_NAME
After=network.target

[Service]
ExecStart=$SCRIPT_DIR/$VENV_NAME/bin/python $SCRIPT_DIR/$SCRIPT_NAME
WorkingDirectory=$SCRIPT_DIR
User=$ACTUAL_USER
Group=$ACTUAL_USER
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
Environment="PYTHONUNBUFFERED=1"
Environment="SCRIPT_ENV=production"

[Install]
WantedBy=multi-user.target
EOF

    echo "Systemd service file created at $SERVICE_FILE"
}

# Function to manage the service
manage_service() {
    local ACTION="$1"
    local SCRIPT_NAME="$2"
    local SERVICE_NAME="${SCRIPT_NAME%.*}"

    case "$ACTION" in
        start)
            systemctl start "$SERVICE_NAME"
            echo "Service started."
            ;;
        stop)
            systemctl stop "$SERVICE_NAME"
            echo "Service stopped."
            ;;
        restart)
            systemctl restart "$SERVICE_NAME"
            echo "Service restarted."
            ;;
        status)
            systemctl status "$SERVICE_NAME"
            ;;
        enable)
            systemctl enable "$SERVICE_NAME"
            echo "Service enabled to start on boot."
            ;;
        disable)
            systemctl disable "$SERVICE_NAME"
            echo "Service disabled from starting on boot."
            ;;
        logs)
            journalctl -u "$SERVICE_NAME" -f
            ;;
        update)
            setup_venv "$SCRIPT_NAME" "$VENV_NAME" "$PYTHON_VERSION"
            systemctl restart "$SERVICE_NAME"
            echo "Service updated and restarted."
            ;;
        config)
            nano "$CONFIG_FILE"
            echo "Configuration updated. Please restart the service to apply changes."
            ;;
        *)
            echo "Invalid action. Use setup, start, stop, restart, status, enable, disable, logs, update, or config."
            exit 1
            ;;
    esac
}

# Function to check if the script exists
check_script_exists() {
    local SCRIPT_NAME="$1"
    if [ ! -f "$SCRIPT_NAME" ]; then
        echo "Error: Script $SCRIPT_NAME does not exist in the current directory."
        exit 1
    fi
}

# Function to create or update configuration
update_config() {
    local PYTHON_VERSION="$1"
    local VENV_NAME="$2"

    echo "Updating configuration..."
    cat > "$CONFIG_FILE" << EOF
# Python Service Manager Configuration
PYTHON_VERSION="$PYTHON_VERSION"
VENV_NAME="$VENV_NAME"
EOF
    echo "Configuration updated."
}

# Main script logic
if [ $# -lt 2 ]; then
    echo "Usage: $0 <setup|start|stop|restart|status|enable|disable|logs|update|config> <script_name.py> [python_version] [venv_name]"
    exit 1
fi

ACTION="$1"
SCRIPT_NAME="$2"
PYTHON_VERSION="${3:-$DEFAULT_PYTHON_VERSION}"
VENV_NAME="${4:-$DEFAULT_VENV_NAME}"

check_script_exists "$SCRIPT_NAME"

if [ "$ACTION" = "setup" ]; then
    setup_venv "$SCRIPT_NAME" "$VENV_NAME" "$PYTHON_VERSION"
    create_service_file "$SCRIPT_NAME" "$VENV_NAME"
    update_config "$PYTHON_VERSION" "$VENV_NAME"
    systemctl daemon-reload
    echo "Setup complete. You can now start the service with: sudo $0 start $SCRIPT_NAME"
elif [ "$ACTION" = "config" ]; then
    update_config "$PYTHON_VERSION" "$VENV_NAME"
else
    manage_service "$ACTION" "$SCRIPT_NAME"
fi
