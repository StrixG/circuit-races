addEvent("Race.onConfirm", true)
addEvent("Race.onFinishLap", true)

Race = {}

Race.waiting = false
Race.started = false

Race.participants = {}
Race.participantAccounts = {}
Race.vehicles = {}

Race.checkpoints = {}

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
  outputMessage(("Скоро начнётся гонка %s!"):format(Race.trackName, root), root)
  outputMessage(("До начала гонки %d %s."):format(
    raceDelayMin, getPluralString(raceDelayMin, { "минут", "минута", "минуты" })))
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

  Race.leftVehicleTimer = {}
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
  if isTimer(Race.updateWaitingTimer) then
    Race.updateWaitingTimer:destroy()
  end

  Race.waitingTimer = nil
  Race.updateWaitingTimer = nil

  for i = #Race.participants, 1, -1 do
    local participant = Race.participants[i]
    if participant:getMoney() < PRIZE_POOL_FEE then
      Race.leave(participant)
      outputMessage("Недостаточно денег для участия в гонке.", participant)
    elseif not isDriver(participant) then
      Race.leave(participant)
      outputMessage("Вы вышли из машины, участие в гонке отменено.", participant)
    end
  end

  -- Cancel race if there are not enough participants
  if #Race.participants < MIN_PARTICIPANTS then
    Race.cancel()
    outputMessage("Гонка отменена из-за недостаточного количества участников.")
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
    outputMessage("Вы заплатили $" .. numberFormat(PRIZE_POOL_FEE, ' ') .. " за участие в гонке.", participant)

    Race.spawnPlayer(participant)
    triggerClientEvent(participant, "Race.onStart", resourceRoot, Race.trackName, Race.checkpoints, RACE_DURATION * 1000)
  end

  outputMessage("Гонка " .. Race.trackName .. " началась. Призовой фонд $" .. numberFormat(Race.prizePool, ' ') .. ".")
  outputMessage("Вы ещё можете успеть присоединиться к гонке.")

  Race.started = true
end

function Race.givePrize(account, amount)
  local player = account:getPlayer()
  if player then
    player:giveMoney(amount)

    outputDebugString(string.format("[Circuit Race] Player %s (%s, %s RUB) won drift event and earned %s",
    player.name,
    account.name,
    tostring(player.money),
    tostring(prize)))
  else
    exports.bank:giveAccountBankMoney(account, amount, "RUB")

    outputDebugString(string.format("[Circuit Race] Offline player (%s) won drift event and earned %s (added to bank)", account.name, tostring(amount)))
  end
end

