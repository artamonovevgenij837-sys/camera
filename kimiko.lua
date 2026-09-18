ds.Transparency = 0.5; ds.Parent = dot
	addConnection(c.MouseEnter:Connect(function()
		TweenService:Create(c, TweenInfo.new(0.2), {BackgroundTransparency = 0.3}):Play()
		TweenService:Create(st, TweenInfo.new(0.2), {Transparency = 0.3}):Play()
	end))
	addConnection(c.MouseLeave:Connect(function()
		TweenService:Create(c, TweenInfo.new(0.2), {BackgroundTransparency = 0.4}):Play()
		TweenService:Create(st, TweenInfo.new(0.2), {Transparency = 0.6}):Play()
	end))
	addConnection(c.MouseButton1Click:Connect(function()
		if ScriptUnloaded then return end
		local is = c:GetAttribute("Active") == true
		local ns = not is
		c:SetAttribute("Active", ns)
		if ns then
			TweenService:Create(dot, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundColor3 = Themes[State.CurrentTheme].Accent}):Play()
			playSound(SFX.On)
		else
			TweenService:Create(dot, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(100,100,100)}):Play()
			playSound(SFX.Off)
		end
		if lmb then lmb(ns) end
	end))
	addConnection(c.MouseButton2Click:Connect(function()
		if ScriptUnloaded then return end
		if rmb then rmb() end
	end))
	return c, dot
end

local function syncVisualCards()
	for k, d in pairs(visualCardRegistry) do
		local a = State[k] == true
		local col = a and Themes[State.CurrentTheme].Accent or Color3.fromRGB(100,100,100)
		if d.dot and d.dot.Parent then d.dot.BackgroundColor3 = col end
		if d.card and d.card.Parent then d.card:SetAttribute("Active", a) end
	end
end

-- [FIX 2/3] Forward declarations теперь через переменные
local openSettings
local refreshExplorer
local applyTheme
local applyThemeToUI
local CFG = {}   -- [FIX 2] CFG объявлена заранее

local function createVisualCard(title, desc, key, onToggle, rmb)
	local c, d = createCard(title, desc, UI.visuals, function(active)
		State[key] = active
		if onToggle then onToggle(active) end
	end, rmb)
	visualCardRegistry[key] = {card = c, dot = d}
	return c
end

-- ================= SETTINGS WINDOWS =================
local WINS = {}
local function hideMain() UI.main.Visible = false end
local function showMain() UI.main.Visible = true end

local function setOverlay(active)
	if active then
		dimOverlay.Visible = true
		dimOverlay.BackgroundTransparency = 1
		TweenService:Create(dimOverlay, TweenInfo.new(0.3), {BackgroundTransparency = 0.6}):Play()
	else
		TweenService:Create(dimOverlay, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
		task.delay(0.35, function()
			if not State.OpenSettings and not State.MenuOpen then dimOverlay.Visible = false end
		end)
	end
end

local function closeAllSettings()
	for _, w in pairs(WINS) do if w.frame then w.frame.Visible = false end end
	State.OpenSettings = nil
	showMain()
end

local function createSettingsWindow(name, title, size)
	local W = {}
	W.frame = Instance.new("Frame")
	W.frame.Name = name.."Settings"
	W.frame.Size = UDim2.new(0, size.X, 0, size.Y)
	W.frame.Position = UDim2.new(0.5, -size.X/2, 0.5, -size.Y/2)
	W.frame.BackgroundColor3 = Themes[State.CurrentTheme].Bg
	W.frame.BackgroundTransparency = 0.35
	W.frame.BorderSizePixel = 0
	W.frame.Visible = false
	W.frame.ZIndex = 600
	W.frame.Parent = screenGui
	W.corner = Instance.new("UICorner"); W.corner.CornerRadius = UDim.new(0,10); W.corner.Parent = W.frame
	W.stroke = Instance.new("UIStroke")
	W.stroke.Color = Themes[State.CurrentTheme].Stroke
	W.stroke.Transparency = 0.4; W.stroke.Parent = W.frame
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1,0,0,45)
	header.BackgroundTransparency = 1
	header.ZIndex = 601; header.Parent = W.frame
	local tl = Instance.new("TextLabel")
	tl.Text = title; tl.Font = FONT_MAIN; tl.TextSize = 16
	tl.TextColor3 = Themes[State.CurrentTheme].Text
	tl.Size = UDim2.new(1,-60,1,0); tl.Position = UDim2.new(0,22,0,0)
	tl.TextXAlignment = Enum.TextXAlignment.Left
	tl.BackgroundTransparency = 1; tl.ZIndex = 602; tl.Parent = header
	local cb = Instance.new("TextButton")
	cb.Text = "X"; cb.Font = FONT_MAIN; cb.TextSize = 22
	cb.TextColor3 = Themes[State.CurrentTheme].Text
	cb.Size = UDim2.new(0,32,0,32); cb.Position = UDim2.new(1,-42,0.5,-16)
	cb.BackgroundTransparency = 1; cb.ZIndex = 602; cb.Parent = header
	addConnection(cb.MouseEnter:Connect(function()
		TweenService:Create(cb, TweenInfo.new(0.2), {TextColor3 = STYLE.Red}):Play()
	end))
	addConnection(cb.MouseLeave:Connect(function()
		TweenService:Create(cb, TweenInfo.new(0.2), {TextColor3 = Themes[State.CurrentTheme].Text}):Play()
	end))
	addConnection(cb.MouseButton1Click:Connect(function() closeAllSettings() end))
	makeDraggable(W.frame, header)
	WINS[name] = W
	return W
end

local function isPointIn(frame, x, y)
	if not frame or not frame.Visible then return false end
	local p, s = frame.AbsolutePosition, frame.AbsoluteSize
	return x >= p.X and x <= p.X + s.X and y >= p.Y and y <= p.Y + s.Y
end

addConnection(UserInputService.InputBegan:Connect(function(input, gp)
	if ScriptUnloaded or gp then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 and State.OpenSettings then
		local mp = UserInputService:GetMouseLocation()
		local w = WINS[State.OpenSettings]
		if w and w.frame and w.frame.Visible then
			if not isPointIn(w.frame, mp.X, mp.Y) then closeAllSettings() end
		end
	end
	if input.KeyCode == Enum.KeyCode.Escape and State.OpenSettings then closeAllSettings() end
end))

-- Slider
local function makeSlider(parent, label, minV, maxV, initV, yPos, cb)
	local lbl = Instance.new("TextLabel")
	lbl.Text = label; lbl.Font = FONT_TEXT; lbl.TextSize = 14
	lbl.TextColor3 = Themes[State.CurrentTheme].Text
	lbl.Size = UDim2.new(1,-40,0,22); lbl.Position = UDim2.new(0,22,0,yPos)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.BackgroundTransparency = 1; lbl.ZIndex = 602; lbl.Parent = parent
	local valLbl = Instance.new("TextLabel")
	valLbl.Text = string.format("%.2f", initV)
	valLbl.Font = FONT_TEXT; valLbl.TextSize = 14
	valLbl.TextColor3 = Themes[State.CurrentTheme].Text
	valLbl.TextTransparency = 0.3
	valLbl.Size = UDim2.new(0,60,0,22); valLbl.Position = UDim2.new(1,-85,0,yPos)
	valLbl.TextXAlignment = Enum.TextXAlignment.Right
	valLbl.BackgroundTransparency = 1; valLbl.ZIndex = 602; valLbl.Parent = parent
	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(0.9,0,0,8); bg.Position = UDim2.new(0.05,0,0,yPos+28)
	bg.BackgroundColor3 = Color3.fromRGB(100,100,100)
	bg.BackgroundTransparency = 0.5
	bg.BorderSizePixel = 0; bg.ZIndex = 602; bg.Parent = parent
	local bgc = Instance.new("UICorner"); bgc.CornerRadius = UDim.new(1,0); bgc.Parent = bg
	local fill = Instance.new("Frame")
	local ratio = (initV - minV)/(maxV - minV)
	fill.Size = UDim2.new(ratio,0,1,0)
	fill.BackgroundColor3 = Themes[State.CurrentTheme].Accent
	fill.BorderSizePixel = 0; fill.ZIndex = 603; fill.Parent = bg
	local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(1,0); fc.Parent = fill
	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0,18,0,18)
	knob.Position = UDim2.new(ratio,-9,0.5,-9)
	knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
	knob.BorderSizePixel = 0; knob.ZIndex = 604; knob.Parent = bg
	local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(1,0); kc.Parent = knob
	local ks = Instance.new("UIStroke"); ks.Color = Color3.fromRGB(0,0,0); ks.Transparency = 0.5; ks.Parent = knob
	local dragging = false
	local function update()
		if ScriptUnloaded then return end
		local mx = UserInputService:GetMouseLocation().X
		local ax = bg.AbsolutePosition.X
		local w = bg.AbsoluteSize.X
		local r = math.clamp((mx - ax)/w, 0, 1)
		fill.Size = UDim2.new(r,0,1,0)
		knob.Position = UDim2.new(r,-9,0.5,-9)
		local v = minV + (maxV - minV)*r
		valLbl.Text = string.format("%.2f", v)
		cb(v)
	end
	addConnection(bg.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; update() end
	end))
	addConnection(UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then update() end
	end))
	addConnection(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end))
