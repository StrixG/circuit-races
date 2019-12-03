local screenWidth, screenHeight = guiGetScreenSize()

Confirmation = {}

Confirmation.visible = false

local fadeProgress = 0
local fadeTarget = 0

function Confirmation.setCallback(callback)
  Confirmation.callback = callback
end

function Confirmation.setVisible(visible)
  if Confirmation.visible == visible then
    return
  end

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
  Confirmation.visible = visible
end

function Confirmation.update(deltaTime)
  local newFadeProgress = fadeProgress + (fadeTarget - fadeProgress) * (deltaTime / 100)
  if fadeTarget < fadeProgress then
    fadeProgress = math.max(fadeTarget, newFadeProgress)
  elseif fadeTarget > fadeProgress then
    fadeProgress = math.min(fadeTarget, newFadeProgress)
  end
end

function Confirmation.draw()
  dxDrawRectangle(0, 0, screenWidth, screenHeight, tocolor(0, 0, 0, fadeProgress * 191))
  dxDrawText(("Принять участие в гонке за\n%s%s руб.?"):format(ACCENT_COLOR_HEX, numberFormat(PRIZE_POOL_FEE, ' ')),
    0, 0, screenWidth, screenHeight, tocolor(255, 255, 255, fadeProgress * 255), 1, Assets.fonts.confirmation,
    "center", "center", false, false, false, true, true)
  dxDrawText(("Backspace %sОтказаться    #FFFFFFEnter %sСогласиться"):format(ACCENT_COLOR_HEX, ACCENT_COLOR_HEX),
    0, 0, screenWidth, screenHeight - 64, tocolor(255, 255, 255, fadeProgress * 255), 1, Assets.fonts.text,
    "center", "bottom", false, false, false, true, true)
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