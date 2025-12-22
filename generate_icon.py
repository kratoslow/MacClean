#!/usr/bin/env python3
"""
Generate MacCoolClean app icons - A cool Mac dude cleaning!
"""

from PIL import Image, ImageDraw, ImageFont
import os
import math

def create_cool_mac_icon(size):
    """Create a cool Mac character with sunglasses cleaning"""
    # Create image with gradient background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Scale factor
    s = size / 512
    
    # Background - cool gradient (deep blue to purple)
    for y in range(size):
        ratio = y / size
        r = int(25 + ratio * 15)  # 25 -> 40
        g = int(25 + ratio * 10)  # 25 -> 35
        b = int(60 + ratio * 40)  # 60 -> 100
        draw.line([(0, y), (size, y)], fill=(r, g, b, 255))
    
    # Add subtle radial glow behind character
    center_x, center_y = size // 2, int(size * 0.45)
    for radius in range(int(180 * s), 0, -2):
        alpha = int(30 * (1 - radius / (180 * s)))
        color = (100, 200, 255, alpha)
        draw.ellipse([
            center_x - radius, center_y - radius,
            center_x + radius, center_y + radius
        ], fill=color)
    
    # === THE COOL MAC DUDE ===
    
    # Mac body (rounded rectangle - like a classic Mac)
    mac_left = int(140 * s)
    mac_top = int(100 * s)
    mac_right = int(372 * s)
    mac_bottom = int(340 * s)
    mac_radius = int(30 * s)
    
    # Mac body shadow
    draw.rounded_rectangle(
        [mac_left + 8*s, mac_top + 8*s, mac_right + 8*s, mac_bottom + 8*s],
        radius=mac_radius,
        fill=(0, 0, 0, 80)
    )
    
    # Mac body gradient (silver/white)
    for i in range(int(mac_top), int(mac_bottom)):
        ratio = (i - mac_top) / (mac_bottom - mac_top)
        gray = int(220 - ratio * 40)  # Light gray gradient
        draw.line([(mac_left, i), (mac_right, i)], fill=(gray, gray, gray + 10, 255))
    
    # Redraw rounded corners
    draw.rounded_rectangle(
        [mac_left, mac_top, mac_right, mac_bottom],
        radius=mac_radius,
        outline=(180, 180, 190, 255),
        width=int(3 * s)
    )
    
    # Screen area (dark)
    screen_margin = int(20 * s)
    screen_left = mac_left + screen_margin
    screen_top = mac_top + screen_margin
    screen_right = mac_right - screen_margin
    screen_bottom = mac_bottom - int(60 * s)
    
    draw.rounded_rectangle(
        [screen_left, screen_top, screen_right, screen_bottom],
        radius=int(10 * s),
        fill=(30, 30, 40, 255)
    )
    
    # Screen gradient (slight blue tint)
    for i in range(int(screen_top), int(screen_bottom)):
        ratio = (i - screen_top) / (screen_bottom - screen_top)
        draw.line(
            [(screen_left + 5*s, i), (screen_right - 5*s, i)],
            fill=(25 + int(10*ratio), 35 + int(15*ratio), 55 + int(20*ratio), 40)
        )
    
    # === COOL SUNGLASSES (on the screen - it's the face!) ===
    glasses_y = int(screen_top + 60 * s)
    glasses_width = int(60 * s)
    glasses_height = int(35 * s)
    
    # Left lens
    left_lens_x = int(screen_left + 45 * s)
    draw.rounded_rectangle(
        [left_lens_x, glasses_y, left_lens_x + glasses_width, glasses_y + glasses_height],
        radius=int(8 * s),
        fill=(20, 20, 20, 255),
        outline=(60, 60, 60, 255),
        width=int(2 * s)
    )
    # Lens shine
    draw.arc(
        [left_lens_x + 5*s, glasses_y + 5*s, left_lens_x + 25*s, glasses_y + 20*s],
        start=200, end=340,
        fill=(255, 255, 255, 150),
        width=int(2 * s)
    )
    
    # Right lens
    right_lens_x = int(screen_right - 45 * s - glasses_width)
    draw.rounded_rectangle(
        [right_lens_x, glasses_y, right_lens_x + glasses_width, glasses_y + glasses_height],
        radius=int(8 * s),
        fill=(20, 20, 20, 255),
        outline=(60, 60, 60, 255),
        width=int(2 * s)
    )
    # Lens shine
    draw.arc(
        [right_lens_x + 5*s, glasses_y + 5*s, right_lens_x + 25*s, glasses_y + 20*s],
        start=200, end=340,
        fill=(255, 255, 255, 150),
        width=int(2 * s)
    )
    
    # Bridge between lenses
    bridge_y = glasses_y + glasses_height // 2
    draw.line(
        [left_lens_x + glasses_width, bridge_y, right_lens_x, bridge_y],
        fill=(60, 60, 60, 255),
        width=int(4 * s)
    )
    
    # === COOL SMILE ===
    smile_center_x = (screen_left + screen_right) // 2
    smile_y = int(glasses_y + 70 * s)
    smile_width = int(80 * s)
    
    draw.arc(
        [smile_center_x - smile_width//2, smile_y - 20*s, 
         smile_center_x + smile_width//2, smile_y + 30*s],
        start=10, end=170,
        fill=(100, 220, 100, 255),  # Cool green smile
        width=int(6 * s)
    )
    
    # === CLEANING ARM WITH MOP ===
    # Arm coming from right side of Mac
    arm_start_x = mac_right - int(20 * s)
    arm_start_y = int(mac_top + 100 * s)
    
    # Upper arm
    arm_color = (200, 200, 210, 255)
    draw.line(
        [arm_start_x, arm_start_y, arm_start_x + 80*s, arm_start_y + 60*s],
        fill=arm_color,
        width=int(20 * s)
    )
    
    # Hand/glove
    hand_x = int(arm_start_x + 75 * s)
    hand_y = int(arm_start_y + 55 * s)
    draw.ellipse(
        [hand_x - 15*s, hand_y - 15*s, hand_x + 15*s, hand_y + 15*s],
        fill=(255, 230, 100, 255),  # Yellow glove
        outline=(230, 200, 50, 255),
        width=int(2 * s)
    )
    
    # Mop/cleaning brush handle
    handle_end_x = int(hand_x + 60 * s)
    handle_end_y = int(hand_y + 100 * s)
    draw.line(
        [hand_x, hand_y, handle_end_x, handle_end_y],
        fill=(139, 90, 43, 255),  # Brown handle
        width=int(8 * s)
    )
    
    # Mop head (fluffy)
    mop_x = handle_end_x
    mop_y = handle_end_y
    mop_colors = [(100, 180, 255), (80, 160, 240), (120, 200, 255)]
    
    for i in range(12):
        angle = (i / 12) * math.pi + math.pi/2
        length = int(35 * s) + (i % 3) * int(8 * s)
        end_x = mop_x + math.cos(angle) * length
        end_y = mop_y + math.sin(angle) * length * 0.6
        color = mop_colors[i % 3]
        draw.line(
            [mop_x, mop_y, end_x, end_y],
            fill=color + (255,),
            width=int(6 * s)
        )
    
    # === SPARKLES ===
    sparkle_positions = [
        (90 * s, 150 * s),
        (420 * s, 100 * s),
        (450 * s, 300 * s),
        (70 * s, 350 * s),
        (200 * s, 420 * s),
        (380 * s, 430 * s),
    ]
    
    for sx, sy in sparkle_positions:
        sparkle_size = int(12 * s)
        # Four-point star
        draw.polygon([
            (sx, sy - sparkle_size),
            (sx + sparkle_size//4, sy),
            (sx, sy + sparkle_size),
            (sx - sparkle_size//4, sy)
        ], fill=(255, 255, 100, 255))
        draw.polygon([
            (sx - sparkle_size, sy),
            (sx, sy + sparkle_size//4),
            (sx + sparkle_size, sy),
            (sx, sy - sparkle_size//4)
        ], fill=(255, 255, 100, 255))
        # Center glow
        draw.ellipse(
            [sx - 4*s, sy - 4*s, sx + 4*s, sy + 4*s],
            fill=(255, 255, 255, 255)
        )
    
    # === BUBBLES ===
    bubble_positions = [
        (100 * s, 250 * s, 18 * s),
        (60 * s, 320 * s, 12 * s),
        (430 * s, 200 * s, 15 * s),
        (400 * s, 380 * s, 20 * s),
        (320 * s, 450 * s, 14 * s),
    ]
    
    for bx, by, br in bubble_positions:
        # Bubble
        draw.ellipse(
            [bx - br, by - br, bx + br, by + br],
            fill=(200, 230, 255, 60),
            outline=(255, 255, 255, 120),
            width=int(2 * s)
        )
        # Shine
        draw.arc(
            [bx - br*0.6, by - br*0.6, bx + br*0.2, by + br*0.2],
            start=200, end=320,
            fill=(255, 255, 255, 200),
            width=int(2 * s)
        )
    
    # === MAC STAND ===
    stand_top = mac_bottom
    stand_bottom = int(mac_bottom + 40 * s)
    stand_width = int(60 * s)
    center = size // 2
    
    # Neck
    draw.polygon([
        (center - 15*s, stand_top),
        (center + 15*s, stand_top),
        (center + 25*s, stand_bottom - 15*s),
        (center - 25*s, stand_bottom - 15*s),
    ], fill=(170, 170, 180, 255))
    
    # Base
    draw.ellipse(
        [center - stand_width, stand_bottom - 20*s, center + stand_width, stand_bottom + 10*s],
        fill=(160, 160, 170, 255),
        outline=(140, 140, 150, 255),
        width=int(2 * s)
    )
    
    # === TEXT "COOL" (optional small badge) ===
    # Small badge in corner
    badge_x = int(380 * s)
    badge_y = int(50 * s)
    badge_w = int(100 * s)
    badge_h = int(35 * s)
    
    draw.rounded_rectangle(
        [badge_x, badge_y, badge_x + badge_w, badge_y + badge_h],
        radius=int(12 * s),
        fill=(233, 69, 96, 255)  # Pink/red badge
    )
    
    # Try to add text if font available
    try:
        font_size = int(18 * s)
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size)
        draw.text(
            (badge_x + badge_w//2, badge_y + badge_h//2),
            "COOL",
            fill=(255, 255, 255, 255),
            font=font,
            anchor="mm"
        )
    except:
        pass  # Skip if font not available
    
    return img


def main():
    # Icon sizes needed for macOS
    sizes = [16, 32, 64, 128, 256, 512, 1024]
    
    output_dir = "MacCoolClean/Assets.xcassets/AppIcon.appiconset"
    os.makedirs(output_dir, exist_ok=True)
    
    print("🧊 Generating MacCoolClean icons...")
    
    # Generate each size
    for size in sizes:
        print(f"  Creating {size}x{size}...")
        icon = create_cool_mac_icon(size)
        
        # Save at 1x
        if size <= 512:
            icon.save(f"{output_dir}/icon_{size}x{size}.png")
        
        # For @2x versions
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
    
    # Update Contents.json
    contents = '''{
  "images" : [
    {
      "filename" : "icon_16x16.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_16x16@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_32x32@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_128x128.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_128x128@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_256x256@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "icon_512x512@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}'''
    
    with open(f"{output_dir}/Contents.json", "w") as f:
        f.write(contents)
    
    # Also save a preview
    preview = create_cool_mac_icon(512)
    preview.save("icon_preview.png")
    print("\n✅ Icons generated!")
    print("📁 Preview saved to: icon_preview.png")
    print("\n😎 Your cool Mac dude is ready to clean!")


if __name__ == "__main__":
    main()
