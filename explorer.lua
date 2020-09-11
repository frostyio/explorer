-- explorer v1
-- dont mind messy code most was written while doing an all nighter
-- frosty

local RunService = game:GetService("RunService");
local ContextAction = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService");
local HttpService = game:GetService("HttpService");
local TweenService = game:GetService("TweenService");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Players = game:GetService("Players");

local Client = Players.LocalPlayer;
local Mouse = Client:GetMouse();

-- retrieve gui
local Gui;

-- gotta keep it studio friendly;
if RunService:IsStudio() then
	Gui = script.Parent:WaitForChild("Screen");
else
	Gui = game:GetObjects("rbxassetid://4840423175")[1];
	syn.protect_gui(Gui)
end

local ExplorerFrame = Gui:WaitForChild("Explorer");
local PropertiesFrame = Gui:WaitForChild("Properties");
local TemplateFrame = Gui:waitForChild("ColorFrame"):Clone(); 

local Dropdown = ExplorerFrame:WaitForChild("Dropdown");
local DropdownList = Dropdown:WaitForChild("List");
local DropdownSlot = DropdownList:WaitForChild("Slot");
local SlotTemplate = DropdownSlot:Clone();
local SlotSize = DropdownSlot.AbsoluteSize;
DropdownSlot:Destroy();

local Explorer = ExplorerFrame:WaitForChild("Explorer");
local FilterFrame = ExplorerFrame:WaitForChild("FilterFrame");
local ExplorerExitButton = ExplorerFrame:WaitForChild("Exit");
local FilterInput = FilterFrame:WaitForChild("Filter");
local List = Explorer:WaitForChild("List");
local Scrollbar = Explorer:WaitForChild("Scrollbar");
local UpArrow = Scrollbar:WaitForChild("UpArrow");
local DownArrow = Scrollbar:WaitForChild("DownArrow");
local Zone = Scrollbar:WaitForChild("Zone");
local ScrollButton = Zone:WaitForChild("Button");
local ExplorerTitle = ExplorerFrame:WaitForChild("Title");

local Properties = PropertiesFrame:WaitForChild("Properties");
local PropertyTitle = PropertiesFrame:WaitForChild("Title");
local PropertiesList = Properties:WaitForChild("List");
local PropertySlot = PropertiesList:WaitForChild("Slot1");
local PropertyTemplate = PropertySlot:Clone();
local PropertySize = PropertySlot.AbsoluteSize;
PropertySlot:Destroy(); PropertySlot = nil;

local Template = List:WaitForChild("Slot1");
local TemplateSize = Template.AbsoluteSize;
local ObjectTemplate = Template:Clone();
Template:Destroy(); Template = nil;

local SelectionColor = Color3.fromRGB(11, 90, 175);
local HoverColor = Color3.fromRGB(66, 66, 66);
local TextColor = Color3.fromRGB(226, 226, 226);
local ReadOnlyColor = Color3.fromRGB(140, 140, 140);
local CheckmarkBlue = Color3.fromRGB(53, 178, 251);
local CheckmarkBackground = Color3.fromRGB(37, 37, 37);
local ExitRed = Color3.fromRGB(255, 51, 51);


-- for the um filter thingy
local CustomShowList, CustomChildrenShowing, OnlyShow = nil, nil, nil;

local Start = 1; -- <- this start is the index of where the Explorer Scrollbar is at
local START = tick();

-- list of services to show
local services = {
	"Workspace", "Players", 
	not RunService:IsStudio() and "CoreGui" or nil, 
	"Lighting", "ReplicatedFirst", "ReplicatedStorage", "StarterGui",
	"StarterPack", "StarterPlayer", "Teams", "SoundService", "Chat"
};

local ChildrenShowing = {};
local UpdateList, GetShowList, UpdateScrollbar;
local LoadProperties;
local ListObjects = {};
local ScriptEditor = {};
local ChildAddedUpdates, ScrollUpdates, Selection = {}, {}, {};
local ExplorerHovering, PropertiesHovering = false, false;
local HoverEnd = 175; -- AbsolutePos.X + HoverEnd
local clipboard = nil;
local wrap = coroutine.wrap;

-- detectable
local SelectionBox;
if Drawing then
	SelectionBox = {
		Adornee = nil
	};

	coroutine.wrap(function() 
		local function wtvp(...) return workspace.CurrentCamera:WorldToViewportPoint(...) end

		local objects = {};
		for i = 1, 12 do
			local Line = Drawing.new("Line");
			Line.Thickness = 2;
			Line.Color = CheckmarkBlue;
			objects[("Line%d"):format(i)] = Line;
		end
			
		while true do
			local object = SelectionBox.Adornee;
			if SelectionBox.Adornee and object and object:IsA("BasePart") then

				local cf = object.CFrame;
				local _, on_screen = wtvp(cf.p);

				if on_screen then
					local size = object.Size;
					local x, y, z = size.X, size.Y, size.Z;
					local v3 = CFrame.new;
					-- front
					local front_top_left, front_top_left_showing = wtvp((cf * v3(-(x / 2), y / 2, z / 2)).p);
					local front_top_right, front_top_right_showing = wtvp((cf * v3(x / 2, y / 2, z / 2)).p);
					local front_bottom_left, front_bottom_left_showing = wtvp((cf * v3(-(x / 2), -(y / 2), z / 2)).p);
					local front_bottom_right, front_bottom_right_showing = wtvp((cf * v3(x / 2, -(y / 2), z / 2)).p);
					front_top_left = Vector2.new(front_top_left.X, front_top_left.Y);
					front_top_right = Vector2.new(front_top_right.X, front_top_right.Y);
					front_bottom_left = Vector2.new(front_bottom_left.X, front_bottom_left.Y);
					front_bottom_right = Vector2.new(front_bottom_right.X, front_bottom_right.Y);
					-- back
					local back_top_left, back_top_left_showing = wtvp((cf * v3(-(x / 2), y / 2, -(z / 2))).p);
					local back_top_right, back_top_right_showing = wtvp((cf * v3(x / 2, y / 2, -(z / 2))).p);
					local back_bottom_left, back_bottom_left_showing = wtvp((cf * v3(-(x / 2), -(y / 2), -(z / 2))).p);
					local back_bottom_right, back_bottom_right_showing = wtvp((cf * v3(x / 2, -(y / 2), -(z / 2))).p);
					back_top_left = Vector2.new(back_top_left.X, back_top_left.Y);
					back_top_right = Vector2.new(back_top_right.X, back_top_right.Y);
					back_bottom_left = Vector2.new(back_bottom_left.X, back_bottom_left.Y);
					back_bottom_right = Vector2.new(back_bottom_right.X, back_bottom_right.Y);

					objects.Line1.From = front_top_left;
					objects.Line1.To = front_top_right;
					objects.Line1.Visible = front_top_right_showing;

					objects.Line2.From = front_top_right;
					objects.Line2.To = front_bottom_right;
					objects.Line2.Visible = front_bottom_right_showing;

					objects.Line3.From = front_bottom_right;
					objects.Line3.To = front_bottom_left;
					objects.Line3.Visible = front_bottom_left_showing;

					objects.Line4.From = front_bottom_left;
					objects.Line4.To = front_top_left;
					objects.Line4.Visible = front_top_left_showing;

					objects.Line5.From = back_top_left;
					objects.Line5.To = back_top_right;
					objects.Line5.Visible = back_top_right_showing;

					objects.Line6.From = back_top_right;
					objects.Line6.To = back_bottom_right;
					objects.Line6.Visible = back_bottom_right_showing;

					objects.Line7.From = back_bottom_right;
					objects.Line7.To = back_bottom_left;
					objects.Line7.Visible = back_bottom_left_showing;

					objects.Line8.From = back_bottom_left;
					objects.Line8.To = back_top_left;
					objects.Line8.Visible = back_top_left_showing;

					-- connections

					objects.Line9.From = back_bottom_left;
					objects.Line9.To = front_bottom_left;
					objects.Line9.Visible = front_bottom_left_showing;

					objects.Line10.From = back_bottom_right;
					objects.Line10.To = front_bottom_right;
					objects.Line10.Visible = front_bottom_right_showing;

					objects.Line11.From = back_top_left;
					objects.Line11.To = front_top_left;
					objects.Line11.Visible = front_top_left_showing;

					objects.Line12.From = front_top_right;
					objects.Line12.To = back_top_right;
					objects.Line12.Visible = back_bottom_right_showing;
				else
					for i = 1, 12 do
						objects[("Line%d"):format(i)].Visible = false
					end
				end
				RunService.RenderStepped:Wait();
			else
				for i = 1, 12 do
					objects[("Line%d"):format(i)].Visible = false
				end
				wait(0.1);
			end
		end
	end)()
else
	-- is detectable if exploit does not support the Drawing api
	SelectionBox = Instance.new("SelectionBox");
	SelectionBox.LineThickness = 0.05;
	SelectionBox.Color3 = CheckmarkBlue;
	SelectionBox.Parent = Gui;
end


local CurrentZIndexPriority = 1; -- for windows

local TotalObjects = #workspace:GetDescendants();

-- GetFromDump is for if it should get the latest updated properties directly from the roblox api dump
-- this is disabled because it causes slight lag at startup because of JSONDecoding such a huge JSON file
-- i should be hopefully maintaining my github's property page fairly often
local GetFromDump = false;

local HttpGet;
local ApiDump, ClassProperties;

local ExitButton;

-- still keeping it studio friendly
if not RunService:IsStudio() then
	HttpGet = function(url) return game:HttpGet(url) end;
end

if RunService:IsStudio() then
	ApiDump = require(ReplicatedStorage:WaitForChild("ApiDump"));
elseif GetFromDump then
	local proxy = "https://s3.amazonaws.com/";
	local version = HttpGet(proxy .. "setup.roblox.com/versionQTStudio");
	ApiDump = HttpGet(proxy .. "setup.roblox.com/"..version.."-API-Dump.json");
end


