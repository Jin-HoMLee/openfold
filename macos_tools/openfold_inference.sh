#!/bin/bash
# OpenFold Inference Runner for macOS
# Enhanced version with proper error handling and options

set -e

echo "🧬 OpenFold Inference Runner for macOS"
echo "======================================"

# Function to show help
show_help() {
    echo "Usage: $0 [options] [fasta_dir] [output_dir]"
    echo ""
    echo "Options:"
    echo "  -d, --device DEVICE     Device to use (cpu, mps) [default: cpu]"
    echo "  -c, --config CONFIG     Config preset [default: model_1_ptm]"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Arguments:"
    echo "  fasta_dir               Directory containing FASTA files [default: examples/monomer/fasta_dir]"
    echo "  output_dir              Output directory [default: openfold_results]"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Use defaults"
    echo "  $0 my_fastas my_results              # Custom paths"
    echo "  $0 -d mps examples/monomer/fasta_dir # Use MPS device"
    echo ""
    echo "Requirements:"
    echo "  - OpenFold conda environment must be activated (openfold_env)"
    echo "  - Template mmCIF files in examples/monomer/mmcifs/"
    echo "  - Precomputed alignments in examples/monomer/alignments/"
}

# Default values
DEVICE="cpu"
CONFIG="model_1_ptm"
FASTA_DIR="examples/monomer/fasta_dir"
OUTPUT_DIR="examples/monomer/macos_prediction"
MMCIF_DIR="examples/monomer/mmcifs"
ALIGNMENTS_DIR="examples/monomer/alignments"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--device)
            DEVICE="$2"
            shift 2
            ;;
        -c|--config)
            CONFIG="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            echo "❌ Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            if [[ -z "${FASTA_DIR_SET:-}" ]]; then
                FASTA_DIR="$1"
                FASTA_DIR_SET=true
            elif [[ -z "${OUTPUT_DIR_SET:-}" ]]; then
                OUTPUT_DIR="$1"
                OUTPUT_DIR_SET=true
            else
                echo "❌ Too many arguments"
                show_help
                exit 1
            fi
            shift
            ;;
    esac
done

# Check environment
if [[ "$CONDA_DEFAULT_ENV" != "openfold_env" ]]; then
    echo "❌ Please activate the openfold_env environment first:"
    echo "   conda activate openfold_env"
    exit 1
fi

# Validate device
if [[ "$DEVICE" == "mps" ]]; then
    if ! python3 -c "import torch; assert torch.backends.mps.is_available()" 2>/dev/null; then
        echo "⚠️  MPS not available, falling back to CPU"
        DEVICE="cpu"
    fi
fi

# Check required directories
for dir in "$FASTA_DIR" "$MMCIF_DIR" "$ALIGNMENTS_DIR"; do
    if [[ ! -d "$dir" ]]; then
        echo "❌ Required directory not found: $dir"
        if [[ "$dir" == "$MMCIF_DIR" ]]; then
            echo "   💡 Tip: Run the template download script to get mmCIF files"
        fi
        exit 1
    fi
done

# Check for FASTA files
if [[ -z "$(find "$FASTA_DIR" -name "*.fasta" -o -name "*.fa" | head -1)" ]]; then
    echo "❌ No FASTA files found in $FASTA_DIR"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "✅ Environment: $CONDA_DEFAULT_ENV"
echo "📁 Configuration:"
echo "   FASTA directory: $FASTA_DIR"
echo "   Output directory: $OUTPUT_DIR"
echo "   Template mmCIFs: $MMCIF_DIR"
echo "   Alignments: $ALIGNMENTS_DIR"
echo "   Device: $DEVICE"
echo "   Config preset: $CONFIG"

# Count FASTA files
FASTA_COUNT=$(find "$FASTA_DIR" -name "*.fasta" -o -name "*.fa" | wc -l | tr -d ' ')
echo "   FASTA files: $FASTA_COUNT"

echo ""
echo "🚀 Running OpenFold inference..."
echo "⏱️  Estimated time: $(($FASTA_COUNT * 10)) minutes (depends on sequence length and device)"

# Record start time
START_TIME=$(date +%s)

# Run OpenFold
python3 run_pretrained_openfold.py \
    "$FASTA_DIR" \
    "$MMCIF_DIR" \
    --output_dir "$OUTPUT_DIR" \
    --config_preset "$CONFIG" \
    --model_device "$DEVICE" \
    --use_precomputed_alignments "$ALIGNMENTS_DIR" \
    --skip_relaxation \
    --data_random_seed 42

# Calculate runtime
END_TIME=$(date +%s)
RUNTIME=$((END_TIME - START_TIME))
RUNTIME_MIN=$((RUNTIME / 60))
RUNTIME_SEC=$((RUNTIME % 60))

echo ""
echo "🎉 OpenFold inference completed successfully!"
echo "⏱️  Total runtime: ${RUNTIME_MIN}m ${RUNTIME_SEC}s"
echo "📁 Results saved to: $OUTPUT_DIR"
echo ""
echo "📋 Output files:"
ls -la "$OUTPUT_DIR"/ 2>/dev/null || echo "   (Output directory empty - check for errors above)"

echo ""
echo "🔬 To visualize results:"
echo "   • Use PyMOL, ChimeraX, or other protein viewers"
echo "   • Upload PDB files to online viewers like Mol*"
echo "   • Check confidence scores in the B-factor column"