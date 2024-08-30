from PIL import Image
import numpy as np

memory = [[0 for _ in range(640)] for _ in range(480)]

def bresenham(x1, y1, x2, y2):
    dx = abs(x2 - x1)
    dy = abs(y2 - y1)
    sx = 1 if x1 < x2 else -1
    sy = 1 if y1 < y2 else -1
    err = dx - dy

    while True:
        memory[y1][x1] = 1  # Draw the pixel
        if x1 == x2 and y1 == y2:
            break
        e2 = 2 * err
        if e2 > -dy:
            err -= dy
            x1 += sx
        if e2 < dx:
            err += dx
            y1 += sy

def sample_1_khz_sine():
    frequency = 1000
    sample_rate = 44100
    duration = 1
    amplitude = 1

    t = np.arange(0, duration, 1/sample_rate)
    
    sine_wave = amplitude * np.sin(2 * np.pi * frequency * t)

    digital_signal = (sine_wave * ((2 ** 23) - 1)).astype(np.int32)
    digital_signal = np.clip(digital_signal, (-2 ** 23), (2 ** 23) - 1)

    sample_diffs = []
    prev_sample = 0
    for sample in digital_signal:
        sample_diffs.append(sample - prev_sample)
        prev_sample = sample

    with open('samples.txt', 'w') as f:
        for sample in digital_signal:
            s = sample & 0xFFFFFF
            f.write(f"{format(s, '024b')}00000000\n") # Left Sample
            f.write(f"{format(s, '024b')}00000000\n") # Right Sample

    with open('samples_decimal.txt', 'w') as f:
        for sample in digital_signal:
            f.write(f"{str(sample)}\n")

def convert_smaples_to_memory():
    global memory
    i = 0
    prev_row = 0
    prev_i = 0
    wrote_memory = False
    with open('samples.txt', 'r') as f:
        for line in f:
            if (i == 639):
                if not wrote_memory:
                    write_memory()
                    wrote_memory = True
                draw_bitmap(memory, 640, 480)
                memory = [[0 for _ in range(640)] for _ in range(480)]
                i = 0

            sample = int(line.strip(), 2) >> 8
            if sample & (1 << 23):
                sample -= (1 << 24)
            
            row = 239 - ((239 * sample) >> 23)

            if (i > 0 and i < 639):
                bresenham(prev_i, prev_row, i, row)
            prev_row = row
            prev_i = i

            memory[row][i] = 1
        
            i += 1

def write_memory():
    with open('memory.txt', 'w') as f:
        for row in memory:
            f.write("".join(str(v) + ",\n" for v in row))

def draw_bitmap(bitmap, width, height, pixel_size=1):
    img_width = width
    img_height = height
    
    # Create a new image with a black background
    img = Image.new('RGB', (img_width, img_height), 'black')
    pixels = img.load()
    
    # Flatten the bitmap from 32-bit words to a single list of bits
    bit_array = []
    for row in bitmap:  # Use only the first 13824 words
        for col in row:
            bit_array.append(col)
    
    # Ensure the bit_array has the correct length
    expected_length = width * height
    if len(bit_array) != expected_length:
        raise ValueError(f"The bitmap data has {len(bit_array)} bits, but {expected_length} bits are required for {width}x{height} dimensions.")
    
    # Define the size of the line
    line_height = 1  # Number of pixels tall for the line
    line_radius = line_height // 2

    for row in range(height):
        for col in range(width):
            bit = bit_array[row * width + col]
            color = (255, 255, 0) if bit == 1 else (0, 0, 0)  # Yellow for 1, Black for 0
            if bit == 1:
                # Draw a vertical line centered on (col, row) that is 5 pixels tall
                center_x = col
                center_y = row
                for y in range(center_y - line_radius, center_y + line_radius + 1):
                    if 0 <= y < height:  # Check if within image boundaries
                        pixels[center_x, y] = color
    
    img.save('bitmap_image.png')  # Save the image to a file

if __name__ == "__main__":
    sample_1_khz_sine()
    convert_smaples_to_memory()