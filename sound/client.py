import pyaudio
import socket
from threading import Thread
from time import sleep

frames = []

def udpStream():
    udp = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

    while True:
        if len(frames) > 0:
            udp.sendto(frames.pop(0), ("otherserveraddress", 6000))

    udp.close()

def record(stream, CHUNK):
    while True:
        try:
            frames.append(stream.read(CHUNK))
        except Exception as Err:
            print(Err)

def start_client():
    try:
        CHUNK = 1024
        FORMAT = pyaudio.paInt16
        CHANNELS = 2
        RATE = 44100

        p = pyaudio.PyAudio()

        stream = p.open(format = FORMAT,
                        channels = CHANNELS,
                        rate = RATE,
                        input = True,
                        frames_per_buffer = CHUNK,
                        )

        Tr = Thread(target = record, args = (stream, CHUNK,))
        Ts = Thread(target = udpStream)
        Tr.setDaemon(True)
        Ts.setDaemon(True)
        Tr.start()
        Ts.start()
        Tr.join()
        Ts.join()
    except Exception as Err:
        print(Err)
        sleep(0.5)
        start_client()

if __name__ == "__main__":
    start_client()