end

-- Toggle
local function makeToggle(parent, label, initState, yPos, cb)
	local lbl = Instance.new("TextLabel")
	lbl.Text = label; lbl.Font = FONT_TEXT; lbl.TextSize = 14
	lbl.TextColor3 = Themes[State.CurrentTheme].Text
	lbl.Size = UDim2.new(1,-40,0,22); lbl.Position = UDim2.new(0,22,0,yPos)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.BackgroundTransparency = 1; lbl.ZIndex = 602; lbl.Parent = parent
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0,50,0,26); btn.Position = UDim2.new(1,-75,0,yPos)
	btn.BackgroundColor3 = initState and Themes[State.CurrentTheme].Accent or Color3.fromRGB(100,100,100)
	btn.BackgroundTransparency = 0.3; btn.Text = ""; btn.ZIndex = 602; btn.Parent = parent
	local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(1,0); bc.Parent = btn
	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0,20,0,20)
	knob.Position = initState and UDim2.new(1,-22,0.5,-10) or UDim2.new(0,2,0.5,-10)
	knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
	knob.BorderSizePixel = 0; knob.ZIndex = 603; knob.Parent = btn
	local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(1,0); kc.Parent = knob
	local st = initState
	addConnection(btn.MouseButton1Click:Connect(function()
		if ScriptUnloaded then return end
		st = not st
		if st then
			TweenService:Create(btn, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundColor3 = Themes[State.CurrentTheme].Accent}):Play()
			TweenService:Create(knob, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(1,-22,0.5,-10)}):Play()
			playSound(SFX.On)
		else
			TweenService:Create(btn, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(100,100,100)}):Play()
			TweenService:Create(knob, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0,2,0.5,-10)}):Play()
			playSound(SFX.Off)
		end
		cb(st)
	end))
end

-- Color picker
local function makeColorPicker(parent, label, initColor, yPos, cb)
	local lbl = Instance.new("TextLabel")
	lbl.Text = label; lbl.Font = FONT_TEXT; lbl.TextSize = 14
	lbl.TextColor3 = Themes[State.CurrentTheme].Text
	lbl.Size = UDim2.new(1,-40,0,22); lbl.Position = UDim2.new(0,22,0,yPos)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.BackgroundTransparency = 1; lbl.ZIndex = 602; lbl.Parent = parent
	local prev = Instance.new("TextButton")
	prev.Size = UDim2.new(0,65,0,28); prev.Position = UDim2.new(1,-85,0,yPos)
	prev.BackgroundColor3 = initColor; prev.Text = ""; prev.ZIndex = 602; prev.Parent = parent
	local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0,5); pc.Parent = prev
	local ps = Instance.new("UIStroke"); ps.Color = Themes[State.CurrentTheme].Stroke; ps.Transparency = 0.5; ps.Parent = prev
	local palette = Instance.new("Frame")
	palette.Size = UDim2.new(0,200,0,30); palette.Position = UDim2.new(0,22,0,yPos+32)
	palette.BackgroundTransparency = 1; palette.ZIndex = 602; palette.Parent = parent
	local cols = {Color3.fromRGB(255,255,255), Color3.fromRGB(255,0,0), Color3.fromRGB(0,255,0), Color3.fromRGB(0,0,255), Color3.fromRGB(255,255,0), Color3.fromRGB(0,0,0)}
	for i, c in ipairs(cols) do
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0,28,0,28); b.Position = UDim2.new(0,(i-1)*33,0,0)
		b.BackgroundColor3 = c; b.Text = ""; b.ZIndex = 603; b.Parent = palette
		local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,4); bc.Parent = b
		addConnection(b.MouseButton1Click:Connect(function()
			if ScriptUnloaded then return end
			prev.BackgroundColor3 = c; cb(c); playSound(SFX.On)
		end))
	end
end

-- ================= SETTINGS WINDOWS CREATION =================
local fogW = createSettingsWindow("Fog", "Настройки тумана", Vector2.new(380,400))
makeSlider(fogW.frame, "Плотность", 0,1, State.FogSettings.Density, 55, function(v) State.FogSettings.Density = v; applyFog() end)
makeSlider(fogW.frame, "Смещение", -1,1, State.FogSettings.Offset, 120, function(v) State.FogSettings.Offset = v; applyFog() end)
makeColorPicker(fogW.frame, "Цвет тумана", State.FogSettings.Color, 185, function(c) State.FogSettings.Color = c; applyFog() end)
makeColorPicker(fogW.frame, "Цвет затухания", State.FogSettings.Decay, 260, function(c) State.FogSettings.Decay = c; applyFog() end)

local aspectW = createSettingsWindow("Aspect", "Настройки растяжения", Vector2.new(380,170))
makeSlider(aspectW.frame, "Сила (0.5-1.5)", 0.5,1.5, State.AspectValue, 55, function(v) State.AspectValue = v end)

local fbW = createSettingsWindow("Fullbright", "Fullbright", Vector2.new(380,170))
makeSlider(fbW.frame, "Яркость (1-10)", 1,10, State.FullbrightBrightness, 55, function(v) State.FullbrightBrightness = v; if State.FullbrightEnabled then applyFullbright() end end)

local mbW = createSettingsWindow("MotionBlur", "Motion Blur", Vector2.new(380,170))
makeSlider(mbW.frame, "Сила", 0,56, State.MotionBlurStrength, 55, function(v) State.MotionBlurStrength = v end)

local worldW = createSettingsWindow("World", "Visuals", Vector2.new(380,340))
makeSlider(worldW.frame, "Насыщенность", -1,1, State.WorldSettings.Saturation, 55, function(v) State.WorldSettings.Saturation = v; applyWorld() end)
makeSlider(worldW.frame, "Контраст", -1,1, State.WorldSettings.Contrast, 120, function(v) State.WorldSettings.Contrast = v; applyWorld() end)
makeSlider(worldW.frame, "Яркость", -0.5,0.5, State.WorldSettings.Brightness, 185, function(v) State.WorldSettings.Brightness = v; applyWorld() end)
makeColorPicker(worldW.frame, "Цвет мира", State.WorldSettings.TintColor, 250, function(c) State.WorldSettings.TintColor = c; applyWorld() end)

