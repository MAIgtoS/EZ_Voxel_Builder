-- LOCAL GLOBAL TABLE TO STORE COPIED NODE DATA
local nodes = {}
local undonodes = {}
local copied_params ={}

--BUILD AN ARRAY OF NODES USING 3 NUMBER PARAMETERS, FWD RIGHT UP. USES THE NODE PLAYER IS CURRENTLY WIELDING
minetest.register_chatcommand("b", {
    description = "Build an area of nodes. Will use currently wielded node. Parameters 2 and 3 can be negative numbers, ie. /b 3 -10 -2.",
    params = "[<# of Nodes Forward>] [<# of Nodes Right>] [<# of Nodes Up>]",
    
    func = function(name, param)
        
        local hdg, xstep, zstep = get_heading(name)
        local itemName = get_item(name)
        if itemName == "not_node" then
            return true
        end
        local playerPos, t, hstep, vstep = get_data(name, param)
        local param2counter, param3counter = get_counters(t)
        if tonumber(t[1]) == 0 then
            place_node(playerPos,xstep,zstep,itemName)
        else
            place_nodes(name,playerPos,t,param2counter,param3counter,hstep,vstep,xstep,zstep,itemName,hdg)
        end

        return true
    end
})

--MAKE A COPY OF AN ARRAY OF NODES USING 3 NUMBER PARAMETERS, FWD RIGHT UP. 
minetest.register_chatcommand("c", {
    description = "Copy an area of nodes. Parameters 2 and 3 can be negative numbers, ie. /c 16 -12 -1.",
    params = "[<# of Nodes Forward>] [<# of Nodes Right>] [<# of Nodes Up>]",
    
    func = function(name, param)
        
        local hdg, xstep, zstep = get_heading(name)
        local playerPos, t, hstep, vstep = get_data(name, param)
        local param2counter, param3counter = get_counters(t)

        copy_nodes(name,playerPos,t,param2counter,param3counter,hstep,vstep,xstep,zstep,hdg)
        
        return true, minetest.chat_send_player(name, "Copied")
    end
})

--PASTE AN ARRAY OF NODES FROM COPIED DATA
minetest.register_chatcommand("p", {
    description = "Paste an area of nodes identical to that which was copied.",
    
    func = function(name, param)

        if #copied_params == 0 then
            return true, minetest.chat_send_player(name, "Nothing to paste")
        end

        local params = tostring(copied_params[1]) .. " " .. tostring(copied_params[2]) .. " " .. tostring(copied_params[3])     
        local hdg, xstep, zstep = get_heading(name)
        local playerPos, t, hstep, vstep = get_data(name, params)
        local param2counter, param3counter = get_counters(t)
        local mirrored = false

        paste_nodes(name,playerPos,t,param2counter,param3counter,hstep,vstep,xstep,zstep,hdg,mirrored)
        
        return true
    end
})

--PASTE A MIRRORED ARRAY OF NODES FROM COPIED DATA
minetest.register_chatcommand("pm", {
    description = "Paste an area of nodes as mirror image to that which was copied.",
    
    func = function(name, param)

        if #copied_params == 0 then
            return true, minetest.chat_send_player(name, "Nothing to mirror")
        end

        local params = tostring(copied_params[1]) .. " " .. tostring(copied_params[2]) .. " " .. tostring(copied_params[3])     
        local hdg, xstep, zstep = get_heading(name)
        local playerPos, t, hstep, vstep = get_data(name, params)
        local param2counter, param3counter = get_counters(t)
        local mirrored = true

        paste_nodes(name,playerPos,t,param2counter,param3counter,hstep,vstep,xstep,zstep,hdg,mirrored)
        
        return true
    end
})

--UNDO PREVIOUS BUILD OR PASTE OPERATION
minetest.register_chatcommand("u", {
    description = "Undo a previously commanded 'build' or 'paste' action. Will restore nodes to prior state.",
    
    func = function(name, param)

        if #undonodes == 0 then
            return true, minetest.chat_send_player(name,"Nothing to undo")
        end
        for node_count = 1, #undonodes, 1 do
            local pos = minetest.string_to_pos(undonodes[node_count].position)
            local node_name = undonodes[node_count].name
            minetest.set_node(pos,{name = node_name})
        end

        undonodes = {}
        
        return true, minetest.chat_send_player(name,"Undo complete")
    end
})



---------FUNCTIONS-----------------------------------------------------

--ROUND NUMBER TO SPECIFIED DECIMAL PLACES
function round(num,places)
    local mult = 10^(places or 0)
    local result = math.floor(num * mult + 0.5)/mult
    return result
end

