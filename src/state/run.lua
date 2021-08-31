local run = {}

function run:run_function(func, ...)
    local status, err = pcall(func, ...)
    if not status then
        self.err(err)
    end
end

function run.err(msg)
    state:load("console")
    state:get_state().code_editor:print(string.format("ERROR: %s", msg))
end

function run:load(data)
    if data["file"] then
        local status, err = pcall(fs.load, data["file"])
        if status then
            self.program = err()
            if type(self.program.load) == "function" then
                local function f(dt)
                    state:get_state().program:load()
                end
                self:run_function(f, dt)
            end
        else
            self.err(err)
        end

    else
        self.err("No code to run")
    end

end

function run:update(dt)
    update_globals()
    if type(self.program.update) == "function" then
        local function f(dt)
            state:get_state().program:update(dt)
        end
        self:run_function(f, dt)
    end
end

function run:draw()
    if type(self.program.draw) == "function" then
        local function f()
            state:get_state().program:draw()
        end
        self:run_function(f, dt)
    end
end

function run:keypressed(key)
    if type(self.program.keypressed) == "function" then
        local function f(key)
            state:get_state().program:keypressed(key)
        end
        self:run_function(f, key)
    end

    if key == "escape" then
        state:load("editor")
    end
end

function run:keyreleased(key)
    if type(self.program.keyreleased) == "function" then
        local function f(key)
            state:get_state().program:keyreleased(key)
        end
        self:run_function(f, key)
    end
end

function run:textinput(key)
    if type(self.program.textinput) == "function" then
        local function f(key)
            state:get_state().program:textinput(key)
        end
        self:run_function(f, key)
    end
end

function run:mousepressed(x, y, key)
    if type(self.program.mousepressed) == "function" then
        local function f(dt)
            state:get_state().program:mousepressed(dt)
        end
        self:run_function(f, dt)
    end
end

function run:mousereleased(x, y, key)
    if type(self.program.mousereleased) == "function" then
        local function f(dt)
            state:get_state().program:mousereleased(dt)
        end
        self:run_function(f, dt)
    end
end

return run