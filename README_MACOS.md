# OpenFold macOS Installation Guide

This document provides a comprehensive guide for installing OpenFold on Apple Silicon (M1/M2/M3) macOS systems. OpenFold was originally designed for Linux with CUDA support, but this guide shows how to set it up on macOS with CPU/MPS acceleration.

## ⚠️ Important Limitations

- **No CUDA Support**: macOS doesn't support CUDA, so GPU acceleration is limited to Apple's Metal Performance Shaders (MPS)
- **Performance**: Significantly slower than Linux with dedicated GPUs
- **C++ Extensions**: CUDA-specific extensions will not compile, but Python fallbacks are used automatically
- **Recommended Use**: Development, small-scale testing, or educational purposes

## Prerequisites

- macOS (tested on Apple Silicon M1/M2/M3)
- Command line tools for Xcode
- At least 8GB of free disk space

## Installation Steps

### 1. Install Miniconda (ARM64 version)

First, download and install Miniconda for Apple Silicon:

```bash
# Download the correct ARM64 version
curl -O https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh

# Install Miniconda
bash Miniconda3-latest-MacOSX-arm64.sh

# When prompted:
# - Accept license terms: yes
# - Install location: press ENTER (use default)
# - Initialize conda: no (we'll do this manually)

# Clean up installer
rm Miniconda3-latest-MacOSX-arm64.sh
```

### 2. Initialize Conda/Mamba

```bash
# Initialize conda for current session
eval "$(/Users/$(whoami)/miniconda3/bin/conda shell.zsh hook)"

# Make it permanent by adding to your shell profile
echo 'eval "$(/Users/$(whoami)/miniconda3/bin/conda shell.zsh hook)"' >> ~/.zshrc

# Install mamba (faster package manager)
conda install -c conda-forge mamba

# Initialize mamba
eval "$(mamba shell hook --shell zsh)"
```

### 3. Create macOS-Compatible Environment

The original `environment.yml` contains Linux/CUDA-specific packages that aren't available on macOS. Use the provided `environment_macos.yml` instead:

```bash
# Create environment using macOS-compatible configuration
mamba env create -n openfold_env -f environment_macos.yml

# Activate the environment
mamba activate openfold_env
```

### 4. Install Additional Dependencies

Some packages need to be installed separately due to compatibility issues:

```bash
# Install missing dependencies for DeepSpeed
pip install py-cpuinfo

# Downgrade NumPy for DeepSpeed compatibility
pip install "numpy<2"

# Install remaining pip packages
pip install dm-tree==0.1.6
pip install git+https://github.com/NVIDIA/dllogger.git
```

### 5. Verify Installation

```bash
# Test core imports
python -c "import torch, deepspeed, numpy, openmm; print('All packages imported successfully!')"

# Test OpenFold import
python -c "import openfold; print('OpenFold imported successfully!')"
```

## Key Differences from Linux Installation

### Modified Dependencies

The `environment_macos.yml` file excludes or modifies the following packages:

**Removed (not available on macOS):**
- `cuda` - CUDA toolkit
- `gcc=12.4` - Specific GCC version
- `pytorch-cuda=12.4` - CUDA-enabled PyTorch
- `mkl` - Intel Math Kernel Library (not needed)

**Modified:**
- `pytorch::pytorch` - Uses CPU/MPS version instead of CUDA
- Added `pytorch::torchvision` and `pytorch::torchaudio`
- Removed `flash-attn` from pip dependencies (CUDA-only)

### CPU Fallback Implementation

**Automatic Fallback**: OpenFold has been patched to automatically detect when CUDA extensions are unavailable and fall back to PyTorch implementations for:
- Attention mechanisms (`openfold/utils/kernel/attention_core.py`)
- Invariant Point Attention in Structure Module (`openfold/model/structure_module.py`)

**Performance Impact**: CPU fallbacks are functional but significantly slower than CUDA implementations. For serious research, use Linux with CUDA GPUs.

### Package Versions

- **NumPy**: Downgraded to 1.x for DeepSpeed compatibility
- **Python**: 3.10 (same as Linux)
- **PyTorch**: 2.2.2 CPU version with MPS support

## Usage

### Activating the Environment

**Critical**: Always verify you're in the correct environment before running pip or python commands.

```bash
# Activate environment
mamba activate openfold_env

# Verify activation (all should point to the environment)
which python   # Should show: /Users/$(whoami)/miniconda3/envs/openfold_env/bin/python
which pip      # Should show: /Users/$(whoami)/miniconda3/envs/openfold_env/bin/pip
conda info --envs  # Should show openfold_env with *

# Alternative: Use mamba run for guaranteed environment isolation
mamba run -n openfold_env python your_script.py
mamba run -n openfold_env pip install package_name
```

### Running OpenFold

```bash
# Example: Run pretrained inference
python run_pretrained_openfold.py \
    --fasta_path example.fasta \
    --model_device cpu \
    --output_dir ./output

# Example: Training (CPU-only, will be very slow)
python train_openfold.py \
    --config_preset model_1 \
    --output_dir ./training_output
```

### Performance Optimization for macOS

```bash
# Set environment variables for better CPU performance
export OMP_NUM_THREADS=8  # Adjust based on your CPU cores
export MKL_NUM_THREADS=8

# For MPS (Apple GPU) support (if available)
export PYTORCH_ENABLE_MPS_FALLBACK=1
```

