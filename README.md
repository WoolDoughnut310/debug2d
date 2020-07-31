# Debug 2D

### Debugging Love2D with style

Monocle reborn is an easier way to watch things while you play your game. 
It's easy to implement, and easy to understand. The setup of a basic main.lua file is as follows:

```lua
require 'Debugger'
debugger = Debugger()

-- The most basic way to watch any expression or variable:
debugger:watch("FPS", function() return love.timer.getFPS() end)

function love.update(dt)
	debugger:update(dt)
end

function love.draw()
	debugger:draw()
end

function love.keypressed(key)
	debugger:keypressed(key)
end
```
Easy as that! When the game is run, what you're watching will show up in the top right of the screen.

For more information on how to use the old Monocle, as well as the official Love2D forum post, look [here](http://love2d.org/forums/viewtopic.php?f=5&t=77108).

Oh, you can watch string, number and table variables. so if you have a variable player.health that you really want to watch,
```lua
debugger:watch("Health", function() return player.health end)
```
is fine.


 You can also pass in certain parameters when you load Monocle. Here's a list of them, with their default values:
 
 ```lua
 Debugger{       -- ALL of these parameters are optional!
	isActive = true,          -- Whether the debugger is initially active
	customPrinter = false,    -- Whether Monocle prints status messages to the output
	printColor = {51, 51, 51},-- Color to print with
	printFont = love.graphics.getFont(),
	debugToggle = '`',        -- The keyboard button for toggling Monocle
	filesToWatch = {
		'main.lua'
	}, -- Files that, when edited, cause the game to reload automatically,
	x, y, r, sx, sy, ox, oy, kx, ky
}
```


You can now display debug on different parts of the screen with only one debugger object.
```lua
debugger:addPane(id, x, y, w, h)
```

* id - The index of the pane to add ("string")
* x - The x position of the pane
* y - The y position of the pane
* w - The width of the pane
* h - The height of the pane

By default there is already a pane with the index "default" which would be added with this:
```lua
debugger:addPane{
        id = "default",
        x = self.x,
        y = self.y,
        w = WINDOW_WIDTH - self.x * 2,
        h = WINDOW_HEIGHT - self.y * 2
}
```

where `WINDOW_WIDTH, WINDOW_HEIGHT = love.graphics.getWidth(), love.graphics.getHeight()`

```lua
debugger:drawPanes(mode)
```
* mode - Drawing mode - "line" or "fill"

```lua
require 'Debugger'

function love.load()
	debugger = Debugger{
		x = 20,
		y = 40,
		printColor={0, 0, 0, 1}
	}

	-- The most basic way to watch any expression or variable:
	debugger:watch("FPS", function() return love.timer.getFPS() end)

	love.graphics.setBackgroundColor(1, 0.8, 0)
end

function love.update(dt)
	debugger:update(dt)
end

function love.draw()
	debugger:drawPanes("fill")
	debugger:render()
end

function love.keypressed(text)
	debugger:keypressed(text)
end
```
The above code would look like this:
![Panes drawn with gold background](/images/panes_drawn.png)

And removing the `debugger:drawPanes("fill")` and adding `debugger:activate()` would show:
![Debug mode activated](/images/debug_activated.png)
