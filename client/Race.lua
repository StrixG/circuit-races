addEvent("Race.askConfirmation", true)
addEvent("Race.startWaiting", true)
addEvent("Race.updateWaitingTime", true)
addEvent("Race.onStart", true)
addEvent("Race.onCancel", true)

Race = {}

Race.waiting = false
Race.started = false

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

addEventHandler("Race.onStart", resourceRoot, function (trackName)
  Race.waiting = false
  Race.started = true
  Race.trackName = trackName
  Waiting.setVisible(false)
end)

addEventHandler("Race.onCancel", resourceRoot, function ()
  Race.waiting = false
  Race.started = false
  Race.trackName = false
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
    dxDrawRectangle(32, 256, 256, 300, 0xBF333333)
    dxDrawText(Race.trackName, 44, 264, 256, 32, tocolor(255, 255, 255, 255), 1, Assets.trackName)
  end
end)