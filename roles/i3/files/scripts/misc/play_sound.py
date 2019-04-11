import pygame, time,  sys
from pathlib import Path
#Well, it needs to be rewritten in better way, it is just too slow, no real-time interaction, turned off for now

sys.exit(0)

home_directory=str(Path.home()) #this is potentially dangerous

file_directory= home_directory+"/.config/i3/sounds/" + sys.argv[1]


pygame.mixer.pre_init(44100, -16, 1, 512)
pygame.mixer.init()

pygame.init()

sound=pygame.mixer.Sound(file_directory)
pygame.mixer.Channel(0).play(sound)
print(sound.get_length())
time.sleep(sound.get_length()+0.2)

