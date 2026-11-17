-- lang: Lua, file: escooter_world_540spin.lua
-- target: Escooter World by WorldDevEX on Roblox
-- trick: yaw 540 flat spin only — zero pitch

local CFG = {
    speed_enabled   = false,
    vehicle_speed   = 150,
    walk_speed      = 50,
    nocrash_enabled = false,
    trick_enabled   = false,
    trick_height    = 18,
    trick_lift      = 6,
    trick_spin      = 14,
    trick_drop      = 6,
    trick_pause     = 0.2,
    trick_payout    = 50,
    boost_enabled   = false,
    nocops_enabled  = false,
}

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local lp           = Players.LocalPlayer
local gui_parent   = (gethui and gethui()) or lp:WaitForChild("PlayerGui")

local char, hum, hrp
local function grabChar(c)
    char = c
    hum  = c:WaitForChild("Humanoid")
    hrp  = c:WaitForChild("HumanoidRootPart")
end
if lp.Character then grabChar(lp.Character) end
lp.CharacterAdded:Connect(grabChar)

local function getScooter()
    if not (hum and hum.SeatPart) then return nil end
    return hum.SeatPart:FindFirstAncestorOfClass("Model")
end

local function fireRemotes(tag)
    local rs = game:GetService("ReplicatedStorage")
    local pats = {
        "trick","540","spin","stunt","land","cash",
        "reward","earn","score","combo","grant","complete"
    }
    for _, store in ipairs({rs, workspace}) do
        for _, re in ipairs(store:GetDescendants()) do
            if re:IsA("RemoteEvent") then
                local n = re.Name:lower()
                for _, p in ipairs(pats) do
                    if n:find(p) then
                        pcall(function() re:FireServer(tag) end)
                        pcall(function() re:FireServer() end)
                    end
                end
            end
            if re:IsA("RemoteFunction") then
                local n = re.Name:lower()
                for _, p in ipairs(pats) do
                    if n:find(p) then
                        pcall(function() re:InvokeServer(tag) end)
                    end
                end
            end
        end
    end
end

local function forceTrickValues(state)
    for _, store in ipairs({workspace, lp, char}) do
        if not store then continue end
        for _, v in ipairs(store:GetDescendants()) do
            if v:IsA("BoolValue") then
                local n = v.Name:lower()
                if n:find("trick") or n:find("spin") or n:find("stunt") or n:find("combo") then
                    pcall(function() v.Value = state end)
                end
            end
            if v:IsA("NumberValue") then
                local n = v.Name:lower()
                if n:find("rotation") or n:find("trickcount") or n:find("combo") then
                    pcall(function() v.Value = state and 540 or 0 end)
                end
            end
        end
    end
end

-- ░░ SPEED ░░
RunService.Heartbeat:Connect(function()
    if not CFG.speed_enabled then return end
    if hum then hum.WalkSpeed = CFG.walk_speed end
    local seat = hum and hum.SeatPart
    if seat and seat:IsA("VehicleSeat") then
        seat.MaxSpeed = CFG.vehicle_speed
        seat.Torque   = 9999
    end
    local model = getScooter()
    if not model then return end
    for _, v in ipairs(model:GetDescendants()) do
        if v:IsA("LinearVelocity") then
            if v.VelocityConstraintMode == Enum.VelocityConstraintMode.Line and v.LineVelocity > 1 then
                v.LineVelocity = math.max(v.LineVelocity, CFG.vehicle_speed)
            elseif v.VelocityConstraintMode == Enum.VelocityConstraintMode.Vector then
                local mag = v.VectorVelocity.Magnitude
                if mag > 1 then v.VectorVelocity = v.VectorVelocity.Unit * math.max(mag, CFG.vehicle_speed) end
            end
        end
        if v:IsA("BodyVelocity") then
            local mag = v.Velocity.Magnitude
            if mag > 1 then v.Velocity = v.Velocity.Unit * math.max(mag, CFG.vehicle_speed) end
        end
    end
end)

-- ░░ NO CRASH ░░
RunService.Heartbeat:Connect(function()
    if not CFG.nocrash_enabled then return end
    local model = getScooter()
    if not model then return end
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") and not p.Anchored then
            local av = p.AssemblyAngularVelocity
            if math.abs(av.X) > 0.5 or math.abs(av.Z) > 0.5 then
                p.AssemblyAngularVelocity = Vector3.new(0, av.Y, 0)
            end
        end
    end
end)

-- ░░ BOOST ░░
RunService.Heartbeat:Connect(function()
    if not CFG.boost_enabled then return end
    for _, v in ipairs(lp:GetDescendants()) do
        if v:IsA("NumberValue") then
            local n = v.Name:lower()
            if n:find("boost") or n:find("battery") or n:find("energy") or n:find("stamina") then
                pcall(function() v.Value = v.MaxValue or 100 end)
            end
        end
    end
end)

