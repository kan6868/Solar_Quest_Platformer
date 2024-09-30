--[[

Explanation:
    Module Setup: Initializes the player module and imports necessary modules.
    
    Sprite Sheet: Creates a sprite sheet and defines animation sequences for different actions.
    
    Movement Constants: Sets constants for various movement speeds and forces.
    
    Player Creation: Defines the new function to create a new player instance, setting initial properties and physics bodies.
    
    State Management: Integrates with the state manager to handle different player states.
    
    Physics and Collision: Defines functions to manage physics bodies and check for collisions with the ground.
    
    Animation Control: Functions to set animations and handle jump/stretch animations.
    
    Update Function: Handles player movement, input, and updates the state manager.
    
    Getter Functions: Provides access to speed constants.

]]

-- Module to create and manage the player character
local M = {}
local StateManager = require("scripts.state_machine.state_manager")  -- Import the state manager
local SheetMaker = require("scripts.libs.sheetMaker")  -- Import the sheet maker

-- Create a sprite sheet for the player
local sheetData = SheetMaker.createSheet(5, 9, 192, 256)
local sheet = graphics.newImageSheet("images/robot.png", sheetData)  -- Load the sprite sheet

-- Define animation sequences for the player
local sequenceData =
{
    {
        name = "idle",
        frames = { 1 }, -- frame index for idle animation
    },
    {
        name = "walk",
        start = 37,
        count = 7,
        time = 750 -- duration of the walk animation
    },
    {
        name = "jump",
        frames = { 2 } -- frame index for jump animation
    },
    {
        name = "fall",
        frames = { 3 } -- frame index for fall animation
    },
    {
        name = "dash",
        frames = { 11 } -- frame index for dash animation
    },
    {
        name = "run",
        frames = { 25, 26, 27 }, -- frames for run animation
        time = 250 -- duration of the run animation
    }
}

-- Define movement constants
local GROUND_SPD = 20   -- Ground speed
local AIR_SPD = 40      -- Air speed
local DASH_SPD = 100     -- Dash speed
local JUMP_FORCE = 800   -- Jump force

local DASH_TIME = 300    -- Duration of the dash

-- Function to create a new player instance
function M.new(x, y)
    local player = display.newSprite(sheet, sequenceData) -- Create a new sprite for the player
    player.anchorY = 1  -- Set the anchor point for the sprite
    player.x, player.y = x, y -- Set the initial position of the player

    -- Initialize player properties
    player.spd = GROUND_SPD
    player.airSpd = AIR_SPD
    player.faceDir = 0  -- Facing direction
    player.isGrounded = false -- Ground state
    player.isRunning = false -- Running state

    StateManager.init(player) -- Initialize the state manager for the player

    local debugGroundBox = nil -- Variable for debugging ground box

    -- Define normal body properties for physics
    local normalBody = {
        box = {
            halfWidth = 40,
            halfHeight = 80,
            x = 0,
            y = -80
        },
        bounce = 0
    }

    -- Define dash body properties for physics
    local dashBody = {
        box = {
            halfWidth = 40,
            halfHeight = 40,
            x = 0,
            y = -40
        },
        friction = 0,
        bounce = 0
    }

    physics.addBody(player, "dynamic", normalBody) -- Add physics body to the player
    player.isFixedRotation = true -- Prevent rotation of the player

    -- Function to set the normal body properties
    function player:setNormalBody()
        if physics.removeBody(player) then
            physics.addBody(player, "dynamic", normalBody)
            player.isFixedRotation = true
        end
    end

    -- Function to set the dash body properties
    function player:setDashBody()
        if physics.removeBody(player) then
            physics.addBody(player, "dynamic", dashBody)
            player.isFixedRotation = true
        end
    end

    -- Function to set the animation for the player
    function player:setAnimation(anim)
        if player.sequence == anim then
            return false -- No change if the animation is the same
        end

        player:setSequence(anim) -- Set the new animation sequence
        player:play() -- Play the animation
    end

    -- Function to draw a debug line for overlaps
    function player:drawDebug(upperX, upperY, lowerX, lowerY)
        if debugGroundBox then
            debugGroundBox:removeSelf() -- Remove the previous debug box
            debugGroundBox = nil
        end

        debugGroundBox = display.newLine(upperX, upperY, lowerX, lowerY) -- Draw a new debug line
        debugGroundBox.strokeWidth = 3 -- Set the line width
    end

    -- Function to check for overlaps at the player's footer
    function player:overlapAtFooter(query)
        local upperX = player.x - 40
        local upperY = player.y

        local lowerX = player.x + 40
        local lowerY = player.y + 2

        player:drawDebug(upperX, upperY, lowerX, lowerY) -- Debug output
        
        local hits = physics.queryRegion(upperX, upperY, lowerX, lowerY) -- Query physics for overlapping objects
        local queryResult = false
        if (hits) then
            -- Output the results
            for _, hitObject in ipairs(hits) do
                queryResult = query(hitObject) -- Check for query conditions
                if queryResult then
                    return queryResult -- Return the result if found
                end
            end
        end
        
        return false -- No overlaps found
    end

    -- Function to check if the player is on the ground
    function player:onGround()
        return player:overlapAtFooter(function (obj)
            if obj.isPlatform then
                return true -- Return true if the object is a platform
            end
        end)
    end

    -- Function to update the player's state
    function player:update(dt)
        local vx, vy = player:getLinearVelocity() -- Get current velocity
        
        player.vx = vx
        player.vy = vy
        player.isGrounded = player:onGround() -- Update grounded state

        if Keyboard.justPressed("right") then
            player.faceDir = 1 -- Face right
        end

        if Keyboard.justPressed("left") then
            player.faceDir = -1 -- Face left
        end

        if player.isGrounded then
            if not Keyboard.pressed("left") and not Keyboard.pressed("right") then
                player.faceDir = 0 -- Stop facing direction if no keys pressed
            end
        end

        if player.faceDir ~= 0 then
            player.xScale = player.faceDir -- Flip the sprite based on direction
        end

        StateManager.update(dt) -- Update the state manager

        if Keyboard.justPressed("w") and player.isGrounded then
            player:jumpStretch() -- Trigger jump if grounded
            player.isReadyJumping = true
        end
        
        player:setLinearVelocity(player.vx, player.vy) -- Set the player's linear velocity
    end

    -- Function for jump stretching animation
    function player:jumpStretch(time)
        local time = time or 150
        transition.to(player, {yScale = .4, time = time * .67, onComplete = function ()
            player.vy = -JUMP_FORCE -- Apply jump force
            player.isReadyJumping = false
            player:setLinearVelocity(player.vx, player.vy) 
            transition.to(player, {yScale = 1, time = time * .33, transition = easing.outBack}) -- Reset scale
        end})
    end

    -- Function for fall squash animation
    function player:fallSquash(time)
        local time = time or 200
        local face = player.xScale / math.abs(player.xScale) -- Determine facing direction
        transition.to(player, {xScale = 1.25 * face, yScale = .75, time = time * .875, transition = easing.outBack, onComplete = function ()
            transition.to(player, {yScale = 1, xScale = 1 * face, time = time * .125}) -- Reset scale after squash
        end})
    end

    -- GETTER functions for player speeds
    player.getGroundSpeed = function ()
        return GROUND_SPD
    end

    player.getAirSpeed = function ()
        return AIR_SPD
    end

    player.getDashSpeed = function ()
        return DASH_SPD
    end

    player.getDashTime = function ()
        return DASH_TIME
    end

    return player -- Return the created player instance
end

return M -- Return the module
