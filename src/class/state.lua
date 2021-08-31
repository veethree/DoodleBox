-- A bare bones state system
local state = {
    state = false,
    state_list = {},
    saved_state = {}
}

-- state_module: Path to a state module file
-- name: Name of the state, Used in state:load
function state:define_state(state_module, name)
    self.state_list[name] = state_module
end

-- state: state name as defined with define_state
-- data: Anything you want to pass to the state in the states load function
function state:load(state_name, data)
    data = data or {}
    if self.state_list[state_name] then
        if self.saved_state[state_name] then
            self.state = self.saved_state[state_name]
            self.state:load({refresh = true})
        else
            self.state = fs.load(self.state_list[state_name])()
            self.state.name = state_name
            if type(self.state.load) == "function" then
                self.state:load(data)
            end
        end
    else
        error(string.format("STATE: State '%s' does not exist!", state_name))
    end
end 

function state:save()
    self.saved_state[self.state.name] = self.state
end

function state:clear(state_name)
    state_name = state_name or self.state.name
    if self.saved_state[state_name] then
        self.saved_state[state_name] = nil
    end
end

function state:get_state()
    return self.state
end

--The following are callback functions
function state:update(dt)
    if type(self.state.update) == "function" then
        self.state:update(dt)
    end
end

function state:draw()
    if type(self.state.draw) == "function" then
        self.state:draw()
    end
end

function state:resize(w, h)
    if type(self.state.resize) == "function" then
        self.state:resize(w, h)
    end
end

function state:keypressed(key)
    if type(self.state.keypressed) == "function" then
        self.state:keypressed(key)
    end
end

function state:keyreleased(key)
    if type(self.state.keyreleased) == "function" then
        self.state:keyreleased(key)
    end
end

function state:mousepressed(x, y, key)
    if type(self.state.mousepressed) == "function" then
        self.state:mousepressed(x, y, key)
    end
end

function state:mousereleased(x, y, key)
    if type(self.state.mousereleased) == "function" then
        self.state:mousereleased(x, y, key)
    end
end

function state:wheelmoved(x, y)
    if type(self.state.wheelmoved) == "function" then
        self.state:wheelmoved(x, y)
    end
end

function state:quit()
    if type(self.state.quit) == "function" then
        self.state:quit()
    end
end

function state:textinput(t)
    if type(self.state.textinput) == "function" then
        self.state:textinput(t)
    end
end

return state