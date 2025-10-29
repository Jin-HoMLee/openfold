#!/bin/bash
# OpenFold macOS Installation Script
# This script automates the installation process documented in README_MACOS.md

set -e  # Exit on any error

# Parse command line arguments
UPDATE_MODE=false
HELP_MODE=false
USE_MAMBA_RUN=false

while getopts "uh" opt; do
    case $opt in
        u)
            UPDATE_MODE=true
            ;;
        h)
            HELP_MODE=true
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

if [ "$HELP_MODE" = true ]; then
    echo "OpenFold macOS Installation Script"
    echo "Usage: $0 [-u] [-h]"
    echo "  -u    Update existing installation (force update Miniconda)"
    echo "  -h    Show this help message"
    exit 0
fi

echo "🧬 OpenFold macOS Installation Script"
echo "======================================"

if [ "$UPDATE_MODE" = true ]; then
    echo "🔄 Running in update mode"
fi

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script is designed for macOS only"
    exit 1
fi

# Check if we're on Apple Silicon
ARCH=$(uname -m)
if [[ "$ARCH" != "arm64" ]]; then
    echo "⚠️  Warning: This script is optimized for Apple Silicon (ARM64)"
    echo "   You're running on: $ARCH"
    echo "   Continue anyway? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "📋 Checking prerequisites..."

# Function to safely run commands in the target environment
run_in_env() {
    local env_name="$1"
    shift
    if ! mamba run -n "$env_name" "$@"; then
        echo "❌ Failed to run command in environment $env_name: $*"
        exit 1
    fi
}

# Function to check if conda/mamba is available
check_conda() {
    if command -v conda &> /dev/null; then
        echo "✅ Conda found: $(conda --version)"
        return 0
    else
        return 1
    fi
}

# Function to check if mamba is available
check_mamba() {
    if command -v mamba &> /dev/null; then
        echo "✅ Mamba found: $(mamba --version)"
        return 0
    else
        return 1
    fi
}

# Install or update Miniconda
if ! check_conda || [ "$UPDATE_MODE" = true ]; then
    if [ "$UPDATE_MODE" = true ] && check_conda; then
        echo "📥 Updating Miniconda (force reinstall)..."
        # Remove existing installation
        rm -rf "$HOME/miniconda3"
    else
        echo "📥 Installing Miniconda..."
    fi
    
    curl -O https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh
    bash Miniconda3-latest-MacOSX-arm64.sh -b -p "$HOME/miniconda3"
    rm Miniconda3-latest-MacOSX-arm64.sh
    
    # Initialize conda
    eval "$($HOME/miniconda3/bin/conda shell.bash hook)"
    
    # Add to shell profile if not already present
    if ! grep -q 'miniconda3/bin/conda shell.zsh hook' ~/.zshrc 2>/dev/null; then
        echo 'eval "$($HOME/miniconda3/bin/conda shell.zsh hook)"' >> ~/.zshrc
    fi
    
    echo "✅ Miniconda installed/updated successfully"
else
    # Make sure conda is initialized
    eval "$(conda shell.bash hook 2>/dev/null || echo '')"
fi

# Install mamba if not present
if ! check_mamba; then
    echo "📥 Installing Mamba..."
    conda install -c conda-forge mamba -y
    eval "$(mamba shell hook --shell bash)"
    echo "✅ Mamba installed successfully"
fi

# Check if environment file exists
if [[ ! -f "environment_macos.yml" ]]; then
    echo "❌ environment_macos.yml not found in current directory"
    echo "   Please run this script from the OpenFold repository root"
    exit 1
fi

# Create or update environment
ENV_NAME="openfold_env"
if mamba env list | grep -q "$ENV_NAME"; then
    if [ "$UPDATE_MODE" = true ]; then
        echo "🔄 Force updating environment: $ENV_NAME"
        mamba env update -n "$ENV_NAME" -f environment_macos.yml --prune
    else
        echo "🔄 Updating existing environment: $ENV_NAME"
        mamba env update -n "$ENV_NAME" -f environment_macos.yml
    fi
else
    echo "🆕 Creating new environment: $ENV_NAME"
    mamba env create -n "$ENV_NAME" -f environment_macos.yml
fi

# Activate environment and install additional packages
echo "📦 Installing additional dependencies..."
eval "$(mamba shell hook --shell bash)"

# Check if we're already in the target environment
if [[ "$CONDA_DEFAULT_ENV" != "$ENV_NAME" ]]; then
    echo "🔄 Activating environment $ENV_NAME..."
    mamba activate "$ENV_NAME"
else
    echo "✅ Already in environment $ENV_NAME"
fi

# Verify we're in the correct environment
echo "🔍 Verifying environment activation..."
# Use a more reliable method to check current environment
if [[ "$CONDA_DEFAULT_ENV" == "$ENV_NAME" ]]; then
    echo "✅ Successfully activated environment: $ENV_NAME"
