import esp
from Wifi import Sta
import socket as soc
import camera
from time import sleep

esp.osdebug(None)

cam = camera.init()  # Camera
print("Camera ready?: ", cam)

# connect to access point
sta = Sta()              # Station mode (i.e., need WiFi router)
sta.wlan.disconnect()    # disconnec`t from the previous connection
AP = const('Autobonics_4G')  # Your SSID
PW = const('autobonics@27')  # Your password
#AP = const('JioFi3_4F2F1C')  # Your SSID
#PW = const('kp7rbxfwtm')  # Your password
sta.connect(AP, PW)  # connect to WiFi
sta.wait()

# wait for WiFi
con = ()
for i in range(5):
    if sta.wlan.isconnected():
        con = sta.status()
        break
    else:
        print("WIFI not ready. Wait...")
        sleep(2)
else:
    print("WIFI not ready")

if con and cam:  # WiFi and camera are ready
    if cam:
        # set preferred camera setting
        camera.framesize(10)  # frame size 800X600 (1.33 aspect ratio)
        camera.contrast(2)  # increase contrast

    if con:
        # TCP server
        port = 80
        addr = soc.getaddrinfo('0.0.0.0', port)[0][-1]
        s = soc.socket(soc.AF_INET, soc.SOCK_STREAM)
        s.setsockopt(soc.SOL_SOCKET, soc.SO_REUSEADDR, 1)
        s.bind(addr)
        s.listen(1)

        while True:
            cs, ca = s.accept()   # wait for client connect
            print('Request from:', ca)
            w = cs.recv(200)  # blocking

            # Check for the request path
            if b'GET /image' in w:
                # Send the image as response
                cs.sendall(b'HTTP/1.1 200 OK\r\nContent-Type: image/jpeg\r\n\r\n' + camera.capture())
                cs.close()
            else:
                # Invalid request, close the connection
                cs.close()

else:
    if not con:
        print("WiFi not connected.")
    if not cam:
        print("Camera not ready.")
    print("System not ready. Please restart")

print('System aborted')




