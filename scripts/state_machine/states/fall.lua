local BaseState = {}

function BaseState.new()
    local state = {}
    state.name = "fall"
    local target
    function state:setTarget(_target)
        target = _target
    end

    function state:enter()
        target.gravityScale = 4
        target:setAnimation(state.name)
    end

    function state:exit() 
        target:fallSquash()
        target.gravityScale = 1
    end

    function state:update(dt)
        if target.isGrounded then
            if target.vx ~= 0 then
                return "walk"
            end

            return "idle"
        end

        target.vx = target.airSpd * target.faceDir * dt
    end

    return state
end

return BaseState