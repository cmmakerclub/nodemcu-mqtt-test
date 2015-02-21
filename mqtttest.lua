myFn = function(mac, ip)
  readDhtFn = dofile("read_dht.lua")

  -- Configuration to connect to the MQTT broker.
  BROKER = "192.168.1.1"   -- Ip/hostname of MQTT broker
  BRPORT = 1883             -- MQTT broker port
  BRUSER = ""           -- If MQTT authenitcation is used then define the user
  BRPWD  = ""            -- The above user password
  CLIENTID = "ESP8266-" ..  node.chipid() -- The MQTT ID. Change to something you like

  -- MQTT topics to subscribe
  topics = {"topic1","topic2","topic3","topic4"} -- Add/remove topics to the array

  -- Control variables.
  pub_sem = 0         -- MQTT Publish semaphore. Stops the publishing whne the previous hasn't ended
  current_topic  = 1  -- variable for one currently being subscribed to
  topicsub_delay = 50 -- microseconds between subscription attempts, worked for me (local network) down to 5...YMMV
  id1 = 0

  -- connect to the broker
  print "Connecting to MQTT broker. Please wait..."
  m = mqtt.Client( CLIENTID, 120, BRUSER, BRPWD)
  m:connect( BROKER , BRPORT, 0, function(conn)
       print("Connected to MQTT:" .. BROKER .. ":" .. BRPORT .." as " .. CLIENTID )
       mqtt_sub() --run the subscription function
       -- run_main_prog()
  end)

  function mqtt_sub()
       if table.getn(topics) < current_topic then
            -- if we have subscribed to all topics in the array, run the main prog
            run_main_prog()
       else
            --subscribe to the topic
            m:subscribe(topics[current_topic] , 0, function(conn)
                 print("Subscribing topic: " .. topics[current_topic - 1] )
            end)
            current_topic = current_topic + 1  -- Goto next topic
            --set the timer to rerun the loop as long there is topics to subscribe
            tmr.alarm(5, topicsub_delay, 0, mqtt_sub )
       end
  end

  -- Sample publish functions:
  function publish_data1()
     if pub_sem == 0 then  -- Is the semaphore set=
       pub_sem = 1  -- Nop. Let's block it
       t, h = readDhtFn()
       print("temp: " .. t .. " humid .. " .. h)
       print(node.heap())  
       m:publish("temperature","hello",0,0, function(conn) 
          -- Callback function. We've sent the data
          print("Sending data1: " .. id1)
          pub_sem = 0  -- Unblock the semaphore
          id1 = id1 +1 -- Let's increase our counter
       end)
     end  
  end


  --main program to run after the subscriptions are done
  function run_main_prog()
       print("Main program")
       
       tmr.alarm(2, 5000, 1, publish_data1 )
       -- Callback to receive the subscribed topic messages. 
       m:on("message", function(conn, topic, data)
          print(topic .. ":" )
          if (data ~= nil ) then
            print ( data )
          end
        end )
  end
end

return myFn