-- decoding json
do
	-- get auto updated dump
	if GetFromDump then
		local JsonDecoded = HttpService:JSONDecode(ApiDump);
		local Classes = JsonDecoded.Classes;
		local ClassesDictionary = {};
		local WaitingForInherit = {};
		
		-- this basically ends up formatting the API dump into a properties list
		-- this is what my properties table on the github is 

		local function HasTag(Data, Tag)
			for _, tag in pairs(Data.Tags or {}) do
				if tag == Tag then
					return true;
				end
			end
			return false;
		end
		
		for _, class in pairs(Classes) do
			local Super, Members, Name = class.Superclass, class.Members, class.Name;
			local properties = {};
			for _, member in pairs(Members) do
				local Category, Type, Name = member.Category, member.MemberType, member.Name;
				if Type == "Property" and HasTag(member, "Hidden") == false then
					local property = {Name = Name, Category = Category};
					if HasTag(member, "Deprecated") then
						property.Deprecated = true;
					end
					property.ValueType = member.ValueType.Name;
					if member.Security.Write ~= "None" or HasTag(member, "ReadOnly") then
						property.ReadOnly = true;
					end
					properties[Name] = property;
				end
			end
			WaitingForInherit[Name] = Super;
			ClassesDictionary[Name] = {Super = Super, Properties = properties, Name = Name};
		end
		
		local function GetLength(List)
			local Num = 0;
			for k, v in pairs(List) do Num = Num + 1 end;
			return Num
		end
		
		-- made this more efficient in my js code kinda too lazy to update it
		while GetLength(WaitingForInherit) ~= 0 do
			for Name, Super in pairs(WaitingForInherit) do
				if not WaitingForInherit[Super] then
					for name, property in pairs((ClassesDictionary[Super] or {}).Properties or {}) do
						ClassesDictionary[Name].Properties[name] = property;
					end
					WaitingForInherit[Name] = nil;
				end
			end
		end
		
		ClassProperties = ClassesDictionary;
	else
		-- gotta keep it studio safe!
		if RunService:IsStudio() then
			ClassProperties = require(ReplicatedStorage:WaitForChild("ClassProperties"));
		else
			ClassProperties = loadstring(HttpGet("https://raw.githubusercontent.com/frostyio/explorer/master/properties.lua"))();
		end
	end
end

-- i should propably think of a better way to do this but im able to keep it basically automated with the run of a script
local IconData;

if RunService:IsStudio() then
	IconData = require(ReplicatedStorage:WaitForChild("IconData"));
else
	IconData = loadstring(HttpGet("https://raw.githubusercontent.com/frostyio/explorer/master/icon_data.lua"))();
end

-- RectSize, RectOffset

-- MapId = "rbxasset://textures/ClassImages.png";

local function GetIconFromClass(Class)
	local Data = IconData[Class];
	-- why tf does sirthurt errorr here
	local RectSize = Vector2.new(Data[1][1], Data[1][2]);
	local RectOffset = Vector2.new(Data[2][1], Data[2][2]);
	return RectSize, RectOffset;
end

-- misc functions --

local function SetZIndex(Frame, ZIndex)
	Frame.ZIndex = ZIndex;
	for _, object in pairs(Frame:GetDescendants()) do
		if object:IsA("GuiBase") then
			object.ZIndex = object.ZIndex + ZIndex;
		end
	end
end

local function BringWindowToFront(Window)
	CurrentZIndexPriority = CurrentZIndexPriority + 5;

	SetZIndex(Window, CurrentZIndexPriority);
end

-- dragging --
local drag;
do
	local is_dragging, input_start, input_drag, position_start, item_drag, drag_frame, tween_time;
	local function update(input, gui)
		local delta = input.Position - input_start;
		local pos = UDim2.new(0, position_start.X.Offset + delta.X, 0, position_start.Y.Offset + delta.Y);

		-- bounds --
		if drag_frame then
			local small_x = pos.X.Scale * gui.AbsoluteSize.X + pos.X.Offset;
			local small_y = pos.Y.Scale * gui.AbsoluteSize.Y + pos.Y.Offset;
				
			local far_x = small_x + gui.Size.X.Offset;
			local far_y = small_y + gui.Size.Y.Offset;
			
			local true_x = math.clamp(small_x, 0, drag_frame.AbsoluteSize.X - (far_x - small_x));
			local true_y = math.clamp(small_y, 0, drag_frame.AbsoluteSize.Y - (far_y - small_y));
			
			pos = UDim2.new(0, true_x, 0, true_y);
		end

		if tween_time then
			gui:TweenPosition(pos, 1, 1, tween_time, 1);
		else
			gui.Position = pos;
		end
	end
	
	function drag(object, move_frame, tween, border_frame, update_func)
		move_frame = move_frame or object;
		
		local connections = {};
		
		table.insert(connections, object.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				is_dragging = true;
				position_start = UDim2.new(0, move_frame.AbsolutePosition.X, 0, move_frame.AbsolutePosition.Y);
				input_start = input.Position;
				item_drag = move_frame;
				drag_frame = border_frame;
				tween_time = tween;

				BringWindowToFront(move_frame);
				
				if update_func then
					update_func(true);
				end
				
				table.insert(connections, input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						is_dragging = false;
						if update_func then
							update_func(false);
						end
					end
				end))
				
			end
		end))

		table.insert(connections, object.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				input_drag = input;
			end
		end))
				
		-- return --
		return {
			disconnect = function()
				for _, connection in pairs(connections) do connection:Disconnect() end;
			end	
		}
	end
	
	UserInputService.InputChanged:Connect(function(input)
		if input == input_drag and is_dragging then
			update(input, item_drag);
		end
	end);
end


-- Color Picker --

local ColorObject; do
	local function rgb_to_hsv(r, g, b)
		local max, min = math.max(r, g, b), math.min(r, g, b);
		local h, s, v;
		v = max;
	
		local d = max - min;
		if max == 0 then s = 0 else s = d / max end;
			if max == min then
				h = 0; -- achromatic
			else
				if max == r then
					h = (g - b) / d ;
					if g < b then 
						h = h + 6 ;
					end
				elseif max == g then 
					h = (b - r) / d + 2;
				elseif max == b then
					h = (r - g) / d + 4;
			end
			h = h / 6;
		end
	
		return h, s, v;
	end
	
	local current_input, callback;
	
	ColorObject = {
		h = nil,
		s = nil,
		v = nil,
	
		new = function(this, frame, starting, cb)
			local self = setmetatable({}, this);
			self.Frame = frame:Clone();
			self.Frame.Parent = Gui;
			self.cb = cb;
			self.previous = starting;
			
			self.h, self.s, self.v = rgb_to_hsv(starting.r, starting.g, starting.b);
			self:Update();
			
			local Hue = self.Frame:WaitForChild("Hue");
			local Mask = self.Frame:WaitForChild("Mask");
			local ExitB = self.Frame:WaitForChild("Topbar"):WaitForChild("Exit");

			ExitButton(ExitB);
			
			ExitB.MouseButton1Click:Connect(function() 
				self:cancel();
			end);
			self.Frame:WaitForChild("Cancel").MouseButton1Click:Connect(function() self:cancel(); end);
			self.Frame:WaitForChild("Ok").MouseButton1Click:Connect(function() self:hide(); end);
			
			drag(self.Frame.Topbar, self.Frame);
			BringWindowToFront(self.Frame);
			
			Mask.InputBegan:Connect(function(input) 
				if input.UserInputType == Enum.UserInputType.MouseButton1 and not current_input then
					callback = function() 
						self:SetMaskToMouse();
						self:Update();
					end;
										
					local conn; conn = Mask.InputChanged:Connect(function(inp) 
						if inp.UserInputType == Enum.UserInputType.MouseMovement then
							current_input = inp;
						end
					end);
					
					local c; c = input.Changed:Connect(function() 
						if input.UserInputState == Enum.UserInputState.End then
							current_input = nil;
							conn:Disconnect();
							c:Disconnect();
						end
					end);
				end
			end);
			
			Hue.InputBegan:Connect(function(input) 
				if input.UserInputType == Enum.UserInputType.MouseButton1 and not current_input then
					callback = function() 
						self:SetHueToMouse();
						self:Update();
					end;
										
					local conn; conn = Hue.InputChanged:Connect(function(inp) 
						if inp.UserInputType == Enum.UserInputType.MouseMovement then
							current_input = inp;
						end
					end);
					
					local c; c = input.Changed:Connect(function() 
						if input.UserInputState == Enum.UserInputState.End then
							current_input = nil;
							conn:Disconnect();
							c:Disconnect();
						end
					end);
				end
			end);
			
			return self;
		end,
		show = function(self)
			local Size = self.Frame.AbsoluteSize;
			self.Frame.Position = UDim2.new(0.5, -Size.X/2, 0.5, -Size.Y/2);
			self.Frame.Visible = true;
			self.previous = self.color;
		end,
		hide = function(self)
			self.Frame:Destroy();
		end,
		cancel = function(self)
			self.color = self.previous;
			self.cb(self.color);
			self:hide();
		end,
		SetMaskToMouse = function(self)
			local mask = self.Frame.Mask;
			local selector = mask.Frame;
			local abs = self.Frame.Mask.AbsolutePosition;
			local siz = self.Frame.Mask.AbsoluteSize;
			local siz2 = selector.AbsoluteSize;
			local mouse_pos = Vector2.new(Mouse.X, Mouse.Y);
			local delta = mouse_pos - abs;
			selector.Position = UDim2.new(
				0, math.clamp(delta.X, siz2.X, siz.X - siz2.X), 
				0, math.clamp(delta.Y, siz2.Y, siz.Y - siz2.Y / 2)
			);
			self.v = math.clamp(1 - ((mouse_pos - abs).Y / mask.AbsoluteSize.Y), 0, 1);
			self.s = math.clamp(1 - ((mouse_pos - abs).X / mask.AbsoluteSize.X), 0, 1);
		end,
		SetHueToMouse = function(self)
			local selector = self.Frame.Hue.Frame;
			local abs = self.Frame.Hue.AbsolutePosition;
			local siz = self.Frame.Hue.AbsoluteSize;
			local siz2 = selector.AbsoluteSize;
			local mouse_pos = Vector2.new(Mouse.X, Mouse.Y);
			local delta = mouse_pos - abs;
			selector.Position = UDim2.new(
				0, 0, 
				0, math.clamp(delta.Y, siz2.Y, siz.Y - siz2.Y / 2)
			);
			local a = math.clamp(((mouse_pos - abs).Y / siz.Y), 0, 1);
			self.h = a - (a*2) + 1;
		end,
		Update = function(self)
			self.Frame.Mask.ImageColor3 = Color3.fromHSV(self.h, 1, 1);
			self.color = Color3.fromHSV(self.h, self.s, self.v);
			self.cb(self.color);
		end
	};
	ColorObject.__index = ColorObject;
	
	UserInputService.InputChanged:Connect(function(input) 
		if input == current_input and callback then
			callback();
		end
	end);
