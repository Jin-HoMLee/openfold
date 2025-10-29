#!/usr/bin/env python3
"""
Align two protein structures and save the aligned version
"""

import sys
import os
import numpy as np

def parse_pdb_coords(pdb_file):
    """Extract CA coordinates from PDB file"""
    coords = []
    residues = []
    
    with open(pdb_file, 'r') as f:
        for line in f:
            if line.startswith('ATOM') and line[12:16].strip() == 'CA':
                x = float(line[30:38])
                y = float(line[38:46])
                z = float(line[46:54])
                res_num = int(line[22:26])
                coords.append([x, y, z])
                residues.append(res_num)
    
    return np.array(coords), residues

def kabsch_alignment(P, Q):
    """
    Kabsch algorithm to find optimal rotation matrix
    P: coordinates to align (Nx3)
    Q: reference coordinates (Nx3)
    Returns: rotation matrix and translation vector
    """
    # Center both coordinate sets
    centroid_P = np.mean(P, axis=0)
    centroid_Q = np.mean(Q, axis=0)
    
    P_centered = P - centroid_P
    Q_centered = Q - centroid_Q
    
    # Compute cross-covariance matrix
    H = P_centered.T @ Q_centered
    
    # SVD
    U, S, Vt = np.linalg.svd(H)
    
    # Compute rotation matrix
    R = Vt.T @ U.T
    
    # Ensure proper rotation (det(R) = 1)
    if np.linalg.det(R) < 0:
        Vt[-1, :] *= -1
        R = Vt.T @ U.T
    
    # Compute translation
    t = centroid_Q - R @ centroid_P
    
    return R, t

def apply_transformation(pdb_file, output_file, R, t):
    """Apply rotation and translation to all atoms in PDB file"""
    
    with open(pdb_file, 'r') as f:
        lines = f.readlines()
    
    with open(output_file, 'w') as f:
        for line in lines:
            if line.startswith('ATOM'):
                # Extract coordinates
                x = float(line[30:38])
                y = float(line[38:46])
                z = float(line[46:54])
                
                # Apply transformation
                coord = np.array([x, y, z])
                new_coord = R @ coord + t
                
                # Replace coordinates in line
                new_line = (line[:30] + 
                           f"{new_coord[0]:8.3f}" + 
                           f"{new_coord[1]:8.3f}" + 
                           f"{new_coord[2]:8.3f}" + 
                           line[54:])
                f.write(new_line)
            else:
                f.write(line)

def align_structures(mobile_pdb, reference_pdb, output_pdb=None):
    """Align mobile structure to reference structure"""
    
    if output_pdb is None:
        base_name = os.path.splitext(mobile_pdb)[0]
        output_pdb = f"{base_name}_aligned.pdb"
    
    print(f"🔄 Aligning structures...")
    print(f"   Mobile: {mobile_pdb}")
    print(f"   Reference: {reference_pdb}")
    print(f"   Output: {output_pdb}")
    
    # Extract CA coordinates
    mobile_coords, mobile_res = parse_pdb_coords(mobile_pdb)
    ref_coords, ref_res = parse_pdb_coords(reference_pdb)
    
    print(f"📊 Structure info:")
    print(f"   Mobile CA atoms: {len(mobile_coords)}")
    print(f"   Reference CA atoms: {len(ref_coords)}")
    
    # Check if structures have same number of residues
    if len(mobile_coords) != len(ref_coords):
        print("⚠️  Warning: Different number of CA atoms!")
        # Use minimum length for alignment
        min_len = min(len(mobile_coords), len(ref_coords))
        mobile_coords = mobile_coords[:min_len]
        ref_coords = ref_coords[:min_len]
        print(f"   Using first {min_len} residues for alignment")
    
    # Perform Kabsch alignment
    R, t = kabsch_alignment(mobile_coords, ref_coords)
    
    # Calculate RMSD before alignment
    diff_before = mobile_coords - ref_coords
    rmsd_before = np.sqrt(np.mean(np.sum(diff_before**2, axis=1)))
    
    # Calculate RMSD after alignment
    aligned_coords = (R @ mobile_coords.T).T + t
    diff_after = aligned_coords - ref_coords
    rmsd_after = np.sqrt(np.mean(np.sum(diff_after**2, axis=1)))
    
    print(f"📐 Alignment results:")
    print(f"   RMSD before: {rmsd_before:.3f} Å")
    print(f"   RMSD after:  {rmsd_after:.3f} Å")
    print(f"   Improvement: {rmsd_before - rmsd_after:.3f} Å")
    
    # Apply transformation to all atoms
    apply_transformation(mobile_pdb, output_pdb, R, t)
    
    print(f"✅ Aligned structure saved: {output_pdb}")
    return output_pdb

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python align_structures.py <mobile_pdb> <reference_pdb> [output_pdb]")
        print("Example: python align_structures.py structure1.pdb structure2.pdb aligned.pdb")
        sys.exit(1)
    
    mobile = sys.argv[1]
    reference = sys.argv[2]
    output = sys.argv[3] if len(sys.argv) > 3 else None
    
    if not os.path.exists(mobile):
        print(f"❌ Mobile structure not found: {mobile}")
        sys.exit(1)
    
    if not os.path.exists(reference):
        print(f"❌ Reference structure not found: {reference}")
        sys.exit(1)
    
    aligned_file = align_structures(mobile, reference, output)
    print(f"🧬 Use the aligned structure for comparison!")