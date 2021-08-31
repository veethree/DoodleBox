local code_editor = {}
code_editor_meta = {__index = code_editor}

--Local methods
-- Converts color from 0-255 range to 0-1
local function color(r, g, b, a)
	a = a or 255
	return {r / 255, g / 255, b / 255, a / 255}
end

local function getCharBytes(string, char)
	char = char or 1
	local b = string.byte(string, char)
	local bytes = 1
	if b > 0 and b <= 127 then
      bytes = 1
   elseif b >= 194 and b <= 223 then
      bytes = 2
   elseif b >= 224 and b <= 239 then
      bytes = 3
   elseif b >= 240 and b <= 244 then
      bytes = 4
   end
	return bytes
end

local function len(str)
	local pos = 1
	local len = 0
	while pos <= #str do
		len = len + 1
		pos = pos + getCharBytes(str, pos)
	end
	return len
end

local function sub(str, s, e)
	s = s or 1
	e = e or len(str)

	if s < 1 then s = 1 end
	if e < 1 then e = len(str) + e + 1 end
	if e > len(str) then e = len(str) end

	if s > e then return "" end

	local sByte = 0
	local eByte = 1

	local pos = 1
	local i = 0
	while pos <= #str do
		i = i + 1
		if i == s then
			sByte = pos
		end
		pos = pos + getCharBytes(str, pos)
		if i == e then
			eByte = pos - 1
			break
		end
	end

	return string.sub(str, sByte, eByte)
end

local function has_key(tab, key)
	local r = false
	for k, v in pairs(tab) do
		if k == key then
			r = true
			break
		end
	end
	return r
end

