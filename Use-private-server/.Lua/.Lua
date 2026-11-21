-- SENAR HUB | Steal Lucky Block  (WindUI, Theme Amber)
-- Menu: Auto Steal | Progres | Giftaway | Player | Setting | Alien Event | Star Light Event
--       Boss Starlight | Fun | Loader | Discord
--
-- CATATAN:
--  * Safe zone = posisi karakter saat script dijalankan (ubah lewat Setting -> Set Safe Zone).
--  * Nama prompt/remote/objek game tidak saya ketahui, jadi deteksi memakai KATA KUNCI di CFG.
--    Kalau ada fitur yang tidak jalan: Setting -> "Dump Prompt", lalu sesuaikan kata kunci di CFG.
--  * "Anti Kick" TIDAK disertakan (itu memblokir penegakan aturan dari game/Roblox).

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Senar Hub [Premium]",
    Icon = "Home",
    Author = "GGSIHLUH",
    Folder = "ProjectHubConfig",
    Size = UDim2.fromOffset(300, 400),
    Transparent = true,
    Theme = "Amber",
    Resizable = true,
    SideBarWidth = 170,
    User = {
        Enabled = true,
        Anonymous = false
    }
})

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__SenarLuckyCleanup then pcall(env.__SenarLuckyCleanup) end

local antiAfkConnection = nil
local function EnableAntiAFK()
    if antiAfkConnection then antiAfkConnection:Disconnect() end
    antiAfkConnection = LocalPlayer.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    end)
end
EnableAntiAFK()

if game:GetService("CoreGui"):FindFirstChild("WindUIToggleGui") then
    game:GetService("CoreGui").WindUIToggleGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
local ToggleBtn = Instance.new("ImageButton")
local UICorner = Instance.new("UICorner")
local UIStroke = Instance.new("UIStroke")

if syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
elseif protectgui then
    protectgui(ScreenGui)
end

ScreenGui.Name = "WindUIToggleGui"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

ToggleBtn.Name = "ToggleButton"
ToggleBtn.Parent = ScreenGui
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ToggleBtn.BackgroundTransparency = 0.5
ToggleBtn.Position = UDim2.new(0, 15, 0.4, 0)
ToggleBtn.Size = UDim2.new(0, 55, 0, 55)
ToggleBtn.Image = "rbxassetid://120264930670687"
ToggleBtn.ScaleType = Enum.ScaleType.Fit
ToggleBtn.Active = true
ToggleBtn.Draggable = true

UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = ToggleBtn

UIStroke.Color = Color3.fromRGB(255, 102, 153)
UIStroke.Thickness = 2.5
UIStroke.Parent = ToggleBtn

ToggleBtn.MouseButton1Click:Connect(function()
    if Window and Window.Toggle then
        Window:Toggle()
    end
end)

-- ================= CONFIG =================
local CFG = {
	SAFE_RADIUS = 60,
	WALK_TIMEOUT = 90,
	UP_HEIGHT = 70,

	STEAL_WORDS = { "steal", "curi", "grab", "take", "pick", "ambil", "collect" },
	CARRY_WORDS = { "lucky", "block" },
	MELEE_WORDS = { "bat", "sword", "pedang", "tongkat", "knife", "hammer", "palu" },
	OPEN_WORDS  = { "open", "buka" },
	REBIRTH     = { "rebirth" },
	UP_EXTRA    = { "upgrade", "buy", "purchase", "level", "up" },
	GIFT_WORDS  = { "gift", "give", "hadiah", "kirim", "trade" },
	ALIEN_WORDS = { "alien", "ufo", "aircraft", "pesawat", "saucer" },
	LIGHT_WORDS = { "light", "cahaya", "orb" },
	CATCH_WORDS = { "catch", "tangkap", "collect", "grab" },
	STAR_WORDS  = { "star", "bintang" },
	BOSS_WORDS  = { "boss", "bos", "starlight" },

	RARITIES = { "common", "uncommon", "rare", "epic", "legendary", "mythic", "secret", "celestial", "divine", "infinite" },

	DISCORD_CODE = "My9aazvDeM",
	DISCORD_LINK = "https://discord.gg/My9aazvDeM",
}

-- ================= STATE =================
local S = { alive = true, busy = false, noclip = false, floatOn = false }
local settings = {
	rarity = 0, method = 1, forcespeed = 150,
	autosteal = false, autoopen = false,
	rebirth = false, upspeed = false, upjump = false,
	walkspeed = 16, jumppower = 50, wsOn = false, jpOn = false,
	alien = false, alienTp = true, alienForce = false,
	autolight = false, autocatch = false, killstar = false,
	autoboss = false, autoattack = false,
}
local conns, floatPart = {}, nil
local SAFE = nil
do
	local c = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local h = c:WaitForChild("HumanoidRootPart", 10)
	SAFE = h and h.Position or Vector3.new(0, 10, 0)
end

-- ================= UTIL =================
local function any(s, words)
	for _, w in ipairs(words) do if s:find(w, 1, true) then return true end end
	return false
