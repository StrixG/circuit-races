local announcementTimer

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
end)