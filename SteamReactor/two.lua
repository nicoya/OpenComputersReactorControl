local term = require("term")
local comp = require("component")
local reac = comp.getPrimary("br_reactor")
local turbs = comp.list("br_turbine")

local targetSteam = reac.getHotFluidAmountMax() * 0.5
local minCoolant = reac.getCoolantAmountMax() * 0.1
local rodCount = reac.getNumberOfControlRods()
local targetSteamChangeCoef = 0.01
local steamChangeTempCoef = 0.1
local targetTempChangeCoef = 0.1
local tempRodCoef = -1
local targetTemp = 250

local lastTemp = reac.getCasingTemperature()
local lastSteam = reac.getHotFluidAmount()

function adjReac()
  local currentTemp = reac.getCasingTemperature()
  if reac.getCoolantAmount() < minCoolant then
    targetTemp = 200
  else
    local currentSteam = reac.getHotFluidAmount()
    local steamChange = currentSteam - lastSteam
    lastSteam = currentSteam
    local targetSteamChange = (targetSteam - currentSteam) * targetSteamChangeCoef
    local tempAdj = (targetSteamChange - steamChange) * steamChangeTempCoef
    targetTemp = currentTemp + tempAdj
  end

  local tempChange = currentTemp - lastTemp
  lastTemp = currentTemp
  local targetTempChange = (targetTemp - currentTemp) * targetTempChangeCoef

  print("Target Temperature: " .. targetTemp)
  print("Current Temperature: " .. currentTemp)

  rodAdj = (targetTempChange - tempChange) * tempRodCoef
  local currentRodInsert = reac.getControlRodLevel(0)
  local newRodLevel = math.min(100, math.max(0, currentRodInsert + rodAdj))

  print("Rod Insertion: " .. newRodLevel)

  for i = 0, rodCount - 1 do
    reac.setControlRodLevel(i, newRodLevel)
  end
end

local turbRpmSteamCoef = 1
local turbRpmTarg = 1800

function adjTurb(turbID)
  local turb = comp.proxy(turbID)

  local currentRpm = turb.getRotorSpeed();
  local rfFrac = turb.getEnergyStored() / turb.getEnergyCapacity()

  if currentRpm < (turbRpmTarg - 100) or rfFrac > 0.6 then
    turb.setInductorEngaged(false)
  elseif rfFrac < 0.4 then
    turb.setInductorEngaged(true)
  end

  if turb.getInductorEngaged() then
    print("Inductor ENGAGED")
  else
    print("Inductor DISENGAGED")
  end

  local steamAdj = (turbRpmTarg - currentRpm) * turbRpmSteamCoef
  local steamRate = turb.getFluidFlowRate()
  local newSteamRate = math.max(0, math.min(2000, steamRate + steamAdj))
  turb.setFluidFlowRateMax(newSteamRate)
  print("Turbine Steam Rate: " .. newSteamRate)
end

function main()
  while true do
    term.clear()
    adjReac()
    for turbId,turbType in turbs do
      adjTurb(turbId)
    end
    os.sleep(0.1)
  end
end

main()
