#!/bin/bash
# macOS OpenFold Test Runner
# Convenient script to run macOS-specific tests

set -e

echo "🧬 macOS OpenFold Test Runner"
echo "=============================="

# Check if conda environment is activated
if [[ "$CONDA_DEFAULT_ENV" != "openfold_env" ]]; then
    echo "⚠️  OpenFold environment not activated. Attempting to activate..."
    if command -v conda &> /dev/null; then
        eval "$(conda shell.bash hook)"
        conda activate openfold_env
    else
        echo "❌ Please activate the openfold_env environment first:"
        echo "   conda activate openfold_env"
        exit 1
    fi
fi

echo "✅ Environment: $CONDA_DEFAULT_ENV"
echo ""

# Parse command line arguments
case "${1:-simple}" in
    "simple"|"s")
        echo "🚀 Running simple model test..."
        python macos_tools/simple_model_test.py
        ;;
    "full"|"f")
        echo "🚀 Running full model tests..."
        echo "⚠️  Note: This test is still under development and may fail"
        python macos_tools/test_model_macos.py
        ;;
    "both"|"b")
        echo "🚀 Running both tests..."
        echo ""
        echo "1️⃣ Simple test first:"
        python macos_tools/simple_model_test.py
        echo ""
        echo "2️⃣ Full test (may fail):"
        python macos_tools/test_model_macos.py
        ;;
    "help"|"h"|"-h"|"--help")
        echo "Usage: $0 [test_type]"
        echo ""
        echo "Test types:"
        echo "  simple|s    Run simple model instantiation test (default)"
        echo "  full|f      Run full model forward pass tests"
        echo "  both|b      Run both tests"
        echo "  help|h      Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0          # Run simple test"
        echo "  $0 simple   # Run simple test"
        echo "  $0 full     # Run full test"
        echo "  $0 both     # Run both tests"
        exit 0
        ;;
    *)
        echo "❌ Unknown test type: $1"
        echo "Run '$0 help' for usage information"
        exit 1
        ;;
esac

echo ""
echo "✅ macOS test completed!"