local function split(str)
	local res = {}

	for word in str:gmatch("%w+") do
		res[#res + 1] = word
	end

	return res
end

-- Calculates the step the cursor should take to step by word
local function calculate_step_back(line)
	local last = ""
	local current = sub(line, len(line))
	if current == " " then
		last = line:match("(%s+)$")
	else
		last = line:match("(%w+)$")
	end
	last = last or " "
	return len(last)
end
-- Calculates the step the cursor should take to step by word
local function calculate_step_forward(line)
	local last = ""
	local current = sub(line, 1, 1)
	if current == " " then
		last = line:match("^(%s+)")
	else
		last = line:match("^(%w+)")
	end
	last = last or " "
	print(last)
	return len(last)
end

--LÖVE SETUP
local lg = love.graphics
local fs = love.filesystem
local lk = love.keyboard
lk.setKeyRepeat(true)

function code_editor.new(x, y, width, height)
    local ce = {
        x = x,
        y = y,
        width = width,
        height = height,
		
        lines = {""},
		file = "None",

		scroll = {
			x = 1,
			y = 1
		},
        cursor = {
            x = 1,
            y = 1,
			draw_x = 1,
			draw_y = 1
        },
		
        config = {
			-- CONSOLE MODE
			console_mode = false,
			console_history = {},
			console_commands = {},
			console_colors = {
				normal = {1, 1, 1, 1},
				info = color(51, 177, 255),
				warning = color(237, 160, 71),
				danger = color(230, 76, 76),
				success = color(129, 219, 90)
			},
			
			--Look
			font = lg.newFont(16),
			show_info = true,
			--Color
			text_color_base = {1, 1, 1, 1},
			cursor_color = {0, 0.7, 0, 1},
			background_color = color(26, 28, 36),
			info_color = color(232, 118, 118),

			--Line numbers
			show_line_numbers = true,
			line_number_color = color(191, 191, 191),
			line_number_margin = 0,

			x_margin = 12,
			y_margin = 12,

			tab = "    ",

			syntax_highlight = true,
			syntax_colors = {
				number = color(230, 76, 76),
				value = color(180, 77, 240),
				keyword = color(51, 177, 255),
				string = color(237, 160, 71),
				symbol = color(129, 219, 90),
				comment = color(120, 120, 120),
				ident = color(239, 239, 239),
				operator = color(160, 160, 160)
			}
        }    
    }

    return setmetatable(ce, code_editor_meta)
end

-- Init function
-- file: Path to a text file to load. Files can also be loaded directly with the load_file() method
-- resize: Boolean, If true, Only things that need to be reinitialized for a rezied are reinitialized
function code_editor:load(file, resize)
	self.font_height = self.config.font:getAscent() - self.config.font:getDescent()
	self.font_width = self.config.font:getWidth("W")
	self.visible_lines = math.floor((self.height - (self.config.y_margin * 2) - self.font_height) / self.font_height) - 1
	self.max_line_width = math.floor((self.width - (self.config.x_margin * 8)) / self.font_width)
	if self.config.show_line_numbers then
		self.config.line_number_margin = self.font_width * 4
	end
	if not resize then
		file = file or false
		resize = resize or false
		if file then
			self:load_file(file)
		end
		self.cursor.x = 1
		self.cursor.y = 1
		self.scroll.x = 1
		self.scroll.y = 1
		self:update_cursor()
	end
end

-- Console mode related methods
function code_editor:register_command(cmd, func, description)
	description = description or "No description"
	self.config.console_commands[cmd] = {
		func = func,
		description = description
	}
end

function code_editor:run_command(cmd)
	local sp = split(cmd)
	cmd = sp[1]
	if has_key(self.config.console_commands, cmd) then
		table.remove(sp, 1)
		self.config.console_commands[cmd].func(self, unpack(sp))
	else
		self:print(string.format("'%s' is not a recognized command.", cmd))
	end
end

function code_editor:print(t, color)
	color = color or false
	if self.config.console_mode then
		if color then t = "<"..color..">"..t end
		self:set_line(t, #self.lines)
		self:insert_line(#self.lines+ 1)
		self:move_cursor(0, 1)
		self.cursor.x = 1
	end
end

-- con: A table containing a config item to be changed {show_line_numbers = false}
function code_editor:set_config(con)
	for k,v in pairs(con) do
		self.config[k] = v
	end
end

-- Line editing functions
function code_editor:get_line(line)
	line = line or self.cursor.y
	if line < 1 then line = 1 end
	return self.lines[line]
end

function code_editor:set_line(text, line)
	line = line or self.cursor.y
	self.lines[line] = text
end

-- Inserts 't' wherever the cursor is in  a line
function code_editor:insert(t)
	local line_start, line_end = self:split_line()
	if self.cursor.x == 1 then
		line_start = ""
	end

	self:set_line(line_start..t..line_end)
end

function code_editor:insert_line(pos, line)
	line = line or ""
	table.insert(self.lines, pos, line)
end

function code_editor:remove_line(pos)
	table.remove(self.lines, pos)
	if #self.lines == 0 then
		self.lines[1] = ""
	end
end

-- Splits the line at the cursor
function code_editor:split_line()
	local line = self:get_line()
	local line_start = sub(line, 1, self.cursor.x-1)
	local line_end = sub(line, self.cursor.x, #line)

	return line_start, line_end
end

-- Updates the cursor drawing position
function code_editor:update_cursor()
	self.cursor.draw_y = self.y + self.config.y_margin + (self.cursor.y - self.scroll.y) * self.font_height 
	self.cursor.draw_x = self.x + ((self.config.x_margin * 2) + self.config.line_number_margin) + (self.cursor.x - 1 - self.scroll.x) * self.font_width

	--Scrolling
	self.scroll.x = self.cursor.x - self.max_line_width
	if self.scroll.x < 1 then
		self.scroll.x = 1
	end
end

-- Navigation related functions

function code_editor:goto(line)
	line = tonumber(line)
	if line < 1 then line = 1 elseif line > #self.lines then line = #self.lines end
	self:move_cursor(0, line, true)
end

-- Moves the cursor, And handels scrolling
-- Needs to be refactored something fierece. this shit is garbage.
function code_editor:move_cursor(x, y, set)
	set = set or false
	local current_line = self:get_line()
	if set then
		x = x or self.cursor.x
		y = y or self.cursor.y
		self.cursor.x = x
		self.cursor.y = y
		if self.cursor.y - self.scroll.y < self.visible_lines then
			self.scroll.y = y
			if self.scroll.y + self.visible_lines > #self.lines then
				self.scroll.y = #self.lines - self.visible_lines
			end
		end
	else
		x = x or 0
		y = y or 0
		self.cursor.x = self.cursor.x + x	
		self.cursor.y = self.cursor.y + y	
	end
	--Clamping
	if self.cursor.x < 1 then
		self.cursor.x = 1
	end
	if current_line then
		if self.cursor.x > #current_line then
			self.cursor.x = #current_line + 1
		end
	end	

	if self.cursor.y < 1 then
		self.cursor.y = 1
	elseif self.cursor.y > #self.lines then
		self.cursor.y = #self.lines
	end

	--Scrolling
	if self.cursor.y < self.scroll.y then
		self.scroll.y = self.scroll.y - 1
	elseif self.cursor.y > self.scroll.y + self.visible_lines then
		self.scroll.y = self.scroll.y + 1
	end

	self:update_cursor()
end

-- Loads a file & replaces tabs with spaces
function code_editor:load_file(file)
	if fs.getInfo(file) then
		self.file = file
		for line in fs.lines(file) do
			-- Replacing tabs with spaces cause fuck tabs
			fixed_line = string.gsub(line, "\t", self.config.tab)
			self:insert_line(#self.lines, fixed_line)
		end
		self:remove_line(#self.lines)
	end
end

function code_editor:save_file(file)
	local data = ""
	for i,v in ipairs(self.lines) do
		data = data..v
		if i < #self.lines then
			data = data.."\n"
		end
	end
	fs.write(file, data)
end

-- Renders a line with syntax highlighting or colors depending on console_mode
function code_editor:draw_line(line)
	local colored_text = {}
	if self.config.syntax_highlight then
		local l = lexer(self:get_line(line))
		for i,v in ipairs(l) do
			for o,j in ipairs(v) do
				local color = self.config.text_color_base
				if has_key(self.config.syntax_colors, j.type) then
					color = self.config.syntax_colors[j.type]
				end
			
				colored_text[#colored_text + 1] = color
				colored_text[#colored_text + 1] = j.data
			end
		end
	else
		local raw_line = self:get_line(line)
		local color, str = raw_line:match("<(%w+)>(.+)")
		if color then
			if not has_key(self.config.console_colors, color) then color = "normal" end
			colored_text = {
				self.config.console_colors[color],
				str
			}
		else
			colored_text = self:get_line(line)
		end
	end

	line = line - self.scroll.y
	lg.setStencilTest("greater", 0)
	lg.setColor(1, 1, 1, 1)
	lg.print(colored_text, self.x + ((self.config.x_margin * 2) + self.config.line_number_margin) - (self.font_width * (self.scroll.x)), self.y + self.config.y_margin + (self.font_height * (line)))

	--Line numbers
	if self.config.show_line_numbers then
		lg.setColor(self.config.line_number_color)
		lg.print(line + self.scroll.y, self.x + self.config.x_margin, self.y + self.config.y_margin + (self.font_height * (line)))
	end
end

function code_editor:draw_info_tab()
	if self.config.show_info then
		lg.setColor(self.config.info_color)
		local str_left = string.format("%d/%d", self.cursor.y, #self.lines)
		local str_center = string.format("'%s'", self.file)
		local str_right = string.format("[%dx%d] [%dx%d]", self.cursor.x, self.cursor.y, self.scroll.x, self.scroll.y)
		lg.printf(str_left, self.x, self.height - self.font_height, self.width, "left")
		lg.printf(str_center, self.x, self.height - self.font_height, self.width, "center")
		lg.printf(str_right, self.x, self.height - self.font_height, self.width, "right")
	end
end

function code_editor:draw()
	local of = lg.getFont()
	local r, g, b, a = lg.getColor()

	local function stencil()
		lg.rectangle("fill", self.x, self.y, self.width, self.height)
	end
	lg.stencil(stencil)

	lg.setStencilTest("greater", 0)
	--BG
	lg.setColor(self.config.background_color)
	lg.rectangle("fill", self.x, self.y, self.width, self.height)

	--CURSOR
	lg.setColor(self.config.cursor_color)
	lg.rectangle("fill", self.cursor.draw_x, self.cursor.draw_y, self.font_width, self.font_height)

	--FONT
	lg.setColor(1, 1, 1, 1)
	lg.setFont(self.config.font)

	-- Code
	for i=self.scroll.y, self.scroll.y + self.visible_lines do
		if i <= #self.lines then
			self:draw_line(i)
		end
	end

	self:draw_info_tab()

	lg.setStencilTest()
	lg.setColor(r, g, b, a)
	lg.setFont(of)
end 

function code_editor:resize(w, h)
    self.width = w
	self.height = h
	self:load(false, true)
end

function code_editor:keypressed(key)
	if key == "backspace" then
		local line_start, line_end = self:split_line()
		local step = 2
		if lk.isDown("lctrl") then
			step = calculate_step_back(line_start) + 1
		end
		line_start = sub(line_start, 1, self.cursor.x-step)
		if self.cursor.x <= step then
			line_start = ""
		end

		self:set_line(line_start..line_end)

		self.cursor.x = self.cursor.x - (step - 1)
		if self.cursor.x < 1 then 
			self.cursor.x = 1
			if self.cursor.y > 1 and not self.config.console_mode then
				self.cursor.y = self.cursor.y - 1
				if self.cursor.y < self.scroll.y then
					self.scroll.y = self.scroll.y - 1
				end
				self.cursor.x = #self:get_line() + 1
				self:set_line(self:get_line()..line_end)
				self:remove_line(self.cursor.y + 1)
			end
		end

	elseif key == "return" then
		if self.config.console_mode then
			self:run_command(self:get_line())
		else
			local line_start, line_end = self:split_line()
			if self.cursor.x <= 1 then
				line_start = ""
			end

			if lk.isDown("lctrl") or lk.isDown("rctrl") then
				if lk.isDown("lshift") or lk.isDown("lshift") then
					self:insert_line(self.cursor.y)
				else
					self:insert_line(self.cursor.y + 1)
					self:move_cursor(0, 1)
				end
			else
				self.cursor.x = 1
				self:set_line(line_start, self.cursor.y)
				self:insert_line(self.cursor.y + 1, line_end)
				self:move_cursor(0, 1)
			end
		end
	elseif key == "tab" then
		self:insert(self.config.tab)
		self.cursor.x = self.cursor.x + #self.config.tab
	elseif key == "left" then
		local step = 1
		local line_start, line_end = self:split_line()
		if lk.isDown("lctrl") or lk.isDown("rctrl") then
			step = calculate_step_back(line_start)
	
			--snap to start
			if lk.isDown("lshift") or lk.isDown("rshift") then
				self.cursor.x = 1
				self:update_cursor()
			end
		end

		if self.cursor.x > step then
			self.cursor.x = self.cursor.x - step
		end
	
	elseif key == "right" then
		local step = 1
		local line_start, line_end = self:split_line()
		if lk.isDown("lctrl") or lk.isDown("rctrl") then
			step = calculate_step_forward(line_end)
			--snap to end
			if lk.isDown("lshift") or lk.isDown("rshift") then
				self.cursor.x = #self:get_line() + 1
				self:update_cursor()
			end
		end

		self.cursor.x = self.cursor.x + step
		if self.cursor.x > #self:get_line() then
			self.cursor.x = #self:get_line() + 1
		end
	elseif key == "up" and not self.config.console_mode then
		self.cursor.y = self.cursor.y - 1
		if self.cursor.y < 1 then
			self.cursor.y = 1
		end

		--Scrolling also
		if self.cursor.y < self.scroll.y then
			self.scroll.y = self.scroll.y - 1
		end

		--Fixing cursor x
		if self.cursor.x > #self:get_line() then
			self.cursor.x = #self:get_line() + 1
		end

		--Scroll
		if lk.isDown("lshift") or lk.isDown("rshift") then
			local step = math.floor(self.visible_lines / 2)
			if lk.isDown("lctrl") or lk.isDown("rctrl") then
				step = self.visible_lines
			end
			self.scroll.y = self.scroll.y - step
			self.cursor.y = self.scroll.y
			if self.cursor.y < 1 then self.cursor.y = 1 end
			if self.scroll.y < 1 then
				self.scroll.y = 1
			end
		elseif lk.isDown("lalt") or lk.isDown("ralt") then
			local above = self:get_line()
			local current = self:get_line(self.cursor.y + 1)
			self:set_line(current)
			self:set_line(above, self.cursor.y + 1)
		else
			--Snap
			if lk.isDown("lctrl") or lk.isDown("rctrl") then
				self.scroll.y = 1
				self.cursor.y = 1
			end
		end
	elseif key == "down" and not self.config.console_mode then
		
		self.cursor.y = self.cursor.y + 1
		if self.cursor.y > #self.lines then
			self.cursor.y = #self.lines
		end

		--Scrolling 
		if self.cursor.y > (self.scroll.y + self.visible_lines) then
			self.scroll.y = self.scroll.y + 1
		end

		-- Fixing cursor X
		if self.cursor.x > #self:get_line() then
			self.cursor.x = #self:get_line() + 1
		end

		--Scroll
		if lk.isDown("lshift") or lk.isDown("rshift") then
			local step = math.floor(self.visible_lines / 2)
			if lk.isDown("lctrl") or lk.isDown("rctrl") then
				step = self.visible_lines
			end
			self.scroll.y = self.scroll.y + step
			self.cursor.y = self.scroll.y
			if self.cursor.y > #self.lines then self.cursor.y = #self.lines end
			if self.scroll.y > #self.lines - self.visible_lines then
				self.scroll.y = #self.lines - self.visible_lines
			end
		elseif lk.isDown("lalt") or lk.isDown("ralt") then
			local above = self:get_line()
			local current = self:get_line(self.cursor.y - 1)
			self:set_line(current)
			self:set_line(above, self.cursor.y - 1)
		else
			--Snap
			if lk.isDown("lctrl") or lk.isDown("rctrl") then
				if #self.lines > self.visible_lines then
					self.scroll.y = #self.lines - self.visible_lines
				end
				--self.cursor.y = #self.lines
				self:move_cursor(0, #self.lines, true)
				self:update_cursor()
			end
		end
	elseif key == "d" and not self.config.console_mode then
		if lk.isDown("lctrl") or lk.isDown("rctrl") then
			self:insert_line(self.cursor.y + 1, self:get_line())
			self:move_cursor(0, 1)
		end
	elseif key == "x" and not self.config.console_mode then
		if lk.isDown("lctrl") or lk.isDown("rctrl") then
			self:remove_line(self.cursor.y)
			self:move_cursor(0, -1)
		end
	end
	self:update_cursor()
end

function code_editor:textinput(t)
	self:insert(t)
	self.cursor.x = self.cursor.x + 1
	self:update_cursor()
end

return code_editor