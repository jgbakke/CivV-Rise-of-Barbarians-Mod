--
-- Created by IntelliJ IDEA.
-- User: jordan
-- Date: 3/29/20
-- Time: 3:40 AM
-- To change this template use File | Settings | File Templates.
--

g_SaveData = Modding.OpenSaveData()
g_Properties = {}

function GetPersistentProperty(name)
    if not g_Properties[name] then
        g_Properties[name] = g_SaveData.GetValue(name)
    end
    return g_Properties[name]
end

function SetPersistentProperty(name, value)
    if GetPersistentProperty(name) == value then return end
    g_SaveData.SetValue(name, value)
    g_Properties[name] = value
end