end

-- Notify --

local Notify; do
	local NotifyFrame = Gui:WaitForChild("Error"):Clone();

	Notify = {
		new = function(this, title, info, width, height)
			local self = setmetatable({}, this);

			local Frame = NotifyFrame:Clone();

			local Topbar = Frame:WaitForChild("Topbar");
			local Exit = Topbar:WaitForChild("Exit");
			local Image = Frame:WaitForChild("ImageLabel");
			local Title = Image:WaitForChild("Title");
			local Info = Frame:WaitForChild("Info");
			local Ok = Frame:WaitForChild("Ok");

			self.Frame = Frame;

			local function Close() self:Close() end;

			Exit.MouseButton1Click:Connect(Close);
			Ok.MouseButton1Click:Connect(Close);

			Title.Text = title;
			Info.Text = info;

			if width or height then
				Frame.Size = UDim2.new(width, 0, height, 0);
			end
			Frame.Visible = true;
			Frame.Parent = Gui;

			drag(Topbar, Frame);

			ExitButton(Exit);
			BringWindowToFront(Frame);

			return self;
		end,

		Close = function(self)
			self.Frame:Destroy();
		end
	};
	Notify.__index = Notify;
end

-- misc -- 

function ExitButton(button)
	if button and (button:IsA("TextButton") or button:IsA("ImageButton")) then
		local CurrentTween = nil;
		local TweenTime = 0.3;
		local Property = button:IsA("TextButton") and "TextColor3" or "ImageColor3";
		local OriginalColor = button[Property];

		local function CancelCurrentTween() 
			if CurrentTween then
				CurrentTween:Cancel();
				CurrentTween = nil;
			end
		end

		local function OnHover()
			CancelCurrentTween();

			CurrentTween = TweenService:Create(button, TweenInfo.new(TweenTime), {[Property] = ExitRed});
			CurrentTween:Play();
		end

		local function OnLeave()
			CancelCurrentTween();

			CurrentTween = TweenService:Create(button, TweenInfo.new(TweenTime), {[Property] = OriginalColor});
			CurrentTween:Play();
		end

		button.MouseEnter:Connect(OnHover);
		button.MouseLeave:Connect(OnLeave);
	end
end

local function make_path(object)
	local parent, s = object, "";
	repeat
		local name = parent.Name;
		if name:match("[%a_]+") ~= name then name = "[\""..name.."\"]" else name = "." .. name end;
		s = ("%s"):format(name) .. s;
		parent = parent.Parent;
	until parent.Parent == game
	return (parent == workspace and "workspace" or ("game:GetService(\"%s\")"):format(parent.Name)) .. s;
end

local function is_service(object)
	return game:GetService(object.ClassName) and true;
end

local cached_decomp = {};
local function decomp(obj)
	if decompile == nil then
		Notify:new("Decompiling error", "Please execute with an exploit that supports decompiling.");
	end

	if cached_decomp[obj] then return cached_decomp[obj]; end;
	cached_decomp[obj] = decompile(obj);
	return cached_decomp[obj];
end

