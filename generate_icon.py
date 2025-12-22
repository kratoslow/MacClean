#!/usr/bin/env python3
"""
MacClean App Icon Generator
Creates a cartoony iMac with cleaning wiper icon
"""

import os
import subprocess
from math import pi, sin, cos

try:
    from PIL import Image, ImageDraw, ImageFilter, ImageFont
except ImportError:
    print("Installing Pillow...")
    subprocess.run(["pip3", "install", "Pillow"], check=True)
    from PIL import Image, ImageDraw, ImageFilter, ImageFont


def create_gradient(size, color1, color2, direction='vertical'):
    """Create a gradient image"""
    img = Image.new('RGBA', (size, size))
    draw = ImageDraw.Draw(img)
    
    for i in range(size):
        ratio = i / size
        r = int(color1[0] + (color2[0] - color1[0]) * ratio)
        g = int(color1[1] + (color2[1] - color1[1]) * ratio)
        b = int(color1[2] + (color2[2] - color1[2]) * ratio)
        a = int(color1[3] + (color2[3] - color1[3]) * ratio) if len(color1) > 3 else 255
        
        if direction == 'vertical':
            draw.line([(0, i), (size, i)], fill=(r, g, b, a))
        else:
            draw.line([(i, 0), (i, size)], fill=(r, g, b, a))
    
    return img


def draw_rounded_rect(draw, xy, radius, fill):
    """Draw a rounded rectangle"""
    x1, y1, x2, y2 = xy
    
    # Draw main rectangles
    draw.rectangle([x1 + radius, y1, x2 - radius, y2], fill=fill)
    draw.rectangle([x1, y1 + radius, x2, y2 - radius], fill=fill)
    
    # Draw corners
    draw.ellipse([x1, y1, x1 + radius * 2, y1 + radius * 2], fill=fill)
    draw.ellipse([x2 - radius * 2, y1, x2, y1 + radius * 2], fill=fill)
    draw.ellipse([x1, y2 - radius * 2, x1 + radius * 2, y2], fill=fill)
    draw.ellipse([x2 - radius * 2, y2 - radius * 2, x2, y2], fill=fill)


