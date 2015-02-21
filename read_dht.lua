local f = function()
  node.compile("dht22.lua")
  local dht22 = require("dht22")
  PIN = 4 --  data pin, GPIO2

  dht22.read(PIN)

  t = dht22.getTemperature()
  h = dht22.getHumidity()

  if h == nil or t == nil then
    return 0, 0
  else
    return t, h
  end
end

return f