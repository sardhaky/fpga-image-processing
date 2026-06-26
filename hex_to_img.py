from PIL import Image

INPUT_HEX  = "sim/canny_output.hex"
OUTPUT_IMG = "canny_result.png"
IMG_W = 128
IMG_H = 128

with open(INPUT_HEX,"r") as f:
    values = [int(l.strip(),16) for l in f if l.strip()]

values = values[:IMG_W*IMG_H]
while len(values) < IMG_W*IMG_H:
    values.append(0)

img = Image.new("L",(IMG_W,IMG_H))
img.putdata(values)
img = img.resize((512,512),Image.NEAREST)
img.save(OUTPUT_IMG)
print(f"Saved {OUTPUT_IMG}")