function Race.onEnd()
  outputMessage("Гонка окончена.")

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
        -- TODO
        Race.givePrize(player.player:getAccount(), player.prize)
      end
    else
      player.prize = 0
    end
    -- Remove other players from top
    if i > 10 then
      topPlayers[i] = nil
    end
  end

  if #topPlayers > 0 then
    outputMessage("Победители:")
    local topCount = math.min(TOP_PLAYER_COUNT, #topPlayers)
    for i = 1, topCount do
      local time = ("%d:%02d.%03d"):format(topPlayers[i].time / 1000 / 60, topPlayers[i].time / 1000 % 60, topPlayers[i].time % 1000)
      outputMessage(("%d. %s на %s (%s, $%s)"):format(
        i, removeHexFromString(topPlayers[i].name), topPlayers[i].vehicle, time, numberFormat(topPlayers[i].prize, ' ')))
    end
  else
    outputMessage("Нет результатов гонки, так как никто не закончил круг.")
  end

  triggerClientEvent(Race.participants, "Race.onEnd", resourceRoot, topPlayers)
  Race.stop()
end

function Race.spawnPlayer(player)
  Race.lapStartTime[player] = getTickCount()
end

function Race.join(player)
  if not Race.activeTrack or not player.vehicle then
    return
  end

  local playerAccount = player:getAccount()
  if not playerAccount then
    return
  end

  for i, participant in pairs(Race.participants) do
    if participant == player then
      return
    end
  end

  table.insert(Race.participants, player)
  table.insert(Race.participantAccounts, playerAccount)
  Race.vehicles[player] = player.vehicle

  Race.startMarker:setVisibleTo(player, true) -- bug workaround
  Race.startMarker:setVisibleTo(player, false)

  triggerClientEvent(player, "Race.onJoin", resourceRoot)
  if Race.started then
    Race.spawnPlayer(player)
    local timeLeft = Race.endTimer:getDetails()
    triggerClientEvent(player, "Race.onStart", resourceRoot, Race.trackName, Race.checkpoints, timeLeft)
  end
end

function Race.leave(player)
  for i, participant in pairs(Race.participants) do
    if participant == player then
      table.remove(Race.participants, i)
      break
    end
  end

  Race.vehicles[player] = nil

  Race.lapStartTime[player] = nil

  if Race.startMarker then
    Race.startMarker:setVisibleTo(player, true)
  end

  triggerClientEvent(player, "Race.onLeave", resourceRoot)
end

function Race.isJoined(player)
  for i, participant in pairs(Race.participants) do
    if participant.player == player then
      return true
    end
  end

  return false
end

function Race.onStartMarkerHit(source, matchingDimension)
  if source.type == "player" and matchingDimension then
    if Race.waiting or Race.started then
      local playerAccount = source:getAccount()
      if not playerAccount then
        return
      end

      if Race.isJoined(source) then
        if Race.waiting then
          outputMessage("Вы уже участвуете в гонке. Ожидайте начала.", source)
        end
        return
      end
      if not isDriver(source) then
        outputMessage("Вы должны быть в машине, чтобы принять участие в гонке.", source)
        return
      end
      if source:getMoney() < PRIZE_POOL_FEE then
        outputMessage("Недостаточно денег для участия в гонке.", source)
        return
      end
      toggleAllControls(source, false, true, false)
      triggerClientEvent(source, "Race.askConfirmation", resourceRoot)
    end
  end
end

function Race.onFinishLap()
  local player = client

  -- Calculate lap time
  local newLapStartTime = getTickCount()
  local elapsedTime = newLapStartTime - Race.lapStartTime[player]
  Race.lapStartTime[player] = newLapStartTime

  -- Calculate best lap time
  if not Race.bestLapTime[player] then
    Race.bestLapTime[player] = elapsedTime
  elseif elapsedTime < Race.bestLapTime[player] then
    Race.bestLapTime[player] = elapsedTime
  end
  -- Determine the best player
  if not Race.bestPlayer or elapsedTime < Race.bestPlayerTime then
    Race.bestPlayer = player
    Race.bestPlayerTime = elapsedTime
    triggerClientEvent(Race.participants, "Race.onLapRecord", resourceRoot, Race.bestPlayer, Race.bestPlayerTime)
  end
  triggerClientEvent(player, "Race.onFinishLap", resourceRoot, elapsedTime, Race.bestLapTime[player])
end

addEventHandler("Race.onFinishLap", resourceRoot, Race.onFinishLap)

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
    outputMessage("Вернитесь в машину, чтобы продолжить гонку.", source)
    Race.leftVehicleTimer[source] = Timer(function (player)
      outputMessage("Вы вышли из машины. Участие в гонке отменено.", player)
      Race.leave(player)
    end, RACE_LEFT_VEHICLE_TIME * 1000, 1, source)
  end
end)

addEventHandler("Race.onConfirm", resourceRoot, function (confirmed)
  if confirmed then
    if client:getMoney() < PRIZE_POOL_FEE then
      outputMessage("Недостаточно денег для участия в гонке.", client)
      return
    end

    Race.join(client)
    outputMessage("Вы присоединились к гонке.", client)

    if Race.waiting then
      outputMessage("Ожидайте начала.", client)
      local waitingTime = Race.waitingTimer:getDetails()
      triggerClientEvent(client, "Race.startWaiting", resourceRoot, waitingTime)
    end
  else
    outputMessage("Вы отказались от участия в гонке.", source)
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
        outputMessage("Ваша машина уничтожена. Участие в гонке отменено.", player)
        Race.leave(player)
        break
      end
    end
  end
end)