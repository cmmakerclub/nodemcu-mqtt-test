-- original version is https://primalcortex.wordpress.com/2015/02/06/nodemcu-and-mqtt-how-to-start/
myFn = function(mac, ip, dht22)
  -- Configuration to connect to the MQTT broker.
  BROKER = "192.168.1.1"   -- Ip/hostname of MQTT broker
  BRPORT = 1883             -- MQTT broker port
  BRUSER = ""           -- If MQTT authenitcation is used then define the user
  BRPWD  = ""            -- The above user password
  CLIENTID = "ESP8266-" ..  node.chipid() -- The MQTT ID. Change to something you like
  
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
       print("HEAP: " .. node.heap())  
       run_main_prog()
  end)
  
  m:on("offline", function(con) node.restart() end)

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
         sensor="DHT22" 
         -- type can be sensor or actuator
         type="sensor" 
         mcu="ESP8266"
         heap=node.heap()

         jstr_1 =           string.format("{ ");
         jstr_1 = jstr_1 .. string.format('"mac": %q, ', mac)
         jstr_1 = jstr_1 .. string.format('"ip": %q, ', ip)
         jstr_1 = jstr_1 .. string.format('"sensor": %q, ', sensor)
         jstr_1 = jstr_1 .. string.format('"mcu": %q, ', mcu)

         jstr_1 = jstr_1 .. string.format('"cnt": %q, ', l_cnt)
         jstr_1 = jstr_1 .. string.format('"collision": %q, ', lb_cnt)
         jstr_1 = jstr_1 .. string.format('"clientId": %q, ', CLIENTID)

         jstr_1 = jstr_1 .. string.format('"temp": %q, ', t)
         jstr_1 = jstr_1 .. string.format('"humid": %q, ', h)
         jstr_1 = jstr_1 .. string.format('"heap": %q ', heap)

         jstr_1 = jstr_1 .. string.format("}")

         print(jstr_1)

         m:publish("/nat/sensor/data", jstr_1, 0, 0, function(conn)
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
  end
end

return myFn
