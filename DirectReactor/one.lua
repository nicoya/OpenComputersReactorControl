local term = require("term")
local comp = require("component")
local reac = comp.getPrimary("br_reactor")

local targetPower = reac.getEnergyCapacity() * 0.9
local powerChangeRodInsertCoef = -0.001
local targetPowerChangeCoef = 0.005
local lastPower = reac.getEnergyStored()
local rodCount = reac.getNumberOfControlRods()

function adjReac()
  local currentPower = reac.getEnergyStored()
  print("Current Power: " .. currentPower)
  local powerChange = currentPower - lastPower
  print("Power Change: " .. powerChange)
  lastPower = currentPower
  local targetPowerChange = (targetPower - currentPower) * targetPowerChangeCoef
  print("Target Power Change: " .. targetPowerChange)
  local currentRodInsert = reac.getControlRodLevel(0)
  local rodAdj = (targetPowerChange - powerChange) * powerChangeRodInsertCoef
  local newRodLevel = math.min(100, math.max(0, currentRodInsert + rodAdj))
  print("Rod Insertion: " .. newRodLevel)

  for i = 0, rodCount - 1 do
    reac.setControlRodLevel(i, newRodLevel)
  end
end

function main()
  while true do
    term.clear()
    adjReac()
    os.sleep(0.1)
  end
end

main()
