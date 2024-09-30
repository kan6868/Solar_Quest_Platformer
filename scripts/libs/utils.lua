local utils = {}
local json = require "json"
local composer = require "composer"
-- local SpineWrapper = require ("scripts.libs.spineWrapper")
-- Localised global functions.
local getTimer = system.getTimer
local dRemove = display.remove
local random = math.random
local floor = math.floor
local reverse = string.reverse
local gmatch = string.gmatch
local format = string.format
local find = string.find
local gsub = string.gsub
local sub = string.sub
local len = string.len
local rep = string.rep
local tonumber = tonumber
local tostring = tostring
local pairs = pairs
local type = type

--------------------------------------------------------------------------------------------------
-- utils
--------------------------------------------------------------------------------------------------

local _defaultLocation = system.DocumentsDirectory
local _realDefaultLocation = _defaultLocation
local _validLocations = {
    [system.DocumentsDirectory] = true,
    [system.CachesDirectory] = true,
    [system.TemporaryDirectory] = true,
    [system.ResourceDirectory] = true
}


function utils.createEmitter(path, mode)
    local mode = mode or system.ResourceDirectory


    local filePath = system.pathForFile(path, mode)
    local f = io.open(filePath, "r")

    local emitterData = f:read("*a")
    f:close()

    -- Decode the string
    local emitterParams = json.decode(emitterData)

    return emitterParams
end

function utils.getCurrentScene()
    return composer.getScene(composer.getSceneName("current"))
end

function utils.pointInBounds(x, y, object)
    local bounds = object.contentBounds
    if not bounds then
        print("Not Bounds")
        return false
    end
    -- print(bounds.xMin, x, bounds.xMax)
    -- print(bounds.yMin, y, bounds.yMax)
    if x > bounds.xMin and x < bounds.xMax and y > bounds.yMin and y < bounds.yMax then
        return true
    else
        return false
    end
end

function utils.getSheet(row, col, width, height, sheetWidth, sheetHeight, path)
    local row = row or 1
    local col = col or 1
    if row <= 0 and col <= 0 then return false end
    local sheet = {
        frames = {

        },
        sheetContentWidth = sheetWidth,
        sheetContentHeight = sheetHeight
    }

    for r = 1, row do
        for c = 1, col do
            sheet.frames[#sheet.frames + 1] = {
                x = 0 + (width * (c - 1)),
                y = 0 + (height * (r - 1)),
                width = width,
                height = height
            }
        end
    end
    return graphics.newImageSheet(path, sheet)
end

---Save file *.json from table
---@param t table
---@param filename string
---@param location any
---@return boolean
function utils.saveTable(t, filename, location)
    if location and (not _validLocations[location]) then
        error("Attempted to save a table to an invalid location", 2)
    elseif not location then
        location = _defaultLocation
    end

    local path = system.pathForFile(filename, location)
    local file = io.open(path, "w")
    if file then
        local contents = json.prettify(json.encode(t))
        file:write(contents)
        io.close(file)
        return true
    else
        return false
    end
end

---Read file *.json
---@param filename string
---@param location any
---@return table
function utils.loadTable(filename, location)
    if location and (not _validLocations[location]) then
        error("Attempted to load a table from an invalid location", 2)
    elseif not location then
        location = _defaultLocation
    end

    local path = system.pathForFile(filename, location)

    local contents = ""
    local myTable = {}
    local file = io.open(path, "r")

    if file then
        -- read all contents of file into a string
        local contents = file:read("*a")
        myTable = json.decode(contents)
        io.close(file)
        return myTable
    else
        print("error loading " .. filename)
        return nil
    end
    return nil
end

function utils.changeDefault(location)
    if location and (not location) then
        error("Attempted to change the default location to an invalid location", 2)
    elseif not location then
        location = _realDefaultLocation
    end
    _defaultLocation = location
    return true
end

