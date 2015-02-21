node.compile("dht22.lua")
node.compile("mqtttest.lua")
node.compile("init.lua")

dht22 = require("dht22")


if true then  --change to if true
    print("set up wifi mode")
    wifi.setmode(wifi.STATION)
    --please config ssid and password according to settings of your wireless router.
    wifi.sta.config("OpenWrt_NAT_91_DEVICE","devicenetwork")
    wifi.sta.connect()
    cnt = 0
    tmr.alarm(1, 1000, 1, function() 
        if (wifi.sta.getip() == nil) and (cnt < 40) then 
            print("IP unavaiable, Waiting...")
            print(node.heap())  
            cnt = cnt + 1 
        else
            tmr.stop(1)
             if (cnt < 40) then 
              print(node.heap())  
              print("Config done, IP is "..wifi.sta.getip())
              print("Config done, MAC is "..wifi.sta.getmac())

              dofile("mqtttest.lc")(wifi.sta.getmac(), wifi.sta.getip(), dht22)
            else
              print("Wifi setup time more than 20s, Please verify wifi.sta.config() function. Then re-download the file.")
              node.restart()
            end
        end 
     end)
else
    print("\n")
    print("Please edit 'init.lua' first:")
    print("Step 1: Modify wifi.sta.config() function in line 5 according settings of your wireless router.")
    print("Step 2: Change the 'if false' statement in line 1 to 'if true'.")
end