#!/bin/bash

# Screenshot Resizer for Mac App Store Submission
# Place your original screenshots in this folder and run this script

# Required size for Mac App Store (Retina)
TARGET_WIDTH=2880
TARGET_HEIGHT=1800

echo "🖼️  Mac App Store Screenshot Resizer"
echo "======================================"
echo ""

# Check if sips is available (built into macOS)
if ! command -v sips &> /dev/null; then
    echo "Error: sips command not found"
    exit 1
fi

# Create output directory
mkdir -p "resized"

# Process all PNG and JPG files in current directory
for file in *.png *.PNG *.jpg *.JPG *.jpeg *.JPEG; do
    # Skip if no files match
    [ -e "$file" ] || continue
    
    # Skip the readme and this script
    [[ "$file" == "README"* ]] && continue
    [[ "$file" == "resize"* ]] && continue
    
    echo "Processing: $file"
    
    # Get current dimensions
    current_width=$(sips -g pixelWidth "$file" | tail -1 | awk '{print $2}')
    current_height=$(sips -g pixelHeight "$file" | tail -1 | awk '{print $2}')
    
    echo "  Current size: ${current_width}x${current_height}"
    
    # Calculate aspect ratios
    target_ratio=$(echo "scale=4; $TARGET_WIDTH / $TARGET_HEIGHT" | bc)
    current_ratio=$(echo "scale=4; $current_width / $current_height" | bc)
    
    # Copy and resize
    output_file="resized/${file%.*}_${TARGET_WIDTH}x${TARGET_HEIGHT}.png"
    cp "$file" "$output_file"
    
    # Resize to target dimensions (may crop if aspect ratio differs)
    sips -z $TARGET_HEIGHT $TARGET_WIDTH "$output_file" --out "$output_file" 2>/dev/null
    
    echo "  Resized to: ${TARGET_WIDTH}x${TARGET_HEIGHT}"
    echo "  Saved: $output_file"
    echo ""
done

echo "✅ Done! Check the 'resized' folder for your App Store ready screenshots."
echo ""
echo "📱 Upload these to App Store Connect:"
echo "   My Apps → MacCoolClean → macOS Screenshots"