local jumpW = createSettingsWindow("JumpCircle", "Jump Circle", Vector2.new(380,440))
local jumpLbl = Instance.new("TextLabel")
jumpLbl.Text = "Стиль:"; jumpLbl.Font = FONT_TEXT; jumpLbl.TextSize = 14
jumpLbl.TextColor3 = Themes[State.CurrentTheme].Text
jumpLbl.Size = UDim2.new(1,-40,0,22); jumpLbl.Position = UDim2.new(0,22,0,50)
jumpLbl.TextXAlignment = Enum.TextXAlignment.Left
jumpLbl.BackgroundTransparency = 1; jumpLbl.ZIndex = 602; jumpLbl.Parent = jumpW.frame
local styleButtons = {}
local function makeStyleBtn(label, styleName, yPos)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0.9,0,0,30); b.Position = UDim2.new(0.05,0,0,yPos)
	b.BackgroundColor3 = (State.JumpCircleStyle == styleName) and Themes[State.CurrentTheme].Accent or Themes[State.CurrentTheme].Card
	b.BackgroundTransparency = 0.3; b.Text = label; b.Font = FONT_TEXT; b.TextSize = 14
	b.TextColor3 = Themes[State.CurrentTheme].Text
	b.AutoButtonColor = false; b.ZIndex = 602; b.Parent = jumpW.frame
	local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,6); bc.Parent = b
	local bs = Instance.new("UIStroke"); bs.Color = Themes[State.CurrentTheme].Stroke; bs.Transparency = 0.5; bs.Parent = b
	addConnection(b.MouseButton1Click:Connect(function()
		if ScriptUnloaded then return end
		State.JumpCircleStyle = styleName
		for _, x in ipairs(styleButtons) do
			TweenService:Create(x, TweenInfo.new(0.25), {BackgroundColor3 = Themes[State.CurrentTheme].Card}):Play()
		end
		TweenService:Create(b, TweenInfo.new(0.25), {BackgroundColor3 = Themes[State.CurrentTheme].Accent}):Play()
		playSound(SFX.On)
	end))
	table.insert(styleButtons, b)
end
makeStyleBtn("Палочки", "segments", 80)
makeStyleBtn("Круг", "circle", 115)
makeStyleBtn("Квадрат", "square", 150)
makeToggle(jumpW.frame, "Свечение", State.JumpCircleGlow, 200, function(s) State.JumpCircleGlow = s end)
makeToggle(jumpW.frame, "Использовать цвет темы", State.JumpCircleUseTheme, 250, function(s)
	State.JumpCircleUseTheme = s
	if s then updateJumpCircleColor(getVisualColor(true, nil)) else updateJumpCircleColor(State.JumpCircleCustomColor) end
end)
makeColorPicker(jumpW.frame, "Свой цвет", State.JumpCircleCustomColor, 320, function(c)
	State.JumpCircleCustomColor = c
	if not State.JumpCircleUseTheme then updateJumpCircleColor(c) end
end)

local partW = createSettingsWindow("Particles", "Particles", Vector2.new(380,250))
makeToggle(partW.frame, "Использовать цвет темы", State.ParticlesUseTheme, 55, function(s)
	State.ParticlesUseTheme = s
	if s then updateParticlesColor(getVisualColor(true, nil)) else updateParticlesColor(State.ParticlesCustomColor) end
end)
makeColorPicker(partW.frame, "Свой цвет", State.ParticlesCustomColor, 120, function(c)
	State.ParticlesCustomColor = c
	if not State.ParticlesUseTheme then updateParticlesColor(c) end
end)

local trailW = createSettingsWindow("Trails", "Trails", Vector2.new(380,250))
makeToggle(trailW.frame, "Использовать цвет темы", State.TrailsUseTheme, 55, function(s)
	State.TrailsUseTheme = s
	if s then updateTrailsColor(getVisualColor(true, nil)) else updateTrailsColor(State.TrailsCustomColor) end
end)
makeColorPicker(trailW.frame, "Свой цвет", State.TrailsCustomColor, 120, function(c)
	State.TrailsCustomColor = c
	if not State.TrailsUseTheme then updateTrailsColor(c) end
end)

local hatW = createSettingsWindow("ChinaHat", "China Hat", Vector2.new(380,300))
makeToggle(hatW.frame, "Свечение", State.ChinaHatGlow, 55, function(s)
	State.ChinaHatGlow = s
	if State.ChinaHatEnabled then applyChinaHat() end
end)
makeToggle(hatW.frame, "Использовать цвет темы", State.ChinaHatUseTheme, 105, function(s)
	State.ChinaHatUseTheme = s
	if s then updateChinaHatColor(getVisualColor(true, nil)) else updateChinaHatColor(State.ChinaHatCustomColor) end
end)
makeColorPicker(hatW.frame, "Свой цвет", State.ChinaHatCustomColor, 170, function(c)
	State.ChinaHatCustomColor = c
	if not State.ChinaHatUseTheme then updateChinaHatColor(c) end
end)

local wingsW = createSettingsWindow("Wings", "Wings", Vector2.new(380,300))
makeToggle(wingsW.frame, "Свечение", State.WingsGlow, 55, function(s)
	State.WingsGlow = s
	if State.WingsEnabled then applyWings() end
end)
makeToggle(wingsW.frame, "Использовать цвет темы", State.WingsUseTheme, 105, function(s)
	State.WingsUseTheme = s
	if s then updateWingsColor(getVisualColor(true, nil)) else updateWingsColor(State.WingsCustomColor) end
end)
makeColorPicker(wingsW.frame, "Свой цвет", State.WingsCustomColor, 170, function(c)
	State.WingsCustomColor = c
	if not State.WingsUseTheme then updateWingsColor(c) end
end)

local kaguneW = createSettingsWindow("Kagune", "Kagune", Vector2.new(380,300))
makeToggle(kaguneW.frame, "Свечение", State.KaguneGlow, 55, function(s)
	State.KaguneGlow = s
	if State.KaguneEnabled then applyKagune() end
end)
makeToggle(kaguneW.frame, "Использовать цвет темы", State.KaguneUseTheme, 105, function(s)
	State.KaguneUseTheme = s
	if s then updateKaguneColor(getVisualColor(true, nil)) else updateKaguneColor(State.KaguneCustomColor) end
end)
makeColorPicker(kaguneW.frame, "Свой цвет", State.KaguneCustomColor, 170, function(c)
	State.KaguneCustomColor = c
	if not State.KaguneUseTheme then updateKaguneColor(c) end
end)

local skyW = createSettingsWindow("Sky", "Custom Sky", Vector2.new(380,220))
local skyLbl = Instance.new("TextLabel")
skyLbl.Text = "Выбор скайбокса:"; skyLbl.Font = FONT_TEXT; skyLbl.TextSize = 14
skyLbl.TextColor3 = Themes[State.CurrentTheme].Text
skyLbl.Size = UDim2.new(1,-40,0,22); skyLbl.Position = UDim2.new(0,22,0,50)
skyLbl.TextXAlignment = Enum.TextXAlignment.Left
skyLbl.BackgroundTransparency = 1; skyLbl.ZIndex = 602; skyLbl.Parent = skyW.frame
local skyButtons = {}
for i, d in ipairs(SKIES) do
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0.9,0,0,30)
	b.Position = UDim2.new(0.05,0,0,80 + (i-1)*35)
	b.BackgroundColor3 = (State.SkyIndex == i) and Themes[State.CurrentTheme].Accent or Themes[State.CurrentTheme].Card
	b.BackgroundTransparency = 0.3; b.Text = d.name
	b.Font = FONT_TEXT; b.TextSize = 14
	b.TextColor3 = Themes[State.CurrentTheme].Text
	b.AutoButtonColor = false; b.ZIndex = 602; b.Parent = skyW.frame
	local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,6); bc.Parent = b
	local bs = Instance.new("UIStroke"); bs.Color = Themes[State.CurrentTheme].Stroke; bs.Transparency = 0.5; bs.Parent = b
	addConnection(b.MouseButton1Click:Connect(function()
		if ScriptUnloaded then return end
		State.SkyIndex = i; applySky()
		for _, x in ipairs(skyButtons) do
			TweenService:Create(x, TweenInfo.new(0.25), {BackgroundColor3 = Themes[State.CurrentTheme].Card}):Play()
		end
		TweenService:Create(b, TweenInfo.new(0.25), {BackgroundColor3 = Themes[State.CurrentTheme].Accent}):Play()
		playSound(SFX.On)
	end))
	table.insert(skyButtons, b)
