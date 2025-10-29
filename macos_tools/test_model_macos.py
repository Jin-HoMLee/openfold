#!/usr/bin/env python3
"""
macOS-compatible version of model tests that use CPU/MPS instead of CUDA
"""

import torch
import torch.nn as nn
import unittest
import sys
import os

# Add the project root to Python path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from openfold.model.model import AlphaFold
from openfold.config import model_config
from openfold.data import data_transforms
from tests.data_utils import random_template_feats, random_extra_msa_feats
from tests.config import consts

def get_device():
    """Get the best available device for macOS"""
    # For now, let's use CPU to avoid MPS-specific issues
    return torch.device('cpu')
    # Uncomment below to use MPS when ready
    # if torch.backends.mps.is_available():
    #     return torch.device('mps')
    # else:
    #     return torch.device('cpu')

class TestModelMacOS(unittest.TestCase):
    def setUp(self):
        self.device = get_device()
        print(f"Using device: {self.device}")

    def test_dry_run_cpu_mps(self):
        """Test dry run using CPU or MPS instead of CUDA"""
        n_seq = 4
        n_res = 32
        n_templ = 2
        n_extra_seq = 8

        c = model_config(consts.model)
        c.model.evoformer_stack.no_blocks = 4  # no need to go overboard here
        c.model.evoformer_stack.blocks_per_ckpt = None  # don't want to set up
        # deepspeed for this test

        # Use CPU/MPS instead of CUDA
        model = AlphaFold(c).to(self.device)
        model.eval()

        batch = {}
        tf = torch.randint(c.model.input_embedder.tf_dim - 1, size=(n_res,))
        batch["target_feat"] = nn.functional.one_hot(
            tf, c.model.input_embedder.tf_dim
        ).float()
        batch["aatype"] = torch.argmax(batch["target_feat"], dim=-1)
        batch["residue_index"] = torch.arange(n_res)

        batch["msa_feat"] = torch.rand((n_seq, n_res, c.model.input_embedder.msa_dim))
        t_feats = random_template_feats(n_templ, n_res)
        batch.update({k: torch.tensor(v) for k, v in t_feats.items()})
        extra_feats = random_extra_msa_feats(n_extra_seq, n_res)
        batch.update({k: torch.tensor(v) for k, v in extra_feats.items()})
        
        # Add missing masks
        batch["msa_mask"] = torch.randint(low=0, high=2, size=(n_seq, n_res)).float()
        batch["seq_mask"] = torch.randint(low=0, high=2, size=(n_res,)).float()
        batch.update(data_transforms.make_atom14_masks(batch))
        batch["no_recycling_iters"] = torch.tensor(2.)

        # Add recycling dimensions
        from openfold.utils.tensor_utils import tensor_tree_map
        add_recycling_dims = lambda t: (
            t.unsqueeze(-1).expand(*t.shape, c.data.common.max_recycling_iters)
        )
        batch = tensor_tree_map(add_recycling_dims, batch)

        # Move batch to device
        to_device = lambda t: t.to(self.device) if isinstance(t, torch.Tensor) else t
        batch = tensor_tree_map(to_device, batch)

        with torch.no_grad():
            out = model(batch)

        print("✅ Dry run test passed!")
        print(f"Output keys: {list(out.keys())}")

    def test_dry_run_seqemb_mode_cpu_mps(self):
        """Test dry run in sequence embedding mode using CPU or MPS"""
        n_seq = 2
        n_res = 32
        n_templ = 2
        msa_dim = 49

        c = model_config("seq_model_esm1b")
        c.model.evoformer_stack.no_blocks = 2
        c.model.evoformer_stack.blocks_per_ckpt = None
        
        # Use CPU/MPS instead of CUDA
        model = AlphaFold(c).to(self.device)
        model.eval()

        batch = {}
        tf = torch.randint(c.model.preembedding_embedder.tf_dim - 1, size=(n_res,))
        batch["target_feat"] = nn.functional.one_hot(tf, c.model.preembedding_embedder.tf_dim).float()
        batch["aatype"] = torch.argmax(batch["target_feat"], dim=-1)
        batch["residue_index"] = torch.arange(n_res)
        batch["msa_feat"] = torch.rand((n_seq, n_res, msa_dim))
        batch["seq_embedding"] = torch.rand((n_res, c.model.preembedding_embedder.preembedding_dim))

        t_feats = random_template_feats(n_templ, n_res)
        batch.update({k: torch.tensor(v) for k, v in t_feats.items()})

        # Add required masks
        batch["msa_mask"] = torch.randint(low=0, high=2, size=(n_seq, n_res)).float()
        batch["seq_mask"] = torch.randint(low=0, high=2, size=(n_res,)).float()
        batch.update(data_transforms.make_atom14_masks(batch))
        batch["no_recycling_iters"] = torch.tensor(2.)

        # Add recycling dimensions
        from openfold.utils.tensor_utils import tensor_tree_map
        add_recycling_dims = lambda t: (
            t.unsqueeze(-1).expand(*t.shape, c.data.common.max_recycling_iters)
        )
        batch = tensor_tree_map(add_recycling_dims, batch)

        # Move batch to device  
        to_device = lambda t: t.to(self.device) if isinstance(t, torch.Tensor) else t
        batch = tensor_tree_map(to_device, batch)

        with torch.no_grad():
            out = model(batch)

        print("✅ Sequence embedding mode test passed!")
        print(f"Output keys: {list(out.keys())}")

if __name__ == '__main__':
    print("🧬 Running macOS-compatible OpenFold model tests")
    print(f"PyTorch version: {torch.__version__}")
    print(f"MPS available: {torch.backends.mps.is_available()}")
    
    unittest.main(verbosity=2)