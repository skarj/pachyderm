from gtts import gTTS
import os

def make_speech(file):
    with open(file) as f:
        text = f.read()

    tts = gTTS(text=text, lang='en')
    tts.save("/pfs/tts/{}.mp3".format(file.split('.txt')[0]))


for dirpath, dirs, files in os.walk("/pfs/tts"):
    for file in files:
        make_speech(os.path.join(dirpath, file))
