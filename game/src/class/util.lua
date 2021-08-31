-- Various utility functions

function require_folder(folder)
    if fs.getInfo(folder) then
        for i,v in ipairs(fs.getDirectoryItems(folder)) do
            if get_file_type(v) == "lua" then
                _G[get_file_name(v)] = require(folder.."."..get_file_name(v))
            end
        end
    else
        error(string.format("Folder '%s' does not exists", folder))
    end
end

function get_file_type(file_name)
    return string.match(file_name, "%..+"):sub(2)
end

function get_file_name(file_name)
    return string.match(file_name, ".+%."):sub(1, -2)
end