-- ░░ NO COPS ░░
local function startNoCops()
    local function nuke()
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("Model") then
                local n = v.Name:lower()
                if n:find("cop") or n:find("police") or n:find("officer") or n:find("patrol") then
                    pcall(function() v:Destroy() end)
                end
            end
        end
    end
    nuke()
    workspace.DescendantAdded:Connect(function(v)
        if not CFG.nocops_enabled then return end
        task.wait(0.05)
        if v:IsA("Model") then
            local n = v.Name:lower()
            if n:find("cop") or n:find("police") or n:find("officer") or n:find("patrol") then
                pcall(function() v:Destroy() end)
            end
        end
    end)
end

-- ░░ 540 FLAT SPIN ░░
-- yaw 540 only — zero pitch the whole time
local trickCount, estCash = 0, 0
local trickRunning = false

local function do540Spin()
    if not (char and hum and hrp and hum.Health > 0) then return end
    local scooter = getScooter()
    if not scooter then return end

    local origin = scooter:GetPivot()

    -- lift
    for i = 1, CFG.trick_lift do
        local e = 1-(1-i/CFG.trick_lift)^2
        scooter:PivotTo(origin + Vector3.new(0, CFG.trick_height * e, 0))
        task.wait(0.016)
    end

    local airCF = scooter:GetPivot()
    forceTrickValues(true)
    fireRemotes("trick_540spin")

    -- yaw 540, pitch stays zero the entire time
    for i = 1, CFG.trick_spin do
        local p = i / CFG.trick_spin
        local e = p < 0.5 and 2*p*p or 1-(-2*p+2)^2/2

        local yaw = math.rad(540) * e   -- 1.5 full horizontal rotations

        scooter:PivotTo(
            CFrame.new(airCF.Position)
            * CFrame.Angles(0, yaw, 0)  -- yaw only, no pitch
        )
        task.wait(0.016)
    end

    -- drop — 540 yaw means 180 offset on land, correct back to origin facing
    local finalCF = CFrame.new(origin.Position) * CFrame.Angles(0, math.rad(180), 0)
    for i = 1, CFG.trick_drop do
        local e = (i/CFG.trick_drop)^2
        scooter:PivotTo(scooter:GetPivot():Lerp(finalCF, e))
        task.wait(0.016)
    end

    forceTrickValues(false)
    fireRemotes("land")
    fireRemotes("trick_complete")

    task.wait(CFG.trick_pause)
    trickCount += 1
    estCash    += CFG.trick_payout
end

local function trickLoop()
    while true do
        task.wait(0.05)
        if CFG.trick_enabled and not trickRunning then
            trickRunning = true
            do540Spin()
            trickRunning = false
        end
    end
end
task.spawn(trickLoop)

-- ░░ GUI ░░
local C = {
    bg=Color3.fromRGB(15,15,20), header=Color3.fromRGB(20,20,28), card=Color3.fromRGB(22,22,32),
    accent=Color3.fromRGB(100,180,255), accent2=Color3.fromRGB(60,130,220),
    text=Color3.fromRGB(230,230,240), muted=Color3.fromRGB(120,120,140),
    tog_on=Color3.fromRGB(80,200,120), tog_off=Color3.fromRGB(55,55,70),
    green=Color3.fromRGB(80,200,120), red=Color3.fromRGB(200,70,70),
    gold=Color3.fromRGB(255,200,60), purple=Color3.fromRGB(160,100,255),
}
local function ni(cls,props) local i=Instance.new(cls) for k,v in pairs(props) do i[k]=v end return i end
local function corner(p,r) local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r or 6) c.Parent=p end
local function tw(o,pr,t) TweenService:Create(o,TweenInfo.new(t or 0.15,Enum.EasingStyle.Quad),pr):Play() end

local W,H = 300,460
local sg=ni("ScreenGui",{Name="EscooterWorld540",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=1000,Parent=gui_parent})
local win=ni("Frame",{Size=UDim2.new(0,W,0,H),Position=UDim2.new(0.5,-W/2,0.5,-H/2),BackgroundColor3=C.bg,BorderSizePixel=0,Parent=sg})
corner(win,10)
local str=Instance.new("UIStroke") str.Color=C.accent2 str.Thickness=1.5 str.Parent=win

