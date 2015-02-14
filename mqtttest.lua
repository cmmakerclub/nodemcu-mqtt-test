local myFn = function(mac)
    print("MAC ADDRESS: " .. mac)
    -- init mqtt client with keepalive timer 120sec
    m = mqtt.Client("clientid", 120, "", "")

    -- setup Last Will and Testament (optional)
    -- Broker will publish a message with qos = 0, retain = 0, data = "offline" 
    -- to topic "/lwt" if client don't send keepalive packet
    m:lwt("/lwt", "offline", 0, 0)

    create_callback = function(text)
      return function() print(text) end;
    end

    m:on("connect", function()
        -- create_callback("connected")()
        print("CONNECTED")
        m:publish("/topic/nat", "MAC:"..mac.." IP"..ip.. "CONNECTED",0,0, create_callback("sent"))
    end)
    m:on("offline", create_callback("offline"))

    -- on publish message receive event
    m:on("message", function(conn, topic, data) 
      print(topic .. ":" ) 
      if data ~= nil then
        print(data)
      end
    end)

    -- for secure: m:connect("iot.eclipse.org", 1880, 1)
    connectedFn = function(conn) 
      print("connected")
      m:subscribe("/topic",0, create_callback("subscribed"))
    end

    m:connect("iot.eclipse.org", 1883, 0,  connectedFn)

    -- subscribe topic with qos = 0
    --m:subscribe("/topic",0, function(conn) print("subscribe success") end)
    -- or subscribe multiple topic (topic/0, qos = 0; topic/1, qos = 1; topic2 , qos = 2)
    -- m:subscribe({["topic/0"]=0,["topic/1"]=1,topic2=2}, function(conn) print("subscribe success") end)
    -- publish a message with data = hello, QoS = 0, retain = 0
    m:publish("/topic","hello",0,0, create_callback("sent"))

m:close();  
end

return myFn