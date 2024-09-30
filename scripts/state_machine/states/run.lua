local BaseState = {}

function BaseState.new()
  
    local state = {}
    state.name = "run"
    local target
    function state:setTarget(_target)
        target = _target
    end

    function state:enter() -- emit
        target.spd = target.getGroundSpeed() * 2
        target:setAnimation(state.name)
    end

    function state:exit() -- emit
        target.spd = target.getGroundSpeed()
        target.isRunning = false
    end

    function state:update(dt)
        
        if (target.vy < 0 or target.isJumping) and not target.isGrounded then
            return "jump"
        end
        if not Keyboard.pressed("leftShift") and not Keyboard.pressed("rightShift") then
            target.isRunning = false
            return "walk"
        end
        if target.faceDir == 0 then
            return "idle"
        end

        if not target.isRunning then
            return "walk"
        end

        if Keyboard.justPressed("z") then
            return "dash"
        end
        
        target.vx = target.spd * target.faceDir * dt
    end

    return state
end

return BaseState