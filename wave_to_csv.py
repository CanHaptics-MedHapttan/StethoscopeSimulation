import csv
import sys
from scipy.io import wavfile

#FILENAME = "C:\\Users\\naomi\\Documents\\GIT\\ETS\\CanHaptics\\Test\\tricuspid_valve.wav"
#OUTNAME = "C:\\Users\\naomi\\Documents\\GIT\\ETS\\CanHaptics\\Test\\sample.csv"
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