end

-- ================= OPEN SETTINGS (impl) =================
-- [FIX 4] Присваиваем в forward-declared local, а не создаём глобальную
openSettings = function(name)
	for _, w in pairs(WINS) do if w.frame then w.frame.Visible = false end end
	if WINS[name] then
		hideMain()
		WINS[name].frame.Visible = true
		local sizes = {
			Fog = Vector2.new(380,400), Aspect = Vector2.new(380,170),
			Fullbright = Vector2.new(380,170), MotionBlur = Vector2.new(380,170),
			World = Vector2.new(380,340), JumpCircle = Vector2.new(380,440),
			Particles = Vector2.new(380,250), Trails = Vector2.new(380,250),
			ChinaHat = Vector2.new(380,300), Wings = Vector2.new(380,300),
			Kagune = Vector2.new(380,300), Sky = Vector2.new(380,220)
		}
		local ts = sizes[name] or Vector2.new(380,170)
		WINS[name].frame.Size = UDim2.new(0,0,0,0)
		WINS[name].frame.Position = UDim2.new(0.5,0,0.5,0)
		TweenService:Create(WINS[name].frame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0,ts.X,0,ts.Y), Position = UDim2.new(0.5,-ts.X/2,0.5,-ts.Y/2)
		}):Play()
		State.OpenSettings = name
		setOverlay(true)
	end
end

-- ================= VISUAL CARDS CREATION =================
createVisualCard("Fog Blur", "Туман в мире. ПКМ - настройки.", "FogEnabled", function() applyFog() end, function() openSettings("Fog") end)
createVisualCard("Custom Sky", "Смена неба. ПКМ - выбор.", "SkyEnabled", function() applySky() end, function() openSettings("Sky") end)
createVisualCard("Aspect Ratio", "Растяг экрана. ПКМ - настройки.", "AspectEnabled", nil, function() openSettings("Aspect") end)
createVisualCard("Fullbright", "Полное освещение. ПКМ - настройки.", "FullbrightEnabled", function() applyFullbright() end, function() openSettings("Fullbright") end)
createVisualCard("Motion Blur", "Размытие при движении. ПКМ - настройки.", "MotionBlurEnabled", nil, function() openSettings("MotionBlur") end)
createVisualCard("Visuals", "Настройка цвета мира. ПКМ - настройки.", "WorldEnabled", function() applyWorld() end, function() openSettings("World") end)
createVisualCard("HUD", "Dynamic Island с FPS и PING.", "HudEnabled", function(s)
	HUD.frame.Visible = s
	if s then
		HUD.frame.Size = UDim2.new(0,0,0,38)
		HUD.frame.Position = UDim2.new(0.5,0,0,15)
		TweenService:Create(HUD.frame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0,280,0,38), Position = UDim2.new(0.5,-140,0,15)
		}):Play()
	end
end, nil)
createVisualCard("Jump Circle", "Круг при прыжке. ПКМ - цвет и стиль.", "JumpCircleEnabled", function(s) if s then setupJumpCircle() end end, function() openSettings("JumpCircle") end)
createVisualCard("Particles", "Светящиеся снежинки. ПКМ - цвет.", "ParticlesEnabled", function() applyParticles() end, function() openSettings("Particles") end)
createVisualCard("Trails", "След за спиной. ПКМ - цвет.", "TrailsEnabled", function() applyTrails() end, function() openSettings("Trails") end)
createVisualCard("China Hat", "Шляпа над головой. ПКМ - цвет.", "ChinaHatEnabled", function() applyChinaHat() end, function() openSettings("ChinaHat") end)
createVisualCard("Wings", "Крылья. ПКМ - цвет.", "WingsEnabled", function() applyWings() end, function() openSettings("Wings") end)
createVisualCard("Kagune", "Щупальца. ПКМ - цвет.", "KaguneEnabled", function() applyKagune() end, function() openSettings("Kagune") end)
createVisualCard("Optimization", "Разблокирует FPS выше лимита.", "OptimizationEnabled", nil, nil)

-- ================= THEME CARDS =================
local themeCards = {}
for _, themeName in ipairs(ThemeOrder) do
	local th = Themes[themeName]
	local c = Instance.new("TextButton")
	c.Name = "Theme_"..themeName
	c.Size = UDim2.new(0.23,0,0,110)
	c.BackgroundColor3 = th.Card
	c.BackgroundTransparency = 0.3
	c.BorderSizePixel = 0; c.Text = ""; c.AutoButtonColor = false
	c.ZIndex = 12; c.Parent = UI.themes
	local co = Instance.new("UICorner"); co.CornerRadius = UDim.new(0,10); co.Parent = c
	local st = Instance.new("UIStroke")
	st.Color = th.Stroke; st.Transparency = 0.5; st.Thickness = 2; st.Parent = c
	local cd = Instance.new("Frame")
	cd.Size = UDim2.new(0,40,0,40); cd.Position = UDim2.new(0.5,-20,0,15)
	cd.BackgroundColor3 = th.Accent; cd.BorderSizePixel = 0; cd.ZIndex = 13; cd.Parent = c
	local cdc = Instance.new("UICorner"); cdc.CornerRadius = UDim.new(1,0); cdc.Parent = cd
	local cds = Instance.new("UIStroke"); cds.Color = Color3.fromRGB(255,255,255); cds.Transparency = 0.4; cds.Thickness = 2; cds.Parent = cd
	local nl = Instance.new("TextLabel")
	nl.Text = themeName; nl.Font = FONT_MAIN; nl.TextSize = 14
	nl.TextColor3 = th.Text
	nl.Size = UDim2.new(1,0,0,25); nl.Position = UDim2.new(0,0,1,-35)
	nl.BackgroundTransparency = 1; nl.ZIndex = 13; nl.Parent = c
	if themeName == State.CurrentTheme then st.Transparency = 0; st.Thickness = 3 end
	themeCards[themeName] = {card = c, stroke = st, dot = cd}
	addConnection(c.MouseEnter:Connect(function()
		TweenService:Create(c, TweenInfo.new(0.2), {BackgroundTransparency = 0.1}):Play()
	end))
	addConnection(c.MouseLeave:Connect(function()
		TweenService:Create(c, TweenInfo.new(0.2), {BackgroundTransparency = 0.3}):Play()
	end))
	addConnection(c.MouseButton1Click:Connect(function()
		if ScriptUnloaded then return end
		applyTheme(themeName)
		playSound(SFX.On)
	end))
end