end
local function randName(n)
	local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	local t = table.create(n)
	for i = 1, n do local k = math.random(1, #chars) t[i] = chars:sub(k, k) end
	return table.concat(t)
end
local function hrp() local c = LocalPlayer.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c = LocalPlayer.Character return c and c:FindFirstChildOfClass("Humanoid") end
local function setPos(h, pos)
	if not h then return end
	h.CFrame = CFrame.new(pos) * (h.CFrame - h.CFrame.Position)
	h.AssemblyLinearVelocity = Vector3.zero
end
local function cleanTxt(s) return (tostring(s):gsub("<[^>]+>", "")) end
local function notify(title, content)
	pcall(function() WindUI:Notify({ Title = title, Content = content, Duration = 4 }) end)
end
local function guiParent()
	local ok, p = pcall(function() return (gethui and gethui()) or game:GetService("CoreGui") end)
	return ok and p or LocalPlayer:WaitForChild("PlayerGui")
end

table.insert(conns, RunService.Heartbeat:Connect(function()
	local h = hrp()
	if S.floatOn and h then
		if not floatPart or not floatPart.Parent then
			floatPart = Instance.new("Part")
			floatPart.Name = randName(8)
			floatPart.Size = Vector3.new(14, 1, 14)
			floatPart.Anchored = true
			floatPart.CanCollide = true
			floatPart.Transparency = 1
			floatPart.CanQuery = false
			floatPart.CanTouch = false
			floatPart.Parent = Workspace
		end
		floatPart.CFrame = CFrame.new(h.Position - Vector3.new(0, 3.5, 0))
	elseif floatPart then
		floatPart:Destroy()
		floatPart = nil
	end
end))
table.insert(conns, RunService.Stepped:Connect(function()
	if not S.noclip then return end
	local c = LocalPlayer.Character
	if not c then return end
	for _, p in ipairs(c:GetDescendants()) do
		if p:IsA("BasePart") then p.CanCollide = false end
	end
end))

-- ================= REGISTRY =================
local prompts, clickers = {}, {}
local function reg(d)
	if d:IsA("ProximityPrompt") then prompts[d] = true
	elseif d:IsA("ClickDetector") then clickers[d] = true end
end
table.insert(conns, Workspace.DescendantAdded:Connect(reg))
table.insert(conns, Workspace.DescendantRemoving:Connect(function(d) prompts[d] = nil clickers[d] = nil end))
task.spawn(function()
	local n = 0
	for _, d in ipairs(Workspace:GetDescendants()) do
		reg(d)
		n += 1
		if n % 3000 == 0 then task.wait() end
	end
end)

local function partPos(par)
	if not par then return nil end
	if par:IsA("BasePart") then return par.Position end
	if par:IsA("Attachment") then return par.WorldPosition end
	if par:IsA("Model") then return par:GetPivot().Position end
	return nil
end
local function promptPos(p) return partPos(p.Parent) end
local function ptext(p)
	local par = p.Parent
	return (p.ActionText .. " " .. p.ObjectText .. " " .. p.Name .. " " .. (par and par.Name or "")):lower()
end
local function fire(p)
	pcall(function()
		p.HoldDuration = 0
		p.RequiresLineOfSight = false
		if p.MaxActivationDistance < 40 then p.MaxActivationDistance = 40 end
	end)
	if fireproximityprompt then pcall(fireproximityprompt, p)
	else pcall(function() p:InputHoldBegin() p:InputHoldEnd() end) end
end

-- ================= GERAK =================
local function forceMove(target, stop, speed, cond)
	S.floatOn, S.noclip = true, true
	pcall(function() LocalPlayer:RequestStreamAroundAsync(target) end)
	local t0 = os.clock()
	local reached = false
	while cond() and os.clock() - t0 < CFG.WALK_TIMEOUT do
		local h = hrp()
		if not h then break end
		local d = target - h.Position
		local dist = d.Magnitude
		if dist <= stop then reached = true break end
		local dt = RunService.Heartbeat:Wait()
		h = hrp()
		if not h then break end
		h.CFrame = CFrame.new(h.Position + d.Unit * math.min(dist, speed * dt)) * (h.CFrame - h.CFrame.Position)
		h.AssemblyLinearVelocity = Vector3.zero
	end
	S.noclip = false
	return reached
end

-- eksklusif: hanya satu fitur gerak pada satu waktu
local function exclusive(fn)
	if S.busy then return false end
	S.busy = true
	local ok, err = pcall(fn)
	S.floatOn, S.noclip, S.busy = false, false, false
	if not ok then warn("[Senar Hub] " .. tostring(err)) end
	return true
end

-- ================= SENJATA / TAP =================
local function meleeTool()
	local function pick(root)
		if not root then return nil end
		local fb
		for _, t in ipairs(root:GetChildren()) do
			if t:IsA("Tool") then
				local n = t.Name:lower()
				if any(n, CFG.MELEE_WORDS) then return t end
				if not any(n, CFG.CARRY_WORDS) then fb = fb or t end
			end
		end
		return fb
	end
	return pick(LocalPlayer.Character) or pick(LocalPlayer:FindFirstChild("Backpack"))
end
local function tap()
	local t = meleeTool()
	local hm = hum()
	if t and hm and t.Parent ~= LocalPlayer.Character then
		pcall(function() hm:EquipTool(t) end)
	end
	if t then pcall(function() t:Activate() end) end
	pcall(function() VirtualUser:CaptureController() VirtualUser:ClickButton1(Vector2.new(0, 0)) end)
end

local function carryScore()
	local n = 0
	local c = LocalPlayer.Character
	if c then
		for _, d in ipairs(c:GetChildren()) do
			if d:IsA("Tool") and any(d.Name:lower(), CFG.CARRY_WORDS) then n += 1 end
		end
	end
	local bp = LocalPlayer:FindFirstChild("Backpack")
	if bp then
		for _, d in ipairs(bp:GetChildren()) do
			if d:IsA("Tool") and any(d.Name:lower(), CFG.CARRY_WORDS) then n += 1 end
		end
	end
	return n
end

-- ================= PRESS KEYWORDS (prompt / click / tombol GUI) =================
local function activateGui(b)
	pcall(function()
		if firesignal then
			firesignal(b.MouseButton1Click)
			firesignal(b.Activated)
		elseif getconnections then
			for _, c in ipairs(getconnections(b.MouseButton1Click)) do c:Fire() end
			for _, c in ipairs(getconnections(b.Activated)) do c:Fire() end
		end
	end)
end
local function pressKeywords(words, extra)
	local did = false
	for p in pairs(prompts) do
		if p.Parent and p.Enabled then
			local t = ptext(p)
			if any(t, words) and (not extra or any(t, extra)) then fire(p) did = true end
		end
	end
	for d in pairs(clickers) do
		if d.Parent and fireclickdetector then
			local t = (d.Name .. " " .. d.Parent.Name):lower()
			if any(t, words) and (not extra or any(t, extra)) then pcall(fireclickdetector, d) did = true end
		end
	end
	local pg = LocalPlayer:FindFirstChild("PlayerGui")
	if pg then
		for _, b in ipairs(pg:GetDescendants()) do
			if (b:IsA("TextButton") or b:IsA("ImageButton")) and b.Visible then
				local t = (b.Name .. " " .. (b:IsA("TextButton") and b.Text or "")):lower()
				if any(t, words) and (not extra or any(t, extra)) then activateGui(b) did = true end
			end
		end
	end
	return did
end
local function fireRemotes(words)
	for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
		if d:IsA("RemoteEvent") and any(d.Name:lower(), words) then pcall(function() d:FireServer() end) end
	end
end
local function loopFeature(flag, fn, delay)
	task.spawn(function()
		while S.alive do
			if settings[flag] then pcall(fn) end
			task.wait(delay)
		end
	end)
end

-- ================= AUTO STEAL LUCKY BLOCK =================
local function rarityOf(p)
	local model = p.Parent
	local node = p.Parent
	for _ = 1, 6 do
		if not node or node == Workspace then break end
		if node:IsA("Model") then model = node end
		node = node.Parent
	end
	local parts = { ptext(p), model and model.Name:lower() or "" }
	if model then
		local n = 0
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("TextLabel") and d.Text ~= "" then
				parts[#parts + 1] = cleanTxt(d.Text):lower()
				n += 1
				if n >= 25 then break end
			end
		end
		for _, v in pairs(model:GetAttributes()) do parts[#parts + 1] = tostring(v):lower() end
	end
	local str = table.concat(parts, " ")
	for i = #CFG.RARITIES, 1, -1 do
		if str:find(CFG.RARITIES[i], 1, true) then return i end
	end
	return 0
end

local function bestLucky()
	local h = hrp()
	if not h then return nil end
	local best, bpos, br, bd
	for p in pairs(prompts) do
		if p.Parent and p.Enabled and any(ptext(p), CFG.STEAL_WORDS) then
			local pos = promptPos(p)
			if pos and (pos - SAFE).Magnitude > CFG.SAFE_RADIUS then
				local r = rarityOf(p)
				if settings.rarity == 0 or r == settings.rarity then
					local d = (pos - h.Position).Magnitude
					if not best or r > br or (r == br and d < bd) then best, bpos, br, bd = p, pos, r, d end
				end
			end
		end
	end
	return best, bpos, br
end

local function stealOne(cond)
	local p, pos, r = bestLucky()
	if not p then return false end
	local h = hrp()
	local speed = settings.forcespeed
	local rname = r and r > 0 and CFG.RARITIES[r] or "?"
	if settings.method == 1 then
		-- naik ke atas -> melintas di atas -> turun ke lucky block
		local alt = math.max(h.Position.Y, pos.Y) + CFG.UP_HEIGHT
		forceMove(Vector3.new(h.Position.X, alt, h.Position.Z), 2, speed, cond)
		forceMove(Vector3.new(pos.X, alt, pos.Z), 2, speed, cond)
		forceMove(pos, 7, speed, cond)
	else
		forceMove(pos, 7, speed, cond)
	end
	if not cond() then return false end
	local before = carryScore()
	local got = false
	for _ = 1, 8 do
		if not (p.Parent and p.Enabled) or not cond() then break end
		fire(p)
		task.wait(0.06)
		if carryScore() > before then got = true break end
	end
	if not got then got = carryScore() > before or not (p.Parent and p.Enabled) end
	if got then
		setPos(hrp(), SAFE + Vector3.new(0, 3, 0)) -- TP ke safe zone
		task.wait(0.3)
		notify("Auto Steal", "Dapat lucky block (" .. rname .. ")")
	end
	return got
end

task.spawn(function()
	while S.alive do
		if settings.autosteal and hrp() then
			exclusive(function()
				stealOne(function() return S.alive and settings.autosteal end)
			end)
			task.wait(1)
		else
			task.wait(0.4)
		end
	end
end)

-- ================= PROGRES =================
loopFeature("rebirth", function()
	if not pressKeywords(CFG.REBIRTH) then fireRemotes(CFG.REBIRTH) end
end, 3)
loopFeature("upspeed", function()
	if not pressKeywords({ "speed" }, CFG.UP_EXTRA) then fireRemotes({ "upgradespeed", "speedupgrade", "upspeed" }) end
end, 2)
loopFeature("upjump", function()
	if not pressKeywords({ "jump" }, CFG.UP_EXTRA) then fireRemotes({ "upgradejump", "jumpupgrade", "upjump" }) end
end, 2)
loopFeature("autoopen", function()
	if not pressKeywords(CFG.OPEN_WORDS, CFG.CARRY_WORDS) then pressKeywords(CFG.OPEN_WORDS) end
end, 2)

-- ================= PLAYER =================
task.spawn(function()
	while S.alive do
		local hm = hum()
		if hm then
			if settings.wsOn then hm.WalkSpeed = settings.walkspeed end
			if settings.jpOn then
				hm.UseJumpPower = true
				hm.JumpPower = settings.jumppower
			end
		end
		task.wait(0.25)
	end
end)

local function fakeScreen(title, msg)
	local g = Instance.new("ScreenGui")
	g.Name = randName(10)
	g.DisplayOrder = 5000
	g.IgnoreGuiInset = true
	g.ResetOnSpawn = false
	g.Parent = guiParent()
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	bg.BackgroundTransparency = 0.35
	bg.BorderSizePixel = 0
	bg.Active = true
	bg.Parent = g
	local box = Instance.new("Frame")
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	box.Position = UDim2.fromScale(0.5, 0.5)
	box.Size = UDim2.fromOffset(340, 180)
	box.BackgroundColor3 = Color3.fromRGB(35, 37, 40)
	box.BorderSizePixel = 0
	box.Parent = bg
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 10)
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, 0, 0, 40)
	t.BackgroundTransparency = 1
	t.Text = title
	t.TextColor3 = Color3.new(1, 1, 1)
	t.Font = Enum.Font.GothamBold
	t.TextSize = 18
	t.Parent = box
	local m = Instance.new("TextLabel")
	m.Position = UDim2.fromOffset(16, 44)
	m.Size = UDim2.new(1, -32, 0, 70)
	m.BackgroundTransparency = 1
	m.Text = msg
	m.TextWrapped = true
	m.TextColor3 = Color3.fromRGB(210, 210, 215)
	m.Font = Enum.Font.Gotham
	m.TextSize = 14
	m.Parent = box
	local b = Instance.new("TextButton")
	b.AnchorPoint = Vector2.new(0.5, 1)
	b.Position = UDim2.new(0.5, 0, 1, -14)
	b.Size = UDim2.fromOffset(200, 34)
	b.BackgroundColor3 = Color3.fromRGB(235, 235, 240)
	b.Text = "Tutup (visual lokal)"
	b.TextColor3 = Color3.new(0, 0, 0)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 14
	b.Parent = box
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	b.Activated:Connect(function() g:Destroy() end)
end

-- ================= GIFT =================
local selPlayer, selItem
local function playerNames()
	local t = {}
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl ~= LocalPlayer then t[#t + 1] = pl.Name end
	end
	if #t == 0 then t[1] = "(tidak ada pemain)" end
	return t
end
local function itemNames()
	local t, seen = {}, {}
	local function scan(root)
		if not root then return end
		for _, d in ipairs(root:GetChildren()) do
			if d:IsA("Tool") and not seen[d.Name] then seen[d.Name] = true t[#t + 1] = d.Name end
		end
	end
	scan(LocalPlayer:FindFirstChild("Backpack"))
	scan(LocalPlayer.Character)
	if #t == 0 then t[1] = "(inventory kosong)" end
	return t
end

local function giftNow()
	local target = selPlayer and Players:FindFirstChild(selPlayer)
	if not target or not target.Character then notify("Gift", "Pilih player dulu") return end
	if not selItem then notify("Gift", "Pilih item dulu") return end
	local tool
	local bp = LocalPlayer:FindFirstChild("Backpack")
	for _, root in ipairs({ LocalPlayer.Character, bp }) do
		if root and not tool then
			for _, d in ipairs(root:GetChildren()) do
				if d:IsA("Tool") and d.Name == selItem then tool = d break end
			end
		end
	end
	if not tool then notify("Gift", "Item tidak ditemukan") return end
	exclusive(function()
		local hm, h = hum(), hrp()
		local origin = h and h.Position
		if hm and tool.Parent ~= LocalPlayer.Character then hm:EquipTool(tool) task.wait(0.2) end
		local th = target.Character:FindFirstChild("HumanoidRootPart")
		if h and th then
			setPos(h, (th.CFrame * CFrame.new(0, 0, 4)).Position)
			task.wait(0.3)
		end
		-- 1) prompt gift pada karakter target
		for _, d in ipairs(target.Character:GetDescendants()) do
			if d:IsA("ProximityPrompt") and any(ptext(d), CFG.GIFT_WORDS) then fire(d) end
		end
		-- 2) remote gift (argumen tebakan)
		for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
			if d:IsA("RemoteEvent") and any(d.Name:lower(), CFG.GIFT_WORDS) then
				pcall(function() d:FireServer(target) end)
				pcall(function() d:FireServer(target, tool) end)
				pcall(function() d:FireServer(target, tool.Name) end)
			end
		end
		task.wait(1)
		if h and origin then setPos(hrp(), origin) end
	end)
	notify("Gift", "Dicoba kirim " .. selItem .. " ke " .. selPlayer)
end

-- ================= ALIEN EVENT =================
local function nearestByName(words, requireHumanoid)
	local h = hrp()
	if not h then return nil, nil end
	local best, bpos, bd = nil, nil, math.huge
	for _, d in ipairs(Workspace:GetDescendants()) do
		if (d:IsA("Model") or d:IsA("BasePart")) and any(d.Name:lower(), words) then
			local ok = true
			if requireHumanoid then
				local hh = d:IsA("Model") and d:FindFirstChildOfClass("Humanoid")
				ok = hh ~= nil and hh ~= false and hh.Health > 0
			end
			if ok and not Players:GetPlayerFromCharacter(d) then
				local pos = partPos(d)
				if pos then
					local dist = (pos - h.Position).Magnitude
					if dist < bd then best, bpos, bd = d, pos, dist end
				end
			end
		end
	end
	return best, bpos
end

local function interactNear(obj, words)
	local h = hrp()
	if not h then return end
	for p in pairs(prompts) do
		if p.Parent and p.Enabled and (p:IsDescendantOf(obj) or (promptPos(p) and (promptPos(p) - h.Position).Magnitude < 20)) then
			if not words or any(ptext(p), words) then fire(p) end
		end
	end
	for d in pairs(clickers) do
		if d.Parent and fireclickdetector and d:IsDescendantOf(obj) then pcall(fireclickdetector, d) end
	end
end

local function approach(pos, cond, useTp)
	local h = hrp()
	if not h then return end
	if useTp then
		setPos(h, pos + Vector3.new(0, 4, 0))
		task.wait(0.1)
	else
		forceMove(pos + Vector3.new(0, 3, 0), 8, settings.forcespeed, cond)
	end
end

task.spawn(function()
	while S.alive do
		if settings.alien and hrp() then
			exclusive(function()
				local cond = function() return S.alive and settings.alien end
				local obj, pos = nearestByName(CFG.ALIEN_WORDS)
				if obj and pos then
					approach(pos, cond, settings.alienTp or not settings.alienForce)
					for _ = 1, 6 do
						if not cond() then break end
						tap()
						interactNear(obj)
						task.wait(0.08)
					end
				end
			end)
		end
		task.wait(0.3)
	end
end)

-- ================= STAR LIGHT EVENT =================
task.spawn(function()
	while S.alive do
		if (settings.autolight or settings.autocatch or settings.killstar) and hrp() then
			exclusive(function()
				local cond = function() return S.alive and (settings.autolight or settings.autocatch or settings.killstar) end
				if settings.autolight then
					local obj, pos = nearestByName(CFG.LIGHT_WORDS)
					if obj and pos then
						approach(pos, cond, true)
						interactNear(obj)
						local h = hrp()
						if h and obj:IsA("BasePart") and firetouchinterest then
							pcall(function() firetouchinterest(h, obj, 0) firetouchinterest(h, obj, 1) end)
						end
					end
				end
				if settings.autocatch then
					pressKeywords(CFG.CATCH_WORDS, CFG.LIGHT_WORDS)
					local obj = nearestByName(CFG.LIGHT_WORDS)
					if obj then interactNear(obj, CFG.CATCH_WORDS) end
				end
				if settings.killstar then
					local star, pos = nearestByName(CFG.STAR_WORDS, true)
					if star and pos then
						approach(pos, cond, true)
						for _ = 1, 8 do
							if not cond() then break end
							local hm = star:FindFirstChildOfClass("Humanoid")
							if not hm or hm.Health <= 0 then break end
							tap()
							task.wait(0.08)
						end
					end
				end
			end)
		end
		task.wait(0.3)
	end
end)

-- ================= BOSS STARLIGHT =================
local function findBoss()
	local best, bhp = nil, 0
	for _, d in ipairs(Workspace:GetDescendants()) do
		if d:IsA("Humanoid") and d.Health > 0 then
			local m = d.Parent
			if m and m:IsA("Model") and not Players:GetPlayerFromCharacter(m) then
				local score = d.MaxHealth + (any(m.Name:lower(), CFG.BOSS_WORDS) and 1e9 or 0)
				if score > bhp then best, bhp = m, score end
			end
		end
	end
	return best
end

task.spawn(function()
	while S.alive do
		if (settings.autoboss or settings.autoattack) and hrp() then
			local boss = findBoss()
			if boss then
				local br = boss:FindFirstChild("HumanoidRootPart") or boss.PrimaryPart
				local h = hrp()
				if br and h then
					if settings.autoboss then
						local pos = br.Position + br.CFrame.LookVector * 8
						h.CFrame = CFrame.lookAt(pos, Vector3.new(br.Position.X, pos.Y, br.Position.Z))
						h.AssemblyLinearVelocity = Vector3.zero
					end
					if settings.autoattack and (br.Position - h.Position).Magnitude < 45 then tap() end
				end
			end
			RunService.Heartbeat:Wait()
		else
			task.wait(0.4)
		end
	end
end)

-- ================= FUN: MINI GAME =================
local function makeGameWindow(title, w, h)
	local g = Instance.new("ScreenGui")
	g.Name = randName(10)
	g.DisplayOrder = 1500
	g.ResetOnSpawn = false
	g.Parent = guiParent()
	local f = Instance.new("Frame")
	f.Size = UDim2.fromOffset(w, h)
	f.Position = UDim2.new(0.5, -w / 2, 0.5, -h / 2)
	f.BackgroundColor3 = Color3.fromRGB(28, 22, 14)
	f.BorderSizePixel = 0
	f.Active = true
	f.Draggable = true
	f.Parent = g
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
	local st = Instance.new("UIStroke", f)
	st.Color = Color3.fromRGB(255, 176, 40)
	st.Thickness = 2
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, -40, 0, 30)
	t.Position = UDim2.fromOffset(10, 4)
	t.BackgroundTransparency = 1
	t.Text = title
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.TextColor3 = Color3.new(1, 1, 1)
	t.Font = Enum.Font.GothamBold
	t.TextSize = 15
	t.Parent = f
	local x = Instance.new("TextButton")
	x.Size = UDim2.fromOffset(26, 26)
	x.Position = UDim2.new(1, -32, 0, 4)
	x.BackgroundColor3 = Color3.fromRGB(180, 40, 50)
	x.Text = "X"
	x.TextColor3 = Color3.new(1, 1, 1)
	x.Font = Enum.Font.GothamBold
	x.TextSize = 14
	x.Parent = f
	Instance.new("UICorner", x).CornerRadius = UDim.new(0, 6)
	x.Activated:Connect(function() g:Destroy() end)
	return g, f
