Tracks = {}
Tracks.list = {}

Tracks.LIST_FILENAME = "track_list.json"

-- Loads the track list
function Tracks.loadList()
  if File.exists(Tracks.LIST_FILENAME) then
    local file = File.open(Tracks.LIST_FILENAME, true)
    if file then
      local content = file:read(file.size)
      file:close()

      local trackList = {fromJSON(content)}
      if trackList[1] then
        Tracks.list = {}
        for i, track in pairs(trackList) do
          if File.exists(Tracks.getTrackPath(track)) then
            table.insert(Tracks.list, track)
          else
            print("Race: Couldn't find track '" .. track .. "'")
          end
        end
      end

      return true
    end
  end
  print("Race: Failed to load track list")
end

function Tracks.getTrackPath(track)
  return "tracks/" .. track .. ".xml"
end

function Tracks.getName(track)
  local trackXml = XML.load(Tracks.getTrackPath(track), true)
  if trackXml then
    local trackName = trackXml:findChild("name", 0).value
    trackXml:unload()

    return trackName
  end
end

function Tracks.getCheckpoints(track)
  local trackXml = XML.load(Tracks.getTrackPath(track), true)
  if trackXml then
    local trackCheckpoints = {}
    local childrenNode = trackXml:getChildren()
    for i, node in pairs(childrenNode) do
      if node:getName() == "checkpoint" then
        local posX = node:getAttribute("x")
        local posY = node:getAttribute("y")
        local posZ = node:getAttribute("z")
        table.insert(trackCheckpoints, {posX, posY, posZ})
      end
    end
    trackXml:unload()

    return trackCheckpoints
  end
end

local activeCheckpoints
local currentCheckpoint

local currentMarker
local nextMarker

addEventHandler("onResourceStart", resourceRoot, function ()
  Tracks.loadList()
  activeCheckpoints = Tracks.getCheckpoints("test")
  currentCheckpoint = 1

  local cp = activeCheckpoints[currentCheckpoint]
  currentMarker = Marker(cp[1], cp[2], cp[3])
  currentMarker:setColor(255, 255, 120, 255)

  local nextCp = activeCheckpoints[currentCheckpoint % #activeCheckpoints + 1]
  nextMarker = Marker(nextCp[1], nextCp[2], nextCp[3])
  nextMarker:setColor(255, 255, 255, 255)
  currentMarker:setTarget(nextCp[1], nextCp[2], nextCp[3])

  local nextNextCp = activeCheckpoints[(currentCheckpoint + 1) % #activeCheckpoints + 1]
  nextMarker:setTarget(nextNextCp[1], nextNextCp[2], nextNextCp[3])
end)

addEventHandler("onPlayerMarkerHit", root, function (markerHit)
  if markerHit == currentMarker then
    currentCheckpoint = currentCheckpoint % #activeCheckpoints + 1

    currentMarker:destroy()
    currentMarker = nextMarker
    currentMarker:setColor(255, 255, 120, 255)

    if currentCheckpoint == #activeCheckpoints then
      currentMarker:setIcon("finish")
    else
      currentMarker:setIcon("arrow")
    end

    local nextCp = activeCheckpoints[currentCheckpoint % #activeCheckpoints + 1]
    nextMarker = Marker(nextCp[1], nextCp[2], nextCp[3])
    nextMarker:setColor(255, 255, 255, 255)
    currentMarker:setTarget(nextCp[1], nextCp[2], nextCp[3])

    local nextNextCp = activeCheckpoints[(currentCheckpoint + 1) % #activeCheckpoints + 1]
    nextMarker:setTarget(nextNextCp[1], nextNextCp[2], nextNextCp[3])
  end
end)