from ffmpy import FFmpeg

def run_ffmpeg():
    ff = FFmpeg(
        inputs = { "/audio/sample.mp3": None },
        outputs= { "/audio/sample.wav": None }
    )

    ff.run()
