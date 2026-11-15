--[[ Svclutcher Hub v3.8 | keyless | Delta Android | WindUI retro-hacker ]]

local P = game:GetService("Players")
while not P.LocalPlayer do task.wait(0.1) end
local LP = P.LocalPlayer
local VU = game:GetService("VirtualUser")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local TP = game:GetService("TeleportService")
local HS = game:GetService("HttpService")
local RUN = game:GetService("RunService")
local PG = LP:WaitForChild("PlayerGui")

local function log(...) print("[Svclutcher]", ...) end
local function ok(f, ...) local a, b = pcall(f, ...) return a and b end

-- ─────────────────────────────────────────────── WindUI loader (multi-source)

local SOURCES = {
	"https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua",
	"https://cdn.jsdelivr.net/gh/Footagesus/WindUI@main/dist/main.lua",
	"https://github.com/Footagesus/WindUI/releases/latest/download/main.lua",
}

local WindUI
for _, url in ipairs(SOURCES) do
	local success, result = pcall(function()
		local src = game:HttpGet(url)
		assert(type(src) == "string" and #src > 1000, "empty response")
		return loadstring(src)()
	end)
	if success and type(result) == "table" then
		WindUI = result
		log("WindUI loaded from " .. url)
		break
	end
	log("source failed: " .. url .. " -> " .. tostring(result))
end
if not WindUI then
	return warn("[Svclutcher] FATAL: could not load WindUI. Check your executor's HTTP access.")
end

-- ─────────────────────────────────────────────── theme (all keys)

local THEME = {
	Name = "RetroHacker",
	Accent = Color3.fromHex("#39FF6A"),
	Dialog = Color3.fromHex("#0A0F0B"),
	Outline = Color3.fromHex("#1C3621"),
	Text = Color3.fromHex("#B0FFC2"),
	Placeholder = Color3.fromHex("#4E7A58"),
	Background = Color3.fromHex("#060A07"),
	Button = Color3.fromHex("#123B1E"),
	Icon = Color3.fromHex("#39FF6A"),
	Toggle = Color3.fromHex("#39FF6A"),
	Slider = Color3.fromHex("#39FF6A"),
	SliderIcon = Color3.fromHex("#B0FFC2"),
	Checkbox = Color3.fromHex("#39FF6A"),
	Primary = Color3.fromHex("#39FF6A"),
	LabelBackground = Color3.fromHex("#0A0F0B"),
	ElementBackground = Color3.fromHex("#0A0F0B"),
	PanelBackground = Color3.fromHex("#040705"),
	PanelBackgroundTransparency = 0.1,
	LabelBackgroundTransparency = 0.35,
	ElementBackgroundTransparency = 0.35,
}

local themeName = "Dark"
if pcall(function() WindUI:AddTheme(THEME) end) then
	themeName = "RetroHacker"
else
	log("AddTheme failed, falling back to Dark")
end

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
				HRP.CFrame = d.CFrame + Vector3.new(0, s.y + 5, 0)
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

-- ─────────────────────────────────────────────── UI

local function main()
	local Window = WindUI:CreateWindow({
		Title = "svclutcher@delta",
		Icon = "terminal",
		Author = "v3.8 | keyless | windui",
		Folder = "SvclutcherHub",
		Size = UDim2.fromOffset(540, 420),
		Theme = themeName,
		Transparent = true,
		Resizable = true,
		SideBarWidth = 165,
		HideSearchBar = false,
		ScrollBarEnabled = true,
		ToggleKey = Enum.KeyCode.RightShift,
	})

	-- every element call is guarded so one failure can't kill the build
	local function el(parent, kind, opts)
		if not parent then return nil end
		local success, result = pcall(function() return parent[kind](parent, opts) end)
		if not success then log("element failed: " .. kind .. " :: " .. tostring(result)) end
		return result
	end

	local function section(tab, title)
		local success, sec = pcall(function()
			return tab:Section({ Title = title, TextXAlignment = "Left", TextSize = 15 })
		end)
		if success and sec then return sec end
		return tab
	end

	local function tab(title, icon)
		local success, t = pcall(function() return Window:Tab({ Title = title, Icon = icon }) end)
		if not success then log("tab failed: " .. title .. " :: " .. tostring(t)) end
		return t
	end

	local function Toggle(parent, title, desc, key, cb)
		return el(parent, "Toggle", {
			Title = title, Desc = desc, Value = S[key] or false,
			Callback = function(v) S[key] = v if cb then ok(cb, v) end end,
		})
	end

	local function Slider(parent, title, desc, key, min, max, step, default)
		return el(parent, "Slider", {
			Title = title, Desc = desc, Step = step,
			Value = { Min = min, Max = max, Default = default },
			Callback = function(v) S[key] = v end,
		})
	end

	local function Button(parent, title, desc, cb)
		return el(parent, "Button", { Title = title, Desc = desc, Callback = function() ok(cb) end })
	end

	-- ── combat
	local combat = tab("Combat", "swords")
	if combat then
		local a = section(combat, "Auras")
		Toggle(a, "Slap Aura", "Auto-activate + hitbox around you", "slap")
		Toggle(a, "Kill Aura", "Touch every player in hitbox range", "kill")
		Toggle(a, "Auto Clicker", "Virtual clicks at screen centre", "click")

		local b = section(combat, "Tuning")
		Slider(b, "Hitbox Size", "Glove hitbox scale", "size", 6, 40, 1, 16)
		Slider(b, "Click Delay", "Lower = faster", "cps", 0.03, 0.3, 0.01, 0.08)
		Toggle(b, "Hitbox Reach", "Keep hitbox big while holding a glove", "reach", function(v)
			if not v and not S.slap then
				for h in pairs(orig) do small(h) end
			end
		end)

		Button(combat, "Activate Tool", "Fire the equipped glove once", function()
			local g = glove()
			if g then g:Activate() end
		end)
		Button(combat, "TP to Nearest", "Jump to closest player", function()
			local t = nearest(500)
			if t and HRP then HRP.CFrame = t.CFrame * CFrame.new(0, 0, 3) end
		end)
	end

	-- ── movement
	local move = tab("Movement", "move")
	if move then
		local a = section(move, "Flight")
		Toggle(a, "Fly", "Joystick / WASD flight", "fly", function(v)
			if v then flyOn() else flyOff() end
		end)
		Slider(a, "Fly Speed", nil, "speed", 20, 200, 1, 55)
		Slider(a, "Fly Lift", "Upward drift", "lift", -40, 100, 1, 0)

		local b = section(move, "Ground")
		Slider(b, "Walk Speed", nil, "ws", 16, 200, 1, 20)
		Slider(b, "Jump Power", nil, "jp", 50, 300, 1, 50)
		Toggle(b, "Infinite Jump", nil, "ijump")
		Toggle(b, "Noclip", "Survives respawn", "noclip", function(v)
			if not v and Ch then
				for _, d in ipairs(Ch:GetDescendants()) do
					if d:IsA("BasePart") and ncStore[d] ~= nil then
						d.CanCollide = ncStore[d]
						ncStore[d] = nil
					end
				end
			end
		end)

		local c = section(move, "Position")
		Button(c, "Save Position", nil, function()
			if HRP then
				savedPos = HRP.CFrame
				notify("Position saved")
			end
		end)
		Button(c, "Load Position", nil, function()
			if savedPos and HRP then
				HRP.CFrame = savedPos
				notify("Position loaded")
			end
		end)
		Button(c, "TP Safe Ground", nil, function()
			if not HRP then return end
			local g = ground(HRP.Position)
			HRP.CFrame = g and CFrame.new(g) or spawnCF()
		end)
	end

	-- ── defence
	local defend = tab("Defence", "shield")
	if defend then
		local a = section(defend, "Protection")
		Toggle(a, "Anti Void", nil, "void")
		Toggle(a, "Anti Ragdoll", nil, "ragdoll")
		Toggle(a, "Anti Fling", nil, "fling")
		Toggle(a, "Anti Knockback", nil, "knock")
		Toggle(a, "Auto Dodge", nil, "dodge")
		Toggle(a, "Anti AFK", nil, "afk")
	end

	-- ── visuals
	local vis = tab("Visuals", "eye")
	if vis then
		local a = section(vis, "ESP")
		Toggle(a, "Player ESP", "Name + distance", "esp")
		Toggle(a, "Box ESP", nil, "box")
		Toggle(a, "Tracers", nil, "tracer")
		Toggle(a, "Glove ESP", "Show equipped tool name", "gloveesp")
		Slider(a, "Max Distance", nil, "dist", 100, 2000, 50, 600)
	end

	-- ── royale
	local roy = tab("Royale", "gem")
	if roy then
		local a = section(roy, "Automation")
		Toggle(a, "Auto Loot", nil, "loot")
		Toggle(a, "Anti Acid", nil, "acid")
		Toggle(a, "Auto Drop", "Land on ground below", "drop")
		Button(roy, "TP to Nearest Loot", nil, function()
			if not HRP then return end
			local best, bd
			for _, d in ipairs(workspace:GetDescendants()) do
				if d:IsA("BasePart") and string.find(string.lower(d.Name), "pickup") then
					local dist = (d.Position - HRP.Position).Magnitude
					if not bd or dist < bd then best, bd = d, dist end
				end
			end
			if best then HRP.CFrame = CFrame.new(best.Position + Vector3.new(0, 4, 0)) end
		end)
	end

	-- ── server
	local srv = tab("Server", "globe")
	if srv then
		local a = section(srv, "Session")
		Button(a, "Rejoin", nil, function()
			notify("Rejoining...")
			task.wait(0.3)
			ok(TP.Teleport, TP, game.PlaceId, LP)
		end)
		Button(a, "Server Hop", "Lowest populated server", function()
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
		end)
		Button(a, "Copy Job ID", nil, function()
			ok(function() setclipboard(game.JobId) end)
			notify("JobId copied")
		end)
		Button(srv, "Player Count", nil, function()
			notify(#P:GetPlayers() .. " players in server")
		end)
	end

	-- ── misc
	local misc = tab("Misc", "wrench")
	if misc then
		local a = section(misc, "Client")
		Button(a, "FPS Boost", "Lowest quality, kill particles", function()
			settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
			for _, d in ipairs(workspace:GetDescendants()) do
				if d:IsA("ParticleEmitter") then d.Enabled = false end
			end
			notify("Boost applied")
		end)
		Button(a, "Minimize", "Collapse to the open button", function()
			Window:Close()
		end)
		Button(a, "Panic", "Turn everything off", function()
			for k in pairs(S) do
				if type(S[k]) == "boolean" then S[k] = false end
			end
			flyOff()
			for h in pairs(orig) do small(h) end
			notify("All features disabled", "warning")
		end)
		Button(a, "Unload", "Remove the hub completely", function()
			unloaded = true
			flyOff()
			for h in pairs(orig) do small(h) end
			for _, c in ipairs(conns) do ok(function() c:Disconnect() end) end
			if espGui then espGui:Destroy() end
			ok(function() Window:Destroy() end)
			for _, v in ipairs(PG:GetChildren()) do
				if v:IsA("ScreenGui") and string.find(v.Name, "WindUI") then
					ok(function() v:Destroy() end)
				end
			end
		end)
	end
end

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

local built, err = xpcall(main, function(e)
	return tostring(e) .. "\n" .. (debug and debug.traceback() or "")
end)

if built then
	notify("link established :: keyless", "svclutcher")
	log("ready")
else
	warn("[Svclutcher] BUILD ERROR:\n" .. tostring(err))
	notify("Build error, check console", "error")
end