local hdr=ni("Frame",{Size=UDim2.new(1,0,0,36),BackgroundColor3=C.header,BorderSizePixel=0,Parent=win})
corner(hdr,10)
ni("Frame",{Size=UDim2.new(1,0,0,10),Position=UDim2.new(0,0,1,-10),BackgroundColor3=C.header,BorderSizePixel=0,Parent=hdr})
ni("TextLabel",{Size=UDim2.new(1,-50,1,0),Position=UDim2.new(0,12,0,0),BackgroundTransparency=1,Text="🤖 Escooter World",TextColor3=C.accent,Font=Enum.Font.GothamBold,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,Parent=hdr})
local xbtn=ni("TextButton",{Size=UDim2.new(0,20,0,20),Position=UDim2.new(1,-26,0.5,-10),BackgroundColor3=C.red,Text="×",TextColor3=Color3.fromRGB(255,255,255),Font=Enum.Font.GothamBold,TextSize=14,Parent=hdr})
corner(xbtn,4)
local open=true
xbtn.MouseButton1Click:Connect(function()
    open=not open
    tw(win,{Size=open and UDim2.new(0,W,0,H) or UDim2.new(0,W,0,36)},0.2)
end)

local drag,ds,dp=false
hdr.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true ds=i.Position dp=win.Position end end)
UIS.InputChanged:Connect(function(i) if drag and i.UserInputType==Enum.UserInputType.MouseMovement then local d=i.Position-ds win.Position=UDim2.new(dp.X.Scale,dp.X.Offset+d.X,dp.Y.Scale,dp.Y.Offset+d.Y) end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)

local body=ni("ScrollingFrame",{Size=UDim2.new(1,0,1,-36),Position=UDim2.new(0,0,0,36),BackgroundTransparency=1,ScrollBarThickness=3,ScrollBarImageColor3=C.accent2,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,Parent=win})
ni("UIListLayout",{FillDirection=Enum.FillDirection.Vertical,Padding=UDim.new(0,8),Parent=body})
ni("UIPadding",{PaddingTop=UDim.new(0,10),PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10),Parent=body})

local stats=ni("Frame",{Size=UDim2.new(1,0,0,55),BackgroundColor3=C.card,BorderSizePixel=0,Parent=body}) corner(stats,8)
local trickLbl=ni("TextLabel",{Size=UDim2.new(0.5,0,1,0),BackgroundTransparency=1,Text="TRICKS\n0",TextColor3=C.accent,Font=Enum.Font.GothamBold,TextSize=13,Parent=stats})
local cashLbl=ni("TextLabel",{Size=UDim2.new(0.5,0,1,0),Position=UDim2.new(0.5,0,0,0),BackgroundTransparency=1,Text="EST. CASH\n$0",TextColor3=C.green,Font=Enum.Font.GothamBold,TextSize=13,Parent=stats})

local pill=ni("Frame",{Size=UDim2.new(1,0,0,26),BackgroundColor3=C.card,BorderSizePixel=0,Parent=body}) corner(pill,13)
local statusLbl=ni("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="● IDLE",TextColor3=C.muted,Font=Enum.Font.GothamBold,TextSize=11,Parent=pill})

local function addSection(text, col)
    local l=ni("TextLabel",{Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,Text=text:upper(),TextColor3=col or C.muted,Font=Enum.Font.GothamBold,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,Parent=body})
    ni("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=col or C.muted,BorderSizePixel=0,Parent=l})
end

local function addToggle(label,desc,accentCol,onCb,offCb)
    local row=ni("Frame",{Size=UDim2.new(1,0,0,52),BackgroundColor3=C.card,BorderSizePixel=0,Parent=body}) corner(row,8)
    ni("TextLabel",{Size=UDim2.new(0.7,0,0,24),Position=UDim2.new(0,12,0,8),BackgroundTransparency=1,Text=label,TextColor3=C.text,Font=Enum.Font.GothamBold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,Parent=row})
    ni("TextLabel",{Size=UDim2.new(0.7,0,0,16),Position=UDim2.new(0,12,0,30),BackgroundTransparency=1,Text=desc,TextColor3=C.muted,Font=Enum.Font.Gotham,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,Parent=row})
    local track=ni("Frame",{Size=UDim2.new(0,38,0,20),Position=UDim2.new(1,-50,0.5,-10),BackgroundColor3=C.tog_off,BorderSizePixel=0,Parent=row}) corner(track,10)
    local knob=ni("Frame",{Size=UDim2.new(0,16,0,16),Position=UDim2.new(0,2,0.5,-8),BackgroundColor3=Color3.fromRGB(255,255,255),BorderSizePixel=0,Parent=track}) corner(knob,8)
    local btn=ni("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",Parent=row})
    local state=false
    btn.MouseButton1Click:Connect(function()
        state=not state
        tw(track,{BackgroundColor3=state and (accentCol or C.tog_on) or C.tog_off})
        tw(knob,{Position=state and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)})
        if state and onCb then onCb() end
        if not state and offCb then offCb() end
    end)
end

