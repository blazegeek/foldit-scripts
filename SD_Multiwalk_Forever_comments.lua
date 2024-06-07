-- Sd Multiwalk Forever 2.6
--LUA multiwalker by PB, modified by Stardancer
--USES QUICKSAVE SLOTS 8, 3 & 10
--Added more LUA walkers to those pasted together by PB, changed the order and simplified output.
--1.2 fixed to clean up: unfreeze, reset clash importance, delete bands, etc...
--2.0 added additional functions
--2.02removed AOT Rom Campon (which was generating an error)
--2.3 general cleanup
--2.3.1 translated to Lua v2 (Bruno Kestemont)
--2.4 Filter (porky)
--2.6 Jeffs 1) don't disable existing bands
--			2) ordered display
--			3) List the date & time regularly, like on every line that says
--				"Starting" and on the "All walkers done" line.
--			4) Notes management


--[[ for filter management (bug)
function CopyTable(orig)

    local copy = {}

    for orig_key, orig_value in pairs(orig) do

        copy[orig_key] = orig_value  

    end

    return copy

end



-- functions for filters

function FiltersOn()

    if behavior.GetSlowFiltersDisabled() then

        behavior.SetSlowFiltersDisabled(false)

    end

end

function FiltersOff()

    if behavior.GetSlowFiltersDisabled()==false then

        behavior.SetSlowFiltersDisabled(true)

    end

end



-- function to overload a funtion

function mutFunction(func)

    local currentfunc = func

    local function mutate(func, newfunc)

        local lastfunc = currentfunc

        currentfunc = function(...) return newfunc(lastfunc, ...) end

    end

    local wrapper = function(...) return currentfunc(...) end

    return wrapper, mutate

end





-- function to overload a class

-- to do: set the name of function

classes_copied = 0

myclcp = {}

function MutClass(cl, filters)

    classes_copied = classes_copied+1

    myclcp[classes_copied] = CopyTable(cl)

    local mycl =myclcp[classes_copied]

    for orig_key, orig_value in pairs(cl) do

        myfunc, mutate = mutFunction(mycl[orig_key])

        if filters==true then

            mutate(myfunc, function(...)

                FiltersOn()

                if table.getn(arg)>1 then

                    -- first arg is self (function pointer), we pack from second argument

                    local arguments = {}

                    for i=2,table.getn(arg) do

                        arguments[i-1]=arg[i] 

                    end

                    return mycl[orig_key](unpack(arguments))

                else

                    --print("No arguments")

                    return mycl[orig_key]()

                end

            end)   

            cl[orig_key] = myfunc

        else

            mutate(myfunc, function(...)

                FiltersOff()

                if table.getn(arg)>1 then

                    local arguments = {} 

                    for i=2, table.getn(arg) do

                        arguments[i-1]=arg[i]  

                    end

                    return mycl[orig_key](unpack(arguments))

                else

                    return mycl[orig_key]()

                end

            end)   

            cl[orig_key] = myfunc

        end

           

           

    end    

end





-- how to use:

MutClass(structure, false)
MutClass(band, false)
MutClass(current, true)
MutClass(recentbest, true) -- new BK
MutClass(save, true) -- new BK	


]]--
