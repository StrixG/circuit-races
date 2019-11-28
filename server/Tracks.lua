Tracks = {}

Tracks.LIST_FILENAME = "track_list.json"
Tracks.DEFAULT_CHECKPOINT_SIZE = 4

Tracks.list = {}

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
        local size = node:getAttribute("size") or Tracks.DEFAULT_CHECKPOINT_SIZE
        table.insert(trackCheckpoints, {posX, posY, posZ, size})
      end
    end
    trackXml:unload()

    return trackCheckpoints
  end
end
