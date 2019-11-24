addEvent("Race.onConfirm", true)

Race = {}

Race.waiting = false
Race.started = false
Race.participants = {}
Race.checkpoints = {}

Race.currentCheckpoint = {}
Race.currentCheckpointMarker = {}
Race.nextCheckpointMarker = {}

function Race.prepare()
  -- Pick random track
  local track = Tracks.list[math.random(1, #Tracks.list)]

  Race.prizePool = 0

  Race.trackName = Tracks.getName(track)
  Race.checkpoints = Tracks.getCheckpoints(track)

  Race.startMarker = Marker(Race.checkpoints[1][1], Race.checkpoints[1][2], Race.checkpoints[1][3])
  Race.startBlip = Blip(Race.checkpoints[1][1], Race.checkpoints[1][2], Race.checkpoints[1][3], 53)

  Race.waiting = true
  Race.waitingTimer = Timer(Race.start, RACE_DELAY * 1000, 1)
  Race.updateWaitingTimer = Timer(function ()
    local waitingTime = math.floor(Race.waitingTimer:getDetails() / 1000)
    triggerClientEvent(Race.participants, "Race.updateWaitingTime", resourceRoot, waitingTime)
  end, 3000, 0)

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

  for i, participant in pairs(Race.participants) do
    participant.vehicle:setFrozen(false)
    toggleAllControls(participant, true, true, false)
  end
  
  if isTimer(Race.waitingTimer) then
    Race.waitingTimer:destroy()
  end
  if isTimer(Race.updateWaitingTimer) then
    Race.updateWaitingTimer:destroy()
  end
  if isTimer(Race.endTimer) then
    Race.endTimer:destroy()
  end
  if isElement(Race.startMarker) then
    Race.startMarker:destroy()
  end
  if isElement(Race.startBlip) then
    Race.startBlip:destroy()
  end
  
  Race.waitingTimer = nil
  Race.updateWaitingTimer = nil
  Race.endTimer = nil
  Race.startMarker = nil
  Race.startBlip = nil
  
  Race.prizePool = nil
  Race.trackName = nil
  Race.checkpoints = {}
  Race.participants = {}
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
    local firstCheckpoint = Race.checkpoints[1]
    local secondCheckpoint = Race.checkpoints[2]

    local _, _, directionZ = findRotation3D(firstCheckpoint[1], firstCheckpoint[2], firstCheckpoint[3], secondCheckpoint[1], secondCheckpoint[2], secondCheckpoint[3])
    participant.vehicle:setPosition(firstCheckpoint[1], firstCheckpoint[2], firstCheckpoint[3] + 0.5)
    participant.vehicle:setRotation(0, 0, directionZ)
    participant.vehicle:setFrozen(true)
    participant:setCameraTarget()
    toggleAllControls(participant, false, true, false)

    triggerClientEvent(participant, "Race.onStart", resourceRoot)
  end

  outputChatBox("Гонка " .. Race.trackName .. " началась. Призовой фонд $" .. numberFormat(Race.prizePool, ' ') .. ".", root, unpack(CHAT_MESSAGES_COLOR))
  outputChatBox("Вы ещё можете успеть присоединиться к гонке.", root, unpack(CHAT_MESSAGES_COLOR))

  Race.endTimer = Timer(function ()
    Race.stop()
  end, RACE_DURATION * 1000, 1)

  Race.started = true
end

function Race.join(player)
  for i, participant in pairs(Race.participants) do
    if participant == player then
      return
    end
  end

  table.insert(Race.participants, player)
end

function Race.leave(player)
  for i, participant in pairs(Race.participants) do
    if participant == player then
      table.remove(Race.participants, i)
      break
    end
  end
end

function Race.isJoined(player)
  for i, participant in pairs(Race.participants) do
    if participant == player then
      return true
    end
  end

  return false
end

function Race.increasePrizePool(amount)
  if Race.prizePool then
    Race.prizePool = Race.prizePool + amount
  end
end

addEventHandler("onPlayerMarkerHit", root, function (markerHit, matchingDimension)
  if matchingDimension then
    if Race.isJoined(source) then
      outputChatBox("Вы уже участвуете в гонке. Ожидайте начала.", source, unpack(CHAT_MESSAGES_COLOR))
      return
    end
    if Race.waiting and markerHit == Race.startMarker then
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
end)

addEventHandler("onPlayerMarkerLeave", root, function (markerLeft, matchingDimension)

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
      local waitingTime = math.floor(Race.waitingTimer:getDetails() / 1000)
      triggerClientEvent(client, "Race.startWaiting", resourceRoot, waitingTime)
    elseif Race.started then

    end
  else
    outputChatBox("Вы отказались от участия в гонке.", source, unpack(CHAT_MESSAGES_COLOR))
  end
end)

addEventHandler("onPlayerQuit", root, function ()
  Race.leave(source)
end)