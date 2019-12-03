local screenWidth, screenHeight = guiGetScreenSize()
local topWidth = 768
local nameOffset = 32
local vehicleOffset = 288
local timeOffset = 488
local prizeOffset = 600

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
    local topHeight = 132 + #Top.players * 32

    local x, y = screenWidth / 2 - topWidth / 2, screenHeight / 2 - topHeight / 2
    dxDrawRectangle(x, y, topWidth, topHeight, tocolor(0, 0, 0, fadeProgress * 191))

    x = x + 8
    y = y + 4
    dxDrawText("Результаты", x, y, x, y,
      tocolor(255, 255, 255, fadeProgress * 255), 1, Assets.fonts.bold)
    y = y + 48
    dxDrawText("Топ-10 участников", x, y, x, y,
      tocolor(255, 255, 255, fadeProgress * 255), 1, Assets.fonts.text)

    y = y + 48
    dxDrawText("№", x, y, x, y,
      tocolor(255, 255, 255, fadeProgress * 255), 1, Assets.fonts.top)
    dxDrawText("Ник", x + nameOffset, y, x, y,
      tocolor(255, 255, 255, fadeProgress * 255), 1, Assets.fonts.top)
    dxDrawText("Машина", x + vehicleOffset, y, x, y,
      tocolor(255, 255, 255, fadeProgress * 255), 1, Assets.fonts.top)
    dxDrawText("Время", x + timeOffset, y, x, y,
      tocolor(255, 255, 255, fadeProgress * 255), 1, Assets.fonts.top)
    dxDrawText("Выигрыш", x + prizeOffset, y, x, y,
      tocolor(255, 255, 255, fadeProgress * 255), 1, Assets.fonts.top)

    y = y + 32
    for i, player in pairs(Top.players) do
      local color
      if i <= WINNER_COUNT then
        color = tocolor(31, 133, 222, fadeProgress * 255)
      else
        color = tocolor(255, 255, 255, fadeProgress * 255)
      end

      dxDrawText(i, x, y, x, y, color, 1, Assets.fonts.top)
      dxDrawText(removeHexFromString(Top.players[i].name), x + nameOffset, y, x, y, color, 1, Assets.fonts.top)
      dxDrawText(Top.players[i].vehicle, x + vehicleOffset, y, x, y, color, 1, Assets.fonts.top)
      local time = ("%d:%02d.%03d"):format(Top.players[i].time / 1000 / 60, Top.players[i].time / 1000 % 60, Top.players[i].time % 1000)
      dxDrawText(time, x + timeOffset, y, x, y, color, 1, Assets.fonts.top)
      dxDrawText(numberFormat(Top.players[i].prize, ' ') .. " руб.", x + prizeOffset, y, x, y, color, 1, Assets.fonts.top)

      y = y + 32
    end

    dxDrawText("Backspace #1F85DEЗакрыть",
      0, 0, screenWidth, screenHeight - 64, tocolor(255, 255, 255, fadeProgress * 255), 1, Assets.fonts.text,
      "center", "bottom", false, false, false, true, true)
  end
end

addEventHandler("onClientKey", root, function (key, state)
  if Top.visible then
    if key == "enter" or key == "backspace" then
      Top.setVisible(false)
      cancelEvent()
    end
  end
end)