-- ================= APPLY THEME =================
-- [FIX 3] Через присваивание в forward-declared local
applyThemeToUI = function(themeName)
	local th = Themes[themeName]; if not th then return end
	local ti = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

	TweenService:Create(UI.main, ti, {BackgroundColor3 = th.Bg}):Play()
	TweenService:Create(UI.mainStroke, ti, {Color = th.Stroke}):Play()
	TweenService:Create(UI.sidebar, ti, {BackgroundColor3 = th.Bg}):Play()
	TweenService:Create(UI.sideStroke, ti, {Color = th.Stroke}):Play()
	TweenService:Create(UI.title, ti, {TextColor3 = th.Text}):Play()
	TweenService:Create(UI.separator, ti, {BackgroundColor3 = th.Stroke}):Play()
	TweenService:Create(UI.visuals, ti, {ScrollBarImageColor3 = th.Accent}):Play()
	TweenService:Create(UI.themes, ti, {ScrollBarImageColor3 = th.Accent}):Play()
	TweenService:Create(UI.indVisuals, ti, {BackgroundColor3 = th.Accent}):Play()
	TweenService:Create(UI.indThemes, ti, {BackgroundColor3 = th.Accent}):Play()
	TweenService:Create(UI.indConfigs, ti, {BackgroundColor3 = th.Accent}):Play()
	TweenService:Create(HUD.frame, ti, {BackgroundColor3 = th.Bg}):Play()
	TweenService:Create(HUD.stroke, ti, {Color = th.Stroke}):Play()
	TweenService:Create(HUD.label, ti, {TextColor3 = th.Text}):Play()

	if CFG and CFG.title then
		TweenService:Create(CFG.title, ti, {TextColor3 = th.Text}):Play()
		TweenService:Create(CFG.save, ti, {BackgroundColor3 = th.Card, TextColor3 = th.Text}):Play()
		TweenService:Create(CFG.refresh, ti, {BackgroundColor3 = th.Card, TextColor3 = th.Text}):Play()
		TweenService:Create(CFG.importBtn, ti, {BackgroundColor3 = th.Card, TextColor3 = th.Text}):Play()
		TweenService:Create(CFG.explorer, ti, {BackgroundColor3 = th.Card}):Play()
		TweenService:Create(CFG.explorerStroke, ti, {Color = th.Stroke}):Play()
		TweenService:Create(CFG.explorerScroll, ti, {ScrollBarImageColor3 = th.Accent}):Play()
		TweenService:Create(CFG.load, ti, {BackgroundColor3 = th.Card, TextColor3 = th.Text}):Play()
		TweenService:Create(CFG.delete, ti, {BackgroundColor3 = th.Card, TextColor3 = th.Text}):Play()
		TweenService:Create(CFG.path, ti, {TextColor3 = th.Text}):Play()
	end

	for _, child in ipairs(UI.visuals:GetChildren()) do
		if child:IsA("TextButton") then
			TweenService:Create(child, ti, {BackgroundColor3 = th.Card}):Play()
			local s = child:FindFirstChildOfClass("UIStroke")
			if s then TweenService:Create(s, ti, {Color = th.Stroke}):Play() end
			for _, sub in ipairs(child:GetChildren()) do
				if sub:IsA("TextLabel") then TweenService:Create(sub, ti, {TextColor3 = th.Text}):Play() end
			end
		end
	end
	for _, d in pairs(themeCards) do
		if d.stroke then TweenService:Create(d.stroke, ti, {Color = th.Stroke}):Play() end
	end
	for _, w in pairs(WINS) do
		if w.frame then
			TweenService:Create(w.frame, ti, {BackgroundColor3 = th.Bg}):Play()
			if w.stroke then TweenService:Create(w.stroke, ti, {Color = th.Stroke}):Play() end
			for _, sub in ipairs(w.frame:GetDescendants()) do
				if sub:IsA("TextLabel") then TweenService:Create(sub, ti, {TextColor3 = th.Text}):Play()
				elseif sub:IsA("UIStroke") then TweenService:Create(sub, ti, {Color = th.Stroke}):Play() end
			end
		end
	end
	syncVisualCards()
end

applyTheme = function(themeName)
	if ScriptUnloaded then return end
	State.CurrentTheme = themeName
	applyThemeToUI(themeName)
	for name, d in pairs(themeCards) do
		local t = (name == themeName)
		TweenService:Create(d.stroke, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Transparency = t and 0 or 0.5, Thickness = t and 3 or 2
		}):Play()
	end
end

-- ================= CONFIG UI =================
-- CFG уже объявлена выше (forward declaration)

CFG.title = Instance.new("TextLabel")
CFG.title.Text = "Проводник конфигов"
CFG.title.Font = FONT_MAIN; CFG.title.TextSize = 20
CFG.title.TextColor3 = Themes[State.CurrentTheme].Text
CFG.title.Size = UDim2.new(1,-40,0,30); CFG.title.Position = UDim2.new(0,20,0,10)
CFG.title.TextXAlignment = Enum.TextXAlignment.Left
CFG.title.BackgroundTransparency = 1; CFG.title.ZIndex = 12; CFG.title.Parent = UI.configs

-- Button row with UIListLayout for alignment
local btnRow = Instance.new("Frame")
btnRow.Name = "ConfigButtonsRow"
btnRow.Size = UDim2.new(1, -40, 0, 40)
btnRow.Position = UDim2.new(0, 20, 0, 45)
btnRow.BackgroundTransparency = 1
btnRow.ZIndex = 12
btnRow.Parent = UI.configs

local btnLayout = Instance.new("UIListLayout")
btnLayout.FillDirection = Enum.FillDirection.Horizontal
btnLayout.SortOrder = Enum.SortOrder.LayoutOrder
btnLayout.Padding = UDim.new(0, 10)
btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
btnLayout.Parent = btnRow

CFG.save = Instance.new("TextButton")
CFG.save.Name = "SaveBtn"
CFG.save.Size = UDim2.new(0, 0, 0, 36)
CFG.save.BackgroundColor3 = Themes[State.CurrentTheme].Card
CFG.save.BackgroundTransparency = 0.3
CFG.save.Text = "Сохранить конфиг"
CFG.save.Font = FONT_MAIN; CFG.save.TextSize = 14
CFG.save.TextColor3 = Themes[State.CurrentTheme].Text
CFG.save.AutoButtonColor = false
CFG.save.LayoutOrder = 1
CFG.save.ZIndex = 12
CFG.save.Parent = btnRow
local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(0,8); sc.Parent = CFG.save
local st1 = Instance.new("UIStroke"); st1.Color = Themes[State.CurrentTheme].Stroke; st1.Transparency = 0.5; st1.Parent = CFG.save

CFG.refresh = Instance.new("TextButton")
CFG.refresh.Name = "RefreshBtn"
CFG.refresh.Size = UDim2.new(0, 0, 0, 36)
CFG.refresh.BackgroundColor3 = Themes[State.CurrentTheme].Card
CFG.refresh.BackgroundTransparency = 0.3
CFG.refresh.Text = "Обновить список"
CFG.refresh.Font = FONT_MAIN; CFG.refresh.TextSize = 14
CFG.refresh.TextColor3 = Themes[State.CurrentTheme].Text
CFG.refresh.AutoButtonColor = false
CFG.refresh.LayoutOrder = 2
CFG.refresh.ZIndex = 12
CFG.refresh.Parent = btnRow
local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0,8); rc.Parent = CFG.refresh
local st2 = Instance.new("UIStroke"); st2.Color = Themes[State.CurrentTheme].Stroke; st2.Transparency = 0.5; st2.Parent = CFG.refresh

CFG.importBtn = Instance.new("TextButton")
CFG.importBtn.Name = "ImportBtn"
CFG.importBtn.Size = UDim2.new(0, 0, 0, 36)
CFG.importBtn.BackgroundColor3 = Themes[State.CurrentTheme].Card
CFG.importBtn.BackgroundTransparency = 0.3
CFG.importBtn.Text = "Скопировать путь"
CFG.importBtn.Font = FONT_MAIN; CFG.importBtn.TextSize = 14
CFG.importBtn.TextColor3 = Themes[State.CurrentTheme].Text
CFG.importBtn.AutoButtonColor = false
CFG.importBtn.LayoutOrder = 3
CFG.importBtn.ZIndex = 12
CFG.importBtn.Parent = btnRow
local ic = Instance.new("UICorner"); ic.CornerRadius = UDim.new(0,8); ic.Parent = CFG.importBtn
local st3 = Instance.new("UIStroke"); st3.Color = Themes[State.CurrentTheme].Stroke; st3.Transparency = 0.5; st3.Parent = CFG.importBtn

