addEvent("Race.askConfirmation", true)
addEvent("Race.startWaiting", true)

addEvent("Race.updateWaitingTime", true)
addEvent("Race.updateLapTime", true)
addEvent("Race.updateLeftTime", true)

addEvent("Race.onLapRecord", true)
addEvent("Race.onFinishLap", true)
addEvent("Race.onStart", true)
addEvent("Race.onCancel", true)
addEvent("Race.onEnd", true)

addEvent("Race.onJoin", true)
addEvent("Race.onLeave", true)

local screenWidth, screenHeight = guiGetScreenSize()

Race = {}

Race.waiting = false
Race.started = false

Race.joined = false
Race.leftVehicle = false

Race.leftTime = 0
Race.lapTime = 0
Race.bestLapTime = 0

function Race.onConfirm(conirmed)
  toggleAllControls(true, true, false)
  triggerServerEvent("Race.onConfirm", resourceRoot, conirmed)
end

function Race.start(trackName, timeLeft)
  Race.waiting = false
  Race.started = true
  Race.trackName = trackName
  Race.timeLeft = timeLeft

  Waiting.setVisible(false)

  addEventHandler("onClientRender", root, Race.drawUI)
  addEventHandler("onClientPreRender", root, Race.update)
end

function Race.stop()
  Race.waiting = false
  Race.started = false
  Race.joined = false
  Race.trackName = false
  Race.lapTime = 0
  Race.bestLapTime = 0
  Race.timeLeft = nil
  Race.bestPlayerName = nil
  Race.bestPlayerTime = nil
  Race.leftVehicle = false
  Race.leftVehicleTime = nil

  toggleAllControls(true, true, false)
  Confirmation.setVisible(false)
  Waiting.setVisible(false)

  removeEventHandler("onClientRender", root, Race.drawUI)
  removeEventHandler("onClientPreRender", root, Race.update)
end

function Race.join()
  Race.joined = true
end

-- Update times
function Race.update(deltaTime)
  Race.lapTime = Race.lapTime + deltaTime

  if Race.timeLeft then
    Race.timeLeft = math.max(Race.timeLeft - deltaTime, 0)
  end

  -- Left vehicle
  if Race.leftVehicle then
    Race.leftVehicleTime = math.max(Race.leftVehicleTime - deltaTime, 0)
  end

  if not isDriver(localPlayer) then
    if not Race.leftVehicle then
      Race.leftVehicle = true
      Race.leftVehicleTime = RACE_LEFT_VEHICLE_TIME * 1000
    end
  else
    if Race.leftVehicle then
      Race.leftVehicle = false
      Race.leftVehicleTime = nil
    end
  end
end

function Race.drawUI()
  if Race.started then
    -- Time left
    if Race.timeLeft <= RACE_END_MESSAGE_TIME * 1000 then
      dxDrawText("До конца гонки", 44, 200, 256, 32, tocolor(255, 255, 255, 255), 1, Assets.fonts.text)

      time = ("%d:%02d.%03d"):format(Race.timeLeft / 1000 / 60, Race.timeLeft / 1000 % 60, Race.timeLeft % 1000)
      dxDrawText(time, 44, 225, 256, 32, tocolor(255, 255, 255, 255), 1, Assets.fonts.timeSmall)
    end

    dxDrawText(Race.trackName, 46, 262, 256, 32, tocolor(0, 0, 0, 128), 1, Assets.fonts.trackName)
    dxDrawText(Race.trackName, 44, 260, 256, 32, tocolor(255, 255, 255, 255), 1, Assets.fonts.trackName)

    -- Current lap
    local time = ("%d:%02d.%03d"):format(Race.lapTime / 1000 / 60, Race.lapTime / 1000 % 60, Race.lapTime % 1000)
    dxDrawText(time, 44, 290, 256, 32, tocolor(255, 255, 255, 255), 1, Assets.fonts.time)

    -- Best lap
    dxDrawText("Лучший круг", 44, 350, 256, 32, tocolor(255, 255, 255, 255), 1, Assets.fonts.text)

    time = ("%d:%02d.%03d"):format(Race.bestLapTime / 1000 / 60, Race.bestLapTime / 1000 % 60, Race.bestLapTime % 1000)
    dxDrawText(time, 44, 375, 256, 32, tocolor(255, 255, 255, 255), 1, Assets.fonts.timeSmall)

    -- Best player
    if Race.bestPlayerName then
      dxDrawText("Лучший игрок", 44, 410, 256, 32, tocolor(255, 255, 255, 255), 1, Assets.fonts.text)

      dxDrawText(removeHexFromString(Race.bestPlayerName), 44, 435, 256, 32, tocolor(255, 255, 255, 255), 1, Assets.fonts.timeSmall)

      time = ("%d:%02d.%03d"):format(Race.bestPlayerTime / 1000 / 60, Race.bestPlayerTime / 1000 % 60, Race.bestPlayerTime % 1000)
      dxDrawText(time, 44, 460, 256, 32, tocolor(255, 255, 255, 255), 1, Assets.fonts.timeSmall)
    end

    if Race.leftVehicle then
      dxDrawText("Вернитесь в машину",
        0, 64, screenWidth, screenHeight, tocolor(255, 255, 255, 255), 1, Assets.fonts.text,
        "center", "top", false, false, false, false, true)
      local time = ("%d:%02d.%03d"):format(Race.leftVehicleTime / 1000 / 60, Race.leftVehicleTime / 1000 % 60, Race.leftVehicleTime % 1000)
      dxDrawText(time,
        0, 88, screenWidth, screenHeight, tocolor(255, 255, 255, 255), 1, Assets.fonts.time,
        "center", "top", false, false, false, false, true)
    end
  end
end

addEventHandler("Race.startWaiting", resourceRoot, function (time)
  Race.waiting = true
  Waiting.setVisible(true)
  Waiting.setTime(time)
end)

addEventHandler("Race.updateWaitingTime", resourceRoot, function (time)
  Waiting.setTime(time)
end)

addEventHandler("Race.updateLapTime", resourceRoot, function (time)
  Race.lapTime = time
end)

addEventHandler("Race.onLapRecord", resourceRoot, function (bestPlayer, bestPlayerTime)
  Race.bestPlayerName = bestPlayer.name
  Race.bestPlayerTime = bestPlayerTime
end)

addEventHandler("Race.onFinishLap", resourceRoot, function (lapTime, bestLapTime)
  Race.lapTime = 0
  Race.bestLapTime = bestLapTime
end)

addEventHandler("Race.onStart", resourceRoot, function (trackName, timeLeft)
  Race.start(trackName, timeLeft)
end)

addEventHandler("Race.onCancel", resourceRoot, function ()
  Race.stop()
end)

addEventHandler("Race.onJoin", resourceRoot, Race.join)

addEventHandler("Race.onLeave", resourceRoot, Race.stop)

addEventHandler("Race.onEnd", resourceRoot, function (topPlayers)
  Race.stop()
  Top.setVisible(true)
  Top.setPlayers(topPlayers)
end)

addEventHandler("Race.askConfirmation", resourceRoot, function ()
  toggleAllControls(false, true, false)
  Confirmation.setCallback(Race.onConfirm)
  Confirmation.setVisible(true)
end)

-- Disable collisions with others
-- addEventHandler("onClientElementStreamIn", root, function ()
--   if Race.started then
--     if source.type == "player" or source.type == "vehicle" then
--       localPlayer:setCollidableWith(source, false)
--       localPlayer.vehicle:setCollidableWith(source, false)
--       source:setCollidableWith(localPlayer, false)
--     end
--   end
-- end)