function utils.pillShape(object, corner, xScale, yScale)
    if not object.contentWidth or not object.contentHeight then
        return false
    end

    local w, h = object.width, object.height
    local x, y = object.offsetX or 0.5, object.offsetY or 0.5

    local maxCorner = (w < h) and w or h
    corner = corner or (maxCorner * 0.15)
    if corner > maxCorner then corner = maxCorner * 0.5 end

    w = w * 0.5 * (xScale or 1)
    h = h * 0.5 * (yScale or 1)
    local shape = {
        x - w + corner, y - h,
        x + w - corner, y - h,
        x + w, y - h + corner,
        x + w, y + h - corner,
        x + w - corner, y + h,
        x - w + corner, y + h,
        x - w, y + h - corner,
        x - w, y - h + corner
    }

    return shape
end

---Checking file is available or not.
---@param filename string
---@param location any
---@return boolean
function utils.isExists(filename, location)
    if location == nil then location = system.DocumentsDirectory end
    local path = system.pathForFile(filename, location)

    local f = io.open(path, "r")

    if f then
        return true
    else
        return false
    end
end

local function rightToLeft(a, b)
    return (a.x or 0) + (a.width or 0) * 0.5 > (b.x or 0) + (b.width or 0) * 0.5
end

local function leftToRight(a, b)
    return (a.x or 0) + (a.width or 0) * 0.5 < (b.x or 0) + (b.width or 0) * 0.5
end

local function upToDown(a, b)
    return (a.y or 0) + (a.height or 0) * ((1 - a.anchorY) or 0.5) <
        (b.y or 0) + (b.height or 0) * ((1 - b.anchorY) or 0.5)
end

local function downToUp(a, b)
    return (a.y or 0) + (a.height or 0) * ((1 - a.anchorY) or 0.5) >
        (b.y or 0) + (b.height or 0) * ((1 - b.anchorY) or 0.5)
end

