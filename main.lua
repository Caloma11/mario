WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

-- 16:9 res

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243


Class = require 'class' -- https://github.com/vrld/hump/blob/master/class.lua
push = require 'push' -- https://github.com/Ulydev/push

-- require 'Util'


require 'Map'

function love.load()
    map = Map()

    love.graphics.setDefaultFilter('nearest', 'nearest')

    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullScreen = false,
        resizable = false,
        vsync = true
    })
end

-- called every frame, dt is delta time since last frame

function love.update(dt)
    map:update(dt)
end

-- called every frame, renders the screen

function love.draw()

    push:apply('start') -- virtual res drawing
--
    love.graphics.translate(math.floor(-map.camX), math.floor(-map.camY))

    love.graphics.clear(108 / 255, 140 / 255, 255 / 255, 1) -- background
    map:render()
    push:apply('end') -- end virtual res drawing

end
