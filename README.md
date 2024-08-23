# PythonServiceManager

PythonServiceManager is a robust and versatile Bash script designed to simplify the process of managing Python scripts as system services on Linux. It provides an easy-to-use interface for setting up virtual environments, creating systemd service files, and managing the lifecycle of Python-based services.

## Features

- Set up Python virtual environments with customizable Python versions
- Create systemd service files automatically
- Manage service lifecycle (start, stop, restart, enable, disable)
- View service logs
- Update services and their dependencies
- Configure service settings via a central configuration file
- Support for multiple Python versions and virtual environments

## Prerequisites

- Linux operating system with systemd
- Bash shell
- sudo privileges
- Python (version 3.6 or later recommended)

## Installation

1. Clone this repository or download the `psm.sh` script.
2. Make the script executable:
   ```
   chmod +x psm.sh
   ```
3. Optionally, move the script to a directory in your PATH for easier access:
   ```
   sudo mv psm.sh /usr/local/bin/pythonservicemanager
   ```

## Usage

The basic syntax for using PythonServiceManager is:

```
sudo ./psm.sh <action> <script_name.py> [python_version] [venv_name]
```

Available actions:
- `setup`: Set up a new Python service
- `start`: Start the service
- `stop`: Stop the service
- `restart`: Restart the service
- `status`: Check the status of the service
- `enable`: Enable the service to start on boot
- `disable`: Disable the service from starting on boot
- `logs`: View service logs
- `update`: Update the service (reinstall dependencies and restart)
- `config`: Edit the configuration file

Examples:

1. Set up a new service:
   ```
   sudo ./psm.sh setup my_script.py 3.9 my_venv
   ```

2. Start a service:
   ```
   sudo ./psm.sh start my_script.py
   ```

3. View service logs:
   ```
   sudo ./psm.sh logs my_script.py
   ```

## Configuration Options

The `python_service_manager.conf` file contains various settings to customize the behavior of PythonServiceManager. Key options include:

- `DEFAULT_PYTHON_VERSION`: The default Python version for new services.
- `DEFAULT_VENV_NAME`: The default name for virtual environments.
- `LOG_DIR`: Directory for storing service logs.
- `DEFAULT_RESTART_POLICY`: Default restart policy for services.
- `GLOBAL_ENV_VARS`: Global environment variables for all services.

For a complete list of options and their descriptions, please refer to the comments in the configuration file.

## Contributing

Contributions to PythonServiceManager are welcome! Please feel free to submit pull requests, create issues, or suggest new features.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by the need for a simple, yet powerful tool to manage Python services on Linux systems.
- Thanks to the open-source community for providing the tools and libraries that make this project possible.
