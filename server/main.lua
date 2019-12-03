local announcementTimer

addEventHandler("onResourceStart", resourceRoot, function ()
  Tracks.loadList()

  Race.prepare()
  announcementTimer = Timer(
    function ()
      Race.prepare()
    end,
  RACE_ANNOUNCE_INTERVAL * 1000, 0)
end)

function outputMessage(message, to)
  local r, g, b = unpack(ACCENT_COLOR)
  outputChatBox("[Гонка] #FFFFFF" .. message, to, r, g, b, true)
end