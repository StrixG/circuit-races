addEvent("Race.askConfirmation", true)
addEvent("Race.startWaiting", true)
addEvent("Race.updateWaitingTime", true)
addEvent("Race.updateLapTime", true)
addEvent("Race.onLapRecord", true)
addEvent("Race.onFinishLap", true)
addEvent("Race.onStart", true)
addEvent("Race.onCancel", true)

Race = {}

Race.waiting = false
Race.started = false

Race.pastTime = 0
Race.lapTime = 0
Race.bestLapTime = 0

function Race.onConfirm(conirmed)
  toggleAllControls(true, true, false)
  triggerServerEvent("Race.onConfirm", resourceRoot, conirmed)
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

addEventHandler("Race.onStart", resourceRoot, function (trackName)
  Race.waiting = false
  Race.started = true
  Race.trackName = trackName
  Race.pastTime = getTickCount()
  Waiting.setVisible(false)
end)

addEventHandler("Race.onCancel", resourceRoot, function ()
  Race.waiting = false
  Race.started = false
  Race.trackName = false
  Race.pastTime = 0
  Race.lapTime = 0
  Race.bestLapTime = 0
  Race.bestPlayerName = nil
  Race.bestPlayerTime = nil

  if Confirmation.visible then
    toggleAllControls(true, true, false)
    Confirmation.setVisible(false)
  end
  Waiting.setVisible(false)
end)

addEventHandler("Race.askConfirmation", resourceRoot, function ()
  toggleAllControls(false, true, false)
  Confirmation.setCallback(Race.onConfirm)
  Confirmation.setVisible(true)
end)

addEventHandler("onClientRender", root, function ()
  if Race.started then
    dxDrawText(Race.trackName, 46, 266, 256, 32, tocolor(0, 0, 0, 128), 1, Assets.trackName)
    dxDrawText(Race.trackName, 44, 264, 256, 32, tocolor(255, 255, 255, 255), 1, Assets.trackName)

    -- Current lap
    local elapsedTime = getTickCount() - Race.pastTime
    Race.pastTime = getTickCount()
    Race.lapTime = Race.lapTime + elapsedTime

    local time = ("%d:%02d.%03d"):format(Race.lapTime / 1000 / 60, Race.lapTime / 1000 % 60, Race.lapTime % 1000)
    dxDrawText(time, 44, 290, 256, 32, tocolor(255, 255, 255, 255), 1, Assets.time)

    -- Best lap
    dxDrawText("Лучший круг", 44, 350, 256, 32, tocolor(255, 255, 255, 255), 1, Assets.text)

    time = ("%d:%02d.%03d"):format(Race.bestLapTime / 1000 / 60, Race.bestLapTime / 1000 % 60, Race.bestLapTime % 1000)
    dxDrawText(time, 44, 375, 256, 32, tocolor(255, 255, 255, 255), 1, Assets.timeSmall)

    -- Best player
    if Race.bestPlayerName then
      dxDrawText("Лучший игрок", 44, 410, 256, 32, tocolor(255, 255, 255, 255), 1, Assets.text)

      dxDrawText(removeHexFromString(Race.bestPlayerName), 44, 435, 256, 32, tocolor(255, 255, 255, 255), 1, Assets.timeSmall)

      time = ("%d:%02d.%03d"):format(Race.bestPlayerTime / 1000 / 60, Race.bestPlayerTime / 1000 % 60, Race.bestPlayerTime % 1000)
      dxDrawText(time, 44, 460, 256, 32, tocolor(255, 255, 255, 255), 1, Assets.timeSmall)
    end
  end
end)