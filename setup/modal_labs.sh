#!/bin/bash

# Modal Labs integration script for Local AI Packaged environment
# This script sets up GPU processing capabilities using Modal Labs

# Log file setup for debugging and troubleshooting
LOGFILE="/var/log/cloud-init-ai-setup.log"
exec > >(tee -a $LOGFILE) 2>&1

# Color codes for better log visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Functions for logging
info() {
    echo -e "${GREEN}[INFO] $(date): $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARN] $(date): $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $(date): $1${NC}"
}

# Variables
USERNAME="localai"
CREDENTIALS_FILE="/root/credentials.txt"

info "Setting up Modal Labs integration..."

# Install Modal client library
apt-get install -y python3-pip
pip3 install modal

# Create Modal integration script
mkdir -p /home/$USERNAME/scripts/modal
cat > /home/$USERNAME/scripts/modal/gpu_processor.py << 'EOF'
#!/usr/bin/env python3

import modal
import os
import sys
import argparse

# Create Modal app
app = modal.App("local-ai-gpu-processor")

# Set up the GPU image with necessary libraries
image = (
    modal.Image.debian_slim()
    .pip_install("torch", "transformers", "numpy", "pandas", "sklearn")
    .apt_install("git")
)

@app.function(
    image=image,
    gpu="A100",  # Can be "H100", "A100", "L4", "T4" based on your needs
    timeout=3600
)
def run_gpu_task(code_file=None, code_string=None, input_data=None):
    """
    Run a task on a GPU in Modal's cloud.

    Args:
        code_file: Path to a Python file to execute
        code_string: Python code to execute as a string
        input_data: Data to pass to the code

    Returns:
        The result of the execution
    """
    import torch
    import json
    import tempfile

    # Print GPU info
    print(f"Running on GPU: {torch.cuda.get_device_name(0)}")
    print(f"CUDA available: {torch.cuda.is_available()}")

    result = {
        "success": False,
        "output": None,
        "error": None
    }

    try:
        # Create a namespace for the code execution
        namespace = {
            "input_data": input_data,
            "torch": torch,
            "result": None
        }

        if code_file:
            # Execute the file
            with open(code_file, 'r') as f:
                exec(f.read(), namespace)
        elif code_string:
            # Execute the code string
            exec(code_string, namespace)

        # Get the result
        result["success"] = True
        result["output"] = namespace.get("result", None)

    except Exception as e:
        import traceback
        result["error"] = {
            "message": str(e),
            "traceback": traceback.format_exc()
        }

    return result

def main():
    parser = argparse.ArgumentParser(description="Run GPU tasks using Modal")

    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--file", help="Python file to execute")
    group.add_argument("--code", help="Python code to execute")

    parser.add_argument("--input", help="Input data as JSON string")
    parser.add_argument("--output", help="Output file for results")

    args = parser.parse_args()

    # Parse input data if provided
    input_data = None
    if args.input:
        try:
            input_data = json.loads(args.input)
        except json.JSONDecodeError:
            print("Error: Input data is not valid JSON")
            sys.exit(1)

    # Run the GPU task
    if args.file:
        result = run_gpu_task.remote(code_file=args.file, input_data=input_data)
    else:
        result = run_gpu_task.remote(code_string=args.code, input_data=input_data)

    # Output the result
    if args.output:
        with open(args.output, 'w') as f:
            json.dump(result, f, indent=2)
    else:
        print(json.dumps(result, indent=2))

if __name__ == "__main__":
    main()
EOF

# Create Modal setup instructions
cat > /home/$USERNAME/scripts/modal/README.md << 'EOF'
# Modal Labs GPU Processing

This directory contains scripts to run GPU-accelerated tasks using Modal Labs cloud infrastructure.

## Setup

1. Run the following command to set up your Modal account:
   ```
   modal token new
   ```

2. This will open a browser window to authenticate with Modal. Follow the instructions.

## Running GPU Tasks

Use the `gpu_processor.py` script to run tasks on Modal's GPUs:

### Example: Run a Python file on an A100 GPU

```bash
python3 gpu_processor.py --file your_script.py --output results.json
```

### Example: Run code directly

```bash
python3 gpu_processor.py --code "import torch; result = torch.cuda.device_count()" --output results.json
```

### Example: Pass input data

```bash
python3 gpu_processor.py --file process_data.py --input '{"data": [1, 2, 3]}' --output results.json
```

## Available GPU Types

Modify the script to use different GPU types:
- H100 (fastest)
- A100
- L4
- T4

Change the `gpu` parameter in the `@app.function` decorator.
EOF

# Make scripts executable
chmod +x /home/$USERNAME/scripts/modal/gpu_processor.py
chown -R $USERNAME:$USERNAME /home/$USERNAME/scripts/modal

# Add Modal Labs info to credentials file
cat >> $CREDENTIALS_FILE << EOF

MODAL LABS GPU PROCESSING
-----------------------
1. Set up Modal account by running: modal token new
2. Run GPU tasks using: python3 /home/$USERNAME/scripts/modal/gpu_processor.py
3. Documentation available at: /home/$USERNAME/scripts/modal/README.md
EOF

info "Modal Labs integration setup completed successfully."
