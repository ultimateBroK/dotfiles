#!/usr/bin/env python3
import sys
import cv2
import numpy as np

# Allowed scheme types
SCHEMES = [
    "scheme-content",
    "scheme-expressive",
    "scheme-fidelity",
    "scheme-fruit-salad",
    "scheme-monochrome",
    "scheme-neutral",
    "scheme-rainbow",
    "scheme-tonal-spot",
    "scheme-vibrant"
]

def image_colorfulness(image):
    # Based on Hasler and Süsstrunk's colorfulness metric
    (B, G, R) = cv2.split(image.astype("float"))
    rg = np.absolute(R - G)
    yb = np.absolute(0.5 * (R + G) - B)
    std_rg = np.std(rg)
    std_yb = np.std(yb)
    mean_rg = np.mean(rg)
    mean_yb = np.mean(yb)
    colorfulness = np.sqrt(std_rg ** 2 + std_yb ** 2) + (0.3 * np.sqrt(mean_rg ** 2 + mean_yb ** 2))
    return colorfulness

def image_saturation(image):
    """Calculate average saturation of the image"""
    hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
    saturation = hsv[:, :, 1].astype("float")
    return np.mean(saturation)

def image_brightness(image):
    """Calculate average brightness of the image"""
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    return np.mean(gray.astype("float"))

def image_color_diversity(image):
    """Calculate how many distinct colors are in the image"""
    # Resize for performance
    small = cv2.resize(image, (100, 100))
    # Convert to RGB and flatten
    rgb = cv2.cvtColor(small, cv2.COLOR_BGR2RGB)
    pixels = rgb.reshape(-1, 3)
    # Quantize colors to reduce noise
    quantized = (pixels // 32) * 32
    # Count unique colors
    unique_colors = len(set(map(tuple, quantized)))
    return unique_colors

def is_mostly_monochrome(image):
    """Check if image is mostly grayscale"""
    hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
    saturation = hsv[:, :, 1]
    # If average saturation is very low, it's mostly monochrome
    return np.mean(saturation) < 30

def has_many_colors(image):
    """Check if image has many distinct colors"""
    diversity = image_color_diversity(image)
    return diversity > 50

def pick_scheme(image):
    """
    Intelligently select the best color scheme based on image analysis.
    Uses multiple metrics to make a better decision.
    """
    colorfulness = image_colorfulness(image)
    saturation = image_saturation(image)
    brightness = image_brightness(image)
    diversity = image_color_diversity(image)
    monochrome = is_mostly_monochrome(image)
    many_colors = has_many_colors(image)
    
    # Monochrome images
    if monochrome:
        if brightness < 80:
            return "scheme-monochrome"
        else:
            return "scheme-neutral"
    
    # Very colorful images with many distinct colors
    if many_colors and colorfulness > 60:
        if saturation > 100:
            return "scheme-rainbow"
        elif colorfulness > 80:
            return "scheme-fruit-salad"
        else:
            return "scheme-expressive"
    
    # Moderately colorful images
    if colorfulness > 50:
        if saturation > 120:
            return "scheme-vibrant"
        elif diversity > 40:
            return "scheme-tonal-spot"
        else:
            return "scheme-expressive"
    
    # Less colorful but still has some color
    if colorfulness > 30:
        if saturation > 80:
            return "scheme-fidelity"
        else:
            return "scheme-content"
    
    # Low colorfulness - preserve what color exists
    if colorfulness > 20:
        return "scheme-content"
    
    # Very low colorfulness
    if brightness > 127:
        return "scheme-neutral"
    else:
        return "scheme-tonal-spot"

def main():
    colorfulness_mode = False
    args = sys.argv[1:]
    if '--colorfulness' in args:
        colorfulness_mode = True
        args.remove('--colorfulness')
    if len(args) < 1:
        print("scheme-tonal-spot")
        sys.exit(1)
    img_path = args[0]
    img = cv2.imread(img_path)
    if img is None:
        print("scheme-tonal-spot")
        sys.exit(1)
    
    if colorfulness_mode:
        colorfulness = image_colorfulness(img)
        print(f"{colorfulness}")
    else:
        scheme = pick_scheme(img)
        # Validate the scheme is in our allowed list
        if scheme not in SCHEMES:
            scheme = "scheme-tonal-spot"
        print(scheme)

if __name__ == "__main__":
    main()
