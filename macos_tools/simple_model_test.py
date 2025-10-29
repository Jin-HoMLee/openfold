#!/usr/bin/env python3
"""
Simple test to verify OpenFold model can be instantiated on macOS
"""

import torch
import sys
import os

# Add the project root to Python path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

print("🧬 Simple OpenFold Model Test")
print(f"PyTorch version: {torch.__version__}")
print(f"MPS available: {torch.backends.mps.is_available()}")

try:
    from openfold.model.model import AlphaFold
    from openfold.config import model_config
    from tests.config import consts
    print("✅ Successfully imported OpenFold components")
    
    # Try to create a model configuration
    c = model_config(consts.model)
    c.model.evoformer_stack.no_blocks = 2  # Small model for testing
    c.model.evoformer_stack.blocks_per_ckpt = None
    print("✅ Successfully created model configuration")
    
    # Try to instantiate the model
    device = torch.device('cpu')  # Use CPU for initial test
    model = AlphaFold(c).to(device)
    model.eval()
    print(f"✅ Successfully created AlphaFold model on {device}")
    
    # Count parameters
    param_count = sum(p.numel() for p in model.parameters())
    print(f"✅ Model has {param_count:,} parameters")
    
    print("\n🎉 Basic model instantiation test PASSED!")
    print("The OpenFold model can be created successfully on macOS")
    
except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)