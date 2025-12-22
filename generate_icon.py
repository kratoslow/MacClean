#!/usr/bin/env python3
"""
Generate MacCoolClean app icons - Clean 3D Mac Mini style with a smile
"""

from PIL import Image, ImageDraw, ImageFont
import os
import math

def create_clean_mac_icon(size):
    """Create a clean, 3D Mac Mini style icon with a friendly smile"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    s = size / 512  # Scale factor
    
    # === BACKGROUND - Clean gradient (soft blue-gray) ===
    for y in range(size):
        ratio = y / size
        # Soft gradient from light blue-gray to slightly darker
        r = int(70 + ratio * 20)
        g = int(130 + ratio * 20)
        b = int(180 + ratio * 20)
        draw.line([(0, y), (size, y)], fill=(r, g, b, 255))
    
    # === MAIN MAC MINI BODY ===
    # Center position
    cx, cy = size // 2, int(size * 0.48)
    
    # Mac Mini dimensions (rounded rectangle, 3D look)
    body_width = int(280 * s)
    body_height = int(180 * s)
    body_depth = int(40 * s)  # 3D depth
    corner_radius = int(35 * s)
    
    # Calculate body bounds
    body_left = cx - body_width // 2
    body_right = cx + body_width // 2
    body_top = cy - body_height // 2
    body_bottom = cy + body_height // 2
    
    # === 3D SHADOW (soft) ===
    shadow_offset = int(15 * s)
    for i in range(int(20 * s), 0, -1):
        alpha = int(40 * (1 - i / (20 * s)))
        draw.rounded_rectangle(
            [body_left + shadow_offset + i//2, body_top + shadow_offset + i//2, 
             body_right + shadow_offset + i//2, body_bottom + body_depth + shadow_offset + i//2],
            radius=corner_radius,
            fill=(0, 0, 0, alpha)
        )
    
    # === 3D SIDE (depth) - darker aluminum ===
    draw.rounded_rectangle(
        [body_left, body_top + body_depth, body_right, body_bottom + body_depth],
        radius=corner_radius,
        fill=(160, 165, 175, 255)
    )
    
    # === MAIN BODY - Aluminum gradient ===
    # Draw the main face with gradient
    for i in range(int(body_top), int(body_bottom)):
        ratio = (i - body_top) / (body_bottom - body_top)
        # Aluminum gradient - light at top, slightly darker at bottom
        gray = int(220 - ratio * 30)
        draw.line([(body_left, i), (body_right, i)], fill=(gray, gray, gray + 5, 255))
    
    # Redraw with rounded corners (clip)
    # Create a mask and apply
    draw.rounded_rectangle(
        [body_left, body_top, body_right, body_bottom],
        radius=corner_radius,
        outline=(200, 200, 205, 255),
        width=int(2 * s)
    )
    
    # === SCREEN AREA (dark, glossy) ===
    screen_margin = int(25 * s)
    screen_left = body_left + screen_margin
    screen_right = body_right - screen_margin
    screen_top = body_top + screen_margin
    screen_bottom = body_bottom - int(50 * s)
    screen_radius = int(15 * s)
    
    # Screen background - dark with subtle gradient
    for i in range(int(screen_top), int(screen_bottom)):
        ratio = (i - screen_top) / (screen_bottom - screen_top)
        gray = int(25 + ratio * 15)
        draw.line([(screen_left, i), (screen_right, i)], fill=(gray, gray + 5, gray + 10, 255))
    
    draw.rounded_rectangle(
        [screen_left, screen_top, screen_right, screen_bottom],
        radius=screen_radius,
        outline=(60, 60, 70, 255),
        width=int(2 * s)
    )
    
    # === FRIENDLY EYES (simple, clean) ===
    eye_y = int(screen_top + (screen_bottom - screen_top) * 0.35)
    eye_spacing = int(50 * s)
    eye_width = int(35 * s)
    eye_height = int(20 * s)
    
    # Left eye - simple curved line (happy closed eye)
    left_eye_x = cx - eye_spacing
    draw.arc(
        [left_eye_x - eye_width//2, eye_y - eye_height//2, 
         left_eye_x + eye_width//2, eye_y + eye_height//2],
        start=200, end=340,
        fill=(255, 255, 255, 255),
        width=int(4 * s)
    )
    
    # Right eye
    right_eye_x = cx + eye_spacing
    draw.arc(
        [right_eye_x - eye_width//2, eye_y - eye_height//2, 
         right_eye_x + eye_width//2, eye_y + eye_height//2],
        start=200, end=340,
        fill=(255, 255, 255, 255),
        width=int(4 * s)
    )
    
    # === SMILE (friendly, clean arc) ===
    smile_y = int(screen_top + (screen_bottom - screen_top) * 0.7)
    smile_width = int(70 * s)
    smile_height = int(35 * s)
    
    draw.arc(
        [cx - smile_width//2, smile_y - smile_height//2,
         cx + smile_width//2, smile_y + smile_height//2],
        start=20, end=160,
        fill=(120, 230, 150, 255),  # Fresh green smile
        width=int(5 * s)
    )
    
    # === SPARKLE (one clean sparkle to show "clean") ===
    sparkle_x = int(body_right - 30 * s)
    sparkle_y = int(body_top + 30 * s)
    sparkle_size = int(20 * s)
    
    # Four-point star sparkle
    # Vertical line
    draw.line(
        [sparkle_x, sparkle_y - sparkle_size, sparkle_x, sparkle_y + sparkle_size],
        fill=(255, 255, 255, 255),
        width=int(3 * s)
    )
    # Horizontal line
    draw.line(
        [sparkle_x - sparkle_size, sparkle_y, sparkle_x + sparkle_size, sparkle_y],
        fill=(255, 255, 255, 255),
        width=int(3 * s)
    )
    # Small diagonal lines
    diag = int(sparkle_size * 0.5)
    draw.line(
        [sparkle_x - diag, sparkle_y - diag, sparkle_x + diag, sparkle_y + diag],
        fill=(255, 255, 255, 200),
        width=int(2 * s)
    )
    draw.line(
        [sparkle_x + diag, sparkle_y - diag, sparkle_x - diag, sparkle_y + diag],
        fill=(255, 255, 255, 200),
        width=int(2 * s)
    )
    # Center glow
    draw.ellipse(
        [sparkle_x - 4*s, sparkle_y - 4*s, sparkle_x + 4*s, sparkle_y + 4*s],
        fill=(255, 255, 255, 255)
    )
    
    # === SMALL SECOND SPARKLE ===
    sparkle2_x = int(body_left + 50 * s)
    sparkle2_y = int(body_bottom - 20 * s)
    sparkle2_size = int(12 * s)
    
    draw.line(
        [sparkle2_x, sparkle2_y - sparkle2_size, sparkle2_x, sparkle2_y + sparkle2_size],
        fill=(255, 255, 255, 230),
        width=int(2 * s)
    )
    draw.line(
        [sparkle2_x - sparkle2_size, sparkle2_y, sparkle2_x + sparkle2_size, sparkle2_y],
        fill=(255, 255, 255, 230),
        width=int(2 * s)
    )
    draw.ellipse(
        [sparkle2_x - 3*s, sparkle2_y - 3*s, sparkle2_x + 3*s, sparkle2_y + 3*s],
        fill=(255, 255, 255, 255)
    )
    
    # === APPLE-STYLE REFLECTION (subtle highlight on body) ===
    highlight_y = body_top + int(15 * s)
    for i in range(int(30 * s)):
        alpha = int(60 * (1 - i / (30 * s)))
        draw.line(
            [body_left + corner_radius, highlight_y + i, 
             body_right - corner_radius, highlight_y + i],
            fill=(255, 255, 255, alpha)
        )
    
    # === BASE/STAND (simple, clean) ===
    base_width = int(80 * s)
    base_height = int(15 * s)
    base_top = body_bottom + body_depth + int(5 * s)
    
    # Simple rounded base
    draw.rounded_rectangle(
        [cx - base_width//2, base_top, cx + base_width//2, base_top + base_height],
        radius=int(5 * s),
        fill=(180, 185, 190, 255)
    )
    # Base shadow
    draw.rounded_rectangle(
        [cx - base_width//2 + 5*s, base_top + base_height, 
         cx + base_width//2 - 5*s, base_top + base_height + 5*s],
        radius=int(3 * s),
        fill=(100, 105, 110, 100)
    )
    
    return img


def main():
    sizes = [16, 32, 64, 128, 256, 512, 1024]
    
    output_dir = "MacCoolClean/Assets.xcassets/AppIcon.appiconset"
    os.makedirs(output_dir, exist_ok=True)
    
    print("✨ Generating clean MacCoolClean icons...")
    
    for size in sizes:
        print(f"  Creating {size}x{size}...")
        icon = create_clean_mac_icon(size)
        
        if size <= 512:
            icon.save(f"{output_dir}/icon_{size}x{size}.png")
        
        if size == 32:
            icon.save(f"{output_dir}/icon_16x16@2x.png")
        elif size == 64:
            icon.save(f"{output_dir}/icon_32x32@2x.png")
        elif size == 256:
            icon.save(f"{output_dir}/icon_128x128@2x.png")
        elif size == 512:
            icon.save(f"{output_dir}/icon_256x256@2x.png")
        elif size == 1024:
            icon.save(f"{output_dir}/icon_512x512@2x.png")
    
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
    
    preview = create_clean_mac_icon(512)
    preview.save("icon_preview.png")
    print("\n✅ Clean icons generated!")
    print("📁 Preview: icon_preview.png")


if __name__ == "__main__":
    main()