-- Auto-size buttons to fit content
local function updateButtonWidths()
	local rowWidth = btnRow.AbsoluteSize.X
	if rowWidth <= 0 then return end
	local padding = 20
	local gap = 10
	local btnW = (rowWidth - padding - gap*2) / 3
	CFG.save.Size = UDim2.new(0, btnW, 0, 36)
	CFG.refresh.Size = UDim2.new(0, btnW, 0, 36)
	CFG.importBtn.Size = UDim2.new(0, btnW, 0, 36)
end
btnRow:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateButtonWidths)
task.spawn(function()
	task.wait(0.1)
	updateButtonWidths()
end)

CFG.explorer = Instance.new("Frame")
CFG.explorer.Size = UDim2.new(1,-40,0,320); CFG.explorer.Position = UDim2.new(0,20,0,95)
CFG.explorer.BackgroundColor3 = Themes[State.CurrentTheme].Card
CFG.explorer.BackgroundTransparency = 0.4
CFG.explorer.BorderSizePixel = 0; CFG.explorer.ZIndex = 12; CFG.explorer.Parent = UI.configs
local ec = Instance.new("UICorner"); ec.CornerRadius = UDim.new(0,10); ec.Parent = CFG.explorer
CFG.explorerStroke = Instance.new("UIStroke")
CFG.explorerStroke.Color = Themes[State.CurrentTheme].Stroke
CFG.explorerStroke.Transparency = 0.5; CFG.explorerStroke.Parent = CFG.explorer

CFG.explorerScroll = Instance.new("ScrollingFrame")
CFG.explorerScroll.Size = UDim2.new(1,-16,1,-16); CFG.explorerScroll.Position = UDim2.new(0,8,0,8)
CFG.explorerScroll.BackgroundTransparency = 1; CFG.explorerScroll.BorderSizePixel = 0
CFG.explorerScroll.ScrollBarThickness = 5
CFG.explorerScroll.ScrollBarImageColor3 = Themes[State.CurrentTheme].Accent
CFG.explorerScroll.CanvasSize = UDim2.new(0,0,0,0)
CFG.explorerScroll.ZIndex = 13; CFG.explorerScroll.Parent = CFG.explorer
CFG.explorerList = Instance.new("UIListLayout")
CFG.explorerList.Padding = UDim.new(0,6)
CFG.explorerList.SortOrder = Enum.SortOrder.LayoutOrder
CFG.explorerList.Parent = CFG.explorerScroll
addConnection(CFG.explorerList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	CFG.explorerScroll.CanvasSize = UDim2.new(0,0,0, CFG.explorerList.AbsoluteContentSize.Y + 10)
end))

CFG.load = Instance.new("TextButton")
CFG.load.Size = UDim2.new(0.48,0,0,40); CFG.load.Position = UDim2.new(0,20,0,425)
CFG.load.BackgroundColor3 = Themes[State.CurrentTheme].Card
CFG.load.BackgroundTransparency = 0.3
CFG.load.Text = "Загрузить выбранный"; CFG.load.Font = FONT_MAIN; CFG.load.TextSize = 15
CFG.load.TextColor3 = Themes[State.CurrentTheme].Text
CFG.load.AutoButtonColor = false; CFG.load.ZIndex = 12; CFG.load.Parent = UI.configs
local lc = Instance.new("UICorner"); lc.CornerRadius = UDim.new(0,8); lc.Parent = CFG.load

CFG.delete = Instance.new("TextButton")
CFG.delete.Size = UDim2.new(0.48,0,0,40); CFG.delete.Position = UDim2.new(0.52,0,0,425)
CFG.delete.BackgroundColor3 = Themes[State.CurrentTheme].Card
CFG.delete.BackgroundTransparency = 0.3
CFG.delete.Text = "Удалить выбранный"; CFG.delete.Font = FONT_MAIN; CFG.delete.TextSize = 15
CFG.delete.TextColor3 = Themes[State.CurrentTheme].Text
CFG.delete.AutoButtonColor = false; CFG.delete.ZIndex = 12; CFG.delete.Parent = UI.configs
local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(0,8); dc.Parent = CFG.delete

CFG.path = Instance.new("TextLabel")
CFG.path.Text = "Путь: " .. getAbsoluteConfigPath()
CFG.path.Font = FONT_TEXT; CFG.path.TextSize = 12
CFG.path.TextColor3 = Themes[State.CurrentTheme].Text
CFG.path.TextTransparency = 0.3
CFG.path.Size = UDim2.new(1,-40,0,20); CFG.path.Position = UDim2.new(0,20,0,472)
CFG.path.TextXAlignment = Enum.TextXAlignment.Left
CFG.path.BackgroundTransparency = 1; CFG.path.ZIndex = 12; CFG.path.Parent = UI.configs

CFG.status = Instance.new("TextLabel")
CFG.status.Text = ""; CFG.status.Font = FONT_TEXT; CFG.status.TextSize = 13
CFG.status.TextColor3 = Themes[State.CurrentTheme].Accent
CFG.status.Size = UDim2.new(1,-40,0,20); CFG.status.Position = UDim2.new(0,20,0,495)
CFG.status.TextXAlignment = Enum.TextXAlignment.Left
CFG.status.BackgroundTransparency = 1; CFG.status.ZIndex = 12; CFG.status.Parent = UI.configs