def create_icon(size):
    """Create the MacClean icon at specified size"""
    
    # Create base image with transparency
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Padding for the icon
    padding = int(size * 0.06)
    icon_size = size - padding * 2
    
    # Colors
    bg_color1 = (89, 55, 110, 255)      # Dark purple
    bg_color2 = (140, 70, 130, 255)     # Medium purple/magenta
    
    screen_color1 = (233, 69, 96, 255)   # Bright pink/red
    screen_color2 = (255, 120, 150, 255) # Light pink
    
    imac_body = (200, 200, 205, 255)     # Silver
    imac_stand = (180, 180, 185, 255)    # Darker silver
    
    wiper_handle = (60, 60, 70, 255)     # Dark gray
    wiper_blade = (40, 40, 50, 255)      # Darker gray
    
    # Draw background with gradient
    bg_img = create_gradient(size, bg_color1, bg_color2)
    
    # Create rounded background
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    corner_radius = int(size * 0.22)  # macOS style rounded corners
    draw_rounded_rect(mask_draw, [padding, padding, size - padding, size - padding], corner_radius, 255)
    
    # Add some noise/texture dots to background
    import random
    random.seed(42)  # Consistent pattern
    for _ in range(int(size * 0.8)):
        x = random.randint(padding, size - padding)
        y = random.randint(padding, size - padding)
        alpha = random.randint(10, 30)
        dot_size = max(1, int(size * 0.003))
        draw.ellipse([x, y, x + dot_size, y + dot_size], fill=(255, 255, 255, alpha))
    
    # Composite background
    result = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    result.paste(bg_img, mask=mask)
    
    # Add texture dots on top
    result.paste(img, mask=img)
    
    draw = ImageDraw.Draw(result)
    
    # === Draw iMac ===
    
    # iMac dimensions
    imac_width = int(size * 0.55)
    imac_height = int(size * 0.42)
    imac_x = (size - imac_width) // 2
    imac_y = int(size * 0.22)
    
    screen_margin = int(size * 0.025)
    bezel = int(size * 0.02)
    chin_height = int(size * 0.045)
    
    # Screen bezel (outer frame) - lighter edge for 3D effect
    bezel_radius = int(size * 0.03)
    draw_rounded_rect(draw, 
                      [imac_x - 2, imac_y - 2, imac_x + imac_width + 2, imac_y + imac_height + chin_height + 2],
                      bezel_radius, (220, 220, 225, 255))
    
    # Main iMac body
    draw_rounded_rect(draw, 
                      [imac_x, imac_y, imac_x + imac_width, imac_y + imac_height + chin_height],
                      bezel_radius, imac_body)
    
    # Screen area (pink gradient)
    screen_x1 = imac_x + bezel
    screen_y1 = imac_y + bezel
    screen_x2 = imac_x + imac_width - bezel
    screen_y2 = imac_y + imac_height - bezel
    
    # Create screen gradient
    screen_height = screen_y2 - screen_y1
    screen_width = screen_x2 - screen_x1
    
    for i in range(int(screen_height)):
        ratio = i / screen_height
        r = int(screen_color1[0] + (screen_color2[0] - screen_color1[0]) * ratio)
        g = int(screen_color1[1] + (screen_color2[1] - screen_color1[1]) * ratio)
        b = int(screen_color1[2] + (screen_color2[2] - screen_color1[2]) * ratio)
        draw.line([(screen_x1, screen_y1 + i), (screen_x2, screen_y1 + i)], fill=(r, g, b, 255))
    
    # Screen shine/reflection (top-left lighter area)
    shine_size = int(size * 0.15)
    for i in range(shine_size):
        alpha = int(40 * (1 - i / shine_size))
        draw.line([(screen_x1 + i, screen_y1), (screen_x1, screen_y1 + i)], 
                  fill=(255, 255, 255, alpha))
    
    # Chin area (bottom bezel with logo dot)
    chin_y = imac_y + imac_height
    
    # Apple logo placeholder (small circle)
    logo_size = int(size * 0.02)
    logo_x = imac_x + imac_width // 2
    logo_y = chin_y + chin_height // 2
    draw.ellipse([logo_x - logo_size, logo_y - logo_size, 
                  logo_x + logo_size, logo_y + logo_size], 
                 fill=(150, 150, 155, 255))
    
    # === Draw Stand ===
    stand_width = int(size * 0.12)
    stand_height = int(size * 0.08)
    stand_x = (size - stand_width) // 2
    stand_y = imac_y + imac_height + chin_height
    
    # Stand neck
    neck_width = int(size * 0.06)
    neck_height = int(size * 0.04)
    neck_x = (size - neck_width) // 2
    draw.polygon([
        (neck_x, stand_y),
        (neck_x + neck_width, stand_y),
        (stand_x + stand_width - int(size * 0.01), stand_y + neck_height + stand_height),
        (stand_x + int(size * 0.01), stand_y + neck_height + stand_height)
    ], fill=imac_stand)
    
    # Stand base
    base_y = stand_y + neck_height + stand_height - int(size * 0.015)
    draw.ellipse([stand_x - int(size * 0.02), base_y,
                  stand_x + stand_width + int(size * 0.02), base_y + int(size * 0.03)],
                 fill=imac_stand)
    
    # === Draw Cleaning Wiper ===
    
    # Wiper positioned diagonally across screen
    wiper_length = int(size * 0.45)
    wiper_width = int(size * 0.025)
    handle_length = int(size * 0.18)
    
    # Wiper angle (tilted)
    angle = -35  # degrees
    
    # Wiper center point (on the screen)
    cx = imac_x + imac_width * 0.65
    cy = imac_y + imac_height * 0.35
    
    # Calculate wiper endpoints
    rad = angle * pi / 180
    
    # Handle
    hx1 = cx - cos(rad) * wiper_length * 0.3
    hy1 = cy - sin(rad) * wiper_length * 0.3
    hx2 = cx + cos(rad) * handle_length
    hy2 = cy + sin(rad) * handle_length
    
    # Draw handle (thick line)
    handle_width = int(size * 0.035)
    
    # Handle shadow
    draw.line([(hx1 + 3, hy1 + 3), (hx2 + 3, hy2 + 3)], 
              fill=(0, 0, 0, 60), width=handle_width + 2)
    
    # Main handle
    draw.line([(hx1, hy1), (hx2, hy2)], fill=wiper_handle, width=handle_width)
    
    # Handle highlight
    draw.line([(hx1 - 1, hy1 - 1), (hx2 - 1, hy2 - 1)], 
              fill=(90, 90, 100, 255), width=max(2, int(handle_width * 0.3)))
    
    # Handle grip (rounded end)
    grip_size = int(size * 0.025)
    draw.ellipse([hx2 - grip_size, hy2 - grip_size, hx2 + grip_size, hy2 + grip_size],
                 fill=wiper_handle)
    
    # Wiper blade (the cleaning part)
    blade_x1 = cx - cos(rad) * wiper_length * 0.35
    blade_y1 = cy - sin(rad) * wiper_length * 0.35
    blade_x2 = cx + cos(rad) * wiper_length * 0.15
    blade_y2 = cy + sin(rad) * wiper_length * 0.15
    
    # Perpendicular direction for blade width
    perp_rad = rad + pi / 2
    blade_half_width = int(size * 0.04)
    
    # Blade polygon (rectangle at angle)
    blade_points = [
        (blade_x1 + cos(perp_rad) * blade_half_width, blade_y1 + sin(perp_rad) * blade_half_width),
        (blade_x1 - cos(perp_rad) * blade_half_width, blade_y1 - sin(perp_rad) * blade_half_width),
        (blade_x2 - cos(perp_rad) * blade_half_width, blade_y2 - sin(perp_rad) * blade_half_width),
        (blade_x2 + cos(perp_rad) * blade_half_width, blade_y2 + sin(perp_rad) * blade_half_width),
    ]
    
    # Blade shadow
    shadow_offset = 3
    shadow_points = [(p[0] + shadow_offset, p[1] + shadow_offset) for p in blade_points]
    draw.polygon(shadow_points, fill=(0, 0, 0, 50))
    
    # Main blade
    draw.polygon(blade_points, fill=wiper_blade)
    
    # Blade edge (rubber part)
    edge_points = [
        (blade_x1 - cos(perp_rad) * blade_half_width * 0.7, blade_y1 - sin(perp_rad) * blade_half_width * 0.7),
        (blade_x1 - cos(perp_rad) * blade_half_width, blade_y1 - sin(perp_rad) * blade_half_width),
        (blade_x2 - cos(perp_rad) * blade_half_width, blade_y2 - sin(perp_rad) * blade_half_width),
        (blade_x2 - cos(perp_rad) * blade_half_width * 0.7, blade_y2 - sin(perp_rad) * blade_half_width * 0.7),
    ]
    draw.polygon(edge_points, fill=(70, 70, 80, 255))
    
    # === Add Sparkles ===
    sparkle_positions = [
        (imac_x + imac_width * 0.2, imac_y + imac_height * 0.25, 0.035),
        (imac_x + imac_width * 0.15, imac_y + imac_height * 0.55, 0.025),
        (imac_x + imac_width * 0.35, imac_y + imac_height * 0.15, 0.02),
    ]
    
    for sx, sy, sparkle_ratio in sparkle_positions:
        sparkle_size = int(size * sparkle_ratio)
        # Draw 4-pointed star sparkle
        draw.polygon([
            (sx, sy - sparkle_size),
            (sx + sparkle_size * 0.3, sy),
            (sx, sy + sparkle_size),
            (sx - sparkle_size * 0.3, sy),
        ], fill=(255, 255, 255, 220))
        draw.polygon([
            (sx - sparkle_size, sy),
            (sx, sy - sparkle_size * 0.3),
            (sx + sparkle_size, sy),
            (sx, sy + sparkle_size * 0.3),
        ], fill=(255, 255, 255, 220))
        # Center dot
        dot_size = max(1, int(sparkle_size * 0.3))
        draw.ellipse([sx - dot_size, sy - dot_size, sx + dot_size, sy + dot_size],
                     fill=(255, 255, 255, 255))
    
    # === Clean streak effect (where wiper cleaned) ===
    # Lighter area on the left side of screen showing "clean" area
    clean_mask = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    clean_draw = ImageDraw.Draw(clean_mask)
    
    # Triangle area that's been "cleaned"
    clean_draw.polygon([
        (screen_x1, screen_y1),
        (screen_x1 + int(screen_width * 0.4), screen_y1),
        (screen_x1, screen_y1 + int(screen_height * 0.7)),
    ], fill=(255, 255, 255, 25))
    
    result = Image.alpha_composite(result, clean_mask)
    
    return result


