myFn = function(mac, ip)
    --print("MAC ADDRESS: " .. mac .. ip)
    -- init mqtt client with keepalive timer 120sec
    m = mqtt.Client("clientid", 120, "", "");

    -- setup Last Will and Testament (optional)
    -- Broker will publish a message with qos = 0, retain = 0, data = "offline" 
    -- to topic "/lwt" if client don't send keepalive packet
    m:lwt("/lwt", "offline", 0, 0);

    local create_callback = function(text)
      local f =  function() if text=="offline" then node.restart(); end; print(text) end;
	  return f
    end

    m:on("connect", function(conn)
      print("connected")
      local str = "MAC: " .. mac .. " IP: " .. ip
      local publish_callback = function()
        print(str .. " SENT!");
        m:subscribe({["/cmmc/nat/iot/"..mac]=0,["/cmmc/nat/iot/central"]=0}, function(conn) 
          print("subscribe success")
        end) 
      end

      m:publish("/cmmc/nat/iot/boss", str, 0, 0, publish_callback)
    end) -- connected
	
    m:on("offline", create_callback("offline"))

    -- on publish message receive event
    m:on("message", function(conn, topic, data) 
      print(topic .. ":" ) 
      if data ~= nil then
        pin = 4
        gpio.mode(pin, gpio.OUTPUT)
        if topic == "/cmmc/nat/iot/"..mac then
          print("PRIVATE: " .. data)
          if data == "off" then
            print("SHOUT DOWN")
            gpio.write(pin, gpio.LOW)
          else 
            gpio.write(pin, gpio.HIGH)
            print("UP UP")
          end
          print(gpio.read(pin))
        else 

        end

        print(data)
      end
    end)

    m:connect("iot.eclipse.org", 1883, 0);

    -- subscribe topic with qos = 0
    --m:subscribe("/topic",0, function(conn) print("subscribe success") end)
    -- or subscribe multiple topic (topic/0, qos = 0; topic/1, qos = 1; topic2 , qos = 2)
    -- m:subscribe({["topic/0"]=0,["topic/1"]=1,topic2=2}, function(conn) print("subscribe success") end)
    -- publish a message with data = hello, QoS = 0, retain = 0

	m:close();
end

return myFn