local function showStatus(msg, isError)
	CFG.status.Text = msg
	CFG.status.TextColor3 = isError and Color3.fromRGB(255,100,100) or Themes[State.CurrentTheme].Accent
	CFG.status.TextTransparency = 0
	TweenService:Create(CFG.status, TweenInfo.new(3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {TextTransparency = 1}):Play()
end

-- ================= FILE EXPLORER =================
local configEntries = {}
local function getFileName(p) return p:match("[^/\\]+$") or p end

-- ================= SAVE NAME WINDOW =================
local SaveW = {}
SaveW.frame = Instance.new("Frame")
SaveW.frame.Name = "SaveNameWindow"
SaveW.frame.Size = UDim2.new(0,400,0,220)
SaveW.frame.Position = UDim2.new(0.5,-200,0.5,-110)
SaveW.frame.BackgroundColor3 = Themes[State.CurrentTheme].Bg
SaveW.frame.BackgroundTransparency = 0.2
SaveW.frame.BorderSizePixel = 0
SaveW.frame.Visible = false
SaveW.frame.ZIndex = 700
SaveW.frame.Parent = screenGui
SaveW.corner = Instance.new("UICorner"); SaveW.corner.CornerRadius = UDim.new(0,12); SaveW.corner.Parent = SaveW.frame
SaveW.stroke = Instance.new("UIStroke")
SaveW.stroke.Color = Themes[State.CurrentTheme].Stroke
SaveW.stroke.Transparency = 0.3; SaveW.stroke.Parent = SaveW.frame

SaveW.title = Instance.new("TextLabel")
SaveW.title.Text = "Название конфига"; SaveW.title.Font = FONT_MAIN; SaveW.title.TextSize = 18
SaveW.title.TextColor3 = Themes[State.CurrentTheme].Text
SaveW.title.Size = UDim2.new(1,-40,0,30); SaveW.title.Position = UDim2.new(0,20,0,15)
SaveW.title.TextXAlignment = Enum.TextXAlignment.Left
SaveW.title.BackgroundTransparency = 1; SaveW.title.ZIndex = 701; SaveW.title.Parent = SaveW.frame

SaveW.input = Instance.new("TextBox")
SaveW.input.Size = UDim2.new(1,-40,0,44); SaveW.input.Position = UDim2.new(0,20,0,60)
SaveW.input.BackgroundColor3 = Themes[State.CurrentTheme].Card
SaveW.input.BackgroundTransparency = 0.3
SaveW.input.BorderSizePixel = 0; SaveW.input.Font = FONT_TEXT; SaveW.input.TextSize = 16
SaveW.input.TextColor3 = Themes[State.CurrentTheme].Text
SaveW.input.PlaceholderText = "Например: MyConfig"
SaveW.input.PlaceholderColor3 = Themes[State.CurrentTheme].Text
SaveW.input.Text = ""; SaveW.input.ClearTextOnFocus = false
SaveW.input.ZIndex = 701; SaveW.input.Parent = SaveW.frame
SaveW.inputCorner = Instance.new("UICorner"); SaveW.inputCorner.CornerRadius = UDim.new(0,8); SaveW.inputCorner.Parent = SaveW.input
SaveW.inputStroke = Instance.new("UIStroke")
SaveW.inputStroke.Color = Themes[State.CurrentTheme].Stroke
SaveW.inputStroke.Transparency = 0.5; SaveW.inputStroke.Parent = SaveW.input

local saveBtnRow = Instance.new("Frame")
saveBtnRow.Size = UDim2.new(1, -40, 0, 40)
saveBtnRow.Position = UDim2.new(0, 20, 0, 160)
saveBtnRow.BackgroundTransparency = 1
saveBtnRow.ZIndex = 701
saveBtnRow.Parent = SaveW.frame

local saveBtnLayout = Instance.new("UIListLayout")
saveBtnLayout.FillDirection = Enum.FillDirection.Horizontal
saveBtnLayout.Padding = UDim.new(0, 12)
saveBtnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
saveBtnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
saveBtnLayout.SortOrder = Enum.SortOrder.LayoutOrder
saveBtnLayout.Parent = saveBtnRow

SaveW.cancel = Instance.new("TextButton")
SaveW.cancel.Size = UDim2.new(0, 160, 0, 40)
SaveW.cancel.BackgroundColor3 = Themes[State.CurrentTheme].Card
SaveW.cancel.BackgroundTransparency = 0.3
SaveW.cancel.Text = "Назад"; SaveW.cancel.Font = FONT_MAIN; SaveW.cancel.TextSize = 15
SaveW.cancel.TextColor3 = Themes[State.CurrentTheme].Text
SaveW.cancel.AutoButtonColor = false
SaveW.cancel.LayoutOrder = 1
SaveW.cancel.ZIndex = 701; SaveW.cancel.Parent = saveBtnRow
SaveW.cancelCorner = Instance.new("UICorner"); SaveW.cancelCorner.CornerRadius = UDim.new(0,8); SaveW.cancelCorner.Parent = SaveW.cancel

SaveW.ok = Instance.new("TextButton")
SaveW.ok.Size = UDim2.new(0, 160, 0, 40)
SaveW.ok.BackgroundColor3 = Themes[State.CurrentTheme].Accent
SaveW.ok.BackgroundTransparency = 0.3
SaveW.ok.Text = "OK"; SaveW.ok.Font = FONT_MAIN; SaveW.ok.TextSize = 15
SaveW.ok.TextColor3 = Themes[State.CurrentTheme].Bg
SaveW.ok.AutoButtonColor = false
SaveW.ok.LayoutOrder = 2
SaveW.ok.ZIndex = 701; SaveW.ok.Parent = saveBtnRow
SaveW.okCorner = Instance.new("UICorner"); SaveW.okCorner.CornerRadius = UDim.new(0,8); SaveW.okCorner.Parent = SaveW.ok

local function openSaveName()
	SaveW.input.Text = ""
	SaveW.frame.Visible = true
	SaveW.frame.Size = UDim2.new(0,0,0,0)
	SaveW.frame.Position = UDim2.new(0.5,0,0.5,0)
	TweenService:Create(SaveW.frame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0,400,0,220), Position = UDim2.new(0.5,-200,0.5,-110)
	}):Play()
end
local function closeSaveName()
	TweenService:Create(SaveW.frame, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
		Size = UDim2.new(0,0,0,0), Position = UDim2.new(0.5,0,0.5,0)
	}):Play()
	task.delay(0.25, function() SaveW.frame.Visible = false end)
end

addConnection(SaveW.cancel.MouseButton1Click:Connect(function()
	playSound(SFX.Off); closeSaveName()
end))
addConnection(SaveW.ok.MouseButton1Click:Connect(function()
	if ScriptUnloaded then return end
	local n = SaveW.input.Text:gsub("[^%w_%-%s]", ""):gsub("%s+", "_")
	if n == "" then showStatus("Введи название", true); return end
	ensureConfigFolder()
	local full = CONFIG_FOLDER.."/"..n..".json"
	local ok, err = safeWriteFile(full, serializeConfig())
	if ok then
		showStatus("Сохранено: "..n..".json", false)
		playSound(SFX.On)
		closeSaveName()
		task.wait(0.3)
		refreshExplorer()
	else
		showStatus("Ошибка: "..tostring(err), true)
	end
end))

-- ================= EXPLORER FUNC =================
-- [FIX 4] Присваиваем в forward-declared local
refreshExplorer = function()
	for _, child in ipairs(CFG.explorerScroll:GetChildren()) do
		if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end
	end
	configEntries = {}

	if not hasFileAPI() or not hasListAPI() then
		local w = Instance.new("TextLabel")
		w.Text = "Файловый API недоступен. Нужен executor с writefile/readfile/listfiles."
		w.Font = FONT_TEXT; w.TextSize = 13
		w.TextColor3 = Color3.fromRGB(255,100,100)
		w.Size = UDim2.new(1,-20,0,40); w.Position = UDim2.new(0,10,0,10)
		w.TextWrapped = true; w.BackgroundTransparency = 1; w.ZIndex = 14
		w.Parent = CFG.explorerScroll
		return
	end

	local files = safeListFiles(CONFIG_FOLDER)
	local jsonFiles = {}
	for _, f in ipairs(files) do
		if type(isfile) == "function" then
			local ok, isf = pcall(isfile, f)
			if ok and isf and f:lower():match("%.json$") then table.insert(jsonFiles, f) end
		else
			if f:lower():match("%.json$") then table.insert(jsonFiles, f) end
		end
	end

	if #jsonFiles == 0 then
		local e = Instance.new("TextLabel")
		e.Text = "Папка пуста. Нажми 'Сохранить конфиг'."
		e.Font = FONT_TEXT; e.TextSize = 13
		e.TextColor3 = Themes[State.CurrentTheme].Text
		e.TextTransparency = 0.4
		e.Size = UDim2.new(1,-20,0,40); e.Position = UDim2.new(0,10,0,10)
		e.TextWrapped = true; e.BackgroundTransparency = 1; e.ZIndex = 14
		e.Parent = CFG.explorerScroll
		return
	end

	for _, path in ipairs(jsonFiles) do
		local fn = getFileName(path)
		local entry = Instance.new("TextButton")
		entry.Name = "Entry_"..fn
		entry.Size = UDim2.new(1,-10,0,34)
		entry.BackgroundColor3 = Themes[State.CurrentTheme].Bg
		entry.BackgroundTransparency = 0.6
		entry.Text = ""; entry.AutoButtonColor = false
		entry.ZIndex = 13; entry.Parent = CFG.explorerScroll
		local ec2 = Instance.new("UICorner"); ec2.CornerRadius = UDim.new(0,6); ec2.Parent = entry

		local ico = Instance.new("TextLabel")
		ico.Text = "📄"; ico.Font = FONT_TEXT; ico.TextSize = 16
		ico.TextColor3 = Themes[State.CurrentTheme].Text
		ico.Size = UDim2.new(0,28,1,0); ico.Position = UDim2.new(0,8,0,0)
		ico.BackgroundTransparency = 1; ico.ZIndex = 14; ico.Parent = entry

		local nl = Instance.new("TextLabel")
		nl.Text = fn; nl.Font = FONT_TEXT; nl.TextSize = 14
		nl.TextColor3 = Themes[State.CurrentTheme].Text
		nl.Size = UDim2.new(1,-50,1,0); nl.Position = UDim2.new(0,38,0,0)
		nl.TextXAlignment = Enum.TextXAlignment.Left
		nl.BackgroundTransparency = 1; nl.ZIndex = 14; nl.Parent = entry

		entry:SetAttribute("Path", path)
		entry:SetAttribute("FileName", fn)
		table.insert(configEntries, {entry = entry, path = path, fileName = fn})

		addConnection(entry.MouseButton1Click:Connect(function()
			if ScriptUnloaded then return end
			for _, e in ipairs(configEntries) do
				if e.entry and e.entry.Parent then
					TweenService:Create(e.entry, TweenInfo.new(0.15), {BackgroundTransparency = 0.6, BackgroundColor3 = Themes[State.CurrentTheme].Bg}):Play()
				end
			end
			State.SelectedConfig = path
			TweenService:Create(entry, TweenInfo.new(0.15), {BackgroundTransparency = 0.2, BackgroundColor3 = Themes[State.CurrentTheme].Accent}):Play()
			playSound(SFX.On)
		end))
	end