## Troubleshooting

### Common Issues

#### 1. C++ Extension Compilation Errors
**Error**: `fatal error: 'functional' file not found`

**Solution**: This is expected on macOS. OpenFold will automatically fall back to Python implementations. You can safely ignore these compilation errors.

**What happens**: 
- The installation patches key files to detect missing CUDA extensions
- CPU fallbacks are automatically used for attention mechanisms
- You'll see: `Warning: CUDA attention kernel not available, falling back to PyTorch implementation`

#### 2. DeepSpeed Import Errors
**Error**: `ModuleNotFoundError: No module named 'cpuinfo'`

**Solution**: 
```bash
pip install py-cpuinfo
```

#### 3. NumPy Compatibility Issues
**Error**: `A module that was compiled using NumPy 1.x cannot be run in NumPy 2.x`

**Solution**:
```bash
pip install "numpy<2"
```

#### 4. Environment Activation Issues
**Error**: `mamba activate` not working

**Solution**:
```bash
# Reinitialize shells
eval "$(mamba shell hook --shell zsh)"
# Then try activating again
mamba activate openfold_env
```

#### 5. Pip Installing to Wrong Environment
**Error**: Packages installed with pip are not found after activation

**Diagnosis**:
```bash
# Check if you're in the right environment
which python  # Should show environment path
which pip     # Should show environment path
```

**Solution**:
```bash
# Option 1: Reactivate environment
mamba deactivate
mamba activate openfold_env

# Option 2: Use mamba run for guaranteed isolation
mamba run -n openfold_env pip install package_name

# Option 3: Use explicit pip path
/Users/$(whoami)/miniconda3/envs/openfold_env/bin/pip install package_name
```

### Performance Considerations

1. **Memory Usage**: OpenFold can be memory-intensive. Monitor usage with Activity Monitor
2. **CPU vs MPS**: For small proteins, CPU might be faster than MPS due to overhead
3. **Batch Size**: Reduce batch sizes compared to GPU systems
4. **Precision**: Consider using mixed precision training if supported

## Development Workflow

### Environment Management

```bash
# List environments
mamba env list

# Update environment
mamba env update -f environment_macos.yml

# Export current environment
mamba env export > environment_current.yml

# Remove environment (if needed)
mamba env remove -n openfold_env
```

### Adding New Dependencies

```bash
# Add via conda/mamba (preferred)
mamba install -n openfold_env package_name

# Add via pip (if not available in conda)
mamba activate openfold_env
pip install package_name
```

## Testing Your Installation

### Quick Verification
```bash
# Activate environment
mamba activate openfold_env

# Run simple test (recommended)
./macos_tools/run_tests.sh simple
```

### Running Protein Structure Prediction
```bash
# 1. Download required template files (first time only)
./macos_tools/download_templates.sh

# 2. Run inference on example protein
./macos_tools/openfold_inference.sh

# 3. Check results in examples/monomer/macos_prediction/
ls examples/monomer/macos_prediction/predictions/

# 4. Or with custom input
./macos_tools/openfold_inference.sh my_fasta_dir/ my_results/
```

### macOS-Specific Test Tools
The `macos_tools/` directory contains macOS-compatible tests:

- **`simple_model_test.py`**: Quick verification that OpenFold works
- **`test_model_macos.py`**: More comprehensive CPU/MPS tests (WIP)
- **`run_tests.sh`**: Convenient test runner script

**Why separate tools?** The original tests in `tests/` are hardcoded for CUDA and will fail on macOS. These tools provide macOS-compatible alternatives.

## File Structure

```
openfold/
├── environment.yml           # Original Linux/CUDA environment
├── environment_macos.yml     # macOS-compatible environment
├── README.md                # Original README
├── README_MACOS.md          # This file
├── macos_tools/             # macOS-specific development tools
│   ├── simple_model_test.py # Quick verification test
│   ├── test_model_macos.py  # Comprehensive CPU/MPS tests
│   ├── run_tests.sh         # Test runner script
│   └── README.md            # Tool documentation
└── ... (other OpenFold files)
```

## Comparison: Linux vs macOS Performance

| Aspect | Linux + GPU | macOS + CPU | macOS + MPS |
|--------|-------------|-------------|-------------|
| Speed | 100x | 1x | 3-5x |
| Memory | High VRAM | High RAM | Moderate RAM |
| Compatibility | Full | Limited | Limited |
| Development | Production | Development | Development |

## Contributing

If you encounter macOS-specific issues or have improvements to the installation process:

1. Test your changes thoroughly
2. Update this README with any new workarounds
3. Consider submitting issues/PRs to the main OpenFold repository

## Additional Resources

- [OpenFold GitHub Repository](https://github.com/aqlaboratory/openfold)
- [PyTorch MPS Documentation](https://pytorch.org/docs/stable/notes/mps.html)
- [Conda Environment Management](https://docs.conda.io/projects/conda/en/latest/user-guide/tasks/manage-environments.html)
- [Mamba Documentation](https://mamba.readthedocs.io/)

## Changelog

- **2025-10-29**: Initial macOS installation guide created
- **2025-10-29**: Added troubleshooting section and performance notes
- **2025-10-29**: Documented all installation steps and workarounds

---

**Note**: This installation method prioritizes compatibility and ease of setup over performance. For production protein folding workloads, consider using a Linux system with CUDA-capable GPUs.