function utils.sortDisplayObjects(layerToSort, reverse)
    local objects = {}
    if layerToSort.numChildren then
        for i = 1, layerToSort.numChildren do
            objects[#objects + 1] = layerToSort[i]
        end
        table.sort(objects, reverse and leftToRight or rightToLeft)
        table.sort(objects, reverse and downToUp or upToDown)
    end
    for i = #objects, 1, -1 do
        if objects[i].toBack then
            objects[i]:toBack()
        end
    end
end

function utils.makeTrail(obj, trailStyle)
    local trailStyle = trailStyle or 1
    local ox, oy = obj:localToContent(0.5, 0.5)
    if (obj.trailCount == nil) then
        obj.trailCount = 0
        obj.lastX = ox
        obj.lastY = oy
    end


    -- Fading Squares
    if (trailStyle == 1) then
        -- Draw every 3rd frame (uncomment to reduce particles)
        --[[
		if( obj.trailCount % 3 ~= 0 ) then
			obj.trailCount = obj.trailCount + 1
			return
		end
		obj.trailCount = obj.trailCount + 1
		--]]
        for i = 1, 3 do
            local tmp = display.newRect(obj.parent,
                obj.x + math.random(-2, 2), obj.y + math.random(-2, 2),
                obj.contentWidth / 2, obj.contentHeight / 2)
            tmp.alpha = 0.5
            tmp:setFillColor(0.25, 0.25, 0.25)
            -- tmp:toBack()
            transition.to(tmp, { alpha = 0.05, xScale = 0.5, yScale = 0.5, time = 1000, onComplete = display.remove })
        end

        -- Fading Circles
    elseif (trailStyle == 2) then
        -- Draw every 3rd frame (uncomment to reduce particles)
        --[[
		if( obj.trailCount % 3 ~= 0 ) then
			obj.trailCount = obj.trailCount + 1
			return
		end
		obj.trailCount = obj.trailCount + 1
		--]]
        for i = 1, 3 do
            local tmp = display.newCircle(obj.parent,
                obj.x + math.random(-1, 1), obj.y + math.random(-1, 1),
                obj.contentWidth / 3)
            tmp.alpha = 0.5
            tmp:setFillColor(0.25, 0.25, 0.25)
            -- tmp:toBack()
            transition.to(tmp, { alpha = 0.05, xScale = 0.5, yScale = 0.5, time = 1000, onComplete = display.remove })
        end

        -- Lines
    elseif (trailStyle == 3) then
        -- Draw every 3rd frame (uncomment to reduce particles)
        ----[[
        if (obj.trailCount % 3 ~= 0) then
            obj.trailCount = obj.trailCount + 1
            return
        end
        obj.trailCount = obj.trailCount + 1
        --]]

        local tmp = display.newLine(obj.parent, obj.lastX, obj.lastY, obj.x, obj.y)
        obj.lastX = obj.x
        obj.lastY = obj.y

        tmp.alpha = 0.8
        tmp:setStrokeColor(1, 1, 1)
        -- tmp:toBack()
        tmp.strokeWidth = obj.contentHeight / 4
        transition.to(tmp, { alpha = 0.05, strokeWidth = 1, time = 500, onComplete = display.remove })


        -- Rainbow Fading Squares
    elseif (trailStyle == 4) then
        -- Draw every 3rd frame (uncomment to reduce particles)
        --[[
		if( obj.trailCount % 3 ~= 0 ) then
			obj.trailCount = obj.trailCount + 1
			return
		end
		obj.trailCount = obj.trailCount + 1
		--]]
        for i = 1, 3 do
            local tmp = display.newRect(obj.parent,
                obj.x + math.random(-1, 1), obj.y + math.random(-1, 1),
                obj.contentWidth / 2, obj.contentHeight / 2)
            tmp.alpha = 0.5
            tmp:setFillColor(math.random(), math.random(), math.random())
            -- tmp:toBack()
            transition.to(tmp, { alpha = 0.05, xScale = 0.5, yScale = 0.5, time = 1000, onComplete = display.remove })
        end

        -- Rainbow Fading Circles
    elseif (trailStyle == 5) then
        -- Draw every 3rd frame (uncomment to reduce particles)
        --[[
		if( obj.trailCount % 3 ~= 0 ) then
			obj.trailCount = obj.trailCount + 1
			return
		end
		obj.trailCount = obj.trailCount + 1
		--]]
        for i = 1, 3 do
            local tmp = display.newCircle(obj.parent,
                obj.x + math.random(-2, 2), obj.y + math.random(-2, 2),
                obj.contentWidth / 3)
            tmp.alpha = 0.5
            tmp:setFillColor(math.random(), math.random(), math.random())
            -- tmp:toBack()
            transition.to(tmp, { alpha = 0.05, xScale = 0.5, yScale = 0.5, time = 1000, onComplete = display.remove })
        end

        -- Rainbow Lines
    elseif (trailStyle == 6) then
        -- Draw every 3rd frame (uncomment to reduce particles)
        ----[[
        if (obj.trailCount % 3 ~= 0) then
            obj.trailCount = obj.trailCount + 1
            return
        end
        obj.trailCount = obj.trailCount + 1
        --]]

        local tmp = display.newLine(obj.parent, obj.lastX, obj.lastY, obj.x, obj.y)
        obj.lastX = obj.x
        obj.lastY = obj.y

        tmp.alpha = 0.8
        tmp:setStrokeColor(math.random(), math.random(), math.random())
        -- tmp:toBack()
        tmp.strokeWidth = obj.contentHeight / 2

        transition.to(tmp, { alpha = 0.05, strokeWidth = 1, time = 1000, onComplete = display.remove })
    end
end

function utils.networkConnection()
    local status = network.getConnectionStatus()
    return status ~= nil and status.isConnected
end

local function netListner(event)
    if (event.isError) or event.status >= 400 then
        GB.printDebug("Server is connect = " .. tostring(GB.isConnected), "e")
    elseif (event.phase == "ended") then
        GB.isConnected = true
        GB.printDebug("Server is connect = " .. tostring(GB.isConnected))
    end
end

function utils.testConnection()
    if utils.networkConnection() then
        local request = "https://kzeit.com/"
        GB.printDebug("Network is connected")
        network.request(request, "GET", netListner, { timeout = 2 })
    else
        GB.printDebug("Network is connected failed", "e")
    end
end

function utils.tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

function utils.calculateDamage(obj, target, type)
    local type = type or "physical"
    local damage = 0
    if type == "physical" then
        damage = ((obj.atk + (obj.atk * obj.atkBuff)) * 100) / ((target.def + (target.def * target.defBuff) + 100))
    elseif type == "magical" then
        damage = ((obj.satk + (obj.satk * obj.satkBuff)) * 100) /
            ((target.sdef + (target.sdef * target.sdefBuff) + 100)
            )
    end
    return damage
end

function utils.urlEncode(str)
    if (str) then
        str = string.gsub(str, "\n", "\r\n")
        str = string.gsub(str, "\\", "-")
        str = string.gsub(str, "([^%w .])",
            function(c) return string.format("%%%02X", string.byte(c)) end)
        str = string.gsub(str, " ", "+")
    end

    return str
end

-- Convert RGB to HEX, and handle normalised (0 to 1) or standard RGB (0 to 255) inputs.
function utils.rgb2hex(r, g, b, notNormalised)
    -- By default, we're expecting the input to be normalised (as Solar2D uses normalised values).
    local m = notNormalised and 1 or 255
    local rgb = floor(r * m) * 0x10000 + floor(g * m) * 0x100 + floor(b * m)
    return format("%x", rgb)
end

-- Convert HEX to RGB, and return normalised (0 to 1) or standard RGB (0 to 255) values.
function utils.hex2rgb(hex, dontNormalise)
    -- By default, we're returning normalised values (as Solar2D uses normalised values).
    local m = dontNormalise and 1 or 255
    local hex = gsub(hex, "#", "")
    if len(hex) == 3 then
        return tonumber("0x" .. hex:sub(1, 1)) / m, tonumber("0x" .. hex:sub(2, 2)) / m,
            tonumber("0x" .. hex:sub(3, 3)) / m
    else
        return tonumber("0x" .. hex:sub(1, 2)) / m, tonumber("0x" .. hex:sub(3, 4)) / m,
            tonumber("0x" .. hex:sub(5, 6)) / m
    end
end

-- Add a power-of-two sized repeating texture fill to a target display object.
function utils.addRepeatingFill(target, filename, textureSize, textureScale, textureWrapX, textureWrapY)
    display.setDefault("textureWrapX", textureWrapX or "repeat")
    display.setDefault("textureWrapY", textureWrapY or "repeat")

    target.fill = {
        type = "image",
        filename = filename,
    }
    target.fill.scaleX = (textureSize / target.width) * (textureScale or 1)
    target.fill.scaleY = (textureSize / target.height) * (textureScale or 1)

    display.setDefault("textureWrapX", "clampToEdge")
    display.setDefault("textureWrapY", "clampToEdge")
end

-- Scale a display object to the smallest possible size where it satisfies both
-- required width and height requirements without distorting the aspect ratio.
function utils.scaleDisplayObject(target, requiredWidth, requiredHeight)
    local scale = math.max(requiredWidth / target.width, requiredHeight / target.height)
    target.xScale, target.yScale = scale, scale
end

-- Check if a given file exists or not.
function utils.checkForFile(filename, directory)
    if type(filename) ~= "string" then
        print("WARNING: bad argument #1 to 'checkForFile' (string expected, got " .. type(filename) .. ").")
        return false
    end

    local path = system.pathForFile(filename, directory or system.ResourceDirectory)
    if path then
        local file = io.open(path, "r")
        if file then
            file:close()
            return true
        end
    end
    return false
end

-- Check if the input exists and isn't false, and return boolean.
function utils.getBoolean(var)
    return not not var
end

-- Calculate how many milliseconds has passed between when the timer was first called (started)
-- and when the timer was called the next (finished). Mainly used for benchmarking, etc.
local startTime = nil
function utils.timer(printResult)
    if not startTime then
        startTime = getTimer()
    else
        local time = getTimer() - startTime
        if printResult then
            print("FINISH TIME: " .. time)
        end
        startTime = nil
        return time
    end
end

-- Simple benchmarking: check how long it takes for a function, f, to be run over n iterations.
function utils.benchmark(f, iterations)
    if type(f) ~= "function" then
        print("WARNING: bad argument #1 to 'benchmark' (function expected, got " .. type(f) .. ").")
        return 0
    end

    local startTime = getTimer()
    local iterations = iterations or 1

    for i = 1, iterations do
        f()
    end

    local result = getTimer() - startTime
    print("TIME: " .. result)
    return result
end

-- Scale factor is the value that Solar2D has used to scale all display objects.
function utils.getScaleFactor()
    -- The scale factor depends on device orientation.
    if find(system.orientation, "portrait") then
        return display.pixelWidth / display.actualContentWidth
    else
        return display.pixelWidth / display.actualContentHeight
    end
end

--------------------------------------------------------------------------------------------------
-- display
--------------------------------------------------------------------------------------------------

-- Check that the object is a display object, i.e. a table, and check that its width and height
-- are not 0, i.e. that the display object rendered correctly. Optionally remove the it afterwards.
function display.isValid(object, remove)
    local isValid = false
    if type(object) == "table" and object.width ~= 0 and object.height ~= 0 then
        isValid = true
    end
    if remove then
        dRemove(object)
    end
    return isValid
end

--------------------------------------------------------------------------------------------------
-- table
--------------------------------------------------------------------------------------------------

-- Create a deep copy of a table and all of its entries (doesn't copy metatables).
function table.copy(t)
    local copy = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            v = table.copy(v)
        end
        copy[k] = v
    end
    return copy
end

-- Returns the next entry in a numeric array and optionally
-- reshuffles the table upon reaching the final entry.
function table.getNext(t, shuffle)
    if not t._index then
        t._index = 1
    else
        t._index = t._index + 1
    end

    if t._index > #t then
        if shuffle then
            table.shuffle(t)
        end
        t._index = 1
    end

    return t[t._index]
end

-- Returns a random entry from a given table (non-recursive).
function table.getRandom(t)
    local temp = {}
    for i, v in pairs(t) do
        temp[#temp + 1] = v
    end
    return temp[random(#temp)]
end

-- Perform a Fisher-Yates shuffle on a table. Optionally, don't shuffle the existing
-- table, but instead create a copy of the initial table, shuffle it and return it.
function table.shuffle(t, newTable)
    local target
    if newTable then
        target = {}
        for i = 1, #t do
            target[i] = t[i]
        end
    else
        target = t
    end
    for i = #target, 2, -1 do
        local j = random(i)
        target[i], target[j] = target[j], target[i]
    end
    return target
end

function table.indexOf(array, value)
    for i, v in ipairs(array) do
        if v == value then
            return i
        end
    end
    return nil
end

-- Print out all values within a table and its possible subtables (for debugging).
-- (source: Solar2D Docs - https://docs.coronalabs.com/tutorial/data/outputTable)
local function printSubtable(printCache, t, indent)
    if (printCache[tostring(t)]) then
        print(indent .. "*" .. tostring(t))
    else
        printCache[tostring(t)] = true
        if (type(t) == "table") then
            for pos, val in pairs(t) do
                local key = type(pos) == "string" and "[\"" .. pos .. "\"] => " or "[" .. pos .. "] => "
                if (type(val) == "table") then
                    print(indent .. key .. tostring(t) .. " {")
                    printSubtable(printCache, val, indent .. rep(" ", len(pos) + 8))
                    print(indent .. rep(" ", len(pos) + 6) .. "}")
                elseif (type(val) == "string") then
                    print(indent .. key .. "\"" .. val .. "\"")
                else
                    print(indent .. key .. tostring(val))
                end
            end
        else
            print(indent .. tostring(t))
        end
    end
end

function table.print(t)
    local printCache = {}

    if (type(t) == "table") then
        print(tostring(t) .. " {")
        printSubtable(printCache, t, "  ")
        print("}")
    else
        printSubtable(printCache, t, "  ")
    end
end

-- Count the number of entries in a given table (non-recursive).
function table.count(t)
    local count = 0
    for i, v in pairs(t) do
        count = count + 1
    end
    return count
end

function table.merge(a, b)
    -- table.print(a)
    -- table.print(b)
    if type(a) == 'table' and type(b) == 'table' then
        for k, v in pairs(b) do
            -- if type(v) == 'table' and type(a[k] or false) == 'table' then
            -- table.merge(a[k], v)
            -- else
            -- a[k] = v
            -- end
            a[#a + 1] = v
        end
    end
    return a
end

--------------------------------------------------------------------------------------------------
-- string
--------------------------------------------------------------------------------------------------

-- Pass a string (s) and find the last occurance of a specific character.
function string.findLast(s, character)
    local n = find(s, character .. "[^" .. character .. "]*$")
    return n
end

-- Format a number so that it the thousands are split from another using a separator (space by default).
-- i.e. input: 123456790 -> 1 234 567 890, or -1234.5678 -> -1 234.5678
function string.formatThousands(number, separator)
    if type(number) ~= "number" then
        print("WARNING: bad argument #1 to 'formatThousands' (number expected, got " .. type(number) .. ").")
        return number
    end
    separator = separator or " "
    -- Separate the integer from the possible minus and fraction.
    local minus, integer, fraction = select(3, find(tostring(number), "([-]?)(%d+)([.]?%d*)"))
    -- Reverse the integer, add a thousands separator every 3 digits and restore the integer.
    integer = reverse(gsub(reverse(integer), "(%d%d%d)", "%1" .. separator))
    -- Remove the possible space from the start of the integer and merge the strings.
    if sub(integer, 1, 1) == " " then integer = sub(integer, 2) end
    return minus .. integer .. fraction
end

-- Pass a string (s) to split and character by which to split the string.
function string.split(s, character)
    local t = {}
    for _s in gmatch(s, "([^" .. character .. "]+)") do
        t[#t + 1] = _s
    end
    return t
end

-- Pass a string (s) to split in two and an index from where to split.
function string.splitInTwo(s, index)
    return sub(s, 1, index), sub(s, index + 1)
end

-- Pass a string (s) and find how many times a character (or pattern) occurs in it.
function string.count(s, character)
    return select(2, gsub(s, character, ""))
end

local mFloor, mFmod = math.floor, math.fmod
function string.formatTime(timerVar, highPrecision)
    local min = mFloor(timerVar / 60000)
    local sec = mFmod(mFloor(timerVar * 0.001), 60)
    local tenth = mFloor(mFmod(timerVar, 1000) / 100) -- 0.01 for tenths, 0.1 for hundredth

    local timerStr = (min ~= 0 and min .. ":" or "") ..
        ((min ~= 0 and sec < 10) and "0" .. sec or (sec > 9 and sec or " " .. sec)) .. "."
    if not highPrecision then
        local hundredth = mFloor(mFmod(timerVar, 1000) / 10) -- 0.01 for tenths, 0.1 for hundredth
        timerStr = timerStr .. (hundredth < 10 and "0" .. hundredth or hundredth)
    else
        -- Used for Car game's leaderboards.
        local thousandth = mFmod(timerVar, 1000)
        timerStr = timerStr ..
            (thousandth < 10 and "00" .. thousandth or thousandth < 100 and "0" .. thousandth or thousandth)
    end
    return timerStr
end

--------------------------------------------------------------------------------------------------
-- math
--------------------------------------------------------------------------------------------------

-- Overwrite and fix the existing math.randomseed function.
local _randomseed = math.randomseed
function math.randomseed(seed)
    if type(seed) ~= "number" then
        print("WARNING: bad argument #1 to 'randomseed' (number expected, got " .. type(seed) .. ").")
        return
    end
    -- Address the integer overflow issue with Lua 5.1 (affects Solar2D):
    -- Source: http://lua-users.org/lists/lua-l/2013-05/msg00290.html
    local bitsize = 32
    if seed >= 2 ^ bitsize then
        seed = seed - math.floor(seed / 2 ^ bitsize) * 2 ^ bitsize
    end
    _randomseed(seed - 2 ^ (bitsize - 1))
end

-- Return a simple and reliable random seed (integer).
function math.getseed()
    return os.time() + getTimer() * 10
end

function math.rndNumbers(len)
    local str = ""
    for i = 1, len do
        str = str .. tostring((random(1, 10) - 1))
    end
    return str
end

--------------------------------------------------------------------------------------------------

return utils
