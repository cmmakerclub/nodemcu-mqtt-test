local myFn = function(mac, ip)
    -- init mqtt client with keepalive timer 120sec
    m = mqtt.Client("clientid", 120, "", "");
    -- setup Last Will and Testament (optional)
    -- Broker will publish a message with qos = 0, retain = 0, data = "offline" 
    -- to topic "/lwt" if client don't send keepalive packet
    m:lwt("/lwt", "offline", 0, 0);

    local create_callback = function(text)
      return function() print(text) end;
    end

    m:on("connect", function(conn)
      print("connected")
      local str = "MAC: " .. mac .. " IP: " .. ip
      local publish_callback = function()
        print(str .. " SENT!");
        m:subscribe({["topic/0"]=0,["/cmmc/nat/iot/central"]=0,["/cmmc/nat/iot/central/command"]=0}, function(conn)
          print("subscribe success")
        end) 
      end

      m:publish("/cmmc/nat/iot/boss", str, 0, 0, publish_callback)
    end) -- connect
  
    m:on("offline", create_callback("offline"))

    -- on publish message receive event
    m:on("message", function(conn, topic, data) 
      print(topic .. ":" ) 
      if data ~= nil then
        print(data)
        if topic == "/cmmc/nat/iot/central/command/"..mac then
            pin = 1
            gpio.mode(pin,gpio.OUTPUT)
          if data == "on" then
            gpio.write(pin, gpio.HIGH)
            print(gpio.read(pin))
          else 
            gpio.write(pin, gpio.LOW)
            print(gpio.read(pin))
          end

        end

      end
    end)

    m:connect("iot.eclipse.org", 1883, 0)
    m:close()

return myFn