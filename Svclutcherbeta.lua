--[[ Svclutcher Hub v3.4 | keyless | Delta Android ]]
local P = game:GetService("Players")
while not P.LocalPlayer do task.wait(0.1) end
local LP = P.LocalPlayer
local VU = game:GetService("VirtualUser")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local TP = game:GetService("TeleportService")
local HS = game:GetService("HttpService")
local RUN = game:GetService("RunService")
local PG = LP:WaitForChild("PlayerGui")

local C = {
bg=Color3.fromRGB(12,13,17), p=Color3.fromRGB(22,24,30), p2=Color3.fromRGB(30,33,42),
st=Color3.fromRGB(46,50,63), a=Color3.fromRGB(124,92,255), t=Color3.fromRGB(232,233,239),
m=Color3.fromRGB(136,141,161), ok=Color3.fromRGB(96,230,150), bad=Color3.fromRGB(255,96,110),
}

local S = {
slap=false, kill=false, click=false, reach=false, size=16, cps=0.08,
fly=false, speed=55, lift=0, noclip=false, ijump=false,
void=false, ragdoll=false, fling=false, knock=false, dodge=false,
esp=false, box=false, tracer=false, dist=600, gloveesp=false,
loot=false, acid=false, drop=false, afk=false,
ws=20, jp=50,
}

local Ch, HRP, Hum, unloaded = nil, nil, nil, false
local conns = {}
local flyBV, stick = nil, Vector3.zero
local lastSafe = Vector3.new()
local orig = setmetatable({}, {__mode="k"})
local ncStore = setmetatable({}, {__mode="k"})
local toggles = {}

