local screenWidth, screenHeight = guiGetScreenSize()

Waiting = {}

Waiting.visible = false
Waiting.time = 0

local pastTickCount = 0

function Waiting.draw()
  if Waiting.time / 1000 > 5 then
    dxDrawText("Старт гонки через",
      0, 64, screenWidth, screenHeight, tocolor(255, 255, 255, 255), 1, Assets.fonts.text,
      "center", "top", false, false, false, false, true)
    local time = ("%d:%02d.%03d"):format(Waiting.time / 1000 / 60, Waiting.time / 1000 % 60, Waiting.time % 1000)
    dxDrawText(time,
      0, 88, screenWidth, screenHeight, tocolor(255, 255, 255, 255), 1, Assets.fonts.time,
      "center", "top", false, false, false, false, true)
  else
    local time = math.ceil(Waiting.time / 1000)
    dxDrawText(time,
      8, 8, screenWidth, screenHeight, tocolor(0, 0, 0, 191), 1, Assets.fonts.countdown,
      "center", "center", false, false, false, false, true)
    dxDrawText(time,
      0, 0, screenWidth, screenHeight, tocolor(255, 255, 255, 255), 1, Assets.fonts.countdown,
      "center", "center", false, false, false, false, true)
  end

  -- Calculate time
  local elapsedTime = getTickCount() - pastTickCount
  pastTickCount = getTickCount()
  Waiting.time = math.max(0, Waiting.time - elapsedTime)
end

function Waiting.setTime(time)
  pastTickCount = getTickCount(0)
  Waiting.time = time
end

function Waiting.setVisible(visible)
  if Waiting.visible == visible then
    return
  end

  if visible then
    addEventHandler("onClientRender", root, Waiting.draw)
  else
    removeEventHandler("onClientRender", root, Waiting.draw)
    Waiting.time = 0
    pastTickCount = 0
  end
  Waiting.visible = visible
end