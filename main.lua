-- Get the center coordinates of the display
_CX, _CY = display.contentCenterX, display.contentCenterY

-- Require the keyboard module for input handling
Keyboard = require("scripts.libs.keyboard")

-- Require the player module to create player instances
local Player = require "scripts.player"

-- Start the physics engine and set gravity
local physics = require("physics")
physics.start()
physics.setGravity(0, 16) -- Set gravity to pull downwards

-- Create a new player instance at the center of the display
local player = Player.new(_CX, _CY)

-- Create a platform for the player to stand on
local platform = display.newRect(_CX, 1050, 2500, 200) -- Create a rectangular platform
physics.addBody(platform, "static", {bounce = 0 }) -- Add a static physics body to the platform

-- Mark the platform as a platform for collision detection
platform.isPlatform = true

-- Variable to track the time for frame updates
local timeOnFrame = 0

-- Function to update the game state on each frame
local function update(event)
    local dt = event.time - timeOnFrame -- Calculate the delta time since the last frame
    timeOnFrame = event.time -- Update the timeOnFrame to the current time

    player:update(dt) -- Update the player with the calculated delta time
end

-- Add an event listener to update the game state on each frame
Runtime:addEventListener("enterFrame", update)
