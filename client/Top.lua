local screenWidth, screenHeight = guiGetScreenSize()
local topWidth = 256

Top = {}

Top.visible = false

local fadeProgress = 0
local fadeTarget = 0

function Top.setVisible(visible)
  if Top.visible == visible then
    return
  end

  if visible then
    fadeProgress = 0
    fadeTarget = 1
    addEventHandler("onClientRender", root, Top.draw)
    addEventHandler("onClientPreRender", root, Top.update)
  else
    removeEventHandler("onClientRender", root, Top.draw)
    removeEventHandler("onClientPreRender", root, Top.update)
    fadeTarget = 0
    Top.players = nil
  end
  Top.visible = visible
end

function Top.setPlayers(topPlayers)
  Top.players = topPlayers
end

function Top.update(deltaTime)
  local newFadeProgress = fadeProgress + (fadeTarget - fadeProgress) * (deltaTime / 100)
  if fadeTarget < fadeProgress then
    fadeProgress = math.max(fadeTarget, newFadeProgress)
  elseif fadeTarget > fadeProgress then
    fadeProgress = math.min(fadeTarget, newFadeProgress)
  end
end

function Top.draw()
  if Top.players then
    dxDrawRectangle(screenWidth / 2 - topWidth / 2, screenHeight / 2 - 256, topWidth, 512, tocolor(0, 0, 0, fadeProgress * 191))
  end
end

addEventHandler("onClientKey", root, function (key, state)
  if Top.visible then
    if key == "enter" or key == "space" or key == "backspace" then
      Top.setVisible(false)
      cancelEvent()
    end
  end
end)