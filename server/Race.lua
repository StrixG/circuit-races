addEvent("Race.onConfirm", true)

Race = {}

Race.waiting = false
Race.started = false

Race.participants = {}
Race.vehicles = {}

Race.checkpoints = {}

Race.currentCheckpoint = {}
Race.currentMarker = {}
Race.nextMarker = {}
Race.lapStartTime = {}
Race.bestLapTime = {}
Race.leftVehicleTimer = {}

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

  -- Waiting
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
  if isTimer(Race.updateLeftTimer) then
    Race.updateLeftTimer:destroy()
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
  Race.updateLeftTimer = nil
  Race.endTimer = nil
  Race.startMarker = nil
  Race.startBlip = nil

  Race.prizePool = nil
  Race.trackName = nil
  Race.checkpoints = {}
  Race.participants = {}
  Race.vehicles = {}

  for player, timer in pairs(Race.leftVehicleTimer) do
    if isTimer(timer) then
      timer:destroy()
    end
  end
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
  Race.leftVehicleTimer = {}
  Race.currentCheckpoint = {}
  Race.currentMarker = {}
  Race.nextMarker = {}
  Race.lapStartTime = {}
  Race.bestLapTime = {}
  
  Race.bestPlayer = nil
  Race.bestPlayerTime = nil
end

function Race.cancel()
  triggerClientEvent("Race.onCancel", resourceRoot)
  Race.stop()
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

  for i = #Race.participants, 1, -1 do
    local participant = Race.participants[i]
    if participant:getMoney() < PRIZE_POOL_FEE then
      Race.leave(participant)
      outputChatBox("Недостаточно денег для участия в гонке.", participant, unpack(CHAT_MESSAGES_COLOR))
    elseif not isDriver(participant) then
      Race.leave(participant)
      outputChatBox("Вы вышли из машины, участие в гонке отменено.", participant, unpack(CHAT_MESSAGES_COLOR))
    end
  end

  -- Cancel race if there are not enough participants
  if #Race.participants < MIN_PARTICIPANTS then
    Race.cancel()
    outputChatBox("Гонка отменена из-за недостаточного количества участников.", root, unpack(CHAT_MESSAGES_COLOR))
    return
  end

  Race.prizePool = #Race.participants * PRIZE_POOL_FEE

  Race.endTimer = Timer(Race.onEnd, RACE_DURATION * 1000, 1)

  -- Sync time with clients
  Race.updateLapTimer = Timer(function ()
    for i, participant in pairs(Race.participants) do
      local lapTime = getTickCount() - Race.lapStartTime[participant]
      triggerClientEvent(participant, "Race.updateLapTime", resourceRoot, lapTime)
    end
  end, TIME_SYNC_INTERVAL * 3, 0)

  Race.updateLeftTimer = Timer(function ()
    local leftTime = Race.endTimer:getDetails()
    triggerClientEvent(Race.participants, "Race.updateLeftTime", resourceRoot, leftTime)
  end, TIME_SYNC_INTERVAL * 3, 0)

  -- Set players in position
  for i, participant in pairs(Race.participants) do
    participant:takeMoney(PRIZE_POOL_FEE)
    outputChatBox("Вы заплатили $" .. numberFormat(PRIZE_POOL_FEE, ' ') .. " за участие в гонке.", participant, unpack(CHAT_MESSAGES_COLOR))

    Race.spawnPlayer(participant)
    triggerClientEvent(participant, "Race.onStart", resourceRoot, Race.trackName, RACE_DURATION * 1000)
  end

  outputChatBox("Гонка " .. Race.trackName .. " началась. Призовой фонд $" .. numberFormat(Race.prizePool, ' ') .. ".", root, unpack(CHAT_MESSAGES_COLOR))
  outputChatBox("Вы ещё можете успеть присоединиться к гонке.", root, unpack(CHAT_MESSAGES_COLOR))

  Race.started = true
end

