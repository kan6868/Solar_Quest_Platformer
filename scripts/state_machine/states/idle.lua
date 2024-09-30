local BaseState = {}

function BaseState.new()
    local state = {}
    state.name = "idle"
    local target
    function state:setTarget(_target)
        target = _target
    end

    function state:enter()
        target:setAnimation("idle")
    end

    function state:exit()
    end

    function state:update(dt)
        if target.isReadyJumping then
            return false
        end

        if not target.isGrounded then
            if target.vy < 0 then
                return "jump"
            end

            if target.vy > 0 then
                return "fall"
            end
        end


        if target.faceDir ~= 0 then
            return "walk"
        end

        target.vx = 0
    end

    return state
end

return BaseState
