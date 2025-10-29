#!/usr/bin/env python3
"""
Visualize protein structure using py3Dmol in Jupyter or as standalone HTML
"""

import sys
import os

def visualize_pdb_html(pdb_path, output_html=None, analysis=None):
    """Create standalone HTML visualization of PDB structure"""
    
    # If no output path specified, create HTML next to the PDB file
    if output_html is None:
        pdb_dir = os.path.dirname(pdb_path)
        pdb_name = os.path.splitext(os.path.basename(pdb_path))[0]
        output_html = os.path.join(pdb_dir, f"{pdb_name}_viewer.html")
    
    try:
        import py3Dmol
    except ImportError:
        print("Installing py3Dmol...")
        os.system("pip install py3Dmol")
        import py3Dmol
    
    # Read PDB file
    with open(pdb_path, 'r') as f:
        pdb_data = f.read()
    
    # Get analysis if not provided
    if analysis is None:
        analysis = analyze_structure(pdb_path)
    
    # Create viewer
    viewer = py3Dmol.view(width=800, height=600)
    viewer.addModel(pdb_data, 'pdb')
    viewer.setStyle({'cartoon': {'color': 'spectrum'}})
    viewer.zoomTo()
    
    # Create enhanced HTML with protein details
    residue_list_str = ", ".join(analysis['residue_list'][:10]) + ("..." if len(analysis['residue_list']) > 10 else "")
    
    html_content = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>Protein Structure Viewer - {os.path.basename(pdb_path)}</title>
        <script src="https://3dmol.org/build/3Dmol-min.js"></script>
        <style>
            body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 20px; background: #f5f5f5; }}
            .container {{ max-width: 1000px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }}
            h1 {{ color: #2c3e50; margin-bottom: 10px; }}
            .info-panel {{ display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-bottom: 20px; }}
            .info-box {{ background: #ecf0f1; padding: 15px; border-radius: 8px; }}
            .info-box h3 {{ margin-top: 0; color: #34495e; }}
            .stat {{ margin: 5px 0; }}
            .stat strong {{ color: #2980b9; }}
            #viewer {{ 
                border: 2px solid #bdc3c7; 
                border-radius: 8px; 
                position: relative; 
                margin: 0 auto; 
                overflow: hidden; 
                background: transparent;
            }}
            #viewer canvas {{
                max-width: 100% !important;
                max-height: 100% !important;
            }}
            .controls {{ margin-top: 15px; text-align: center; }}
            .btn {{ background: #3498db; color: white; border: none; padding: 8px 16px; margin: 0 5px; border-radius: 4px; cursor: pointer; }}
            .btn:hover {{ background: #2980b9; }}
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🧬 OpenFold Prediction: {os.path.basename(pdb_path)}</h1>
            
            <div class="info-panel">
                <div class="info-box">
                    <h3>📊 Structure Details</h3>
                    <div class="stat"><strong>Sequence Length:</strong> {analysis['sequence_length']} residues</div>
                    <div class="stat"><strong>Total Atoms:</strong> {analysis['atoms']:,}</div>
                    <div class="stat"><strong>Chain Count:</strong> {analysis['chains']}</div>
                    <div class="stat"><strong>File Size:</strong> {analysis['file_size_kb']} KB</div>
                </div>
                
                <div class="info-box">
                    <h3>🧪 Composition</h3>
                    <div class="stat"><strong>Residue Types:</strong> {analysis['residue_types']}</div>
                    <div class="stat"><strong>Amino Acids:</strong> {residue_list_str}</div>
                    <div class="stat"><strong>Prediction Model:</strong> OpenFold PTM</div>
                    <div class="stat"><strong>Generated:</strong> {os.path.getctime(pdb_path)}</div>
                </div>
            </div>
            
            <div id="viewer" style="height: 580px; width: 100%; padding: 10px; box-sizing: border-box;"></div>
            
            <div class="controls">
                <button class="btn" onclick="setSpectrum()">Spectrum</button>
                <button class="btn" onclick="setChain()">Solid Color</button>
                <button class="btn" onclick="setSecondaryStructure()">Secondary Structure</button>
                <button class="btn" onclick="setConfidence()">Confidence</button>
                <button class="btn" onclick="resetView()">Reset View</button>
            </div>
        </div>
        
        <script>
            // Global viewer variable for button access
            let viewer;
            
            // Wait for page to load completely
            window.addEventListener('load', function() {{
                viewer = $3Dmol.createViewer("viewer", {{
                    defaultcolors: $3Dmol.rasmolElementColors
                }});
                
                viewer.addModel(`{pdb_data}`, "pdb");
                viewer.setStyle({{"cartoon": {{"color": "spectrum"}}}});
                viewer.zoomTo();
                viewer.render();
                
                // Resize viewer to fit the smaller container properly
                viewer.resize();
            }});
            
            // Button functions
            function setSpectrum() {{
                if (viewer) {{
                    viewer.setStyle({{"cartoon": {{"color": "spectrum"}}}});
                    viewer.render();
                }}
            }}
            
            function setChain() {{
                if (viewer) {{
                    // For single chain, use a solid color (cyan)
                    viewer.setStyle({{"cartoon": {{"color": "cyan"}}}});
                    viewer.render();
                }}
            }}
            
            function setSecondaryStructure() {{
                if (viewer) {{
                    // Secondary structure with manual colors
                    viewer.setStyle({{"cartoon": {{"color": "magenta"}}}});
                    viewer.render();
                }}
            }}
            
            function setConfidence() {{
                if (viewer) {{
                    // B-factor coloring (confidence in predictions)
                    viewer.setStyle({{"cartoon": {{"colorscheme": "RdYlBu", "color": "white"}}}});
                    viewer.render();
                }}
            }}
            
            function resetView() {{
                if (viewer) {{
                    viewer.zoomTo();
                    viewer.render();
                }}
            }}
        </script>
    </body>
    </html>
    """
    
    with open(output_html, 'w') as f:
        f.write(html_content)
    
    print(f"✅ Created {output_html}")
    print(f"🌐 Open in browser: open {output_html}")

def analyze_structure(pdb_path):
    """Basic structure analysis"""
    with open(pdb_path, 'r') as f:
        lines = f.readlines()
    
    atoms = [l for l in lines if l.startswith('ATOM')]
    residues = set(l[17:20].strip() for l in atoms)
    chains = set(l[21] for l in atoms)
    
    # Count residues by chain
    residue_count = len(set((l[21], l[22:26].strip()) for l in atoms))
    
    # Get sequence length and composition
    amino_acids = [l[17:20].strip() for l in atoms if l[12:16].strip() == 'CA']  # CA atoms only
    sequence_length = len(amino_acids)
    
    analysis = {
        'atoms': len(atoms),
        'residue_types': len(residues),
        'chains': len(chains),
        'sequence_length': sequence_length,
        'file_size_kb': round(os.path.getsize(pdb_path)/1024, 1),
        'residue_list': sorted(residues)
    }
    
    print(f"📊 Structure Analysis:")
    print(f"   Atoms: {analysis['atoms']}")
    print(f"   Residues: {analysis['residue_types']} types")
    print(f"   Sequence length: {analysis['sequence_length']} residues")
    print(f"   Chains: {analysis['chains']}")
    print(f"   File size: {analysis['file_size_kb']} KB")
    
    return analysis

if __name__ == "__main__":
    pdb_file = sys.argv[1] if len(sys.argv) > 1 else "examples/monomer/macos_prediction/predictions/6KWC_1_model_1_ptm_unrelaxed.pdb"
    
    if not os.path.exists(pdb_file):
        print(f"❌ File not found: {pdb_file}")
        sys.exit(1)
    
    print(f"🧬 Processing: {pdb_file}")
    analysis = analyze_structure(pdb_file)
    print()
    visualize_pdb_html(pdb_file, analysis=analysis)