local function addSlider(label,min,max,default,fmt,cb)
    local row=ni("Frame",{Size=UDim2.new(1,0,0,48),BackgroundColor3=C.card,BorderSizePixel=0,Parent=body}) corner(row,8)
    ni("TextLabel",{Size=UDim2.new(0.6,0,0,20),Position=UDim2.new(0,10,0,5),BackgroundTransparency=1,Text=label,TextColor3=C.text,Font=Enum.Font.GothamBold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,Parent=row})
    local vl=ni("TextLabel",{Size=UDim2.new(0.4,-10,0,20),Position=UDim2.new(0.6,0,0,5),BackgroundTransparency=1,Text=string.format(fmt,default),TextColor3=C.accent,Font=Enum.Font.GothamBold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Right,Parent=row})
    local tr=ni("Frame",{Size=UDim2.new(1,-20,0,5),Position=UDim2.new(0,10,0,32),BackgroundColor3=Color3.fromRGB(30,30,42),BorderSizePixel=0,Parent=row}) corner(tr,3)
    local t0=(default-min)/(max-min)
    local fi=ni("Frame",{Size=UDim2.new(t0,0,1,0),BackgroundColor3=C.accent,BorderSizePixel=0,Parent=tr}) corner(fi,3)
    local kn=ni("Frame",{Size=UDim2.new(0,11,0,11),Position=UDim2.new(t0,-5,0.5,-5),BackgroundColor3=Color3.fromRGB(255,255,255),BorderSizePixel=0,ZIndex=2,Parent=tr}) corner(kn,6)
    local sl=false
    local function sv(x)
        local t=math.clamp((x-tr.AbsolutePosition.X)/tr.AbsoluteSize.X,0,1)
        local v=min+t*(max-min)
        fi.Size=UDim2.new(t,0,1,0) kn.Position=UDim2.new(t,-5,0.5,-5)
        vl.Text=string.format(fmt,v)
        if cb then cb(v) end
    end
    tr.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then sl=true sv(i.Position.X) end end)
    UIS.InputChanged:Connect(function(i) if sl and i.UserInputType==Enum.UserInputType.MouseMovement then sv(i.Position.X) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then sl=false end end)
end

addSection("── speed ──", C.accent)
addToggle("Speed Hack","vehicle + walk override",C.tog_on,
    function() CFG.speed_enabled=true end,
    function() CFG.speed_enabled=false end)
addSlider("Vehicle Speed",50,400,CFG.vehicle_speed,"%g",function(v) CFG.vehicle_speed=v end)

addSection("── physics ──", C.accent)
addToggle("No Crash","locks scooter upright",C.tog_on,
    function() CFG.nocrash_enabled=true end,
    function() CFG.nocrash_enabled=false end)
addToggle("Inf Boost/Battery","maxes energy values",C.tog_on,
    function() CFG.boost_enabled=true end,
    function() CFG.boost_enabled=false end)

addSection("── 540 flat spin ──", C.gold)
addToggle("540 Spin Farm","yaw 540 only — no flip",C.gold,
    function()
        CFG.trick_enabled=true
        statusLbl.Text="● 540 RUNNING"
        statusLbl.TextColor3=C.gold
    end,
    function()
        CFG.trick_enabled=false
        statusLbl.Text="● IDLE"
        statusLbl.TextColor3=C.muted
    end)
addSlider("Jump Height",8,40,CFG.trick_height,"%g st",function(v) CFG.trick_height=v end)
addSlider("Spin Speed",6,28,CFG.trick_spin,"%g fr",function(v) CFG.trick_spin=math.floor(v) end)
addSlider("Land Pause",0.05,1.0,CFG.trick_pause,"%.2fs",function(v) CFG.trick_pause=v end)
addSlider("Payout/rep",10,2000,CFG.trick_payout,"$%g",function(v) CFG.trick_payout=math.floor(v) end)

addSection("── world ──", C.purple)
addToggle("No Cops","client-side delete on spawn",C.purple,
    function() CFG.nocops_enabled=true startNoCops() end,
    function() CFG.nocops_enabled=false end)

local rbtn=ni("TextButton",{Size=UDim2.new(1,0,0,28),BackgroundColor3=Color3.fromRGB(35,35,50),Text="Reset Counter",TextColor3=C.muted,Font=Enum.Font.GothamBold,TextSize=11,BorderSizePixel=0,Parent=body}) corner(rbtn,6)
rbtn.MouseButton1Click:Connect(function() trickCount=0 estCash=0 end)

RunService.Heartbeat:Connect(function()
    trickLbl.Text="TRICKS\n"..trickCount
    cashLbl.Text="EST. CASH\n$"..estCash
    if CFG.trick_enabled and not trickRunning and not getScooter() then
        statusLbl.Text="● WAITING — mount scooter"
        statusLbl.TextColor3=C.muted
    end
end)

UIS.InputBegan:Connect(function(i,g)
    if g then return end
    if i.KeyCode==Enum.KeyCode.RightShift then win.Visible=not win.Visible end
end)

print("[Noob] escooter_world_540spin loaded — RightShift toggles")