end

local function mkBtn(parent, text, pos, size, cb)
	local b = Instance.new("TextButton")
	b.Position = pos
	b.Size = size
	b.BackgroundColor3 = Color3.fromRGB(70, 52, 24)
	b.Text = text
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 14
	b.AutoButtonColor = true
	b.Parent = parent
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	if cb then b.Activated:Connect(cb) end
	return b
end

-- ---------- Apel Snake ----------
local function openSnake()
	local N, CELL = 15, 18
	local g, f = makeGameWindow("Apel Snake 🍎", 300, 420)
	local alive = true
	g.Destroying:Connect(function() alive = false end)
	local board = Instance.new("Frame")
	board.Position = UDim2.fromOffset(15, 40)
	board.Size = UDim2.fromOffset(N * CELL, N * CELL)
	board.BackgroundColor3 = Color3.fromRGB(15, 12, 8)
	board.BorderSizePixel = 0
	board.Parent = f
	local cells = {}
	for y = 0, N - 1 do
		for x = 0, N - 1 do
			local c = Instance.new("Frame")
			c.Position = UDim2.fromOffset(x * CELL, y * CELL)
			c.Size = UDim2.fromOffset(CELL - 1, CELL - 1)
			c.BackgroundColor3 = Color3.fromRGB(26, 22, 16)
			c.BorderSizePixel = 0
			c.Parent = board
			cells[y * N + x] = c
		end
	end
	local score = Instance.new("TextLabel")
	score.Position = UDim2.fromOffset(15, 314)
	score.Size = UDim2.fromOffset(270, 22)
	score.BackgroundTransparency = 1
	score.TextColor3 = Color3.fromRGB(255, 200, 90)
	score.Font = Enum.Font.GothamBold
	score.TextSize = 14
	score.Text = "Skor: 0"
	score.Parent = f

	local snake, dir, nextDir, apple, pts, over
	local function placeApple()
		repeat apple = { math.random(0, N - 1), math.random(0, N - 1) }
			local clash = false
			for _, s in ipairs(snake) do if s[1] == apple[1] and s[2] == apple[2] then clash = true end end
		until not clash
	end
	local function reset()
		snake = { { 7, 7 }, { 6, 7 }, { 5, 7 } }
		dir, nextDir, pts, over = { 1, 0 }, { 1, 0 }, 0, false
		placeApple()
	end
	local function draw()
		for _, c in pairs(cells) do c.BackgroundColor3 = Color3.fromRGB(26, 22, 16) end
		cells[apple[2] * N + apple[1]].BackgroundColor3 = Color3.fromRGB(230, 50, 50)
		for i, s in ipairs(snake) do
			cells[s[2] * N + s[1]].BackgroundColor3 = i == 1 and Color3.fromRGB(120, 255, 120) or Color3.fromRGB(60, 190, 80)
		end
		score.Text = over and ("Game Over! Skor: " .. pts) or ("Skor: " .. pts)
	end
	local function turn(dx, dy)
		if dir[1] ~= -dx or dir[2] ~= -dy then nextDir = { dx, dy } end
	end
	mkBtn(f, "▲", UDim2.fromOffset(115, 342), UDim2.fromOffset(70, 30), function() turn(0, -1) end)
	mkBtn(f, "◀", UDim2.fromOffset(40, 376), UDim2.fromOffset(70, 30), function() turn(-1, 0) end)
	mkBtn(f, "▼", UDim2.fromOffset(115, 376), UDim2.fromOffset(70, 30), function() turn(0, 1) end)
	mkBtn(f, "▶", UDim2.fromOffset(190, 376), UDim2.fromOffset(70, 30), function() turn(1, 0) end)
	mkBtn(f, "↻", UDim2.fromOffset(15, 342), UDim2.fromOffset(40, 30), function() reset() draw() end)
	reset()
	draw()
	task.spawn(function()
		while alive and S.alive do
			task.wait(0.16)
			if not over then
				dir = nextDir
				local hd = snake[1]
				local nx, ny = hd[1] + dir[1], hd[2] + dir[2]
				if nx < 0 or ny < 0 or nx >= N or ny >= N then
					over = true
				else
					for _, s in ipairs(snake) do if s[1] == nx and s[2] == ny then over = true end end
				end
				if not over then
					table.insert(snake, 1, { nx, ny })
					if nx == apple[1] and ny == apple[2] then
						pts += 1
						placeApple()
					else
						table.remove(snake)
					end
				end
				draw()
			end
		end
	end)
