addEvent("Race.onConfirm", true)

Race = {}

Race.waiting = false
Race.started = false
Race.participants = {}
Race.checkpoints = {}

Race.currentCheckpoint = {}
Race.currentMarker = {}
Race.nextMarker = {}
Race.lapStartTime = {}
Race.bestLapTime = {}

function Race.prepare()
  if Race.activeTrack then
    return
  end

  -- Pick random track
  Race.activeTrack = Tracks.list[math.random(1, #Tracks.list)]

  Race.prizePool = 0

  Race.trackName = Tracks.getName(Race.activeTrack)
  Race.checkpoints = Tracks.getCheckpoints(Race.activeTrack)

  Race.startMarker = Marker(Race.checkpoints[1][1], Race.checkpoints[1][2], Race.checkpoints[1][3])
  Race.startBlip = Blip(Race.checkpoints[1][1], Race.checkpoints[1][2], Race.checkpoints[1][3], 53)

  addEventHandler("onMarkerHit", Race.startMarker, Race.onStartMarkerHit)

  Race.waiting = true
  Race.waitingTimer = Timer(Race.start, RACE_DELAY * 1000, 1)
  Race.updateWaitingTimer = Timer(function ()
    local waitingTime = Race.waitingTimer:getDetails()
    triggerClientEvent(Race.participants, "Race.updateWaitingTime", resourceRoot, waitingTime)
  end, TIME_SYNC_INTERVAL * 3, 0)

  local raceDelayMin = RACE_DELAY / 60
  outputChatBox(("Скоро начнётся гонка %s!"):format(Race.trackName, root), root, unpack(CHAT_MESSAGES_COLOR))
  outputChatBox(("До начала гонки %d %s."):format(
    raceDelayMin, getPluralString(raceDelayMin, { "минут", "минута", "минуты" })), root,
    unpack(CHAT_MESSAGES_COLOR)
  )
end

function Race.stop()
  triggerClientEvent("Race.onCancel", resourceRoot)

  Race.waiting = false

  -- for i, participant in pairs(Race.participants) do
  --   participant.vehicle:setFrozen(false)
  --   toggleAllControls(participant, true, true, false)
  -- end

  if isTimer(Race.waitingTimer) then
    Race.waitingTimer:destroy()
  end
  if isTimer(Race.updateWaitingTimer) then
    Race.updateWaitingTimer:destroy()
  end
  if isTimer(Race.endTimer) then
    Race.endTimer:destroy()
  end
  if isTimer(Race.updateLapTimer) then
    Race.updateLapTimer:destroy()
  end
  if isElement(Race.startMarker) then
    Race.startMarker:destroy()
  end
  if isElement(Race.startBlip) then
    Race.startBlip:destroy()
  end

  Race.activeTrack = nil

  Race.waitingTimer = nil
  Race.updateWaitingTimer = nil
  Race.updateLapTimer = nil
  Race.endTimer = nil
  Race.startMarker = nil
  Race.startBlip = nil

  Race.prizePool = nil
  Race.trackName = nil
  Race.checkpoints = {}
  Race.participants = {}
  
  for player, marker in pairs(Race.currentMarker) do
    if isElement(marker) then
      marker:destroy()
    end
  end
  for player, marker in pairs(Race.nextMarker) do
    if isElement(marker) then
      marker:destroy()
    end
  end
  Race.currentCheckpoint = {}
  Race.currentMarker = {}
  Race.nextMarker = {}
  Race.lapStartTime = {}
  Race.bestLapTime = {}

  Race.bestPlayer = nil
  Race.bestPlayerTime = nil
end

function Race.start()
  Race.waiting = false
  if isTimer(Race.waitingTimer) then
    Race.waitingTimer:destroy()
  end
  Race.waitingTimer = nil
  if isTimer(Race.updateWaitingTimer) then
    Race.updateWaitingTimer:destroy()
  end
  Race.updateWaitingTimer = nil

  if #Race.participants < MIN_PARTICIPANTS then
    Race.stop()
    outputChatBox("Гонка отменена из-за недостаточного количества участников.", root, unpack(CHAT_MESSAGES_COLOR))
    return
  end

  for i = #Race.participants, 1, -1 do
    local participant = Race.participants[i]
    if participant:getMoney() < PRIZE_POOL_FEE then
      Race.leave(participant)
      outputChatBox("Недостаточно денег для участия в гонке.", participant, unpack(CHAT_MESSAGES_COLOR))
    else
      participant:takeMoney(PRIZE_POOL_FEE)
      outputChatBox("Вы заплатили $" .. numberFormat(PRIZE_POOL_FEE, ' ') .. " за участие в гонке.", participant, unpack(CHAT_MESSAGES_COLOR))
    end
  end

  Race.prizePool = #Race.participants * PRIZE_POOL_FEE

  -- Set players in position
  for i, participant in pairs(Race.participants) do
    Race.spawnPlayer(participant)
  end

  outputChatBox("Гонка " .. Race.trackName .. " началась. Призовой фонд $" .. numberFormat(Race.prizePool, ' ') .. ".", root, unpack(CHAT_MESSAGES_COLOR))
  outputChatBox("Вы ещё можете успеть присоединиться к гонке.", root, unpack(CHAT_MESSAGES_COLOR))

  Race.endTimer = Timer(function ()
    Race.stop()
  end, RACE_DURATION * 1000, 1)

  Race.updateLapTimer = Timer(function ()
    for i, participant in pairs(Race.participants) do
      local lapTime = getTickCount() - Race.lapStartTime[participant]
      triggerClientEvent(participant, "Race.updateLapTime", resourceRoot, lapTime)
    end
  end, TIME_SYNC_INTERVAL * 3, 0)

  Race.started = true
end

function Race.spawnPlayer(player)
  local firstCheckpoint = Race.checkpoints[1]
  local secondCheckpoint = Race.checkpoints[2]

  local _, _, directionZ = findRotation3D(firstCheckpoint[1], firstCheckpoint[2], firstCheckpoint[3], secondCheckpoint[1], secondCheckpoint[2], secondCheckpoint[3])
  player.vehicle:setPosition(firstCheckpoint[1], firstCheckpoint[2], firstCheckpoint[3] + 0.5)
  player.vehicle:setRotation(0, 0, directionZ)
  player.vehicle:setVelocity(0, 0, 0)
  player:setCameraTarget()

  Race.showNextCheckpoint(player)

  Race.lapStartTime[player] = getTickCount()

  triggerClientEvent(player, "Race.onStart", resourceRoot, Race.trackName)
end

function Race.join(player)
  if not Race.activeTrack then
    return
  end

  for i, participant in pairs(Race.participants) do
    if participant == player then
      return
    end
  end

  table.insert(Race.participants, player)
  Race.startMarker:setVisibleTo(player, true)
  Race.startMarker:setVisibleTo(player, false)

  if Race.started then
    Race.spawnPlayer(player)
  end
end

function Race.leave(player)
  for i, participant in pairs(Race.participants) do
    if participant == player then
      table.remove(Race.participants, i)
      break
    end
  end

  if isElement(Race.currentMarker[player]) then
    Race.currentMarker[player]:destroy()
  end
  if isElement(Race.nextMarker[player]) then
    Race.nextMarker[player]:destroy()
  end

  Race.lapStartTime[player] = nil
  Race.bestLapTime[player] = nil
  Race.currentCheckpoint[player] = nil
  Race.currentMarker[player] = nil
  Race.nextMarker[player] = nil

  if Race.startMarker then
    Race.startMarker:setVisibleTo(player, true)
  end

  triggerClientEvent(player, "Race.onCancel", resourceRoot)
end

function Race.isJoined(player)
  for i, participant in pairs(Race.participants) do
    if participant == player then
      return true
    end
  end

  return false
end

function Race.onStartMarkerHit(source, matchingDimension)
  if matchingDimension then
    if Race.waiting or Race.started then
      if Race.isJoined(source) then
        if Race.waiting then
          outputChatBox("Вы уже участвуете в гонке. Ожидайте начала.", source, unpack(CHAT_MESSAGES_COLOR))
        end
        return
      end
      if not source.vehicle or source.vehicleSeat ~= 0 then
        outputChatBox("Вы должны быть в машине, чтобы принять участие в гонке.", source, unpack(CHAT_MESSAGES_COLOR))
        return
      end
      if source:getMoney() < PRIZE_POOL_FEE then
        outputChatBox("Недостаточно денег для участия в гонке.", source, unpack(CHAT_MESSAGES_COLOR))
        return
      end
      toggleAllControls(source, false, true, false)
      triggerClientEvent(source, "Race.askConfirmation", resourceRoot)
    end
  end
end

function Race.onFinishLap(player, elapsedTime)
  if not Race.bestLapTime[player] then
    Race.bestLapTime[player] = elapsedTime
  elseif elapsedTime < Race.bestLapTime[player] then
    Race.bestLapTime[player] = elapsedTime
  end
  if not Race.bestPlayer or elapsedTime < Race.bestPlayerTime then
    Race.bestPlayer = player
    Race.bestPlayerTime = elapsedTime
    triggerClientEvent(root, "Race.onLapRecord", resourceRoot, Race.bestPlayer, Race.bestPlayerTime)
  end
  triggerClientEvent(player, "Race.onFinishLap", resourceRoot, elapsedTime, Race.bestLapTime[player])
end

function Race.showNextCheckpoint(player)
  if isElement(Race.currentMarker[player]) then
    Race.currentMarker[player]:destroy()
  end
  if isElement(Race.nextMarker[player]) then
    Race.nextMarker[player]:destroy()
  end

  if not Race.currentCheckpoint[player] then
    Race.currentCheckpoint[player] = 2
  else
    Race.currentCheckpoint[player] = Race.currentCheckpoint[player] % #Race.checkpoints + 1
  end

  local currentCheckpoint = Race.currentCheckpoint[player]
  -- Current checkpoint
  local position = Race.checkpoints[currentCheckpoint]
  local currentMarker = Marker(position[1], position[2], position[3], "checkpoint", 4,
    CURRENT_CHECKPOINT_COLOR[1], CURRENT_CHECKPOINT_COLOR[2], CURRENT_CHECKPOINT_COLOR[3], 255, player)

  -- Next checkpoint
  local nextCheckpoint = currentCheckpoint % #Race.checkpoints + 1
  local nextPosition = Race.checkpoints[nextCheckpoint]
  local nextMarker = Marker(nextPosition[1], nextPosition[2], nextPosition[3], "checkpoint", 4,
    NEXT_CHECKPOINT_COLOR[1], NEXT_CHECKPOINT_COLOR[2], NEXT_CHECKPOINT_COLOR[3], 255, player)

  -- Set checkpoints targets
  if currentCheckpoint == 1 then
    currentMarker:setIcon("finish")
  else
    currentMarker:setIcon("arrow")
    currentMarker:setTarget(nextPosition[1], nextPosition[2], nextPosition[3])
  end

  if nextCheckpoint == 1 then
    nextMarker:setIcon("finish")
  else
    local nextNextCheckpoint = (currentCheckpoint + 1) % #Race.checkpoints + 1
    local nextNextPosition = Race.checkpoints[nextNextCheckpoint]
    nextMarker:setTarget(nextNextPosition[1], nextNextPosition[2], nextNextPosition[3])
  end

  Race.currentMarker[player] = currentMarker
  Race.nextMarker[player] = nextMarker
end

addEventHandler("onPlayerMarkerHit", root, function (markerHit, matchingDimension)
  if matchingDimension then
    if Race.started then
      if Race.isJoined(source) then
        if markerHit == Race.currentMarker[source] then
          if Race.currentCheckpoint[source] == 1 then
            Race.onFinishLap(source, getTickCount() - Race.lapStartTime[source])
            Race.lapStartTime[source] = getTickCount()
          end
          Race.showNextCheckpoint(source)
        end
      end
    end
  end
end)

addEventHandler("onPlayerVehicleExit", root, function ()
  if Race.isJoined(source) then
    outputChatBox("Вы вышли из машины. Участие в гонке отменено.", source, unpack(CHAT_MESSAGES_COLOR))
    Race.leave(source)
  end
end)

addEventHandler("Race.onConfirm", resourceRoot, function (confirmed)
  if confirmed then
    if client:getMoney() < PRIZE_POOL_FEE then
      outputChatBox("Недостаточно денег для участия в гонке.", client, unpack(CHAT_MESSAGES_COLOR))
      return
    end

    Race.join(client)
    outputChatBox("Вы присоединились к гонке.", client, unpack(CHAT_MESSAGES_COLOR))

    if Race.waiting then
      outputChatBox("Ожидайте начала.", client, unpack(CHAT_MESSAGES_COLOR))
      local waitingTime = Race.waitingTimer:getDetails()
      triggerClientEvent(client, "Race.startWaiting", resourceRoot, waitingTime)
    end
  else
    outputChatBox("Вы отказались от участия в гонке.", source, unpack(CHAT_MESSAGES_COLOR))
  end
end)

addEventHandler("onPlayerQuit", root, function ()
  Race.leave(source)
end)