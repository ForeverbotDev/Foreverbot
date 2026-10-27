import subprocess
import os

os.makedirs("assets/sounds", exist_ok=True)

# 1. ding.mp3 - Four-tone level-up golden chime
subprocess.run([
    'ffmpeg', '-y',
    '-f', 'lavfi', '-i', 'sine=frequency=523.25:duration=0.12',
    '-f', 'lavfi', '-i', 'sine=frequency=659.25:duration=0.12',
    '-f', 'lavfi', '-i', 'sine=frequency=783.99:duration=0.12',
    '-f', 'lavfi', '-i', 'sine=frequency=1046.50:duration=0.75',
    '-filter_complex', '[0:a][1:a][2:a][3:a]concat=n=4:v=0:a=1,volume=1.5',
    'assets/sounds/ding.mp3'
], check=True)

# 2. aggro.mp3 - Intense double-pulse alert tone
subprocess.run([
    'ffmpeg', '-y',
    '-f', 'lavfi', '-i', 'sine=frequency=880:duration=0.15',
    '-f', 'lavfi', '-i', 'sine=frequency=0:duration=0.08',
    '-f', 'lavfi', '-i', 'sine=frequency=1174:duration=0.4',
    '-filter_complex', '[0:a][1:a][2:a]concat=n=3:v=0:a=1,volume=1.8',
    'assets/sounds/aggro.mp3'
], check=True)

# 3. murloc.mp3 - Vibrato / FM gargle warcry
subprocess.run([
    'ffmpeg', '-y',
    '-f', 'lavfi', '-i', 'sine=frequency=620:duration=1.2',
    '-af', 'tremolo=f=18:d=0.9,vibrato=f=12:d=0.8,flanger=speed=2:width=80,volume=2.0',
    'assets/sounds/murloc.mp3'
], check=True)

# 4. ragnaros.mp3 - Heavy low-frequency subterranean rumble + fiery burst
subprocess.run([
    'ffmpeg', '-y',
    '-f', 'lavfi', '-i', 'sine=frequency=95:duration=1.8',
    '-f', 'lavfi', '-i', 'anoisesrc=d=1.5:c=brown:r=44100:a=0.8',
    '-filter_complex', '[0:a][1:a]amix=inputs=2:duration=first,lowpass=f=450,volume=2.5',
    'assets/sounds/ragnaros.mp3'
], check=True)

# 5. leeroy.mp3 - Charging brass fanfare
subprocess.run([
    'ffmpeg', '-y',
    '-f', 'lavfi', '-i', 'sine=frequency=392:duration=0.2',
    '-f', 'lavfi', '-i', 'sine=frequency=523.25:duration=0.2',
    '-f', 'lavfi', '-i', 'sine=frequency=659.25:duration=0.2',
    '-f', 'lavfi', '-i', 'sine=frequency=783.99:duration=0.8',
    '-filter_complex', '[0:a][1:a][2:a][3:a]concat=n=4:v=0:a=1,volume=1.5',
    'assets/sounds/leeroy.mp3'
], check=True)

# 6. onyxia.mp3 - Ominous deep breath dragon rumble
subprocess.run([
    'ffmpeg', '-y',
    '-f', 'lavfi', '-i', 'anoisesrc=d=2.0:c=pink:r=44100:a=0.9',
    '-af', 'lowpass=f=280,tremolo=f=4:d=0.7,volume=2.0',
    'assets/sounds/onyxia.mp3'
], check=True)

print("Generated all 6 sound effects in assets/sounds/ successfully!")
