#!/bin/bash
# Test script to verify OpenFold macOS installation

set -e

echo "🧪 OpenFold macOS Installation Verification"
echo "=========================================="

# Check if mamba is available
if ! command -v mamba &> /dev/null; then
    echo "❌ Mamba not found. Please run install_macos.sh first."
    exit 1
fi

# Check if environment exists
ENV_NAME="openfold_env"
if ! mamba env list | grep -q "$ENV_NAME"; then
    echo "❌ Environment $ENV_NAME not found. Please run install_macos.sh first."
    exit 1
fi

echo "✅ Environment $ENV_NAME found"

# Test imports in the environment
echo "🧬 Testing OpenFold imports..."

# Core scientific packages
echo "📦 Testing core packages..."
mamba run -n "$ENV_NAME" python -c "
import sys
print(f'Python: {sys.version}')

import torch
print(f'PyTorch: {torch.__version__}')
print(f'MPS available: {torch.backends.mps.is_available()}')

import numpy as np
print(f'NumPy: {np.__version__}')

import deepspeed
print(f'DeepSpeed: {deepspeed.__version__}')

import openmm
print(f'OpenMM: {openmm.__version__}')

print('✅ All core packages imported successfully')
"

# OpenFold specific
echo "🔬 Testing OpenFold modules..."
mamba run -n "$ENV_NAME" python -c "
import openfold
print(f'✅ OpenFold main module imported')

from openfold.model.model import AlphaFold
print('✅ AlphaFold model class imported')

from openfold.config import model_config
print('✅ Model config imported')

from openfold.data import data_pipeline
print('✅ Data pipeline imported')

print('✅ All OpenFold modules imported successfully')
"

# Test a simple tensor operation
echo "🧮 Testing tensor operations..."
mamba run -n "$ENV_NAME" python -c "
import torch
import numpy as np

# Test basic tensor operations
x = torch.randn(10, 10)
y = torch.mm(x, x.t())
print(f'✅ Basic tensor operations work: {y.shape}')

# Test MPS if available
if torch.backends.mps.is_available():
    device = torch.device('mps')
    x_mps = x.to(device)
    y_mps = torch.mm(x_mps, x_mps.t())
    print(f'✅ MPS operations work: {y_mps.device}')
else:
    print('ℹ️  MPS not available, using CPU only')

print('✅ Tensor operations completed successfully')
"

echo ""
echo "🎉 All tests passed! OpenFold installation is working correctly."
echo ""
echo "📚 Next steps:"
echo "  1. Activate environment: mamba activate $ENV_NAME"
echo "  2. Check available scripts: ls *.py"
echo "  3. Run inference: python run_pretrained_openfold.py --help"
echo "  4. See README_MACOS.md for detailed usage instructions"