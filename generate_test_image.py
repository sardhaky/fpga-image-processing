from PIL import Image, ImageDraw

img = Image.new("RGB", (256, 256), color=(255, 255, 255))
draw = ImageDraw.Draw(img)

draw.rectangle([40, 40, 140, 140], outline=(0,0,0), width=3)
draw.ellipse([110, 110, 220, 220], outline=(0,0,0), width=3)
draw.line([0, 0, 255, 255], fill=(0,0,0), width=4)
draw.polygon([(128,10),(220,200),(36,200)], outline=(0,0,0), width=3)

img.save("test_image.png")
print("Generated test_image.png")