function Race.onEnd()
  outputChatBox("Гонка окончена.", root, unpack(CHAT_MESSAGES_COLOR))

  local topPlayers = {}
  -- Commission
  Race.prizePool = Race.prizePool * (1 - PRIZE_COMMISSION / 100)
  
  -- Top
  for player, lapTime in pairs(Race.bestLapTime) do
    table.insert(topPlayers, {player = player, name = player.name, time = lapTime, vehicle = player.vehicle.name})
  end

  table.sort(topPlayers, function (player1, player2)
    return player1.time < player2.time
  end)

  -- Give prizes
  for i, player in pairs(topPlayers) do
    if i <= TOP_PLAYER_COUNT then
      player.prize = math.floor(Race.prizePool * PRIZE_COEFFS[i] / 100)
      if isElement(player.player) then
        player.player:giveMoney(player.prize)
      end
    else
      player.prize = 0
    end
    if i > 10 then
      topPlayers[i] = nil
    end
  end

  if #topPlayers > 0 then
    outputChatBox("Победители:", root, unpack(CHAT_MESSAGES_COLOR))
    local topCount = math.min(TOP_PLAYER_COUNT, #topPlayers)
    for i = 1, topCount do
      local time = ("%d:%02d.%03d"):format(topPlayers[i].time / 1000 / 60, topPlayers[i].time / 1000 % 60, topPlayers[i].time % 1000)
      outputChatBox(("%d. %s на %s (%s, $%s)"):format(
        i, removeHexFromString(topPlayers[i].name), topPlayers[i].vehicle, time, numberFormat(topPlayers[i].prize, ' ')), root, unpack(CHAT_MESSAGES_COLOR))
    end
  else
    outputChatBox("Нет результатов гонки, так как никто не закончил круг.", root, unpack(CHAT_MESSAGES_COLOR))
  end

  triggerClientEvent(Race.participants, "Race.onEnd", resourceRoot, topPlayers)
  Race.stop()
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
end

function Race.join(player)
  if not Race.activeTrack or not player.vehicle then
    return
  end

  for i, participant in pairs(Race.participants) do
    if participant == player then
      return
    end
  end

  table.insert(Race.participants, player)
  Race.vehicles[player] = player.vehicle

  Race.startMarker:setVisibleTo(player, true) -- bug workaround
  Race.startMarker:setVisibleTo(player, false)

  triggerClientEvent(player, "Race.onJoin", resourceRoot)
  if Race.started then
    Race.spawnPlayer(player)
    local timeLeft = Race.endTimer:getDetails()
    triggerClientEvent(player, "Race.onStart", resourceRoot, Race.trackName, timeLeft)
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

  Race.vehicles[player] = nil

  Race.lapStartTime[player] = nil
  Race.bestLapTime[player] = nil
  Race.currentCheckpoint[player] = nil
  Race.currentMarker[player] = nil
  Race.nextMarker[player] = nil

  if Race.startMarker then
    Race.startMarker:setVisibleTo(player, true)
  end

  -- Reset best player
  if Race.bestPlayer == player then
    Race.bestPlayer = nil
    Race.bestPlayerTime = nil
    triggerClientEvent(Race.participants, "Race.onLapRecord", resourceRoot)
  end

  triggerClientEvent(player, "Race.onLeave", resourceRoot)
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
  if source.type == "player" and matchingDimension then
    if Race.waiting or Race.started then
      if Race.isJoined(source) then
        if Race.waiting then
          outputChatBox("Вы уже участвуете в гонке. Ожидайте начала.", source, unpack(CHAT_MESSAGES_COLOR))
        end
        return
      end
      if not isDriver(source) then
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
    playSoundFrontEnd(player, 45)
    triggerClientEvent(Race.participants, "Race.onLapRecord", resourceRoot, Race.bestPlayer, Race.bestPlayerTime)
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

addEventHandler("onMarkerHit", root, function (hitElement, matchingDimension)
  if hitElement.type == "vehicle" and matchingDimension then
    if Race.started then
      local player = hitElement.occupant
      if player and Race.isJoined(player) then
        if source == Race.currentMarker[player] then
          if Race.currentCheckpoint[player] == 1 then
            Race.onFinishLap(player, getTickCount() - Race.lapStartTime[player])
            Race.lapStartTime[player] = getTickCount()
            
            playSoundFrontEnd(player, 44)
          else
            playSoundFrontEnd(player, 43)
          end
          Race.showNextCheckpoint(player)
        end
      end
    end
  end
end)

addEventHandler("onPlayerVehicleEnter", root, function (vehicle, seat)
  if Race.isJoined(source) then
    if Race.leftVehicleTimer[source] and Race.vehicles[source] == vehicle and seat == 0 then
      Race.leftVehicleTimer[source]:destroy()
      Race.leftVehicleTimer[source] = nil
    end
  end
end)

addEventHandler("onPlayerVehicleExit", root, function ()
  if Race.isJoined(source) then
    outputChatBox("Вернитесь в машину, чтобы продолжить гонку.", source, unpack(CHAT_MESSAGES_COLOR))
    Race.leftVehicleTimer[source] = Timer(function (player)
      outputChatBox("Вы вышли из машины. Участие в гонке отменено.", player, unpack(CHAT_MESSAGES_COLOR))
      Race.leave(player)
    end, RACE_LEFT_VEHICLE_TIME * 1000, 1, source)
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

-- Remove a player from the race when he quits
addEventHandler("onPlayerQuit", root, function ()
  Race.leave(source)
end)

-- Remove a player from the race when his vehicle is destroyed
addEventHandler("onElementDestroy", root, function ()
  if Race.activeTrack and source.type == "vehicle" then
    for player, vehicle in pairs(Race.vehicles) do
      if source == vehicle then
        outputChatBox("Ваша машина уничтожена. Участие в гонке отменено.", player, unpack(CHAT_MESSAGES_COLOR))
        Race.leave(player)
        break
      end
    end
  end
end)