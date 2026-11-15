--[[ Svclutcher Hub v3.7 | keyless | Delta Android | WindUI retro-hacker ]]

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

-- ─────────────────────────────────────────────── WindUI

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local THEME = "RetroHacker"
pcall(function()
	WindUI:AddTheme({
		Name = THEME,
		Accent = Color3.fromHex("#39FF6A"),
		Background = Color3.fromHex("#060A07"),
		Outline = Color3.fromHex("#1C3621"),
		Text = Color3.fromHex("#B0FFC2"),
		Placeholder = Color3.fromHex("#4E7A58"),
		Button = Color3.fromHex("#123B1E"),
		Icon = Color3.fromHex("#39FF6A"),
		Hover = Color3.fromHex("#1B4D26"),
		WindowBackground = Color3.fromHex("#040705"),
		WindowShadow = Color3.fromHex("#000000"),
		Dialog = Color3.fromHex("#0A0F0B"),
	})
end)

-- ─────────────────────────────────────────────── state

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
local savedPos = nil

local function add(c) conns[#conns+1] = c end
local function ok(f, ...) local a, b = pcall(f, ...) return a and b end

local function notify(content, title)
	pcall(function()
		WindUI:Notify({
			Title = title or "svclutcher",
			Content = tostring(content),
			Duration = 3,
			Icon = "terminal",
		})
	end)
end

-- ─────────────────────────────────────────────── character

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

-- ─────────────────────────────────────────────── tasks

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

local noclipT = reg(0.2, function()
	if not Ch then return end
	for _, d in ipairs(Ch:GetDescendants()) do
		if d:IsA("BasePart") and d.CanCollide then
			if ncStore[d] == nil then ncStore[d] = true end
			d.CanCollide = false
		end
	end
end)

-- ─────────────────────────────────────────────── fly

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

-- ─────────────────────────────────────────────── ESP

local espGui, espCache

local function ensureESP()
	if espGui and espGui.Parent then return espGui end
	espGui = Instance.new("ScreenGui")
	espGui.Name, espGui.ResetOnSpawn = "SvESP", false
	espGui.DisplayOrder, espGui.IgnoreGuiInset = 998, true
	espGui.Parent = PG
	espCache = {}
	return espGui
end

local function newESP(p)
	local gui = ensureESP()
	local e = {}

	e.box = Instance.new("Frame")
	e.box.AnchorPoint = Vector2.new(0.5, 0)
	e.box.BackgroundTransparency, e.box.BorderSizePixel = 1, 0
	e.box.Visible = false
	e.box.ZIndex = 2
	e.box.Parent = gui
	local bs = Instance.new("UIStroke", e.box)
	bs.Color, bs.Thickness, bs.Transparency = Color3.fromHex("#39FF6A"), 1, 0.25

	e.tracer = Instance.new("Frame")
	e.tracer.AnchorPoint = Vector2.new(0.5, 0.5)
	e.tracer.BackgroundColor3, e.tracer.BorderSizePixel = Color3.fromHex("#1F8A3A"), 0
	e.tracer.BackgroundTransparency = 0.35
	e.tracer.Visible = false
	e.tracer.ZIndex = 1
	e.tracer.Parent = gui

	e.tag = Instance.new("BillboardGui")
	e.tag.Size, e.tag.StudsOffset = UDim2.new(0, 170, 0, 16), Vector3.new(0, 3.2, 0)
	e.tag.AlwaysOnTop, e.tag.MaxDistance, e.tag.Enabled = true, S.dist, false
	e.tag.Adornee = p.Character and p.Character:FindFirstChild("Head")
	e.tag.Parent = p.Character and p.Character:FindFirstChild("Head") or gui

	e.label = Instance.new("TextLabel")
	e.label.BackgroundTransparency = 1
	e.label.Size = UDim2.new(1, 0, 1, 0)
	e.label.Font, e.label.TextSize = Enum.Font.Code, 12
	e.label.TextColor3 = Color3.fromHex("#39FF6A")
	e.label.TextStrokeTransparency, e.label.TextStrokeColor3 = 0.2, Color3.fromRGB(4, 7, 5)
	e.label.Text = ""
	e.label.Parent = e.tag

	e.gtag = Instance.new("BillboardGui")
	e.gtag.Size, e.gtag.StudsOffset = UDim2.new(0, 150, 0, 16), Vector3.new(0, 1.2, 0)
	e.gtag.AlwaysOnTop, e.gtag.MaxDistance, e.gtag.Enabled = true, S.dist, false
	e.gtag.Parent = gui

	e.glabel = Instance.new("TextLabel")
	e.glabel.BackgroundTransparency = 1
	e.glabel.Size = UDim2.new(1, 0, 1, 0)
	e.glabel.Font, e.glabel.TextSize = Enum.Font.Code, 11
	e.glabel.TextColor3 = Color3.fromHex("#FFB000")
	e.glabel.TextStrokeTransparency, e.glabel.TextStrokeColor3 = 0.2, Color3.fromRGB(4, 7, 5)
	e.glabel.Text = ""
	e.glabel.Parent = e.gtag

	espCache[p] = e
	return e
end

local function clearESP(p)
	local e = espCache[p]
	if not e then return end
	for _, o in ipairs({e.box, e.tracer, e.tag, e.gtag}) do
		if o then o:Destroy() end
	end
	espCache[p] = nil
end

local function updateESP(p, e, cam)
	local hr = hrp(p)
	if not hr then return end
	local head = p.Character and p.Character:FindFirstChild("Head")
	if e.tag.Adornee ~= head then
		e.tag.Adornee = head
		e.tag.Parent = head or ensureESP()
	end

	local tool = p.Character and p.Character:FindFirstChildWhichIsA("Tool")
	local gHandle = tool and (tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart"))
	e.gtag.Adornee = gHandle
	e.gtag.Enabled = S.gloveesp and gHandle ~= nil
	if gHandle then e.glabel.Text = tool.Name end

	local dist = (cam.CFrame.Position - hr.Position).Magnitude
	e.tag.MaxDistance = S.dist
	e.tag.Enabled = S.esp and dist <= S.dist
	e.label.Text = string.format("%s [%d]", p.DisplayName, math.floor(dist))

	local top = cam:WorldToViewportPoint(hr.Position + Vector3.new(0, 2.7, 0))
	local bot = cam:WorldToViewportPoint(hr.Position - Vector3.new(0, 2.7, 0))
	local vis = top.Z > 0 and bot.Z > 0 and dist <= S.dist

	if not vis then
		e.box.Visible, e.tracer.Visible = false, false
		return
	end

	local h = math.abs(bot.Y - top.Y)
	local w = h * 0.55
	e.box.Visible = S.box
	e.box.Position = UDim2.fromOffset(top.X, top.Y)
	e.box.Size = UDim2.fromOffset(w, h)

	if S.tracer then
		local vp = cam.ViewportSize
		local o = Vector2.new(vp.X / 2, vp.Y)
		local tg = Vector2.new(top.X, top.Y)
		local d = tg - o
		local mid = (o + tg) / 2
		e.tracer.Visible = true
		e.tracer.Position = UDim2.fromOffset(mid.X, mid.Y)
		e.tracer.Size = UDim2.fromOffset(d.Magnitude, 1)
		e.tracer.Rotation = math.deg(math.atan2(d.Y, d.X))
	else
		e.tracer.Visible = false
	end
end

task.spawn(function()
	while not unloaded do
		RUN.RenderStepped:Wait()
		local cam = workspace.CurrentCamera
		if not (S.esp or S.box or S.tracer or S.gloveesp) or not cam then
			if espGui then espGui.Enabled = false end
		else
			ensureESP().Enabled = true
			for _, p in ipairs(P:GetPlayers()) do
				if p ~= LP and alive(p) then
					updateESP(p, espCache[p] or newESP(p), cam)
				elseif espCache[p] then
					clearESP(p)
				end
			end
		end
	end
end)

-- ─────────────────────────────────────────────── window

local Window = WindUI:CreateWindow({
	Title = "svclutcher@delta",
	Icon = "terminal",
	Author = "v3.7 | keyless | windui",
	Folder = "SvclutcherHub",
	Size = UDim2.fromOffset(540, 420),
	MinSize = Vector2.new(340, 300),
	MaxSize = Vector2.new(780, 640),
	Theme = THEME,
	Transparent = true,
	Resizable = true,
	SideBarWidth = 165,
	HideSearchBar = false,
	ScrollBarEnabled = true,
	ToggleKey = Enum.KeyCode.RightShift,
})

-- ─────────────────────────────────────────────── combat

local combat = Window:Tab({ Title = "Combat", Icon = "swords" })
local cSec = combat:Section({ Title = "Auras", TextXAlignment = "Left", TextSize = 15 })

cSec:Toggle({ Title = "Slap Aura", Desc = "Auto-activate + hitbox around you", Value = false, Callback = function(v) S.slap = v end })
cSec:Toggle({ Title = "Kill Aura", Desc = "Touch every player in hitbox range", Value = false, Callback = function(v) S.kill = v end })
cSec:Toggle({ Title = "Auto Clicker", Desc = "Virtual clicks at screen centre", Value = false, Callback = function(v) S.click = v end })

local cCfg = combat:Section({ Title = "Tuning", TextXAlignment = "Left", TextSize = 15 })
cCfg:Slider({ Title = "Hitbox Size", Step = 1, Value = { Min = 6, Max = 40, Default = 16 }, Callback = function(v) S.size = v end })
cCfg:Slider({ Title = "Click Delay", Step = 0.01, Value = { Min = 0.03, Max = 0.3, Default = 0.08 }, Callback = function(v) S.cps = v end })
cCfg:Toggle({ Title = "Hitbox Reach", Desc = "Keep hitbox big while holding a glove", Value = false, Callback = function(v)
	S.reach = v
	if not v and not S.slap then
		for h in pairs(orig) do small(h) end
	end
end })

combat:Button({ Title = "Activate Tool", Desc = "Fire the equipped glove once", Callback = function()
	local g = glove()
	if g then ok(function() g:Activate() end) end
end })

combat:Button({ Title = "TP to Nearest", Desc = "Jump to closest player", Callback = function()
	local t = nearest(500)
	if t and HRP then HRP.CFrame = t.CFrame * CFrame.new(0, 0, 3) end
end })

-- ─────────────────────────────────────────────── movement

local move = Window:Tab({ Title = "Movement", Icon = "move" })
local mSec = move:Section({ Title = "Flight", TextXAlignment = "Left", TextSize = 15 })

mSec:Toggle({ Title = "Fly", Desc = "Joystick / WASD flight", Value = false, Callback = function(v)
	if v then flyOn() else flyOff() end
end })
mSec:Slider({ Title = "Fly Speed", Step = 1, Value = { Min = 20, Max = 200, Default = 55 }, Callback = function(v) S.speed = v end })
mSec:Slider({ Title = "Fly Lift", Step = 1, Value = { Min = -40, Max = 100, Default = 0 }, Callback = function(v) S.lift = v end })

local mGround = move:Section({ Title = "Ground", TextXAlignment = "Left", TextSize = 15 })
mGround:Slider({ Title = "Walk Speed", Step = 1, Value = { Min = 16, Max = 200, Default = 20 }, Callback = function(v) S.ws = v end })
mGround:Slider({ Title = "Jump Power", Step = 1, Value = { Min = 50, Max = 300, Default = 50 }, Callback = function(v) S.jp = v end })
mGround:Toggle({ Title = "Infinite Jump", Value = false, Callback = function(v) S.ijump = v end })
mGround:Toggle({ Title = "Noclip", Desc = "Survives respawn", Value = false, Callback = function(v)
	S.noclip = v
	if not v and Ch then
		for _, d in ipairs(Ch:GetDescendants()) do
			if d:IsA("BasePart") and ncStore[d] ~= nil then
				d.CanCollide = ncStore[d]
				ncStore[d] = nil
			end
		end
	end
end })

local mPos = move:Section({ Title = "Position", TextXAlignment = "Left", TextSize = 15 })
mPos:Button({ Title = "Save Position", Callback = function()
	if HRP then
		savedPos = HRP.CFrame
		notify("Position saved")
	end
end })
mPos:Button({ Title = "Load Position", Callback = function()
	if savedPos and HRP then
		HRP.CFrame = savedPos
		notify("Position loaded")
	end
end })
mPos:Button({ Title = "TP Safe Ground", Callback = function()
	if not HRP then return end
	local g = ground(HRP.Position)
	HRP.CFrame = g and CFrame.new(g) or spawnCF()
end })

-- ─────────────────────────────────────────────── defence

local defend = Window:Tab({ Title = "Defence", Icon = "shield" })
local dSec = defend:Section({ Title = "Protection", TextXAlignment = "Left", TextSize = 15 })

dSec:Toggle({ Title = "Anti Void", Value = false, Callback = function(v) S.void = v end })
dSec:Toggle({ Title = "Anti Ragdoll", Value = false, Callback = function(v) S.ragdoll = v end })
dSec:Toggle({ Title = "Anti Fling", Value = false, Callback = function(v) S.fling = v end })
dSec:Toggle({ Title = "Anti Knockback", Value = false, Callback = function(v) S.knock = v end })
dSec:Toggle({ Title = "Auto Dodge", Value = false, Callback = function(v) S.dodge = v end })
dSec:Toggle({ Title = "Anti AFK", Value = false, Callback = function(v) S.afk = v end })

-- ─────────────────────────────────────────────── visuals

local vis = Window:Tab({ Title = "Visuals", Icon = "eye" })
local vSec = vis:Section({ Title = "ESP", TextXAlignment = "Left", TextSize = 15 })

vSec:Toggle({ Title = "Player ESP", Desc = "Name + distance", Value = false, Callback = function(v) S.esp = v end })
vSec:Toggle({ Title = "Box ESP", Value = false, Callback = function(v) S.box = v end })
vSec:Toggle({ Title = "Tracers", Value = false, Callback = function(v) S.tracer = v end })
vSec:Toggle({ Title = "Glove ESP", Desc = "Show equipped tool name", Value = false, Callback = function(v) S.gloveesp = v end })
vSec:Slider({ Title = "Max Distance", Step = 50, Value = { Min = 100, Max = 2000, Default = 600 }, Callback = function(v) S.dist = v end })

-- ─────────────────────────────────────────────── royale

local roy = Window:Tab({ Title = "Royale", Icon = "gem" })
local rSec = roy:Section({ Title = "Automation", TextXAlignment = "Left", TextSize = 15 })

rSec:Toggle({ Title = "Auto Loot", Value = false, Callback = function(v) S.loot = v end })
rSec:Toggle({ Title = "Anti Acid", Value = false, Callback = function(v) S.acid = v end })
rSec:Toggle({ Title = "Auto Drop", Desc = "Land on ground below", Value = false, Callback = function(v) S.drop = v end })

roy:Section({ Title = "Utility", TextXAlignment = "Left", TextSize = 15 }):Button({ Title = "TP to Nearest Loot", Callback = function()
	if not HRP then return end
	local best, bd
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("BasePart") and string.find(string.lower(d.Name), "pickup") then
			local dist = (d.Position - HRP.Position).Magnitude
			if not bd or dist < bd then best, bd = d, dist end
		end
	end
	if best then HRP.CFrame = CFrame.new(best.Position + Vector3.new(0, 4, 0)) end
end })

-- ─────────────────────────────────────────────── server

local srv = Window:Tab({ Title = "Server", Icon = "globe" })
local sSec = srv:Section({ Title = "Session", TextXAlignment = "Left", TextSize = 15 })

sSec:Button({ Title = "Rejoin", Callback = function()
	notify("Rejoining...")
	task.wait(0.3)
	ok(TP.Teleport, TP, game.PlaceId, LP)
end })

sSec:Button({ Title = "Server Hop", Desc = "Lowest populated server", Callback = function()
	local req = request or http_request
	if not req then return notify("No HTTP executor", "error") end
	local success, response = pcall(req, {
		Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100",
		Method = "GET",
	})
	if not success or not response or not response.Body then return notify("Hop failed", "error") end
	local decoded, data = pcall(function() return HS:JSONDecode(response.Body) end)
	if not decoded then return notify("Hop failed", "error") end
	local pick, best = nil, math.huge
	for _, server in ipairs(data.data or {}) do
		if server.id ~= game.JobId and server.playing < server.maxPlayers and server.playing < best then
			pick, best = server.id, server.playing
		end
	end
	if pick then
		ok(TP.TeleportToPlaceInstance, TP, game.PlaceId, pick, LP)
	else
		notify("No server found", "warning")
	end
end })

sSec:Button({ Title = "Copy Job ID", Callback = function()
	ok(function() setclipboard(game.JobId) end)
	notify("JobId copied")
end })

srv:Section({ Title = "Info", TextXAlignment = "Left", TextSize = 15 }):Paragraph({
	Title = "Server Stats",
	Desc = "Players: " .. #P:GetPlayers() .. " | JobId: " .. string.sub(game.JobId, 1, 8),
})

-- ─────────────────────────────────────────────── misc

local misc = Window:Tab({ Title = "Misc", Icon = "wrench" })
local xSec = misc:Section({ Title = "Client", TextXAlignment = "Left", TextSize = 15 })

xSec:Button({ Title = "FPS Boost", Desc = "Lowest quality, kill particles", Callback = function()
	ok(function()
		settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
		for _, d in ipairs(workspace:GetDescendants()) do
			if d:IsA("ParticleEmitter") then d.Enabled = false end
		end
	end)
	notify("Boost applied")
end })

xSec:Button({ Title = "Minimize", Desc = "Collapse to the open button", Callback = function()
	ok(function() Window:Close() end)
end })

xSec:Button({ Title = "Panic", Desc = "Turn everything off", Callback = function()
	for k in pairs(S) do
		if type(S[k]) == "boolean" then S[k] = false end
	end
	flyOff()
	for h in pairs(orig) do small(h) end
	notify("All features disabled", "warning")
end })

xSec:Button({ Title = "Unload", Desc = "Remove the hub completely", Callback = function()
	unloaded = true
	flyOff()
	for h in pairs(orig) do small(h) end
	for _, c in ipairs(conns) do ok(function() c:Disconnect() end) end
	if espGui then espGui:Destroy() end
	ok(function() Window:Destroy() end)
	for _, v in ipairs(PG:GetChildren()) do
		if v:IsA("ScreenGui") and (v.Name == "WindUI" or string.find(v.Name, "WindUI")) then
			ok(function() v:Destroy() end)
		end
	end
end)

-- ─────────────────────────────────────────────── loops

local map = {
	slap=slapT, kill=killT, click=clickT, reach=hitT, dodge=dodgeT,
	void=voidT, ragdoll=ragT, fling=flingT, knock=knockT,
	loot=lootT, acid=acidT, drop=dropT, noclip=noclipT,
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

-- ─────────────────────────────────────────────── boot

notify("link established :: keyless", "svclutcher")
print("[Svclutcher] ready — WindUI " .. THEME)