--CONVERT RADIANS TO CARDINAL HEADING AND PROVIDE STEP DIRECTION FOR NODE PLACEMENT
function get_heading(name)
    local radians = minetest.get_player_by_name(name):get_look_horizontal()
    
    if radians > math.pi*2-math.pi/4 or radians < math.pi/4 then
        local xstep = 0
        local zstep = 1
        return "north", xstep, zstep
    elseif radians > math.pi/4 and radians < math.pi-math.pi/4 then
        local xstep = -1
        local zstep = 0
        return "west", xstep, zstep
    elseif radians > math.pi-math.pi/4 and radians < math.pi+math.pi/4 then
        local xstep = 0
        local zstep = -1
        return "south", xstep, zstep
    elseif radians > math.pi+math.pi/4 and radians < math.pi*2-math.pi/4 then
        local xstep = 1
        local zstep = 0
        return "east", xstep, zstep
    end
end

--GET CURRENTLY HELD ITEM
function get_item(name)
    local itemName = minetest.get_player_by_name(name):get_wielded_item()
    if itemName:get_definition().type ~= "node" then
        if itemName:is_empty() then
            itemName = "air"
	    return itemName
        else
	    return "not_node"
	end
    else
        itemName = itemName:get_name()
    end
	
    return itemName
end

--COLLECT INFO BASED ON THE PARAMETERS GIVEN AND CREATE SOME VARIABLES
function get_data(name, param)
    local playerPos = minetest.get_player_by_name(name):get_pos()
    local paramTable = {}
    local hstep
    local vstep

    for i in string.gmatch(param,"%S+")do
        table.insert(paramTable,tonumber(i))
    end
    if #paramTable == 0 then
        table.insert(paramTable,0)
        table.insert(paramTable,0)
        table.insert(paramTable,0)
    elseif #paramTable == 1 then
        table.insert(paramTable,0)
        table.insert(paramTable,0)
    elseif #paramTable == 2 then
        table.insert(paramTable,0)
    end

    if paramTable[2] < 0 then
        hstep = -1
    else
        hstep = 1
    end

    if paramTable[3] < 0 then
        vstep = -1
    else
        vstep = 1
    end

    return playerPos, paramTable, hstep, vstep
end

--RETURN WHICH DIRECTION THE LOOP COUNTERS SHOULD GO BASED ON PARAMETERS
function get_counters(params)
    local param2counter
    local param3counter

    if tonumber(params[2]) == 0 then
        param2counter = 0
    else
        --Account for negative number, eg. param[2] == 10, then param2counter = 10 -(10/10) = 9. If param[2] == -10, then 
        --param2counter = -10 - (-10/10) = -9 
        param2counter = params[2]-(params[2]/math.abs(params[2]))
    end
    if tonumber(params[3]) == 0 then
        param3counter = 0
    else
        param3counter = params[3]-(params[3]/math.abs(params[3]))
    end

    return param2counter, param3counter
end

--CREATE SINGLE NODE IN FRONT OF PLAYER IF NO PARAMETERS GIVEN
function place_node(pos,xstep,zstep,itemName)
    local playerPos = pos
    playerPos.x = playerPos.x + xstep
    playerPos.z = playerPos.z + zstep
    minetest.set_node({x=playerPos.x,y=playerPos.y,z=playerPos.z}, {name = itemName})
end

--CREATE THE NODES REQUESTED BY PARAMETERS
function place_nodes(name,pos,t,t2counter,t3counter,hstep,vstep,xstep,zstep,itemName,hdg)
    --Clear global
    undonodes = {}

    local playerPos = pos
    local node_counter = 0

    for v=0, t3counter, vstep do
        for h=0, t2counter, hstep do  

            if tonumber(t[3])<0 then
                playerPos.y = minetest.get_player_by_name(name):get_pos().y + (v-1)  
            end

            --Make single forward line
            for i=0, t[1]-1, 1 do
                playerPos.x = playerPos.x + xstep
                playerPos.z = playerPos.z + zstep
                local node_pos = minetest.pos_to_string({x=playerPos.x,y=playerPos.y,z=playerPos.z})
                local node_name = minetest.get_node({x=playerPos.x,y=playerPos.y,z=playerPos.z}).name
                node_counter = node_counter + 1
                local node_count = node_counter

                undonodes[node_count] = {position=node_pos,name=node_name}
                minetest.set_node({x=playerPos.x,y=playerPos.y,z=playerPos.z}, {name = itemName})
            end
            playerPos = minetest.get_player_by_name(name):get_pos()

            -- Move sideways 1 after every forward line
            if hdg == "north" then
                playerPos.x = playerPos.x + t[2]/math.abs(t[2])*(math.abs(h)+1) 
            elseif hdg == "west" then
                playerPos.z = playerPos.z + t[2]/math.abs(t[2])*(math.abs(h)+1)
            elseif hdg == "south" then
                playerPos.x = playerPos.x - t[2]/math.abs(t[2])*(math.abs(h)+1)
            elseif hdg == "east" then
                playerPos.z = playerPos.z - t[2]/math.abs(t[2])*(math.abs(h)+1)
            end

            --Move up 1 after every forwad line reposition
            playerPos.y = playerPos.y + v 
        end

        --Move up 1 after every row
        playerPos = minetest.get_player_by_name(name):get_pos()
        playerPos.y = playerPos.y + (v+1) 
    end
