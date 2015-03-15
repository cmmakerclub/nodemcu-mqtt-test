myFn = function(mac, ip, dht22)
  -- Configuration to connect to the MQTT broker.
  BROKER = "192.168.1.1"   -- Ip/hostname of MQTT broker
  BRPORT = 1883             -- MQTT broker port
  BRUSER = ""           -- If MQTT authenitcation is used then define the user
  BRPWD  = ""            -- The above user password
  CLIENTID = "ESP8266-" ..  node.chipid() -- The MQTT ID. Change to something you like

  -- MQTT topics to subscribe
  -- topics = {"topic1","topic2","topic3","topic4"} -- Add/remove topics to the array

  -- Control variables.
  pub_sem = 0         -- MQTT Publish semaphore. Stops the publishing whne the previous hasn't ended
  current_topic  = 1  -- variable for one currently being subscribed to
  topicsub_delay = 50 -- microseconds between subscription attempts, worked for me (local network) down to 5...YMMV
  lb_cnt = 0
  l_cnt = 0

  -- connect to the broker
  print "Connecting to MQTT broker. Please wait..."
  m = mqtt.Client( CLIENTID, 120, BRUSER, BRPWD)
  m:connect( BROKER , BRPORT, 0, function(conn)
       print("Connected to MQTT:" .. BROKER .. ":" .. BRPORT .." as " .. CLIENTID )
       -- mqtt_sub() --run the subscription function
       print("HEAP: " .. node.heap())  
       run_main_prog()
  end)

  m:on("offline", function(con) node.restart() end)

  -- function mqtt_sub()
  --      if table.getn(topics) < current_topic then
  --           -- if we have subscribed to all topics in the array, run the main prog
  --           run_main_prog()
  --      else
  --           --subscribe to the topic
  --           m:subscribe(topics[current_topic] , 0, function(conn)
  --                print("Subscribing topic: " .. topics[current_topic - 1] )
  --           end)
  --           current_topic = current_topic + 1  -- Goto next topic
  --           --set the timer to rerun the loop as long there is topics to subscribe
  --           tmr.alarm(5, topicsub_delay, 0, mqtt_sub )
  --      end
  -- end

  -- Sample publish functions:
  function publish_data1()
     print("DATA-1")
     if lb_cnt > 20 then
       node.restart()
     end
     if pub_sem == 0 then  -- Is the semaphore set=
       pub_sem = 1  -- Nop. Let's block it
       l_cnt = l_cnt + 1
       print("--HEAP: " .. node.heap())  
       t, h = read_dht()
       if t == 0 then 
          print("read data error: " .. t .. " " .. h)
          pub_sem = 0  -- Unblock the semaphore
       else
         jstr_1 = "{ \"mac\":\"".. mac .."\", \"ip\":\"" .. ip .. "\", \"type\": \"DHT22\", \"cnt\": ".. l_cnt .. ", \"collision\": " .. lb_cnt .. ", \"clientId\":\"" .. CLIENTID .. "\", \"temp\":".. t ..", \"humid\":" .. h .. ", \"heap\":" .. node.heap()   .. "}"
         m:publish("/nat/sensor/data/esp8266/"..node.chipid(), jstr_1, 0, 0, function(conn)
            -- Callback function. We've sent the data
            print("SENT! t: " .. t .. " h: " .. h)
            pub_sem = 0  -- Unblock the semaphore
            -- id1 = id1 +1 -- Let's increase our counter
           print("==HEAP: " .. node.heap())  
         end)
       end
     else
       print("DATA-1 -- IN LOCK ")
       lb_cnt = lb_cnt + 1
     end  
  end

  function read_dht()
    PIN = 4 --  data pin, GPIO2

    dht22.read(PIN)

    t = dht22.getTemperature()
    h = dht22.getHumidity()

    if h == nil or t == nil then
      print("NILL H: ")
      print(h)
      print(t)
      return 0, 0
    else
      return t, h
    end

  end


  --main program to run after the subscriptions are done
  function run_main_prog()
       print("Main program")
       print("HEAP: " .. node.heap())  
       
       tmr.alarm(2, 5000, 1, publish_data1 )
       -- tmr.alarm(3, 7000, 1, publish_who_am_i)
       -- Callback to receive the subscribed topic messages. 
       -- m:on("message", function(conn, topic, data)
       --    print(topic .. ":" )
       --    if (data ~= nil ) then
       --      print("HEAP: " .. node.heap())  
       --      print ( data )
       --    end
       --  end )
  end
end

return myFn