-- Module to define a base state for state management
local BaseState = {}

-- Function to create a new state instance
function BaseState.new()
    local state = {} -- Initialize a new state table
    state.name = "base" -- Set the name of the state to "base"
    local target -- Variable to hold a reference to the target object

    -- Function to set the target for this state
    function state:setTarget(_target)
        target = _target -- Assign the provided target to the local variable
    end

    -- Function to handle logic when entering this state
    function state:enter() 
        -- Placeholder for entering logic (can be overridden)
    end

    -- Function to handle logic when exiting this state
    function state:exit() 
        -- Placeholder for exiting logic (can be overridden)
    end

    -- Function to update the state each frame
    function state:update(dt)
        -- Placeholder for update logic (can be overridden)
    end

    return state -- Return the newly created state instance
end

return BaseState -- Return the module
