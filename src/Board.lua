
Board = Class{}

function Board:init(x, y, level)
    self.x = x
    self.y = y
    self.matches = {}

    self.level = level

    self:initializeTiles()
end

function Board:initializeTiles()
    self.tiles = {}

    for tileY = 1, 8 do
        
        table.insert(self.tiles, {})

            -- create a new tile at X,Y with a random color and variety depending on what level you are currently playing
        for tileX = 1, 8 do
            table.insert(self.tiles[tileY], Tile(tileX, tileY, math.random(8), math.random(math.min(6, self.level))))
        end
    end

    while self:calculateMatches() do
        self:initializeTiles()
    end
end

function Board:calculateMatches()
    local matches = {}
    local matchNum = 1

    -- horizontal matches first
    for y = 1, 8 do

        -- if tile in match is shiny
        local shinyMatch = false

        local colorToMatch = self.tiles[y][1].color

        matchNum = 1

        -- every horizontal tile
        for x = 2, 8 do
            if self.tiles[y][x].color == colorToMatch then
                matchNum = matchNum + 1
            else
                colorToMatch = self.tiles[y][x].color
                if matchNum >= 3 then
                    local match = {}

                    for x2 = x - 1, x - matchNum, -1 do
                        if self.tiles[y][x2].shiny then
                            shinyMatch = true
                        end
                    end

                    -- if tile in match is shiny add whole row to match table
                    if shinyMatch then
                        for rowX = 1, 8 do
                            table.insert(match, self.tiles[y][rowX])
                        end
                    else
                        for x2 = x - 1, x - matchNum, -1 do
                            table.insert(match, self.tiles[y][x2])
                        end
                    end
                    table.insert(matches, match)
                end

                matchNum = 1
                if x >= 7 then
                    break
                end
            end
        end

        -- account for the last row ending with a match
        if matchNum >= 3 then
            local match = {}

            for x = 8, 8 - matchNum + 1, -1 do
                if self.tiles[y][x].shiny then
                    shinyMatch = true
                end
            end
            
            -- if tile in match is shiny add whole row to match table
            if shinyMatch then
                for rowX = 1, 8 do
                    table.insert(match, self.tiles[y][rowX])
                end
            else
                for x = 8, 8 - matchNum + 1, -1 do
                    table.insert(match, self.tiles[y][x])
                end
            end

            table.insert(matches, match)
        end
    end

    -- vertical matches
    for x = 1, 8 do
        local shinyMatch = false

        local colorToMatch = self.tiles[1][x].color

        matchNum = 1
        for y = 2, 8 do
            if self.tiles[y][x].color == colorToMatch then
                matchNum = matchNum + 1

            else
                colorToMatch = self.tiles[y][x].color

                if matchNum >= 3 then
                    local match = {}

                    for y2 = y - 1, y - matchNum, -1 do
                        if self.tiles[y2][x].shiny then
                            shinyMatch = true
                        end
                    end

                    -- if tile in match is shiny add whole column to match table
                    if shinyMatch then
                        for columnY = 1, 8 do
                            table.insert(match, self.tiles[columnY][x])
                        end
                    else
                        for y2 = y - 1, y - matchNum, -1 do
                            table.insert(match, self.tiles[y2][x])
                        end
                    end

                    table.insert(matches, match)
                end

                matchNum = 1
                if y >= 7 then
                    break
                end
            end
        end

        -- account for the last column ending with a match
        if matchNum >= 3 then
            local match = {}

            for y = 8, 8 - matchNum, -1 do
                if self.tiles[y][x].shiny then
                    shinyMatch = true
                end
            end
            
            -- if tile in match is shiny add whole column to match table
            if shinyMatch then
                for columnY = 1, 8 do
                    table.insert(match, self.tiles[columnY][x])
                end
            else
                for y = 8, 8 - matchNum, -1 do
                    table.insert(match, self.tiles[y][x])
                end
            end

            table.insert(matches, match)
        end
    end
    self.matches = matches
    return #self.matches > 0 and self.matches or false
end

