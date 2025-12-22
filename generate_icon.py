#!/usr/bin/env python3
"""
Generate MacCoolClean app icons - Cute 3D robot style matching reference
"""

from PIL import Image, ImageDraw, ImageFilter
import os
import math

def draw_rounded_rect(draw, bounds, radius, fill):
    """Draw a rounded rectangle with proper corners"""
    x1, y1, x2, y2 = bounds
    draw.rounded_rectangle(bounds, radius=radius, fill=fill)

def create_robot_icon(size):
    """Create a cute 3D robot icon matching the reference image"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    s = size / 512  # Scale factor
    cx, cy = size // 2, size // 2
    
    # === BACKGROUND - Soft blue gradient ===
    for y in range(size):
        ratio = y / size
        r = int(120 + ratio * 30)   # ~120 -> 150
        g = int(160 + ratio * 30)   # ~160 -> 190
        b = int(220 + ratio * 15)   # ~220 -> 235
        draw.line([(0, y), (size, y)], fill=(r, g, b, 255))
    
    # === FLOOR REFLECTION (subtle) ===
    floor_y = int(420 * s)
    for y in range(floor_y, size):
        ratio = (y - floor_y) / (size - floor_y)
        alpha = int(30 * (1 - ratio))
        draw.line([(0, y), (size, y)], fill=(100, 140, 180, alpha))
    
    # === SHADOW under robot ===
    shadow_y = int(400 * s)
    shadow_width = int(200 * s)
    shadow_height = int(30 * s)
    for i in range(int(40 * s), 0, -1):
        alpha = int(25 * (1 - i / (40 * s)))
        draw.ellipse([
            cx - shadow_width//2 - i, shadow_y - shadow_height//2 + i//2,
            cx + shadow_width//2 + i, shadow_y + shadow_height//2 + i//2
        ], fill=(50, 80, 120, alpha))
    
    # === SIDE EARS (left and right) ===
    ear_width = int(35 * s)
    ear_height = int(50 * s)
    ear_y = int(180 * s)
    body_left = int(100 * s)
    body_right = int(412 * s)
    
    # Left ear - with 3D shading
    left_ear_x = body_left - ear_width + int(10 * s)
    # Darker back
    draw.rounded_rectangle(
        [left_ear_x, ear_y, left_ear_x + ear_width, ear_y + ear_height],
        radius=int(15 * s),
        fill=(180, 185, 195, 255)
    )
    # Lighter front
    draw.rounded_rectangle(
        [left_ear_x + 5*s, ear_y + 5*s, left_ear_x + ear_width - 2*s, ear_y + ear_height - 5*s],
        radius=int(12 * s),
        fill=(210, 215, 225, 255)
    )
    
    # Right ear
    right_ear_x = body_right - int(10 * s)
    draw.rounded_rectangle(
        [right_ear_x, ear_y, right_ear_x + ear_width, ear_y + ear_height],
        radius=int(15 * s),
        fill=(180, 185, 195, 255)
    )
    draw.rounded_rectangle(
        [right_ear_x + 2*s, ear_y + 5*s, right_ear_x + ear_width - 5*s, ear_y + ear_height - 5*s],
        radius=int(12 * s),
        fill=(210, 215, 225, 255)
    )
    
    # === MAIN BODY (rounded squircle) ===
    body_top = int(80 * s)
    body_bottom = int(380 * s)
    body_radius = int(70 * s)
    
    # Body shadow (3D effect)
    for i in range(int(15*s), 0, -1):
        alpha = int(20 * (1 - i/(15*s)))
        draw.rounded_rectangle(
            [body_left + i, body_top + i, body_right + i, body_bottom + i],
            radius=body_radius,
            fill=(100, 120, 150, alpha)
        )
    
    # Main body gradient (light gray/white)
    # Draw base
    draw.rounded_rectangle(
        [body_left, body_top, body_right, body_bottom],
        radius=body_radius,
        fill=(235, 238, 245, 255)
    )
    
    # Add gradient overlay (lighter at top)
    for i in range(int(body_top), int(body_bottom)):
        ratio = (i - body_top) / (body_bottom - body_top)
        # Lighter at top, slightly darker at bottom
        brightness = int(250 - ratio * 25)
        alpha = int(180 - ratio * 100)
        draw.line(
            [body_left + body_radius//2, i, body_right - body_radius//2, i],
            fill=(brightness, brightness, brightness + 5, alpha)
        )
    
    # Redraw outline for clean edges
    draw.rounded_rectangle(
        [body_left, body_top, body_right, body_bottom],
        radius=body_radius,
        outline=(200, 205, 215, 255),
        width=int(2 * s)
    )
    
    # === SCREEN (dark rounded rectangle) ===
    screen_margin_x = int(35 * s)
    screen_margin_top = int(40 * s)
    screen_left = body_left + screen_margin_x
    screen_right = body_right - screen_margin_x
    screen_top = body_top + screen_margin_top
    screen_bottom = int(290 * s)
    screen_radius = int(45 * s)
    
    # Screen with gradient (dark with slight blue tint)
    draw.rounded_rectangle(
        [screen_left, screen_top, screen_right, screen_bottom],
        radius=screen_radius,
        fill=(30, 35, 50, 255)
    )
    
    # Screen inner gradient (subtle glossy effect)
    for i in range(int(screen_top + 10*s), int(screen_bottom - 10*s)):
        ratio = (i - screen_top) / (screen_bottom - screen_top)
        # Keep it dark with subtle gradient
        gray = int(30 + ratio * 15)
        draw.line(
            [screen_left + 10*s, i, screen_right - 10*s, i],
            fill=(gray, gray + 3, gray + 8, 255)
        )
    
    # Screen outline
    draw.rounded_rectangle(
        [screen_left, screen_top, screen_right, screen_bottom],
        radius=screen_radius,
        outline=(50, 55, 70, 255),
        width=int(3 * s)
    )
    
    # === HAPPY EYES (curved arcs) ===
    eye_y = int(185 * s)
    eye_spacing = int(65 * s)
    eye_width = int(45 * s)
    eye_height = int(25 * s)
    line_width = int(6 * s)
    
    # Left eye - happy curved line
    left_eye_cx = cx - eye_spacing
    draw.arc(
        [left_eye_cx - eye_width//2, eye_y - eye_height//2,
         left_eye_cx + eye_width//2, eye_y + eye_height//2],
        start=200, end=340,
        fill=(255, 255, 255, 255),
        width=line_width
    )
    
    # Right eye
    right_eye_cx = cx + eye_spacing
    draw.arc(
        [right_eye_cx - eye_width//2, eye_y - eye_height//2,
         right_eye_cx + eye_width//2, eye_y + eye_height//2],
        start=200, end=340,
        fill=(255, 255, 255, 255),
        width=line_width
    )
    
    # === SMILE (green curved line) ===
    smile_y = int(245 * s)
    smile_width = int(80 * s)
    smile_height = int(40 * s)
    
    draw.arc(
        [cx - smile_width//2, smile_y - smile_height//2,
         cx + smile_width//2, smile_y + smile_height//2],
        start=15, end=165,
        fill=(160, 230, 180, 255),  # Soft green
        width=int(6 * s)
    )
    
    # === FRONT BUTTON/INDICATOR ===
    button_y = int(340 * s)
    button_radius = int(8 * s)
    
    # Button shadow
    draw.ellipse(
        [cx - button_radius - 2*s, button_y - button_radius + 2*s,
         cx + button_radius + 2*s, button_y + button_radius + 4*s],
        fill=(180, 185, 195, 255)
    )
    # Button
    draw.ellipse(
        [cx - button_radius, button_y - button_radius,
         cx + button_radius, button_y + button_radius],
        fill=(140, 150, 170, 255)
    )
    # Button highlight
    draw.ellipse(
        [cx - button_radius//2, button_y - button_radius//2,
         cx + button_radius//3, button_y + button_radius//3],
        fill=(170, 180, 200, 200)
    )
    
    # === TOP HIGHLIGHT (3D shine) ===
    highlight_y = body_top + int(15 * s)
    highlight_width = int(180 * s)
    for i in range(int(25 * s)):
        alpha = int(80 * (1 - i / (25 * s)))
        draw.line(
            [cx - highlight_width//2 + i, highlight_y + i,
             cx + highlight_width//2 - i, highlight_y + i],
            fill=(255, 255, 255, alpha)
        )
    
    return img


def main():
    sizes = [16, 32, 64, 128, 256, 512, 1024]
    
    output_dir = "MacCoolClean/Assets.xcassets/AppIcon.appiconset"
    os.makedirs(output_dir, exist_ok=True)
    
    print("🤖 Generating cute robot icons...")
    
    for size in sizes:
        print(f"  Creating {size}x{size}...")
        icon = create_robot_icon(size)
        
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
    
    preview = create_robot_icon(512)
    preview.save("icon_preview.png")
    print("\n✅ Cute robot icons generated!")
    print("📁 Preview: icon_preview.png")


if __name__ == "__main__":
    main()
