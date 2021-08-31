local console = {}

function console:load()
    self.code_editor = code_editor.new(0, 0, lg.getWidth(), lg.getHeight())
    self.code_editor:set_config({font = font.regular, show_line_numbers = false, console_mode = true, syntax_highlight = false, show_info = false})
    self.code_editor:load()

    -- Registering commands

    -- HELP
    local function help(c)
        c:print("Available commands:")
        for k,v in pairs(c.console_commands) do
            c:print(string.format("%s - %s", k, v.description))
        end
    end
    self.code_editor:register_command("help", help, "You're looking at it.")

    -- EXIT
    self.code_editor:register_command("exit", function(c) love.event.push("quit") end, "Closes Doodle Box")

    -- ECHO
    local function echo(c, ...)
        local t = {...}
        local s = ""
        for i,v in ipairs(t) do
            s = s..v.." "
        end
        c:print(s)
    end
    self.code_editor:register_command("echo", echo, "Echoes whatever you tell it")

    -- NEW
    local function new(c, name)
        if name then
            if fs.getInfo(config.project_directory.."/"..name) then
                c:print(string.format("Project with the name '%s' already exists!", name))
            else
                local project_folder = config.project_directory.."/"..name
                fs.createDirectory(project_folder)

                local main = fs.read("src/doodle/main.lua")
                fs.write(project_folder.."/main.lua", main)

                c:print(string.format("Project '%s' created.", name))
            end
        else
            c:print("Usage: new [project name]")
        end
    end
    self.code_editor:register_command("new", new, "Creates a new project")

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
            c:print(v)
        end
    end
    self.code_editor:register_command("ls", ls, "Lists all projects")

    -- PROJECTS
    local function projects(c)
        love.system.openURL("file://"..love.filesystem.getSaveDirectory().."/"..config.project_directory)
        c:print("Open projects directory..")
    end
    self.code_editor:register_command("projects", projects, "Opens the projects directory in your OS.")

    self.code_editor:print("Welcome to Doodle Box!")
end

function console:update(dt)

end

function console:draw()
    self.code_editor:draw()
end

function console:textinput(t)
    self.code_editor:textinput(t)
end

function console:keypressed(key)
    self.code_editor:keypressed(key)
end

return console