local announcementTimer

local activeCheckpoints
local currentCheckpoint

local currentMarker
local nextMarker

function startTestRace()
  activeCheckpoints = Tracks.getCheckpoints("parking")
  currentCheckpoint = 2

  local cp = activeCheckpoints[currentCheckpoint]
  currentMarker = Marker(cp[1], cp[2], cp[3])
  currentMarker:setColor(255, 255, 120, 255)

  local nextCp = activeCheckpoints[currentCheckpoint % #activeCheckpoints + 1]
  nextMarker = Marker(nextCp[1], nextCp[2], nextCp[3])
  nextMarker:setColor(255, 255, 255, 255)
  currentMarker:setTarget(nextCp[1], nextCp[2], nextCp[3])

  local nextNextCp = activeCheckpoints[(currentCheckpoint + 1) % #activeCheckpoints + 1]
  nextMarker:setTarget(nextNextCp[1], nextNextCp[2], nextNextCp[3])
end

addEventHandler("onResourceStart", resourceRoot, function ()
  Tracks.loadList()

  Race.prepare()
  announcementTimer = Timer(
    function ()
      Race.prepare()
    end,
  RACE_ANNOUNCE_INTERVAL * 1000, 0)

  -- startTestRace()
end)

addEventHandler("onPlayerMarkerHit", root, function (markerHit)
  if markerHit == currentMarker then
    currentCheckpoint = currentCheckpoint % #activeCheckpoints + 1

    currentMarker:destroy()
    currentMarker = nextMarker
    currentMarker:setColor(255, 255, 120, 255)

    local nextCheckpoint = currentCheckpoint % #activeCheckpoints + 1
    local nextPos = activeCheckpoints[nextCheckpoint]
    nextMarker = Marker(nextPos[1], nextPos[2], nextPos[3])
    nextMarker:setColor(255, 255, 255, 255)

    if currentCheckpoint == 1 then
      currentMarker:setIcon("finish")
    else
      currentMarker:setIcon("arrow")
      currentMarker:setTarget(nextPos[1], nextPos[2], nextPos[3])
    end

    if nextCheckpoint == 1 then
      nextMarker:setIcon("finish")
    else
      local nextNextCheckpoint = (currentCheckpoint + 1) % #activeCheckpoints + 1
      local nextNextPos = activeCheckpoints[nextNextCheckpoint]
      nextMarker:setTarget(nextNextPos[1], nextNextPos[2], nextNextPos[3])
    end
  end
end)