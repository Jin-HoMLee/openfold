#!/bin/bash
# Template Downloader for OpenFold on macOS
# Downloads required mmCIF template files based on HHsearch results

set -e

echo "🧬 OpenFold Template Downloader"
echo "==============================="

MMCIF_DIR="examples/monomer/mmcifs"
ALIGNMENTS_DIR="examples/monomer/alignments"

# Function to extract PDB IDs from HHsearch output
extract_pdb_ids() {
    local hhr_file="$1"
    if [[ -f "$hhr_file" ]]; then
        # Extract PDB IDs from lines like "  1 2DFB_A Endo-1,4-beta-xylanase..."
        grep -E "^[[:space:]]*[0-9]+[[:space:]][A-Z0-9]+_[A-Z]" "$hhr_file" | \
        head -20 | \
        awk '{print $2}' | \
        cut -d'_' -f1 | \
        tr '[:upper:]' '[:lower:]' | \
        sort -u
    fi
}

# Create mmCIF directory if it doesn't exist
mkdir -p "$MMCIF_DIR"

echo "📁 Template directory: $MMCIF_DIR"
echo "📊 Alignment directory: $ALIGNMENTS_DIR"

# Find all HHsearch output files
HHR_FILES=$(find "$ALIGNMENTS_DIR" -name "hhsearch_output.hhr" 2>/dev/null || true)

if [[ -z "$HHR_FILES" ]]; then
    echo "❌ No HHsearch alignment files found in $ALIGNMENTS_DIR"
    echo "   Make sure you have precomputed alignments with hhsearch_output.hhr files"
    exit 1
fi

# Collect all unique PDB IDs
ALL_PDB_IDS=""
for hhr_file in $HHR_FILES; do
    echo "🔍 Processing: $hhr_file"
    PDB_IDS=$(extract_pdb_ids "$hhr_file")
    ALL_PDB_IDS="$ALL_PDB_IDS $PDB_IDS"
done

# Remove duplicates and sort
UNIQUE_PDB_IDS=$(echo $ALL_PDB_IDS | tr ' ' '\n' | sort -u | grep -v '^$' | head -50)

if [[ -z "$UNIQUE_PDB_IDS" ]]; then
    echo "❌ No PDB IDs found in alignment files"
    exit 1
fi

echo ""
echo "📋 Found template PDB IDs:"
echo "$UNIQUE_PDB_IDS" | tr '\n' ' '
echo ""

# Count how many we need to download
TOTAL_COUNT=$(echo "$UNIQUE_PDB_IDS" | wc -l | tr -d ' ')
EXISTING_COUNT=0
TO_DOWNLOAD=""

for pdb_id in $UNIQUE_PDB_IDS; do
    if [[ -f "$MMCIF_DIR/${pdb_id}.cif" ]]; then
        EXISTING_COUNT=$((EXISTING_COUNT + 1))
    else
        TO_DOWNLOAD="$TO_DOWNLOAD $pdb_id"
    fi
done

DOWNLOAD_COUNT=$(echo "$TO_DOWNLOAD" | wc -w | tr -d ' ')

echo "📊 Template status:"
echo "   Total needed: $TOTAL_COUNT"
echo "   Already downloaded: $EXISTING_COUNT"
echo "   To download: $DOWNLOAD_COUNT"

if [[ $DOWNLOAD_COUNT -eq 0 ]]; then
    echo "✅ All required templates already downloaded!"
    exit 0
fi

echo ""
echo "📥 Downloading missing templates..."

# Download missing templates
DOWNLOADED=0
FAILED=0

for pdb_id in $TO_DOWNLOAD; do
    if [[ -n "$pdb_id" ]]; then
        echo -n "   Downloading ${pdb_id}.cif... "
        if curl -s -f -o "$MMCIF_DIR/${pdb_id}.cif" "https://files.rcsb.org/download/${pdb_id}.cif"; then
            echo "✅"
            DOWNLOADED=$((DOWNLOADED + 1))
        else
            echo "❌"
            FAILED=$((FAILED + 1))
            rm -f "$MMCIF_DIR/${pdb_id}.cif"  # Remove failed download
        fi
    fi
done

echo ""
echo "📊 Download summary:"
echo "   Successfully downloaded: $DOWNLOADED"
echo "   Failed: $FAILED"
echo "   Total templates available: $((EXISTING_COUNT + DOWNLOADED))"

if [[ $FAILED -gt 0 ]]; then
    echo ""
    echo "⚠️  Some templates failed to download (may be obsolete or unavailable)"
    echo "   OpenFold will still work with the available templates"
fi

echo ""
echo "✅ Template download completed!"
echo "🚀 You can now run OpenFold inference with:"
echo "   ./macos_tools/openfold_inference.sh"