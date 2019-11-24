addEvent("Race.askConfirmation", true)
addEvent("Race.startWaiting", true)
addEvent("Race.updateWaitingTime", true)
addEvent("Race.onStart", true)
addEvent("Race.onCancel", true)

Race = {}
Race.waiting = false

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

addEventHandler("Race.onStart", resourceRoot, function ()
  Race.waiting = false
  Waiting.setVisible(false)
end)

addEventHandler("Race.onCancel", resourceRoot, function ()
  Race.waiting = false
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

end)