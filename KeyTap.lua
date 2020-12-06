local function KeyTapAction(mods, key)
    -- To be removed and passed on as arguments to function
    local mods = {'ctrl'}
    local key = ''
    local holdTime = 2000
    local pressTimeout = 500
    
    -- Manage the log level. Each print to console checks the log level before printing
    -- logLevel = 0 for no logging, 1 for minimal, 2 - for full
    -- When used in Production, use logLevel = 0
    local logLevel = 1

    -- When any of the arrow keys are pressed, eventtap produces a fn along with arrow keys.
    -- Hence it is required to modify input to the function to match eventtap output, 
    -- when input contains 'fn' or 'arrow' keys. Code block below does that.
    local modsHasFn = false
    for i, v in ipairs(mods) do
        if (v == "fn") then
            modsHasFn = true
            break
        end
    end
    if modsHasFn and key then
        if key == "right" or key == "→" then
            key = 'end'
        elseif key == "left" or key == "←" then
            key = 'home'
        elseif key == "up" or key == "↑" then
            key = 'pageup'
        elseif key == "down" or key == "↓" then
            key = 'pageup'
        end
    else
        if key == "right" or key == "→" or key == "left" or key == "←" or key == "up" or key == "↑" or key ==
            "down" or key == "↓" then
            table.insert(mods, "fn")
        end
    end

    if logLevel > 0 then
        print("Mods = " .. hs.inspect(mods))
        print("Key = " .. key)
    end

    -- Local variables initialization with default values before starting event tap
    local triggered = false
    local holdTimer = nil
    local pressTimer = nil
    local held = false
    local secondPress = false

    local t1 = hs.eventtap.new({hs.eventtap.event.types.flagsChanged, hs.eventtap.event.types.keyDown,
                                hs.eventtap.event.types.keyUp}, function(event)

        local eventType = hs.eventtap.event.types[event:getType()]

        -- With if condition below, ignore repeat keystrokes
        local eventRepeat = event:getProperty(hs.eventtap.event.properties["keyboardEventAutorepeat"])
        if eventRepeat == 0 then

            -- When 'fn' key is pressed and released quickly, keyCode 179 is sent
            -- Code if condition below is to handle this situation, without a warning
            local eventKey
            if event:getKeyCode() == 179 then
                eventKey = "fn?"
            else
                eventKey = hs.keycodes.map[event:getKeyCode()]
            end
            if logLevel > 1 then
                print("*** NEW EVENT: " .. hs.inspect(event:getFlags()) .. eventType .. " - " .. eventKey)
            end
            if logLevel > 0 then
                if hasKey and hasMods then
                    print("KeyCombo (" .. eventType .. " - '" .. eventKey .. "')")
                end
            end

            -- Ensure conditions to trigger are set correctly considering the situations
            -- where only keys are passed, keys and mods are passed and only mods are passed
            local hasMods = event:getFlags():containExactly(mods)
            local hasKey = eventKey == key
            local conditionsMet
            if not key or key == '' then
                conditionsMet = false
                for i, mod in ipairs(mods) do
                    if mod == eventKey then conditionsMet = true end 
                end
                conditionsMet = conditionsMet and hasMods and eventType == 'flagsChanged'
            else
                conditionsMet = hasKey and hasMods and eventType == 'keyDown'
            end

            -- Determine when to trigger actions and when to reset trigger
            -- Narrows down processing of unnecessary key events
            if conditionsMet then
                triggered = true
                if logLevel > 0 then
                    print("✔ Triggered")
                end
            elseif triggered then
                triggered = false
                if logLevel > 0 then
                    print("✘ Trigger reset")
                end
            else
                if logLevel > 1 then
                    print "Skip rest and wait for next key"
                end
                return
            end

            -- Take actions when trigger is set
            if triggered then
                -- Following section is about HOLD
                if not holdTimer or not holdTimer:running() then
                    print("✔ Starting timer for HOLD action within " .. tostring(holdTime / 1000) .. " seconds")
                    holdTimer = hs.timer.doAfter(holdTime / 1000, function()
                        print("▶ Initiating HOLD action")
                        held = true
                    end)
                end

                --Following section is about SINGLE PRESS
                if pressTimer and pressTimer:running() then
                    secondPress = true
                end
            else
                -- Following section is about HOLD
                if holdTimer and holdTimer:running() then
                    holdTimer:stop()
                    print("✘ Cancelling HOLD timer")
                end
                holdTimer = nil
                
                --Following section is about SINGLE PRESS
                if (not pressTimer or not pressTimer:running()) and not held then
                    print("✔ Starting timer for SINGLE PRESS action within " .. tostring(pressTimeout / 1000) .. " seconds")
                    pressTimer = hs.timer.doAfter(pressTimeout / 1000, function()
                        print("▶ Initiating SINGLE PRESS action")
                        pressTimer = nil
                    end)
                end

                --Following section is about DOUBLE PRESS
                if pressTimer and pressTimer:running() and secondPress then
                    print("✔ Detected second press within " .. tostring(pressTimeout / 1000) .. " seconds")
                    pressTimer:stop()
                    pressTimer = nil
                    secondPress = false
                    print("▶ Initiating DOUBLE PRESS action")
                end
                -- Should be after handling SINGLE PRESS as it is used to determine SINGLE PRESS timer initiation
                held = false 
            end
        end
    end)

    t1:start()
end
return KeyTapAction
