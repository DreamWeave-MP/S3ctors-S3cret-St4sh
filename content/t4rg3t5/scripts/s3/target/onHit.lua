---@omw-context local

do
  local I = require 'openmw.interfaces'
  local Me, TargetIsPlayer = I.s3.lf.object, require('openmw.types').Player.objectIsInstance
  local SendEvent = Me.sendEvent

  ---@param attackInfo openmw.interfaces.Combat.AttackInfo
  local function T4AttackHandler(attackInfo)
    local attacker = attackInfo.attacker
    if not attackInfo.successful or not attacker or not TargetIsPlayer(attacker) then return end

    SendEvent(attacker, 'S3TargetLockHit', Me)
  end

  I.Combat.addOnHitHandler(T4AttackHandler)
end
