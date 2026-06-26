from PIL import Image

INPUT_IMAGE = "test_image.png"
OUTPUT_HEX  = "image_data.hex"
IMG_W       = 128
IMG_H       = 128

img = Image.open(INPUT_IMAGE).convert("RGB")
img = img.resize((IMG_W, IMG_H), Image.LANCZOS)
pixels = list(img.getdata())

with open(OUTPUT_HEX, "w") as f:
    for (r, g, b) in pixels:
        f.write(f"{r:02X}\n")
        f.write(f"{g:02X}\n")
        f.write(f"{b:02X}\n")

print(f"Done! {IMG_W}x{IMG_H} = {IMG_W*IMG_H} pixels")
print(f"Written to {OUTPUT_HEX} ({IMG_W*IMG_H*3} lines")