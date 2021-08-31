local editor = {}

function editor:load(data)
    if data["refresh"] then
        if self.code_editor.config.font ~= font.regular then
            self.code_editor:set_config({font = font.regular})
        end
        self.code_editor:resize(lg.getWidth(), lg.getHeight())
    else
        self.code_editor = code_editor.new(0, 0, lg.getWidth(), lg.getHeight())
        self.code_editor:set_config({font = font.regular})

        self.file = nil
        if data["file"] then
            self.file = data["file"]
        end
        self.code_editor:load(self.file)
    end
end

function editor:update(dt)

end

function editor:draw()
    lg.setColor(1, 1, 1, 1)
    self.code_editor:draw()
end

function editor:resize(w, h)
    self.code_editor:resize(w, h)
end

function editor:keypressed(key)
    self.code_editor:keypressed(key)
    if key == "s" then
        if lk.isDown("lctrl") then
            self.code_editor:save_file(self.file)
        end
    elseif key == "r" then
        if lk.isDown("lctrl") then
            self.code_editor:save_file(self.file)
            state:save()
            state:load("run", {file=self.file})
        end
    elseif key == "escape" then
        state:save()
        state:load("console")
    end
end

function editor:textinput(t)
    self.code_editor:textinput(t)
end

return editor