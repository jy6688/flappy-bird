from PIL import Image

# === CONFIG ===
INPUT_FILE = "bird.png"     # <-- put your bird sprite here
OUTPUT_FILE = "bird.mem"
WIDTH = 24
HEIGHT = 24

def rgb_to_12bit(r,g,b):
    # convert 8-bit RGB → 4-bit per channel → 12-bit hex
    return f"{(r>>4):01X}{(g>>4):01X}{(b>>4):01X}"

# === LOAD + RESIZE ===
img = Image.open(INPUT_FILE).convert("RGBA")
img = img.resize((WIDTH,HEIGHT), Image.NEAREST)

mem_data = []

for y in range(HEIGHT):
    for x in range(WIDTH):
        r,g,b,a = img.getpixel((x,y))

        # transparent pixels = background (white or black as needed)
        if a < 50:
            mem_data.append("000")  # transparent → black
        else:
            mem_data.append(rgb_to_12bit(r,g,b))

# === WRITE FILE ===
with open(OUTPUT_FILE,"w") as f:
    for val in mem_data:
        f.write(val+"\n")

print(f"Done! Generated {OUTPUT_FILE} with {WIDTH*HEIGHT} entries.")
