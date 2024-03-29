-- Tile data and rendering tile map to screen

require 'Util'
require 'Player'

Map = Class{}


TILE_BRICK = 1
TILE_EMPTY = -1

-- cloud tiles
CLOUD_LEFT = 6
CLOUD_RIGHT = 7

-- bush tiles
BUSH_LEFT = 2
BUSH_RIGHT = 3

-- mushroom tiles
MUSHROOM_TOP= 10
MUSHROOM_BOTTOM = 11

-- flag tiles

FLAG_BOTTOM = 16
FLAG_MIDDLE = 12
FLAG_TOP = 8
FLAG_FLAG = 13

-- jump tiles
JUMP_BLOCK = 5
JUMP_BLOCK_HIT = 9

-- speed to multiply delta time to  scroll map

local SCROLL_SPEED = 62

function Map:init()
    self.spritesheet = love.graphics.newImage('graphics/spritesheet.png')
    self.music = love.audio.newSource('sounds/music.wav', 'static')
    self.tileWidth = 16
    self.tileHeight = 16
    self.mapWidth = 45
    self.mapHeight  = 28
    self.tiles = {}

    self.player = Player(self)

    -- camera offsets

    self.camX = 0
    self.camY = -3

    -- generate a quad for each tile

    self.tileSprites = generateQuads(self.spritesheet, self.tileWidth, self.tileHeight)

    -- cache width and height in pixels

    self.mapWidthPixels = self.mapWidth * self.tileWidth
    self.mapHeightPixels = self.mapHeight * self.tileHeight


    -- fills the map with empty tiles

    for y = 1, self.mapHeight  do
        for x = 1, self.mapWidth do
            self:setTile(x, y, TILE_EMPTY)
        end
    end

    -- begin generating the terrain using vertical scan lines

    local x = 1
    while x < 30 do

        -- 10/3 chance of generating a cloud
        -- makes sures there's a 2 tiles distance from the edge
        if x < self.mapWidth - 2 then
            if math.random(30) == 1 then
                -- choose a random vertical tile above where blocks generate

                local cloudStart = math.random(self.mapHeight / 2 - 6)

                self:setTile(x, cloudStart, CLOUD_LEFT)
                self:setTile(x + 1, cloudStart, CLOUD_RIGHT)

            end
        end

        -- 5% chance to generate a mushroom
        if math.random(20) == 1 then

            -- left side of  pipe
            self:setTile(x, self.mapHeight / 2 - 2, MUSHROOM_TOP)
            self:setTile(x, self.mapHeight / 2 - 1, MUSHROOM_BOTTOM)

            -- column of tiles going to the bottom of the map

            for y = self.mapHeight / 2, self.mapHeight do
                self:setTile(x, y, TILE_BRICK)
            end


            -- next vertical scan line
            x = x + 1

        --  10% chance to  generate bush (away from edge)
        elseif math.random(10) == 1 and x < self.mapWidth - 3 then
            local bushLevel = self.mapHeight / 2 - 1

            -- place bush component and then column of bricks

            self:setTile(x, bushLevel, BUSH_LEFT)
            for y = self.mapHeight / 2, self.mapHeight do
                self:setTile(x, y, TILE_BRICK)
            end

            x = x + 1

            self:setTile(x, bushLevel, BUSH_RIGHT)
            for y = self.mapHeight / 2, self.mapHeight do
                self:setTile(x, y, TILE_BRICK)
            end

            x = x + 1

        -- 10% chance of not generating anything ( gap )
        elseif math.random(10) ~= 1 then

            -- create column of tiles going to the bottom of the map
            for y = self.mapHeight / 2, self.mapHeight do
                self:setTile(x, y, TILE_BRICK)
            end


            -- chance to create a hit block

            if math.random(15) == 1 then
                self:setTile(x, self.mapHeight / 2 - 4, JUMP_BLOCK)
            end

            x = x + 1

        else
            -- increment two scanlines, creating a gap
            x =  x + 2

        end

    end

    -- generate end game space

    for z = 1, 5 do
        for y = self.mapHeight / 2, self.mapHeight do
            self:setTile(self.mapWidth - z, y, TILE_BRICK)
        end
        z = z + 1
    end


    for z = 10, 15 do
        for y = self.mapHeight / 2, self.mapHeight do
            self:setTile(self.mapWidth - z, y, TILE_BRICK)
        end
        z = z + 1
    end


    for height = 0, 5 do
        for y = self.mapHeight / 2, self.mapHeight do
            self:setTile(self.mapWidth -11 + height, y - height, TILE_BRICK)
        end
    end


   -- generate flag

    self:setTile(self.mapWidth  -1, self.mapHeight / 2 - 3, FLAG_TOP)
    self:setTile(self.mapWidth  , self.mapHeight / 2 - 3, FLAG_FLAG)
    self:setTile(self.mapWidth  -1, self.mapHeight / 2 -2, FLAG_MIDDLE)
    self:setTile(self.mapWidth  -1, self.mapHeight / 2 -1, FLAG_BOTTOM)

    -- starts music

    self.music:setLooping(true)
    self.music:setVolume(0.25)
    -- self.music:play()



end

-- sets a tile on a x,y coord to an int value

function Map:setTile(x, y, tile)
    self.tiles[(y - 1) * self.mapWidth + x] = tile
end

-- returns an int for the tile at a x,y coord

function Map:getTile(x, y)
    return self.tiles[(y - 1) * self.mapWidth + x]
end


-- return whether a given tile is collidable
function Map:collides(tile)
    -- define our collidable tiles
    local collidables = {
        TILE_BRICK, JUMP_BLOCK, JUMP_BLOCK_HIT,
        MUSHROOM_TOP, MUSHROOM_BOTTOM
    }

    -- iterate and return true if our tile type matches
    for _, v in ipairs(collidables) do
        if tile.id == v then
            return true
        end
    end

    return false
end



-- function to update camera offset with delta time
function Map:update(dt)
    self.player:update(dt)

    -- keep camera's X coordinate following the player, preventing camera from
    -- scrolling past 0 to the left and the map's width
    self.camX = math.max(0, math.min(self.player.x - VIRTUAL_WIDTH / 2,
        math.min(self.mapWidthPixels - VIRTUAL_WIDTH, self.player.x)))
end

-- gets the tile type at a given pixel coordinate
function Map:tileAt(x, y)
    return {
        x = math.floor(x / self.tileWidth) + 1,
        y = math.floor(y / self.tileHeight) + 1,
        id = self:getTile(math.floor(x / self.tileWidth) + 1, math.floor(y / self.tileHeight) + 1)
    }
end




function Map:render()
    for y = 1, self.mapHeight  do
        for x = 1, self.mapWidth do
            local tile = self:getTile(x, y)
            if tile ~= TILE_EMPTY then
                love.graphics.draw(self.spritesheet, self.tileSprites[tile],
                    (x - 1) * self.tileWidth, (y - 1) * self.tileHeight)
            end
        end
    end

    self.player:render()

end
