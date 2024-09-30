local BaseState = {}

function BaseState.new()
    local state = {}
    state.name = "dash"
    
    local target

    local t_dashing
    
    local currentFaceDir = 0

    function state:setTarget(_target)
        target = _target
    end

    function state:enter() 
        target:setDashBody()
        target:setAnimation(state.name)
        target.spd = target.getDashSpeed() 
        
        t_dashing = target.getDashTime() -- reset timer
        
        currentFaceDir = target.faceDir
        target.xScale = target.faceDir
    end

    function state:exit()  
        target.spd = target.getGroundSpeed()
        target:setNormalBody()
    end

    function state:update(dt)
        t_dashing = t_dashing - dt
        
        if t_dashing <= 0 then
            return "idle"
        end

        if target.vx == 0 then
            return "idle"
        end

        if target.isJumping then
            return "jump"
        end

        target.vx = target.spd * currentFaceDir * dt
    end

    return state
end

return BaseState