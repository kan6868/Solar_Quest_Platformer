--[[
Explanation:
    StateManager: A table containing methods to manage states.

    state_pool: A table containing different states initialized from separate modules.
    
    currentState: The current state of the player object.
    
    init: Initializes the state for the player and sets the target object for the states.
    
    changeState: Changes the current state to a new state, calling the corresponding enter and exit methods.
    
    update: Updates the current state and checks if it needs to transition to a new state.
]]

-- Initialize a StateManager table to manage states
local StateManager = {}

-- Create a state_pool table containing different states for the player
local state_pool = {
    idle = require("scripts.state_machine.states.idle").new(),  -- Idle state
    walk = require("scripts.state_machine.states.walk").new(),  -- Walk state
    jump = require("scripts.state_machine.states.jump").new(),  -- Jump state
    fall = require("scripts.state_machine.states.fall").new(),  -- Fall state
    dash = require("scripts.state_machine.states.dash").new(),  -- Dash state
    run = require("scripts.state_machine.states.run").new()      -- Run state
}

-- Initialize the current state to 'idle'
local currentState = state_pool.idle

-- Function to initialize the StateManager, takes the player object as an argument
function StateManager.init(player)
    -- Set the player target for all states in the state_pool
    for _, state in pairs(state_pool) do
        state:setTarget(player)
    end

    -- Change to 'idle' state upon initialization
    StateManager.changeState(currentState)
end

-- Function to change the state, takes the new state name as an argument
function StateManager.changeState(name)
    -- Check if the new state exists in state_pool
    if not state_pool[name] then return false end

    -- If the current state is already the new state, do not change
    if currentState.name == name then return false end
    
    -- Call the exit function of the current state before transitioning
    if currentState then
        currentState:exit() -- Exit the current state
    end

    -- Update the current state to the new state
    currentState = state_pool[name]
    currentState:enter() -- Enter the new state
end

-- Function to update the state, takes delta time (dt) as an argument
function StateManager.update(dt)
    -- Call the update function of the current state
    local newState = currentState:update(dt)

    -- If a new state is returned, change to that state
    if newState then
        StateManager.changeState(newState)
    end
end

-- Return the StateManager table
return StateManager