local function sort_alphabetical(char, char2)
	assert(char:match("%a") and char2:match("%a") and #char + #char2 == 2, "invalid arguments");
	return char:lower():byte() < char2:lower():byte();
end

local LastUpdate = 0;

local function TotalUpdate()
	if tick() - LastUpdate <= 0.1 then return end;
	LastUpdate = tick(); 

	UpdateList(GetShowList());
	UpdateScrollbar();
end

local function HideClickMenu()
	Dropdown.Visible = false;
	DropdownList:ClearAllChildren();
end

-- right click menu lib --

local function AddHotkey(Name, Key, Func)
	if type(Key) ~= "table" then
		local NewFunc =  function(...) 
			local tbl = {};
			for object in pairs(Selection) do table.insert(tbl, object) end;
			if #tbl > 0 then
				Func(...);
			end	
			return Enum.ContextActionResult.Pass
		end;
		ContextAction:BindAction(Name, NewFunc, false, Key);
	else
		local NumKeysDown = 0;
		local function NewFunc(name, state, obj)
			if state == Enum.UserInputState.Begin then
				NumKeysDown = NumKeysDown + 1;
			else
				NumKeysDown = NumKeysDown - 1;
			end			
			if NumKeysDown == #Key then
				local tbl = {};
				for object in pairs(Selection) do table.insert(tbl, object) end;
				if #tbl > 0 then
					Func(name, state, obj);
				end	
			end
			return Enum.ContextActionResult.Pass
		end
		ContextAction:BindAction(Name, NewFunc, false, unpack(Key));
	end
end
local function STL() -- SelectionToTable
	local tbl = {};for object in pairs(Selection) do table.insert(tbl, object) end return tbl;
end;

local Last;
local RightClickDropdown = {
	Button = function(self, Name, Icon, GrayedOut, func, Hotkey)
		local Clone = SlotTemplate:Clone();
		Clone.Parent = DropdownList;
		Clone.Position = UDim2.new(0, 0, 0, SlotSize.Y * (#DropdownList:GetChildren() - 1));
		Dropdown.Size = UDim2.new(0.65, 0, 0, SlotSize.Y * (#DropdownList:GetChildren()));
		Last = Clone;
		local Hover = Clone:WaitForChild("Hover");
		local Ic = Clone:WaitForChild("Icon");
		if Icon then
			Ic.ImageRectOffset = Vector2.new((Icon - 1) * 17, 0)
		else
			Ic.Visible = false;
		end
		Hover.MouseEnter:Connect(function() 
			Hover.BackgroundTransparency = 0;
		end);
		Hover.MouseLeave:Connect(function() 
			Hover.BackgroundTransparency = 1;
		end);
		if not GrayedOut then
			Hover.MouseButton1Click:Connect(function() 
				if func then func() end;
				HideClickMenu();
			end)
		end
		local HotkeyLabel = Clone:WaitForChild("Hotkey");
		if Hotkey then
			HotkeyLabel.Text = Hotkey;
			HotkeyLabel.Visible = true;
		end
		
		local Label = Clone:WaitForChild("Label");
		Label.Text = Name;
		if GrayedOut then
			Label.TextColor3 = Color3.fromRGB(127, 127, 127);
			HotkeyLabel.TextColor3 = Color3.fromRGB(127, 127, 127);
		end
	end,
	Divider = function(self)
		if Last then
			Last.Divider.Visible = true;
		end
	end
}

-- right click menu click off --

local DropdownHovering = false;

Dropdown.InputBegan:Connect(function(input) 
	if input.UserInputType == Enum.UserInputType.MouseMovement then 
		DropdownHovering = true;
	end 
end);
Dropdown.InputEnded:Connect(function(input) 
	if input.UserInputType == Enum.UserInputType.MouseMovement then 
		DropdownHovering = false;
	end 
end);

UserInputService.InputBegan:Connect(function(input) 
	if input.UserInputType == Enum.UserInputType.MouseButton1 and not DropdownHovering then 
		HideClickMenu();
	end 
end);


-- this function was an after main production function which is why it isn't implemented as good as it could be
local function GetChildrenShowing()
	if CustomChildrenShowing then
		return CustomChildrenShowing;
	end
	return ChildrenShowing;
end

-- right click menu --
		
local function RightClickMenu()
	local Object;
	for object in pairs(Selection) do Object = object break end;
	if Object then
		-- general instance buttons --
		-- for some reason roblox just doesn't like you using control --
		RightClickDropdown:Button("Cut", 1, is_service(Object), function() clipboard = {Object:Clone()}; Object:Destroy(); end, "Shift+X");
		RightClickDropdown:Button("Copy", 2, is_service(Object), function() clipboard = {Object:Clone()}; end, "Shift+C");
		RightClickDropdown:Button("Paste Into", nil, clipboard == nil, function() 
			for _, object in pairs(clipboard) do
				if typeof(object) == "Instance" then
					object:Clone().Parent = Object ;
				end
			end
		end, "Shift+Shift+V");
		RightClickDropdown:Button("Duplicate", 2, is_service(Object), function() Object:Clone().Parent = Object.Parent end, "Shift+D");
		RightClickDropdown:Button("Delete", 3, is_service(Object), function() Object:Destroy(); end, "Del");
		--RightClickDropdown:Button("Rename", nil, false, function() print("hi") end, "F2");
		RightClickDropdown:Divider();
		RightClickDropdown:Button("Group", 4, is_service(Object), function()
			local Model = Instance.new("Model");
			Model.Parent = Object.Parent;
			Object.Parent = Model;
		end, "Shift+G");
		RightClickDropdown:Button("Ungroup", 5, Object.ClassName ~= "Model", function()
			for _, object in pairs(Object:GetChildren()) do object.Parent = Object.Parent end;
			Object:Destroy();
		end, "Shift+U");
		RightClickDropdown:Button("Select Children", 6, false, function() 
			GetChildrenShowing()[Object] = true;
			Selection[Object] = false;
			for _, obj in pairs(Object:GetChildren()) do Selection[obj] = obj SelectionBox.Adornee = obj; end;
			TotalUpdate();
		end);
		RightClickDropdown:Button("Teleport To", 7, not Object:IsA("BasePart"), function() 
			if Client.Character then Client.Character:SetPrimaryPartCFrame(Object.CFrame) end;
		end, "F");
		RightClickDropdown:Divider();
		RightClickDropdown:Button("Insert Part", 8, false, function() 
			Instance.new("Part").Parent = Object;
		end);
		RightClickDropdown:Button("Insert Object", nil, false, function() end);
		RightClickDropdown:Divider();
		RightClickDropdown:Button("Save Instance", nil, true, function() saveinstance(Object) end);
		RightClickDropdown:Button("Get Path", nil, false, function() setclipboard(make_path(Object)) end);
		RightClickDropdown:Divider();
		
		-- script buttons --
		if Object:IsA("LocalScript") or Object:IsA("ModuleScript") then
			RightClickDropdown:Button("Save To Clipboard", 2, false, function() 
				wrap(function() setclipboard(decomp(Object)) end)();
			end);
			RightClickDropdown:Button("Save To Workspace", nil, false, function() 
				wrap(function() writefile(("%s.lua"):format(Object.Name), decomp(Object)) end)();
			end);
			RightClickDropdown:Button("View Script", 9, false, function() 
				ScriptEditor:Show();
				wrap(function() ScriptEditor:CreateScript(Object.Name, decomp(Object)) end)();
			end);
		elseif Object:IsA("ClickDetector") then
			RightClickDropdown:Button("Fire click detector", nil, false, function() 
				if fireclickdetector then
					fireclickdetector(Object);
				else
					Notify:new("Error", "Please execute with an exploit that supports fireclickdetector.");
				end
			end);
		end
		-- --;
		
		Dropdown.Visible = true;
		Dropdown.Position = UDim2.new(0, Mouse.X - ExplorerFrame.AbsolutePosition.X + 5, 0, Mouse.Y - ExplorerFrame.AbsolutePosition.Y);
	end
end

-- hotkeys
do
	AddHotkey("Cut", {Enum.KeyCode.LeftShift, Enum.KeyCode.X}, function() 
		local clip = {};
		for _, obj in pairs(STL()) do
			table.insert(clip, obj:Clone());
			obj:Destroy();
		end
		clipboard = clip;
		Selection = {};
	end);
	AddHotkey("Copy", {Enum.KeyCode.LeftShift, Enum.KeyCode.C}, function() 
		clipboard = STL();
	end);
	AddHotkey("Paste Into", {Enum.KeyCode.LeftShift, Enum.KeyCode.V}, function() 
		local Object = STL()[1];
		local new = {};
		for _, obj in pairs(clipboard) do
			local x = obj:Clone();
			new[x] = x;
			x.Parent = Object;
		end
		Selection = new;
	end);
	AddHotkey("Duplicate", {Enum.KeyCode.LeftShift, Enum.KeyCode.D}, function() 
		local Object = STL()[1];
		local new = {};
		for _, obj in pairs(STL()) do
			local x = obj:Clone();
			new[x] = x;
			x.Parent = Object.Parent;
		end
		Selection = new;
	end);
	AddHotkey("Delete", Enum.KeyCode.Delete, function(Selection) 
		for _, object in pairs(STL()) do object:Destroy() end;
		Selection = {};
	end);
	AddHotkey("Teleport To", Enum.KeyCode.F, function(Selection) 
		local Object = STL()[1];
		if Object:IsA("BasePart") then 
			if Client.Character and Client.Character.PrimaryPart then Client.Character:SetPrimaryPartCFrame(Object.CFrame) end;
		end
	end);
end

-- explorer stuff --

local function GetFurthestOut() -- for HoverEnd
	local biggest = 0;
	for _, obj in pairs(ListObjects) do
		local title = obj.Label;
		local e = title.AbsolutePosition.X + title.TextBounds.X + 20 - Explorer.AbsolutePosition.X;
		if e > biggest then
			biggest = e;
			HoverEnd = e;
		end
	end
end

local function UpdateSelections()
	for _, object in pairs(ListObjects) do
		object:UpdateSelect();
	end
end

-- prefill the explorer list (only called once @Boot) with templates to use later on --

local function FillList()
	local Size = TemplateSize.Y;
	local Amount = math.floor(List.AbsoluteSize.Y / Size);
	for i = 1, Amount do
		local Object = ObjectTemplate:Clone();
		Object.Parent = List;
		Object.Position = UDim2.new(0, 0, 0, (i - 1) * Size);
		Object.Name = ("Slot%d"):format(i);
		local HitboxFrame = Object:WaitForChild("HitboxFrame");
		local Hover = Object:WaitForChild("Hover");
		local Selected = false;
		local ObjectData = {
			Label = Object:WaitForChild("Label"),
			Icon = Object:WaitForChild("Icon"),
			Dropdown = Object:WaitForChild("Dropdown"):WaitForChild("Dropdown"),
			Frame = Object,
			YPosition = (i - 1) * Size,
			CurrentObject = nil,
			UpdateHoverEnd = function(self)
				local DistanceFrom0 = Object.AbsolutePosition.X - ExplorerFrame.AbsolutePosition.X;
				Hover.Size = UDim2.new(0, HoverEnd - DistanceFrom0, 1.05, 0);
			end,
			Select = function(self)
				if self.CurrentObject then
					Selection[self.CurrentObject] = self.CurrentObject;
					SelectionBox.Adornee = self.CurrentObject;
					self:UpdateSelect();
					Selected = true;
					local Length = 0;
					table.foreach(Selection, function() Length = Length + 1 end);
					if Length == 1 then
						LoadProperties(self.CurrentObject);
						PropertyTitle.Text = ("Properties - %s \"%s\""):format(self.CurrentObject.ClassName, self.CurrentObject.Name);
					else
						PropertyTitle.Text = ("Properties - %d items"):format(Length);
					end
				end
				UpdateSelections();
			end,
			UpdateSelect = function(self)
				if Selection[self.CurrentObject] then
					Hover.BackgroundColor3 = SelectionColor;
					Hover.BackgroundTransparency = 0;
					self.Label.TextColor3 = Color3.fromRGB(255, 255, 255);
					Selected = true;
				else
					Hover.BackgroundColor3 = HoverColor;
					Hover.BackgroundTransparency = 1;
					self.Label.TextColor3 = TextColor;
					Selected = false;
				end
			end,
		};
		
		ObjectData.Dropdown.Parent.MouseButton1Down:Connect(function() 
			if not ObjectData.CurrentObject then return end;
			local ChildrenShowing = GetChildrenShowing();
			if ChildrenShowing[ObjectData.CurrentObject] == nil then 
				ChildrenShowing[ObjectData.CurrentObject] = false;
			end
			ChildrenShowing[ObjectData.CurrentObject] = not ChildrenShowing[ObjectData.CurrentObject];
			UpdateList(GetShowList());
			UpdateScrollbar();
			delay(1, function() UpdateList(GetShowList()) end);
			for _, func in pairs(ChildAddedUpdates) do
				func();
			end
		end);
		Hover.MouseEnter:Connect(function() 
			if ObjectData.CurrentObject then
				Hover.BackgroundTransparency = 0;
			end
		end);
		Hover.MouseLeave:Connect(function() 
			if ObjectData.CurrentObject then
				if Selected then return end;
				Hover.BackgroundTransparency = 1;
			end
		end);
		Hover.MouseButton1Click:Connect(function() 
			if not(ObjectData.CurrentObject) then return end;
			if not UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
				Selection = {};
			end
			ObjectData:Select();
		end);
		Hover.MouseButton2Click:Connect(function() 
			if not(ObjectData.CurrentObject) then return end;
			HideClickMenu();
			Selection = {};
			ObjectData:Select();
			RightClickMenu();
		end);
			
		table.insert(ListObjects, ObjectData);
	end
end

local function ChildrenLoop(object, list)
	if GetChildrenShowing()[object] then
		for _, obj in pairs(object:GetChildren()) do
			if OnlyShow then
				if OnlyShow[obj] then
					table.insert(list, obj);
					ChildrenLoop(obj, list);
				end
			else
				table.insert(list, obj);
				ChildrenLoop(obj, list);
			end
		end
	end
end

function GetShowList()
	if CustomShowList then 
		local ShowList = {};
		for _, object in pairs(CustomShowList) do
			if OnlyShow then
				if OnlyShow[object] then
					table.insert(ShowList, object);
					ChildrenLoop(object, ShowList);
				end
			else
				table.insert(ShowList, object);
				ChildrenLoop(object, ShowList);
			end
		end
		return ShowList 
	end

	local ShowList = {};
	for _, object in pairs(services) do
		object = game:GetService(object);
		table.insert(ShowList, object);
		ChildrenLoop(object, ShowList);
	end
	return ShowList;
end

local PreviousConnections = {};

local function FindFirstChild(self, Object)
	for _, obj in pairs(self:GetChildren()) do
		if obj == Object then
			return obj;
		end
	end
end

function UpdateList(ShowList)
	local Indent = 0;
	for _, connection in pairs(PreviousConnections) do connection:Disconnect() end;
	PreviousConnections = {};
	
	if Start > 1 then
		for i = 1, Start - 1 do
			local Object = ShowList[i];
			if Object then
				local NextObject = ShowList[i + 1];
				if NextObject and FindFirstChild(Object, NextObject) then
					Indent = Indent + 1;
				else
					-- INDENTATION FIX --
					-- laggy on big games such as jailbreak --
					-- therefor i disable it even though it is just a slight visual bug but saves frames! --
					-- doesn't do much but it's worth it --

					--if TotalObjects < 35000 then : ugh disabled cause it caused problems
						local parent = Object;
						while NextObject and NextObject.Parent ~= parent do
							if parent == nil then break end;
							parent = parent.Parent;
							if NextObject.Parent ~= parent then
								Indent = math.clamp(Indent - 1, 0, math.huge);
							end
						end
					--end

				end
			end
		end
	end
	for i = Start, Start + #ListObjects - 1 do
		local Object = ShowList[i];
		local ObjectFrame = ListObjects[i - Start + 1];
		if Object then
			ObjectFrame.Label.Text = Object.Name;
			ObjectFrame.CurrentObject = Object;
			ObjectFrame.Frame.Position = UDim2.new(0, Indent * 15, 0, ObjectFrame.YPosition);
			ObjectFrame.Icon.Visible = true;
			local Size, Offset = GetIconFromClass(Object.ClassName);
			ObjectFrame.Icon.ImageRectOffset = Offset;
			ObjectFrame.Icon.ImageRectSize = Size;
			
			-- connections --
			
			table.insert(PreviousConnections, Object:GetPropertyChangedSignal("Name"):Connect(function() 
				ObjectFrame.Label.Text = Object.Name;
			end))
			table.insert(PreviousConnections, Object.ChildRemoved:Connect(function() 
				UpdateList(GetShowList());
				UpdateScrollbar();
			end))
			table.insert(PreviousConnections, Object.ChildAdded:Connect(function() 
				UpdateList(GetShowList());
				UpdateScrollbar();
			end))
			
			-- --
			
			local NextObject = ShowList[i + 1];
			if NextObject and FindFirstChild(Object, NextObject) then
				Indent = Indent + 1;
				ObjectFrame.Dropdown.Visible = true;
				ObjectFrame.Dropdown.Rotation = 0;
			else
				if #Object:GetChildren() > 0 then
					ObjectFrame.Dropdown.Rotation = -90;
					ObjectFrame.Dropdown.Visible = true;
				else
					ObjectFrame.Dropdown.Visible = false;
				end
				local parent = Object;
				while NextObject and NextObject.Parent ~= parent do
					if parent == nil then break end;
					parent = parent.Parent;
					if NextObject.Parent ~= parent then
						Indent = math.clamp(Indent - 1, 0, math.huge);
					end
				end
			end
		else
			ObjectFrame.Label.Text = "";
			ObjectFrame.Dropdown.Visible = false;
			ObjectFrame.Icon.Visible = false;
			ObjectFrame.CurrentObject = nil;
		end
	end
end

local function ShowChildrenTilWorkspace(Childrenshowing, Onlyshowing, object)
	local parent = object;

	repeat 
		Childrenshowing[parent] = true;
		Onlyshowing[parent] = true;
		parent = parent.Parent
	until parent == workspace or parent == game;
end

-- i really gotta do something about how ugly this is
local function CustomExplorerList(List, ChildrenShowing, OnlySh)
	CustomShowList = List;
	OnlyShow = OnlySh;
	CustomChildrenShowing = ChildrenShowing;

	TotalUpdate();
	UpdateSelections();
end

local function ShowDataModel()
	CustomShowList = nil;
	CustomChildrenShowing = nil;
	OnlyShow = nil;

	for _, object in pairs(Selection) do
		ShowChildrenTilWorkspace(ChildrenShowing, {}, object);
	end

	TotalUpdate();
	UpdateSelections();
end

local function ViewOnExplorer(object)
	local index = nil;
	for i, obj in pairs(GetShowList()) do
		if obj == object then
			index = i;
			break;
		end
	end

	if index then
		Start = index;
		TotalUpdate();
		UpdateSelections();
	end
end

local charset = {};
for i = 48, 57 do table.insert(charset, string.char(i)) end;
for i = 65, 90 do table.insert(charset, string.char(i)) end;
for i = 97, 122 do table.insert(charset, string.char(i)) end;

local function RandomString(length)
	local str = "";
	for i = 1, length do
		str = str .. charset[Random.new():NextInteger(1, #charset)];
	end
	return str;
end

-- my semi fix for the comment @ the line above CustomExplorerList

local function DirectShow(obs)
	-- only works with Workspace rn

	local Objects = {workspace};
	local Childrenshowing = {[workspace] = true};
	local Onlyshowing = {[workspace] = true};

	for _, object in pairs(obs) do
		ShowChildrenTilWorkspace(Childrenshowing, Onlyshowing, object);
	end

	CustomExplorerList(Objects, Childrenshowing, Onlyshowing);
end

UserInputService.InputBegan:Connect(function(input, gpe) 
	if input.UserInputType == Enum.UserInputType.MouseButton3 then
		local Selected;
		for _, obj in pairs(Selection) do Selected = obj break end;
		if Selected then
			ViewOnExplorer(Selected);
		end
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 and UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) then
		local target = Mouse.Target;
		if target then
			ViewOnExplorer(target);
			Selection = {};
			Selection[target] = true;
			UpdateSelections();
		end
	end
end);

-- Scrollbar --

do
	-- looking back on this, this is still very ugly code that im too laze to improve --
	local function GetScrollPercent(ListObjects)
		return (Start - 1) / (#ListObjects - 3);
	end

	local Button = Zone:WaitForChild("Button");
	
	function UpdateScrollbar()
		local List = GetShowList();
		local Num = #List;
		
		local GoesOverBy = Num - #ListObjects;
		ScrollButton.Position = UDim2.new(0, 0, GetScrollPercent(List), 0);
		local IterateAmount = 1;
		for _, func in pairs(ScrollUpdates) do func() end;
		
		local ViewportRatio = Zone.AbsoluteSize.Y / (Num * TemplateSize.Y);
		if ViewportRatio < 1 then
			Scrollbar.Visible = true;
			Button.Size = UDim2.new(1, 0, 0, Zone.AbsoluteSize.Y * ViewportRatio);
		else
			Scrollbar.Visible = false;
			Start = 1;
			UpdateList(GetShowList());
		end
	end
	
	local YDelta = 0;
	local function StartScroll()
		RunService:BindToRenderStep("Scrollbar", 1, function() 
			local List = GetShowList();
			local Percentage = math.clamp((Mouse.Y - Zone.AbsolutePosition.Y) / Zone.AbsoluteSize.Y, 0, 1);
			ScrollButton.Position = UDim2.new(0, 0, Percentage, -YDelta);
			Start = math.floor(Percentage * (#List - #ListObjects)) + 1;
			UpdateList(List);
			UpdateScrollbar();
		end);
	end
	local function EndScroll()
		RunService:UnbindFromRenderStep("Scrollbar");
	end
	
	UpArrow.MouseButton1Down:Connect(function() 
		Start = math.clamp(Start - 1, 1, math.huge);
		UpdateList(GetShowList());
		UpdateScrollbar();
	end);
	DownArrow.MouseButton1Down:Connect(function() 
		local ShowList = GetShowList();
		Start = math.clamp(Start + 1, 1, math.clamp(#ShowList - #ListObjects + 1, 1, math.huge));
		UpdateList(ShowList)
		UpdateScrollbar();
	end);
	
	ScrollButton.InputBegan:Connect(function(input) 
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			StartScroll();
			YDelta = Mouse.Y - ScrollButton.AbsolutePosition.Y;
			input.Changed:Connect(function() 
				if input.UserInputState == Enum.UserInputState.End then
					EndScroll();
				end
			end);
		end
	end);
	local LastMaxZoom, LastMinZoom;
	Explorer.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			ExplorerHovering = true;
			LastMaxZoom = Client.CameraMaxZoomDistance;
			LastMinZoom = Client.CameraMinZoomDistance;
			local Head = (Client.Character or Client.CharacterAdded:Wait()):WaitForChild("Head");
			local Zoom = (workspace.CurrentCamera.CoordinateFrame.p - Head.Position).Magnitude;
			Client.CameraMaxZoomDistance = Zoom;
			Client.CameraMinZoomDistance = Zoom;
		end 
	end);
	Explorer.InputChanged:Connect(function(input) 
		if input.UserInputType == Enum.UserInputType.MouseWheel and ExplorerHovering then
			if input.Position.Z == 1 then
				Start = math.clamp(Start - 2, 1, math.huge);
				UpdateList(GetShowList());
				UpdateScrollbar();
			else
				local ShowList = GetShowList();
				Start = math.clamp(Start + 2, 1, math.clamp(#ShowList - #ListObjects + 2, 1, math.huge));
				UpdateList(ShowList)
				UpdateScrollbar();
			end
		end
	end);
	Explorer.InputEnded:Connect(function(input) 
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			ExplorerHovering = false;
			Client.CameraMaxZoomDistance = LastMaxZoom;
			Client.CameraMinZoomDistance = LastMinZoom;
		end
	end);
	
	-- our filter workspace!!

	local function FindInWorkspace(Data)
		local RetData = {};

		Data = Data:lower();

		for _, obj in pairs(workspace:GetDescendants()) do
			if obj.ClassName:lower():match(Data) then
				table.insert(RetData, obj);
			elseif obj.Name:lower():match(Data) then
				table.insert(RetData, obj);
			end
		end

		return RetData;
	end

	FilterInput.FocusLost:Connect(function(Enter) 
		if not Enter then return end;

		local Text = FilterInput.Text;
		if #Text == 0 then
			ShowDataModel();
			return;
		end

		local a = tick();
		local Data = FindInWorkspace(FilterInput.Text);
		DirectShow(Data);
	end);

	-- exit

	ExplorerExitButton.MouseButton1Click:Connect(function() 
		Gui:Destroy();
		script:Destroy();
	end);

	ExitButton(ExplorerExitButton);
end

-- Properties

do
	local PropertyScroll = Properties:WaitForChild("Scrollbar");
	local DownArrow = PropertyScroll:WaitForChild("DownArrow");
	local UpArrow = PropertyScroll:WaitForChild("UpArrow");
	local Zone = PropertyScroll:WaitForChild("Zone");
	local ScrollButton = Zone:WaitForChild("Button");
	
	local ListObjects, ShowList, Categories, Connections = {}, {}, {}, {};
	local Start = 1;
	local UpdateList, UpdateShowList;
	local CurrentLoaded;
	
	local function GetScrollPercent(ListObjects)
		return (Start - 1) / (#ListObjects - 3);
	end
	
	local function UpdateScrollbar()
		local List = ShowList;
		local Num = #List;
		
		local GoesOverBy = Num - #ListObjects;
		ScrollButton.Position = UDim2.new(0, 0, GetScrollPercent(List), 0);
		--for _, func in pairs(ScrollUpdates) do func() end;
		
		local ViewportRatio = Zone.AbsoluteSize.Y / (Num * PropertySize.Y);
		if ViewportRatio < 1 then
			PropertyScroll.Visible = true;
			ScrollButton.Size = UDim2.new(1, 0, 0, Zone.AbsoluteSize.Y * ViewportRatio);
		else
			PropertyScroll.Visible = false;
			Start = 1;
			UpdateList(ShowList);
		end
	end
	
	local YDelta = 0;
	local function StartScroll()
		RunService:BindToRenderStep("Scrollbar", 1, function() 
			local List = ShowList;
			local Percentage = math.clamp((Mouse.Y - Zone.AbsolutePosition.Y) / Zone.AbsoluteSize.Y, 0, 1);
			ScrollButton.Position = UDim2.new(0, 0, Percentage, -YDelta);
			Start = math.floor(Percentage * (#List - #ListObjects)) + 1;
			UpdateList(List);
			UpdateScrollbar();
		end);
	end
	local function EndScroll()
		RunService:UnbindFromRenderStep("Scrollbar");
	end
	
	UpArrow.MouseButton1Down:Connect(function() 
		Start = math.clamp(Start - 1, 1, math.huge);
		UpdateList(ShowList);
		UpdateScrollbar();
	end);
	DownArrow.MouseButton1Down:Connect(function() 
		Start = math.clamp(Start + 1, 1, math.clamp(#ShowList - #ListObjects + 1, 1, math.huge));
		UpdateList(ShowList)
		UpdateScrollbar();
	end);
	
	ScrollButton.InputBegan:Connect(function(input) 
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			StartScroll();
			YDelta = Mouse.Y - ScrollButton.AbsolutePosition.Y;
			input.Changed:Connect(function() 
				if input.UserInputState == Enum.UserInputState.End then
					EndScroll();
				end
			end);
		end
	end);
	local LastMaxZoom, LastMinZoom;
	Properties.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			PropertiesHovering = true;
			LastMaxZoom = Client.CameraMaxZoomDistance;
			LastMinZoom = Client.CameraMinZoomDistance;
			local Head = (Client.Character or Client.CharacterAdded:Wait()):WaitForChild("Head");
			local Zoom = (workspace.CurrentCamera.CoordinateFrame.p - Head.Position).Magnitude;
			Client.CameraMaxZoomDistance = Zoom;
			Client.CameraMinZoomDistance = Zoom;
		end 
	end);
	Properties.InputChanged:Connect(function(input) 
		if input.UserInputType == Enum.UserInputType.MouseWheel and PropertiesHovering then
			if input.Position.Z == 1 then
				Start = math.clamp(Start - 2, 1, math.huge);
				UpdateList(ShowList);
				UpdateScrollbar();
			else
				Start = math.clamp(Start + 2, 1, math.clamp(#ShowList - #ListObjects + 4, 1, math.huge));
				UpdateList(ShowList)
				UpdateScrollbar();
			end
		end
	end);
	Properties.InputEnded:Connect(function(input) 
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			PropertiesHovering = false;
			Client.CameraMaxZoomDistance = LastMaxZoom;
			Client.CameraMinZoomDistance = LastMinZoom;
		end
	end);
	
	local function FillList()
		local Size = PropertySize.Y;
		local Amount = math.floor(List.AbsoluteSize.Y / Size);
		for i = 1, Amount do
			local Object = PropertyTemplate:Clone();
			Object.Parent = PropertiesList;
			Object.Position = UDim2.new(0, 0, 0, (i - 1) * Size);
			Object.Name = ("Slot%d"):format(i);
			local ObjectData = {
				Frame = Object,
				YPosition = (i - 1) * Size,
				CurrentObject = nil,
				
				TextInput = nil,
				ButtonClick = nil
			};

			local Dropdown = Object.Category.Dropdown;
			ObjectData.Dropdown = Dropdown;
			ObjectData.Divider = Object.Divider;

			-- this is for when the strings get randomized
			do -- string
				local frame = Object:WaitForChild("string");
				local label = frame:WaitForChild("Label");
				local Box = frame:WaitForChild("Box");
				local hover = frame:WaitForChild("Hover");
				ObjectData["string"] = {Frame = frame, Label = label, Box = Box, Hover = hover};
			end;
			do -- category
				local frame = Object:WaitForChild("Category");
				local label = frame:WaitForChild("Label");
				local Hover = frame:WaitForChild("Hover");
				local Dropdown = frame:WaitForChild("Dropdown");
				local HitboxFrame = frame:WaitForChild("HitboxFrame");
				local Style = frame:WaitForChild("Style");
				ObjectData["Category"] = {Frame = frame, Label = label, HitboxFrame = HitboxFrame, Hover = Hover, 
					Dropdown = Dropdown, Style = Style};
			end;
			do -- bool
				local frame = Object:WaitForChild("bool");
				local label = frame:WaitForChild("Label");
				local Hover = frame:WaitForChild("Hover");
				local Check = frame:WaitForChild("Check");
				local Mark = Check:WaitForChild("Frame"):WaitForChild("Mark");
				ObjectData["bool"] = {Frame = frame, Label = label, Check = Check, Hover = Hover, Mark = Mark};
			end;
			do -- int
				local frame = Object:WaitForChild("int");
				local label = frame:WaitForChild("Label");
				local Hover = frame:WaitForChild("Hover");
				local Box = frame:WaitForChild("Box");
				ObjectData["int"] = {Frame = frame, Label = label, Box = Box, Hover = hover};
			end;
			do -- float
				local frame = Object:WaitForChild("float");
				local label = frame:WaitForChild("Label");
				local Hover = frame:WaitForChild("Hover");
				local Box = frame:WaitForChild("Box");
				ObjectData["float"] = {Frame = frame, Label = label, Box = Box, Hover = hover};
			end;
			do -- Color3
				local frame = Object:WaitForChild("Color3");
				local label = frame:WaitForChild("Label");
				local Hover = frame:WaitForChild("Hover");
				local Box = frame:WaitForChild("Box");
				local Click = frame:WaitForChild("Click");
				ObjectData["Color3"] = {Frame = frame, Label = label, Box = Box, Hover = hover, Click = Click};
			end;
			
			ObjectData.Dropdown.MouseButton1Down:Connect(function() 
				if not ObjectData.CurrentObject then return end;
				ObjectData.CurrentObject.DropdownOpened = not ObjectData.CurrentObject.DropdownOpened;
				if not ObjectData.CurrentObject.DropdownOpened then
					ObjectData.Dropdown.Rotation = -90;
				else
					ObjectData.Dropdown.Rotation = 0;
				end
				UpdateShowList();
				UpdateList(ShowList)
			end);
				
			-- event types (Object, EventArguments) :
			-- TextInput : Textbox.FocusLost
			-- ButtonClick : TextButton.MouseButton1Click
			-- ButtonHover (bool hovering) : TextButton.MouseEnter/TextButton.MouseLeave
				
			-- connecting up connections --
				
			for _, obj in pairs(Object:GetDescendants()) do
				if obj:IsA("TextBox") then
					obj.FocusLost:Connect(function(...) 
						if ObjectData.TextInput then
							ObjectData.TextInput(obj, ...);
						end
					end);
				elseif obj:IsA("TextButton") or obj:IsA("ImageButton") then
					obj.MouseButton1Down:Connect(function(...) 
						if ObjectData.ButtonClick then
							ObjectData.ButtonClick(obj, ...);
						end
					end);
					obj.MouseEnter:Connect(function() 
						if ObjectData.ButtonHover then
							ObjectData.ButtonHover(obj, true);
						end
					end);
					obj.MouseLeave:Connect(function() 
						if ObjectData.ButtonHover then
							ObjectData.ButtonHover(obj, false);
						end
					end);
				end
			end
			
			-- ok --
				
			table.insert(ListObjects, ObjectData);
		end
	end
	
	function UpdateList(ShowList)
		-- Need to change so everything isn't being indexed by name and rather by a reference w/ Name Randomization 
		for i = Start, Start + #ListObjects - 1 do
			local Object = ShowList[i];
			local ObjectFrame = ListObjects[i - Start + 1];
			-- ObjectFrame = ObjectData
			-- Object = Property
			if Object then
				ObjectFrame.CurrentObject = Object;
				for _, child in pairs(ObjectFrame.Frame:GetChildren()) do
					child.Visible = false;
				end
				local ValueType = Object.ValueType;
				local Frame = ObjectFrame.Frame;

				--local ValueFrame = Frame:FindFirstChild(ValueType);
				local ValueFrame = ObjectFrame[ValueType];
				
				if not ObjectFrame.CurrentObject.DropdownOpened then
					ObjectFrame.Dropdown.Rotation = -90;
				else
					ObjectFrame.Dropdown.Rotation = 0;
				end
				if ValueFrame then
					ValueFrame.Label.Text = Object.Name;
					ValueFrame.Frame.Visible = true;
					ObjectFrame.Divider.Visible = true;
					
					if Object.ReadOnly then
						ValueFrame.Label.TextColor3 = ReadOnlyColor;
					else
						ValueFrame.Label.TextColor3 = TextColor;
					end
					
					-- TODO --
					-- this is the part where you control the properties such as changing them and showing them! --
					-- add all roblox datatypes and not just have string and boolean --
					
					if ValueType == "string" then
						ValueFrame.Box.Text = tostring(Object.Value);
						if Object.ReadOnly then
							ValueFrame.Box.TextColor3 = ReadOnlyColor;
							ValueFrame.Box.TextEditable = false;
						else
							ValueFrame.Box.TextColor3 = TextColor;
							ValueFrame.Box.TextEditable = true;
							ObjectFrame.TextInput = function(object)
								if object == ValueFrame.Box then
									CurrentLoaded[Object.Name] = ValueFrame.Box.Text;
								end
							end
						end
					elseif ValueType == "bool" then
						if Object.Value then
							ValueFrame.Mark.Visible = true;
						else
							ValueFrame.Mark.Visible = false;
						end
						if Object.ReadOnly then
							ValueFrame.Mark.ImageColor3 = ReadOnlyColor;
							ValueFrame.Mark.Parent.BackgroundColor3 = Color3.fromRGB(80, 80, 80);
						else
							ValueFrame.Mark.ImageColor3 = CheckmarkBlue;
							ValueFrame.Mark.Parent.BackgroundColor3 = CheckmarkBackground;
							ObjectFrame.ButtonClick = function(object)
								if object == ValueFrame.Check then
									CurrentLoaded[Object.Name] = not CurrentLoaded[Object.Name];
									ValueFrame.Mark.Visible = CurrentLoaded[Object.Name];
								end
							end
						end
					elseif ValueType == "int" or ValueType == "float" then
						ValueFrame.Box.Text = tostring(("%.03f"):format(Object.Value));
						if Object.ReadOnly then
							ValueFrame.Box.TextColor3 = ReadOnlyColor;
							ValueFrame.Box.TextEditable = false;
						else
							ValueFrame.Box.TextColor3 = TextColor;
							ValueFrame.Box.TextEditable = true;
							ObjectFrame.TextInput = function(object)
								if object == ValueFrame.Box then
									CurrentLoaded[Object.Name] = tonumber(ValueFrame.Box.Text);
								end
							end
						end
					elseif ValueType == "Color3" then
						local a = Object.Value;
						ValueFrame.Box.Text = ("[Color] %d, %d, %d"):format(a.r * 255, a.g * 255, a.b * 255);
						if Object.ReadOnly then
							ValueFrame.Box.TextColor3 = ReadOnlyColor;
						else
							ValueFrame.Box.TextColor3 = TextColor;
							ObjectFrame.ButtonClick = function(object)
								if object == ValueFrame.Click then
									ColorObject:new(TemplateFrame, a, function(color) 
										CurrentLoaded[Object.Name] = color;
									end):show();
								end
							end
						end
					end
				end
			else
				for _, child in pairs(ObjectFrame.Frame:GetChildren()) do
					child.Visible = false;
				end
			end
		end
	end
	
	local function DropdownLoop(Data, ShowList)
		if Data.DropdownOpened then
			for _, property in pairs(Data.Dropdown) do
				if PropertyTemplate:FindFirstChild(property.ValueType) then
					property.Value = CurrentLoaded[property.Name];
					table.insert(ShowList, property);
					DropdownLoop(property, ShowList);
				else
					--warn(("Unsupported data type %s, making string"):format(property.ValueType));
					property.ValueType = "string";
					property.Value = tostring(property.Value);
					table.insert(ShowList, property);
					DropdownLoop(property, ShowList);
				end
			end
		end
	end
	function UpdateShowList()
		local new = {}
		for _, data in pairs(ShowList) do
			if data.ValueType == "Category" then
				table.insert(new, data);
				DropdownLoop(data, new);
			end
		end
		ShowList = new;
	end

	function LoadProperties(Object)
		if CurrentLoaded == Object then return end;
		for _, connection in pairs(Connections) do connection:Disconnect() end;
		UpdateScrollbar();
		Connections = {};
		CurrentLoaded = Object;
		local Data = ClassProperties[Object.ClassName];
		local Properties = Data.Properties;
		Categories = {};
		for name, property in pairs(Properties) do
			local category = property.Category;
			if Categories[category] == nil then
				Categories[category] = {};
			end
			local list = Categories[category];
			local s, v = pcall(function() return Object[name] end);
			if s and property.Deprecated ~= true then
				table.insert(list, {
					Value = Object[name],
					Name = name,
					DropdownOpened = false,
					-- eventually will make it so you can like dropdown on XYZ and get individual number slots for each one like the
					-- real explorer
					Dropdown = {
						-- {"Number", 50, print}
					},
					ValueType = property.ValueType,
					ReadOnly = property.ReadOnly,
					Deprecated = property.Deprecated
				});
			end
		end
		
		local NewCategories = {};
		for category, properties in pairs(Categories) do
			table.insert(NewCategories, {category, properties});
		end
		

		-- this isn't techincally mimicing the real explorer as the real explorer only sorts into alphabetical order
		-- for the categories then for the properties but oh well
		table.sort(NewCategories, function(a, b) 
			return sort_alphabetical(a[1]:sub(1,1), b[1]:sub(1,1));
		end)
		
		ShowList = {};
		for _, data in pairs(NewCategories) do
			local category, properties = unpack(data);
			local Data = {
				Value = nil,
				Name = category,
				DropdownOpened = true,
				Dropdown = properties,
				ValueType = "Category",
			};
			table.insert(ShowList, Data);
			DropdownLoop(Data, ShowList);
		end
		
		UpdateList(ShowList);
	end

	FillList()
end

-- script viewer

do
	
	local CodeReview = Gui:WaitForChild("CodeReview");
	local Code = CodeReview:WaitForChild("Code");
	local HorizontalOutline = CodeReview:WaitForChild("HorizontalOutline");
	local VerticalOutline = CodeReview:WaitForChild("VerticalOutline");
	local EditorFrame = Code:WaitForChild("Editor");
	local LineNumbers = Code:WaitForChild("LineNumbers");
	local TabList = CodeReview:WaitForChild("TabList");
	local TabFrame = TabList:WaitForChild("Frame");
	local TabTemplate = TabFrame:WaitForChild("Template");
	local Ribbon = CodeReview:WaitForChild("Ribbon");
	local Clipboard = Ribbon:WaitForChild("Clipboard");
	local Folder = Ribbon:WaitForChild("Folder");
	local Exit = Ribbon:WaitForChild("Exit");
	local Title = Ribbon:WaitForChild("Title");
	local Finder = CodeReview:WaitForChild("Finder");
	local FinderInput = Finder:WaitForChild("Input");
	local Matches = Finder:WaitForChild("Matches");
	local UpArrow = Finder:WaitForChild("UpArrow");
	local DownArrow = Finder:WaitForChild("DownArrow");
	local FinderExit = Finder:WaitForChild("Exit");
	local Template = TabTemplate:Clone(); TabTemplate:Destroy();
	
	do
	
		local Lexer;
		-- lost my own lexer and too lazy to recreate, using a modified penlight lexer as it's fast and already made
		if RunService:IsStudio() then
			Lexer = require(ReplicatedStorage.Lexer).scan;
		else
			local String = game:HttpGet("https://pastebin.com/raw/1FkZFmhb");
			Lexer = loadstring(String)().scan;
		end
		
		local TabSelectionColor = Color3.fromRGB(37, 37, 37);
		local TabColor = Color3.fromRGB(53, 53, 53);
		local CurrentScript = nil;
		
		-- MONOKAI THEME --
		local Colors = {
			Selection = Color3.fromRGB(68, 71, 90),
			Comment = Color3.fromRGB(121, 121, 121),
			InbuiltFunction = Color3.fromRGB(102, 217, 239),
			Function = Color3.fromRGB(226, 226, 226),
			Orange = Color3.fromRGB(255, 184, 108),
			Keyword = Color3.fromRGB(249, 38, 114),
			Operator = Color3.fromRGB(248, 248, 242),
			Red = Color3.fromRGB(255, 85, 85),
			String = Color3.fromRGB(230, 219, 90),
			Text = Color3.fromRGB(248, 248, 242),
			Number = Color3.fromRGB(174, 129, 255)
		};
		
		local function CenterUI()
			local Absolute = Gui.AbsoluteSize;
			local Size = CodeReview.AbsoluteSize;
			local X, Y = Absolute.X / 2 - (Size.X / 2), Absolute.Y / 2 - (Size.Y / 2);
			CodeReview.Position = UDim2.new(0, X, 0, Y);
		end
		
		local function GetColor(token)
			if token == "keyword" then
				return Colors.Keyword;
			elseif token == "builtin" then
				return Colors.InbuiltFunction;
			elseif token == "string" then
				return Colors.String;
			elseif token == "comment" then
				return Colors.Comment;
			elseif token == "iden" then
				return Colors.Function;
			elseif token == "number" then
				return Colors.Number;
			elseif token:match("%p") then
				return Colors.Operator;
			else
				return Colors.Text;
			end
		end
		
		local function ShowCode(String)
			local CurrentLine = 0;
			local _, NumberLines = String:gsub("\n","");
			NumberLines = NumberLines + 1;
			
			local LineSize, FontSize, Font = 20, 22, "SourceSans";
			local CurrentX, CurrentY = 0, 0;
			
			local Data = {};
			for token, src in Lexer(String) do
				if src:find("\n") then
					local _, NumberLines = src:gsub("\n","");
					local x, num = src, 0;
					while true do
						local d = x:find("\n");
						if not d then break end;
						local str = x:sub(1, d - 1);
						if num ~= 0 then table.insert(Data, {token, "\n"}) end;
						table.insert(Data, {token, str});
						x = x:sub(d + 1);
						num = num + 1;
					end
					table.insert(Data, {token, "\n"});
					table.insert(Data, {token, x});
				else
					table.insert(Data, {token, src});
				end
			end

			local function UpdateVertical()
				local SizeY, CurrentSize = (NumberLines - 1) * LineSize, Code.AbsoluteSize.Y;
				if CurrentSize < SizeY then
					Code.CanvasSize = UDim2.new(0, 0, 0, SizeY + LineSize * 2);
					VerticalOutline.Visible = true;
				else
					Code.CanvasSize = UDim2.new(0, 0, 0, 0);
					VerticalOutline.Visible = false;
				end
			end
			
			local SpaceSize;
			
			for i, data in pairs(Data) do
				--if i % 20 == 0 then RunService.RenderStepped:Wait() UpdateVertical() end

				local token, src = unpack(data);
				local Color = GetColor(token);
				local ThisLineSize = LineSize;
				local good = true;
				
				if src:sub(1,1) == "\n" then
					CurrentX = 0;
					CurrentY = CurrentY + LineSize;
					src = src:sub(src:find("\n") + 1);
					if #src == 1 then
						good = false;
					end
				end
				if src == " " and SpaceSize then
					good = false;
					CurrentX = CurrentX + SpaceSize;
				end
				if good then
					local Label = Instance.new("TextLabel");
					local _, extra = src:gsub("\t", "");
					--extra = extra * 15;
					extra = extra * (6 * 4)
					
					local Size = Vector2.new();
					Label.TextColor3 = Color;
					Label.TextXAlignment = "Left";
					Label.Text = src;
					Label.TextSize = FontSize;
					Label.BackgroundTransparency = 1;
					Label.Parent = EditorFrame;
					Label.Font = Font;
					Size = Vector2.new(Label.TextBounds.X + extra, 20);
					Label.Size = UDim2.new(0, Size.X, 0, ThisLineSize);
					Label.Position = UDim2.new(0, CurrentX + extra, 0, CurrentY);
					Label.Name = ("Line%d"):format((CurrentY / LineSize) + 1);
					
					if src == " " then
						SpaceSize = Label.TextBounds.X;
					end
					
					if Size.X == 0 then
						Label:Destroy();
					end
					
					CurrentX = CurrentX + Size.X;
				end
			end
			
			for i = 1, NumberLines do
				local Label = Instance.new("TextLabel");
				Label.Size = UDim2.new(0.6, 0, 0, 20);
				Label.Position = UDim2.new(0.6, 0, 0, (i - 1) * LineSize);
				Label.BackgroundTransparency = 1;
				Label.AnchorPoint = Vector2.new(0.5, 0);
				Label.Font = "SourceSansSemibold";
				Label.TextScaled = true;
				Label.TextColor3 = Color3.fromRGB(166, 166, 166);
				Label.Text = tostring(i);
				Label.Parent = LineNumbers;
			end
			
			UpdateVertical();
			
			local Size = math.clamp((#tostring(NumberLines)) * 12, 35, math.huge);
			LineNumbers.Size = UDim2.new(0, Size, 1, 0);
			EditorFrame.Position = UDim2.new(0, Size + 5, 0, 0);
			
			if false then -- todo : horizontal scaling
				
			else
				HorizontalOutline.Visible = false;
			end
		end
		
		local function ClearEditor()
			EditorFrame:ClearAllChildren();
			for _, obj in pairs(LineNumbers:GetChildren()) do
				if obj.Name ~= "VerticalOutline" then
					obj:Destroy()
				end
			end
		end
		
		do
			local Scripts = {};
			ScriptEditor = {
				Code = nil,
				IsScript = false,
				CreateScript = function(s, name, code)	
					local self = {};
					for k, v in pairs(s) do self[k] = v end;
					self.Code = code;
					self.IsScript = true;
					self.original = s;
					self.Name = name;
					
					local Clone = Template:Clone();
					local Label = Clone:WaitForChild("Label");
					local Exit = Clone:WaitForChild("Close");
					self.Button = Clone;
					
					Label.Text = name;
					Clone.Parent = TabFrame;
					Clone.Size = UDim2.new(0, Label.TextBounds.X + 30, 1, 0);
					
					Clone.MouseButton1Click:Connect(function() 
						self:Select();
					end)
					Exit.MouseButton1Click:Connect(function() 
						self:Close();
					end);
					ExitButton(Exit);

					self:Select();
					
					table.insert(Scripts, self);
					
					return self;
				end,
				Select = function(self)
					self.original:UnselectAll();
					ClearEditor();
					ShowCode(self.Code);
					self.Button.BackgroundColor3 = TabSelectionColor;
					CurrentScript = self;
					Title.Text = ("Script Viewer - %s"):format(self.Name);
				end,
				Unselect = function(self)
					self.Button.BackgroundColor3 = TabColor;
				end,
				Close = function(self)
					if CurrentScript == self then 
						CurrentScript = nil;
						Title.Text = "Script Viewer";
					end;
					self.Button:Destroy();
					for i, s in pairs(Scripts) do
						if s == self then
							if Scripts[i - 1] then
								Scripts[i - 1]:Select();
							elseif Scripts[i + 1] then
								Scripts[i + 1]:Select();
							else
								ClearEditor();
							end
							table.remove(Scripts, i);
							break;
						end
					end
				end,
				UnselectAll = function(self)
					if self.IsScript == false then
						for _, sc in pairs(Scripts) do
							sc:Unselect();
						end
					end
				end,
				Show = function(self)
					CodeReview.Visible = true;
					CenterUI();
				end,
				Hide = function(self)
					CodeReview.Visible = false;
				end
			}
		end
		
		-- Topbar / Ribbon Stuff
		Exit.MouseButton1Click:Connect(function() 
			ScriptEditor:Hide();
		end);
		ExitButton(Exit);

		Folder.MouseButton1Click:Connect(function() 
			if CurrentScript then 
				writefile(("%s.lua"):format(CurrentScript.Name), CurrentScript.Code);
			end
		end);
		Clipboard.MouseButton1Click:Connect(function()
			if CurrentScript then 
				setclipboard(CurrentScript.Code);
			end
		end);
		
		-- so the camera script doesn't zoom in and out during scrolling
		-- still breaks sometimes NICE
		local LastMaxZoom, LastMinZoom;
		CodeReview.MouseEnter:Connect(function() 
			LastMaxZoom = Client.CameraMaxZoomDistance;
			LastMinZoom = Client.CameraMinZoomDistance;
			local Head = (Client.Character or Client.CharacterAdded:Wait()):WaitForChild("Head");
			local Zoom = (workspace.CurrentCamera.CoordinateFrame.p - Head.Position).Magnitude;
			Client.CameraMaxZoomDistance = Zoom;
			Client.CameraMinZoomDistance = Zoom;
		end);
		CodeReview.MouseLeave:Connect(function() 
			Client.CameraMaxZoomDistance = LastMaxZoom;
			Client.CameraMinZoomDistance = LastMinZoom;
		end);
		
		CenterUI();
		
		-- Shift + F for word finder
		local NumKeysDown = 0;
		local function NewFunc(name, state)
			if state == Enum.UserInputState.Begin then
				NumKeysDown = NumKeysDown + 1;
			else
				NumKeysDown = math.clamp(NumKeysDown - 1, 0, 1);
			end			
			if NumKeysDown == 2 then
				Finder.Visible = true;
				FinderInput:CaptureFocus();	
			end
			return Enum.ContextActionResult.Pass
		end
		ContextAction:BindAction("FindHotkey", NewFunc, false, Enum.KeyCode.F, Enum.KeyCode.LeftShift);
		
		-- highlight the words on new match(es)
		
		local match_location, max_matches = 0, 0;
		local matching_str = "";
		local last_wins = {};
		
		local function update_match()
			Matches.Text = ("%d of %d"):format(match_location, max_matches);
			for _, label in pairs(last_wins) do
				label.BackgroundTransparency = 1;
			end
			local code = CurrentScript;
			if code then
				code = code.Code;
				local matches, bad_code = {}, code;
				while true do
					local match = bad_code:find(matching_str);
					if not match then break end;
					table.insert(matches, match);
					bad_code = bad_code:sub(match + 1);
				end
				
				local selected = matches[match_location];
				if selected then
					local codetil = code:sub(1, selected);
					local _, lines = codetil:gsub("\n", "");
					lines = lines + 1;
					local match_left = matching_str;
					
					local line_labels = {};
					for _, label in pairs(EditorFrame:GetChildren()) do
						if label.Name == ("Line%d"):format(lines) and label.Text:match(matching_str) then
							table.insert(line_labels, label);
						end
					end
					
					local wins = line_labels[match_location] or line_labels[1];
					
					--[[
					for i, label in pairs(line_labels) do 
						-- ffs i give up, for special characters it breaks and for having it 
						--work over multiple text labels
						if label.Text:match(match_left) then
							local add = 0;
							local good = true;
							repeat
								local next_label = line_labels[i + add];
								if next_label and next_label.Text:match(match_left) then
									add = add + 1;
									local num = label.Text:match(match_left);
									match_left = match_left:sub(#num + 1);
									if #match_left == 0 then break end;
								else
									good = false;
									break
								end
							until not good or line_labels[i + add] == nil or #match_left == 0;
							if not good then
								match_left = matching_str;
							else
								table.insert(wins, label);
								break
							end
							table.insert(wins, label);
							break;
						end
					end
					]]
					
					for i, label in pairs({wins}) do
						if i == 1 then
							Code.CanvasPosition = Vector2.new(0, label.Position.Y.Offset);
						end
						label.BackgroundColor3 = Colors.Selection;
						label.BackgroundTransparency = 0;
					end
					last_wins = {wins};
				end
			end
		end
		
		local function find(str)
			if #str == 0 then return end;
			match_location = 1;
			matching_str = str:gsub("[%(%)%.]+", "%%%1");
			local code = CurrentScript;
			if code then
				code = code.Code;
				local _, matches = code:gsub(str, "");
				max_matches = matches;
				update_match();
			end
		end
		
		ExitButton(FinderExit);
		FinderExit.MouseButton1Click:Connect(function() 
			Finder.Visible = false;
			for _, label in pairs(last_wins) do
				label.BackgroundTransparency = 1;
			end
		end)
		DownArrow.MouseButton1Click:Connect(function() 
			match_location = match_location + 1;
			if match_location > max_matches then
				match_location = 1;
			end
			update_match();
		end);
		UpArrow.MouseButton1Click:Connect(function() 
			match_location = match_location - 1;
			if match_location <= 0 then
				match_location = max_matches;
			end
			update_match();
		end);
		
		FinderInput.FocusLost:Connect(function() 
			find(FinderInput.Text);
		end);
			
		update_match();
	
	end
end

-- loading --

local function Load()
	local OriginalSize = ExplorerFrame.Size;
	local OriginalSize2 = PropertiesFrame.Size;
	
	ExplorerFrame.ClipsDescendants = true;
	PropertiesFrame.ClipsDescendants = true;
	
	ExplorerFrame.Size = UDim2.new(OriginalSize.X.Scale, OriginalSize.X.Offset, 0, 0);
	PropertiesFrame.Size = UDim2.new(OriginalSize2.X.Scale, OriginalSize2.X.Offset, 0, 0);
	
	ExplorerFrame.Visible = true;
	PropertiesFrame.Visible = true;
	
	ExplorerFrame:TweenSize(OriginalSize, 1, Enum.EasingStyle.Linear, 0.2, 1);
	wait(0.2);
	PropertiesFrame:TweenSize(OriginalSize2, 1, Enum.EasingStyle.Linear, 0.2, 1);
	wait(0.2);
	
	ExplorerFrame.ClipsDescendants = false;
	PropertiesFrame.ClipsDescendants = false;
	
end

-----------

local function Boot()
	local CodeReview = Gui:WaitForChild("CodeReview");

	drag(ExplorerFrame:WaitForChild("Topbar"), ExplorerFrame);
	drag(CodeReview:WaitForChild("Ribbon"), CodeReview);
	
	FillList();
	UpdateList(GetShowList());
	UpdateScrollbar();
	local function HoverUpdates()
		GetFurthestOut();
		for _, object in pairs(ListObjects) do
			object:UpdateHoverEnd();
		end
	end
	table.insert(ChildAddedUpdates, HoverUpdates);
	table.insert(ScrollUpdates, HoverUpdates);
	table.insert(ScrollUpdates, UpdateSelections);
	
	delay(0, Load);

	-- for studio testing --
	if RunService:IsStudio() then
		delay(1, function()
			--[[
			ScriptEditor:Show();
			ScriptEditor:CreateScript("test", 'print("Hello World!")\n--comment\nfor i = 1, 25 / 5 do\n\tlocal bye = 1;\nend');

			Notify:new("an error", "an error");]]
		end);
	else
		Gui.Name = RandomString(10);
		for _, object in pairs(Gui:GetDescendants()) do
			object.Name = RandomString(10);
		end

		Gui.Parent = game:GetService("CoreGui");
	end
	
	-- temporary?
	
	RunService.RenderStepped:Connect(function() 
		PropertiesFrame.Position = ExplorerFrame.Position + UDim2.new(0, 0, 0, ExplorerFrame.AbsoluteSize.Y);
	end);
	ExplorerFrame:GetPropertyChangedSignal("ZIndex"):Connect(function() 
		SetZIndex(PropertiesFrame, ExplorerFrame.ZIndex - 1);
	end);
	
	--print("Successfully booted in " .. tostring(tick() - START) .. " seconds!");
end

Boot();