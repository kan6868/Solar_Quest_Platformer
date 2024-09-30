local BaseState = {}

function BaseState.new()
  
    local state = {}
    state.name = "walk"
    local target
    function state:setTarget(_target)
        target = _target
    end

    function state:enter() -- emit
        target:setAnimation("walk")
    end

    function state:exit() -- emit
        
    end

    function state:update(dt)
        
        if target.vy < 0 and not target.isGrounded then
            return "jump"
        end

        if target.faceDir == 0 then
            return "idle"
        end

        if Keyboard.pressed("leftShift") or Keyboard.pressed("rightShift") then
            target.isRunning = true
            return "run"
        end

        target.vx = target.spd * target.faceDir * dt
    end

    return state
end

return BaseState