end

-- ---------- Block Blast ----------
local function openBlockBlast()
	local N, CELL = 8, 32
	local g, f = makeGameWindow("Block Blast 🧱", 290, 440)
	local SHAPES = {
		{ { 0, 0 } }, { { 0, 0 }, { 0, 1 } }, { { 0, 0 }, { 1, 0 } },
		{ { 0, 0 }, { 0, 1 }, { 0, 2 } }, { { 0, 0 }, { 1, 0 }, { 2, 0 } },
		{ { 0, 0 }, { 0, 1 }, { 1, 0 }, { 1, 1 } },
		{ { 0, 0 }, { 1, 0 }, { 1, 1 } }, { { 0, 0 }, { 0, 1 }, { 1, 0 } },
		{ { 0, 0 }, { 0, 1 }, { 0, 2 }, { 1, 0 }, { 1, 1 }, { 1, 2 }, { 2, 0 }, { 2, 1 }, { 2, 2 } },
		{ { 0, 0 }, { 0, 1 }, { 0, 2 }, { 0, 3 } },
	}
	local grid, cells = {}, {}
	for r = 0, N - 1 do grid[r] = {} for c = 0, N - 1 do grid[r][c] = false end end
	local pieces, selected, pts = {}, nil, 0

	local board = Instance.new("Frame")
	board.Position = UDim2.fromOffset(17, 40)
	board.Size = UDim2.fromOffset(N * CELL, N * CELL)
	board.BackgroundColor3 = Color3.fromRGB(15, 12, 8)
	board.BorderSizePixel = 0
	board.Parent = f
	local score = Instance.new("TextLabel")
	score.Position = UDim2.fromOffset(17, 300)
	score.Size = UDim2.fromOffset(256, 22)
	score.BackgroundTransparency = 1
	score.TextColor3 = Color3.fromRGB(255, 200, 90)
	score.Font = Enum.Font.GothamBold
	score.TextSize = 14
	score.Text = "Skor: 0"
	score.Parent = f

	local slots = {}
	local function fits(shape, r, c)
		for _, o in ipairs(shape) do
			local rr, cc = r + o[1], c + o[2]
			if rr < 0 or cc < 0 or rr >= N or cc >= N or grid[rr][cc] then return false end
		end
		return true
	end
	local function anyFit()
		for _, s in pairs(pieces) do
			for r = 0, N - 1 do for c = 0, N - 1 do if fits(s, r, c) then return true end end end
		end
		return false
	end
	local function drawGrid()
		for r = 0, N - 1 do for c = 0, N - 1 do
			cells[r * N + c].BackgroundColor3 = grid[r][c] and Color3.fromRGB(255, 170, 40) or Color3.fromRGB(34, 28, 20)
		end end
	end
	local function drawSlots()
		for k = 1, 3 do
			local slot = slots[k]
			for _, ch in ipairs(slot:GetChildren()) do
				if ch:IsA("Frame") then ch:Destroy() end
			end
			slot.BackgroundColor3 = (selected == k) and Color3.fromRGB(120, 86, 30) or Color3.fromRGB(50, 38, 20)
			local s = pieces[k]
			if s then
				for _, o in ipairs(s) do
					local m = Instance.new("Frame")
					m.Size = UDim2.fromOffset(10, 10)
					m.Position = UDim2.fromOffset(8 + o[2] * 11, 8 + o[1] * 11)
					m.BackgroundColor3 = Color3.fromRGB(255, 190, 70)
					m.BorderSizePixel = 0
					m.Parent = slot
				end
			end
		end
	end
	local function refill()
		for k = 1, 3 do pieces[k] = SHAPES[math.random(1, #SHAPES)] end
		selected = nil
	end
	local function clearLines()
		local rows, cols = {}, {}
		for r = 0, N - 1 do
			local full = true
			for c = 0, N - 1 do if not grid[r][c] then full = false end end
			if full then rows[#rows + 1] = r end
		end
		for c = 0, N - 1 do
			local full = true
			for r = 0, N - 1 do if not grid[r][c] then full = false end end
			if full then cols[#cols + 1] = c end
		end
		for _, r in ipairs(rows) do for c = 0, N - 1 do grid[r][c] = false end end
		for _, c in ipairs(cols) do for r = 0, N - 1 do grid[r][c] = false end end
		return #rows + #cols
	end
	local function place(r, c)
		local s = selected and pieces[selected]
		if not s or not fits(s, r, c) then return end
		for _, o in ipairs(s) do grid[r + o[1]][c + o[2]] = true end
		pts += #s
		local lines = clearLines()
		pts += lines * lines * 10
		pieces[selected] = nil
		selected = nil
		local left = false
		for k = 1, 3 do if pieces[k] then left = true end end
		if not left then refill() end
		score.Text = "Skor: " .. pts
		drawGrid()
		drawSlots()
		if not anyFit() then score.Text = "Game Over! Skor: " .. pts end
	end

	for r = 0, N - 1 do
		for c = 0, N - 1 do
			local b = Instance.new("TextButton")
			b.Position = UDim2.fromOffset(c * CELL, r * CELL)
			b.Size = UDim2.fromOffset(CELL - 2, CELL - 2)
			b.BackgroundColor3 = Color3.fromRGB(34, 28, 20)
			b.BorderSizePixel = 0
			b.Text = ""
			b.AutoButtonColor = false
			b.Parent = board
			cells[r * N + c] = b
			b.Activated:Connect(function() place(r, c) end)
		end
	end
	for k = 1, 3 do
		local slot = Instance.new("TextButton")
		slot.Position = UDim2.fromOffset(17 + (k - 1) * 88, 330)
		slot.Size = UDim2.fromOffset(80, 80)
		slot.BackgroundColor3 = Color3.fromRGB(50, 38, 20)
		slot.Text = ""
		slot.AutoButtonColor = false
		slot.Parent = f
		Instance.new("UICorner", slot).CornerRadius = UDim.new(0, 8)
		slots[k] = slot
		slot.Activated:Connect(function() if pieces[k] then selected = k drawSlots() end end)
	end
	mkBtn(f, "↻ Ulang", UDim2.new(1, -90, 0, 298), UDim2.fromOffset(75, 24), function()
		for r = 0, N - 1 do for c = 0, N - 1 do grid[r][c] = false end end
		pts = 0
		refill()
		score.Text = "Skor: 0"
		drawGrid()
		drawSlots()
	end)
	refill()
	drawGrid()
	drawSlots()
end

-- ================= DISCORD =================
local discord = { loaded = false, name = "Discord", members = 0, online = 0, iconFile = nil, bannerFile = nil }
local function httpGet(url)
	local ok, res = pcall(function() return game:HttpGet(url) end)
	if ok and res then return res end
	if request then
		local ok2, r = pcall(function() return request({ Url = url, Method = "GET" }) end)
		if ok2 and r then return r.Body end
	end
	return nil
end
local function saveImage(url, fname)
	if not (writefile and getcustomasset) then return nil end
	local body = httpGet(url)
	if not body then return nil end
	local ok, asset = pcall(function()
		writefile(fname, body)
		return getcustomasset(fname)
	end)
	return ok and asset or nil
end
local discordCard
local function loadDiscord()
	local body = httpGet("https://discord.com/api/v10/invites/" .. CFG.DISCORD_CODE .. "?with_counts=true&with_expiration=true")
	if not body then return false end
	local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
	if not ok or type(data) ~= "table" then return false end
	local gd = data.guild or {}
	discord.name = gd.name or "Discord"
	discord.members = data.approximate_member_count or 0
	discord.online = data.approximate_presence_count or 0
	if gd.id and gd.icon then
		discord.iconFile = saveImage("https://cdn.discordapp.com/icons/" .. gd.id .. "/" .. gd.icon .. ".png?size=256", "SenarDiscordIcon.png")
	end
	if gd.id and gd.banner then
		discord.bannerFile = saveImage("https://cdn.discordapp.com/banners/" .. gd.id .. "/" .. gd.banner .. ".png?size=600", "SenarDiscordBanner.png")
	elseif gd.id and gd.splash then
		discord.bannerFile = saveImage("https://cdn.discordapp.com/splashes/" .. gd.id .. "/" .. gd.splash .. ".png?size=600", "SenarDiscordBanner.png")
	end
	discord.loaded = true
	return true
end

local function showDiscordCard()
	if discordCard and discordCard.Parent then discordCard:Destroy() discordCard = nil return end
	local g = Instance.new("ScreenGui")
	g.Name = randName(10)
	g.DisplayOrder = 1200
	g.ResetOnSpawn = false
	g.Parent = guiParent()
	discordCard = g
	local f = Instance.new("Frame")
	f.Size = UDim2.fromOffset(300, 170)
	f.Position = UDim2.new(0.5, -150, 0.5, -85)
	f.BackgroundColor3 = Color3.fromRGB(32, 34, 48)
	f.BorderSizePixel = 0
	f.ClipsDescendants = true
	f.Active = true
	f.Draggable = true
	f.Parent = g
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 12)
	local st = Instance.new("UIStroke", f)
	st.Color = Color3.fromRGB(88, 101, 242)
	st.Thickness = 2
	if discord.bannerFile then
		local bg = Instance.new("ImageLabel")
		bg.Size = UDim2.fromScale(1, 1)
		bg.BackgroundTransparency = 1
		bg.Image = discord.bannerFile
		bg.ScaleType = Enum.ScaleType.Crop
		bg.ImageTransparency = 0.25
		bg.Parent = f
	end
	local dim = Instance.new("Frame")
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Color3.new(0, 0, 0)
	dim.BackgroundTransparency = 0.45
	dim.BorderSizePixel = 0
	dim.Parent = f
	local icon = Instance.new("ImageLabel")
	icon.Position = UDim2.fromOffset(14, 14)
	icon.Size = UDim2.fromOffset(64, 64)
	icon.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
	icon.Image = discord.iconFile or ""
	icon.Parent = f
	Instance.new("UICorner", icon).CornerRadius = UDim.new(1, 0)
	local function lbl(text, y, size, col)
		local l = Instance.new("TextLabel")
		l.Position = UDim2.fromOffset(90, y)
		l.Size = UDim2.new(1, -100, 0, 22)
		l.BackgroundTransparency = 1
		l.Text = text
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextColor3 = col or Color3.new(1, 1, 1)
		l.Font = Enum.Font.GothamBold
		l.TextSize = size
		l.TextStrokeTransparency = 0.5
		l.Parent = f
		return l
	end
	lbl(discord.name, 14, 17)
	lbl("🟢 Online: " .. tostring(discord.online), 40, 13, Color3.fromRGB(120, 255, 150))
	lbl("👥 Member: " .. tostring(discord.members), 60, 13, Color3.fromRGB(200, 210, 255))
	mkBtn(f, "Copy Link Discord", UDim2.fromOffset(14, 100), UDim2.new(1, -28, 0, 26), function()
		if setclipboard then pcall(setclipboard, CFG.DISCORD_LINK) end
		notify("Discord", "Link disalin: " .. CFG.DISCORD_LINK)
	end)
	mkBtn(f, "Tutup", UDim2.fromOffset(14, 132), UDim2.new(1, -28, 0, 26), function() g:Destroy() end)
end

-- ================= UI HELPERS =================
local function norm(v)
	if type(v) == "table" then return v.Title or v.Name or v[1] or tostring(v) end
	return v
end
local function add(tab, kind, props)
	if not tab then return nil end
	local ok, res = pcall(function() return tab[kind](tab, props) end)
	if not ok then warn("[Senar Hub] UI " .. kind .. ": " .. tostring(res)) end
	return ok and res or nil
end
local function newTab(title, icon)
	local ok, tab = pcall(function() return Window:Tab({ Title = title, Icon = icon }) end)
	if ok and tab then return tab end
	ok, tab = pcall(function() return Window:Tab({ Title = title, Icon = "folder" }) end)
	return ok and tab or nil
end
local function toggle(tab, title, desc, key, cb)
	return add(tab, "Toggle", {
		Title = title, Desc = desc, Value = settings[key], Default = settings[key],
		Callback = function(v)
			settings[key] = v and true or false
			if cb then cb(settings[key]) end
		end,
	})
end
local function slider(tab, title, desc, key, min, max, default, step)
	return add(tab, "Slider", {
		Title = title, Desc = desc, Step = step or 1,
		Value = { Min = min, Max = max, Default = default },
		Callback = function(v) settings[key] = tonumber(v) or default end,
	})
end

-- ---------- Menu: Auto Steal Lucky Block ----------
local tSteal = newTab("Auto Steal Lucky Block", "box")
local rarityValues = { "All" }
for _, r in ipairs(CFG.RARITIES) do rarityValues[#rarityValues + 1] = r end
add(tSteal, "Dropdown", {
	Title = "Rarity", Values = rarityValues, Value = "All",
	Callback = function(v)
		local name = tostring(norm(v)):lower()
		settings.rarity = 0
		for i, r in ipairs(CFG.RARITIES) do if r == name then settings.rarity = i end end
	end,
})
add(tSteal, "Dropdown", {
	Title = "Mentode", Values = { "Naik ke atas lalu turun", "Force (langsung)" }, Value = "Naik ke atas lalu turun",
	Callback = function(v) settings.method = (norm(v) == "Force (langsung)") and 2 or 1 end,
})
toggle(tSteal, "Auto Steal", "Menuju lucky block, ambil, lalu TP ke safe zone", "autosteal")

-- ---------- Menu: Progres ----------
local tProg = newTab("Progres", "trending-up")
toggle(tProg, "Auto Rebirth", nil, "rebirth")
toggle(tProg, "Auto Up Speed", nil, "upspeed")
toggle(tProg, "Auto Up Jumppower", nil, "upjump")

-- ---------- Menu: GIFTAWAY ----------
local tGift = newTab("GIFTAWAY", "gift")
local playerDrop = add(tGift, "Dropdown", {
	Title = "Select Player", Values = playerNames(), Value = playerNames()[1],
	Callback = function(v) selPlayer = norm(v) end,
})
local itemDrop = add(tGift, "Dropdown", {
	Title = "Select Item in Inventory", Values = itemNames(), Value = itemNames()[1],
	Callback = function(v) selItem = norm(v) end,
})
add(tGift, "Button", {
	Title = "Refresh Player & Item",
	Callback = function()
		if playerDrop and playerDrop.Refresh then pcall(function() playerDrop:Refresh(playerNames()) end) end
		if itemDrop and itemDrop.Refresh then pcall(function() itemDrop:Refresh(itemNames()) end) end
	end,
})
add(tGift, "Button", { Title = "Gift Player", Desc = "Kirim item terpilih ke player terpilih", Callback = function() task.spawn(giftNow) end })

-- ---------- Menu: Player ----------
local tPlayer = newTab("Player", "user")
toggle(tPlayer, "Walk Speed (aktif)", nil, "wsOn")
slider(tPlayer, "Walk Speed", nil, "walkspeed", 16, 300, 16)
toggle(tPlayer, "Jump Power (aktif)", nil, "jpOn")
slider(tPlayer, "Jump Power", nil, "jumppower", 50, 500, 50)
add(tPlayer, "Button", {
	Title = "Fake Banned", Desc = "Layar banned palsu (hanya tampil di layarmu)",
	Callback = function() fakeScreen("Banned", "You have been banned from this experience.\n(Error Code: 267)") end,
})
add(tPlayer, "Button", {
	Title = "Fake Kick", Desc = "Layar kick palsu (hanya tampil di layarmu)",
	Callback = function() fakeScreen("Disconnected", "You were kicked from the game.\n(Error Code: 267)") end,
})

-- ---------- Menu: Setting ----------
local tSet = newTab("Setting", "settings")
slider(tSet, "Speed Force", "Kecepatan gerak paksa (1-900)", "forcespeed", 1, 900, 150)
toggle(tSet, "Auto Open Lucky Block", nil, "autoopen")
add(tSet, "Button", {
	Title = "Set Safe Zone (posisiku)", Desc = "Simpan posisi sekarang sebagai safe zone",
	Callback = function()
		local h = hrp()
		if h then SAFE = h.Position notify("Safe Zone", "Disimpan") end
	end,
})
add(tSet, "Button", {
	Title = "Dump Prompt (debug)", Desc = "Salin daftar prompt ke clipboard",
	Callback = function()
		local h = hrp()
		local lines = {}
		for p in pairs(prompts) do
			if p.Parent and p.Enabled then
				local pos = promptPos(p)
				lines[#lines + 1] = string.format("%s | %d stud", ptext(p), (h and pos) and math.floor((pos - h.Position).Magnitude) or -1)
			end
			if #lines >= 60 then break end
		end
		local s = #lines > 0 and table.concat(lines, "\n") or "(tidak ada prompt)"
		if setclipboard then pcall(setclipboard, s) end
		print(s)
		notify("Dump", "Disalin ke clipboard")
	end,
})

-- ---------- Menu: Alien Event ----------
local tAlien = newTab("Alien Event", "rocket")
toggle(tAlien, "Farming Alien Aircraft", nil, "alien")
toggle(tAlien, "Farming Use Tp", "Pindah ke pesawat dengan TP", "alienTp")
toggle(tAlien, "Farming Use Force", "Pindah ke pesawat dengan gerak paksa", "alienForce")

-- ---------- Menu: Star Light Event ----------
local tStar = newTab("Star Light Event", "star")
toggle(tStar, "Auto Get Light", nil, "autolight")
toggle(tStar, "Auto Catch Light", nil, "autocatch")
toggle(tStar, "Kill Star", nil, "killstar")

-- ---------- Menu: Boss Starlight ----------
local tBoss = newTab("Boss Starlight", "skull")
toggle(tBoss, "Auto Boss", "Menempel di badan boss", "autoboss")
toggle(tBoss, "Auto attack", nil, "autoattack")

-- ---------- Menu: Fun ----------
local tFun = newTab("Fun", "gamepad-2")
add(tFun, "Button", { Title = "Block Blast", Desc = "Mini game puzzle blok", Callback = function() openBlockBlast() end })
add(tFun, "Button", { Title = "Apel Snake", Desc = "Mini game ular makan apel", Callback = function() openSnake() end })

-- ---------- Menu: Loader ----------
local tLoader = newTab("Loader", "download")
add(tLoader, "Paragraph", {
	Title = "Penjelasan",
	Desc = "Halo Selamat Datang di Loader, ini adalah Loader yg ada di script\nCopy: " .. CFG.DISCORD_LINK,
})
add(tLoader, "Button", {
	Title = "Copy Link", Desc = CFG.DISCORD_LINK,
	Callback = function()
		if setclipboard then pcall(setclipboard, CFG.DISCORD_LINK) end
		notify("Loader", "Link disalin")
	end,
})

-- ---------- Menu: Discord ----------
local tDisc = newTab("Discord", "message-circle")
local discPara = add(tDisc, "Paragraph", { Title = "Discord", Desc = "Memuat info server..." })
local function refreshDiscordUi()
	if discPara then
		pcall(function() discPara:SetTitle(discord.name) end)
		pcall(function()
			discPara:SetDesc(string.format("🟢 Online: %s\n👥 Member: %s\n%s", tostring(discord.online), tostring(discord.members), CFG.DISCORD_LINK))
		end)
	end
end
add(tDisc, "Button", {
	Title = "Tampilkan Kartu Discord", Desc = "Background, icon, member, dan online",
	Callback = function()
		task.spawn(function()
			if not discord.loaded then loadDiscord() refreshDiscordUi() end
			showDiscordCard()
		end)
	end,
})
add(tDisc, "Button", {
	Title = "Refresh Info", Callback = function()
		task.spawn(function() loadDiscord() refreshDiscordUi() end)
	end,
})
add(tDisc, "Button", {
	Title = "Copy Link Discord", Desc = CFG.DISCORD_LINK,
	Callback = function()
		if setclipboard then pcall(setclipboard, CFG.DISCORD_LINK) end
		notify("Discord", "Link disalin")
	end,
})
task.spawn(function() loadDiscord() refreshDiscordUi() end)

pcall(function() Window:SelectTab(1) end)

env.__SenarLuckyCleanup = function()
	S.alive = false
	if floatPart then pcall(function() floatPart:Destroy() end) end
	for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
	if antiAfkConnection then antiAfkConnection:Disconnect() end
	if discordCard then pcall(function() discordCard:Destroy() end) end
	pcall(function() ScreenGui:Destroy() end)
	pcall(function() Window:Destroy() end)
end
