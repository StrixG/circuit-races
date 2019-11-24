local screenWidth, screenHeight = guiGetScreenSize()

Confirmation = {}

Confirmation.visible = false

local fadeProgress = 0
local fadeTarget = 0

function Confirmation.update(deltaTime)
  local newFadeProgress = fadeProgress + (fadeTarget - fadeProgress) * (deltaTime / 100)
  if fadeTarget < fadeProgress then
    fadeProgress = math.max(fadeTarget, newFadeProgress)
  elseif fadeTarget > fadeProgress then
    fadeProgress = math.min(fadeTarget, newFadeProgress)
  end
end

function Confirmation.setCallback(callback)
  Confirmation.callback = callback
end

function Confirmation.draw()
  dxDrawRectangle(0, 0, screenWidth, screenHeight, tocolor(0, 0, 0, fadeProgress * 191))
  dxDrawText("Принять участие в гонке за\n#1F85DE$" .. numberFormat(PRIZE_POOL_FEE, ' ') .. "?",
    0, 0, screenWidth, screenHeight, tocolor(255, 255, 255, fadeProgress * 255), 1, Assets.confirmation,
    "center", "center", false, false, false, true, true)
  dxDrawText("Backspace #1F85DEОтказаться    #FFFFFFEnter #1F85DEСогласиться",
    0, 0, screenWidth, screenHeight - 64, tocolor(255, 255, 255, fadeProgress * 255), 1, Assets.text,
    "center", "bottom", false, false, false, true, true)
end

function Confirmation.setVisible(visible)
  Confirmation.visible = visible
  if visible then
    fadeProgress = 0
    fadeTarget = 1
    addEventHandler("onClientRender", root, Confirmation.draw)
    addEventHandler("onClientPreRender", root, Confirmation.update)
  else
    removeEventHandler("onClientRender", root, Confirmation.draw)
    removeEventHandler("onClientPreRender", root, Confirmation.update)
    fadeTarget = 0
    Confirmation.callback = nil
  end
end

addEventHandler("onClientKey", root, function (key, state)
  if Confirmation.visible then
    if key == "backspace" then
      Confirmation.callback(false)
      Confirmation.setVisible(false)
      cancelEvent()
    elseif key == "enter" then
      Confirmation.callback(true)
      Confirmation.setVisible(false)
      cancelEvent()
    end
  end
end)