end

--COPY THE NODES REQUESTED BY THE PARAMETERS
function copy_nodes(name,pos,t,t2counter,t3counter,hstep,vstep,xstep,zstep,hdg)
    --Clear globals
    nodes = {}
    copied_params ={}

    local playerPos = pos
    local node_counter = 0
    copied_params = t

    for v=0, t3counter, vstep do
        for h=0, t2counter, hstep do  

            if tonumber(t[3])<0 then
                playerPos.y = minetest.get_player_by_name(name):get_pos().y + (v-1)  
            end

            --Copy single forward line
            for i=0, t[1]-1, 1 do
                playerPos.x = playerPos.x + xstep
                playerPos.z = playerPos.z + zstep
                local node_pos = minetest.pos_to_string({x=playerPos.x,y=playerPos.y,z=playerPos.z})
                local node_name = minetest.get_node({x=playerPos.x,y=playerPos.y,z=playerPos.z}).name
                node_counter = node_counter + 1
                local node_count = node_counter

                nodes[node_count] = {position=node_pos,name=node_name}

            end
            playerPos = minetest.get_player_by_name(name):get_pos()

            -- Move sideways 1 after every forward line
            if hdg == "north" then
                playerPos.x = playerPos.x + t[2]/math.abs(t[2])*(math.abs(h)+1) 
            elseif hdg == "west" then
                playerPos.z = playerPos.z + t[2]/math.abs(t[2])*(math.abs(h)+1)
            elseif hdg == "south" then
                playerPos.x = playerPos.x - t[2]/math.abs(t[2])*(math.abs(h)+1)
            elseif hdg == "east" then
                playerPos.z = playerPos.z - t[2]/math.abs(t[2])*(math.abs(h)+1)
            end

            --Move up 1 after every forwad line reposition
            playerPos.y = playerPos.y + v 
        end

        --Move up 1 after every row
        playerPos = minetest.get_player_by_name(name):get_pos()
        playerPos.y = playerPos.y + (v+1) 
    end

end

--PASTE THE NODES REQUESTED BY THE PARAMETERS
function paste_nodes(name,pos,t,t2counter,t3counter,hstep,vstep,xstep,zstep,hdg,mirrored)
    --Clear global
    undonodes = {}

    local playerPos = pos
    if mirrored then
        t2counter = t2counter * -1
        hstep = hstep * -1
    end
    local node_counter = 0

    for v=0, t3counter, vstep do
        for h=0, t2counter, hstep do  

            if tonumber(t[3])<0 then
                playerPos.y = minetest.get_player_by_name(name):get_pos().y + (v-1)  
            end

            --Paste single forward line
            for i=0, t[1]-1, 1 do
                playerPos.x = playerPos.x + xstep
                playerPos.z = playerPos.z + zstep
                node_counter = node_counter + 1
                local node_count = node_counter
                local node_name = nodes[node_count].name
                local node_pos = minetest.pos_to_string({x=playerPos.x,y=playerPos.y,z=playerPos.z})
                local undonode_name = minetest.get_node({x=playerPos.x,y=playerPos.y,z=playerPos.z}).name

                undonodes[node_count] = {position=node_pos,name=undonode_name}
               
                minetest.set_node({x=playerPos.x,y=playerPos.y,z=playerPos.z},{name = node_name})

            end
            playerPos = minetest.get_player_by_name(name):get_pos()

            -- Move sideways 1 after every forward line
            if mirrored then
                if hdg == "north" then
                    playerPos.x = playerPos.x - t[2]/math.abs(t[2])*(math.abs(h)+1) 
                elseif hdg == "west" then
                    playerPos.z = playerPos.z - t[2]/math.abs(t[2])*(math.abs(h)+1)
                elseif hdg == "south" then
                    playerPos.x = playerPos.x + t[2]/math.abs(t[2])*(math.abs(h)+1)
                elseif hdg == "east" then
                    playerPos.z = playerPos.z + t[2]/math.abs(t[2])*(math.abs(h)+1)
                end
            else
                if hdg == "north" then
                    playerPos.x = playerPos.x + t[2]/math.abs(t[2])*(math.abs(h)+1) 
                elseif hdg == "west" then
                    playerPos.z = playerPos.z + t[2]/math.abs(t[2])*(math.abs(h)+1)
                elseif hdg == "south" then
                    playerPos.x = playerPos.x - t[2]/math.abs(t[2])*(math.abs(h)+1)
                elseif hdg == "east" then
                    playerPos.z = playerPos.z - t[2]/math.abs(t[2])*(math.abs(h)+1)
                end
            end

            --Move up 1 after every forwad line reposition
            playerPos.y = playerPos.y + v 
        end

        --Move up 1 after every row
        playerPos = minetest.get_player_by_name(name):get_pos()
        playerPos.y = playerPos.y + (v+1) 
    end
end

--LICENSE INFORMATION
--[[
    
Copyright 2024 MAIgtoS

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files
(the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge,
publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

]]--