def main():
    """Generate all icon sizes and create iconset"""
    
    # Icon sizes needed for macOS (size, scale)
    sizes = [
        (16, 1), (16, 2),
        (32, 1), (32, 2),
        (128, 1), (128, 2),
        (256, 1), (256, 2),
        (512, 1), (512, 2),
    ]
    
    # Create iconset directory
    iconset_path = "MacClean/Assets.xcassets/AppIcon.appiconset"
    os.makedirs(iconset_path, exist_ok=True)
    
    # Generate master icon at highest resolution
    print("Generating master icon at 1024x1024...")
    master = create_icon(1024)
    master.save(os.path.join(iconset_path, "icon_512x512@2x.png"))
    
    # Generate all sizes
    contents_images = []
    
    for base_size, scale in sizes:
        actual_size = base_size * scale
        filename = f"icon_{base_size}x{base_size}"
        if scale > 1:
            filename += f"@{scale}x"
        filename += ".png"
        
        print(f"Generating {filename} ({actual_size}x{actual_size})...")
        
        # Resize from master for best quality
        icon = master.resize((actual_size, actual_size), Image.LANCZOS)
        icon.save(os.path.join(iconset_path, filename))
        
        contents_images.append({
            "filename": filename,
            "idiom": "mac",
            "scale": f"{scale}x",
            "size": f"{base_size}x{base_size}"
        })
    
    # Update Contents.json
    import json
    contents = {
        "images": contents_images,
        "info": {
            "author": "xcode",
            "version": 1
        }
    }
    
    with open(os.path.join(iconset_path, "Contents.json"), 'w') as f:
        json.dump(contents, f, indent=2)
    
    print("\n✅ Icon generation complete!")
    print(f"Icons saved to: {iconset_path}")
    
    # Also save a preview
    preview_path = "icon_preview.png"
    master.save(preview_path)
    print(f"Preview saved to: {preview_path}")


if __name__ == "__main__":
    main()