function Board:removeMatches()
    for k, match in pairs(self.matches) do
        for k, tile in pairs(match) do
            self.tiles[tile.gridY][tile.gridX] = nil
        end
    end

    self.matches = nil
end

--[[
    Shifts down all of the tiles that now have spaces below them, then returns a table that
    contains tweening information for these new tiles.
]]
function Board:getFallingTiles()
    -- tween table, with tiles as keys and their x and y as the to values
    local tweens = {}

    -- for each column, go up tile by tile till we hit a space
    for x = 1, 8 do
        local space = false
        local spaceY = 0

        local y = 8
        while y >= 1 do
            -- if our last tile was a space...
            local tile = self.tiles[y][x]
            
            if space then
                -- if the current tile is *not* a space, bring this down to the lowest space
                if tile then
                    -- put the tile in the correct spot in the board and fix its grid positions
                    self.tiles[spaceY][x] = tile
                    tile.gridY = spaceY

                    -- set its prior position to nil
                    self.tiles[y][x] = nil

                    -- tween the Y position to 32 x its grid position
                    tweens[tile] = {
                        y = (tile.gridY - 1) * 32
                    }

                    -- set Y to spaceY so we start back from here again
                    space = false
                    y = spaceY

                    -- set this back to 0 so we know we don't have an active space
                    spaceY = 0
                end
            elseif tile == nil then
                space = true
                
                -- if we haven't assigned a space yet, set this to it
                if spaceY == 0 then
                    spaceY = y
                end
            end

            y = y - 1
        end
    end

    -- create replacement tiles at the top of the screen
    for x = 1, 8 do
        for y = 8, 1, -1 do
            local tile = self.tiles[y][x]

            -- if the tile is nil, we need to add a new one
            if not tile then

                -- new tile with random color and variety
                local tile = Tile(x, y, math.random(8), math.random(math.min(6, self.level)))
                tile.y = -32
                self.tiles[y][x] = tile

                -- create a new tween to return for this tile to fall down
                tweens[tile] = {
                    y = (tile.gridY - 1) * 32
                }
            end
        end
    end

    return tweens
end

function Board:getNewTiles()
    return {}
end

function Board:render()
    for y = 1, #self.tiles do
        for x = 1, #self.tiles[1] do
            self.tiles[y][x]:render(self.x, self.y)
        end
    end
end

function Board:findMatches()
    
    local matchTable = {}

    for x = 1, 8 do
        for y = 1, 8 do
            local x2 = x
            local y2 = y

            for y2 = y - 1, y + 1, 2 do
                if y2 < 1 or y2 > 8 then
                    break
                end

                local testBoard = Class.clone(self)
                local tile = testBoard.tiles[y][x]
                local newTile = testBoard.tiles[y2][x]

                newTile = testBoard.tiles[newTile.gridY][newTile.gridX]

                tempTile = testBoard.tiles[tile.gridY][tile.gridX]

                testBoard.tiles[tile.gridY][tile.gridX] = newTile
                testBoard.tiles[newTile.gridY][newTile.gridX] = tempTile

                local matches = testBoard:calculateMatches()

                if type(matches) == 'table' then
                    table.insert(matchTable, {x..","..y, x..","..y2})
                end
            end

            y2 = y

            for x2 = x - 1, x + 1, 2 do
                if x2 < 1 or x2 > 8  then
                    break
                end

                local testBoard = Class.clone(self)
                local tile = testBoard.tiles[y][x]
                local newTile = testBoard.tiles[y][x2]

                newTile = testBoard.tiles[newTile.gridY][newTile.gridX]

                tempTile = testBoard.tiles[tile.gridY][tile.gridX]

                testBoard.tiles[tile.gridY][tile.gridX] = newTile
                testBoard.tiles[newTile.gridY][newTile.gridX] = tempTile

                if type(matches) == 'table' then
                    table.insert(matchTable, {x..","..y, x2..","..y})
                end
            end
        end
    end

    return matchTable
end

function Board:check()
    local matches = self:findMatches()
    print_r(matches)

    
    while #matches < 0 do
        self.initializeTiles()
        matches = self.findMatches()
    end

end

