from example_pkg import example

def lambda_handler(event:dict, _:dict):
    print(event)
    example.run_ffmpeg()
    return event
