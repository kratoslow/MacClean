#!/usr/bin/env python3
"""
Generate MacCoolClean app icons from source image
"""

from PIL import Image
import os

def create_icons_from_source(source_path):
    """Generate all icon sizes from a source image"""
    
    # Load source image
    print(f"📂 Loading source image: {source_path}")
    source = Image.open(source_path)
    
    # Convert to RGBA if needed
    if source.mode != 'RGBA':
        source = source.convert('RGBA')
    
    # Make it square (crop to center if needed)
    width, height = source.size
    if width != height:
        print(f"  Cropping from {width}x{height} to square...")
        size = min(width, height)
        left = (width - size) // 2
        top = (height - size) // 2
        source = source.crop((left, top, left + size, top + size))
    
    print(f"  Source size: {source.size[0]}x{source.size[1]}")
    
    # Icon sizes needed for macOS
    sizes = {
        'icon_16x16.png': 16,
        'icon_16x16@2x.png': 32,
        'icon_32x32.png': 32,
        'icon_32x32@2x.png': 64,
        'icon_128x128.png': 128,
        'icon_128x128@2x.png': 256,
        'icon_256x256.png': 256,
        'icon_256x256@2x.png': 512,
        'icon_512x512.png': 512,
        'icon_512x512@2x.png': 1024,
    }
    
    output_dir = "MacCoolClean/Assets.xcassets/AppIcon.appiconset"
    os.makedirs(output_dir, exist_ok=True)
    
    print("\n🎨 Generating icon sizes...")
    
    for filename, size in sizes.items():
        print(f"  Creating {filename} ({size}x{size})...")
        resized = source.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(f"{output_dir}/{filename}")
    
    # Contents.json
    contents = '''{
  "images" : [
    { "filename" : "icon_16x16.png", "idiom" : "mac", "scale" : "1x", "size" : "16x16" },
    { "filename" : "icon_16x16@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "16x16" },
    { "filename" : "icon_32x32.png", "idiom" : "mac", "scale" : "1x", "size" : "32x32" },
    { "filename" : "icon_32x32@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "32x32" },
    { "filename" : "icon_128x128.png", "idiom" : "mac", "scale" : "1x", "size" : "128x128" },
    { "filename" : "icon_128x128@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "128x128" },
    { "filename" : "icon_256x256.png", "idiom" : "mac", "scale" : "1x", "size" : "256x256" },
    { "filename" : "icon_256x256@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "256x256" },
    { "filename" : "icon_512x512.png", "idiom" : "mac", "scale" : "1x", "size" : "512x512" },
    { "filename" : "icon_512x512@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "512x512" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}'''
    
    with open(f"{output_dir}/Contents.json", "w") as f:
        f.write(contents)
    
    # Also save preview
    preview = source.resize((512, 512), Image.Resampling.LANCZOS)
    preview.save("icon_preview.png")
    
    print("\n✅ All icons generated!")
    print(f"📁 Output: {output_dir}/")
    print("📁 Preview: icon_preview.png")


if __name__ == "__main__":
    import sys
    
    # Check for source image
    source_path = "source_icon.png"
    
    if len(sys.argv) > 1:
        source_path = sys.argv[1]
    
    if not os.path.exists(source_path):
        print(f"❌ Source image not found: {source_path}")
        print("\nPlease save your icon image as 'source_icon.png' in this folder")
        print("Or run: python3 generate_icon.py /path/to/your/image.png")
        exit(1)
    
    create_icons_from_source(source_path)
