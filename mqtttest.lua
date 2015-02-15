myFn = function(mac, ip)
    --print("MAC ADDRESS: " .. mac .. ip)
    -- init mqtt client with keepalive timer 120sec
    m = mqtt.Client("clientid", 120, "", "");

    -- setup Last Will and Testament (optional)
    -- Broker will publish a message with qos = 0, retain = 0, data = "offline" 
    -- to topic "/lwt" if client don't send keepalive packet
    m:lwt("/lwt", "offline", 0, 0);

    local create_callback = function(text)
      local f =  function() print(text) end;
	  return f
    end

    m:on("connect", function(conn)
      m:subscribe("/topic",0, function() 
		print("subscribed") 
		local str = "MAC: " .. mac .. " IP: " .. ip 
        m:publish("/topic/nat", str ,0,0, create_callback("sent"))
	  end)
    end)
	
    m:on("offline", create_callback("offline"))

    -- on publish message receive event
    m:on("message", function(conn, topic, data) 
      print(topic .. ":" ) 
      if data ~= nil then
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