mosquitto_sub -t nat -h 127.0.0.1 |  { read test; echo test=$test; iw dev wlan0 station dump | mosquitto_pub -t "nat2" -l  -h 127.0.0.1; }