addEvent("Race.onConfirm", true)
addEvent("Race.onFinishLap", true)

Race = {}

Race.waiting = false
Race.started = false

Race.participants = {}
Race.participantAccounts = {}
Race.participantNames = {}
Race.vehicles = {}
Race.bestLapVehicleName = {}

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
  Race.participantAccounts = {}
  Race.participantNames = {}
  Race.vehicles = {}
  Race.bestLapVehicleName = {}

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

  Race.endTimer = Timer(Race.onEnd, RACE_DURATION * 1000, 1)

  -- Sync time with clients
  Race.updateLapTimer = Timer(function ()
    for i, participant in pairs(Race.participants) do
      if Race.lapStartTime[participant] then
        local lapTime = getTickCount() - Race.lapStartTime[participant]
        triggerClientEvent(participant, "Race.updateLapTime", resourceRoot, lapTime)
      end
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

  outputMessage("Гонка " .. Race.trackName .. " началась. Призовой фонд " .. numberFormat(Race.prizePool, ' ') .. " руб.")
  outputMessage("Вы ещё можете успеть присоединиться к гонке.")

  Race.waiting = false
  Race.started = true
end

function Race.givePrize(account, amount)
  local player = account:getPlayer()
  if player then
    player:giveMoney(amount)

    outputDebugString(string.format("[Circuit Race] Player %s (%s, %s RUB) won race and earned %s",
      player.name,
      account.name,
      tostring(player.money),
      tostring(amount)))
  else
    exports.bank:giveAccountBankMoney(account, amount, "RUB")

    outputDebugString(string.format("[Circuit Race] Offline player (%s) won race and earned %s (added to bank)", account.name, tostring(amount)))
  end
end

function Race.onEnd()
  outputMessage("Гонка окончена.")

  Race.prizePool = #Race.participantAccounts * PRIZE_POOL_FEE
  -- Commission
  Race.prizePool = Race.prizePool * (1 - PRIZE_COMMISSION / 100)
  
  -- Top
  local topPlayers = {}
  for account, lapTime in pairs(Race.bestLapTime) do
    table.insert(topPlayers, {account = account, name = Race.participantNames[account], time = lapTime, vehicle = Race.bestLapVehicleName[account]})
  end

  -- Sort
  for i = 1, TOP_PLAYER_COUNT do
    local minValue = topPlayers[i]
    for j = i + 1, #topPlayers do
      if topPlayers[j] < minValue then
        minValue = topPlayers[j]
        topPlayers[i], topPlayers[j] = topPlayers[j], topPlayers[i]
      end
    end
  end

  -- Give prizes
  for i, player in pairs(topPlayers) do
    if i <= TOP_PLAYER_COUNT then
      if i <= WINNER_COUNT then
        player.prize = math.floor(Race.prizePool * PRIZE_COEFFS[i] / 100)
        if player.account then
          Race.givePrize(player.account, player.prize)
        end
      else
        player.prize = 0
      end
    else
      topPlayers[i] = nil
    end
  end

  if #topPlayers > 0 then
    outputMessage("Победители:")
    local topCount = math.min(WINNER_COUNT, #topPlayers)
    for i = 1, topCount do
      local time = ("%d:%02d.%03d"):format(topPlayers[i].time / 1000 / 60, topPlayers[i].time / 1000 % 60, topPlayers[i].time % 1000)
      outputMessage(("%d. %s на %s %s(%s, %s руб.)"):format(
        i, removeHexFromString(topPlayers[i].name), topPlayers[i].vehicle, ACCENT_COLOR_HEX, time, numberFormat(topPlayers[i].prize, ' ')))

      local player = topPlayers[i].account:getPlayer()
      if player then
        outputMessage(("Поздравляем! Вы заняли %d место в гонке и получили %s%s руб."):format(
          i, ACCENT_COLOR_HEX, numberFormat(topPlayers[i].prize, ' ')), player)
      end
    end
  else
    outputMessage("Нет результатов, так как никто не завершил круг.")
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

  if Race.isInRace(player) then
    return
  end

  local joined = Race.isJoined(player)

  table.insert(Race.participants, player)
  if not joined then
    table.insert(Race.participantAccounts, playerAccount)
    Race.participantNames[playerAccount] = player.name
  end

  Race.vehicles[player] = player.vehicle

  Race.startMarker:setVisibleTo(player, true) -- bug workaround
  Race.startMarker:setVisibleTo(player, false)

  triggerClientEvent(player, "Race.onJoin", resourceRoot, Race.bestLapTime[playerAccount], Race.bestPlayerName, Race.bestPlayerTime)
  if Race.started then
    if not joined then
      player:takeMoney(PRIZE_POOL_FEE)
      outputMessage("Вы заплатили " .. numberFormat(PRIZE_POOL_FEE, ' ') .. " руб. за участие в гонке.", player)
    end

    Race.spawnPlayer(player)
    local timeLeft = Race.endTimer:getDetails()
    triggerClientEvent(player, "Race.onStart", resourceRoot, Race.trackName, Race.checkpoints, timeLeft)
  end
end

function Race.leave(player)
  if isTimer(Race.leftVehicleTimer[player]) then
    Race.leftVehicleTimer[player]:destroy()
  end
  Race.leftVehicleTimer[player] = nil

  Race.vehicles[player] = nil

  Race.lapStartTime[player] = nil

  for i, participant in pairs(Race.participants) do
    if participant == player then
      table.remove(Race.participants, i)
      break
    end
  end

  if Race.waiting then
    local playerAccount = player:getAccount()
    for i, participantAccount in pairs(Race.participantAccounts) do
      if participantAccount == playerAccount then
        table.remove(Race.participantAccounts, i)
        break
      end
    end
  end

  if Race.startMarker then
    Race.startMarker:setVisibleTo(player, true)
  end

  triggerClientEvent(player, "Race.onLeave", resourceRoot)
end

function Race.isJoined(player)
  local account = player:getAccount()
  for i, participantAccount in pairs(Race.participantAccounts) do
    if participantAccount == account then
      return true
    end
  end

  return false
end

function Race.isInRace(player)
  return Race.lapStartTime[player] and true or false
end

function Race.onStartMarkerHit(source, matchingDimension)
  if source.type == "player" and matchingDimension then
    if Race.waiting or Race.started then
      local playerAccount = source:getAccount()
      if playerAccount:isGuest() then
        return
      end

      if Race.isJoined(source) then
        if not Race.waiting and not Race.isInRace(source) then
          Race.join(source)
        end
      elseif not isDriver(source) then
        outputMessage("Вы должны быть в машине, чтобы принять участие в гонке.", source)
      elseif source:getMoney() < PRIZE_POOL_FEE then
        outputMessage("Недостаточно денег для участия в гонке.", source)
      else
        toggleAllControls(source, false, true, false)
        triggerClientEvent(source, "Race.askConfirmation", resourceRoot)
      end
    end
  end
end

function Race.onFinishLap()
  local player = client
  local playerAccount = player:getAccount()
  if not playerAccount then
    return
  end

  -- Calculate lap time
  local newLapStartTime = getTickCount()
  local elapsedTime = newLapStartTime - Race.lapStartTime[player]
  Race.lapStartTime[player] = newLapStartTime

  -- Calculate best lap time
  if not Race.bestLapTime[playerAccount] or elapsedTime < Race.bestLapTime[playerAccount] then
    Race.bestLapTime[playerAccount] = elapsedTime
    -- Race.bestLapVehicleName[playerAccount] = Race.vehicles[player].name
    Race.bestLapVehicleName[playerAccount] = exports.car_system:getVehicleModName(Race.vehicles[player].model)
  end
  -- Determine the best player
  if not Race.bestPlayerName or elapsedTime < Race.bestPlayerTime then
    Race.bestPlayerName = player.name
    Race.bestPlayerTime = elapsedTime
    for i, participantAccount in pairs(Race.participants) do
      triggerClientEvent(Race.participants, "Race.onLapRecord", resourceRoot, Race.bestPlayerName, Race.bestPlayerTime)
    end
  end
  triggerClientEvent(player, "Race.onFinishLap", resourceRoot, elapsedTime, Race.bestLapTime[playerAccount])
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

addEventHandler("onPlayerChangeNick", root, function (oldNick, newNick)
  local playerAccount = source:getAccount()
  if playerAccount and Race.participantNames[playerAccount] then
    Race.participantNames[playerAccount] = newNick
  end
end)