end

-- ================= APPLY ALL =================
local function applyAllFromState()
	applyFog(); applySky(); applyFullbright(); applyWorld()
	applyParticles(); applyTrails(); applyChinaHat(); applyWings(); applyKagune()
	HUD.frame.Visible = State.HudEnabled
	if State.HudEnabled then
		HUD.frame.Size = UDim2.new(0,280,0,38)
		HUD.frame.Position = UDim2.new(0.5,-140,0,15)
	end
	if State.JumpCircleEnabled then setupJumpCircle() end
	applyThemeToUI(State.CurrentTheme)
	syncVisualCards()
end

-- ================= CONFIG BUTTONS =================
addConnection(CFG.save.MouseButton1Click:Connect(function()
	if ScriptUnloaded then return end
	playSound(SFX.On); openSaveName()
end))
addConnection(CFG.refresh.MouseButton1Click:Connect(function()
	if ScriptUnloaded then return end
	playSound(SFX.On); refreshExplorer(); showStatus("Список обновлён", false)
end))
addConnection(CFG.importBtn.MouseButton1Click:Connect(function()
	if ScriptUnloaded then return end
	playSound(SFX.On)
	local path = getAbsoluteConfigPath()
	local ok = safeSetClipboard(path)
	if ok then showStatus("Путь скопирован: "..path, false)
	else showStatus("Не удалось скопировать", true) end
end))
addConnection(CFG.load.MouseButton1Click:Connect(function()
	if ScriptUnloaded then return end
	if not State.SelectedConfig then showStatus("Выбери конфиг в списке", true); return end
	local d = safeReadFile(State.SelectedConfig)
	if not d or d == "" then showStatus("Не удалось прочитать", true); return end
	if deserializeConfig(d) then
		applyAllFromState()
		showStatus("Загружено: "..getFileName(State.SelectedConfig), false)
		playSound(SFX.On)
	else
		showStatus("Неверный формат", true)
	end
end))
addConnection(CFG.delete.MouseButton1Click:Connect(function()
	if ScriptUnloaded then return end
	if not State.SelectedConfig then showStatus("Выбери конфиг", true); return end
	local ok, err = safeDeleteFile(State.SelectedConfig)
	if ok then
		showStatus("Удалено: "..getFileName(State.SelectedConfig), false)
		State.SelectedConfig = nil
		playSound(SFX.Off)
		task.wait(0.3)
		refreshExplorer()
	else
		showStatus("Ошибка: "..tostring(err), true)
	end
end))

-- ================= TABS =================
local tabButtons = {UI.btnVisuals, UI.btnThemes, UI.btnConfigs}
local tabInds = {UI.indVisuals, UI.indThemes, UI.indConfigs}
local tabTexts = {UI.txtVisuals, UI.txtThemes, UI.txtConfigs}
local tabFrames = {UI.visuals, UI.themes, UI.configs}

local function selectTab(idx)
	for i, b in ipairs(tabButtons) do
		b:SetAttribute("Selected", false)
		TweenService:Create(b, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
		TweenService:Create(tabTexts[i], TweenInfo.new(0.2), {TextColor3 = STYLE.TextDim}):Play()
		TweenService:Create(tabInds[i], TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
	end
	local sb = tabButtons[idx]
	sb:SetAttribute("Selected", true)
	TweenService:Create(sb, TweenInfo.new(0.2), {BackgroundTransparency = 0.85}):Play()
	TweenService:Create(tabTexts[idx], TweenInfo.new(0.2), {TextColor3 = Themes[State.CurrentTheme].Text}):Play()
	TweenService:Create(tabInds[idx], TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
	for _, f in ipairs(tabFrames) do f.Visible = false end
	tabFrames[idx].Visible = true
	if idx == 3 then refreshExplorer() end
end

addConnection(UI.btnVisuals.MouseButton1Click:Connect(function() if not ScriptUnloaded then selectTab(1) end end))
addConnection(UI.btnThemes.MouseButton1Click:Connect(function() if not ScriptUnloaded then selectTab(2) end end))
addConnection(UI.btnConfigs.MouseButton1Click:Connect(function() if not ScriptUnloaded then selectTab(3) end end))
selectTab(1)

-- ================= TOGGLE MENU =================
local function toggleMenu()
	if ScriptUnloaded then return end
	State.MenuOpen = not State.MenuOpen
	if State.MenuOpen then
		playSound(SFX.MenuOpen)
		Bubble.frame.Size = UDim2.new(0,10,0,10)
		Bubble.frame.Position = UDim2.new(0.5,-5,0.5,-5)
		Bubble.stroke.Transparency = 0.5
		Bubble.frame.BackgroundTransparency = 0.8
		TweenService:Create(Bubble.frame, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.new(0,1000,0,1000), Position = UDim2.new(0.5,-500,0.5,-500),
			BackgroundTransparency = 1
		}):Play()
		TweenService:Create(Bubble.stroke, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Transparency = 1, Thickness = 0
		}):Play()
		UI.main.Visible = true
		UI.main.Size = UDim2.new(0,0,0,0)
		UI.main.Position = UDim2.new(0.5,0,0.5,0)
		TweenService:Create(UI.main, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0,980,0,640), Position = UDim2.new(0.5,-490,0.5,-320)
		}):Play()
		TweenService:Create(blur, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = 24}):Play()
		dimOverlay.Visible = true
		dimOverlay.BackgroundTransparency = 1
		TweenService:Create(dimOverlay, TweenInfo.new(0.5), {BackgroundTransparency = 0.5}):Play()
	else
		playSound(SFX.MenuClose)
		TweenService:Create(UI.main, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
			Size = UDim2.new(0,0,0,0), Position = UDim2.new(0.5,0,0.5,0)
		}):Play()
		TweenService:Create(blur, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size = 0}):Play()
		TweenService:Create(dimOverlay, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
		for _, w in pairs(WINS) do if w.frame then w.frame.Visible = false end end
		SaveW.frame.Visible = false
		State.OpenSettings = nil
		task.wait(0.35)
		if not ScriptUnloaded then
			UI.main.Visible = false
			dimOverlay.Visible = false
		end
	end
end

addConnection(UserInputService.InputBegan:Connect(function(input, gp)
	if ScriptUnloaded or gp then return end
	if input.KeyCode == Enum.KeyCode.RightShift then toggleMenu() end
end))

local dragH = Instance.new("Frame")
dragH.Size = UDim2.new(1,0,0,45)
dragH.BackgroundTransparency = 1
dragH.ZIndex = 15
dragH.Parent = UI.main
makeDraggable(UI.main, dragH)

-- ================= AUTOLOAD =================
task.spawn(function()
	task.wait(1)
	ensureConfigFolder()
	local d = safeReadFile(CONFIG_FOLDER.."/autoload.json")
	if d and d ~= "" then
		if deserializeConfig(d) then
			applyAllFromState()
			print("Kimiko: автозагружен autoload.json")
		end
	end
end)

print("Kimiko Visuals v51 loaded.")
print("Путь к конфигам: "..getAbsoluteConfigPath())
