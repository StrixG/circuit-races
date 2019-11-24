local announcementTimer = Timer(
  function ()
    local raceDelayMin = RACE_DELAY / 60
    outputChatBox(("До начала гонки %d %s"):format(
      raceDelayMin, getPluralString(raceDelayMin, { "минут", "минуту", "минуты" })),
      unpack(CHAT_MESSAGES_COLOR)
    )
  end,
RACE_ANNOUNCE_INTERVAL * 1000, 0)