elif conda info --envs | grep -E "^\s*$ENV_NAME\s+\*" > /dev/null; then
    echo "✅ Environment $ENV_NAME is active"
else
    echo "⚠️  Environment activation uncertain, using mamba run for safety"
    echo "   CONDA_DEFAULT_ENV: $CONDA_DEFAULT_ENV"
    echo "   Will use 'mamba run -n $ENV_NAME' for all operations"
    USE_MAMBA_RUN=true
fi

# Install pip dependencies that need special handling
echo "📦 Installing/updating pip dependencies..."
if [[ "$USE_MAMBA_RUN" == "true" ]]; then
    echo "� Using mamba run for pip installations..."
    mamba run -n "$ENV_NAME" pip install py-cpuinfo
    mamba run -n "$ENV_NAME" pip install "numpy<2"
    mamba run -n "$ENV_NAME" pip install dm-tree==0.1.6
    mamba run -n "$ENV_NAME" pip install git+https://github.com/NVIDIA/dllogger.git
else
    # Verify pip is from the correct environment
    PIP_PATH=$(which pip)
    EXPECTED_PIP_PATH="$HOME/miniconda3/envs/$ENV_NAME/bin/pip"
    if [[ "$PIP_PATH" != "$EXPECTED_PIP_PATH" ]]; then
        echo "⚠️  Warning: pip path mismatch, using mamba run instead"
        echo "   Expected: $EXPECTED_PIP_PATH"
        echo "   Found: $PIP_PATH"
        mamba run -n "$ENV_NAME" pip install py-cpuinfo
        mamba run -n "$ENV_NAME" pip install "numpy<2"
        mamba run -n "$ENV_NAME" pip install dm-tree==0.1.6
        mamba run -n "$ENV_NAME" pip install git+https://github.com/NVIDIA/dllogger.git
    else
        echo "✅ Pip is correctly using environment: $ENV_NAME"
        pip install py-cpuinfo
        pip install "numpy<2"
        pip install dm-tree==0.1.6
        pip install git+https://github.com/NVIDIA/dllogger.git
    fi
fi

echo "🧪 Testing installation..."
if [[ "$USE_MAMBA_RUN" == "true" ]]; then
    echo "📦 Using mamba run for testing..."
    mamba run -n "$ENV_NAME" python -c "import torch, deepspeed, numpy, openmm; print('✅ Core packages imported successfully')"
    mamba run -n "$ENV_NAME" python -c "import openfold; print('✅ OpenFold imported successfully')"
else
    # Ensure we're using the correct Python interpreter
    PYTHON_PATH=$(which python)
    EXPECTED_PYTHON_PATH="$HOME/miniconda3/envs/$ENV_NAME/bin/python"
    if [[ "$PYTHON_PATH" != "$EXPECTED_PYTHON_PATH" ]]; then
        echo "⚠️  Warning: Python path mismatch, using mamba run instead"
        mamba run -n "$ENV_NAME" python -c "import torch, deepspeed, numpy, openmm; print('✅ Core packages imported successfully')"
        mamba run -n "$ENV_NAME" python -c "import openfold; print('✅ OpenFold imported successfully')"
    else
        echo "✅ Using correct Python interpreter: $PYTHON_PATH"
        python -c "import torch, deepspeed, numpy, openmm; print('✅ Core packages imported successfully')"
        python -c "import openfold; print('✅ OpenFold imported successfully')"
    fi
fi

echo ""
echo "🔍 Environment Details:"
echo "   Environment name: $ENV_NAME"
echo "   Python path: $(mamba run -n "$ENV_NAME" which python)"
echo "   Pip path: $(mamba run -n "$ENV_NAME" which pip)"
echo "   PyTorch version: $(mamba run -n "$ENV_NAME" python -c "import torch; print(torch.__version__)")"
echo "   NumPy version: $(mamba run -n "$ENV_NAME" python -c "import numpy; print(numpy.__version__)")"

echo ""
echo "🎉 Installation completed successfully!"
echo ""
echo "To use OpenFold:"
echo "  1. Activate the environment: mamba activate $ENV_NAME"
echo "  2. Verify activation: which python (should show the environment path)"
echo "  3. Run OpenFold scripts as documented in README_MACOS.md"
echo ""
echo "📚 For detailed usage instructions, see README_MACOS.md"
echo ""
echo "✅ Installation Notes:"
echo "   • CUDA extensions are not available on macOS (expected)"
echo "   • OpenFold will automatically use CPU/PyTorch fallbacks"
echo "   • MPS (Apple Silicon GPU) acceleration is available for compatible operations"
echo "   • Performance will be slower than CUDA systems but fully functional"