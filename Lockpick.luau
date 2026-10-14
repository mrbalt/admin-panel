local WAYPOINTS, REFRESH_WPS = {}, nil
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local player = Players.LocalPlayer
local mouse = player:GetMouse()
local TOGGLE_KEY = Enum.KeyCode.RightShift
local rebinding = false
local DEFAULTS = {
WalkSpeed = 16, JumpPower = 50,
Gravity = math.floor(workspace.Gravity * 10 + 0.5) / 10,
FOV = math.floor(workspace.CurrentCamera.FieldOfView + 0.5),
MaxZoom = math.clamp(math.floor(player.CameraMaxZoomDistance), 5, 1000),
ClockTime = math.floor(Lighting.ClockTime * 10 + 0.5) / 10,
}
local S = {
fly = false, flySpeed = 70, noclip = false, infjump = false,
spin = false, spinSpeed = 360, clicktp = false, antiafk = false,
esp = false, walkSpeed = nil, jumpPower = nil, muted = false, flow = true, animSpeed = 1, sprint = false, sprintMult = 1.8, glide = false, glideSpeed = 25, airwalk = false, dash = false, dashForce = 90, zoom = false, zoomFov = 20, fov = nil, timeFlow = false, timeSpeed = 1, inspect = false, winAlpha = 0, follow = false, orbit = false, followDist = 8, autowalk = false, autojump = false, facemouse = false, clickwalk = false, trail = false, selfglow = false, rainbowchar = false, neon = false, bhop = false, freeze = false, antivoid = false, freecam = false, freecamSpeed = 60, tracers = false, rainbow = false, timeLock = nil, clickdelete = false,
}
local C = {
bg = Color3.fromRGB(13, 14, 19), surface = Color3.fromRGB(20, 22, 30),
elevated = Color3.fromRGB(28, 30, 41), hover = Color3.fromRGB(40, 43, 58),
stroke = Color3.fromRGB(46, 49, 66), text = Color3.fromRGB(240, 242, 250),
muted = Color3.fromRGB(125, 131, 155),
}
local THEMES = {
{ "Azure", Color3.fromRGB(80, 140, 255) }, { "Violet", Color3.fromRGB(150, 110, 255) },
{ "Rose", Color3.fromRGB(255, 95, 150) }, { "Mint", Color3.fromRGB(50, 214, 150) },
{ "Amber", Color3.fromRGB(255, 170, 55) }, { "Crimson", Color3.fromRGB(255, 80, 90) },
{ "Cyan", Color3.fromRGB(45, 200, 230) },
}
local accent = THEMES[1][2]
local accentFns = {}
local function onAccent(fn) table.insert(accentFns, fn) fn(accent) end
local function setAccent(c) accent = c for _, fn in ipairs(accentFns) do fn(c) end end
local function shift(c, d) local h, s2, v = c:ToHSV() return Color3.fromHSV((h + d) % 1, s2, v) end
local flowGrads = {}
local function flowSeq(c)
return ColorSequence.new({
ColorSequenceKeypoint.new(0, c),
ColorSequenceKeypoint.new(0.33, shift(c, 0.12)),
ColorSequenceKeypoint.new(0.66, shift(c, 0.28)),
ColorSequenceKeypoint.new(1, c),
})
end
local conns = {}
local function connect(sig, fn) local c = sig:Connect(fn) table.insert(conns, c) return c end
local function new(class, props, parent)
local o = Instance.new(class)
for k, v in pairs(props) do o[k] = v end
if parent then o.Parent = parent end
return o
end
local function tween(o, props, t)
local tw = TweenService:Create(o, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
tw:Play()
return tw
end
local function corner(o, r) return new("UICorner", { CornerRadius = UDim.new(0, r or 8) }, o) end
local function stroke(o, c, th, tr)
return new("UIStroke", { Color = c or C.stroke, Thickness = th or 1, Transparency = tr or 0 }, o)
end
local function text(parent, props)
local d = { BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left }
for k, v in pairs(props) do d[k] = v end
return new("TextLabel", d, parent)
end
local function nextOrder(p)
local n = (p:GetAttribute("n") or 0) + 1
p:SetAttribute("n", n)
return n
end
local function getChar() return player.Character end
local function getHum() local c = getChar() return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot() local c = getChar() return c and c:FindFirstChild("HumanoidRootPart") end
local playerGui = player:WaitForChild("PlayerGui")
local oldGui = playerGui:FindFirstChild("Lockpick")
if oldGui then oldGui:Destroy() end
local gui = new("ScreenGui", { Name = "Lockpick", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999, IgnoreGuiInset = true }, playerGui)
local toastHolder = new("Frame", { Size = UDim2.new(0, 250, 1, -24), Position = UDim2.new(1, -266, 0, 0), BackgroundTransparency = 1 }, gui)
new("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, toastHolder)
local toastN = 0
local notifHistory = {}
local function toast(msg, force)
table.insert(notifHistory, 1, os.date("%H:%M:%S") .. "  " .. msg)
if #notifHistory > 40 then table.remove(notifHistory) end
if S.muted and not force then return end
toastN += 1
local t = new("CanvasGroup", { Size = UDim2.fromOffset(240, 36), BackgroundColor3 = C.surface, BorderSizePixel = 0, GroupTransparency = 1, LayoutOrder = toastN }, toastHolder)
corner(t, 10) stroke(t, C.stroke, 1, 0.2)
new("Frame", { Size = UDim2.new(0, 4, 1, 0), BackgroundColor3 = accent, BorderSizePixel = 0 }, t)
text(t, { Size = UDim2.new(1, -24, 1, 0), Position = UDim2.fromOffset(16, 0), Text = msg, TextSize = 13, Font = Enum.Font.GothamMedium, TextTruncate = Enum.TextTruncate.AtEnd })
tween(t, { GroupTransparency = 0 }, 0.2)
task.delay(2.2, function()
if t.Parent then
tween(t, { GroupTransparency = 1 }, 0.3)
task.delay(0.35, function() if t.Parent then t:Destroy() end end)
end
end)
end
local win = new("Frame", { Name = "Window", Size = UDim2.fromOffset(640, 440), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1 }, gui)
local winScale = new("UIScale", {}, win)
local userScale = 1
local function fit()
local vp = gui.AbsoluteSize
if vp.X < 10 then return end
winScale.Scale = math.min(1, vp.X / 680, vp.Y / 480) * userScale
end
fit()
connect(gui:GetPropertyChangedSignal("AbsoluteSize"), fit)
do
gui:SetAttribute("t0", os.clock())
local sp = new("CanvasGroup", { Name = "Splash", Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.bg, BorderSizePixel = 0, ZIndex = 100 }, win)
corner(sp, 14)
local function box(size, pos, col, z, par, r, anc)
local f = new("Frame", { Size = size, Position = pos, AnchorPoint = anc or Vector2.new(0.5, 0.5), BackgroundColor3 = col, BorderSizePixel = 0, ZIndex = z }, par or sp)
if r then corner(f, r) end
return f
end
local sh = box(UDim2.fromOffset(70, 90), UDim2.new(0.5, 0, 0.5, -30), C.bg, 1, sp, 35)
sh.BackgroundTransparency = 1
stroke(sh, Color3.fromRGB(175, 180, 195), 10, 0)
local body = box(UDim2.fromOffset(116, 88), UDim2.new(0.5, 0, 0.5, 18), Color3.new(1, 1, 1), 2, sp, 14)
new("UIGradient", { Color = flowSeq(accent), Rotation = 45 }, body)
box(UDim2.fromOffset(16, 16), UDim2.new(0.5, 0, 0.5, 10), C.bg, 3, sp, 8)
box(UDim2.fromOffset(7, 20), UDim2.new(0.5, 0, 0.5, 26), C.bg, 3, sp, 3)
local pick = box(UDim2.fromOffset(112, 28), UDim2.new(0.5, -240, 0.5, 12), C.bg, 4, sp, nil, Vector2.new(1, 0.5))
pick.BackgroundTransparency = 1
local silver = Color3.fromRGB(205, 210, 222)
box(UDim2.fromOffset(34, 12), UDim2.fromOffset(17, 14), Color3.fromRGB(255, 150, 60), 1, pick, 6)
box(UDim2.fromOffset(78, 3), UDim2.fromOffset(73, 14), silver, 1, pick, 1)
box(UDim2.fromOffset(3, 9), UDim2.fromOffset(108, 10), silver, 1, pick, 1)
local wr = box(UDim2.fromOffset(34, 4), UDim2.new(0.5, 0, 0.5, 34), Color3.fromRGB(150, 155, 170), 4, sp, 2, Vector2.new(0, 0.5))
text(sp, { Size = UDim2.fromOffset(300, 30), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 112), Text = "LOCKPICK", Font = Enum.Font.GothamBlack, TextSize = 26, TextXAlignment = Enum.TextXAlignment.Center })
local sub = text(sp, { Size = UDim2.fromOffset(300, 16), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 140), Text = "picking the lock...", TextSize = 12, TextColor3 = C.muted, TextXAlignment = Enum.TextXAlignment.Center })
tween(pick, { Position = UDim2.new(0.5, 4, 0.5, 12) }, 1.9)
task.delay(2, function()
sub.Text = "feeling the pins..."
for i = 1, 8 do
tween(pick, { Rotation = i % 2 == 0 and 5 or -5 }, 0.08)
task.wait(0.16)
end
tween(pick, { Rotation = 0 }, 0.1)
end)
task.delay(3.5, function() tween(wr, { Rotation = -35 }, 0.3) end)
task.delay(3.8, function()
tween(sh, { Position = UDim2.new(0.5, 0, 0.5, -52), Rotation = -18 }, 0.7)
sub.Text = "unlocked."
sub.TextColor3 = accent
end)
RunService.RenderStepped:Wait()
end
local shadow = new("Frame", { Size = UDim2.new(1, 30, 1, 30), Position = UDim2.fromOffset(-15, -8), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, ZIndex = 0 }, win)
corner(shadow, 24)
onAccent(function(c) shadow.BackgroundColor3 = c:Lerp(Color3.new(0, 0, 0), 0.6) end)
local main = new("CanvasGroup", { Name = "Main", Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.bg, BorderSizePixel = 0, GroupTransparency = 1 }, win)
corner(main, 14)
local mainStroke = stroke(main, C.stroke, 1, 0)
mainStroke.Color = Color3.new(1, 1, 1)
mainStroke.Thickness = 1.5
mainStroke.Transparency = 0.3
local msGrad = new("UIGradient", {}, mainStroke)
onAccent(function(c) msGrad.Color = flowSeq(c) end)
table.insert(flowGrads, msGrad)
local bgFill = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, main)
new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(18, 19, 27), Color3.fromRGB(11, 12, 17)), Rotation = 90 }, bgFill)
local topLine = new("Frame", { Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 5 }, main)
local topGrad = new("UIGradient", {}, topLine)
onAccent(function(c) topGrad.Color = flowSeq(c) end)
table.insert(flowGrads, topGrad)
do
local MIN_W, MIN_H = 520, 360
local THICK = 8
local rs = nil
local function makeHandle(dx, dy, size, pos, cursor)
local h = new("TextButton", { Size = size, Position = pos, BackgroundColor3 = accent, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 20, BorderSizePixel = 0 }, win)
corner(h, 4)
onAccent(function(c) h.BackgroundColor3 = c end)
h.MouseEnter:Connect(function()
tween(h, { BackgroundTransparency = 0.4 }, 0.1)
if not rs then mouse.Icon = cursor end
end)
h.MouseLeave:Connect(function()
if not rs or rs.h ~= h then
tween(h, { BackgroundTransparency = 1 }, 0.15)
if not rs then mouse.Icon = "" end
end
end)
h.InputBegan:Connect(function(i)
if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
rs = { h = h, dx = dx, dy = dy, start = Vector2.new(i.Position.X, i.Position.Y), w = win.Size.X.Offset, ht = win.Size.Y.Offset, pos = win.Position }
mouse.Icon = cursor
end
end)
end
local EW, NS = "rbxasset://SystemCursors/SizeEW", "rbxasset://SystemCursors/SizeNS"
local NWSE, NESW = "rbxasset://SystemCursors/SizeNWSE", "rbxasset://SystemCursors/SizeNESW"
makeHandle(-1, 0, UDim2.new(0, THICK, 1, -28), UDim2.new(0, -THICK / 2, 0, 14), EW)
makeHandle(1, 0, UDim2.new(0, THICK, 1, -28), UDim2.new(1, -THICK / 2, 0, 14), EW)
makeHandle(0, -1, UDim2.new(1, -28, 0, THICK), UDim2.new(0, 14, 0, -THICK / 2), NS)
makeHandle(0, 1, UDim2.new(1, -28, 0, THICK), UDim2.new(0, 14, 1, -THICK / 2), NS)
makeHandle(-1, -1, UDim2.fromOffset(18, 18), UDim2.new(0, -9, 0, -9), NWSE)
makeHandle(1, -1, UDim2.fromOffset(18, 18), UDim2.new(1, -9, 0, -9), NESW)
makeHandle(-1, 1, UDim2.fromOffset(18, 18), UDim2.new(0, -9, 1, -9), NESW)
makeHandle(1, 1, UDim2.fromOffset(18, 18), UDim2.new(1, -9, 1, -9), NWSE)
connect(UIS.InputChanged, function(i)
if not rs then return end
if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then return end
local d = Vector2.new(i.Position.X, i.Position.Y) - rs.start
local sc = winScale.Scale
local vp = gui.AbsoluteSize
local maxW, maxH = math.max(MIN_W, vp.X / sc - 12), math.max(MIN_H, vp.Y / sc - 12)
local nw = math.clamp(rs.w + rs.dx * d.X / sc, MIN_W, maxW)
local nh = math.clamp(rs.ht + rs.dy * d.Y / sc, MIN_H, maxH)
local dw, dh = nw - rs.w, nh - rs.ht
win.Size = UDim2.fromOffset(nw, nh)
win.Position = UDim2.new(rs.pos.X.Scale, rs.pos.X.Offset + rs.dx * dw * sc / 2, rs.pos.Y.Scale, rs.pos.Y.Offset + rs.dy * dh * sc / 2)
end)
connect(UIS.InputEnded, function(i)
if rs and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
local h = rs.h
rs = nil
tween(h, { BackgroundTransparency = 1 }, 0.15)
mouse.Icon = ""
end
end)
end
-- Header
local header = new("Frame", { Size = UDim2.new(1, 0, 0, 52), Position = UDim2.fromOffset(0, 2), BackgroundTransparency = 1 }, main)
local logo = new("Frame", { Size = UDim2.fromOffset(30, 30), Position = UDim2.fromOffset(18, 11), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, header)
corner(logo, 9)
local logoGrad = new("UIGradient", { Rotation = 45 }, logo)
onAccent(function(c) logoGrad.Color = flowSeq(c) end)
table.insert(flowGrads, logoGrad)
text(logo, { Size = UDim2.fromScale(1, 1), Text = "L", Font = Enum.Font.GothamBlack, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Center })
local title = text(header, { Size = UDim2.fromOffset(240, 22), Position = UDim2.fromOffset(58, 8), Font = Enum.Font.GothamBold, TextSize = 17, RichText = true })
onAccent(function(c)
title.Text = string.format('LOCK<font color="rgb(%d,%d,%d)">PICK</font>', math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end)
text(header, { Size = UDim2.fromOffset(240, 14), Position = UDim2.fromOffset(58, 29), Text = "client-side toolkit  •  v3", TextSize = 11, TextColor3 = C.muted })
local stats = text(header, { Size = UDim2.fromOffset(190, 52), Position = UDim2.new(1, -250, 0, 0), Text = "", TextSize = 12, TextColor3 = C.muted, TextXAlignment = Enum.TextXAlignment.Right })
local closeBtn = new("TextButton", { Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, -44, 0, 11), BackgroundColor3 = C.elevated, Text = "X", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.muted, AutoButtonColor = false }, header)
corner(closeBtn, 8)
closeBtn.MouseEnter:Connect(function() tween(closeBtn, { BackgroundColor3 = Color3.fromRGB(220, 70, 85), TextColor3 = C.text }) end)
closeBtn.MouseLeave:Connect(function() tween(closeBtn, { BackgroundColor3 = C.elevated, TextColor3 = C.muted }) end)
new("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.fromOffset(0, 54), BackgroundColor3 = C.stroke, BackgroundTransparency = 0.3, BorderSizePixel = 0 }, main)
local sidebar = new("Frame", { Size = UDim2.new(0, 150, 1, -55), Position = UDim2.fromOffset(0, 55), BackgroundColor3 = C.surface, BackgroundTransparency = 0.35, BorderSizePixel = 0 }, main)
local searchFrame = new("Frame", { Size = UDim2.new(1, -20, 0, 32), Position = UDim2.fromOffset(10, 10), BackgroundColor3 = C.elevated, BorderSizePixel = 0 }, sidebar)
corner(searchFrame, 8)
local searchStroke = stroke(searchFrame, C.stroke, 1, 0.3)
local searchBox = new("TextBox", { Size = UDim2.new(1, -34, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1, Text = "", PlaceholderText = "Search...", PlaceholderColor3 = C.muted, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, ClipsDescendants = true }, searchFrame)
local searchClear = new("TextButton", { Size = UDim2.fromOffset(22, 22), Position = UDim2.new(1, -26, 0.5, -11), BackgroundTransparency = 1, Text = "X", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.muted, Visible = false }, searchFrame)
searchClear.MouseButton1Click:Connect(function() searchBox.Text = "" end)
searchBox.Focused:Connect(function() tween(searchStroke, { Color = accent, Transparency = 0 }) end)
searchBox.FocusLost:Connect(function() tween(searchStroke, { Color = C.stroke, Transparency = 0.3 }) end)
local tabHolder = new("ScrollingFrame", { Size = UDim2.new(1, 0, 1, -118), Position = UDim2.fromOffset(0, 52), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y }, sidebar)
local indicator = new("Frame", { Size = UDim2.fromOffset(3, 20), Position = UDim2.fromOffset(0, 13), BorderSizePixel = 0 }, tabHolder)
corner(indicator, 2)
onAccent(function(c) indicator.BackgroundColor3 = c end)
new("Frame", { Size = UDim2.new(1, -20, 0, 1), Position = UDim2.new(0, 10, 1, -62), BackgroundColor3 = C.stroke, BackgroundTransparency = 0.4, BorderSizePixel = 0 }, sidebar)
local avatar = new("ImageLabel", { Size = UDim2.fromOffset(36, 36), Position = UDim2.new(0, 12, 1, -50), BackgroundColor3 = C.elevated, BorderSizePixel = 0, Image = "" }, sidebar)
corner(avatar, 18)
task.spawn(function()
local ok, img = pcall(function() return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100) end)
if ok and avatar.Parent then avatar.Image = img end
end)
text(sidebar, { Size = UDim2.new(1, -62, 0, 16), Position = UDim2.new(0, 56, 1, -48), Text = player.DisplayName, Font = Enum.Font.GothamMedium, TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd })
local hintLabel = text(sidebar, { Size = UDim2.new(1, -62, 0, 14), Position = UDim2.new(0, 56, 1, -30), Text = "RightShift to toggle", TextSize = 11, TextColor3 = C.muted })
local content = new("Frame", { Size = UDim2.new(1, -150, 1, -55), Position = UDim2.fromOffset(150, 55), BackgroundTransparency = 1 }, main)
local pages, tabBtns, currentTab = {}, {}, nil
local function selectTab(name)
currentTab = name
for n, p in pairs(pages) do p.Visible = (n == name) end
for n, b in pairs(tabBtns) do
tween(b, { TextColor3 = n == name and C.text or C.muted, BackgroundTransparency = n == name and 0 or 1 })
end
local b = tabBtns[name]
tween(indicator, { Position = UDim2.fromOffset(0, b.Position.Y.Offset + 7) }, 0.2)
end
local tabOrder = 0
local function newPage(name)
tabOrder += 1
local sf = new("ScrollingFrame", { Name = name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.hover, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, Visible = false }, content)
new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, sf)
new("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 14), PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }, sf)
pages[name] = sf
local b = new("TextButton", { Name = name, Size = UDim2.new(1, -20, 0, 34), Position = UDim2.fromOffset(10, 6 + (tabOrder - 1) * 37), BackgroundColor3 = C.elevated, BackgroundTransparency = 1, Text = "    " .. name, Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = C.muted, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false }, tabHolder)
corner(b, 8)
b.MouseButton1Click:Connect(function()
if searchBox.Text ~= "" then searchBox.Text = "" end
selectTab(name)
end)
b.MouseEnter:Connect(function() if currentTab ~= name then tween(b, { BackgroundTransparency = 0.6 }) end end)
b.MouseLeave:Connect(function() if currentTab ~= name then tween(b, { BackgroundTransparency = 1 }) end end)
tabBtns[name] = b
return sf
end
local searchIndex = {}
local togglesByName, slidersByName, bindables = {}, {}, {}
local function register(f, txt)
local e = { f = f, text = string.lower(txt), parent = f.Parent, order = f.LayoutOrder }
table.insert(searchIndex, e)
f.InputBegan:Connect(function(i)
if i.UserInputType == Enum.UserInputType.MouseButton2 and searchIndex.toggleFav then searchIndex.toggleFav(e) end
end)
end
local resultsPage = new("ScrollingFrame", { Name = "__results", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.hover, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, Visible = false }, content)
new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, resultsPage)
new("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 14), PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }, resultsPage)
local resultsLabel = text(resultsPage, { Size = UDim2.new(1, 0, 0, 26), Text = "", Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = C.muted, TextYAlignment = Enum.TextYAlignment.Bottom, LayoutOrder = 0 })
pages["__results"] = resultsPage
local function restoreRow(e)
local tgt = (e.fav and searchIndex.favPage) or e.parent
if e.f.Parent ~= tgt then e.f.Parent = tgt end
e.f.LayoutOrder = e.fav and e.favOrder or e.order
end
local function runSearch(raw)
local q = string.lower(raw)
q = q:gsub("^%s+", "")
q = q:gsub("%s+$", "")
searchClear.Visible = raw ~= ""
if q == "" then
for _, e in ipairs(searchIndex) do restoreRow(e) end
indicator.Visible = true
if currentTab then selectTab(currentTab) end
return
end
local words = {}
for w in q:gmatch("%S+") do table.insert(words, w) end
local n = 0
for _, e in ipairs(searchIndex) do
local ok = true
for _, w in ipairs(words) do
if not string.find(e.text, w, 1, true) then ok = false break end
end
if ok then
n += 1
e.f.Parent = resultsPage
e.f.LayoutOrder = n
else
restoreRow(e)
end
end
resultsLabel.Text = n > 0 and (n .. " RESULT" .. (n == 1 and "" or "S")) or "NO MATCHES"
for name, p in pairs(pages) do p.Visible = (name == "__results") end
indicator.Visible = false
end
connect(searchBox:GetPropertyChangedSignal("Text"), function() runSearch(searchBox.Text) end)
local resetters = {}
local function section(page, t)
local sf = new("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, LayoutOrder = nextOrder(page) }, page)
local dot = new("Frame", { Size = UDim2.fromOffset(3, 12), Position = UDim2.new(0, 0, 1, -13), BorderSizePixel = 0 }, sf)
corner(dot, 2)
onAccent(function(c) dot.BackgroundColor3 = c end)
text(sf, { Size = UDim2.new(1, -12, 1, 0), Position = UDim2.fromOffset(10, 0), Text = string.upper(t), Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = C.muted, TextYAlignment = Enum.TextYAlignment.Bottom })
end
local function row(parent, h, order)
local f = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = C.surface, BorderSizePixel = 0, LayoutOrder = order or nextOrder(parent) }, parent)
corner(f, 10) stroke(f, C.stroke, 1, 0.4)
return f
end
local function toggle(page, name, desc, cb)
local f = row(page, desc and 52 or 40)
register(f, name .. " " .. (desc or ""))
text(f, { Size = UDim2.new(1, -80, 0, 20), Position = UDim2.fromOffset(14, desc and 8 or 10), Text = name, Font = Enum.Font.GothamMedium })
if desc then text(f, { Size = UDim2.new(1, -80, 0, 14), Position = UDim2.fromOffset(14, 28), Text = desc, TextSize = 11, TextColor3 = C.muted }) end
local track = new("TextButton", { Size = UDim2.fromOffset(42, 22), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), BackgroundColor3 = C.hover, Text = "", AutoButtonColor = false }, f)
corner(track, 11)
local knob = new("Frame", { Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = C.text, BorderSizePixel = 0 }, track)
corner(knob, 8)
local on = false
onAccent(function(c)
if on then
track.BackgroundColor3 = c
local st = f:FindFirstChildOfClass("UIStroke")
if st then st.Color = c end
end
end)
local obj = { get = function() return on end }
togglesByName[string.lower(name)] = obj
bindables[#bindables + 1] = { name = name, kind = "toggle", fire = function() obj.set(not on) end }
function obj.set(v, silent)
on = v
tween(track, { BackgroundColor3 = on and accent or C.hover })
local rowStroke = f:FindFirstChildOfClass("UIStroke")
if rowStroke then tween(rowStroke, { Color = on and accent or C.stroke, Transparency = on and 0.35 or 0.4 }) end
tween(knob, { Position = on and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3) })
cb(v)
if not silent then
toast(name .. (v and " enabled" or " disabled"))
if bindables.rec then bindables.rec("toggle " .. string.lower(name) .. (v and " on" or " off")) end
end
end
track.MouseButton1Click:Connect(function() obj.set(not on) end)
table.insert(resetters, function() if on then obj.set(false, true) end end)
return obj
end
local function slider(page, name, min, max, default, cb, decimals)
decimals = decimals or 0
local mult = 10 ^ decimals
local f = row(page, 58)
register(f, name)
text(f, { Size = UDim2.new(1, -100, 0, 20), Position = UDim2.fromOffset(14, 8), Text = name, Font = Enum.Font.GothamMedium })
local box = new("TextBox", { Size = UDim2.fromOffset(64, 22), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 7), BackgroundColor3 = C.elevated, Text = "", Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.text, ClearTextOnFocus = false, BorderSizePixel = 0 }, f)
corner(box, 6) stroke(box, C.stroke, 1, 0.3)
local track = new("Frame", { Size = UDim2.new(1, -28, 0, 6), Position = UDim2.fromOffset(14, 40), BackgroundColor3 = C.hover, BorderSizePixel = 0 }, f)
corner(track, 3)
local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BorderSizePixel = 0 }, track)
corner(fill, 3)
fill.BackgroundColor3 = Color3.new(1, 1, 1)
local fillGrad = new("UIGradient", {}, fill)
onAccent(function(c) fillGrad.Color = flowSeq(c) end)
table.insert(flowGrads, fillGrad)
local knob = new("Frame", { Size = UDim2.fromOffset(14, 14), Position = UDim2.new(0, -7, 0.5, -7), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, track)
corner(knob, 7)
local knobStroke = stroke(knob, C.stroke, 2, 0)
onAccent(function(c) knobStroke.Color = c end)
local hit = new("TextButton", { Size = UDim2.new(1, -14, 0, 28), Position = UDim2.fromOffset(7, 29), BackgroundTransparency = 1, Text = "" }, f)
local current = default
local function setValue(v, fire)
v = math.round(v * mult) / mult
current = v
box.Text = tostring(v)
local a = math.clamp((v - min) / (max - min), 0, 1)
fill.Size = UDim2.new(a, 0, 1, 0)
knob.Position = UDim2.new(a, -7, 0.5, -7)
if fire then cb(v) end
end
setValue(default, false)
local dragging = false
local function fromX(x)
local a = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
setValue(min + (max - min) * a, true)
end
hit.InputBegan:Connect(function(i)
if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
dragging = true
fromX(i.Position.X)
end
end)
connect(UIS.InputChanged, function(i)
if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
fromX(i.Position.X)
end
end)
connect(UIS.InputEnded, function(i)
if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)
box.FocusLost:Connect(function()
local n = tonumber(box.Text)
if n then setValue(n, true) else setValue(current, false) end
end)
table.insert(resetters, function() setValue(default, true) end)
local so = { set = function(v) setValue(v, true) end, get = function() return current end }
slidersByName[string.lower(name)] = so
bindables[#bindables + 1] = { name = name, kind = "slider", fire = function(dir) setValue(math.clamp(current + (max - min) / 10 * (dir or 1), min, max), true) end }
return so
end
local function makeButton(parent, label, cb, primary, size, order)
local b = new("TextButton", { Size = size or UDim2.new(1, 0, 0, 38), BackgroundColor3 = primary and accent or C.elevated, Text = label, Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = C.text, AutoButtonColor = false, LayoutOrder = order or 0 }, parent)
corner(b, 10)
if primary then
onAccent(function(c) b.BackgroundColor3 = c end)
else
stroke(b, C.stroke, 1, 0.4)
end
b.MouseEnter:Connect(function() tween(b, { BackgroundColor3 = primary and accent:Lerp(Color3.new(1, 1, 1), 0.15) or C.hover }) end)
b.MouseLeave:Connect(function() tween(b, { BackgroundColor3 = primary and accent or C.elevated }) end)
b.MouseButton1Click:Connect(cb)
return b
end
local function button(page, label, cb, primary)
local b = makeButton(page, label, cb, primary, nil, nextOrder(page))
register(b, label)
bindables[#bindables + 1] = { name = label, kind = "action", fire = cb }
return b
end
local function buttonRow(page, defs)
local holder = new("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, LayoutOrder = nextOrder(page) }, page)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, holder)
local n = #defs
local labels = {}
for _, d in ipairs(defs) do table.insert(labels, d[1]) end
register(holder, table.concat(labels, " "))
for i, d in ipairs(defs) do
bindables[#bindables + 1] = { name = d[1], kind = "action", fire = d[2] }
makeButton(holder, d[1], d[2], d[3], UDim2.new(1 / n, -8 * (n - 1) / n, 1, 0), i)
end
end
local function miniButton(parent, label, rightOffset, cb, primary)
local b = makeButton(parent, label, cb, primary, UDim2.fromOffset(50, 26), 0)
b.TextSize = 12
b.AnchorPoint = Vector2.new(1, 0.5)
b.Position = UDim2.new(1, -rightOffset, 0.5, 0)
return b
end
local function infoRow(page, key, desc)
local f = row(page, 36)
register(f, key .. " " .. desc .. " hotkey")
local pill = text(f, { Size = UDim2.fromOffset(104, 22), Position = UDim2.fromOffset(10, 7), Text = key, TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center, BackgroundTransparency = 0, BackgroundColor3 = C.elevated })
corner(pill, 6)
text(f, { Size = UDim2.new(1, -130, 1, 0), Position = UDim2.fromOffset(124, 0), Text = desc, TextSize = 13, TextColor3 = C.muted })
return pill
end
local pFav = newPage("Favorites")
local pPlayer = newPage("Player")
local pMove = newPage("Movement")
local pTp = newPage("Teleport")
local pEsp = newPage("ESP")
local pPInfo = newPage("Player Info")
local pVisual = newPage("Visuals")
local pCam = newPage("Camera")
local pHud = newPage("HUD")
local pWorld = newPage("World")
local pFun = newPage("Fun")
local pExp = newPage("Explorer")
local pTools = newPage("Tools")
local pAim = newPage("Aimbot")
local pKeys = newPage("Hotkeys")
local pSet = newPage("Settings")
local T = {}
local function flags(page, list)
for _, d in ipairs(list) do
local key = d[3]
if S[key] == nil then S[key] = false end
T[key] = toggle(page, d[1], d[2], function(v) S[key] = v if d[4] then d[4](v) end end)
end
end
local function binds(page, list)
for _, d in ipairs(list) do
local key = d[4]
if S[key] == nil then S[key] = d[5] end
slider(page, d[1], d[2], d[3], S[key], function(v) S[key] = v if d[7] then d[7](v) end end, d[6])
end
end
local function inbox(parent, ph, size, pos, multi)
local b = new("TextBox", { Size = size, Position = pos, BackgroundColor3 = C.elevated, Text = "", PlaceholderText = ph, PlaceholderColor3 = C.muted, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.text, ClearTextOnFocus = false, BorderSizePixel = 0, MultiLine = multi or false, TextWrapped = multi or false, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = multi and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center, ClipsDescendants = true }, parent)
corner(b, 8) stroke(b, C.stroke, 1, 0.3)
new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, multi and 6 or 0) }, b)
return b
end
local function irow(page, ph, label, cb, kw)
local f = row(page, 44)
register(f, kw or ph)
local b = inbox(f, ph, UDim2.new(1, -78, 0, 28), UDim2.fromOffset(8, 8))
miniButton(f, label, 8, function() cb(b.Text, b) end, true)
b.FocusLost:Connect(function(enter) if enter then cb(b.Text, b) end end)
return b
end
local function lrow(page, h, kw)
local f = row(page, h)
if kw then register(f, kw) end
return text(f, { Size = UDim2.new(1, -24, 1, -12), Position = UDim2.fromOffset(12, 6), TextSize = 12, TextColor3 = C.muted, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, Text = "" }), f
end
local function applyStats()
local hum = getHum()
if not hum then return end
if S.walkSpeed then hum.WalkSpeed = S.walkSpeed end
if S.jumpPower then hum.UseJumpPower = true hum.JumpPower = S.jumpPower end
end
local lastSafe
local noclipCache = {}
local function restoreNoclip()
for p, v in pairs(noclipCache) do if p.Parent then p.CanCollide = v end end
noclipCache = {}
end
local lightSaved
local function setFullbright(v)
if v then
lightSaved = { Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, GlobalShadows = Lighting.GlobalShadows, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient }
Lighting.Brightness = 2
Lighting.GlobalShadows = false
Lighting.Ambient = Color3.fromRGB(190, 190, 190)
Lighting.OutdoorAmbient = Color3.fromRGB(190, 190, 190)
elseif lightSaved then
for k, val in pairs(lightSaved) do if k ~= "ClockTime" then Lighting[k] = val end end
lightSaved = nil
end
end
local fogSaved
local function setNoFog(v)
local atm = Lighting:FindFirstChildOfClass("Atmosphere")
if v then
fogSaved = { end_ = Lighting.FogEnd, density = atm and atm.Density, haze = atm and atm.Haze }
Lighting.FogEnd = 1e6
if atm then atm.Density = 0 atm.Haze = 0 end
elseif fogSaved then
Lighting.FogEnd = fogSaved.end_
if atm and fogSaved.density then atm.Density = fogSaved.density atm.Haze = fogSaved.haze end
fogSaved = nil
end
end
local fxSaved = {}
local function setNoFX(v)
if v then
for _, e in ipairs(Lighting:GetChildren()) do
if e:IsA("PostEffect") then fxSaved[e] = e.Enabled e.Enabled = false end
end
else
for e, en in pairs(fxSaved) do if e.Parent then e.Enabled = en end end
fxSaved = {}
end
end
local xraySaved = {}
local function isCharPart(p)
local m = p:FindFirstAncestorOfClass("Model")
return m ~= nil and m:FindFirstChildOfClass("Humanoid") ~= nil
end
local function setXray(v)
if v then
for _, p in ipairs(workspace:GetDescendants()) do
if p:IsA("BasePart") and p.Transparency < 0.6 and not isCharPart(p) then
xraySaved[p] = p.Transparency
p.Transparency = 0.6
end
end
else
for p, t in pairs(xraySaved) do if p.Parent then p.Transparency = t end end
xraySaved = {}
end
end
local X = {}
local espObjs = {}
local function clearESP(plr)
local o = espObjs[plr]
if o then
if o.hl then o.hl:Destroy() end
if o.bb then o.bb:Destroy() end
espObjs[plr] = nil
end
end
local function applyESP(plr)
clearESP(plr)
if not S.esp or plr == player then return end
if X.espAllowed and not X.espAllowed(plr) then return end
local c = plr.Character
local head = c and c:FindFirstChild("Head")
if not head then return end
local col = (X.relCol and X.relCol(plr)) or (plr.Team and plr.TeamColor.Color or Color3.fromRGB(255, 255, 255))
local hl = new("Highlight", { Adornee = c, FillColor = col, OutlineColor = col, FillTransparency = 0.75, OutlineTransparency = 0, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop }, c)
local bb = new("BillboardGui", { Adornee = head, AlwaysOnTop = true, Size = UDim2.fromOffset(160, 34), StudsOffset = Vector3.new(0, 2.6, 0), LightInfluence = 0 }, head)
local tl = text(bb, { Size = UDim2.fromScale(1, 1), Text = plr.DisplayName, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = col, TextStrokeTransparency = 0.4, TextXAlignment = Enum.TextXAlignment.Center })
espObjs[plr] = { hl = hl, bb = bb, label = tl }
end
local function setESP(v)
S.esp = v
for _, plr in ipairs(Players:GetPlayers()) do
if v then applyESP(plr) else clearESP(plr) end
end
end
X.steps, X.ticks, X.keys, X.cleanups, X.clicks, X.stepWarned, X.userBinds = {}, {}, {}, {}, {}, {}, {}
X.notifHistory, X.bindables = notifHistory, bindables
function X.fireBind(b)
if b.kind == "slider" then b.fire(UIS:IsKeyDown(Enum.KeyCode.LeftShift) and -1 or 1) else b.fire() end
end
do
local ContextActionService = game:GetService("ContextActionService")
local tracerLayer = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 0 }, gui)
X.tracerLines = {}
function X.hideTracers() for _, l in pairs(X.tracerLines) do l.Visible = false end end
function X.updateTracers()
local cam = workspace.CurrentCamera
local vp = cam.ViewportSize
local origin = Vector2.new(vp.X / 2, vp.Y)
for _, plr in ipairs(Players:GetPlayers()) do
if plr ~= player then
local r = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
local line = X.tracerLines[plr]
if not line then
line = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1), Visible = false }, tracerLayer)
X.tracerLines[plr] = line
end
local show = false
if r then
local p, on = cam:WorldToViewportPoint(r.Position)
if on and p.Z > 0 then
local to = Vector2.new(p.X, p.Y)
local d = to - origin
line.Size = UDim2.fromOffset(d.Magnitude, 1.5)
line.Position = UDim2.fromOffset((origin.X + to.X) / 2, (origin.Y + to.Y) / 2)
line.Rotation = math.deg(math.atan2(d.Y, d.X))
line.BackgroundColor3 = plr.Team and plr.TeamColor.Color or accent
show = true
end
end
line.Visible = show
end
end
end
local fc = { yaw = 0, pitch = 0, pos = Vector3.zero }
function X.setFreecam(v)
S.freecam = v
local cam = workspace.CurrentCamera
if v then
local x, y = cam.CFrame:ToOrientation()
fc.pitch, fc.yaw, fc.pos = x, y, cam.CFrame.Position
cam.CameraType = Enum.CameraType.Scriptable
ContextActionService:BindActionAtPriority("LockpickFreecam", function() return Enum.ContextActionResult.Sink end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.Space, Enum.KeyCode.LeftShift)
else
ContextActionService:UnbindAction("LockpickFreecam")
UIS.MouseBehavior = Enum.MouseBehavior.Default
cam.CameraType = Enum.CameraType.Custom
local h = getHum()
if h then cam.CameraSubject = h end
end
end
function X.stepFreecam(dt)
local cam = workspace.CurrentCamera
if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
local d = UIS:GetMouseDelta()
fc.yaw -= d.X * 0.004
fc.pitch = math.clamp(fc.pitch - d.Y * 0.004, -1.5, 1.5)
else
UIS.MouseBehavior = Enum.MouseBehavior.Default
end
local rot = CFrame.fromOrientation(fc.pitch, fc.yaw, 0)
local mv = Vector3.zero
if UIS:IsKeyDown(Enum.KeyCode.W) then mv += rot.LookVector end
if UIS:IsKeyDown(Enum.KeyCode.S) then mv -= rot.LookVector end
if UIS:IsKeyDown(Enum.KeyCode.D) then mv += rot.RightVector end
if UIS:IsKeyDown(Enum.KeyCode.A) then mv -= rot.RightVector end
if UIS:IsKeyDown(Enum.KeyCode.E) or UIS:IsKeyDown(Enum.KeyCode.Space) then mv += Vector3.yAxis end
if UIS:IsKeyDown(Enum.KeyCode.Q) or UIS:IsKeyDown(Enum.KeyCode.LeftShift) then mv -= Vector3.yAxis end
if mv.Magnitude > 0 then mv = mv.Unit end
fc.pos += mv * S.freecamSpeed * (UIS:IsKeyDown(Enum.KeyCode.LeftControl) and 3 or 1) * dt
cam.CFrame = CFrame.new(fc.pos) * rot
end
local deleted = {}
function X.hidePart(p)
table.insert(deleted, { p, p.Transparency, p.CanCollide })
p.Transparency = 1
p.CanCollide = false
end
function X.undoDelete()
local e = table.remove(deleted)
if not e then return toast("Nothing to undo") end
if e[1].Parent then e[1].Transparency = e[2] e[1].CanCollide = e[3] end
toast("Part restored")
end
function X.restoreAll()
while #deleted > 0 do
local e = table.remove(deleted)
if e[1].Parent then e[1].Transparency = e[2] e[1].CanCollide = e[3] end
end
end
X.crosshair = new("Frame", { Size = UDim2.fromOffset(8, 8), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BorderSizePixel = 0, Visible = false }, gui)
new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, X.crosshair)
new("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1, Transparency = 0.3 }, X.crosshair)
onAccent(function(c) X.crosshair.BackgroundColor3 = c end)
end
do
local platform
local platY = 0
function X.setAirwalk(v)
S.airwalk = v
if v then
local root = getRoot()
if not root then return end
platY = root.Position.Y - 3.5
platform = new("Part", { Name = "LockpickPlatform", Size = Vector3.new(10, 1, 10), Anchored = true, CanCollide = true, Transparency = 0.6, Material = Enum.Material.Neon, Color = accent, CFrame = CFrame.new(root.Position.X, platY, root.Position.Z) }, workspace)
elseif platform then
platform:Destroy()
platform = nil
end
end
function X.stepAirwalk(dt)
local root = getRoot()
if not platform or not root then return end
if UIS:IsKeyDown(Enum.KeyCode.Space) then platY += 30 * dt end
if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then platY -= 30 * dt end
platform.Color = accent
platform.CFrame = CFrame.new(root.Position.X, platY, root.Position.Z)
end
local fxHidden = {}
local EFFECT_CLASSES = { "ParticleEmitter", "Smoke", "Fire", "Sparkles", "Beam", "Trail" }
function X.setHideEffects(v)
if v then
for _, e in ipairs(workspace:GetDescendants()) do
for _, cn in ipairs(EFFECT_CLASSES) do
if e:IsA(cn) then
fxHidden[e] = e.Enabled
e.Enabled = false
break
end
end
end
else
for e, en in pairs(fxHidden) do if e.Parent then e.Enabled = en end end
fxHidden = {}
end
end
function X.getBlur()
if not X.blur or not X.blur.Parent then X.blur = new("BlurEffect", { Name = "LockpickBlur", Size = 0 }, Lighting) end
return X.blur
end
local insp = new("Frame", { Size = UDim2.fromOffset(210, 94), BackgroundColor3 = C.surface, BorderSizePixel = 0, Visible = false, ZIndex = 50 }, gui)
corner(insp, 8) stroke(insp, C.stroke, 1, 0.2)
local inspText = text(insp, { Size = UDim2.new(1, -16, 1, -12), Position = UDim2.fromOffset(8, 6), Text = "", TextSize = 12, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 51 })
function X.setInspect(v)
S.inspect = v
insp.Visible = v
end
function X.stepInspect()
local t = mouse.Target
local loc = UIS:GetMouseLocation()
insp.Position = UDim2.fromOffset(loc.X + 18, loc.Y + 18)
if t then
local root = getRoot()
local dist = root and math.floor((t.Position - root.Position).Magnitude) or 0
local hp = mouse.Hit.Position
inspText.Text = string.format("%s\n%s  •  %s\nSize  %.1f, %.1f, %.1f\nHit  %.1f, %.1f, %.1f\n%d studs away", t.Name, t.ClassName, t.Material.Name, t.Size.X, t.Size.Y, t.Size.Z, hp.X, hp.Y, hp.Z, dist)
else
inspText.Text = "No target"
end
end
end
do
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
X.t0 = os.clock()
X.viewTarget = nil
X.auras = {
fire = { "Fire", "LockpickFire" },
sparkles = { "Sparkles", "LockpickSparkles" },
smoke = { "Smoke", "LockpickSmoke" },
}
local bodyCaches = { neon = {}, hide = {}, acc = {}, rainbow = {} }
local bodyProp = { neon = "Material", hide = "Transparency", acc = "Transparency", rainbow = "Color" }
local function bodyTargets(key)
local c = getChar()
local out = {}
if not c then return out end
for _, p in ipairs(c:GetDescendants()) do
if p:IsA("BasePart") then
if p.Name ~= "HumanoidRootPart" then
local isAcc = p.Parent ~= nil and p.Parent:IsA("Accessory")
if key ~= "acc" or isAcc then table.insert(out, p) end
end
elseif key == "hide" and p:IsA("Decal") then
table.insert(out, p)
end
end
return out
end
function X.bodyFeature(key, on)
local cache, prop = bodyCaches[key], bodyProp[key]
if on then
for _, p in ipairs(bodyTargets(key)) do
if cache[p] == nil then cache[p] = p[prop] end
if key == "neon" then
p.Material = Enum.Material.Neon
elseif key == "hide" or key == "acc" then
p.Transparency = 1
end
end
else
for p, v in pairs(cache) do if p.Parent then p[prop] = v end end
bodyCaches[key] = {}
end
end
function X.stepRainbow()
local cache = bodyCaches.rainbow
local col = Color3.fromHSV((os.clock() * 0.3) % 1, 0.8, 1)
for _, p in ipairs(bodyTargets("rainbow")) do
if cache[p] == nil then cache[p] = p.Color end
p.Color = col
end
end
function X.updateBodyFx()
local root, char = getRoot(), getChar()
for key, def in pairs(X.auras) do
local ex = root and root:FindFirstChild(def[2])
if S["aura_" .. key] and root then
if not ex then new(def[1], { Name = def[2] }, root) end
elseif ex then
ex:Destroy()
end
end
if root then
local tr = root:FindFirstChild("LockpickTrail")
if S.trail then
if not tr then
local a0 = new("Attachment", { Name = "LockpickA0", Position = Vector3.new(0, 1.2, 0) }, root)
local a1 = new("Attachment", { Name = "LockpickA1", Position = Vector3.new(0, -1.5, 0) }, root)
tr = new("Trail", { Name = "LockpickTrail", Attachment0 = a0, Attachment1 = a1, Lifetime = 0.7, LightEmission = 1, Transparency = NumberSequence.new(0.1, 1) }, root)
end
tr.Color = flowSeq(accent)
elseif tr then
tr:Destroy()
local a0, a1 = root:FindFirstChild("LockpickA0"), root:FindFirstChild("LockpickA1")
if a0 then a0:Destroy() end
if a1 then a1:Destroy() end
end
end
if S.selfglow and char then
if not X.glow or X.glow.Parent ~= char then
if X.glow then X.glow:Destroy() end
X.glow = new("Highlight", { Name = "LockpickGlow", FillTransparency = 0.6, OutlineTransparency = 0, DepthMode = Enum.HighlightDepthMode.Occluded, Adornee = char }, char)
end
X.glow.FillColor = accent
X.glow.OutlineColor = accent
elseif X.glow then
X.glow:Destroy()
X.glow = nil
end
if S.neon then X.bodyFeature("neon", true) end
end
function X.stepFollow(dt)
local t = X.viewTarget
local tr = t and t.Character and t.Character:FindFirstChild("HumanoidRootPart")
local root = getRoot()
if not tr or not root then return end
if S.orbit then
X.orbitAngle = (X.orbitAngle or 0) + dt * 1.5
local off = Vector3.new(math.cos(X.orbitAngle), 0, math.sin(X.orbitAngle)) * S.followDist
root.CFrame = CFrame.lookAt(tr.Position + off, tr.Position)
elseif S.follow then
root.CFrame = tr.CFrame * CFrame.new(0, 0, S.followDist)
end
end
X.blocks = {}
function X.spawnBlock()
local root = getRoot()
if not root then return end
local p = new("Part", { Name = "LockpickBlock", Size = Vector3.new(4, 4, 4), Anchored = true, Material = Enum.Material.SmoothPlastic, Color = accent, CFrame = root.CFrame * CFrame.new(0, -1.5, -6) }, workspace)
table.insert(X.blocks, p)
toast("Block spawned")
end
function X.clearBlocks()
for _, b in ipairs(X.blocks) do b:Destroy() end
X.blocks = {}
end
local texCache, matCache = {}, {}
function X.setNoTextures(v)
if v then
local ch = getChar()
for _, d in ipairs(workspace:GetDescendants()) do
if (d:IsA("Decal") or d:IsA("Texture")) and not (ch and d:IsDescendantOf(ch)) then
texCache[d] = d.Transparency
d.Transparency = 1
end
end
else
for d, t in pairs(texCache) do if d.Parent then d.Transparency = t end end
texCache = {}
end
end
function X.setPlainMaterials(v)
if v then
for _, p in ipairs(workspace:GetDescendants()) do
if p:IsA("BasePart") and not p:IsA("Terrain") and not isCharPart(p) then
matCache[p] = p.Material
p.Material = Enum.Material.SmoothPlastic
end
end
else
for p, m in pairs(matCache) do if p.Parent then p.Material = m end end
matCache = {}
end
end
local waterSaved
function X.setClearWater(v)
local t = workspace.Terrain
if v then
waterSaved = { t.WaterTransparency, t.WaterReflectance, t.WaterWaveSize }
t.WaterTransparency = 1
t.WaterReflectance = 0
t.WaterWaveSize = 0
elseif waterSaved then
t.WaterTransparency, t.WaterReflectance, t.WaterWaveSize = waterSaved[1], waterSaved[2], waterSaved[3]
waterSaved = nil
end
end
function X.hideCore(coreType, v)
pcall(function() StarterGui:SetCoreGuiEnabled(coreType, not v) end)
end
local overlay = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 0 }, gui)
local vig = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 0 }, overlay)
local function edge(size, pos, anchorPt, rot)
local f = new("Frame", { Size = size, Position = pos, AnchorPoint = anchorPt, BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 0 }, vig)
new("UIGradient", { Rotation = rot, Transparency = NumberSequence.new(0.25, 1) }, f)
end
edge(UDim2.fromScale(0.25, 1), UDim2.fromScale(0, 0), Vector2.new(0, 0), 0)
edge(UDim2.fromScale(0.25, 1), UDim2.fromScale(1, 0), Vector2.new(1, 0), 180)
edge(UDim2.fromScale(1, 0.3), UDim2.fromScale(0, 0), Vector2.new(0, 0), 90)
edge(UDim2.fromScale(1, 0.3), UDim2.fromScale(0, 1), Vector2.new(0, 1), 270)
function X.setVignette(v) vig.Visible = v end
local barTop = new("Frame", { Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 0 }, overlay)
local barBot = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 0 }, overlay)
function X.setBars(v)
local h = v and 0.11 or 0
tween(barTop, { Size = UDim2.new(1, 0, h, 0) }, 0.4)
tween(barBot, { Size = UDim2.new(1, 0, h, 0) }, 0.4)
end
function X.say(msg)
if msg == "" then return end
local ok = pcall(function()
local channels = TextChatService:FindFirstChild("TextChannels")
local ch = channels and channels:FindFirstChild("RBXGeneral")
if not ch then error("no channel") end
ch:SendAsync(msg)
end)
if not ok then toast("Couldn't send chat message") end
end
end
do
S.flingPower = 5000
S.launchPower = 250
S.touchfling = false
X.flinging = false
function X.launch(up)
local root = getRoot()
if not root then return end
if up then
root.AssemblyLinearVelocity = Vector3.new(0, S.launchPower, 0)
else
root.AssemblyLinearVelocity = root.CFrame.LookVector * S.launchPower + Vector3.new(0, S.launchPower * 0.25, 0)
end
end
function X.flingPlayer(plr, queued)
if X.flinging then return end
local root = getRoot()
local tr = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
if not root or not tr then return toast("Can't reach that player") end
X.flinging = true
local home = root.CFrame
if not queued then X.flingAbort = false end
local t0 = os.clock()
toast("Flinging " .. plr.DisplayName)
local conn
conn = RunService.Heartbeat:Connect(function()
local r = getRoot()
local target = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
if not r or not target or X.flingAbort or os.clock() - t0 > 1.5 then
conn:Disconnect()
X.flinging = false
if r then
r.AssemblyLinearVelocity = Vector3.zero
r.AssemblyAngularVelocity = Vector3.zero
r.CFrame = home
end
return
end
r.CFrame = target.CFrame
r.AssemblyAngularVelocity = Vector3.new(0, S.flingPower, 0)
r.AssemblyLinearVelocity = Vector3.new(S.flingPower, S.flingPower, S.flingPower)
end)
end
function X.setTouchFling(v)
S.touchfling = v
if not v then return end
task.spawn(function()
while S.touchfling do
local root = getRoot()
if root then
local vel = root.AssemblyLinearVelocity
root.AssemblyLinearVelocity = Vector3.new(S.flingPower, S.flingPower, S.flingPower)
RunService.RenderStepped:Wait()
if root.Parent then root.AssemblyLinearVelocity = vel end
end
RunService.Heartbeat:Wait()
end
end)
end
end
do
S.looptp = false
S.loopSpeed = 2
S.tpHeight = 4
S.pickModel = false
X.objSrc = nil
X.objDst = nil
X.pickMode = nil
X.flingAbort = false
local hls = {}
function X.setHL(key, obj, color)
if hls[key] then hls[key]:Destroy() hls[key] = nil end
if obj and obj.Parent then
hls[key] = new("Highlight", { Name = "LockpickPick", FillColor = color, OutlineColor = color, FillTransparency = 0.7, OutlineTransparency = 0, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop }, obj)
end
end
local DST_COLOR = Color3.fromRGB(255, 170, 55)
function X.objLabels()
if not X.objLabel then return end
local srcName = (X.objSrc and X.objSrc.Parent) and X.objSrc.Name or "You"
local dstName = (X.objDst and X.objDst.Parent) and X.objDst.Name or "not picked"
X.objLabel.Text = "Source:  " .. srcName .. "\nDestination:  " .. dstName
end
function X.startPick(mode)
if X.pickMode == mode then
X.pickMode = nil
mouse.Icon = ""
return toast("Pick cancelled")
end
X.pickMode = mode
mouse.Icon = "rbxasset://SystemCursors/Cross"
toast("Click an object to set the " .. (mode == "src" and "source" or "destination"))
end
function X.handlePick(target)
local mode = X.pickMode
X.pickMode = nil
mouse.Icon = ""
if not target then return toast("Nothing there to pick") end
local obj = target
if S.pickModel then
local m = target:FindFirstAncestorOfClass("Model")
if m and m ~= workspace then obj = m end
end
if mode == "src" then
X.objSrc = obj
X.setHL("src", obj, accent)
elseif mode == "sel" then
X.exSelect(obj)
else
X.objDst = obj
X.setHL("dst", obj, DST_COLOR)
end
X.objLabels()
toast("Picked " .. obj.Name)
end
local function pivotOf(o) return o:IsA("Model") and o:GetPivot() or o.CFrame end
local function sizeOf(o) return o:IsA("Model") and o:GetExtentsSize() or o.Size end
function X.objectTeleport(silent)
local dst = X.objDst
if not dst or not dst.Parent then
if silent then
if S.looptp and T.looptp then T.looptp.set(false, true) end
toast("Loop teleport stopped: destination is gone")
else
toast("Pick a destination object first")
end
return
end
local srcObj = X.objSrc
if srcObj and not srcObj.Parent then
X.objSrc = nil
srcObj = nil
X.objLabels()
end
local dcf, dsz = pivotOf(dst), sizeOf(dst)
local pos = dcf.Position + Vector3.new(0, dsz.Y / 2 + S.tpHeight, 0)
if srcObj then
local scf = pivotOf(srcObj)
local newCf = CFrame.new(pos) * (scf - scf.Position)
if srcObj:IsA("Model") then
srcObj:PivotTo(newCf)
else
srcObj.CFrame = newCf
srcObj.AssemblyLinearVelocity = Vector3.zero
end
else
local root = getRoot()
if not root then return end
root.CFrame = CFrame.new(pos) * (root.CFrame - root.CFrame.Position)
root.AssemblyLinearVelocity = Vector3.zero
end
if not silent then toast("Teleported") end
end
function X.resetObjects()
X.objSrc, X.objDst, X.pickMode = nil, nil, nil
X.setHL("src", nil)
X.setHL("dst", nil)
mouse.Icon = ""
X.objLabels()
end
function X.flingAll()
if X.flinging or X.flingAllRunning then return end
local list = {}
for _, plr in ipairs(Players:GetPlayers()) do
if plr ~= player and X.rel[plr.UserId] ~= "friend" and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then table.insert(list, plr) end
end
if #list == 0 then return toast("No other players in this server") end
X.flingAbort = false
X.flingAllRunning = true
task.spawn(function()
for _, plr in ipairs(list) do
if X.flingAbort then break end
if plr.Parent and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
X.flingPlayer(plr, true)
while X.flinging do task.wait(0.1) end
task.wait(0.25)
end
end
X.flingAllRunning = false
end)
end
end
-- Teleport helpers
local function tpTo(plr)
local r = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
local me = getRoot()
if r and me then
X.go(me, r.CFrame * CFrame.new(0, 0, 4))
toast("Teleported to " .. plr.DisplayName)
else
toast("Can't reach that player")
end
end
local function spectate(plr)
local h = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
if h then
workspace.CurrentCamera.CameraSubject = h
X.viewTarget = plr
toast("Viewing " .. plr.DisplayName)
else
toast("Player has no character")
end
end
section(pPlayer, "Character")
slider(pPlayer, "WalkSpeed", 0, 250, DEFAULTS.WalkSpeed, function(v) S.walkSpeed = v applyStats() end)
slider(pPlayer, "JumpPower", 0, 300, DEFAULTS.JumpPower, function(v) S.jumpPower = v applyStats() end)
X.gravity = slider(pPlayer, "Gravity", 0, 400, DEFAULTS.Gravity, function(v) workspace.Gravity = v end, 1)
section(pPlayer, "Abilities")
T.fly = toggle(pPlayer, "Fly", "WASD + Space / LeftShift", function(v)
S.fly = v
local hum = getHum()
if hum then hum.PlatformStand = v end
end)
slider(pPlayer, "Fly Speed", 10, 300, S.flySpeed, function(v) S.flySpeed = v end)
T.noclip = toggle(pPlayer, "Noclip", "Walk through walls", function(v)
S.noclip = v
if not v then restoreNoclip() end
end)
T.infjump = toggle(pPlayer, "Infinite Jump", "Jump again in mid-air", function(v) S.infjump = v end)
T.spin = toggle(pPlayer, "Spin", "Rotate your character", function(v) S.spin = v end)
slider(pPlayer, "Spin Speed", 30, 1440, S.spinSpeed, function(v) S.spinSpeed = v end)
T.clicktp = toggle(pPlayer, "Click Teleport", "Hold Ctrl and click to teleport", function(v) S.clicktp = v end)
T.antiafk = toggle(pPlayer, "Anti-AFK", "Prevents idle kick", function(v) S.antiafk = v end)
T.sprint = toggle(pPlayer, "Sprint", "Hold LeftShift to run faster", function(v)
S.sprint = v
if not v then
local h = getHum()
if h then h.WalkSpeed = S.walkSpeed or DEFAULTS.WalkSpeed end
end
end)
slider(pPlayer, "Sprint Multiplier", 1, 5, S.sprintMult, function(v) S.sprintMult = v end, 1)
T.glide = toggle(pPlayer, "Slow Fall", "Caps your falling speed", function(v) S.glide = v end)
slider(pPlayer, "Max Fall Speed", 5, 100, S.glideSpeed, function(v) S.glideSpeed = v end)
T.airwalk = toggle(pPlayer, "Air Walk", "Space / LeftShift to rise or sink", X.setAirwalk)
T.dash = toggle(pPlayer, "Dash", "Press V to dash forward", function(v) S.dash = v end)
slider(pPlayer, "Dash Force", 30, 300, S.dashForce, function(v) S.dashForce = v end)
T.bhop = toggle(pPlayer, "Bunny Hop", "Hold Space to auto-jump", function(v) S.bhop = v end)
T.antivoid = toggle(pPlayer, "Anti-Void", "Return to safe ground if you fall", function(v) S.antivoid = v end)
T.freeze = toggle(pPlayer, "Freeze", "Lock your character in place", function(v)
S.freeze = v
local r = getRoot()
if r then r.Anchored = v end
end)
do
local hipDefault = (function() local h = getHum() return h and h.HipHeight or 2 end)()
slider(pPlayer, "Hip Height", 0, 30, math.floor(hipDefault * 10 + 0.5) / 10, function(v) local h = getHum() if h then h.HipHeight = v end end, 1)
end
section(pPlayer, "Actions")
buttonRow(pPlayer, {
{ "Sit", function() local h = getHum() if h then h.Sit = true end end },
{ "Jump", function() local h = getHum() if h then h.Jump = true end end },
})
buttonRow(pPlayer, {
{ "Teleport to Spawn", function()
local root = getRoot()
local sp = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
if root and sp then root.CFrame = sp.CFrame + Vector3.new(0, 5, 0) toast("Teleported to spawn") else toast("No spawn found") end
end },
{ "Reset Character", function() local h = getHum() if h then h.Health = 0 end end },
})
section(pTp, "Players")
local playerList = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = nextOrder(pTp) }, pTp)
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, playerList)
local function clearList(l)
for _, c in ipairs(l:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
l:SetAttribute("n", 0)
end
local refreshPlayers
buttonRow(pTp, {
{ "Nearest Player", function()
local root = getRoot()
if not root then return end
local best, bd
for _, plr in ipairs(Players:GetPlayers()) do
local r = plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
if r then
local d = (r.Position - root.Position).Magnitude
if not bd or d < bd then best, bd = plr, d end
end
end
if best then tpTo(best) else toast("No players found") end
end },
{ "Random Player", function()
local list = {}
for _, plr in ipairs(Players:GetPlayers()) do
if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then table.insert(list, plr) end
end
if #list > 0 then tpTo(list[math.random(#list)]) else toast("No players found") end
end },
})
button(pTp, "Stop Viewing", function()
local h = getHum()
if h then workspace.CurrentCamera.CameraSubject = h toast("Camera restored") end
end)
section(pTp, "Follow")
T.follow = toggle(pTp, "Follow Viewed Player", "Stay next to the player you last viewed", function(v)
S.follow = v
if v then
if not X.viewTarget then toast("Press View on a player first") end
if S.orbit then T.orbit.set(false, true) end
end
end)
T.orbit = toggle(pTp, "Orbit Viewed Player", "Circle around the player you last viewed", function(v)
S.orbit = v
if v then
if not X.viewTarget then toast("Press View on a player first") end
if S.follow then T.follow.set(false, true) end
end
end)
slider(pTp, "Follow / Orbit Distance", 3, 40, S.followDist, function(v) S.followDist = v end)
section(pTp, "Coordinates")
do
local posRow = row(pTp, 40)
X.posLabel = text(posRow, { Size = UDim2.new(1, -28, 1, 0), Position = UDim2.fromOffset(14, 0), Text = "Position:  --", Font = Enum.Font.GothamMedium, TextSize = 13 })
local coordRow = row(pTp, 44)
register(coordRow, "coordinates xyz position teleport go here")
local coordBox = new("TextBox", { Size = UDim2.new(1, -132, 0, 28), Position = UDim2.fromOffset(8, 8), BackgroundColor3 = C.elevated, Text = "", PlaceholderText = "x, y, z", PlaceholderColor3 = C.muted, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.text, ClearTextOnFocus = false, BorderSizePixel = 0 }, coordRow)
corner(coordBox, 8) stroke(coordBox, C.stroke, 1, 0.3)
local function goCoords()
local nums = {}
for n in string.gmatch(coordBox.Text, "-?%d+%.?%d*") do table.insert(nums, tonumber(n)) end
local root = getRoot()
if #nums >= 3 and root then
root.CFrame = CFrame.new(nums[1], nums[2], nums[3])
toast("Teleported to coordinates")
else
toast("Enter x, y, z")
end
end
miniButton(coordRow, "Go", 8, goCoords, true)
miniButton(coordRow, "Here", 64, function()
local root = getRoot()
if root then local p = root.Position coordBox.Text = string.format("%.1f, %.1f, %.1f", p.X, p.Y, p.Z) end
end)
coordBox.FocusLost:Connect(function(enter) if enter then goCoords() end end)
end
section(pTp, "Object Teleporter")
do
local f = row(pTp, 62)
register(f, "object teleporter source destination pick teleport loop")
X.objLabel = text(f, { Size = UDim2.new(1, -28, 1, -14), Position = UDim2.fromOffset(14, 8), Text = "", TextSize = 13, TextYAlignment = Enum.TextYAlignment.Top, Font = Enum.Font.GothamMedium })
X.objLabels()
table.insert(resetters, X.resetObjects)
end
buttonRow(pTp, {
{ "Pick Source", function() X.startPick("src") end },
{ "Pick Destination", function() X.startPick("dst") end, true },
})
buttonRow(pTp, {
{ "Source = Me", function()
X.objSrc = nil
X.setHL("src", nil)
X.objLabels()
toast("Source is you")
end },
{ "Teleport Now", function() X.objectTeleport(false) end, true },
})
T.pickmodel = toggle(pTp, "Pick Whole Model", "Picking a part selects its whole model", function(v) S.pickModel = v end)
T.looptp = toggle(pTp, "Loop Teleport", "Keeps teleporting the source to the destination", function(v)
S.looptp = v
X.loopAcc = 0
if v and not X.objDst then toast("Pick a destination object first") end
end)
slider(pTp, "Loop Speed (teleports / sec)", 0.2, 60, S.loopSpeed, function(v) S.loopSpeed = v end, 1)
slider(pTp, "Height Offset", -10, 40, S.tpHeight, function(v) S.tpHeight = v end, 1)
section(pTp, "Find Object")
do
local objRow = row(pTp, 44)
register(objRow, "go to object find part model name teleport")
local objBox = new("TextBox", { Size = UDim2.new(1, -78, 0, 28), Position = UDim2.fromOffset(8, 8), BackgroundColor3 = C.elevated, Text = "", PlaceholderText = "Part or model name...", PlaceholderColor3 = C.muted, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.text, ClearTextOnFocus = false, BorderSizePixel = 0 }, objRow)
corner(objBox, 8) stroke(objBox, C.stroke, 1, 0.3)
local function goObject()
local name = objBox.Text
if name == "" then return toast("Enter an object name") end
local found = workspace:FindFirstChild(name, true)
if not found then
local lname = string.lower(name)
for _, d in ipairs(workspace:GetDescendants()) do
if (d:IsA("BasePart") or d:IsA("Model")) and string.find(string.lower(d.Name), lname, 1, true) then
found = d
break
end
end
end
local root = getRoot()
if found and root and (found:IsA("BasePart") or found:IsA("Model")) then
local cf = found:IsA("Model") and found:GetPivot() or found.CFrame
root.CFrame = cf + Vector3.new(0, 6, 0)
toast("Teleported to " .. found.Name)
else
toast("Object not found")
end
end
miniButton(objRow, "Go", 8, goObject, true)
objBox.FocusLost:Connect(function(enter) if enter then goObject() end end)
end
section(pTp, "Waypoints")
button(pTp, "Save Current Position", function()
local root = getRoot()
if not root then return toast("No character") end
table.insert(WAYPOINTS, { name = "Waypoint " .. (#WAYPOINTS + 1), cf = root.CFrame })
REFRESH_WPS()
toast("Waypoint saved")
end, true)
local wpList = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = nextOrder(pTp) }, pTp)
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, wpList)
section(pVisual, "Render")
T.esp = toggle(pVisual, "Player ESP", "Highlights, names and distance", setESP)
T.tracers = toggle(pVisual, "Tracers", "Lines pointing to every player", function(v)
S.tracers = v
if not v then X.hideTracers() end
end)
T.xray = toggle(pVisual, "X-Ray", "See through world parts", setXray)
T.fullbright = toggle(pVisual, "Fullbright", "Remove darkness and shadows", setFullbright)
T.nofog = toggle(pVisual, "No Fog", "Clear distance fog and haze", setNoFog)
T.nofx = toggle(pVisual, "Disable Post-Processing", "Turns off bloom, blur, etc.", setNoFX)
T.hidefx = toggle(pVisual, "Hide Effects", "Particles, smoke, fire, beams, trails", X.setHideEffects)
section(pVisual, "Interface")
T.hidechat = toggle(pVisual, "Hide Chat", nil, function(v) X.hideCore(Enum.CoreGuiType.Chat, v) end)
T.hideplist = toggle(pVisual, "Hide Player List", nil, function(v) X.hideCore(Enum.CoreGuiType.PlayerList, v) end)
T.hidebackpack = toggle(pVisual, "Hide Backpack", nil, function(v) X.hideCore(Enum.CoreGuiType.Backpack, v) end)
T.hidehealth = toggle(pVisual, "Hide Health Bar", nil, function(v) X.hideCore(Enum.CoreGuiType.Health, v) end)
T.vignette = toggle(pVisual, "Vignette", "Darkened screen edges", X.setVignette)
T.bars = toggle(pVisual, "Cinematic Bars", "Letterbox black bars", X.setBars)
section(pVisual, "Camera & World")
slider(pVisual, "Field of View", 30, 120, DEFAULTS.FOV, function(v) S.fov = v workspace.CurrentCamera.FieldOfView = v end)
T.zoom = toggle(pVisual, "Zoom", "Hold C to zoom in", function(v)
S.zoom = v
if not v then workspace.CurrentCamera.FieldOfView = S.fov or DEFAULTS.FOV end
end)
slider(pVisual, "Zoom FOV", 5, 60, S.zoomFov, function(v) S.zoomFov = v end)
T.firstperson = toggle(pVisual, "Lock First Person", "Force first-person camera", function(v)
player.CameraMode = v and Enum.CameraMode.LockFirstPerson or Enum.CameraMode.Classic
end)
slider(pVisual, "Max Zoom Distance", 5, 1000, DEFAULTS.MaxZoom, function(v) player.CameraMaxZoomDistance = v end)
slider(pVisual, "Camera Height Offset", -5, 10, 0, function(v)
local h = getHum()
if h then h.CameraOffset = Vector3.new(0, v, 0) end
end, 1)
slider(pVisual, "Min Zoom Distance", 0, 50, math.clamp(math.floor(player.CameraMinZoomDistance), 0, 50), function(v) player.CameraMinZoomDistance = v end)
slider(pVisual, "Time of Day", 0, 24, DEFAULTS.ClockTime, function(v)
Lighting.ClockTime = v
if S.timeLock then S.timeLock = v end
end, 1)
T.timelock = toggle(pVisual, "Lock Time of Day", "Keeps the clock where it is", function(v) S.timeLock = v and Lighting.ClockTime or nil end)
T.timeflow = toggle(pVisual, "Time Flow", "Day / night cycle runs on its own", function(v) S.timeFlow = v end)
slider(pVisual, "Time Flow Speed", 0.1, 6, S.timeSpeed, function(v) S.timeSpeed = v end, 1)
section(pVisual, "Color Grading")
function X.getCC()
if not X.cc or not X.cc.Parent then X.cc = new("ColorCorrectionEffect", { Name = "LockpickCC" }, Lighting) end
return X.cc
end
do
local tintRow = row(pVisual, 56)
register(tintRow, "color tint screen filter")
text(tintRow, { Size = UDim2.new(1, -28, 0, 16), Position = UDim2.fromOffset(14, 5), Text = "Color Tint", Font = Enum.Font.GothamMedium, TextSize = 13 })
local tints = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 120, 120), Color3.fromRGB(255, 180, 100), Color3.fromRGB(255, 235, 120), Color3.fromRGB(130, 235, 150), Color3.fromRGB(120, 230, 240), Color3.fromRGB(130, 160, 255), Color3.fromRGB(190, 140, 255), Color3.fromRGB(255, 140, 200) }
for i, col in ipairs(tints) do
local b = new("TextButton", { Size = UDim2.fromOffset(24, 24), Position = UDim2.fromOffset(14 + (i - 1) * 32, 26), BackgroundColor3 = col, Text = "", AutoButtonColor = false }, tintRow)
corner(b, 12)
b.MouseButton1Click:Connect(function() X.getCC().TintColor = col end)
end
table.insert(resetters, function() if X.cc then X.cc.TintColor = Color3.new(1, 1, 1) end end)
end
slider(pVisual, "Saturation", -1, 2, 0, function(v) X.getCC().Saturation = v end, 2)
slider(pVisual, "Contrast", -1, 1, 0, function(v) X.getCC().Contrast = v end, 2)
slider(pVisual, "Blur", 0, 56, 0, function(v) X.getBlur().Size = v end)
slider(pVisual, "Exposure", -3, 3, math.clamp(math.floor(Lighting.ExposureCompensation * 10 + 0.5) / 10, -3, 3), function(v) Lighting.ExposureCompensation = v end, 1)
section(pWorld, "Gravity Presets")
buttonRow(pWorld, {
{ "Moon", function() X.gravity.set(32.7) end },
{ "Low", function() X.gravity.set(98) end },
{ "Normal", function() X.gravity.set(DEFAULTS.Gravity) end },
{ "Heavy", function() X.gravity.set(392) end },
})
section(pWorld, "Lighting")
slider(pWorld, "Brightness", 0, 10, math.clamp(math.floor(Lighting.Brightness * 10 + 0.5) / 10, 0, 10), function(v) Lighting.Brightness = v end, 1)
local origShadows = Lighting.GlobalShadows
T.noshadows = toggle(pWorld, "Disable Shadows", "Flat lighting and better performance", function(v) Lighting.GlobalShadows = (not v) and origShadows or false end)
T.noclouds = toggle(pWorld, "Hide Clouds", "Turn off terrain clouds", function(v)
local c = workspace.Terrain:FindFirstChildOfClass("Clouds")
if c then c.Enabled = not v end
end)
T.clearwater = toggle(pWorld, "Clear Water", "See through terrain water", X.setClearWater)
section(pWorld, "Materials & Textures")
T.plain = toggle(pWorld, "Plain Materials", "Smooth plastic on every world part", X.setPlainMaterials)
T.notex = toggle(pWorld, "Remove Decals & Textures", "Hide decals and textures", X.setNoTextures)
section(pWorld, "Builder (local only)")
buttonRow(pWorld, {
{ "Spawn Block", X.spawnBlock, true },
{ "Clear Blocks", function() X.clearBlocks() toast("Blocks cleared") end },
})
section(pFun, "Auras & Effects")
T.fire = toggle(pFun, "Fire Aura", "Flames around your character", function(v) S.aura_fire = v end)
T.sparkles = toggle(pFun, "Sparkles", "Sparkles on your character", function(v) S.aura_sparkles = v end)
T.smoke = toggle(pFun, "Smoke", "Smoke from your character", function(v) S.aura_smoke = v end)
T.trail = toggle(pFun, "Light Trail", "Glowing trail that follows your theme", function(v) S.trail = v end)
T.selfglow = toggle(pFun, "Self Glow", "Outline glow on your character", function(v) S.selfglow = v end)
section(pFun, "Character Look (client-side)")
T.rainbowchar = toggle(pFun, "Rainbow Character", "Cycle your body colors", function(v)
S.rainbowchar = v
if not v then X.bodyFeature("rainbow", false) end
end)
T.neon = toggle(pFun, "Neon Character", "Neon material on every body part", function(v)
S.neon = v
X.bodyFeature("neon", v)
end)
section(pFun, "Movement Fun")
T.autowalk = toggle(pFun, "Auto Walk", "Walk forward on your own", function(v) S.autowalk = v end)
T.autojump = toggle(pFun, "Auto Jump", "Jump constantly", function(v) S.autojump = v end)
T.facemouse = toggle(pFun, "Face Cursor", "Your character looks at your mouse", function(v) S.facemouse = v end)
T.clickwalk = toggle(pFun, "Click Walk", "Hold LeftShift and click to walk there", function(v) S.clickwalk = v end)
section(pFun, "Fling")
T.touchfling = toggle(pFun, "Touch Fling", "Players you bump into get launched", X.setTouchFling)
slider(pFun, "Fling Power", 500, 20000, S.flingPower, function(v) S.flingPower = v end)
slider(pFun, "Launch Power", 50, 1000, S.launchPower, function(v) S.launchPower = v end)
buttonRow(pFun, {
{ "Launch Forward", function() X.launch(false) end, true },
{ "Launch Up", function() X.launch(true) end },
})
do
end
buttonRow(pFun, {
{ "Fling All Players", function() X.flingAll() end, true },
{ "Stop Flinging", function() X.flingAbort = true toast("Fling stopped") end },
})
section(pTools, "Camera")
T.freecam = toggle(pTools, "Freecam", "WASD + E/Q, hold right mouse to look", X.setFreecam)
slider(pTools, "Freecam Speed", 10, 300, S.freecamSpeed, function(v) S.freecamSpeed = v end)
T.crosshair = toggle(pTools, "Crosshair", "Dot in the center of the screen", function(v) X.xhShow(v) end)
slider(pTools, "Crosshair Size", 2, 30, 8, function(v) X.xhSize(v) end)
section(pTools, "World Editing")
T.clickdelete = toggle(pTools, "Click Delete", "Hold Alt and click a part to hide it", function(v) S.clickdelete = v end)
buttonRow(pTools, {
{ "Undo Delete", X.undoDelete },
{ "Restore All", function() X.restoreAll() toast("All parts restored") end },
})
section(pTools, "Inspect")
T.inspect = toggle(pTools, "Part Inspector", "Hover a part to see its info", X.setInspect)
section(pTools, "Utilities")
button(pTools, "Teleport to Camera", function()
local root = getRoot()
if root then
root.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position)
toast("Teleported to camera")
end
end)
do
local f = row(pTools, 44)
register(f, "chat say send message talk")
local box = new("TextBox", { Size = UDim2.new(1, -78, 0, 28), Position = UDim2.fromOffset(8, 8), BackgroundColor3 = C.elevated, Text = "", PlaceholderText = "Say something in chat...", PlaceholderColor3 = C.muted, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.text, ClearTextOnFocus = false, BorderSizePixel = 0 }, f)
corner(box, 8) stroke(box, C.stroke, 1, 0.3)
local function send() X.say(box.Text) box.Text = "" end
miniButton(f, "Send", 8, send, true)
box.FocusLost:Connect(function(enter) if enter then send() end end)
end
do
end
do
local favCount = 0
searchIndex.favPage = pFav
local hint = row(pFav, 40, 0)
text(hint, { Size = UDim2.new(1, -24, 1, 0), Position = UDim2.fromOffset(12, 0), Text = "Right-click any toggle, slider or button to pin it here.", TextSize = 13, TextColor3 = C.muted })
searchIndex.toggleFav = function(e)
e.fav = not e.fav
if e.fav then
favCount += 1
e.favOrder = favCount
e.f.Parent = pFav
e.f.LayoutOrder = favCount
else
e.f.Parent = e.parent
e.f.LayoutOrder = e.order
end
toast(e.fav and "Pinned to Favorites" or "Removed from Favorites")
end
end
do
function X.fb(page, name, desc, key, sname, min, max, skey, def, dec, extra)
flags(page, { { name, desc, key, extra } })
if sname then binds(page, { { sname, min, max, skey, def, dec } }) end
end
local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Exclude
local wp = RaycastParams.new()
wp.FilterType = Enum.RaycastFilterType.Exclude
wp.IgnoreWater = false
X.fuel = 100
local airJumps, slideT, slideDir, chute, canopy, waterPlat, hookPart, hookPt, lastBlink = 0, 0, Vector3.zero, false, nil, nil, nil, nil, 0
local fuelFrame = new("Frame", { Size = UDim2.fromOffset(180, 8), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -110), BackgroundColor3 = C.surface, BorderSizePixel = 0, Visible = false, ZIndex = 0 }, gui)
corner(fuelFrame, 4)
local fuelBar = new("Frame", { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0 }, fuelFrame)
corner(fuelBar, 4)
onAccent(function(c) fuelBar.BackgroundColor3 = c end)
local function grounded(h) return h.FloorMaterial ~= Enum.Material.Air end
local function jumpVel(h) if h.UseJumpPower then return h.JumpPower end return math.sqrt(2 * workspace.Gravity * h.JumpHeight) end
connect(UIS.JumpRequest, function()
local h, r = getHum(), getRoot()
if not h or not r then return end
if S.djump and not grounded(h) and airJumps < S.djumpCount then
airJumps += 1
local v = r.AssemblyLinearVelocity
r.AssemblyLinearVelocity = Vector3.new(v.X, jumpVel(h), v.Z)
elseif S.longjump and grounded(h) then
r.AssemblyLinearVelocity += r.CFrame.LookVector * S.longJumpBoost
end
end)
table.insert(X.steps, function(dt)
local h, r = getHum(), getRoot()
if not h or not r then return end
if S.fly or S.freecam then return end
local gr = grounded(h)
if gr then airJumps = 0 end
local cam = workspace.CurrentCamera
local vel = r.AssemblyLinearVelocity
local st = h:GetState()
rp.FilterDescendantsInstances = { getChar() }
local fwd = UIS:IsKeyDown(Enum.KeyCode.W) or h.MoveDirection.Magnitude > 0
if S.wallclimb and fwd and workspace:Raycast(r.Position, r.CFrame.LookVector * 3, rp) then
r.AssemblyLinearVelocity = Vector3.new(0, S.climbSpeed, 0)
end
if S.fastclimb and st == Enum.HumanoidStateType.Climbing then
local up = (UIS:IsKeyDown(Enum.KeyCode.W) and 1 or 0) - (UIS:IsKeyDown(Enum.KeyCode.S) and 1 or 0)
if up ~= 0 then r.AssemblyLinearVelocity = Vector3.new(vel.X, up * S.fclimbSpeed, vel.Z) end
end
if S.swimfast and st == Enum.HumanoidStateType.Swimming then
local y = (UIS:IsKeyDown(Enum.KeyCode.Space) and 1 or 0) - (UIS:IsKeyDown(Enum.KeyCode.LeftShift) and 1 or 0)
local d = h.MoveDirection * S.swimSpeed + Vector3.new(0, y * S.swimSpeed, 0)
if d.Magnitude > 0 then r.AssemblyLinearVelocity = d end
end
if S.hover then
local y = (UIS:IsKeyDown(Enum.KeyCode.Space) and 1 or 0) - (UIS:IsKeyDown(Enum.KeyCode.LeftControl) and 1 or 0)
local v = r.AssemblyLinearVelocity
r.AssemblyLinearVelocity = Vector3.new(v.X, y * S.hoverSpeed, v.Z)
end
fuelFrame.Visible = S.jetpack
if S.jetpack then
local on = UIS:IsKeyDown(Enum.KeyCode.Space) and not UIS:GetFocusedTextBox() and X.fuel > 0 and not gr
if on then
local v = r.AssemblyLinearVelocity
r.AssemblyLinearVelocity = Vector3.new(v.X, v.Y + (S.jetPower - v.Y) * math.min(1, dt * 8), v.Z)
X.fuel -= 30 * dt
else
X.fuel = math.min(100, X.fuel + (gr and 45 or 6) * dt)
end
fuelBar.Size = UDim2.new(math.clamp(X.fuel / 100, 0, 1), 0, 1, 0)
end
local v2 = r.AssemblyLinearVelocity
if S.glider and not gr and UIS:IsKeyDown(Enum.KeyCode.Space) and v2.Y < 0 and not S.jetpack then
local l = cam.CFrame.LookVector
local flat = Vector3.new(l.X, 0, l.Z)
flat = flat.Magnitude > 0 and flat.Unit or Vector3.zero
r.AssemblyLinearVelocity = flat * S.gliderSpeed + Vector3.new(0, -12, 0)
end
if S.parachute and not gr and (chute or v2.Y < -45) then
chute = true
if not canopy then
canopy = new("Part", { Name = "LockpickCanopy", Shape = Enum.PartType.Ball, Size = Vector3.new(9, 4, 9), Material = Enum.Material.Neon, Color = accent, Transparency = 0.35, CanCollide = false, CanQuery = false, Massless = true }, getChar())
canopy.CFrame = r.CFrame * CFrame.new(0, 6, 0)
new("WeldConstraint", { Part0 = r, Part1 = canopy }, canopy)
end
local v = r.AssemblyLinearVelocity
if v.Y < -16 then r.AssemblyLinearVelocity = Vector3.new(v.X, -16, v.Z) end
elseif canopy then
canopy:Destroy()
canopy, chute = nil, false
end
if slideT > 0 then
slideT -= dt
local k = math.max(slideT / 0.9, 0)
local v = r.AssemblyLinearVelocity
r.AssemblyLinearVelocity = Vector3.new(slideDir.X * S.slideSpeed * k, v.Y, slideDir.Z * S.slideSpeed * k)
end
if S.waterwalk then
wp.FilterDescendantsInstances = { getChar() }
local hit = workspace:Raycast(r.Position + Vector3.new(0, 2, 0), Vector3.new(0, -14, 0), wp)
if hit and hit.Material == Enum.Material.Water then
if not waterPlat then waterPlat = new("Part", { Name = "LockpickWater", Size = Vector3.new(10, 1, 10), Anchored = true, Transparency = 1, CanQuery = false }, workspace) end
waterPlat.CFrame = CFrame.new(r.Position.X, hit.Position.Y - 0.5, r.Position.Z)
elseif waterPlat then waterPlat:Destroy() waterPlat = nil end
elseif waterPlat then
waterPlat:Destroy()
waterPlat = nil
end
if hookPt then
local d = hookPt - r.Position
if d.Magnitude < 5 then X.hookStop() else r.AssemblyLinearVelocity = d.Unit * S.hookSpeed end
end
end)
function X.hookStart()
if not S.grapple or hookPt then return end
local cam = workspace.CurrentCamera
local loc = UIS:GetMouseLocation()
local ray = cam:ViewportPointToRay(loc.X, loc.Y)
rp.FilterDescendantsInstances = { getChar() }
local hit = workspace:Raycast(ray.Origin, ray.Direction * S.hookRange, rp)
local r = getRoot()
if not hit or not r then return toast("Nothing in range") end
hookPt = hit.Position
hookPart = new("Part", { Name = "LockpickHook", Size = Vector3.new(0.4, 0.4, 0.4), Anchored = true, CanCollide = false, CanQuery = false, Transparency = 1, Position = hookPt }, workspace)
local a1 = new("Attachment", {}, hookPart)
local a0 = new("Attachment", { Name = "LockpickHookA" }, r)
new("Beam", { Attachment0 = a0, Attachment1 = a1, Width0 = 0.15, Width1 = 0.15, FaceCamera = true, LightEmission = 1, Color = ColorSequence.new(accent) }, hookPart)
end
function X.hookStop()
if hookPart then hookPart:Destroy() end
hookPart, hookPt = nil, nil
local r = getRoot()
local a = r and r:FindFirstChild("LockpickHookA")
if a then a:Destroy() end
end
function X.slideStart()
local h, r = getHum(), getRoot()
if not S.slide or not h or not r or not grounded(h) then return end
local md = h.MoveDirection
slideDir = md.Magnitude > 0 and md.Unit or Vector3.new(r.CFrame.LookVector.X, 0, r.CFrame.LookVector.Z).Unit
slideT = 0.9
end
function X.blink()
local r = getRoot()
if not S.blink or not r then return end
local now = os.clock()
if now - lastBlink < S.blinkCd then return toast(string.format("Blink ready in %.1fs", S.blinkCd - (now - lastBlink))) end
lastBlink = now
local l = r.CFrame.LookVector
local dir = Vector3.new(l.X, 0, l.Z)
dir = dir.Magnitude > 0 and dir.Unit or l
rp.FilterDescendantsInstances = { getChar() }
local hit = workspace:Raycast(r.Position, dir * S.blinkDist, rp)
r.CFrame += dir * (hit and math.max(hit.Distance - 2.5, 0) or S.blinkDist)
end
function X.rocket()
local r = getRoot()
if not S.rocketKey or not r then return end
r.AssemblyLinearVelocity = Vector3.new(0, S.rocketPower, 0) + r.CFrame.LookVector * S.rocketPower * 0.3
local fx = new("Fire", { Name = "LockpickRocketFx", Heat = 20, Size = 12, Color = Color3.fromRGB(255, 170, 40), SecondaryColor = Color3.fromRGB(255, 60, 20) }, r)
task.delay(1.5, function() if fx.Parent then fx:Destroy() end end)
end
X.keys[Enum.KeyCode.G] = X.hookStart
X.keys[Enum.KeyCode.Z] = X.slideStart
X.keys[Enum.KeyCode.B] = X.blink
X.keys[Enum.KeyCode.R] = X.rocket
connect(UIS.InputEnded, function(i) if i.KeyCode == Enum.KeyCode.G then X.hookStop() end end)
table.insert(X.cleanups, function()
X.hookStop()
if canopy then canopy:Destroy() end
if waterPlat then waterPlat:Destroy() end
end)
local fb = X.fb
section(pMove, "Jumping")
fb(pMove, "Double Jump", "Extra jumps in mid-air", "djump", "Extra Jumps", 1, 5, "djumpCount", 1)
fb(pMove, "Long Jump", "Forward boost when you jump", "longjump", "Long Jump Boost", 10, 150, "longJumpBoost", 60)
section(pMove, "Climbing & Swimming")
fb(pMove, "Wall Climb", "Hold W against a wall to climb it", "wallclimb", "Wall Climb Speed", 10, 120, "climbSpeed", 35)
fb(pMove, "Fast Climb", "Faster ladders and trusses (W / S)", "fastclimb", "Ladder Speed", 10, 120, "fclimbSpeed", 45)
fb(pMove, "Fast Swim", "Quick swimming (Space / Shift)", "swimfast", "Swim Speed", 10, 150, "swimSpeed", 60)
fb(pMove, "Walk on Water", "Stand on terrain water", "waterwalk")
section(pMove, "Flight Variants")
fb(pMove, "Hover", "Float in place (Space up / LeftCtrl down)", "hover", "Hover Speed", 5, 120, "hoverSpeed", 35)
fb(pMove, "Jetpack", "Hold Space in the air, fuel bar", "jetpack", "Jetpack Power", 20, 200, "jetPower", 70)
fb(pMove, "Glider", "Hold Space while falling to glide", "glider", "Glide Speed", 20, 150, "gliderSpeed", 60)
fb(pMove, "Parachute", "Opens when you fall fast", "parachute")
section(pMove, "Skills (hotkeys)")
fb(pMove, "Grappling Hook", "Hold G to pull toward your cursor", "grapple", "Hook Speed", 30, 250, "hookSpeed", 90, nil, function(v) if not v then X.hookStop() end end)
binds(pMove, { { "Hook Range", 50, 800, "hookRange", 300 } })
fb(pMove, "Slide", "Press Z to slide forward", "slide", "Slide Speed", 20, 200, "slideSpeed", 70)
fb(pMove, "Blink", "Press B to teleport forward", "blink", "Blink Distance", 10, 150, "blinkDist", 40)
binds(pMove, { { "Blink Cooldown (s)", 0, 10, "blinkCd", 2, 1 } })
fb(pMove, "Rocket Boost", "Press R to rocket upward", "rocketKey", "Rocket Power", 40, 400, "rocketPower", 140)
end
do
local sn = { "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine" }
for n = 1, 9 do
X.keys[Enum.KeyCode[sn[n]]] = function()
if not S.wpkeys then return end
local w = WAYPOINTS[n]
local r = getRoot()
if w and r then r.CFrame = w.cf toast("Waypoint " .. n .. ": " .. w.name) end
end
end
X.history = {}
local prevCF, lastRec = nil, 0
table.insert(X.steps, function()
local r = getRoot()
if not r then prevCF = nil return end
local cf = r.CFrame
if prevCF and (cf.Position - prevCF.Position).Magnitude > 40 and os.clock() - lastRec > 0.4 and not X.flinging then
lastRec = os.clock()
table.insert(X.history, prevCF)
if #X.history > 25 then table.remove(X.history, 1) end
end
prevCF = cf
end)
function X.tpBack()
local r = getRoot()
local cf = table.remove(X.history)
if not r or not cf then return toast("No teleport to undo") end
r.CFrame = cf
prevCF = nil
toast("Went back")
end
local patrolIdx, patrolAcc = 0, 0
table.insert(X.steps, function(dt)
if not S.patrol or #WAYPOINTS == 0 then return end
patrolAcc += dt
if patrolAcc >= S.patrolDelay then
patrolAcc = 0
patrolIdx = patrolIdx % #WAYPOINTS + 1
local r = getRoot()
if r then r.CFrame = WAYPOINTS[patrolIdx].cf end
end
end)
local function nearest(test)
local r = getRoot()
if not r then return end
local best, bd
for _, d in ipairs(workspace:GetDescendants()) do
if test(d) then
local p = d:IsA("BasePart") and d or d:FindFirstAncestorWhichIsA("BasePart")
if p then
local dist = (p.Position - r.Position).Magnitude
if not bd or dist < bd then best, bd = p, dist end
end
end
end
return best
end
function X.tpNearest(kind)
local r = getRoot()
local p = nearest(function(d)
if kind == "seat" then return d:IsA("Seat") or d:IsA("VehicleSeat") end
if kind == "prompt" then return d:IsA("ProximityPrompt") end
return d:IsA("ClickDetector")
end)
if p and r then r.CFrame = p.CFrame + Vector3.new(0, p.Size.Y / 2 + 3, 0) toast("Teleported to nearest " .. kind) else toast("None found") end
end
function X.tpExtreme(high)
local best, bv
for _, d in ipairs(workspace:GetDescendants()) do
if d:IsA("BasePart") and not d:IsA("Terrain") and not isCharPart(d) and d.CanCollide then
local y = high and (d.Position.Y + d.Size.Y / 2) or (d.Position.Y - d.Size.Y / 2)
if high or y > workspace.FallenPartsDestroyHeight + 5 then
if not bv or (high and y > bv) or (not high and y < bv) then best, bv = d, y end
end
end
end
local r = getRoot()
if best and r then r.CFrame = CFrame.new(best.Position.X, bv + 4, best.Position.Z) toast(high and "Teleported to the highest point" or "Teleported to the lowest point") else toast("Nothing found") end
end
function X.cycleView(dir)
local list = {}
for _, p in ipairs(Players:GetPlayers()) do if p ~= player then table.insert(list, p) end end
if #list == 0 then return toast("No other players") end
local idx = table.find(list, X.viewTarget) or 0
spectate(list[(idx - 1 + dir) % #list + 1])
end
X.keys[Enum.KeyCode.LeftBracket] = function() X.cycleView(-1) end
X.keys[Enum.KeyCode.RightBracket] = function() X.cycleView(1) end
function REFRESH_WPS()
clearList(wpList)
if #WAYPOINTS == 0 then
local r = row(wpList, 38, 1)
text(r, { Size = UDim2.new(1, -28, 1, 0), Position = UDim2.fromOffset(14, 0), Text = "No waypoints saved yet", TextColor3 = C.muted, TextSize = 13 })
return
end
for i, w in ipairs(WAYPOINTS) do
local r = row(wpList, 42, i)
text(r, { Size = UDim2.fromOffset(18, 42), Position = UDim2.fromOffset(8, 0), Text = tostring(i), TextSize = 12, TextColor3 = C.muted })
local nb = inbox(r, "name", UDim2.new(1, -226, 0, 26), UDim2.fromOffset(28, 8))
nb.Text = w.name
nb.FocusLost:Connect(function() if nb.Text ~= "" then w.name = nb.Text else nb.Text = w.name end end)
miniButton(r, "TP", 12, function() local root = getRoot() if root then root.CFrame = w.cf toast("Teleported to " .. w.name) end end, true)
miniButton(r, "Del", 68, function() table.remove(WAYPOINTS, i) REFRESH_WPS() end)
local function arrow(txt, off, d)
local b = makeButton(r, txt, function()
local j = i + d
if WAYPOINTS[j] then WAYPOINTS[i], WAYPOINTS[j] = WAYPOINTS[j], WAYPOINTS[i] REFRESH_WPS() end
end, false, UDim2.fromOffset(28, 26), 0)
b.AnchorPoint = Vector2.new(1, 0.5)
b.Position = UDim2.new(1, -off, 0.5, 0)
b.TextSize = 12
end
arrow("^", 124, -1)
arrow("v", 158, 1)
end
end
X.route = {}
local recAcc, repT = 0, 0
table.insert(X.steps, function(dt)
local r = getRoot()
if not r then return end
if S.recording then
recAcc += dt
if recAcc >= 0.1 then
recAcc = 0
table.insert(X.route, r.CFrame)
if X.routeLabel then X.routeLabel.Text = string.format("Route:  %d points  (%.1fs)", #X.route, #X.route * 0.1) end
end
elseif S.replay and #X.route > 1 then
repT += dt * S.replaySpeed * 10
local i = math.floor(repT) + 1
if i >= #X.route then
repT = 0
if not S.replayLoop then if T.replay then T.replay.set(false, true) end return end
i = 1
end
r.CFrame = X.route[i]:Lerp(X.route[math.min(i + 1, #X.route)], repT - math.floor(repT))
r.AssemblyLinearVelocity = Vector3.zero
end
end)
S.stick, S.stickDist, X.stickMode = false, 3, 1
table.insert(X.steps, function()
if not S.stick then return end
local t = X.stickTarget
local tr = t and t.Character and t.Character:FindFirstChild("HumanoidRootPart")
local r = getRoot()
if not tr or not r then return end
local off = X.stickMode == 1 and CFrame.new(0, 0, S.stickDist) or X.stickMode == 2 and CFrame.new(0, S.stickDist + 2, 0) or CFrame.new()
r.CFrame = tr.CFrame * off
r.AssemblyLinearVelocity = tr.AssemblyLinearVelocity
end)
function X.stickTo(plr)
X.stickTarget = plr
if T.stick and not S.stick then T.stick.set(true) end
toast("Stuck to " .. plr.DisplayName)
end
section(pTp, "Quick Teleports")
buttonRow(pTp, { { "Back", X.tpBack, true }, { "Highest Point", function() X.tpExtreme(true) end }, { "Lowest Point", function() X.tpExtreme(false) end } })
buttonRow(pTp, { { "Near Seat", function() X.tpNearest("seat") end }, { "Near Prompt", function() X.tpNearest("prompt") end }, { "Near Click", function() X.tpNearest("click") end } })
buttonRow(pTp, { { "Prev Player", function() X.cycleView(-1) end }, { "Next Player", function() X.cycleView(1) end } })
section(pTp, "Stick to Player")
flags(pTp, { { "Stick to Player", "Glue yourself to a player", "stick", function(v) if v and not X.stickTarget then toast("Press Stick next to a player first") end end } })
binds(pTp, { { "Stick Distance", 0, 20, "stickDist", 3, 1 } })
buttonRow(pTp, { { "Behind", function() X.stickMode = 1 end }, { "Above", function() X.stickMode = 2 end }, { "Inside", function() X.stickMode = 3 end } })
section(pTp, "Waypoint Tools")
flags(pTp, { { "Waypoint Hotkeys", "Keys 1-9 teleport to waypoints", "wpkeys" }, { "Auto Patrol", "Cycle through your waypoints", "patrol" } })
binds(pTp, { { "Patrol Delay (s)", 0.5, 30, "patrolDelay", 3, 1 } })
section(pTp, "Route Recorder")
X.routeLabel = lrow(pTp, 36, "route recorder record replay path")
X.routeLabel.Text = "Route:  empty"
flags(pTp, { { "Record Route", "Records where you walk", "recording", function(v) if v then X.route = {} if S.replay and T.replay then T.replay.set(false, true) end end end }, { "Replay Route", "Plays the recorded path back", "replay", function(v) repT = 0 if v and S.recording and T.recording then T.recording.set(false, true) end end }, { "Loop Replay", "Repeat the route forever", "replayLoop" } })
binds(pTp, { { "Replay Speed", 0.2, 5, "replaySpeed", 1, 1 } })
section(pTp, "Spawn Points")
local spawnList = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = nextOrder(pTp) }, pTp)
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, spawnList)
local function refreshSpawns()
clearList(spawnList)
local n = 0
for _, d in ipairs(workspace:GetDescendants()) do
if d:IsA("SpawnLocation") then
n += 1
local r = row(spawnList, 38, n)
text(r, { Size = UDim2.new(1, -90, 1, 0), Position = UDim2.fromOffset(12, 0), Text = d.Name, TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd })
miniButton(r, "TP", 12, function() local root = getRoot() if root then root.CFrame = d.CFrame + Vector3.new(0, 5, 0) toast("Teleported to " .. d.Name) end end, true)
end
end
if n == 0 then
local r = row(spawnList, 36, 1)
text(r, { Size = UDim2.new(1, -24, 1, 0), Position = UDim2.fromOffset(12, 0), Text = "No spawn points found", TextColor3 = C.muted, TextSize = 13 })
end
end
button(pTp, "Refresh Spawn List", refreshSpawns)
refreshSpawns()
end
do
local R15 = { { "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" }, { "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" }, { "LeftLowerArm", "LeftHand" }, { "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" }, { "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" }, { "LeftLowerLeg", "LeftFoot" }, { "LowerTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" } }
local R6 = { { "Head", "Torso" }, { "Torso", "Left Arm" }, { "Torso", "Right Arm" }, { "Torso", "Left Leg" }, { "Torso", "Right Leg" } }
local function teamCol(p) return p.Team and p.TeamColor.Color or Color3.new(1, 1, 1) end
local function allowed(p)
if p == player then return false end
if p.Team and X.teamOff and X.teamOff[p.Team] then return false end
if S.espHideTeam and player.Team and p.Team == player.Team then return false end
if S.espTeamOnly and (not player.Team or p.Team ~= player.Team) then return false end
return true
end
X.espAllowed = allowed
function X.findPlayer(q)
q = string.lower(q or "")
if q == "" then return end
for _, p in ipairs(Players:GetPlayers()) do
if p ~= player and (string.find(string.lower(p.Name), q, 1, true) or string.find(string.lower(p.DisplayName), q, 1, true)) then return p end
end
end
local layer = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 0 }, gui)
local pool, used, arrows, dots = {}, 0, {}, {}
local function line(a, b, col)
used += 1
local l = pool[used]
if not l then l = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0 }, layer) pool[used] = l end
local d = b - a
l.Visible = true
l.Size = UDim2.fromOffset(d.Magnitude, 1.5)
l.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
l.Rotation = math.deg(math.atan2(d.Y, d.X))
l.BackgroundColor3 = col
end
local radar = new("Frame", { Size = UDim2.fromOffset(150, 150), AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 16, 1, -16), BackgroundColor3 = C.bg, BackgroundTransparency = 0.3, BorderSizePixel = 0, Visible = false, ZIndex = 0 }, gui)
new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, radar)
local rs = stroke(radar, accent, 1.5, 0.2)
onAccent(function(c) rs.Color = c end)
new("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.fromScale(0, 0.5), BackgroundColor3 = C.stroke, BorderSizePixel = 0 }, radar)
new("Frame", { Size = UDim2.new(0, 1, 1, 0), Position = UDim2.fromScale(0.5, 0), BackgroundColor3 = C.stroke, BorderSizePixel = 0 }, radar)
local me = new("Frame", { Size = UDim2.fromOffset(6, 6), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BorderSizePixel = 0 }, radar)
new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, me)
onAccent(function(c) me.BackgroundColor3 = c end)
table.insert(X.steps, function()
local cam = workspace.CurrentCamera
local mine = getRoot()
used = 0
local ai, di = 0, 0
radar.Visible = S.radar
if S.skeleton or S.lookdir or S.arrows or S.radar then
local cf = cam.CFrame
local center = cam.ViewportSize / 2
local fwd = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
fwd = fwd.Magnitude > 0.001 and fwd.Unit or Vector3.new(0, 0, -1)
local right = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z)
right = right.Magnitude > 0.001 and right.Unit or Vector3.new(1, 0, 0)
for _, plr in ipairs(Players:GetPlayers()) do
local c = allowed(plr) and plr.Character
local root = c and c:FindFirstChild("HumanoidRootPart")
if root then
local col = plr.Team and plr.TeamColor.Color or accent
if S.skeleton then
for _, pr in ipairs(c:FindFirstChild("UpperTorso") and R15 or R6) do
local pa, pb = c:FindFirstChild(pr[1]), c:FindFirstChild(pr[2])
if pa and pb then
local va, vb = cam:WorldToViewportPoint(pa.Position), cam:WorldToViewportPoint(pb.Position)
if va.Z > 0 and vb.Z > 0 then line(Vector2.new(va.X, va.Y), Vector2.new(vb.X, vb.Y), col) end
end
end
end
if S.lookdir then
local head = c:FindFirstChild("Head")
if head then
local va, vb = cam:WorldToViewportPoint(head.Position), cam:WorldToViewportPoint(head.Position + head.CFrame.LookVector * 7)
if va.Z > 0 and vb.Z > 0 then line(Vector2.new(va.X, va.Y), Vector2.new(vb.X, vb.Y), Color3.fromRGB(255, 220, 90)) end
end
end
local pos = root.Position
if S.arrows then
local v = cam:WorldToViewportPoint(pos)
local onScr = v.Z > 0 and v.X > 0 and v.Y > 0 and v.X < cam.ViewportSize.X and v.Y < cam.ViewportSize.Y
if not onScr then
ai += 1
local rel = cf:PointToObjectSpace(pos)
local dir = Vector2.new(rel.X, -rel.Y)
dir = dir.Magnitude > 0.001 and dir.Unit or Vector2.new(0, 1)
local ep = center + Vector2.new(dir.X * (center.X - 40), dir.Y * (center.Y - 40))
local a = arrows[ai]
if not a then
local f = new("Frame", { Size = UDim2.fromOffset(10, 10), AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0 }, layer)
new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, f)
a = { f = f, l = text(f, { Size = UDim2.fromOffset(110, 14), Position = UDim2.new(0.5, -55, 1, 2), TextSize = 11, TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextStrokeTransparency = 0.5 }) }
arrows[ai] = a
end
a.f.Visible = true
a.f.Position = UDim2.fromOffset(ep.X, ep.Y)
a.f.BackgroundColor3 = col
a.l.TextColor3 = col
a.l.Text = plr.DisplayName .. "  " .. (mine and math.floor((pos - mine.Position).Magnitude) or 0)
end
end
if S.radar and mine then
di += 1
local rel = pos - mine.Position
local v2 = Vector2.new(rel:Dot(right), -rel:Dot(fwd)) * (70 / S.radarRange)
if v2.Magnitude > 68 then v2 = v2.Unit * 68 end
local d = dots[di]
if not d then
d = new("Frame", { Size = UDim2.fromOffset(6, 6), AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0 }, radar)
new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, d)
dots[di] = d
end
d.Visible = true
d.Position = UDim2.fromOffset(75 + v2.X, 75 + v2.Y)
d.BackgroundColor3 = col
end
end
end
end
for i = used + 1, #pool do pool[i].Visible = false end
for i = ai + 1, #arrows do arrows[i].f.Visible = false end
for i = di + 1, #dots do dots[i].Visible = false end
end)
local boxes, bars, hb = {}, {}, {}
table.insert(X.ticks, function()
for _, plr in ipairs(Players:GetPlayers()) do
local c = plr.Character
local ok = allowed(plr) and c ~= nil
local b = boxes[plr]
if S.espBox and ok then
if not b or b.Parent ~= c then
if b then b:Destroy() end
boxes[plr] = new("SelectionBox", { Adornee = c, Color3 = teamCol(plr), LineThickness = 0.04, SurfaceTransparency = 1 }, c)
end
elseif b then b:Destroy() boxes[plr] = nil end
local head, hum = c and c:FindFirstChild("Head"), c and c:FindFirstChildOfClass("Humanoid")
local bar = bars[plr]
if S.hpbars and ok and head and hum then
if not bar or bar.bb.Parent ~= head then
if bar then bar.bb:Destroy() end
local bb = new("BillboardGui", { Adornee = head, AlwaysOnTop = true, Size = UDim2.fromOffset(64, 8), StudsOffset = Vector3.new(0, 4.4, 0) }, head)
local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.4, BorderSizePixel = 0 }, bb)
corner(bg, 4)
local fill = new("Frame", { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0 }, bg)
corner(fill, 4)
bar = { bb = bb, fill = fill }
bars[plr] = bar
end
local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
bar.fill.Size = UDim2.fromScale(pct, 1)
bar.fill.BackgroundColor3 = Color3.fromRGB(255, 70, 70):Lerp(Color3.fromRGB(70, 230, 120), pct)
elseif bar then bar.bb:Destroy() bars[plr] = nil end
end
for p, b in pairs(boxes) do if not p.Parent then b:Destroy() boxes[p] = nil end end
for p, b in pairs(bars) do if not p.Parent then b.bb:Destroy() bars[p] = nil end end
end)
local function restoreHit()
for p, o in pairs(hb) do if p.Parent then p.Size, p.Transparency, p.CanCollide = o[1], o[2], o[3] end end
hb = {}
end
table.insert(X.steps, function()
if not S.hitbox then if next(hb) then restoreHit() end return end
local pn = S.hitHead and "Head" or "HumanoidRootPart"
for p in pairs(hb) do if p.Name ~= pn then restoreHit() break end end
for _, plr in ipairs(Players:GetPlayers()) do
local part = allowed(plr) and plr.Character and plr.Character:FindFirstChild(pn)
if part then
if not hb[part] then hb[part] = { part.Size, part.Transparency, part.CanCollide } end
part.Size = Vector3.new(S.hitSize, S.hitSize, S.hitSize)
part.Transparency = S.hitShow and 0.7 or hb[part][2]
part.CanCollide = false
end
end
end)
table.insert(X.cleanups, restoreHit)
local ct = {}
local function hide(p) if p:IsA("BasePart") and not p:IsA("Terrain") and not isCharPart(p) then ct[p] = p.CanQuery p.CanQuery = false end end
function X.setThroughWalls(v)
if v then
for _, p in ipairs(workspace:GetDescendants()) do hide(p) end
X.twConn = workspace.DescendantAdded:Connect(function(d) task.delay(0.6, function() if S.twalls and d.Parent then hide(d) end end) end)
else
if X.twConn then X.twConn:Disconnect() X.twConn = nil end
for p, q in pairs(ct) do if p.Parent then p.CanQuery = q end end
ct = {}
end
end
table.insert(X.cleanups, function() X.setThroughWalls(false) end)
local items, objs, tk = {}, {}, 0
local function esp2(store, key, adornee, label, col, hl)
local o = store[key]
if not o or o.bb.Parent ~= adornee then
if o then o.bb:Destroy() if o.hl then o.hl:Destroy() end end
local bb = new("BillboardGui", { Adornee = adornee, AlwaysOnTop = true, Size = UDim2.fromOffset(130, 22), StudsOffset = Vector3.new(0, 2.2, 0) }, adornee)
local l = text(bb, { Size = UDim2.fromScale(1, 1), TextSize = 12, Font = Enum.Font.GothamBold, TextColor3 = col, TextStrokeTransparency = 0.4, TextXAlignment = Enum.TextXAlignment.Center })
o = { bb = bb, l = l }
if hl then o.hl = new("Highlight", { FillColor = col, OutlineColor = col, FillTransparency = 0.8, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop }, key) end
store[key] = o
end
o.l.Text = label
end
local function clearStore(st) for k, o in pairs(st) do o.bb:Destroy() if o.hl then o.hl:Destroy() end st[k] = nil end end
local function nameOf(d) return d:IsA("Model") and (d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart", true)) or d end
table.insert(X.ticks, function()
tk += 1
if tk % 8 ~= 0 then return end
local r = getRoot()
if S.itemEsp then
local seen, n = {}, 0
for _, d in ipairs(workspace:GetDescendants()) do
if n < 60 and d:IsA("Tool") then
local owner = d:FindFirstAncestorOfClass("Model")
local h = not (owner and owner:FindFirstChildOfClass("Humanoid")) and (d:FindFirstChild("Handle") or d:FindFirstChildWhichIsA("BasePart"))
if h then n += 1 seen[d] = true esp2(items, d, h, d.Name .. (r and ("  " .. math.floor((h.Position - r.Position).Magnitude)) or ""), Color3.fromRGB(255, 220, 90), false) end
end
end
for k, o in pairs(items) do if not seen[k] then o.bb:Destroy() items[k] = nil end end
elseif next(items) then clearStore(items) end
local q = string.lower(X.objEspQuery or "")
if S.objEsp and q ~= "" then
local seen, n = {}, 0
for _, d in ipairs(workspace:GetDescendants()) do
if n >= 80 then break end
if string.find(string.lower(d.Name), q, 1, true) or d.ClassName == X.objEspQuery then
local t = (d:IsA("BasePart") or d:IsA("Model")) and d or d:FindFirstAncestorWhichIsA("BasePart")
local part = t and nameOf(t)
if part and not isCharPart(part) then n += 1 seen[t] = true esp2(objs, t, part, t.Name .. (r and ("  " .. math.floor((part.Position - r.Position).Magnitude)) or ""), Color3.fromRGB(120, 230, 255), n <= 25) end
end
end
for k, o in pairs(objs) do if not seen[k] then o.bb:Destroy() if o.hl then o.hl:Destroy() end objs[k] = nil end end
elseif next(objs) then clearStore(objs) end
end)
table.insert(X.cleanups, function() clearStore(items) clearStore(objs) for _, b in pairs(boxes) do b:Destroy() end for _, b in pairs(bars) do b.bb:Destroy() end end)
X.infoLabel = lrow(pPInfo, 110, "player info card account age team")
X.infoLabel.Text = "No player selected"
function X.updateInfo()
local p = X.infoTarget
if not p or not p.Parent then X.infoLabel.Text = "No player selected" return end
local c = p.Character
local hum, root, mine = c and c:FindFirstChildOfClass("Humanoid"), c and c:FindFirstChild("HumanoidRootPart"), getRoot()
local tool = c and c:FindFirstChildOfClass("Tool")
X.infoLabel.Text = string.format("%s  (@%s)\nUserId %d  •  %s  •  Account age %d days\nTeam: %s  •  Health %d / %d\nDistance %d studs  •  Holding: %s", p.DisplayName, p.Name, p.UserId, p.MembershipType.Name, p.AccountAge, p.Team and p.Team.Name or "none", hum and math.floor(hum.Health) or 0, hum and math.floor(hum.MaxHealth) or 0, (root and mine) and math.floor((root.Position - mine.Position).Magnitude) or 0, tool and tool.Name or "nothing")
end
table.insert(X.ticks, function() if X.infoTarget then X.updateInfo() end end)
refreshPlayers = function(exclude, soft)
local list = {}
for _, p in ipairs(Players:GetPlayers()) do if p ~= player and p ~= exclude then table.insert(list, p) end end
local mine = getRoot()
local function dist(p) local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart") return (r and mine) and (r.Position - mine.Position).Magnitude or 1e9 end
if S.sortDist and mine then table.sort(list, function(a, b) return dist(a) < dist(b) end) end
local sig = {}
for _, p in ipairs(list) do table.insert(sig, p.Name) end
sig = table.concat(sig, ",")
if soft and sig == X.playerSig then return end
X.playerSig = sig
clearList(playerList)
for n, p in ipairs(list) do
local r = row(playerList, 42, n)
text(r, { Size = UDim2.new(1, -300, 0, 18), Position = UDim2.fromOffset(14, 5), Text = p.DisplayName, Font = Enum.Font.GothamMedium, TextTruncate = Enum.TextTruncate.AtEnd })
local d = dist(p)
text(r, { Size = UDim2.new(1, -300, 0, 14), Position = UDim2.fromOffset(14, 23), Text = "@" .. p.Name .. (d < 1e8 and ("  •  " .. math.floor(d)) or ""), TextSize = 11, TextColor3 = C.muted, TextTruncate = Enum.TextTruncate.AtEnd })
miniButton(r, "TP", 12, function() tpTo(p) end, true)
miniButton(r, "View", 66, function() spectate(p) end)
miniButton(r, "Fling", 120, function() X.flingPlayer(p) end)
miniButton(r, "Stick", 174, function() X.stickTo(p) end)
miniButton(r, "Info", 228, function() X.infoTarget = p X.updateInfo() toast("Inspecting " .. p.DisplayName) end)
end
if #list == 0 then
local r = row(playerList, 38, 1)
text(r, { Size = UDim2.new(1, -28, 1, 0), Position = UDim2.fromOffset(14, 0), Text = "No other players in this server", TextColor3 = C.muted, TextSize = 13 })
end
end
table.insert(X.ticks, function() X.plTk = (X.plTk or 0) + 1 if S.sortDist and X.plTk % 8 == 0 then refreshPlayers(nil, true) end end)
section(pEsp, "Player ESP")
flags(pEsp, { { "Box ESP", "3D box around players", "espBox" }, { "Skeleton ESP", "Bones through walls", "skeleton" }, { "Look Direction", "Where players face", "lookdir" }, { "Health Bars", "Bar over each head", "hpbars" }, { "Off-screen Indicators", "Dots for players out of view", "arrows" } })
section(pEsp, "Radar")
flags(pEsp, { { "Radar", "Minimap of nearby players", "radar" } })
binds(pEsp, { { "Radar Range", 30, 800, "radarRange", 150 } })
section(pEsp, "Filters & Sorting")
local function reESP() if S.esp then setESP(true) end end
flags(pEsp, { { "Hide Teammates", "ESP skips your team", "espHideTeam", reESP }, { "Teammates Only", "ESP shows only your team", "espTeamOnly", reESP }, { "Sort Players by Distance", "Closest first in the Teleport list", "sortDist", function() refreshPlayers() end } })
section(pEsp, "World ESP")
flags(pEsp, { { "Item ESP", "Label dropped tools", "itemEsp" } })
irow(pEsp, "Object name or class...", "Apply", function(q) X.objEspQuery = q toast("Object ESP target: " .. (q ~= "" and q or "none")) end, "object esp name class find")
flags(pEsp, { { "Object ESP", "Highlight objects matching the target", "objEsp" } })
section(pEsp, "Hitboxes & Walls (client-side)")
flags(pEsp, { { "Hitbox Expander", "Bigger player hitboxes", "hitbox" }, { "Head Hitbox", "Expand heads instead of roots", "hitHead" }, { "Show Hitboxes", "Make expanded hitboxes visible", "hitShow" } })
binds(pEsp, { { "Hitbox Size", 2, 40, "hitSize", 8 } })
flags(pEsp, { { "Shoot Through Walls", "Raycasts ignore world parts", "twalls", X.setThroughWalls } })
end
do
local pc, pconn = {}, nil
local function applyP(p)
if not pc[p] then pc[p] = { p.HoldDuration, p.MaxActivationDistance, p.RequiresLineOfSight } end
p.HoldDuration = 0
p.MaxActivationDistance = pc[p][2] * S.promptRange
p.RequiresLineOfSight = false
end
function X.setPrompts(v)
if v then
for _, d in ipairs(workspace:GetDescendants()) do if d:IsA("ProximityPrompt") then applyP(d) end end
pconn = workspace.DescendantAdded:Connect(function(d) if d:IsA("ProximityPrompt") then task.defer(applyP, d) end end)
else
if pconn then pconn:Disconnect() pconn = nil end
for p, o in pairs(pc) do if p.Parent then p.HoldDuration, p.MaxActivationDistance, p.RequiresLineOfSight = o[1], o[2], o[3] end end
pc = {}
end
end
local cc = {}
function X.setColView(v)
if v then
for _, p in ipairs(workspace:GetDescendants()) do
if p:IsA("BasePart") and not p:IsA("Terrain") and not isCharPart(p) then
if not p.CanCollide and p.Transparency < 1 then
cc[p] = { p.Color, p.Transparency }
p.Color = Color3.fromRGB(255, 70, 70)
elseif p.CanCollide and p.Transparency >= 1 then
cc[p] = { p.Color, p.Transparency }
p.Color, p.Transparency = Color3.fromRGB(80, 160, 255), 0.6
end
end
end
else
for p, o in pairs(cc) do if p.Parent then p.Color, p.Transparency = o[1], o[2] end end
cc = {}
end
end
local grabbed, grabDist
table.insert(X.clicks, function()
if not S.grab or X.pickMode then return false end
local t = mouse.Target
local ch = getChar()
if t and t:IsA("BasePart") and not t.Anchored and not t:IsA("Terrain") and not (ch and t:IsDescendantOf(ch)) then
grabbed = t
grabDist = (t.Position - workspace.CurrentCamera.CFrame.Position).Magnitude
toast("Grabbed " .. t.Name .. "  (scroll = distance, right click = throw)")
return true
end
return false
end)
table.insert(X.steps, function()
if not grabbed then return end
if not grabbed.Parent or not S.grab then grabbed = nil return end
local cam = workspace.CurrentCamera
local loc = UIS:GetMouseLocation()
local ray = cam:ViewportPointToRay(loc.X, loc.Y)
grabbed.AssemblyLinearVelocity = (ray.Origin + ray.Direction * grabDist - grabbed.Position) * S.grabPower
grabbed.AssemblyAngularVelocity = Vector3.zero
end)
connect(UIS.InputEnded, function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then grabbed = nil end end)
connect(UIS.InputBegan, function(i)
if grabbed and i.UserInputType == Enum.UserInputType.MouseButton2 then
grabbed.AssemblyLinearVelocity = workspace.CurrentCamera.CFrame.LookVector * S.throwPower
grabbed = nil
end
end)
connect(UIS.InputChanged, function(i) if grabbed and i.UserInputType == Enum.UserInputType.MouseWheel then grabDist = math.clamp(grabDist + i.Position.Z * 4, 5, 300) end end)
local rp, ro = {}, {}
function X.clearRuler() for _, o in ipairs(ro) do o:Destroy() end rp, ro = {}, {} end
table.insert(X.clicks, function()
if not S.ruler or X.pickMode then return false end
mouse.TargetFilter = getChar()
local hit = mouse.Hit
if not hit then return false end
if #rp >= 2 then X.clearRuler() end
local pos = hit.Position
table.insert(rp, pos)
table.insert(ro, new("Part", { Name = "LockpickRuler", Shape = Enum.PartType.Ball, Size = Vector3.new(0.8, 0.8, 0.8), Anchored = true, CanCollide = false, CanQuery = false, Material = Enum.Material.Neon, Color = accent, Position = pos }, workspace))
if #rp == 2 then
local a0, a1 = new("Attachment", {}, ro[1]), new("Attachment", {}, ro[2])
table.insert(ro, new("Beam", { Attachment0 = a0, Attachment1 = a1, Width0 = 0.25, Width1 = 0.25, FaceCamera = true, LightEmission = 1, Color = ColorSequence.new(accent) }, ro[1]))
local d = (rp[1] - rp[2]).Magnitude
toast(string.format("Distance: %.1f studs  (%.1f m)", d, d * 0.28))
local mid = new("Part", { Name = "LockpickRulerLabel", Size = Vector3.one * 0.2, Transparency = 1, Anchored = true, CanCollide = false, CanQuery = false, Position = (rp[1] + rp[2]) / 2 }, workspace)
local bb = new("BillboardGui", { Size = UDim2.fromOffset(120, 24), AlwaysOnTop = true, StudsOffset = Vector3.new(0, 1.5, 0) }, mid)
text(bb, { Size = UDim2.fromScale(1, 1), Text = string.format("%.1f studs", d), Font = Enum.Font.GothamBold, TextSize = 14, TextStrokeTransparency = 0.3, TextXAlignment = Enum.TextXAlignment.Center })
table.insert(ro, mid)
end
return true
end)
local wPart
local function setWeather(kind)
if wPart then wPart:Destroy() wPart = nil end
if kind == "none" then return end
wPart = new("Part", { Name = "LockpickWeather", Size = Vector3.new(70, 1, 70), Anchored = true, CanCollide = false, CanQuery = false, Transparency = 1 }, workspace)
local rain = kind == "rain"
new("ParticleEmitter", { Rate = rain and 600 or 160, Lifetime = NumberRange.new(2, 3), Speed = NumberRange.new(rain and 70 or 6, rain and 90 or 10), EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(rain and 3 or 25, rain and 3 or 25), Size = NumberSequence.new(rain and 0.15 or 0.3), Color = ColorSequence.new(rain and Color3.fromRGB(170, 200, 255) or Color3.new(1, 1, 1)), Transparency = NumberSequence.new(rain and 0.4 or 0.1), LightEmission = 0.3, Acceleration = Vector3.new(0, rain and -40 or -2, 0) }, wPart)
end
table.insert(X.steps, function() if wPart then wPart.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position + Vector3.new(0, 38, 0)) end end)
local snap = {}
for _, k in ipairs({ "Brightness", "ClockTime", "Ambient", "OutdoorAmbient", "FogColor", "FogEnd", "FogStart" }) do snap[k] = Lighting[k] end
local P = {
Day = { ClockTime = 14, Brightness = 2, Ambient = Color3.fromRGB(110, 110, 115), OutdoorAmbient = Color3.fromRGB(140, 140, 150), FogEnd = 100000 },
Dusk = { ClockTime = 18.2, Brightness = 1.5, Ambient = Color3.fromRGB(90, 60, 70), OutdoorAmbient = Color3.fromRGB(150, 90, 90), FogEnd = 3000, FogColor = Color3.fromRGB(200, 120, 100) },
Night = { ClockTime = 0, Brightness = 0.4, Ambient = Color3.fromRGB(25, 30, 60), OutdoorAmbient = Color3.fromRGB(35, 45, 90), FogEnd = 2500, FogColor = Color3.fromRGB(10, 15, 35) },
Foggy = { Brightness = 1.2, FogStart = 0, FogEnd = 160, FogColor = Color3.fromRGB(180, 185, 190), Ambient = Color3.fromRGB(120, 120, 125), OutdoorAmbient = Color3.fromRGB(150, 150, 155) },
Void = { Brightness = 0, ClockTime = 0, Ambient = Color3.new(0, 0, 0), OutdoorAmbient = Color3.new(0, 0, 0), FogStart = 0, FogEnd = 120, FogColor = Color3.new(0, 0, 0) },
Restore = snap,
}
local function applyL(n) return function() for k, v in pairs(P[n]) do Lighting[k] = v end toast("Lighting: " .. n) end end
local skyCache
function X.setSky(v)
local sky = Lighting:FindFirstChildOfClass("Sky")
if v and sky then skyCache = sky sky.Parent = nil elseif not v and skyCache then skyCache.Parent = Lighting skyCache = nil end
end
local G = {
Noir = { Saturation = -1, Contrast = 0.3 }, Vintage = { Saturation = -0.3, Contrast = 0.1, TintColor = Color3.fromRGB(255, 225, 190) }, Vivid = { Saturation = 1, Contrast = 0.2 },
Cold = { TintColor = Color3.fromRGB(190, 215, 255) }, Warm = { TintColor = Color3.fromRGB(255, 215, 180) },
["Night Vision"] = { TintColor = Color3.fromRGB(140, 255, 140), Brightness = 0.12, Contrast = 0.25, Saturation = -0.4 },
Thermal = { Saturation = -1, Contrast = 0.5, Brightness = -0.05, TintColor = Color3.fromRGB(255, 160, 60) }, Reset = {},
}
local function grade(n) return function()
local c = X.getCC()
c.Saturation, c.Contrast, c.Brightness, c.TintColor = 0, 0, 0, Color3.new(1, 1, 1)
for k, v in pairs(G[n]) do c[k] = v end
toast("Grade: " .. n)
end end
local function fx(key, class, props) if not X[key] or not X[key].Parent then X[key] = new(class, props, Lighting) end return X[key] end
local function dof() return fx("dof", "DepthOfFieldEffect", { Name = "LockpickDOF", FarIntensity = 0, NearIntensity = 0, FocusDistance = 30, InFocusRadius = 20 }) end
local function rays() return fx("rays", "SunRaysEffect", { Name = "LockpickRays", Intensity = 0, Spread = 0.5 }) end
local function bloom() return fx("bloom", "BloomEffect", { Name = "LockpickBloom", Intensity = 0, Size = 24, Threshold = 2 }) end
function X.spawnProp(kind)
local r = getRoot()
if not r then return end
local p
if kind == "Seat" then p = new("Seat", { Size = Vector3.new(2, 0.6, 2) })
elseif kind == "Ladder" then p = new("TrussPart", { Size = Vector3.new(2, 14, 2) })
elseif kind == "Ramp" then p = new("WedgePart", { Size = Vector3.new(10, 6, 14) })
elseif kind == "Wall" then p = new("Part", { Size = Vector3.new(16, 10, 1) })
elseif kind == "Platform" then p = new("Part", { Size = Vector3.new(14, 1, 14) })
else p = new("Part", { Size = Vector3.new(10, 1, 10) }) end
p.Name, p.Anchored, p.Material, p.Color = "LockpickProp", true, Enum.Material.SmoothPlastic, accent
p.CFrame = r.CFrame * CFrame.new(0, -2.5 + p.Size.Y / 2, -8)
if kind == "Trampoline" then p.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 1, 1, 100) end
if kind == "Jump Pad" or kind == "Speed Pad" then
p.Color = kind == "Jump Pad" and Color3.fromRGB(80, 230, 130) or Color3.fromRGB(255, 190, 60)
p.Touched:Connect(function(h)
local ch, root = getChar(), getRoot()
if ch and root and h:IsDescendantOf(ch) then
local v = root.AssemblyLinearVelocity
root.AssemblyLinearVelocity = kind == "Jump Pad" and Vector3.new(v.X, 120, v.Z) or p.CFrame.LookVector * 110 + Vector3.new(0, v.Y, 0)
end
end)
end
p.Parent = workspace
table.insert(X.blocks, p)
toast("Spawned " .. kind)
end
table.insert(X.cleanups, function()
X.setPrompts(false) X.setColView(false) X.clearRuler() setWeather("none") X.setSky(false)
for _, k in ipairs({ "dof", "rays", "bloom" }) do if X[k] then X[k]:Destroy() end end
end)
section(pWorld, "Weather")
buttonRow(pWorld, { { "Rain", function() setWeather("rain") end }, { "Snow", function() setWeather("snow") end }, { "Clear Weather", function() setWeather("none") end } })
section(pWorld, "Lighting Presets")
buttonRow(pWorld, { { "Day", applyL("Day") }, { "Dusk", applyL("Dusk") }, { "Night", applyL("Night") } })
buttonRow(pWorld, { { "Foggy", applyL("Foggy") }, { "Void", applyL("Void") }, { "Restore Lighting", applyL("Restore") } })
flags(pWorld, { { "Hide Sky", "Remove sun, moon and stars", "nosky", X.setSky } })
section(pWorld, "Interaction")
flags(pWorld, { { "Instant Prompts", "No hold time, longer reach, no line of sight", "instantPrompts", X.setPrompts } })
binds(pWorld, { { "Prompt Range x", 1, 20, "promptRange", 1, 1, function() for p, o in pairs(pc) do if p.Parent then p.MaxActivationDistance = o[2] * S.promptRange end end end } })
flags(pWorld, { { "Collision Viewer", "Red = no collision, blue = invisible walls", "colview", X.setColView }, { "Performance Mode", "Shadows, effects and textures off", "perf", function(v)
for _, n in ipairs({ "disable shadows", "disable post-processing", "hide effects", "plain materials", "remove decals & textures" }) do
local t = togglesByName[n]
if t and t.get() ~= v then t.set(v, true) end
end
end } })
section(pWorld, "Spawn Menu (local only)")
buttonRow(pWorld, { { "Seat", function() X.spawnProp("Seat") end }, { "Ladder", function() X.spawnProp("Ladder") end }, { "Ramp", function() X.spawnProp("Ramp") end } })
buttonRow(pWorld, { { "Platform", function() X.spawnProp("Platform") end }, { "Wall", function() X.spawnProp("Wall") end }, { "Trampoline", function() X.spawnProp("Trampoline") end } })
buttonRow(pWorld, { { "Jump Pad", function() X.spawnProp("Jump Pad") end }, { "Speed Pad", function() X.spawnProp("Speed Pad") end } })
section(pVisual, "Color Grade Presets")
buttonRow(pVisual, { { "Noir", grade("Noir") }, { "Vintage", grade("Vintage") }, { "Vivid", grade("Vivid") } })
buttonRow(pVisual, { { "Cold", grade("Cold") }, { "Warm", grade("Warm") }, { "Reset Grade", grade("Reset") } })
buttonRow(pVisual, { { "Night Vision", grade("Night Vision") }, { "Thermal", grade("Thermal") } })
section(pVisual, "Depth of Field, Rays, Bloom")
binds(pVisual, { { "DOF Far Blur", 0, 1, "dofFar", 0, 2, function(v) dof().FarIntensity = v end }, { "DOF Focus Distance", 1, 300, "dofDist", 30, 0, function(v) dof().FocusDistance = v end }, { "DOF Focus Radius", 1, 200, "dofRad", 20, 0, function(v) dof().InFocusRadius = v end }, { "Sun Rays", 0, 1, "raysAmt", 0, 2, function(v) rays().Intensity = v end }, { "Bloom", 0, 3, "bloomAmt", 0, 2, function(v) bloom().Intensity = v end } })
section(pTools, "Telekinesis & Ruler")
flags(pTools, { { "Telekinesis", "Click-hold loose parts to move them", "grab" } })
binds(pTools, { { "Grab Strength", 5, 120, "grabPower", 40 }, { "Throw Power", 20, 400, "throwPower", 120 } })
flags(pTools, { { "Ruler", "Click two points to measure", "ruler", function(v) if not v then X.clearRuler() end end } })
button(pTools, "Clear Ruler", X.clearRuler)
end
do
local hud = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 0 }, gui)
local stack = new("Frame", { Size = UDim2.fromOffset(150, 0), AutomaticSize = Enum.AutomaticSize.Y, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0), BackgroundTransparency = 1 }, hud)
new("UIListLayout", { Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder }, stack)
local function pill(order)
local f = new("Frame", { Size = UDim2.fromOffset(150, 28), BackgroundColor3 = C.bg, BackgroundTransparency = 0.3, BorderSizePixel = 0, Visible = false, LayoutOrder = order }, stack)
corner(f, 8) stroke(f, C.stroke, 1, 0.3)
return f, text(f, { Size = UDim2.fromScale(1, 1), TextSize = 13, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Center })
end
local fSpd, lSpd = pill(1)
local fAlt, lAlt = pill(2)
local fClk, lClk = pill(3)
local fFps, lFps = pill(4)
local graph = new("Frame", { Size = UDim2.fromOffset(160, 58), Position = UDim2.fromOffset(16, 64), BackgroundColor3 = C.bg, BackgroundTransparency = 0.3, BorderSizePixel = 0, Visible = false, ZIndex = 0 }, hud)
corner(graph, 8) stroke(graph, C.stroke, 1, 0.3)
local bars, hist = {}, {}
for i = 1, 40 do
bars[i] = new("Frame", { Size = UDim2.fromOffset(3, 4), AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 4 + (i - 1) * 3.85, 1, -4), BorderSizePixel = 0, Visible = false }, graph)
onAccent(function(c) bars[i].BackgroundColor3 = c end)
end
local comp = new("Frame", { Size = UDim2.fromOffset(320, 28), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 54), BackgroundColor3 = C.bg, BackgroundTransparency = 0.35, BorderSizePixel = 0, ClipsDescendants = true, Visible = false, ZIndex = 0 }, hud)
corner(comp, 8)
local cl, ct = {}, {}
for i, n in ipairs({ "N", "NE", "E", "SE", "S", "SW", "W", "NW" }) do
cl[i] = text(comp, { Size = UDim2.fromOffset(30, 24), AnchorPoint = Vector2.new(0.5, 0), Text = n, TextSize = 13, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center })
end
for i = 1, 24 do ct[i] = new("Frame", { Size = UDim2.fromOffset(1, 6), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0, 0, 1, 0), BackgroundColor3 = C.muted, BorderSizePixel = 0 }, comp) end
local mark = new("Frame", { Size = UDim2.fromOffset(2, 28), Position = UDim2.new(0.5, -1, 0, 0), BorderSizePixel = 0 }, comp)
onAccent(function(c) mark.BackgroundColor3 = c end)
local keysF = new("Frame", { Size = UDim2.fromOffset(150, 120), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 16, 0.5, 0), BackgroundTransparency = 1, Visible = false, ZIndex = 0 }, hud)
local kl = {}
local function kb(label, x, y, w, fn)
local f = new("Frame", { Size = UDim2.fromOffset(w, 34), Position = UDim2.fromOffset(x, y), BackgroundColor3 = C.bg, BackgroundTransparency = 0.3, BorderSizePixel = 0 }, keysF)
corner(f, 6)
text(f, { Size = UDim2.fromScale(1, 1), Text = label, TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center })
table.insert(kl, { f = f, fn = fn })
end
local function kd(k) return function() return UIS:IsKeyDown(k) end end
kb("W", 40, 0, 34, kd(Enum.KeyCode.W)) kb("A", 0, 38, 34, kd(Enum.KeyCode.A)) kb("S", 40, 38, 34, kd(Enum.KeyCode.S)) kb("D", 80, 38, 34, kd(Enum.KeyCode.D))
kb("Space", 0, 76, 74, kd(Enum.KeyCode.Space)) kb("LMB", 78, 76, 36, function() return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) end) kb("RMB", 118, 76, 32, function() return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end)
local acc, frames = 0, 0
table.insert(X.steps, function(dt)
acc += dt frames += 1
local r, cam = getRoot(), workspace.CurrentCamera
fSpd.Visible, fAlt.Visible, fClk.Visible, fFps.Visible, graph.Visible, comp.Visible, keysF.Visible = S.hudSpeed, S.hudAlt, S.hudClock, S.hudFps, S.hudGraph, S.hudCompass, S.hudKeys
if S.hudCompass then
local l = cam.CFrame.LookVector
local hd = (math.deg(math.atan2(l.X, -l.Z)) + 360) % 360
for i = 1, 8 do
local d = ((i - 1) * 45 - hd + 540) % 360 - 180
cl[i].Visible = math.abs(d) < 56
cl[i].Position = UDim2.fromOffset(160 + d * 2.67, 2)
end
for i = 1, 24 do
local d = ((i - 1) * 15 - hd + 540) % 360 - 180
ct[i].Visible = math.abs(d) < 58 and (i - 1) % 3 ~= 0
ct[i].Position = UDim2.fromOffset(160 + d * 2.67, 28)
end
end
if S.hudKeys then for _, k in ipairs(kl) do k.f.BackgroundColor3 = k.fn() and accent or C.bg end end
if acc >= 0.25 then
local fps = frames / acc
acc, frames = 0, 0
if S.hudSpeed and r then lSpd.Text = math.floor(r.AssemblyLinearVelocity.Magnitude) .. " studs/s" end
if S.hudAlt and r then lAlt.Text = "Altitude " .. math.floor(r.Position.Y) end
if S.hudClock then lClk.Text = os.date("%I:%M %p") .. "  •  " .. string.format("%02d:%02d", math.floor(Lighting.ClockTime), math.floor(Lighting.ClockTime % 1 * 60)) end
local ping = 0
pcall(function() ping = player:GetNetworkPing() * 1000 end)
if S.hudFps then lFps.Text = math.floor(fps + 0.5) .. " FPS   " .. math.floor(ping + 0.5) .. " ms" end
if S.hudGraph then
table.insert(hist, fps)
if #hist > 40 then table.remove(hist, 1) end
for i = 1, 40 do
local v = hist[i]
bars[i].Visible = v ~= nil
if v then bars[i].Size = UDim2.fromOffset(3, math.clamp(v / 144, 0.05, 1) * 48) end
end
end
end
end)
local xh = new("Frame", { Size = UDim2.fromOffset(24, 24), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Visible = false, ZIndex = 0 }, gui)
local xs = new("UIScale", {}, xh)
local function xp(size, pos)
local f = new("Frame", { Size = size, Position = pos, BorderSizePixel = 0 }, xh)
onAccent(function(c) f.BackgroundColor3 = c end)
return f
end
local ring = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, xh)
new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, ring)
local rg = stroke(ring, accent, 2, 0)
onAccent(function(c) rg.Color = c end)
local g2 = { xp(UDim2.fromOffset(2, 8), UDim2.fromOffset(11, 0)), xp(UDim2.fromOffset(2, 8), UDim2.fromOffset(11, 16)), xp(UDim2.fromOffset(8, 2), UDim2.fromOffset(0, 11)), xp(UDim2.fromOffset(8, 2), UDim2.fromOffset(16, 11)) }
local g4 = { xp(UDim2.fromOffset(24, 2), UDim2.fromOffset(0, 11)), xp(UDim2.fromOffset(2, 24), UDim2.fromOffset(11, 0)) }
X.xhStyle, X.xhVis = 1, false
local function xhApply()
X.crosshair.Visible = X.xhVis and X.xhStyle == 1
xh.Visible = X.xhVis and X.xhStyle ~= 1
ring.Visible = X.xhStyle == 3
for _, f in ipairs(g2) do f.Visible = X.xhStyle == 2 end
for _, f in ipairs(g4) do f.Visible = X.xhStyle == 4 end
end
function X.xhShow(v) X.xhVis = v xhApply() end
function X.xhSize(v) X.crosshair.Size = UDim2.fromOffset(v, v) xs.Scale = v / 12 end
local hm = new("Frame", { Size = UDim2.fromOffset(26, 26), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Visible = false, ZIndex = 0 }, gui)
local hl = {}
for _, rot in ipairs({ 45, -45 }) do hl[#hl + 1] = new("Frame", { Size = UDim2.fromOffset(22, 2), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Rotation = rot, BorderSizePixel = 0 }, hm) end
local hs = new("Sound", { SoundId = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.6 }, gui)
function X.hit(kill)
for _, f in ipairs(hl) do f.BackgroundColor3 = kill and Color3.fromRGB(255, 70, 70) or Color3.new(1, 1, 1) end
hm.Visible = true
hs:Play()
task.delay(0.25, function() hm.Visible = false end)
end
local function hook(plr)
if plr == player then return end
local function onChar(c)
local hum = c:WaitForChild("Humanoid", 10)
if not hum then return end
local last = hum.Health
hum.HealthChanged:Connect(function(h)
if h < last and S.hitmarker then
local cam, root = workspace.CurrentCamera, c:FindFirstChild("HumanoidRootPart")
local d = root and (root.Position - cam.CFrame.Position)
if d and d.Magnitude < 400 and cam.CFrame.LookVector:Dot(d.Unit) > 0.97 then X.hit(h <= 0) end
end
last = h
end)
end
if plr.Character then task.spawn(onChar, plr.Character) end
connect(plr.CharacterAdded, onChar)
end
for _, p in ipairs(Players:GetPlayers()) do hook(p) end
connect(Players.PlayerAdded, hook)
local function lockTarget(cam)
local p = X.viewTarget
local h = p and p.Character and p.Character:FindFirstChild("Head")
if h then return h end
local best, bd = nil, 0.5
for _, pl in ipairs(Players:GetPlayers()) do
local hd = pl ~= player and pl.Character and pl.Character:FindFirstChild("Head")
if hd then
local d = hd.Position - cam.CFrame.Position
local dot = d.Magnitude > 0 and cam.CFrame.LookVector:Dot(d.Unit) or 0
if dot > bd then best, bd = hd, dot end
end
end
return best
end
local orbA = 0
RunService:BindToRenderStep("LockpickCam", Enum.RenderPriority.Camera.Value + 1, function(dt)
if S.freecam then return end
local cam = workspace.CurrentCamera
local r = getRoot()
if S.lockon then
local hd = lockTarget(cam)
if hd then cam.CFrame = CFrame.lookAt(cam.CFrame.Position, hd.Position) end
end
if S.orbitcam then
local tr = X.viewTarget and X.viewTarget.Character and X.viewTarget.Character:FindFirstChild("HumanoidRootPart") or r
if tr then
orbA += dt * S.orbitSpeed * 0.5
cam.CFrame = CFrame.lookAt(tr.Position + Vector3.new(math.cos(orbA) * S.orbitRadius, S.orbitHeight, math.sin(orbA) * S.orbitRadius), tr.Position)
end
end
if S.dolly and r then
local f0 = X.dBase or 70
local fov = math.clamp(f0 + S.dollyAmp * math.sin(os.clock() * 1.5), 20, 120)
cam.FieldOfView = fov
local d = (X.dDist or 14) * math.tan(math.rad(f0 / 2)) / math.tan(math.rad(fov / 2))
cam.CFrame = CFrame.lookAt(r.Position - cam.CFrame.LookVector * d, r.Position)
end
if S.shake then
local a = S.shakeAmt * 0.1
cam.CFrame = cam.CFrame * CFrame.new((math.random() - 0.5) * a, (math.random() - 0.5) * a, 0) * CFrame.Angles(0, 0, math.rad((math.random() - 0.5) * a * 2))
end
if S.camRoll and S.camRoll ~= 0 then cam.CFrame = cam.CFrame * CFrame.Angles(0, 0, math.rad(S.camRoll)) end
end)
table.insert(X.cleanups, function() pcall(function() RunService:UnbindFromRenderStep("LockpickCam") end) end)
local function fovBack() workspace.CurrentCamera.FieldOfView = S.fov or DEFAULTS.FOV end
S.camRoll = 0
section(pHud, "Info Panels")
flags(pHud, { { "FPS & Ping", "Live frame rate and latency", "hudFps" }, { "FPS Graph", "Frame rate history", "hudGraph" }, { "Speedometer", "Your speed in studs/s", "hudSpeed" }, { "Altitude Meter", "Your height", "hudAlt" }, { "Clock", "Real time and game time", "hudClock" }, { "Compass Bar", "Heading strip at the top", "hudCompass" }, { "Keystrokes", "WASD, Space and mouse buttons", "hudKeys" } })
section(pHud, "Crosshair & Hits")
flags(pHud, { { "Hitmarker", "Flash when a player you aim at takes damage", "hitmarker" } })
buttonRow(pHud, { { "Dot", function() X.xhStyle = 1 xhApply() end }, { "Cross", function() X.xhStyle = 2 xhApply() end }, { "Circle", function() X.xhStyle = 3 xhApply() end }, { "Plus", function() X.xhStyle = 4 xhApply() end } })
section(pCam, "Cinematic Cameras")
X.fb(pCam, "Orbit Camera", "Circle around you or the viewed player", "orbitcam", "Orbit Speed", 0.2, 6, "orbitSpeed", 1, 1)
binds(pCam, { { "Orbit Radius", 5, 80, "orbitRadius", 18 }, { "Orbit Height", -10, 40, "orbitHeight", 6 } })
X.fb(pCam, "Lock-On Camera", "Aim at the viewed or nearest player", "lockon")
X.fb(pCam, "Dolly Zoom", "Vertigo effect around you", "dolly", "Dolly Amount", 5, 50, "dollyAmp", 25, 0, function(v)
local cam = workspace.CurrentCamera
local r = getRoot()
if v then X.dBase = cam.FieldOfView X.dDist = math.max(8, r and (cam.CFrame.Position - r.Position).Magnitude or 14) else fovBack() end
end)
X.fb(pCam, "Fisheye View", "Very wide field of view", "fisheye", nil, nil, nil, nil, nil, nil, function(v) workspace.CurrentCamera.FieldOfView = v and 120 or (S.fov or DEFAULTS.FOV) end)
X.fb(pCam, "Camera Shake", "Rumble the camera", "shake", "Shake Amount", 1, 30, "shakeAmt", 5)
binds(pCam, { { "Camera Roll", -45, 45, "camRoll", 0 } })
section(pCam, "Views")
X.marks = {}
for i = 1, 3 do
local r = row(pCam, 40)
register(r, "camera view bookmark " .. i)
text(r, { Size = UDim2.fromOffset(120, 40), Position = UDim2.fromOffset(14, 0), Text = "View " .. i, Font = Enum.Font.GothamMedium })
miniButton(r, "Go", 12, function()
local cf = X.marks[i]
if cf then local cam = workspace.CurrentCamera cam.CameraType = Enum.CameraType.Scriptable cam.CFrame = cf toast("View " .. i) else toast("Slot empty") end
end, true)
miniButton(r, "Save", 68, function() X.marks[i] = workspace.CurrentCamera.CFrame toast("Saved view " .. i) end)
end
button(pCam, "Release Camera", function()
local cam = workspace.CurrentCamera
cam.CameraType = Enum.CameraType.Custom
local h = getHum()
if h then cam.CameraSubject = h end
toast("Camera released")
end)
button(pCam, "Photo Mode  (P to exit)", function() X.photo(true) end, true)
end
do
local CS = game:GetService("CollectionService")
function X.esc(s) return (tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")) end
local esc = X.esc
local PROPS = {
{ "Name", "str" }, { "Position", "v3", "BasePart" }, { "Orientation", "v3", "BasePart" }, { "Size", "v3", "BasePart" }, { "Color", "col", "BasePart" }, { "Transparency", "num", "BasePart" }, { "Reflectance", "num", "BasePart" }, { "Anchored", "bool", "BasePart" }, { "CanCollide", "bool", "BasePart" }, { "CanTouch", "bool", "BasePart" }, { "CanQuery", "bool", "BasePart" }, { "Material", "enum", "BasePart" },
{ "Brightness", "num", "Light" }, { "Range", "num", "Light" }, { "Color", "col", "Light" }, { "Enabled", "bool", "Light" },
{ "Volume", "num", "Sound" }, { "PlaybackSpeed", "num", "Sound" }, { "Looped", "bool", "Sound" },
{ "WalkSpeed", "num", "Humanoid" }, { "JumpPower", "num", "Humanoid" }, { "Health", "num", "Humanoid" }, { "MaxHealth", "num", "Humanoid" }, { "HipHeight", "num", "Humanoid" },
{ "Enabled", "bool", "ParticleEmitter" }, { "Rate", "num", "ParticleEmitter" },
{ "HoldDuration", "num", "ProximityPrompt" }, { "MaxActivationDistance", "num", "ProximityPrompt" }, { "ActionText", "str", "ProximityPrompt" },
{ "Visible", "bool", "GuiObject" }, { "Text", "str", "TextLabel" }, { "Value", "auto", "ValueBase" },
}
local function fmt(v, k)
if k == "v3" then return string.format("%.2f, %.2f, %.2f", v.X, v.Y, v.Z) end
if k == "col" then return math.floor(v.R * 255 + 0.5) .. ", " .. math.floor(v.G * 255 + 0.5) .. ", " .. math.floor(v.B * 255 + 0.5) end
if k == "enum" then return v.Name end
if k == "num" then return tostring(math.floor(v * 1000 + 0.5) / 1000) end
return tostring(v)
end
local function parse(t, k, cur)
if k == "str" then return t end
if k == "num" then return tonumber(t) end
if k == "bool" then
t = string.lower(t)
if t == "true" or t == "1" or t == "yes" then return true end
if t == "false" or t == "0" or t == "no" then return false end
return nil
end
if k == "v3" or k == "col" then
local n = {}
for x in string.gmatch(t, "-?%d+%.?%d*") do n[#n + 1] = tonumber(x) end
if #n >= 3 then
if k == "v3" then return Vector3.new(n[1], n[2], n[3]) end
return Color3.fromRGB(math.clamp(n[1], 0, 255), math.clamp(n[2], 0, 255), math.clamp(n[3], 0, 255))
end
return nil
end
if k == "enum" then
for _, it in ipairs(cur.EnumType:GetEnumItems()) do if string.lower(it.Name) == string.lower(t) then return it end end
end
return nil
end
X.exCur, X.exSel = workspace, nil
local dstack = {}
local function sel() if not X.exSel or not X.exSel.Parent then toast("Select something first") return nil end return X.exSel end
local function pivot(o) return o:IsA("Model") and o:GetPivot() or (o:IsA("BasePart") and o.CFrame) or nil end
section(pExp, "Selected Object")
local cardL = lrow(pExp, 92, "explorer selected instance properties attributes tags")
cardL.Text = "Nothing selected.  Browse below or use Pick in World."
buttonRow(pExp, { { "Pick in World", function() X.startPick("sel") end, true }, { "Select Parent", function() local o = sel() if o and o.Parent and o.Parent ~= game then X.exSelect(o.Parent) end end }, { "Open It", function() local o = sel() if o then X.exCur = o X.exRefresh() end end } })
buttonRow(pExp, { { "Teleport To", function() local o, r = sel(), getRoot() local cf = o and pivot(o) if cf and r then r.CFrame = cf + Vector3.new(0, 6, 0) toast("Teleported") else toast("Can't teleport there") end end }, { "View It", function() local o = sel() local p = o and (o:IsA("BasePart") and o or o:FindFirstChildWhichIsA("BasePart", true)) if p then workspace.CurrentCamera.CameraSubject = p toast("Viewing " .. o.Name) end end }, { "Print Path", function() local o = sel() if o then print(o:GetFullName()) toast("Path printed to Output") end end } })
buttonRow(pExp, { { "As Source", function() local o = sel() if o then X.objSrc = o X.setHL("src", o, accent) X.objLabels() toast("Source set") end end }, { "As Destination", function() local o = sel() if o then X.objDst = o X.setHL("dst", o, Color3.fromRGB(255, 170, 55)) X.objLabels() toast("Destination set") end end }, { "Clone", function()
local o = sel()
if o and o ~= workspace then
local c = o:Clone()
local cf = pivot(c)
if cf then if c:IsA("Model") then c:PivotTo(cf + Vector3.new(5, 0, 0)) else c.CFrame = cf + Vector3.new(5, 0, 0) end end
c.Parent = o.Parent
table.insert(X.blocks, c)
toast("Cloned " .. o.Name)
end
end } })
buttonRow(pExp, { { "Delete (Local)", function() local o = sel() if o and o ~= workspace and o.Parent then table.insert(dstack, { o, o.Parent }) o.Parent = nil X.exSel = nil toast("Removed locally") X.exRefresh() end end }, { "Undo Delete", function() local d = table.remove(dstack) if d then d[1].Parent = d[2] toast("Restored " .. d[1].Name) X.exRefresh() else toast("Nothing to undo") end end } })
local propList = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = nextOrder(pExp) }, pExp)
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, propList)
function X.exSelect(inst)
X.exSel = inst
X.setHL("sel", inst, Color3.fromRGB(120, 255, 160))
local at = {}
for k, v in pairs(inst:GetAttributes()) do at[#at + 1] = k .. "=" .. tostring(v) end
local tg = CS:GetTags(inst)
cardL.Text = string.format("%s  [%s]\n%s\nChildren: %d   Attributes: %s\nTags: %s", inst.Name, inst.ClassName, inst:GetFullName(), #inst:GetChildren(), #at > 0 and table.concat(at, ", ") or "none", #tg > 0 and table.concat(tg, ", ") or "none")
clearList(propList)
local n = 0
for _, d in ipairs(PROPS) do
if inst:IsA(d[3] or "Instance") then
local ok, cur = pcall(function() return inst[d[1]] end)
if ok and cur ~= nil then
local k = d[2]
if k == "auto" then local t = typeof(cur) k = t == "string" and "str" or t == "number" and "num" or t == "boolean" and "bool" or nil end
if k then
n += 1
local r = row(propList, 34, n)
text(r, { Size = UDim2.fromOffset(120, 34), Position = UDim2.fromOffset(12, 0), Text = d[1], TextSize = 12, TextColor3 = C.muted })
local b = inbox(r, "", UDim2.new(1, -144, 0, 24), UDim2.fromOffset(132, 5))
b.Text = fmt(cur, k)
b.FocusLost:Connect(function()
local val = parse(b.Text, k, cur)
if val ~= nil then pcall(function() inst[d[1]] = val end) end
local ok2, now = pcall(function() return inst[d[1]] end)
if ok2 then b.Text = fmt(now, k) end
end)
end
end
end
end
end
section(pExp, "Browse")
local function go(inst) return function() X.exCur = inst X.exRefresh() end end
buttonRow(pExp, { { "Workspace", go(workspace) }, { "Lighting", go(Lighting) }, { "Players", go(Players) } })
buttonRow(pExp, { { "ReplicatedStorage", go(game:GetService("ReplicatedStorage")) }, { "StarterGui", go(game:GetService("StarterGui")) }, { "Camera", go(workspace.CurrentCamera) } })
local pr = row(pExp, 38)
X.exPath = text(pr, { Size = UDim2.new(1, -90, 1, 0), Position = UDim2.fromOffset(12, 0), TextSize = 12, TextColor3 = C.muted, TextTruncate = Enum.TextTruncate.AtEnd })
miniButton(pr, "Up", 12, function() local p = X.exCur.Parent if p and p ~= game then X.exCur = p X.exRefresh() end end)
X.exList = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = nextOrder(pExp) }, pExp)
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, X.exList)
function X.exRefresh()
X.exPath.Text = X.exCur:GetFullName()
clearList(X.exList)
local kids = X.exCur:GetChildren()
table.sort(kids, function(a, b) return string.lower(a.Name) < string.lower(b.Name) end)
for n, k in ipairs(kids) do
if n > 120 then break end
local r = row(X.exList, 32, n)
text(r, { Size = UDim2.new(1, -132, 1, 0), Position = UDim2.fromOffset(12, 0), TextSize = 12, RichText = true, TextTruncate = Enum.TextTruncate.AtEnd, Text = esc(k.Name) .. ' <font color="rgb(125,131,155)">' .. k.ClassName .. "</font>" })
miniButton(r, "Sel", 12, function() X.exSelect(k) end, true)
if #k:GetChildren() > 0 then miniButton(r, "Open", 66, function() X.exCur = k X.exRefresh() end) end
end
if #kids == 0 then
local r = row(X.exList, 32, 1)
text(r, { Size = UDim2.new(1, -24, 1, 0), Position = UDim2.fromOffset(12, 0), Text = "(empty)", TextColor3 = C.muted, TextSize = 12 })
end
end
X.exRefresh()
table.insert(X.cleanups, function() X.setHL("sel", nil) end)
end
section(pSet, "Theme")
local themeRow = row(pSet, 56)
local swatchStrokes = {}
for i, t in ipairs(THEMES) do
local b = new("TextButton", { Size = UDim2.fromOffset(30, 30), Position = UDim2.fromOffset(14 + (i - 1) * 42, 13), BackgroundColor3 = t[2], Text = "", AutoButtonColor = false }, themeRow)
corner(b, 15)
swatchStrokes[i] = stroke(b, C.text, 2, i == 1 and 0 or 1)
b.MouseButton1Click:Connect(function()
setAccent(t[2])
for j, st in ipairs(swatchStrokes) do tween(st, { Transparency = j == i and 0 or 1 }) end
toast("Theme: " .. t[1])
end)
end
slider(pSet, "UI Scale", 0.5, 1.5, 1, function(v) userScale = v fit() end, 2)
T.flow = toggle(pSet, "Freeze Colors", "Stop the flowing gradients", function(v)
S.flow = not v
if v then for _, g in ipairs(flowGrads) do g.Offset = Vector2.zero end end
end)
slider(pSet, "Animation Speed", 0.2, 4, S.animSpeed, function(v) S.animSpeed = v end, 1)
slider(pSet, "Window Opacity", 40, 100, 100, function(v)
S.winAlpha = 1 - v / 100
if main.GroupTransparency < 1 then main.GroupTransparency = S.winAlpha end
end)
T.rainbow = toggle(pSet, "Rainbow Accent", "Cycle the theme color", function(v) S.rainbow = v end)
T.muted = toggle(pSet, "Mute Notifications", "Hide corner toast messages", function(v) S.muted = v end)
section(pSet, "Hotkeys")
local hotkeyPill = infoRow(pSet, "RightShift", "Show / hide the panel")
for _, r in ipairs({ { "F", "Toggle fly" }, { "N", "Toggle noclip" }, { "V", "Dash (when enabled)" }, { "C", "Hold to zoom (when enabled)" }, { "G", "Grappling hook (hold)" }, { "J", "Aimbot on/off" }, { "Y", "Quick action wheel" }, { "Ctrl + Click", "Teleport (Click Teleport on)" }, { "Alt + Click", "Hide a part (Click Delete on)" }, { "Shift + Click", "Walk to spot (Click Walk on)" }, { "Ctrl + F", "Jump to the search box" }, { "Right Mouse", "Look around in Freecam" } }) do infoRow(pSet, r[1], r[2]) end
section(pSet, "Server")
do
local srvRow = row(pSet, 84)
X.srvLabel = text(srvRow, { Size = UDim2.new(1, -28, 1, -14), Position = UDim2.fromOffset(14, 8), Text = "", TextSize = 12, TextColor3 = C.muted, TextYAlignment = Enum.TextYAlignment.Top })
end
section(pSet, "Session")
local function resetAll()
for _, fn in ipairs(resetters) do fn() end
X.restoreAll()
workspace.Gravity = DEFAULTS.Gravity
S.walkSpeed, S.jumpPower = nil, nil
local hum = getHum()
if hum then hum.WalkSpeed = DEFAULTS.WalkSpeed hum.JumpPower = DEFAULTS.JumpPower hum.PlatformStand = false end
end
button(pSet, "Reset Window Size & Position", function()
win.Size = UDim2.fromOffset(640, 440)
win.Position = UDim2.fromScale(0.5, 0.5)
toast("Window reset")
end)
button(pSet, "Rebind Toggle Key", function()
rebinding = true
toast("Press a key...  (Esc to cancel)", true)
end)
button(pSet, "Reset All Settings", function()
resetAll()
T.antiafk.set(true, true)
toast("Everything reset")
end)
buttonRow(pSet, {
{ "Rejoin Server", function()
toast("Rejoining...")
local ok = pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player) end)
if not ok then toast("Rejoin failed") end
end },
{ "Destroy Panel", function()
resetAll()
for _, plr in ipairs(Players:GetPlayers()) do clearESP(plr) end
for _, c in ipairs(conns) do c:Disconnect() end
for _, fn in ipairs(X.cleanups) do pcall(fn) end
if X.cc then X.cc:Destroy() end
if X.blur then X.blur:Destroy() end
gui:Destroy()
end },
})
local fpsAcc, fpsFrames, espAcc = 0, 0, 0
connect(RunService.RenderStepped, function(dt)
fpsAcc += dt fpsFrames += 1
if fpsAcc >= 0.5 then
local ping = 0
pcall(function() ping = math.floor(player:GetNetworkPing() * 1000 + 0.5) end)
stats.Text = string.format("%d FPS   •   %d ms", math.floor(fpsFrames / fpsAcc + 0.5), ping)
fpsAcc, fpsFrames = 0, 0
end
if S.rainbow then setAccent(Color3.fromHSV((os.clock() * 0.08) % 1, 0.65, 1)) end
if S.timeLock then Lighting.ClockTime = S.timeLock end
if S.tracers then X.updateTracers() end
if S.freecam then X.stepFreecam(dt) end
for _, fn in ipairs(X.steps) do
local ok, err = pcall(fn, dt)
if not ok and not X.stepWarned[fn] then X.stepWarned[fn] = true warn("[Lockpick] " .. tostring(err)) end
end
if S.looptp then
X.loopAcc = (X.loopAcc or 0) + dt
if X.loopAcc >= 1 / math.max(S.loopSpeed, 0.05) then
X.loopAcc = 0
X.objectTeleport(true)
end
end
if S.flow then
local ov = Vector2.new(((os.clock() * 0.45 * S.animSpeed) % 2) - 1, 0)
for _, g in ipairs(flowGrads) do g.Offset = ov end
end
if S.zoom then
local cam = workspace.CurrentCamera
local target = (UIS:IsKeyDown(Enum.KeyCode.C) and not UIS:GetFocusedTextBox()) and S.zoomFov or (S.fov or DEFAULTS.FOV)
cam.FieldOfView += (target - cam.FieldOfView) * math.min(1, dt * 12)
end
if S.timeFlow then Lighting.ClockTime = (Lighting.ClockTime + dt * S.timeSpeed) % 24 end
if S.inspect then X.stepInspect() end
if S.airwalk then X.stepAirwalk(dt) end
if S.rainbowchar then X.stepRainbow() end
if S.follow or S.orbit then X.stepFollow(dt) end
if X.sw and X.sw.running then X.swUpdate() end
local hum, root = getHum(), getRoot()
if not hum or not root then return end
if S.walkSpeed and hum.WalkSpeed ~= S.walkSpeed then hum.WalkSpeed = S.walkSpeed end
if S.sprint and not S.fly then
local base = S.walkSpeed or DEFAULTS.WalkSpeed
hum.WalkSpeed = (UIS:IsKeyDown(Enum.KeyCode.LeftShift) and not UIS:GetFocusedTextBox()) and base * S.sprintMult or base
end
if S.autowalk and not S.fly then hum:Move(Vector3.new(0, 0, -1), true) end
if S.autojump then hum.Jump = true end
if S.facemouse and not S.spin then
mouse.TargetFilter = getChar()
local hit = mouse.Hit
if hit then
local tp = Vector3.new(hit.Position.X, root.Position.Y, hit.Position.Z)
if (tp - root.Position).Magnitude > 0.5 then root.CFrame = CFrame.lookAt(root.Position, tp) end
end
end
if S.glide then
local v = root.AssemblyLinearVelocity
if v.Y < -S.glideSpeed then root.AssemblyLinearVelocity = Vector3.new(v.X, -S.glideSpeed, v.Z) end
end
if S.bhop and UIS:IsKeyDown(Enum.KeyCode.Space) and not UIS:GetFocusedTextBox() then
hum:ChangeState(Enum.HumanoidStateType.Jumping)
end
if S.antivoid then
if root.Position.Y < workspace.FallenPartsDestroyHeight + 80 and lastSafe then
root.AssemblyLinearVelocity = Vector3.zero
root.CFrame = lastSafe
elseif hum.FloorMaterial ~= Enum.Material.Air then
lastSafe = root.CFrame + Vector3.new(0, 3, 0)
end
end
if S.fly then
local cam = workspace.CurrentCamera.CFrame
local dir = Vector3.zero
if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cam.LookVector end
if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cam.LookVector end
if UIS:IsKeyDown(Enum.KeyCode.D) then dir += cam.RightVector end
if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= cam.RightVector end
if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.yAxis end
if dir.Magnitude == 0 and hum.MoveDirection.Magnitude > 0 then dir = hum.MoveDirection end
if dir.Magnitude > 0 then dir = dir.Unit end
root.AssemblyLinearVelocity = dir * S.flySpeed
end
if S.spin then
root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(S.spinSpeed * dt), 0)
end
end)
connect(RunService.Stepped, function()
if not S.noclip then return end
local c = getChar()
if not c then return end
for _, p in ipairs(c:GetDescendants()) do
if p:IsA("BasePart") then
if noclipCache[p] == nil then noclipCache[p] = p.CanCollide end
p.CanCollide = false
end
end
end)
connect(RunService.Heartbeat, function(dt)
espAcc += dt
if espAcc < 0.25 then return end
espAcc = 0
local root = getRoot()
if root and X.posLabel then
local p = root.Position
X.posLabel.Text = string.format("Position:  %.1f, %.1f, %.1f", p.X, p.Y, p.Z)
end
if X.srvLabel then
X.srvLabel.Text = string.format("Players:  %d / %d\nPlace ID:  %s\nServer:  %s\nSession:  %d:%02d", #Players:GetPlayers(), Players.MaxPlayers, tostring(game.PlaceId), game.JobId ~= "" and string.sub(game.JobId, 1, 20) or "local / studio", math.floor((os.clock() - X.t0) / 60), math.floor(os.clock() - X.t0) % 60)
end
X.updateBodyFx()
for _, fn in ipairs(X.ticks) do pcall(fn) end
if not S.esp or not root then return end
for plr, o in pairs(espObjs) do
local r = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
if r and o.label then
local eh = plr.Character:FindFirstChildOfClass("Humanoid")
o.label.Text = plr.DisplayName .. ((S.espTeamName and plr.Team) and (" [" .. plr.Team.Name .. "]") or "") .. "\n" .. math.floor((r.Position - root.Position).Magnitude) .. " studs" .. (eh and ("  •  " .. math.floor(eh.Health) .. " HP") or "")
end
end
end)
connect(UIS.JumpRequest, function()
if S.infjump then
local hum = getHum()
if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end
end)
connect(player.Idled, function()
if S.antiafk then
pcall(function()
VirtualUser:CaptureController()
VirtualUser:ClickButton2(Vector2.new())
end)
end
end)
connect(player.CharacterAdded, function(char)
local hum = char:WaitForChild("Humanoid", 10)
task.wait()
noclipCache = {}
applyStats()
if S.fly and hum then hum.PlatformStand = true end
if S.freeze and T.freeze then T.freeze.set(false, true) end
end)
local function hookPlayer(plr)
if plr == player then return end
connect(plr.CharacterAdded, function()
task.wait(0.6)
applyESP(plr)
end)
if S.esp then applyESP(plr) end
end
for _, p in ipairs(Players:GetPlayers()) do hookPlayer(p) end
connect(Players.PlayerAdded, function(p) hookPlayer(p) refreshPlayers() end)
connect(Players.PlayerRemoving, function(p)
clearESP(p)
local l = X.tracerLines[p]
if l then l:Destroy() X.tracerLines[p] = nil end
refreshPlayers(p)
end)
refreshPlayers()
REFRESH_WPS()
do
local dragging, dragStart, startPos
header.InputBegan:Connect(function(i)
if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
if not S.lockpos then dragging, dragStart, startPos = true, i.Position, win.Position end
end
end)
connect(UIS.InputChanged, function(i)
if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
local d = i.Position - dragStart
win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
end
end)
connect(UIS.InputEnded, function(i)
if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)
end
local openBtn = new("TextButton", { Size = UDim2.fromOffset(104, 32), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 56), BackgroundColor3 = accent, Text = "LOCKPICK", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.text, AutoButtonColor = false, Visible = false }, gui)
corner(openBtn, 16)
onAccent(function(c) openBtn.BackgroundColor3 = c end)
local opened = true
local function setOpen(v)
opened = v
if v then
win.Visible = true
openBtn.Visible = false
tween(main, { GroupTransparency = S.winAlpha }, 0.2)
tween(shadow, { BackgroundTransparency = 0.86 }, 0.2)
else
tween(main, { GroupTransparency = 1 }, 0.15)
tween(shadow, { BackgroundTransparency = 1 }, 0.15)
task.delay(0.16, function()
if not opened then win.Visible = false openBtn.Visible = true end
end)
end
end
closeBtn.MouseButton1Click:Connect(function() setOpen(false) end)
openBtn.MouseButton1Click:Connect(function() setOpen(true) end)
connect(UIS.InputBegan, function(i, processed)
if rebinding and i.UserInputType == Enum.UserInputType.Keyboard then
rebinding = false
if i.KeyCode ~= Enum.KeyCode.Escape then
TOGGLE_KEY = i.KeyCode
hotkeyPill.Text = TOGGLE_KEY.Name
hintLabel.Text = TOGGLE_KEY.Name .. " to toggle"
toast("Toggle key: " .. TOGGLE_KEY.Name, true)
else
toast("Rebind cancelled", true)
end
return
end
if processed then return end
local kf = X.keys[i.KeyCode]
if kf then kf(i) end
local ub = X.userBinds[i.KeyCode]
if ub and os.clock() - (X.justBound or 0) > 0.15 then X.fireBind(ub) end
if i.UserInputType == Enum.UserInputType.MouseButton1 then
for _, fn in ipairs(X.clicks) do if fn() then return end end
if X.pickMode then
mouse.TargetFilter = nil
local pt = mouse.Target
if pt and pt:IsA("Terrain") then
X.pickMode = nil
mouse.Icon = ""
toast("Can't pick terrain")
else
X.handlePick(pt)
end
return
end
if S.clickwalk and UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
local h = getHum()
mouse.TargetFilter = getChar()
if h and mouse.Hit then h:MoveTo(mouse.Hit.Position) end
end
if S.clickdelete and UIS:IsKeyDown(Enum.KeyCode.LeftAlt) then
local t = mouse.Target
local ch = getChar()
if t and t:IsA("BasePart") and not t:IsA("Terrain") and not (ch and t:IsDescendantOf(ch)) then X.hidePart(t) end
end
if S.clicktp and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
local root = getRoot()
if root then
mouse.TargetFilter = getChar()
local hit = mouse.Hit
if hit then root.CFrame = CFrame.new(hit.Position + Vector3.new(0, 3, 0)) end
end
end
elseif i.KeyCode == TOGGLE_KEY then
setOpen(not opened)
elseif i.KeyCode == Enum.KeyCode.F and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
setOpen(true)
task.spawn(function()
RunService.RenderStepped:Wait()
searchBox:CaptureFocus()
end)
elseif i.KeyCode == Enum.KeyCode.V and S.dash then
local root, hum = getRoot(), getHum()
if root and hum then
local dir = hum.MoveDirection.Magnitude > 0 and hum.MoveDirection or root.CFrame.LookVector
root.AssemblyLinearVelocity = Vector3.new(dir.X, 0.15, dir.Z).Unit * S.dashForce
end
elseif i.KeyCode == Enum.KeyCode.F then
T.fly.set(not S.fly)
elseif i.KeyCode == Enum.KeyCode.N then
T.noclip.set(not S.noclip)
end
end)
do
-- ===== Aimbot =====
S.aimTrig, S.aimPart, S.aimPrio = "rmb", "Head", 1
local aimRP = RaycastParams.new()
aimRP.FilterType = Enum.RaycastFilterType.Exclude
local aimRing = new("Frame", { Size = UDim2.fromOffset(300, 300), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Visible = false, ZIndex = 0 }, gui)
new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, aimRing)
local aimRS = stroke(aimRing, accent, 1.5, 0.2)
onAccent(function(c) aimRS.Color = c end)
local aimDot = new("Frame", { Size = UDim2.fromOffset(8, 8), AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Visible = false, ZIndex = 0 }, gui)
new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, aimDot)
onAccent(function(c) aimDot.BackgroundColor3 = c end)
local aimLead = new("Frame", { Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Visible = false, ZIndex = 0 }, gui)
new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, aimLead)
stroke(aimLead, Color3.fromRGB(255, 200, 80), 2, 0)
local aimHB = new("Frame", { Size = UDim2.fromOffset(220, 36), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 96), BackgroundColor3 = C.bg, BackgroundTransparency = 0.3, BorderSizePixel = 0, Visible = false, ZIndex = 0 }, gui)
corner(aimHB, 8)
local aimHN = text(aimHB, { Size = UDim2.new(1, -16, 0, 16), Position = UDim2.fromOffset(8, 3), TextSize = 12, Font = Enum.Font.GothamBold })
local aimHF = new("Frame", { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0 }, new("Frame", { Size = UDim2.new(1, -16, 0, 6), Position = UDim2.fromOffset(8, 24), BackgroundColor3 = C.hover, BorderSizePixel = 0 }, aimHB))
local aimTL = text(aimDot, { Size = UDim2.fromOffset(140, 14), Position = UDim2.new(0.5, -70, 1, 3), TextSize = 11, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.4 })
local npcs, npcTk = {}, 0
table.insert(X.ticks, function()
npcTk += 1
if not S.aimNpc or npcTk % 4 ~= 0 then return end
npcs = {}
for _, h in ipairs(workspace:GetDescendants()) do
if h:IsA("Humanoid") and h.Parent:IsA("Model") and not Players:GetPlayerFromCharacter(h.Parent) and h.Parent ~= getChar() then npcs[#npcs + 1] = h.Parent end
end
end)
local function pickPart(c, cam, origin)
local m = S.aimPart
if m == "Head" then return c:FindFirstChild("Head") end
if m == "Torso" then return c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso") end
if m == "Root" then return c:FindFirstChild("HumanoidRootPart") end
local best, bd
for _, n in ipairs({ "Head", "UpperTorso", "Torso", "HumanoidRootPart" }) do
local p = c:FindFirstChild(n)
if p then
local v = cam:WorldToViewportPoint(p.Position)
local d = (Vector2.new(v.X, v.Y) - origin).Magnitude
if v.Z > 0 and (not bd or d < bd) then best, bd = p, d end
end
end
return best
end
local function eval(c, plr, cam, origin)
local hum = c:FindFirstChildOfClass("Humanoid")
if not hum or hum.Health <= 0 then return end
if S.aimFF and c:FindFirstChildOfClass("ForceField") then return end
if S.aimTeam and plr and player.Team and plr.Team == player.Team then return end
if plr and X.rel and X.rel[plr.UserId] == "friend" then return end
local part = pickPart(c, cam, origin)
if not part then return end
local cp = cam.CFrame.Position
local dist = (part.Position - cp).Magnitude
if dist > S.aimDist then return end
local v = cam:WorldToViewportPoint(part.Position)
if v.Z <= 0 then return end
local sd = (Vector2.new(v.X, v.Y) - origin).Magnitude
if sd > S.aimFov then return end
if S.aimVis then
aimRP.FilterDescendantsInstances = { getChar(), c }
if workspace:Raycast(cp, part.Position - cp, aimRP) then return end
end
return part, (S.aimPrio == 1 and sd) or (S.aimPrio == 2 and dist) or hum.Health
end
local function ang(d) return math.atan2(-d.X, -d.Z), math.asin(math.clamp(d.Y, -1, 1)) end
local function aimStep(dt)
local cam = workspace.CurrentCamera
local origin = S.aimCenter and cam.ViewportSize / 2 or UIS:GetMouseLocation()
aimRing.Visible = (S.aim and S.aimShowFov) == true
aimRing.Size = UDim2.fromOffset(S.aimFov * 2, S.aimFov * 2)
aimRing.Position = UDim2.fromOffset(origin.X, origin.Y)
aimDot.Visible = false
aimLead.Visible = false
aimHB.Visible = false
if not S.aim or S.freecam or X.photoOn then X.aimTarget = nil return end
local held = S.aimTrig == "always" or (S.aimTrig == "rmb" and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)) or (S.aimTrig == "lmb" and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1))
if not held or UIS:GetFocusedTextBox() then X.aimTarget = nil return end
local tc
if S.aimSticky and X.aimTarget and X.aimTarget.Parent and eval(X.aimTarget, Players:GetPlayerFromCharacter(X.aimTarget), cam, origin) then tc = X.aimTarget end
if not tc then
local bs
for _, p in ipairs(Players:GetPlayers()) do
if p ~= player and p.Character and (not (S.aimOnly and X.aimPlayer) or p == X.aimPlayer) then
local part, sc = eval(p.Character, p, cam, origin)
if part and (not bs or sc < bs) then tc, bs = p.Character, sc end
end
end
if S.aimNpc and not (S.aimOnly and X.aimPlayer) then
for _, m in ipairs(npcs) do
if m.Parent then
local part, sc = eval(m, nil, cam, origin)
if part and (not bs or sc < bs) then tc, bs = m, sc end
end
end
end
end
X.aimTarget = tc
if not tc then return end
local th = S.aimHP and tc:FindFirstChildOfClass("Humanoid")
if th then
local pc = math.clamp(th.Health / math.max(th.MaxHealth, 1), 0, 1)
aimHB.Visible = true
aimHN.Text = tc.Name .. "  " .. math.floor(th.Health) .. " / " .. math.floor(th.MaxHealth)
aimHF.Size = UDim2.fromScale(pc, 1)
aimHF.BackgroundColor3 = Color3.fromRGB(255, 70, 70):Lerp(Color3.fromRGB(70, 230, 120), pc)
end
local part = pickPart(tc, cam, origin)
if not part then return end
local camPos = cam.CFrame.Position
local pos = part.Position + Vector3.new(0, S.aimOffY, 0)
if S.aimPredict then pos += part.AssemblyLinearVelocity * ((pos - camPos).Magnitude / math.max(S.aimBullet, 1)) * S.aimPredAmt end
if S.aimJitter > 0 then
local j = S.aimJitter * 0.1
pos += Vector3.new((math.random() - 0.5) * j, (math.random() - 0.5) * j, (math.random() - 0.5) * j)
end
local v = cam:WorldToViewportPoint(pos)
if S.aimShowTarget then
local av = cam:WorldToViewportPoint(part.Position)
aimDot.Visible = true
aimDot.Position = UDim2.fromOffset(av.X, av.Y)
aimTL.Text = tc.Name .. "  " .. math.floor((pos - camPos).Magnitude)
end
if S.aimLead and S.aimPredict then
aimLead.Visible = true
aimLead.Position = UDim2.fromOffset(v.X, v.Y)
end
if (Vector2.new(v.X, v.Y) - origin).Magnitude <= S.aimDead then return end
local cy, cpt = ang(cam.CFrame.LookVector)
local ty, tpt = ang((pos - camPos).Unit)
local a = S.aimSpeed >= 100 and 1 or math.clamp(dt * S.aimSpeed, 0, 1)
local dy = (ty - cy + math.pi) % (2 * math.pi) - math.pi
local ny = cy + (S.aimLockYaw and 0 or dy * a)
local np = cpt + (S.aimLockPitch and 0 or (tpt - cpt) * a)
local look = Vector3.new(-math.sin(ny) * math.cos(np), math.sin(np), -math.cos(ny) * math.cos(np))
cam.CFrame = CFrame.lookAt(camPos, camPos + look)
end
local aimWarned = false
RunService:BindToRenderStep("LockpickAim", Enum.RenderPriority.Camera.Value + 2, function(dt)
local ok, err = pcall(aimStep, dt)
if not ok and not aimWarned then aimWarned = true warn("[Lockpick] aim: " .. tostring(err)) end
end)
table.insert(X.cleanups, function() pcall(function() RunService:UnbindFromRenderStep("LockpickAim") end) end)
local function setv(k, v, label) return function() S[k] = v toast(label) end end
section(pAim, "Aimbot")
flags(pAim, { { "Aimbot", "Master switch (hotkey J)", "aim" }, { "Show FOV Circle", nil, "aimShowFov" }, { "Show Target Marker", nil, "aimShowTarget" } })
section(pAim, "Activation")
buttonRow(pAim, { { "Right Mouse", setv("aimTrig", "rmb", "Aim while holding right mouse"), true }, { "Left Mouse", setv("aimTrig", "lmb", "Aim while holding left mouse") }, { "Always On", setv("aimTrig", "always", "Aim always on") } })
section(pAim, "Target Part")
buttonRow(pAim, { { "Head", setv("aimPart", "Head", "Aiming at head"), true }, { "Torso", setv("aimPart", "Torso", "Aiming at torso") }, { "Root", setv("aimPart", "Root", "Aiming at root") }, { "Closest Part", setv("aimPart", "Closest", "Aiming at the part nearest your cursor") } })
section(pAim, "Target Priority")
buttonRow(pAim, { { "Closest to Cursor", setv("aimPrio", 1, "Priority: closest to cursor"), true }, { "Closest Distance", setv("aimPrio", 2, "Priority: closest distance") }, { "Lowest Health", setv("aimPrio", 3, "Priority: lowest health") } })
section(pAim, "Filters")
flags(pAim, { { "Team Check", "Ignore teammates", "aimTeam" }, { "Visible Check", "Only targets in line of sight", "aimVis" }, { "Include NPCs", "Also target dummies and NPCs", "aimNpc" }, { "Ignore ForceField", "Skip protected players", "aimFF" }, { "Sticky Target", "Stay on one target while aiming", "aimSticky" }, { "Aim From Screen Center", "FOV circle at screen center, not cursor", "aimCenter" } })
section(pAim, "Axes")
flags(pAim, { { "Lock Horizontal", "Don't move the camera left/right", "aimLockYaw" }, { "Lock Vertical", "Don't move the camera up/down", "aimLockPitch" } })
section(pAim, "Tuning")
binds(pAim, { { "FOV Radius", 10, 800, "aimFov", 150 }, { "Aim Speed (100 = snap)", 1, 100, "aimSpeed", 40 }, { "Max Distance", 50, 3000, "aimDist", 600 }, { "Deadzone (px)", 0, 60, "aimDead", 2 }, { "Aim Height Offset", -3, 3, "aimOffY", 0, 1 }, { "Humanize (jitter)", 0, 10, "aimJitter", 0, 1 } })
section(pAim, "Prediction")
flags(pAim, { { "Prediction", "Lead moving targets", "aimPredict" } })
binds(pAim, { { "Prediction Strength", 0, 3, "aimPredAmt", 1, 1 }, { "Projectile Speed", 50, 3000, "aimBullet", 600 } })
flags(pAim, { { "Lead Marker", "Ring at the predicted aim point", "aimLead" }, { "Target Health Bar", "Locked target's health on screen", "aimHP" } })
X.keys[Enum.KeyCode.J] = function() if T.aim then T.aim.set(not S.aim) end end
X.keys[Enum.KeyCode.T] = function() X.aimTarget = nil toast("Re-targeting") end
function X.plist(page, btns)
local box = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = nextOrder(page) }, page)
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, box)
local sig
local function refresh(force)
local list, names = {}, {}
for _, p in ipairs(Players:GetPlayers()) do if p ~= player then list[#list + 1] = p names[#names + 1] = p.Name .. p.DisplayName end end
local s2 = table.concat(names, ",")
if not force and s2 == sig then return end
sig = s2
clearList(box)
local w = #btns * 54 + 30
for n, p in ipairs(list) do
local r = row(box, 42, n)
text(r, { Size = UDim2.new(1, -w, 0, 18), Position = UDim2.fromOffset(14, 5), Text = p.DisplayName, Font = Enum.Font.GothamMedium, TextTruncate = Enum.TextTruncate.AtEnd })
text(r, { Size = UDim2.new(1, -w, 0, 14), Position = UDim2.fromOffset(14, 23), Text = "@" .. p.Name, TextSize = 11, TextColor3 = C.muted, TextTruncate = Enum.TextTruncate.AtEnd })
for i, b in ipairs(btns) do miniButton(r, b[1], 12 + (#btns - i) * 54, function() b[2](p) end, i == 1) end
end
if #list == 0 then
local r = row(box, 38, 1)
text(r, { Size = UDim2.new(1, -28, 1, 0), Position = UDim2.fromOffset(14, 0), Text = "No other players in this server", TextColor3 = C.muted, TextSize = 13 })
end
end
refresh(true)
table.insert(X.ticks, function() refresh(false) end)
connect(Players.PlayerAdded, function() task.defer(refresh, true) end)
connect(Players.PlayerRemoving, function() task.delay(0.15, refresh, true) end)
end
function X.setAimPlayer(p)
X.aimPlayer = p
if p and T.aimOnly and not S.aimOnly then T.aimOnly.set(true, true) end
if X.aimLabel then X.aimLabel.Text = p and ("Aim target:  " .. p.DisplayName .. "  (@" .. p.Name .. ")") or "Aim target:  none  (aims at anyone)" end
if p then toast("Aimbot target: " .. p.DisplayName) end
end
connect(Players.PlayerRemoving, function(p) if p == X.aimPlayer then X.setAimPlayer(nil) if T.aimOnly then T.aimOnly.set(false, true) end end end)
section(pPInfo, "Players  (pick one)")
X.plist(pPInfo, { { "Info", function(p) X.infoTarget = p X.updateInfo() end }, { "TP", tpTo }, { "View", spectate }, { "Fling", function(p) X.flingPlayer(p) end }, { "Aim", X.setAimPlayer } })
section(pAim, "Player Target")
X.aimLabel = lrow(pAim, 30, "aimbot player target selected")
X.setAimPlayer(nil)
flags(pAim, { { "Only Target Selected Player", "Ignore everyone except the chosen player", "aimOnly" } })
button(pAim, "Clear Target Player", function() X.setAimPlayer(nil) if T.aimOnly then T.aimOnly.set(false, true) end end)
X.plist(pAim, { { "Target", X.setAimPlayer } })
section(pFun, "Fling a Player")
X.plist(pFun, { { "Fling", function(p) X.flingPlayer(p) end } })
do
X.teamOff = {}
local Teams = game:GetService("Teams")
section(pEsp, "Team Viewer")
flags(pEsp, { { "Show Team Names", "Add [Team] to ESP labels", "espTeamName" } })
local tvBox = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = nextOrder(pEsp) }, pEsp)
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, tvBox)
local tvSig
local function tvRefresh()
local groups, order = {}, {}
local function grp(t)
local k = t or "none"
if not groups[k] then groups[k] = { team = t, names = {} } order[#order + 1] = k end
return groups[k]
end
for _, t in ipairs(Teams:GetTeams()) do grp(t) end
for _, p in ipairs(Players:GetPlayers()) do table.insert(grp(p.Team).names, p.DisplayName .. (p == player and " (you)" or "")) end
local sig = {}
for _, k in ipairs(order) do
local g = groups[k]
sig[#sig + 1] = (g.team and g.team.Name or "Neutral") .. #g.names .. table.concat(g.names, ",") .. tostring(g.team and X.teamOff[g.team])
end
sig = table.concat(sig, "|")
if sig == tvSig then return end
tvSig = sig
clearList(tvBox)
for i, k in ipairs(order) do
local g = groups[k]
local r = row(tvBox, 56, i)
corner(new("Frame", { Size = UDim2.fromOffset(6, 40), Position = UDim2.fromOffset(10, 8), BackgroundColor3 = g.team and g.team.TeamColor.Color or C.muted, BorderSizePixel = 0 }, r), 3)
text(r, { Size = UDim2.new(1, -150, 0, 18), Position = UDim2.fromOffset(24, 6), Text = (g.team and g.team.Name or "Neutral") .. "  (" .. #g.names .. ")", Font = Enum.Font.GothamMedium, TextTruncate = Enum.TextTruncate.AtEnd })
text(r, { Size = UDim2.new(1, -150, 0, 28), Position = UDim2.fromOffset(24, 25), Text = #g.names > 0 and table.concat(g.names, ", ") or "no players", TextSize = 11, TextColor3 = C.muted, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, TextTruncate = Enum.TextTruncate.AtEnd })
if g.team then
local off = X.teamOff[g.team]
miniButton(r, off and "ESP off" or "ESP on", 12, function()
X.teamOff[g.team] = not X.teamOff[g.team] or nil
if S.esp then setESP(true) end
tvSig = nil
tvRefresh()
end, not off)
end
end
end
tvRefresh()
table.insert(X.ticks, tvRefresh)
end
do
local kf = new("Frame", { Size = UDim2.fromOffset(240, 0), AutomaticSize = Enum.AutomaticSize.Y, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 56), BackgroundTransparency = 1, ZIndex = 0 }, gui)
new("UIListLayout", { Padding = UDim.new(0, 4), HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder }, kf)
local kn = 0
local function feed(msg)
if not S.killfeed then return end
kn += 1
local f = new("Frame", { Size = UDim2.fromOffset(236, 24), BackgroundColor3 = C.bg, BackgroundTransparency = 0.25, BorderSizePixel = 0, LayoutOrder = kn }, kf)
corner(f, 6)
text(f, { Size = UDim2.new(1, -12, 1, 0), Position = UDim2.fromOffset(8, 0), Text = msg, TextSize = 12, Font = Enum.Font.GothamMedium, TextTruncate = Enum.TextTruncate.AtEnd })
task.delay(6, function() if f.Parent then f:Destroy() end end)
end
local function deathHook(plr)
local function onChar(c)
local h = c:WaitForChild("Humanoid", 10)
if not h then return end
h.Died:Connect(function()
local tag = h:FindFirstChild("creator")
local k = tag and tag.Value
local killer = typeof(k) == "Instance" and k:IsA("Player") and k ~= plr and k.DisplayName
feed((killer and (killer .. "  >  ") or "") .. plr.DisplayName .. (killer and "" or " died"))
end)
end
if plr.Character then task.spawn(onChar, plr.Character) end
connect(plr.CharacterAdded, onChar)
end
for _, p in ipairs(Players:GetPlayers()) do deathHook(p) end
connect(Players.PlayerAdded, deathHook)
local tags, alerted = {}, {}
local pb = new("Sound", { SoundId = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.7 }, gui)
table.insert(X.ticks, function()
local r = getRoot()
for _, p in ipairs(Players:GetPlayers()) do
local c = p ~= player and p.Character
local head, pr = c and c:FindFirstChild("Head"), c and c:FindFirstChild("HumanoidRootPart")
local ok = not X.espAllowed or X.espAllowed(p)
local t = tags[p]
if S.nametags and head and ok then
if not t or t.bb.Parent ~= head then
if t then t.bb:Destroy() end
local bb = new("BillboardGui", { Adornee = head, AlwaysOnTop = true, Size = UDim2.fromOffset(170, 38), StudsOffset = Vector3.new(0, 5.4, 0) }, head)
t = { bb = bb, l = text(bb, { Size = UDim2.fromScale(1, 1), TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.3 }) }
tags[p] = t
end
local h, tool = c:FindFirstChildOfClass("Humanoid"), c:FindFirstChildOfClass("Tool")
t.l.TextColor3 = X.relCol(p) or (p.Team and p.TeamColor.Color or Color3.new(1, 1, 1))
t.l.Text = p.DisplayName .. "\n@" .. p.Name .. (tool and ("  •  " .. tool.Name) or "") .. (h and ("  •  " .. math.floor(h.Health) .. " HP") or "")
elseif t then
t.bb:Destroy()
tags[p] = nil
end
if S.prox and r and pr and ok then
local d = (pr.Position - r.Position).Magnitude
if d <= S.proxDist then
if not alerted[p] then alerted[p] = true toast(p.DisplayName .. " is " .. math.floor(d) .. " studs away", true) pb:Play() end
elseif d > S.proxDist * 1.15 then alerted[p] = nil end
end
end
for p, t in pairs(tags) do if not p.Parent then t.bb:Destroy() tags[p] = nil end end
end)
table.insert(X.cleanups, function() for _, t in pairs(tags) do t.bb:Destroy() end end)
flags(pHud, { { "Kill Feed", "Show kills and deaths on screen", "killfeed" } })
flags(pEsp, { { "Nametags", "Info tags over player heads", "nametags" }, { "Proximity Alert", "Warn when a player gets close", "prox" } })
binds(pEsp, { { "Alert Distance", 10, 300, "proxDist", 40 } })
local wheel = new("Frame", { Size = UDim2.fromOffset(340, 340), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Visible = false, ZIndex = 80 }, gui)
local wlist = "fly, noclip, player esp, tracers, aimbot, freecam, bunny hop, back"
local function build()
for _, c in ipairs(wheel:GetChildren()) do c:Destroy() end
local items = {}
for w in wlist:gmatch("[^,]+") do items[#items + 1] = w:match("^%s*(.-)%s*$") end
local n = math.min(#items, 12)
for i = 1, n do
local a = (i - 1) / n * math.pi * 2 - math.pi / 2
local b = makeButton(wheel, items[i], function() wheel.Visible = false X.runCommand(items[i]) end, i == 1, UDim2.fromOffset(100, 34), 0)
b.AnchorPoint = Vector2.new(0.5, 0.5)
b.Position = UDim2.new(0.5, math.cos(a) * 130, 0.5, math.sin(a) * 130)
b.ZIndex = 81
end
local x = makeButton(wheel, "Close", function() wheel.Visible = false end, false, UDim2.fromOffset(60, 60), 0)
x.AnchorPoint = Vector2.new(0.5, 0.5)
x.Position = UDim2.fromScale(0.5, 0.5)
x.ZIndex = 81
corner(x, 30)
end
X.keys[Enum.KeyCode.Y] = function()
if wheel.Visible then wheel.Visible = false else build() wheel.Visible = true end
end
section(pSet, "Quick Actions")
button(pSet, "Open Quick Action Wheel  (Y)", X.keys[Enum.KeyCode.Y])
irow(pSet, "fly, noclip, player esp, ...", "Set Wheel", function(q)
if q:match("%S") then wlist = q build() toast("Wheel updated") end
end, "quick action wheel actions list")
end
local AS = { "Freefall", "Jumping", "Running", "RunningNoPhysics", "Landed", "GettingUp", "FallingDown", "Climbing" }
local function aw(h, on) for _, t in ipairs(AS) do h:SetStateEnabled(Enum.HumanoidStateType[t], on) end end
table.insert(X.steps, function()
if not S.airswim or S.fly or S.freecam then return end
local h, r, SW = getHum(), getRoot(), Enum.HumanoidStateType.Swimming
if not h or not r then return end
if h:GetStateEnabled(Enum.HumanoidStateType.Freefall) then aw(h, false) end
if h:GetState() ~= SW then h:ChangeState(SW) end
local cf = workspace.CurrentCamera.CFrame
local d = Vector3.zero
if UIS:IsKeyDown(Enum.KeyCode.W) then d += cf.LookVector end
if UIS:IsKeyDown(Enum.KeyCode.S) then d -= cf.LookVector end
if UIS:IsKeyDown(Enum.KeyCode.D) then d += cf.RightVector end
if UIS:IsKeyDown(Enum.KeyCode.A) then d -= cf.RightVector end
if UIS:IsKeyDown(Enum.KeyCode.Space) then d += Vector3.yAxis end
if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then d -= Vector3.yAxis end
if d.Magnitude == 0 and h.MoveDirection.Magnitude > 0 then d = h.MoveDirection end
if d.Magnitude > 0 then
d = d.Unit
local fl = Vector3.new(d.X, 0, d.Z)
if fl.Magnitude > 0.1 then r.CFrame = CFrame.lookAt(r.Position, r.Position + fl) end
end
r.AssemblyLinearVelocity = d * S.airSwimSpeed
end)
section(pMove, "Swimming in Air")
X.fb(pMove, "Air Swim", "Real swimming, in the air", "airswim", "Air Swim Speed", 10, 200, "airSwimSpeed", 16, nil, function(v)
if v and S.fly and T.fly then T.fly.set(false, true) end
if not v then
local h = getHum()
if h then aw(h, true) h:ChangeState(Enum.HumanoidStateType.Freefall) end
end
end)
do
local rpp = RaycastParams.new()
rpp.FilterType = Enum.RaycastFilterType.Exclude
function X.go(root, cf)
if S.smoothtp then tween(root, { CFrame = cf }, 0.45) else root.CFrame = cf end
end
X.rel = {}
function X.relCol(p)
local k = X.rel[p.UserId]
return k == "friend" and Color3.fromRGB(80, 230, 130) or k == "enemy" and Color3.fromRGB(255, 70, 70) or nil
end
local function mark(k) return function(p)
X.rel[p.UserId] = X.rel[p.UserId] ~= k and k or nil
toast(p.DisplayName .. ": " .. (X.rel[p.UserId] or "neutral"))
if S.esp then setESP(true) end
end end
table.insert(X.steps, function(dt)
local h, r = getHum(), getRoot()
if not h or not r or S.fly or S.freecam then return end
rpp.FilterDescendantsInstances = { getChar() }
local v = r.AssemblyLinearVelocity
local air = h.FloorMaterial == Enum.Material.Air
if S.softland and air and v.Y < -40 and workspace:Raycast(r.Position, Vector3.new(0, v.Y * 0.12, 0), rpp) then
r.AssemblyLinearVelocity = Vector3.new(v.X, -12, v.Z)
end
local md = h.MoveDirection
if S.airstrafe and air and md.Magnitude > 0 then
local flat = Vector3.new(v.X, 0, v.Z)
if flat.Magnitude > 4 then
local d = flat.Unit:Lerp(md, math.min(1, dt * 4))
if d.Magnitude > 0.01 then d = d.Unit * flat.Magnitude r.AssemblyLinearVelocity = Vector3.new(d.X, v.Y, d.Z) end
end
end
if S.mantle and air and md.Magnitude > 0 and v.Y < 20 then
local l = r.CFrame.LookVector * 3
if workspace:Raycast(r.Position, l, rpp) and not workspace:Raycast(r.Position + Vector3.new(0, 4, 0), l, rpp) then
r.AssemblyLinearVelocity = Vector3.new(v.X, 38, v.Z)
end
end
end)
table.insert(X.steps, function()
if not S.antifling then return end
for _, p in ipairs(Players:GetPlayers()) do
local c = p ~= player and p.Character
if c then for _, q in ipairs(c:GetChildren()) do if q:IsA("BasePart") then q.CanCollide = false end end end
end
local r = getRoot()
if r and not S.fly and not S.touchfling and not X.flinging and r.AssemblyLinearVelocity.Magnitude > 600 then
r.AssemblyLinearVelocity = Vector3.zero
r.AssemblyAngularVelocity = Vector3.zero
end
end)
local clickAcc = 0
table.insert(X.steps, function(dt)
if not (S.autoclick or (S.autofire and X.aimTarget)) then return end
clickAcc += dt
if clickAcc >= 1 / S.cps then
clickAcc = 0
local c = getChar()
local tool = c and c:FindFirstChildOfClass("Tool")
if tool then tool:Activate() end
end
end)
local itk = 0
table.insert(X.ticks, function()
itk += 1
local r = getRoot()
if not S.autointeract or not r or itk % 4 ~= 0 then return end
for _, d in ipairs(workspace:GetDescendants()) do
if d:IsA("ProximityPrompt") and d.Enabled then
local p = d.Parent
local pos = p:IsA("BasePart") and p.Position or (p:IsA("Attachment") and p.WorldPosition)
if pos and (pos - r.Position).Magnitude <= d.MaxActivationDistance then
d:InputHoldBegin()
task.delay(d.HoldDuration + 0.05, function() d:InputHoldEnd() end)
end
end
end
end)
local function dmgHook(plr)
local function onChar(c)
local h = c:WaitForChild("Humanoid", 10)
if not h then return end
local last = h.Health
h.HealthChanged:Connect(function(n)
local d = last - n
last = n
if d < 0.5 then return end
if plr == player then
if S.lasthit then
local tag = h:FindFirstChild("creator")
local k = tag and tag.Value
toast("-" .. math.floor(d) .. " HP" .. ((typeof(k) == "Instance" and k:IsA("Player")) and (" from " .. k.DisplayName) or ""), true)
end
elseif S.dmgnums then
local hd = c:FindFirstChild("Head")
if hd then
local bb = new("BillboardGui", { Adornee = hd, AlwaysOnTop = true, Size = UDim2.fromOffset(60, 24), StudsOffset = Vector3.new((math.random() - 0.5) * 2, 3, 0) }, hd)
text(bb, { Size = UDim2.fromScale(1, 1), Text = "-" .. math.floor(d), TextColor3 = Color3.fromRGB(255, 90, 90), Font = Enum.Font.GothamBlack, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.3 })
tween(bb, { StudsOffset = bb.StudsOffset + Vector3.new(0, 3, 0) }, 0.9)
task.delay(0.9, function() bb:Destroy() end)
end
end
end)
end
if plr.Character then task.spawn(onChar, plr.Character) end
connect(plr.CharacterAdded, onChar)
end
for _, p in ipairs(Players:GetPlayers()) do dmgHook(p) end
connect(Players.PlayerAdded, dmgHook)
local function cycleAim(dir)
local list = {}
for _, p in ipairs(Players:GetPlayers()) do if p ~= player then list[#list + 1] = p end end
if #list == 0 then return toast("No other players") end
X.setAimPlayer(list[((table.find(list, X.aimPlayer) or 0) - 1 + dir) % #list + 1])
end
X.keys[Enum.KeyCode.Comma] = function() cycleAim(-1) end
X.keys[Enum.KeyCode.Period] = function() cycleAim(1) end
X.keys[Enum.KeyCode.End] = function()
resetAll()
setOpen(false)
toast("Panic: everything off", true)
end
section(pMove, "Movement Helpers")
flags(pMove, { { "Soft Landing", "Slows you just before the ground", "softland" }, { "Air Strafe", "Steer your momentum in mid-air", "airstrafe" }, { "Auto Mantle", "Pull up ledges you jump at", "mantle" } })
section(pTp, "Teleport Options")
flags(pTp, { { "Smooth Teleport", "Glide to players instead of snapping", "smoothtp" } })
section(pTools, "Utilities")
flags(pTools, { { "Anti-Fling", "Other players can't push or fling you", "antifling" }, { "Auto Clicker", "Clicks your equipped tool", "autoclick" }, { "Auto Interact", "Holds nearby proximity prompts", "autointeract" } })
binds(pTools, { { "Clicks per Second", 1, 30, "cps", 10 } })
button(pTools, "Equip Next Tool", function()
local h, bp = getHum(), player:FindFirstChild("Backpack")
local t = bp and bp:GetChildren()[1]
if h and t then h:EquipTool(t) else toast("No tools in backpack") end
end)
button(pSet, "Panic: everything off  (End)", X.keys[Enum.KeyCode.End])
flags(pAim, { { "Auto Fire", "Clicks your tool while locked on", "autofire" } })
flags(pHud, { { "Damage Numbers", "Floating damage over players", "dmgnums" }, { "Hit Alerts", "Tell me who damaged me", "lasthit" } })
section(pPInfo, "Friends & Enemies  (green / red ESP)")
X.plist(pPInfo, { { "Friend", mark("friend") }, { "Enemy", mark("enemy") } })
end
do
local PFS = game:GetService("PathfindingService")
local walkId = 0
function X.walkTo(pos)
local h, r = getHum(), getRoot()
if not h or not r then return end
walkId += 1
local id = walkId
local path = PFS:CreatePath({ AgentCanJump = true })
local ok = pcall(function() path:ComputeAsync(r.Position, pos) end)
if not ok or path.Status ~= Enum.PathStatus.Success then return toast("No path found") end
toast("Walking...")
task.spawn(function()
for _, w in ipairs(path:GetWaypoints()) do
if id ~= walkId then return end
if w.Action == Enum.PathWaypointAction.Jump then h.Jump = true end
h:MoveTo(w.Position)
h.MoveToFinished:Wait()
end
end)
end
section(pPInfo, "Walk  (pathfinding)")
X.plist(pPInfo, { { "Walk", function(p) local rr = p.Character and p.Character:FindFirstChild("HumanoidRootPart") if rr then X.walkTo(rr.Position) end end } })
buttonRow(pPInfo, { { "Walk to Destination", function()
local o = X.objDst
if o and o.Parent then X.walkTo(o:IsA("Model") and o:GetPivot().Position or o.Position) else toast("Pick a destination object first") end
end }, { "Stop Walking", function() walkId += 1 end } })
section(pPInfo, "Join / Leave Log")
local jl, watch = {}, {}
local jlab = lrow(pPInfo, 110, "join leave log players watch")
jlab.Text = "No joins or leaves yet"
local function jlog(p, joined)
table.insert(jl, 1, os.date("%H:%M:%S") .. (joined and "  + " or "  - ") .. p.DisplayName .. " (@" .. p.Name .. ")" .. (joined and ("  age " .. p.AccountAge .. "d") or ""))
if #jl > 8 then table.remove(jl) end
jlab.Text = table.concat(jl, "\n")
if joined and watch[string.lower(p.Name)] then toast("Watched player joined: " .. p.DisplayName, true) end
end
connect(Players.PlayerAdded, function(p) jlog(p, true) end)
connect(Players.PlayerRemoving, function(p) jlog(p, false) end)
irow(pPInfo, "Watch username (alert on join)...", "Watch", function(q)
q = q:match("^%s*(.-)%s*$")
if q ~= "" then watch[string.lower(q)] = true toast("Watching " .. q) end
end, "watch username alert join")
local st, lastPos = { 0, 0, 0 }, nil
table.insert(X.steps, function()
local r = getRoot()
if r then
if lastPos and (r.Position - lastPos).Magnitude < 40 then st[1] += (r.Position - lastPos).Magnitude end
lastPos = r.Position
else
lastPos = nil
end
end)
connect(UIS.JumpRequest, function() st[2] += 1 end)
local function deathWatch(c)
local h = c:WaitForChild("Humanoid", 10)
if h then h.Died:Connect(function() st[3] += 1 end) end
end
if player.Character then task.spawn(deathWatch, player.Character) end
connect(player.CharacterAdded, deathWatch)
section(pSet, "Session Stats")
local sl = lrow(pSet, 52, "session stats distance jumps deaths time")
table.insert(X.ticks, function()
local t = os.clock() - X.t0
sl.Text = string.format("Time %d:%02d  •  Distance %d studs\nJumps %d  •  Deaths %d", math.floor(t / 60), math.floor(t) % 60, math.floor(st[1]), st[2], st[3])
end)
local beac = {}
local function clearBeac() for k, bc in pairs(beac) do bc:Destroy() beac[k] = nil end end
table.insert(X.ticks, function()
if not S.beacons then if next(beac) then clearBeac() end return end
local r, alive = getRoot(), {}
for _, w in ipairs(WAYPOINTS) do
alive[w] = true
local bc = beac[w]
if not bc or not bc.Parent then
bc = new("Part", { Name = "LockpickBeacon", Anchored = true, CanCollide = false, CanQuery = false, Transparency = 1, Size = Vector3.one }, workspace)
text(new("BillboardGui", { AlwaysOnTop = true, Size = UDim2.fromOffset(130, 24), StudsOffset = Vector3.new(0, 4, 0) }, bc), { Name = "L", Size = UDim2.fromScale(1, 1), Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = accent, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.3 })
beac[w] = bc
end
bc.Position = w.cf.Position
bc.BillboardGui.L.Text = w.name .. (r and ("  " .. math.floor((w.cf.Position - r.Position).Magnitude)) or "")
end
for k, bc in pairs(beac) do if not alive[k] then bc:Destroy() beac[k] = nil end end
end)
table.insert(X.cleanups, clearBeac)
flags(pTp, { { "Waypoint Beacons", "Show saved waypoints in the world", "beacons" } })
local recent = {}
text(pFav, { Size = UDim2.new(1, 0, 0, 26), Text = "RECENTLY USED", Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = C.muted, TextYAlignment = Enum.TextYAlignment.Bottom, LayoutOrder = 999 })
local rbox = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 1000 }, pFav)
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, rbox)
bindables.rec = function(cmd)
local n = cmd:match("^toggle (.-) o[nf]+$")
if not n then return end
for i, v in ipairs(recent) do if v == n then table.remove(recent, i) break end end
table.insert(recent, 1, n)
if #recent > 8 then table.remove(recent) end
clearList(rbox)
for i, nm in ipairs(recent) do
local r = row(rbox, 36, i)
text(r, { Size = UDim2.new(1, -90, 1, 0), Position = UDim2.fromOffset(12, 0), Text = nm, TextSize = 13 })
miniButton(r, "Flip", 12, function() local t = togglesByName[nm] if t then t.set(not t.get()) end end, true)
end
end
end
-- ===== Commands =====
local TS = game:GetService("TeleportService")
local CMDS = {}
local function tgl(name) return function(a)
local t = togglesByName[name]
if not t then return toast("No such toggle") end
local v
if a[1] == "on" then v = true elseif a[1] == "off" then v = false else v = not t.get() end
t.set(v)
end end
local function sld(name) return function(a)
local sl, n = slidersByName[name], tonumber(a[1])
if sl and n then sl.set(n) else toast("Value needed") end
end end
for c, n in pairs({ fly = "fly", noclip = "noclip", esp = "player esp", tracers = "tracers", xray = "x-ray", fullbright = "fullbright", spin = "spin", freecam = "freecam", ij = "infinite jump", bhop = "bunny hop", radar = "radar" }) do CMDS[c] = tgl(n) end
for c, n in pairs({ speed = "walkspeed", jump = "jumppower", gravity = "gravity", fov = "field of view", flyspeed = "fly speed", time = "time of day", hip = "hip height" }) do CMDS[c] = sld(n) end
local function plr(a, fn) local p = X.findPlayer(a[1]) if p then fn(p) else toast("No player matches") end end
CMDS.tp = function(a) plr(a, tpTo) end
CMDS["goto"] = CMDS.tp
CMDS.view = function(a) plr(a, spectate) end
CMDS.stick = function(a) plr(a, X.stickTo) end
CMDS.fling = function(a) plr(a, function(p) X.flingPlayer(p) end) end
CMDS.flingall = function() X.flingAll() end
CMDS.unview = function() local h = getHum() if h then workspace.CurrentCamera.CameraSubject = h end end
CMDS.sit = function() local h = getHum() if h then h.Sit = true end end
CMDS.reset = function() local h = getHum() if h then h.Health = 0 end end
CMDS.back = function() X.tpBack() end
CMDS.wp = function() local r = getRoot() if r then table.insert(WAYPOINTS, { name = "Waypoint " .. (#WAYPOINTS + 1), cf = r.CFrame }) REFRESH_WPS() toast("Waypoint saved") end end
CMDS.wptp = function(a) local w, r = WAYPOINTS[tonumber(a[1]) or 0], getRoot() if w and r then r.CFrame = w.cf end end
CMDS.pos = function(a) local x, y, z, r = tonumber(a[1]), tonumber(a[2]), tonumber(a[3]), getRoot() if x and y and z and r then r.CFrame = CFrame.new(x, y, z) end end
CMDS.say = function(a) X.say(table.concat(a, " ")) end
CMDS.rejoin = function() pcall(function() TS:TeleportToPlaceInstance(game.PlaceId, game.JobId, player) end) end
CMDS.help = function() toast("Try: ;fly  ;speed 80  ;tp name  ;fling name  ;pos x y z  ;wp  ;wptp 1  or any feature name (;bunny hop on)", true) end
function X.runCommand(line)
line = line:gsub("^%s*;", "")
if bindables.rec and not X.inMacro then bindables.rec(line) end
local a = {}
for w in line:gmatch("%S+") do a[#a + 1] = w end
if #a == 0 then return end
local cmd = string.lower(table.remove(a, 1))
if cmd == "toggle" or cmd == "set" or cmd == "do" then cmd = string.lower(table.remove(a, 1) or "") end
if CMDS[cmd] then return CMDS[cmd](a) end
local state
if a[#a] == "on" or a[#a] == "off" then state = table.remove(a) == "on" end
local val = tonumber(a[#a])
if val then table.remove(a) end
local q = string.lower(cmd .. (#a > 0 and (" " .. table.concat(a, " ")) or ""))
for _, b in ipairs(bindables) do
if string.find(string.lower(b.name), q, 1, true) then
local key = string.lower(b.name)
if b.kind == "toggle" and state ~= nil then togglesByName[key].set(state)
elseif b.kind == "slider" and val and slidersByName[key] then slidersByName[key].set(val)
else X.fireBind(b) end
return
end
end
toast("Unknown command: " .. cmd)
end
local bar = new("Frame", { Size = UDim2.fromOffset(460, 40), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -24), BackgroundColor3 = C.surface, BorderSizePixel = 0, Visible = false, ZIndex = 60 }, gui)
corner(bar, 10)
local bs = stroke(bar, accent, 1.5, 0.2)
onAccent(function(c) bs.Color = c end)
local cb = inbox(bar, "Command...  (;help for ideas)", UDim2.new(1, -16, 0, 28), UDim2.fromOffset(8, 6))
cb.ZIndex = 61
cb.FocusLost:Connect(function(enter)
bar.Visible = false
local t = cb.Text
cb.Text = ""
if enter and t ~= "" then X.runCommand(t) end
end)
X.keys[Enum.KeyCode.Semicolon] = function()
bar.Visible = true
task.spawn(function() RunService.RenderStepped:Wait() cb.Text = "" cb:CaptureFocus() end)
end
local function chatCmd(t)
if os.clock() - (X.lastChat or 0) < 0.5 then return end
X.lastChat = os.clock()
X.runCommand(t)
end
connect(player.Chatted, function(m) if S.chatcmds and m:sub(1, 1) == ";" then chatCmd(m) end end)
pcall(function()
connect(game:GetService("TextChatService").MessageReceived, function(msg)
if S.chatcmds and msg.TextSource and msg.TextSource.UserId == player.UserId and msg.Text:sub(1, 1) == ";" then chatCmd(msg.Text) end
end)
end)
do
local hist, hi = {}, 0
local sug = text(bar, { Size = UDim2.new(1, -16, 0, 14), Position = UDim2.new(0, 8, 0, -18), Text = "", TextSize = 11, TextColor3 = C.muted })
cb:GetPropertyChangedSignal("Text"):Connect(function()
local q = (string.lower(cb.Text):gsub("^%s*;", ""))
local out = {}
if #q > 0 then
for _, bd in ipairs(bindables) do
if string.find(string.lower(bd.name), q, 1, true) then out[#out + 1] = string.lower(bd.name) if #out >= 4 then break end end
end
end
sug.Text = table.concat(out, "   |   ")
end)
connect(UIS.InputBegan, function(i)
if not cb:IsFocused() then return end
if i.KeyCode == Enum.KeyCode.Up then
hi = math.min(hi + 1, #hist)
if hist[#hist - hi + 1] then cb.Text = hist[#hist - hi + 1] end
elseif i.KeyCode == Enum.KeyCode.Down then
hi = math.max(hi - 1, 0)
cb.Text = hi == 0 and "" or hist[#hist - hi + 1]
end
end)
local orig = X.runCommand
X.runCommand = function(l) table.insert(hist, l) hi = 0 return orig(l) end
end
-- ===== Photo mode =====
function X.photo(v)
if v == X.photoOn then return end
X.photoOn = v
gui.Enabled = not v
pcall(function() game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, not v) end)
local r = getRoot()
if v then
X.photoLock = S.timeLock
S.timeLock = Lighting.ClockTime
if T.freecam and not S.freecam then T.freecam.set(true, true) X.photoFc = true end
if r then r.Anchored = true end
else
S.timeLock = X.photoLock
if X.photoFc and T.freecam then T.freecam.set(false, true) X.photoFc = nil end
if r then r.Anchored = false end
end
end
X.keys[Enum.KeyCode.P] = function() if X.photoOn then X.photo(false) end end
table.insert(X.cleanups, function() if X.photoOn then X.photo(false) end end)
local minBtn = makeButton(header, "-", function() end, false, UDim2.fromOffset(30, 30), 0)
minBtn.Position = UDim2.new(1, -80, 0, 11)
stats.Position = UDim2.new(1, -290, 0, 0)
local mini, restoreH = false, 440
minBtn.MouseButton1Click:Connect(function()
mini = not mini
sidebar.Visible, content.Visible = not mini, not mini
if mini then
restoreH = win.Size.Y.Offset
win.Position += UDim2.fromOffset(0, -(restoreH - 58) * winScale.Scale / 2)
win.Size = UDim2.fromOffset(win.Size.X.Offset, 58)
else
win.Size = UDim2.fromOffset(win.Size.X.Offset, restoreH)
win.Position += UDim2.fromOffset(0, (restoreH - 58) * winScale.Scale / 2)
end
end)
local click = new("Sound", { SoundId = "rbxasset://sounds/switch.wav", Volume = 0.5 }, gui)
connect(UIS.InputBegan, function(i, p) if S.clicksounds and p and i.UserInputType == Enum.UserInputType.MouseButton1 then click:Play() end end)
connect(UIS.InputEnded, function(i)
if S.snap and i.UserInputType == Enum.UserInputType.MouseButton1 then
task.defer(function()
local vp, pos, size = gui.AbsoluteSize, win.AbsolutePosition, win.AbsoluteSize
local dx, dy = 0, 0
if math.abs(pos.X) < 28 then dx = 16 - pos.X elseif math.abs(pos.X + size.X - vp.X) < 28 then dx = vp.X - 16 - (pos.X + size.X) end
if math.abs(pos.Y) < 28 then dy = 16 - pos.Y elseif math.abs(pos.Y + size.Y - vp.Y) < 28 then dy = vp.Y - 16 - (pos.Y + size.Y) end
if dx ~= 0 or dy ~= 0 then win.Position += UDim2.fromOffset(dx, dy) end
end)
end
end)
section(pSet, "Interface Extras")
flags(pSet, { { "Snap to Screen Edges", "Window snaps when dropped near an edge", "snap" }, { "Lock Window Position", "Stop the window from being dragged", "lockpos" }, { "Click Sounds", "Sound on every UI click", "clicksounds" }, { "Chat Commands", "Run ;commands typed in chat", "chatcmds" } })
section(pSet, "Config")
local HttpService = game:GetService("HttpService")
local crow = row(pSet, 90)
register(crow, "config export import settings save load")
local cfg = inbox(crow, "Exported settings appear here. Paste a config to import.", UDim2.new(1, -16, 1, -16), UDim2.fromOffset(8, 8), true)
buttonRow(pSet, { { "Export Settings", function()
local c = { t = {}, s = {}, a = { accent.R, accent.G, accent.B } }
for n, o in pairs(togglesByName) do if o.get() then c.t[#c.t + 1] = n end end
for n, o in pairs(slidersByName) do c.s[n] = o.get() end
cfg.Text = HttpService:JSONEncode(c)
toast("Exported")
end, true }, { "Import Settings", function()
local ok, c = pcall(function() return HttpService:JSONDecode(cfg.Text) end)
if not ok or type(c) ~= "table" then return toast("Invalid config text") end
for n, v in pairs(c.s or {}) do local o = slidersByName[n] if o and type(v) == "number" then o.set(v) end end
local want = {}
for _, n in ipairs(c.t or {}) do want[n] = true end
for n, o in pairs(togglesByName) do if o.get() ~= (want[n] == true) then o.set(want[n] == true, true) end end
if c.a then setAccent(Color3.new(c.a[1], c.a[2], c.a[3])) end
toast("Imported")
end } })
section(pSet, "Notification History")
local nl = lrow(pSet, 140, "notification history log")
nl.TextSize = 11
table.insert(X.ticks, function()
local t = {}
for i = 1, math.min(10, #notifHistory) do t[i] = notifHistory[i] end
nl.Text = #t > 0 and table.concat(t, "\n") or "No notifications yet"
end)
button(pSet, "Clear Notification History", function() table.clear(notifHistory) end)
section(pKeys, "Every feature can have a hotkey")
local hint = lrow(pKeys, 50)
hint.Text = "Press Bind, then a key. Toggles flip, buttons run, sliders step +10% (hold Shift for -10%). Backspace clears, Esc cancels."
local filter = inbox(pKeys, "Filter features...", UDim2.new(1, 0, 0, 32), UDim2.new())
filter.LayoutOrder = nextOrder(pKeys)
buttonRow(pKeys, { { "Clear All Hotkeys", function() X.userBinds = {} X.hkRefresh() toast("Hotkeys cleared") end } })
local list = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = nextOrder(pKeys) }, pKeys)
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, list)
function X.hkRefresh()
clearList(list)
local q = string.lower(filter.Text)
local keyOf = {}
for kc, b in pairs(X.userBinds) do keyOf[b] = kc end
local sorted = {}
for _, b in ipairs(bindables) do if q == "" or string.find(string.lower(b.name), q, 1, true) then sorted[#sorted + 1] = b end end
table.sort(sorted, function(a, b) return string.lower(a.name) < string.lower(b.name) end)
for i, b in ipairs(sorted) do
if i > 400 then break end
local r = row(list, 34, i)
text(r, { Size = UDim2.new(1, -250, 1, 0), Position = UDim2.fromOffset(12, 0), TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd, Text = b.name .. (b.kind == "slider" and "  (step)" or "") })
local kc = keyOf[b]
text(r, { Size = UDim2.fromOffset(80, 34), Position = UDim2.new(1, -226, 0, 0), Text = kc and kc.Name or "-", TextSize = 12, TextColor3 = kc and accent or C.muted, TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold })
miniButton(r, "Bind", 66, function() X.bindWait = b toast("Press a key for " .. b.name, true) end, true)
miniButton(r, "X", 12, function() if kc then X.userBinds[kc] = nil X.hkRefresh() end end)
end
end
filter.FocusLost:Connect(function() X.hkRefresh() end)
connect(UIS.InputBegan, function(i)
if not X.bindWait or i.UserInputType ~= Enum.UserInputType.Keyboard then return end
local b = X.bindWait
X.bindWait = nil
X.justBound = os.clock()
if i.KeyCode == Enum.KeyCode.Escape then return toast("Cancelled", true) end
for kc, o in pairs(X.userBinds) do if o == b then X.userBinds[kc] = nil end end
if i.KeyCode ~= Enum.KeyCode.Backspace then X.userBinds[i.KeyCode] = b toast(b.name .. "  ->  " .. i.KeyCode.Name, true) end
X.hkRefresh()
end)
X.hkRefresh()
end
do
local sp = win:FindFirstChild("Splash")
if sp then
task.spawn(function()
local w = 6 - (os.clock() - gui:GetAttribute("t0"))
if w > 0 then task.wait(w) end
tween(sp, { GroupTransparency = 1 }, 0.45)
task.delay(0.5, function() sp:Destroy() end)
end)
end
end
selectTab("Player")
T.antiafk.set(true, true)
setOpen(true)
toast("Lockpick loaded")
print("[Lockpick] loaded")