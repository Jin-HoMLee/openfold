# macOS Tools for OpenFold

This directory contains macOS-specific tools for OpenFold installation, testing, and inference.

## Quick Start

```bash
# 1. Test basic functionality
./macos_tools/run_tests.sh simple

# 2. Download required template files
./macos_tools/download_templates.sh

# 3. Run protein structure prediction
./macos_tools/openfold_inference.sh
```

## Tools Overview

### 🧪 **Testing Tools**

#### `simple_model_test.py`
**Purpose**: Quick verification that OpenFold can be imported and instantiated on macOS.

**Usage**:
```bash
conda activate openfold_env
python macos_tools/simple_model_test.py
```

**What it tests**:
- ✅ OpenFold imports work
- ✅ Model configuration creation
- ✅ AlphaFold model instantiation
- ✅ Parameter counting
- ✅ CPU device compatibility

#### `test_model_macos.py`
**Purpose**: macOS-compatible version of model tests that use CPU/MPS instead of CUDA.

**Status**: 🚧 Work in progress - needs debugging for full batch processing

#### `run_tests.sh`
**Purpose**: Convenient test runner with environment checking.

**Usage**:
```bash
./macos_tools/run_tests.sh [simple|full|both|help]
```

### 🚀 **Inference Tools**

#### `openfold_inference.sh` ⭐ **Main Tool**
**Purpose**: Complete OpenFold inference runner for macOS with proper error handling.

**Usage**:
```bash
# Basic usage (uses examples)
./macos_tools/openfold_inference.sh

# Custom input/output
./macos_tools/openfold_inference.sh my_fastas/ my_results/

# Use MPS device (Apple Silicon GPU)
./macos_tools/openfold_inference.sh -d mps

# Show all options
./macos_tools/openfold_inference.sh --help
```

**Features**:
- ✅ Automatic device detection (CPU/MPS)
- ✅ Input validation and error checking
- ✅ Progress tracking and timing
- ✅ Flexible input/output paths
- ✅ Built-in help and examples

#### `download_templates.sh`
**Purpose**: Automatically downloads required mmCIF template files based on alignment data.

**Usage**:
```bash
./macos_tools/download_templates.sh
```

**What it does**:
- Scans precomputed alignments for required PDB templates
- Downloads missing mmCIF files from RCSB PDB
- Skips already downloaded files
- Provides download progress and summary

## Background

The original OpenFold tests in `tests/` are hardcoded for CUDA and will fail on macOS with errors like:
```
AssertionError: Torch not compiled with CUDA enabled
```

These tools provide macOS-compatible alternatives that:
- Use `cpu` or `mps` devices instead of `cuda`
- Properly handle device placement
- Verify that OpenFold works correctly on Apple Silicon

## Device Support

- **CPU**: ✅ Fully supported and tested
- **MPS** (Apple Silicon GPU): ✅ Available but use with caution
  - Some operations may fall back to CPU
  - Numerical precision may differ slightly from CUDA
  - For production use, CPU is more reliable

## Contributing

If you improve these tools or add new macOS-specific tests, please:
1. Test on both Intel and Apple Silicon Macs if possible
2. Document any device-specific behavior
3. Update this README with your changes
4. Consider submitting improvements back to the main OpenFold project