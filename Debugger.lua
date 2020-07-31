Debugger = require("30log")("Debugger")

function Debugger:init(params)
	params = params or {}
    self.active = params.isActive or false
	self.names = {}
	self.listeners = {}
    self.results = {}
    self.panes = {}
    self.panesData = {}
    
	self.x = params.x or 0
	self.y = params.y or 0
	self.r = params.r or 0
	self.sx = params.sx or 1
	self.sy = params.sy or 1
	self.ox = params.ox or 0
	self.oy = params.oy or 0
	self.kx = params.kx or 0
    self.ky = params.ky or 0

    self:addPane{
        id = "default",
        x = self.x,
        y = self.y,
        w = love.graphics.getWidth() - self.x * 2,
        h = love.graphics.getHeight() - self.y * 2
    }
    
    self.printqueue = {}
    
	self.commands = {}
	self.cmdresults = {}

	self.text = 'Debugger'
	self.textCursorPosition = 0

	self.printer = params.customPrinter or false
	self.printColor = params.printColor or {0.25, 0.25, 0.25, 0.5}
	self.printFont = params.printFont or love.graphics.getFont()

	self.debugToggle = params.debugToggle or '`'

	self.watchedFiles = params.filesToWatch or {}
	self.watchedFileTimes = {}
	for i, v in ipairs(self.watchedFiles) do
		assert(love.filesystem.getLastModified(v), v .. ' must not exist or is in the wrong directory.')
		self.watchedFileTimes[i] = love.filesystem.getLastModified(v)
	end
	self.print('Debugger Initialized.')
end

function Debugger:clearAll()
    self.names = {}
	self.listeners = {}
    self.results = {}
    self.panes = {}
    self.panesData = {}
    self:addPane{
        id = "default",
        x = self.x,
        y = self.y,
        w = love.graphics.getWidth() - self.x * 2,
        h = love.graphics.getHeight() - self.y * 2
    }
end

function Debugger:cleanupPanes()
    local li = 1
    local r = {}
    for i, pane in ipairs(self.panesData) do
        if li ~= 1 then
            if pane.id == self.panesData[li].id then
                table.insert(r, li)
            end
            li = pane.id
        end
    end
    for _, i in ipairs(r) do
        table.remove(self.panesData, i)
    end
end

function Debugger:keypressed(key)
	if key == self.debugToggle then
		self:toggle()
	end
	if self.active then
		-- If entering a command:
		if key == "enter" then
            -- parses string
            self:watch(self.text, loadstring('return ' .. self.text))

			-- Clear self.text.
			self.text = ''
		elseif key == 'backspace' then
			self.text = string.sub(self.text, 1, string.len(self.text) - 1)
		end
	end
end

function Debugger:addPane(id, x, y, w, h)
    local data = {
        id = id,
        x = x,
        y = y,
        w = w,
        h = h
    }
    if type(id) == 'table' and not(x and y and w and h) then
        data = id
    end
    data.id = data.id or data.index or data[1]
    data.x = data.x or data[2]
    data.y = data.y or data[3]
    data.w = data.w or data.width or data[4]
    data.h = data.h or data.height or data[5]
    table.insert(self.panesData, data)
    self.panesData[data.id] = data
end

function Debugger:drawPanes(mode)
    for _, pane in ipairs(self.panesData) do
        love.graphics.setNewFont(20)
        local x, y, w, h = pane.x, pane.y, pane.w or pane.width, pane.h or pane.height
        local text = pane.id
        love.graphics.setColor(1, 1, 1, 0.25)
        love.graphics.rectangle(mode, x, y, w, h)
        local textW = love.graphics.getFont():getWidth(text)
        local textH = love.graphics.getFont():getHeight()
        local textX, textY
        if x < love.graphics.getWidth() / 2 then
            textX = x
        else
            textX = (x + w) - textW
        end
        if y < love.graphics.getHeight() / 2 then
            textY = y
        else
            textY = (y + h) - textH
        end
        love.graphics.setColor(1, 1, 1, 0.65)
        love.graphics.rectangle("fill", textX, textY, textW, textH)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.print(text, textX, textY)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

