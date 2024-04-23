import csv
import sys
from scipy.io import wavfile

FILENAME = sys.argv[1]
OUTNAME = sys.argv[2]

samplerate, channel = wavfile.read(FILENAME)

# only take one channel
with open(OUTNAME, 'w', newline='', encoding='utf-8') as f:
    writer = csv.writer(f)
    writer.writerow(["samples"])
    print(channel.size)
    for row in channel:        
        writer.writerow([row])