from PIL import Image

# Load original
orig = Image.open("Jeyram.png").resize((512,512), Image.NEAREST).convert("RGB")

# Load Harris output
with open("sim/harris_output.hex","r") as f:
    values = [int(l.strip(),16) for l in f if l.strip()]

IMG_W, IMG_H = 128, 128
values = values[:IMG_W*IMG_H]
while len(values) < IMG_W*IMG_H:
    values.append(0)

# Scale corner map to 512×512
corner_img = Image.new("L",(IMG_W,IMG_H))
corner_img.putdata(values)
corner_img = corner_img.resize((512,512), Image.NEAREST)

# Overlay red dots on original where corners detected
result = orig.copy()
pixels = result.load()
cmap   = corner_img.load()

for y in range(512):
    for x in range(512):
        if cmap[x,y] > 128:
            # Draw red 5×5 dot
            for dy in range(-3,4):
                for dx in range(-3,4):
                    nx,ny = x+dx, y+dy
                    if 0<=nx<512 and 0<=ny<512:
                        pixels[nx,ny] = (255,0,0)

result.save("harris_result.png")
print(f"Saved harris_result.png — {sum(1 for v in values if v>0)} corners marked")