function Debugger:watch(name, object, pane)
    if type(object) == 'string' then
        object = load(object)
    end
    if type(object) == 'function' then
        self:print('Watching ' .. name)
        if pane then
            local d, i = any(self.names, name)
            local count = 0
            for _, paneData in ipairs(self.panesData) do
                if paneData.id ~= pane then
                    count = count + 1
                end
            end
            assert(count ~= #self.panesData, "Invalid pane specified")
        else
            pane = "default"
        end
        if d then
            self.listeners[i] = object
            self.names[i] = name
            self.panes[i] = pane
        else
            table.insert(self.listeners, object)
            table.insert(self.names, name)
            table.insert(self.panes, pane)
        end
    else
        self:print('Object to watch is not a string')
        error('Object to watch is not a string')
    end
end

function Debugger:unwatch(name)
    for i, v in ipairs(self.names) do
        if v == name then
            self.names[i] = nil
            self.listeners[i] = nil
            self.panes[i] = nil
        end
    end
    self.listeners[name] = nil
    self.results = {}
end

function Debugger:setFactors(x, y, r, sx, sy, ox, oy, kx, ky)
    self.x, self.y, self.r, self.sx,
    self.sy, self.ox, self.oy, self.kx,
    self.ky = x, y, r, sx, sy, ox, oy, kx, ky
end

function Debugger:enabled()
    return self.active
end

function Debugger:enable()
	self.active = true
end

function Debugger:disable()
	self.active = false
end

Debugger.activate = Debugger.enable
Debugger.deactivate = Debugger.disable
Debugger.activated = Debugger.enabled

function Debugger:toggle()
	self.active = not self.active
end

function Debugger:print(text,justtext)
	if self.printer and not justtext then
		print("[Debugger]: " .. text)
	elseif justtext then
		return "[Debugger]: " .. text
	end
end

function Debugger:update(dt)
    self:cleanupPanes()
	for key, object in ipairs(self.listeners) do
		if type(object) == 'function' then
			self.results[key] = object() or 'Error!'
		elseif type(object) == 'table' then
			self.results[key] = object
		end
	end

	for i, v in ipairs(self.watchedFiles) do
		if self.watchedFileTimes[i] ~= love.filesystem.getLastModified(v) then
			print('reloading...')
			self.watchedFileTimes[i] = love.filesystem.getLastModified(v)
			love.filesystem.load('main.lua')()
		end
	end
end

local function any(t, k)
    k = k or true
    for i, v in ipairs(t) do
        if v == k then
            return true, i
        end
    end
    return false
end

function Debugger:render()
    if self.active then
        for _, pane in ipairs(self.panes) do
                self:display(pane)
        end
    end
end

Debugger.draw = Debugger.render

function Debugger:display(pane)
    if type(pane) == 'string' then
        pane = self.panesData[pane]
    end
    pane = pane or self.panesData['default']
    love.graphics.setColor(self.printColor)
    love.graphics.setFont(self.printFont)
    local draw_x, draw_y = pane.x or 10, pane.y or 0
    local title_text = self.text
    love.graphics.print(title_text, draw_x, draw_y)
    love.graphics.rectangle("line", draw_x, draw_y - 1,
    self.printFont:getWidth(title_text),
    self.printFont:getHeight() + 2
    )
    draw_y = draw_y + self.printFont:getHeight() * 2
    for i, result in pairs(self.results) do
        if self.panes[i] == pane.id then
            if type(result) ~= 'table' then
                if type(result) == 'string' and result == '' then
                    result = 'nil'
                elseif type(result) == 'boolean' then
                    result = tostring(result)
                elseif (type(result) == 'userdata') or (type(result) == 'function') then
                    result = type(result)
                end
                love.graphics.printf(self.names[i] .. " : " .. result,
                    draw_x, draw_y,
                    pane.w, "left", self.r, self.sx, self.sy, self.ox, self.oy, self.kx, self.ky)
            else
                love.graphics.printf(self.names[i] .. " : Table:",
                    draw_x, draw_y,
                    pane.w, "left", self.r, self.sx, self.sy, self.ox, self.oy, self.kx, self.ky)
                draw_y = draw_y + self.printFont:getHeight()
                for i, v in pairs(result) do
                    if type(v) == 'table' then
                        love.graphics.printf("\t" .. i .. " : " .. "Table:",
                            draw_x, draw_y,
                            pane.w, "left", self.r, self.sx, self.sy, self.ox, self.oy, self.kx, self.ky)
                        for i, v in pairs(v) do
                            if type(v) == "table" then
                                v = "table"
                            elseif type(v) == 'boolean' then
                                v = tostring(v)
                            elseif type(v) == 'string' and v == '' then
                                v = 'nil'
                            elseif (type(v) == 'userdata') or (type(v) == 'function') then
                                v = type(v)
                            end
                            draw_y = draw_y + self.printFont:getHeight()
                            love.graphics.printf("\t\t" .. i .. " : " .. v,
                                draw_x, draw_y,
                                pane.w, "left", self.r, self.sx, self.sy, self.ox, self.oy, self.kx, self.ky)
                        end
                    else
                        if type(v) == 'string' and v == '' then
                            v = 'nil'
                        elseif type(v) == 'boolean' then
                            v = tostring(v)
                        elseif (type(v) == 'userdata') or (type(v) == 'function') then
                            v = type(v)
                        end
                        love.graphics.printf("\t" .. i .. " : " .. v,
                            draw_x, draw_y,
                            pane.w, "left", self.r, self.sx, self.sy, self.ox, self.oy, self.kx, self.ky)
                    end
                    draw_y = draw_y + self.printFont:getHeight()
                end
            end
            draw_y = draw_y + self.printFont:getHeight()
        end
    end
end

return Debugger
