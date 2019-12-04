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

function Race.onConfirm(conirmed)
  toggleAllControls(true, true, false)
  triggerServerEvent("Race.onConfirm", resourceRoot, conirmed)
end

function Race.start(trackName, checkpoints, timeLeft)
  Race.waiting = false
  Race.started = true
  Race.trackName = trackName
  Race.checkpoints = checkpoints
  Race.timeLeft = timeLeft
  Race.lapTime = 0

  Waiting.setVisible(false)

  Race.showNextCheckpoint()

  addEventHandler("onClientRender", root, Race.drawUI)
  addEventHandler("onClientPreRender", root, Race.update)
end

function Race.stop()
  Race.waiting = false
  Race.started = false
  Race.joined = false
  Race.trackName = false
  Race.lapTime = nil
  Race.bestLapTime = nil
  Race.timeLeft = nil

  Race.bestPlayerName = nil
  Race.bestPlayerTime = nil

  Race.leftVehicle = false
  Race.leftVehicleTime = nil

  Race.checkpoints = nil

  if isElement(Race.currentMarker) then Race.currentMarker:destroy() end
  if isElement(Race.nextMarker) then Race.nextMarker:destroy() end

  Race.currentCheckpoint = nil
  Race.currentMarker = nil
  Race.currentBlip = nil
  Race.nextMarker = nil

  toggleAllControls(true, true, false)
  Confirmation.setVisible(false)
  Waiting.setVisible(false)

  removeEventHandler("onClientRender", root, Race.drawUI)
  removeEventHandler("onClientPreRender", root, Race.update)
end

function Race.join(bestLapTime, bestPlayerName, bestPlayerTime)
  Race.joined = true
  Race.bestLapTime = bestLapTime
  Race.bestPlayerName = bestPlayerName
  Race.bestPlayerTime = bestPlayerTime
end

function Race.showNextCheckpoint()
  if isElement(Race.currentMarker) then Race.currentMarker:destroy() end
  if isElement(Race.nextMarker) then Race.nextMarker:destroy() end

  if not Race.currentCheckpoint then
    Race.currentCheckpoint = 2
  else
    Race.currentCheckpoint = Race.currentCheckpoint % #Race.checkpoints + 1
  end

  local currentCheckpoint = Race.currentCheckpoint
  -- Current checkpoint
  local checkpointInfo = Race.checkpoints[currentCheckpoint]
  local currentMarker = Marker(checkpointInfo[1], checkpointInfo[2], checkpointInfo[3], "checkpoint", checkpointInfo[4],
    CURRENT_CHECKPOINT_COLOR[1], CURRENT_CHECKPOINT_COLOR[2], CURRENT_CHECKPOINT_COLOR[3], 255)

  -- Next checkpoint
  local nextCheckpoint = currentCheckpoint % #Race.checkpoints + 1
  local nextCheckpointInfo = Race.checkpoints[nextCheckpoint]
  local nextMarker = Marker(nextCheckpointInfo[1], nextCheckpointInfo[2], nextCheckpointInfo[3], "checkpoint", nextCheckpointInfo[4],
    NEXT_CHECKPOINT_COLOR[1], NEXT_CHECKPOINT_COLOR[2], NEXT_CHECKPOINT_COLOR[3], 255)

  -- Set checkpoints targets
  if currentCheckpoint == 1 then
    currentMarker:setIcon("finish")
  else
    currentMarker:setIcon("arrow")
    currentMarker:setTarget(nextCheckpointInfo[1], nextCheckpointInfo[2], nextCheckpointInfo[3])
  end

  if nextCheckpoint == 1 then
    nextMarker:setIcon("finish")
  else
    local nextNextCheckpoint = (currentCheckpoint + 1) % #Race.checkpoints + 1
    local nextNextPosition = Race.checkpoints[nextNextCheckpoint]
    nextMarker:setTarget(nextNextPosition[1], nextNextPosition[2], nextNextPosition[3])
  end

  Race.currentBlip = Blip(0, 0, 0, 27)
  Race.currentBlip:setParent(currentMarker)
  Race.currentBlip:attach(currentMarker)

  Race.currentMarker = currentMarker
  Race.nextMarker = nextMarker
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
  if Race.started and Race.joined then
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
    if Race.bestLapTime then
      dxDrawText("Лучший круг", 44, 350, 256, 32, tocolor(255, 255, 255, 255), 1, Assets.fonts.text)

      time = ("%d:%02d.%03d"):format(Race.bestLapTime / 1000 / 60, Race.bestLapTime / 1000 % 60, Race.bestLapTime % 1000)
      dxDrawText(time, 44, 375, 256, 32, tocolor(255, 255, 255, 255), 1, Assets.fonts.timeSmall)
    end

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

addEventHandler("onClientMarkerHit", root, function (hitElement, matchingDimension)
  if Race.started and hitElement == localPlayer and matchingDimension then
    if Race.joined then
      if source == Race.currentMarker then
        if Race.currentCheckpoint == 1 then
          triggerServerEvent("Race.onFinishLap", resourceRoot)

          playSoundFrontEnd(44)
        else
          playSoundFrontEnd(43)
        end
        Race.showNextCheckpoint()
      end
    end
  end
end)

addEventHandler("Race.updateWaitingTime", resourceRoot, function (time)
  Waiting.setTime(time)
end)

addEventHandler("Race.updateLapTime", resourceRoot, function (time)
  Race.lapTime = time
end)

addEventHandler("Race.updateLeftTime", resourceRoot, function (time)
  Race.leftTime = time
end)

addEventHandler("Race.onLapRecord", resourceRoot, function (bestPlayerName, bestPlayerTime)
  Race.bestPlayerName = bestPlayerName
  Race.bestPlayerTime = bestPlayerTime
  playSoundFrontEnd(45)
end)

addEventHandler("Race.onFinishLap", resourceRoot, function (lapTime, bestLapTime)
  Race.lapTime = 0
  Race.bestLapTime = bestLapTime
end)

addEventHandler("Race.onStart", resourceRoot, Race.start)
addEventHandler("Race.onCancel", resourceRoot, Race.stop)
addEventHandler("Race.onJoin", resourceRoot, Race.join)
addEventHandler("Race.onLeave", resourceRoot, Race.stop)

addEventHandler("Race.onEnd", resourceRoot, function (topPlayers)
  Race.stop()
  if #topPlayers > 0 then
    Top.setVisible(true)
    Top.setPlayers(topPlayers)
  end
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
