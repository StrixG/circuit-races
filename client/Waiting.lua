local screenWidth, screenHeight = guiGetScreenSize()

Waiting = {}

Waiting.visible = false
Waiting.time = 0

local pastTickCount = 0

function Waiting.draw()
  dxDrawText("До начала гонки",
    0, 64, screenWidth, screenHeight, tocolor(255, 255, 255, 255), 1, Assets.text,
    "center", "top", false, false, false, false, true)
  local time = ("%d:%02d"):format(Waiting.time / 60, Waiting.time % 60)
  dxDrawText(Waiting.time,
    0, 96, screenWidth, screenHeight, tocolor(255, 255, 255, 255), 1, Assets.time,
    "center", "top", false, false, false, false, true)

  -- Calculate time
  if getTickCount() - pastTickCount >= 1000 then
    pastTickCount = getTickCount()
    Waiting.time = Waiting.time - 1
  end
end

function Waiting.setTime(time)
  pastTickCount = getTickCount(0)
  Waiting.time = time
end

function Waiting.setVisible(visible)
  Waiting.visible = visible
  if visible then
    addEventHandler("onClientRender", root, Waiting.draw)
  else
    removeEventHandler("onClientRender", root, Waiting.draw)
    Waiting.time = 0
    pastTickCount = 0
  end
end