from PIL import Image
import os

def convert_png_to_ico(png_path, ico_path):
    try:
        img = Image.open(png_path)
        img.save(ico_path, format='ICO', sizes=[(256, 256)])
        print(f"Successfully converted {png_path} to {ico_path}")
    except Exception as e:
        print(f"Error converting image: {e}")

if __name__ == "__main__":
    png_file = r"d:\web app\I-buzz bd mangement\assets\images\logo.png"
    ico_file = r"d:\web app\I-buzz bd mangement\windows\runner\resources\app_icon.ico"
    convert_png_to_ico(png_file, ico_file)
