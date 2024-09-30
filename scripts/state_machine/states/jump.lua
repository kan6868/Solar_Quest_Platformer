local BaseState = {}

function BaseState.new()
    local state = {}
    state.name = "jump"
    local target
    function state:setTarget(_target)
        target = _target
    end

    function state:enter() 
        target.gravityScale = 3

        target:setAnimation(state.name)
    end

    function state:exit() 
        target.gravityScale = 1
        target.isJumping = false -- reset jump
    end

    function state:update(dt)
    
        if target.isGrounded then
            return "idle"
        end

        if not target.isGrounded and target.vy > 0 then
            return "fall"
        end
    
        target.vx = target.airSpd * target.faceDir * dt
    end

    return state
end

return BaseState