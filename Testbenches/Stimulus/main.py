import numpy as np

def sample_1_khz_sine():
    frequency = 1000
    sample_rate = 44100

    duration = 1

    num_samples = int(sample_rate * duration)

    t = np.linspace(0, duration, num_samples, endpoint=False)

    sine_wave = np.sin(2 * np.pi * frequency * t)

    sine_wave_24bit = np.int64(sine_wave * ((2 << 23) - 1))

    with open('samples.txt', 'w') as f:
        for sample in sine_wave_24bit:
            sample = sample & 0xFFFFFF  # Mask to 24-bit
            sample_32bit = (sample << 8) & 0xFFFFFFFF  
            binary_str = format(sample_32bit, '032b')  # Convert to 32-bit binary string
            f.write(f'{binary_str}\n')


if __name__ == "__main__":
    sample_1_khz_sine()