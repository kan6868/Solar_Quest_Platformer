-- Module to create sprite sheets
local M = {}

-- Function to create a sprite sheet
function M.createSheet(rows, cols, width, height)
    -- Initialize a table to hold the frame data
    local sheetData = {
        frames = {}
    }

    -- Variables to track the current position of frames
    local x = 0
    local y = 0

    -- Dimensions for each frame
    local width = width
    local height = height

    -- Loop through the specified number of rows and columns to populate the sheet data
    for r = 1, rows do
        for c = 1, cols do
            local idx = #sheetData.frames + 1 -- Get the next index for the frame
            sheetData.frames[idx] = { -- Add a new frame to the frames table
                x = x, -- X position of the frame
                y = y, -- Y position of the frame
                width = width, -- Width of the frame
                height = height -- Height of the frame
            }

            x = x + width -- Move the X position to the right for the next frame
        end
        y = y + height -- Move the Y position down for the next row
        x = 0 -- Reset X position for the new row
    end

    return sheetData -- Return the populated sheet data
end

return M -- Return the module
