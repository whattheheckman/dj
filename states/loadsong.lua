local threaded, filename = ...

if threaded == true then
  require "love.sound"
  local soundData = love.sound.newSoundData(filename)
  love.thread.getChannel("loadsong"):supply(soundData)
  return
end

local thisFile = (...):gsub("%.", "/") .. ".lua"

local gamestate = require "lib.hump.gamestate"
local state = {}

function state:enter(previous, song_filename, callback)
  self.previous = previous
  self.callback = callback
  self.fade = 0
  self.data = nil
  self.done = false

  self.thread = love.thread.newThread(thisFile)
  self.thread:start(true, song_filename)
end

function state:leave()
  self.previous = nil
  self.callback = nil
  self.fade = nil
  self.data = nil
  self.done = nil

  self.thread = nil
end

-- function state:keypressed(key, unicode)
--     if key == "escape" then
--         self.done = true
--     end
-- end
--
-- function state:gamepadpressed(joystick, button)
--     if key == "b" then
--         self.done = true
--     end
-- end

function state:update(dt)
  if self.done then
    self.fade = self.fade - dt * 4

    if self.fade < 0 then
      local callback = self.callback
      local data = self.data

      gamestate.pop()

      if data then
        callback(data)
      end
    end
  else
    self.fade = math.min(1, self.fade + dt * 2)
  end

  if self.thread then
    local soundData = love.thread.getChannel("loadsong"):pop()

    if soundData then
      self.data = soundData
      self.done = true
      self.thread = nil
    else
      local error = self.thread:getError()

      if error then
        self.done = true
        self.thread = nil
      end
    end
  end
end

function state:draw()
  self.previous:draw()

  local width, height = love.window.fromPixels(love.graphics.getDimensions())

  love.graphics.setColor(0, 0, 0, self.fade * 150)
  love.graphics.rectangle("fill", 0, 0, love.window.toPixels(width, height))

  local time = love.timer.getTime()
  local radius = 64

  local cx = love.window.toPixels(width / 2)
  local cy = love.window.toPixels(height / 2)

  love.graphics.stencil(function()
    love.graphics.circle("fill", cx, cy, love.window.toPixels(radius * 0.8, radius * 1.6))
  end)

  love.graphics.setStencilTest("equal", 0)

  -- Draw empty part
  love.graphics.setColor(32/255, 32/255, 32/255, self.fade * 200)
  love.graphics.circle("fill", cx, cy, love.window.toPixels(radius, radius * 2))

  -- Draw fill
  local a1 = (time % (math.pi * 2)) + math.sin(math.cos(time / 4) * math.pi * 2) * math.pi
  local a2 = (time % (math.pi * 2)) + math.cos(math.sin(time / 4) * math.pi * 2) * math.pi

  love.graphics.setColor(150/255, 150/255, 150/255, self.fade * 255)
  love.graphics.arc("fill", cx, cy, radius, a1, a2, radius * 2)

  love.graphics.setStencilTest()
end

return state
