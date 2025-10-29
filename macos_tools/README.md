# macOS Development Tools

This directory contains macOS-specific tools and tests for OpenFold development.

## Files

### `simple_model_test.py`
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

**When to use**:
- After installation to verify basic functionality
- After updates to check if core functionality still works
- When debugging import issues
- For quick smoke tests

### `test_model_macos.py`
**Purpose**: macOS-compatible version of model tests that use CPU/MPS instead of CUDA.

**Usage**:
```bash
conda activate openfold_env
python macos_tools/test_model_macos.py
```

**What it tests**:
- Model forward pass with realistic batch data
- CPU/MPS device compatibility
- Full inference pipeline
- Sequence embedding mode

**Status**: 🚧 Work in progress - needs debugging for full batch processing

**When to use**:
- For more comprehensive testing than the simple test
- When developing macOS-specific features
- For debugging model execution issues

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