local function add(c) conns[#conns+1] = c end
local function ok(f, ...) local a, b = pcall(f, ...) return a and b end

───

local function notify(txt)
local g = PG:FindFirstChild("SvNotif")
if not g then
g = Instance.new("ScreenGui")
g.Name, g.ResetOnSpawn, g.DisplayOrder = "SvNotif", false, 1001
g.Parent = PG
end
local l = Instance.new("TextLabel")
l.BackgroundColor3, l.BorderSizePixel = C.p, 0
l.Size, l.Position = UDim2.new(0, 260, 0, 30), UDim2.new(0.5, -130, 0, 46)
l.Font, l.TextSize, l.TextColor3 = Enum.Font.GothamBold, 12, C.t
l.Text = tostring(txt)
l.Parent = g
Instance.new("UICorner", l).CornerRadius = UDim.new(0, 8)
task.delay(2.2, function()
if l.Parent then
TS:Create(l, TweenInfo.new(0.2), {TextTransparency = 1, BackgroundTransparency = 1}):Play()
task.wait(0.25)
l:Destroy()
end
end)
end

local function bind(c)
Ch = c
HRP = c:WaitForChild("HumanoidRootPart", 10)
Hum = c:FindFirstChildOfClass("Humanoid") or c:WaitForChild("Humanoid", 10)
if HRP and Hum then
lastSafe = HRP.Position
Hum.WalkSpeed, Hum.UseJumpPower, Hum.JumpPower = S.ws, true, S.jp
end
end
bind(LP.Character or LP.CharacterAdded:Wait())
add(LP.CharacterAdded:Connect(bind))

local function alive(p)
if not p or p == LP or not p.Character then return false end
local h = p.Character:FindFirstChildOfClass("Humanoid")
return h ~= nil and h.Health > 0
end
local function hrp(p)
local c = p and p.Character
return c and c:FindFirstChild("HumanoidRootPart")
end
local function glove()
return Ch and Ch:FindFirstChildWhichIsA("Tool")
end
local function touch(a, b)
if a and b and firetouchinterest then
pcall(firetouchinterest, a, b, 0)
pcall(firetouchinterest, a, b, 1)
end
end
local function nearest(maxd)
if not HRP then return nil end
local best, bd
for _, p in ipairs(P:GetPlayers()) do
if alive(p) then
local t = hrp(p)
if t then
local d = (HRP.Position - t.Position).Magnitude
if d <= maxd and (not bd or d < bd) then best, bd = t, d end
end
end
end
return best, bd
end
local function ground(pos)
local rp = RaycastParams.new()
rp.FilterType, rp.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, {Ch}
local hit = workspace:Raycast(Vector3.new(pos.X, 500, pos.Z), Vector3.new(0, -1000, 0), rp)
if hit then return hit.Position + Vector3.new(0, 4, 0) end
end
local function spawnCF()
local sp = workspace:FindFirstChildOfClass("SpawnLocation")
if sp then return sp.CFrame + Vector3.new(0, 4, 0) end
return CFrame.new(0, 150, 0)
end
local function big(h)
if not h then return end
if not orig[h] then
orig[h] = {s=h.Size, t=h.Transparency, c=h.CanCollide, m=h.Massless, b=h.BrickColor}
end
h.Size = Vector3.new(S.size, S.size, S.size)
h.Transparency, h.CanCollide, h.Massless = 0.85, false, true
h.BrickColor = BrickColor.new("Bright red")
end
local function small(h)
local o = orig[h]
if not o or not h.Parent then return end
h.Size, h.Transparency, h.CanCollide = o.s, o.t, o.c
h.Massless, h.BrickColor = o.m, o.b
end

───

-- taken
local tasks = {}
local function reg(iv, fn)
local t = {on=false, iv=iv, acc=0, fn=fn}
tasks[#tasks+1] = t
return t
end
add(RUN.Heartbeat:Connect(function(dt)
for i = 1, #tasks do
local t = tasks[i]
if t.on then
t.acc += dt
if t.acc >= t.iv then t.acc = 0 ok(t.fn) end
end
end
end))

local hitT = reg(0, function()
local g = glove()
if g then big(g:FindFirstChild("Handle") or g:FindFirstChildWhichIsA("BasePart")) end
end)

local slapT = reg(0.06, function()
local g = glove()
if not g then return end
local h = g:FindFirstChild("Handle") or g:FindFirstChildWhichIsA("BasePart")
if not h then return end
big(h)
g:Activate()
for _, p in ipairs(P:GetPlayers()) do
if alive(p) then
local t = hrp(p)
if t and (h.Position - t.Position).Magnitude <= S.size + 6 then touch(h, t) end
end
end
end)

local killT = reg(0.06, function()
local g = glove()
local h = g and (g:FindFirstChild("Handle") or g:FindFirstChildWhichIsA("BasePart"))
if not h then return end
for _, p in ipairs(P:GetPlayers()) do
if alive(p) then
local t = hrp(p)
if t and (h.Position - t.Position).Magnitude <= S.size + 4 then touch(h, t) end
end
end
end)

local clickT = reg(0.08, function()
local cam = workspace.CurrentCamera
if not cam or not glove() then return end
local c = cam.ViewportSize / 2
pcall(VU.Button1Down, VU, c)
pcall(VU.Button1Up, VU, c)
end)

local dodgeT = reg(0.3, function()
if not HRP then return end
for _, p in ipairs(P:GetPlayers()) do
if alive(p) then
local t = hrp(p)
if t and (HRP.Position - t.Position).Magnitude < 7 then
local d = (HRP.Position - t.Position).Unit
HRP.CFrame = HRP.CFrame + Vector3.new(-d.Z, 0, d.X) * 4
return
end
end
end
end)

local voidT = reg(0.2, function()
if HRP and HRP.Position.Y < -60 then
local g = ground(HRP.Position)
HRP.CFrame = g and CFrame.new(g) or spawnCF()
HRP.AssemblyLinearVelocity = Vector3.zero
end
end)

local ragT = reg(0.05, function()
if not Ch then return end
if Hum then
if Hum.PlatformStand and not flyBV then Hum.PlatformStand = false end
if Hum.Sit then Hum.Sit = false end
end
for _, d in ipairs(Ch:GetDescendants()) do
if d:IsA("BallSocketConstraint") then d:Destroy() end
end
end)

local knockT = reg(0, function()
if not HRP then return end
local v = HRP.AssemblyLinearVelocity
if Vector3.new(v.X, 0, v.Z).Magnitude > 60 then
HRP.AssemblyLinearVelocity = Vector3.new(v.X * 0.15, v.Y, v.Z * 0.15)
end
end)

local flingT = reg(0.1, function()
if not HRP then return end
local p = HRP.Position
if p.X ~= p.X or p.Y ~= p.Y then HRP.CFrame = CFrame.new(lastSafe) return end
if HRP.AssemblyLinearVelocity.Magnitude > 1500 then HRP.AssemblyLinearVelocity = Vector3.zero end
if HRP.AssemblyLinearVelocity.Magnitude < 400 then lastSafe = p end
end)

local acidT = reg(0.15, function()
if not HRP then return end
for _, d in ipairs(workspace:GetDescendants()) do
if d:IsA("BasePart") and string.find(string.lower(d.Name), "acid") then
local r = d.CFrame:PointToObjectSpace(HRP.Position)
local s = d.Size / 2
if math.abs(r.X) <= s.X and math.abs(r.Y) <= s.Y and math.abs(r.Z) <= s.Z then
HRP.CFrame = d.CFrame + Vector3.new(0, s.Y + 5, 0)
HRP.AssemblyLinearVelocity = Vector3.zero
return
end
end
end
end)

local lootT = reg(0.25, function()
if not HRP then return end
for _, d in ipairs(workspace:GetDescendants()) do
if d:IsA("BasePart") and string.find(string.lower(d.Name), "pickup") then
if (d.Position - HRP.Position).Magnitude < 40 then touch(HRP, d) end
end
end
end)

local dropT = reg(0.3, function()
if not HRP or flyBV or HRP.Position.Y < 75 then return end
local g = ground(HRP.Position)
if g then
HRP.CFrame = CFrame.new(g)
HRP.AssemblyLinearVelocity = Vector3.zero
end
end)

───

-- fly
local ctrl
local function controls()
if ctrl ~= nil then return ctrl or nil end
local a, pm = pcall(function()
return require(LP:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
end)
if a and pm then
local b, c = pcall(function() return pm:GetControls() end)
ctrl = (b and c) or false
else
ctrl = false
end
return ctrl or nil
end

local function flyOn()
if flyBV or not HRP then return end
flyBV = Instance.new("BodyVelocity")
flyBV.MaxForce = Vector3.new(1e6, 1e6, 1e6)
flyBV.Parent = HRP
if Hum then Hum.PlatformStand = true end
end
local function flyOff()
if flyBV then flyBV:Destroy() flyBV = nil end
stick = Vector3.zero
if Hum then
Hum.PlatformStand = false
Hum:ChangeState(Enum.HumanoidStateType.GettingUp)
end
end

add(RUN.RenderStepped:Connect(function()
if not flyBV or not HRP then return end
local cam = workspace.CurrentCamera
if not cam then return end
local mv = Vector3.zero
local c = controls()
if c then
local a, v = pcall(function() return c:GetMoveVector() end)
if a and v and v.Magnitude > 0.05 then mv = v end
end
if mv.Magnitude < 0.05 and stick.Magnitude > 0.05 then mv = stick end
if mv.Magnitude > 1 then mv = mv.Unit end
local dir = cam.CFrame:VectorToWorldSpace(Vector3.new(mv.X, 0, mv.Z))
flyBV.Velocity = dir * S.speed + Vector3.new(0, S.lift, 0)
end))

───

-- UI
local function build()
if PG:FindFirstChild("SvHub") then
PG.SvHub:Destroy()
end

local g = Instance.new("ScreenGui")
g.Name, g.ResetOnSpawn, g.DisplayOrder = "SvHub", false, 999

local m = Instance.new("Frame")
m.BackgroundColor3, m.BorderSizePixel = C.bg, 0
m.Position, m.Size = UDim2.new(0, 10, 0, 50), UDim2.new(0, 290, 0, 400)
m.Active, m.ClipsDescendants = true, true
m.Parent = g
Instance.new("UICorner", m).CornerRadius = UDim.new(0, 12)

local ms = Instance.new("UIStroke", m)
ms.Color = C.st

local hd = Instance.new("Frame")
hd.BackgroundColor3, hd.BorderSizePixel, hd.Size = C.p, 0, UDim2.new(1, 0, 0, 36)
hd.Parent = m
Instance.new("UICorner", hd).CornerRadius = UDim.new(0, 12)

local ti = Instance.new("TextLabel")
ti.BackgroundTransparency = 1
ti.Position, ti.Size = UDim2.new(0, 12, 0, 0), UDim2.new(1, -80, 1, 0)
ti.Font, ti.TextSize, ti.TextColor3 = Enum.Font.GothamBold, 12, C.t
ti.TextXAlignment = Enum.TextXAlignment.Left
ti.Text = "Svclutcher Hub"
ti.Parent = hd

local function makeHeaderButton(text, xOffset, color)
local button = Instance.new("TextButton")
button.BackgroundColor3, button.BorderSizePixel = C.p2, 0
button.Position = UDim2.new(1, xOffset, 0.5, -10)
button.Size = UDim2.new(0, 20, 0, 20)
button.Font, button.TextSize = Enum.Font.GothamBold, 14
button.TextColor3, button.Text = color or C.t, text
button.Parent = hd

Instance.new("UICorner", button).CornerRadius = UDim.new(0, 5)
return button
end

local toggleButton = makeHeaderButton("−", -54, C.a)
local closeButton = makeHeaderButton("×", -30, C.bad)

local sc = Instance.new("ScrollingFrame")
sc.BackgroundTransparency, sc.BorderSizePixel = 1, 0
sc.Position, sc.Size = UDim2.new(0, 0, 0, 40), UDim2.new(1, 0, 1, -40)
sc.ScrollBarThickness, sc.CanvasSize = 2, UDim2.new(0, 0, 0, 0)
sc.AutomaticCanvasSize = Enum.AutomaticSize.Y
sc.Parent = m

local pd = Instance.new("UIPadding", sc)
pd.PaddingLeft, pd.PaddingRight = UDim.new(0, 8), UDim.new(0, 8)
pd.PaddingTop, pd.PaddingBottom = UDim.new(0, 6), UDim.new(0, 8)

local ly = Instance.new("UIListLayout", sc)
ly.Padding, ly.SortOrder = UDim.new(0, 4), Enum.SortOrder.LayoutOrder

local ord = 0
local function nextOrd()
ord += 1
return ord
end

local function sect(name)
local label = Instance.new("TextLabel")
label.BackgroundTransparency = 1
label.Size = UDim2.new(1, 0, 0, 18)
label.LayoutOrder = nextOrd()
label.Font, label.TextSize = Enum.Font.GothamBold, 9
label.TextXAlignment, label.TextColor3 = Enum.TextXAlignment.Left, C.m
label.Text = name
label.Parent = sc
end

local function toggle(label, key, cb)
local row = Instance.new("TextButton")
row.BackgroundColor3, row.BorderSizePixel = C.p, 0
row.AutoButtonColor = false
row.Size, row.LayoutOrder, row.Text = UDim2.new(1, 0, 0, 32), nextOrd(), ""
row.Parent = sc
Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

local text = Instance.new("TextLabel")
text.BackgroundTransparency = 1
text.Position, text.Size = UDim2.new(0, 10, 0, 0), UDim2.new(1, -54, 1, 0)
text.Font, text.TextSize = Enum.Font.GothamMedium, 12
text.TextXAlignment, text.TextColor3 = Enum.TextXAlignment.Left, C.t
text.Text = label
text.Parent = row

local track = Instance.new("Frame")
track.BackgroundColor3, track.BorderSizePixel = C.p2, 0
track.Position, track.Size = UDim2.new(1, -44, 0.5, -9), UDim2.new(0, 34, 0, 18)
track.Parent = row
Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

local knob = Instance.new("Frame")
knob.BackgroundColor3, knob.BorderSizePixel = C.m, 0
knob.Position, knob.Size = UDim2.new(0, 2, 0.5, -7), UDim2.new(0, 14, 0, 14)
knob.Parent = track
Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

local on = false
local function set(value, force)
if on == value and not force then
return
end

on, S[key] = value, value
knob.Position = value
and UDim2.new(1, -16, 0.5, -7)
or UDim2.new(0, 2, 0.5, -7)
knob.BackgroundColor3 = value and C.a or C.m
track.BackgroundColor3 = value and Color3.fromRGB(52, 42, 96) or C.p2

if cb and not force then
ok(cb, value)
end
end

row.MouseButton1Click:Connect(function()
set(not on)
end)

toggles[key] = set
end

local function cycle(label, key, list)
local row = Instance.new("TextButton")
row.BackgroundColor3, row.BorderSizePixel = C.p, 0
row.AutoButtonColor = false
row.Size, row.LayoutOrder, row.Text = UDim2.new(1, 0, 0, 32), nextOrd(), ""
row.Parent = sc
Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

local text = Instance.new("TextLabel")
text.BackgroundTransparency = 1
text.Position, text.Size = UDim2.new(0, 10, 0, 0), UDim2.new(1, -70, 1, 0)
text.Font, text.TextSize = Enum.Font.GothamMedium, 12
text.TextXAlignment, text.TextColor3 = Enum.TextXAlignment.Left, C.t
text.Text = label
text.Parent = row

local choice = Instance.new("TextLabel")
choice.BackgroundColor3, choice.BorderSizePixel = C.p2, 0
choice.Position, choice.Size = UDim2.new(1, -58, 0.5, -10), UDim2.new(0, 48, 0, 20)
choice.Font, choice.TextSize, choice.TextColor3 = Enum.Font.GothamBold, 10, C.a
choice.Parent = row
Instance.new("UICorner", choice).CornerRadius = UDim.new(0, 5)

local index = 1
for i, value in ipairs(list) do
if value == S[key] then
index = i
break
end
end

local function draw()
choice.Text = tostring(list[index])
end

draw()

row.MouseButton1Click:Connect(function()
index = (index % #list) + 1
S[key] = list[index]
draw()
end)
end

local function action(label, fn)
local button = Instance.new("TextButton")
button.BackgroundColor3, button.BorderSizePixel = C.p, 0
button.Size, button.LayoutOrder = UDim2.new(1, 0, 0, 30), nextOrd()
button.Font, button.TextSize = Enum.Font.GothamMedium, 12
button.Text, button.TextColor3 = label, C.t
button.Parent = sc
Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

local stroke = Instance.new("UIStroke", button)
stroke.Color = C.st

button.MouseButton1Click:Connect(function()
ok(fn)
end)
end

sect("COMBAT")
toggle("Slap Aura", "slap")
toggle("Kill Aura", "kill")
toggle("Auto Clicker", "click")
cycle("CPS", "cps", {0.05, 0.08, 0.12, 0.2})
cycle("Reach", "size", {8, 16, 24, 32})
toggle("Hitbox Reach", "reach", function(value)
if not value and not S.slap then
for hitbox in pairs(orig) do
small(hitbox)
end
end
end)

sect("MOVE")
toggle("Fly (joystick)", "fly", function(value)
if value then
flyOn()
else
flyOff()
end
end)
cycle("FlySpeed", "speed", {35, 55, 90})
cycle("WalkSpeed", "ws", {16, 20, 45, 75, 120})
cycle("JumpPower", "jp", {50, 90, 150})
toggle("Infinite Jump", "ijump")

toggle("Noclip", "noclip", function(value)
if not Ch then
return
end

for _, descendant in ipairs(Ch:GetDescendants()) do
if descendant:IsA("BasePart") then
if value then
if ncStore[descendant] == nil then
ncStore[descendant] = descendant.CanCollide
end
descendant.CanCollide = false
elseif ncStore[descendant] ~= nil then
descendant.CanCollide = ncStore[descendant]
end
end
end
end)

sect("DEFEND")
toggle("Anti Void", "void")
toggle("Anti Ragdoll", "ragdoll")
toggle("Anti Fling", "fling")
toggle("Anti Knockback", "knock")
toggle("Auto Dodge", "dodge")
toggle("Anti AFK", "afk")

sect("ESP")
toggle("Player ESP", "esp")
toggle("Box ESP", "box")
toggle("Tracers", "tracer")
cycle("Distance", "dist", {200, 600, 1500})

sect("ROYALE")
toggle("Auto Loot", "loot")
toggle("Anti Acid", "acid")
toggle("Auto Drop", "drop")

action("TP to nearest", function()
local target = nearest(500)
if target and HRP then
HRP.CFrame = target.CFrame * CFrame.new(0, 0, 3)
end
end)

action("TP safe ground", function()
if not HRP then
return
end

local groundPosition = ground(HRP.Position)
HRP.CFrame = groundPosition and CFrame.new(groundPosition) or spawnCF()
end)

sect("SERVER")
action("Rejoin", function()
notify("Rejoining...")
task.wait(0.3)
ok(TP.Teleport, TP, game.PlaceId, LP)
end)

action("Server hop", function()
local req = request or http_request
if not req then
return notify("No HTTP")
end

local success, response = pcall(req, {
Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100",
Method = "GET",
})

if not success or not response or not response.Body then
return notify("Hop failed")
end

local decoded, data = pcall(function()
return HS:JSONDecode(response.Body)
end)

if not decoded then
return notify("Hop failed")
end

for _, server in ipairs(data.data or {}) do
if server.id ~= game.JobId and server.playing < server.maxPlayers then
ok(TP.TeleportToPlaceInstance, TP, game.PlaceId, server.id, LP)
return
end
end

notify("No server")
end)

sect("MISC")
action("FPS boost", function()
ok(function()
settings().Rendering.QualityLevel = Enum.QualityLevel.Level01

for _, descendant in ipairs(workspace:GetDescendants()) do
if descendant:IsA("ParticleEmitter") then
descendant.Enabled = false
end
end
end)

notify("Boost applied")
end)

action("UNLOAD", function()
unloaded = true
flyOff()

for hitbox in pairs(orig) do
small(hitbox)
end

for _, connection in ipairs(conns) do
ok(function()
connection:Disconnect()
end)
end

local notificationGui = PG:FindFirstChild("SvNotif")
if notificationGui then
notificationGui:Destroy()
end

g:Destroy()
end)

local collapsed = false
local expandedSize = m.Size

toggleButton.MouseButton1Click:Connect(function()
collapsed = not collapsed
sc.Visible = not collapsed
m.Size = collapsed
and UDim2.new(expandedSize.X.Scale, expandedSize.X.Offset, 0, 36)
or expandedSize
toggleButton.Text = collapsed and "+" or "−"
end)

closeButton.MouseButton1Click:Connect(function()
m.Visible = false
end)

local drag, dragStart, startPosition

hd.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.Touch
or input.UserInputType == Enum.UserInputType.MouseButton1 then
drag, dragStart, startPosition = true, input.Position, m.Position

input.Changed:Connect(function()
if input.UserInputState == Enum.UserInputState.End then
drag = false
end
end)
end
end)

add(UIS.InputChanged:Connect(function(input)
if not drag then
return
end

if input.UserInputType == Enum.UserInputType.Touch
or input.UserInputType == Enum.UserInputType.MouseMovement then
local delta = input.Position - dragStart
m.Position = UDim2.new(
0,
startPosition.X.Offset + delta.X,
0,
startPosition.Y.Offset + delta.Y
)
end
end))

g.Parent = PG
return g
end

───

-- loops
local map = {
slap=slapT, kill=killT, click=clickT, reach=hitT, dodge=dodgeT,
void=voidT, ragdoll=ragT, fling=flingT, knock=knockT,
loot=lootT, acid=acidT, drop=dropT,
}

task.spawn(function()
while not unloaded do
RUN.Heartbeat:Wait()
for k, t in pairs(map) do t.on = S[k] == true end
clickT.iv = S.cps
if Hum and Hum.Parent then
if Hum.WalkSpeed ~= S.ws then Hum.WalkSpeed = S.ws end
if Hum.UseJumpPower and Hum.JumpPower ~= S.jp then Hum.JumpPower = S.jp end
end
end
end)

add(UIS.JumpRequest:Connect(function()
if S.ijump and Hum then Hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end))

add(LP.Idled:Connect(function()
if not S.afk then return end
VU:CaptureController()
VU:ClickButton2(Vector2.new(0.5, 0.5))
end))

───

local okRun, err = xpcall(function()
local g = build()
notify("Svclutcher loaded")
print("[Svclutcher] ready")

-- ESP simpel
local tags = {}
task.spawn(function()
while not unloaded do
RUN.Heartbeat:Wait()
for _, p in ipairs(P:GetPlayers()) do
if p ~= LP and p.Character then
local hd2 = p.Character:FindFirstChild("Head")
if S.esp and hd2 and not tags[p] then
local bb = Instance.new("BillboardGui")
bb.Size, bb.StudsOffset, bb.AlwaysOnTop, bb.MaxDistance = UDim2.new(0, 160, 0, 18), Vector3.new(0, 3, 0), true, S.dist
bb.Parent = hd2
local l = Instance.new("TextLabel")
l.BackgroundTransparency, l.Size, l.Font, l.TextSize = 1, UDim2.new(1, 0, 1, 0), Enum.Font.GothamBold, 12
l.TextColor3, l.TextStrokeTransparency, l.Text = C.t, 0.4, p.DisplayName
l.Parent = bb
tags[p] = bb
elseif not S.esp and tags[p] then
tags[p]:Destroy()
tags[p] = nil
end
end
end
for p, bb in pairs(tags) do
if not p.Parent or not p.Character then
bb:Destroy()
tags[p] = nil
end
end
end
end)
end, function(e)
return tostring(e)
end)

if not okRun then
print("[Svclutcher] ERROR: " .. tostring(err))
notify("ERROR: " .. tostring(err))
end
