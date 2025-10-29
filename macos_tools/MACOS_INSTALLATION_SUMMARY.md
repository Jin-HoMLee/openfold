# macOS Installation Documentation Summary

This document summarizes all the files created and modifications made to support OpenFold installation on macOS.

## Files Created

### 1. `README_MACOS.md`
- **Purpose**: Comprehensive macOS installation guide
- **Content**: 
  - Step-by-step installation instructions
  - Troubleshooting section
  - Performance considerations
  - Compatibility notes
  - Development workflow tips

### 2. `environment_macos.yml`
- **Purpose**: macOS-compatible conda environment file
- **Key Changes from original `environment.yml`**:
  - Removed CUDA dependencies (`cuda`, `pytorch-cuda=12.4`)
  - Removed Linux-specific packages (`gcc=12.4`, `mkl`)
  - Added CPU versions of PyTorch packages
  - Removed `flash-attn` from pip dependencies (CUDA-only)

### 3. `install_macos.sh`
- **Purpose**: Automated installation script
- **Features**:
  - Detects macOS and Apple Silicon
  - Installs Miniconda if not present
  - Creates environment and installs all dependencies
  - Includes error handling and progress reporting
  - Tests installation automatically

## Files Modified

### 1. `README.md`
- **Change**: Added macOS installation section
- **Location**: After the Documentation section
- **Content**: References to macOS-specific documentation and installation script

### 2. `environment_macos.yml` (header comments)
- **Change**: Added explanatory comments
- **Purpose**: Links to README_MACOS.md for context

## Key Differences from Linux Installation

| Component | Linux Version | macOS Version | Reason |
|-----------|---------------|---------------|---------|
| CUDA | `cuda` package | Not included | macOS doesn't support CUDA |
| PyTorch | `pytorch-cuda=12.4` | `pytorch::pytorch` (CPU) | No CUDA on macOS |
| GCC | `gcc=12.4` | Not included | Uses system clang |
| Math Lib | `mkl` | Not included | Uses Accelerate framework |
| Flash Attention | `flash-attn` | Not included | CUDA-only package |
| NumPy | 2.x | Downgraded to 1.x | DeepSpeed compatibility |

## Installation Process Overview

1. **Miniconda Installation**: ARM64 version for Apple Silicon
2. **Mamba Installation**: Faster package resolution
3. **Environment Creation**: Using macOS-compatible package list
4. **Dependency Resolution**: Manual installation of problematic packages
5. **Testing**: Verification of core functionality

## Compatibility Notes

- ✅ **Works**: Basic OpenFold functionality, CPU inference, training
- ⚠️ **Limited**: Performance compared to GPU systems
- ❌ **Doesn't Work**: CUDA extensions (falls back to Python implementations)

## Future Maintenance

When updating OpenFold:

1. Check if new dependencies are macOS-compatible
2. Update `environment_macos.yml` as needed
3. Test the installation script
4. Update documentation for any new workarounds

## Usage Statistics

Based on our installation:
- **Total packages installed**: ~153 conda packages
- **Additional pip packages**: 4 (py-cpuinfo, dm-tree, DLLogger, numpy<2)
- **Disk space**: ~2-3 GB for full environment
- **Installation time**: ~10-15 minutes on good internet connection

## Testing Checklist

For verifying the installation works:

- [ ] Import core packages (torch, deepspeed, numpy, openmm)
- [ ] Import openfold module
- [ ] Run simple inference test
- [ ] Check MPS availability (if applicable)
- [ ] Verify environment activation works

This documentation approach ensures that future macOS users can easily set up OpenFold with all the necessary workarounds and compatibility fixes.