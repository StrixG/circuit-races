local screenWidth, screenHeight = guiGetScreenSize()

Waiting = {}

Waiting.visible = false
Waiting.time = 0

local pastTickCount = 0

function Waiting.draw()
  dxDrawText("До начала гонки",
    0, 64, screenWidth, screenHeight, tocolor(255, 255, 255, 255), 1, Assets.fonts.text,
    "center", "top", false, false, false, false, true)
  local time = ("%d:%02d.%03d"):format(Waiting.time / 1000 / 60, Waiting.time / 1000 % 60, Waiting.time % 1000)
  dxDrawText(time,
    0, 88, screenWidth, screenHeight, tocolor(255, 255, 255, 255), 1, Assets.fonts.time,
    "center", "top", false, false, false, false, true)

  -- Calculate time
  local elapsedTime = getTickCount() - pastTickCount
  pastTickCount = getTickCount()
  Waiting.time = Waiting.time - elapsedTime
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