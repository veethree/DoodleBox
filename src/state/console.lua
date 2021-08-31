local console = {}

-- Turns variable arguments into a string.
-- Used for console commands, Probably should be a part of code_editor.lua
local function arg_to_str(...)
    local s = ""
    for i,v in ipairs({...}) do
        s = s..v.." "
    end
    return s:sub(1, -2)
end

function console:define_commands()
    -- HELP
    local function help(c)
        c:print("Available commands:", "normal")
        for k,v in pairs(c.config.console_commands) do
            c:print(string.format("%s - %s", k, v.description), "info")
        end
    end
    self.code_editor:register_command("help", help, "You're looking at it.")

    -- EXIT
    self.code_editor:register_command("exit", function(c) love.event.push("quit") end, "Closes Doodle Box")

    -- ECHO
    local function echo(c, ...)
        if ... then
            s = arg_to_str(...)
            c:print(s, "info")
        else
            c:print("Usage: echo [text]", "info")
        end
    end
    self.code_editor:register_command("echo", echo, "Echoes whatever you tell it")

    -- NEW
    local function new(c, ...)
        if ... then
            local name = arg_to_str(...)
            local fixed_name = name:gsub(" ", "_")
            print(fixed_name)

            if fs.getInfo(config.project_directory.."/"..name) then
                c:print(string.format("Project with the name '%s' already exists!", name), "danger")
            else
                local project_folder = config.project_directory.."/"..name
                fs.createDirectory(project_folder)

                local main = ""
                for line in fs.lines("src/doodle/main.lua") do
                    main = main..line:gsub("project_name", fixed_name).."\n"
                end


                fs.write(project_folder.."/main.lua", main)

                c:print(string.format("Project '%s' created.", name), "success")
            end
        else
            c:print("Usage: new [project name]", "info")
        end
    end
    self.code_editor:register_command("new", new, "Creates a new project")

    -- LOAD
    local function load(c, ...)
        if ... then
            local name = arg_to_str(...)
            local project_folder = config.project_directory.."/"..name
            if fs.getInfo(project_folder) then
                self.loaded_project = name
                state:save()
                state:clear("editor")
                c:print(string.format("Loading project '%s'", name), "info")
                state:load("editor", {file=project_folder.."/main.lua"})
            else
                c:print(string.format("Project '%s' does not exists!", name), "danger")
            end
        else
            c:print("Usage: load [project name]", "info")
        end
    end
    self.code_editor:register_command("load", load, "Loads a project")

    -- UNLOAD
    local function unload(c, ...)
        c:print(string.format("Project '%s' unloaded", self.loaded_project), "success")
        self.loaded_project = false
    end
    self.code_editor:register_command("unload", unload, "Unloads a project")

    -- DEL
    local function del(c, ...)
        if ... then
            local name = arg_to_str(...)
            if self.loaded_project == name then
                c:print(string.format("Cannot remove project while its loaded! Run 'unload %s' to unload it first.", name), "danger")
                return
            end
            local project_folder = config.project_directory.."/"..name
            if fs.getInfo(project_folder) then
                for k, file in ipairs(fs.getDirectoryItems(project_folder)) do
                    local ok = fs.remove(project_folder.."/"..file)
                    if ok then
                        c:print(string.format("Deleting '%s'", file), "info")
                    else
                        c:print(string.format("Couldn't delete '%s'", file), "danger")
                    end
                end
                fs.remove(project_folder)
                c:print(string.format("Project '%s' deleted", name), "success")
            else
                c:print(string.format("Project '%s' does not exists!", name), "danger")
            end
        else
            c:print("Usage: del [project name / -a] '-a' will delete all the projects.", "info")
        end
    end
    self.code_editor:register_command("del", del, "Deletes a project. This is PERMANENT.")

    -- CLEAR
    local function clear(c)
        c.lines = {""}
        c:load()
    end
    self.code_editor:register_command("clear", clear, "Clears the console.")

    -- LS
    local function ls(c)
        c:print("Projects:")
        for i,v in ipairs(fs.getDirectoryItems(config.project_directory)) do
            c:print(v, "info")
        end
    end
    self.code_editor:register_command("ls", ls, "Lists all projects")

    -- PROJECTS
    local function projects(c)
        love.system.openURL("file://"..love.filesystem.getSaveDirectory().."/"..config.project_directory)
        c:print("Opening projects directory...", "info")
    end
    self.code_editor:register_command("projects", projects, "Opens the projects directory in your OS.")

    -- op
    local function op(c)
        if self.loaded_project then
            love.system.openURL("file://"..love.filesystem.getSaveDirectory().."/"..config.project_directory.."/"..self.loaded_project)
            c:print("Opening project directory...", "info")
        else
            c:print("No project loaded!", "danger")
        end
    end
    self.code_editor:register_command("op", op, "Opens the current projects directory in your OS.")

    local function lsconfig(c)
        c:print("Config:")
        for k,v in pairs(config) do
            if type(v) == "table" then
                c:print(k..":")
                for o,j in pairs(v) do
                    c:print(string.format('    %s = %s', o, j), "info")
                end
            else
                c:print(string.format('%s =l %s', k, v), "info")
            end
        end
    end
    self.code_editor:register_command("lsconfig", lsconfig, "Lists all config items you can change with 'config'")

    -- L
    local function goto(c, line)
        if self.loaded_project then
            if line then
                if tonumber(line) then
                    state:load("editor")
                    state:get_state().code_editor:goto(line)
                    c:print(string.format("Going to line %d", line))
                else
                    c:print(string.format("'%s' is not a valid line number.", line), "danger")
                end
            else
                c:print("Usage: l [line number]", "info")
            end
        else
            c:print("No project loaded!", "danger")
        end
    end
    self.code_editor:register_command("l", goto, "goes to a specific line")

end

function console:load(data)
    if data["refresh"] then
        self.code_editor:resize(lg.getWidth(), lg.getHeight())
    else
        self.code_editor = code_editor.new(0, 0, lg.getWidth(), lg.getHeight())
        self.code_editor:set_config({font = font.regular, show_line_numbers = false, console_mode = true, syntax_highlight = false, show_info = false})
        self.code_editor:load()
        self.code_editor:resize(lg.getWidth(), lg.getHeight())

        self.loaded_project = false
        self:define_commands()
        self.code_editor:print("Welcome to Doodle Box! Type 'help' if you don't know what to do.", "success")
    end
end

function console:update(dt)

end

function console:draw()
    self.code_editor:draw()
end

function console:resize(w, h)
    self.code_editor:resize(w, h)
end

function console:textinput(t)
    self.code_editor:textinput(t)
end

function console:keypressed(key)
    self.code_editor:keypressed(key)
    if key == "escape" then
        if self.loaded_project then
            state:load("editor")
        else
            self.code_editor:print("No project loaded!", "danger")
        end
    end
end

return console