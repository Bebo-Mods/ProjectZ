-- forked by SharKK | SharKK#1954

local library = {count = 0, queue = {}, callbacks = {}, rainbowtable = {}, toggled = true, binds = {}, notifications = {}};
local defaults; do
    local dragger = {}; do
        local mouse        = cloneref(game:GetService("Players")).LocalPlayer:GetMouse();
        local inputService = cloneref(game:GetService('UserInputService'));
        local heartbeat    = cloneref(game:GetService("RunService")).Heartbeat;
        -- // credits to Ririchi / Inori for this cute drag function :)
        function dragger.new(frame)
            local s, event = pcall(function()
                return frame.MouseEnter
            end)
    
            if s then
                frame.Active = true;
                
                event:Connect(function()
                    local input = frame.InputBegan:Connect(function(key)
                        if key.UserInputType == Enum.UserInputType.MouseButton1 then
                            local objectPosition = Vector2.new(mouse.X - frame.AbsolutePosition.X, mouse.Y - frame.AbsolutePosition.Y);
                            while heartbeat:wait() and inputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                                pcall(function()
                                    frame:TweenPosition(UDim2.new(0, mouse.X - objectPosition.X, 0, mouse.Y - objectPosition.Y), 'Out', 'Linear', 0.1, true);
                                end)
                            end
                        end
                    end)
    
                    local leave;
                    leave = frame.MouseLeave:Connect(function()
                        input:Disconnect();
                        leave:Disconnect();
                    end)
                end)
            end
        end


        cloneref(game:GetService('UserInputService')).InputBegan:Connect(function(key, gpe)
            if (not gpe) then
                if key.KeyCode == Enum.KeyCode.RightControl then
                    library.toggled = not library.toggled;
                    for i, data in next, library.queue do
                        local pos = (library.toggled and data.p or UDim2.new(-1, 0, -0.5,0))
                        pcall(function()
                            data.w:TweenPosition(pos, (library.toggled and 'Out' or 'In'), 'Quad', 0.15, true)
                        end)
                        task.wait();
                    end
                end
            end
        end)
    end
    
    -- Themes
    library.themes = {
        Default = {
            topcolor = Color3.fromRGB(30, 30, 30),
            bgcolor = Color3.fromRGB(35, 35, 35),
            boxcolor = Color3.fromRGB(35, 35, 35),
            btncolor = Color3.fromRGB(25, 25, 25),
            dropcolor = Color3.fromRGB(25, 25, 25),
            sectncolor = Color3.fromRGB(25, 25, 25),
            bordercolor = Color3.fromRGB(60, 60, 60),
            underlinecolor = Color3.fromRGB(0, 255, 140),
            textcolor = Color3.fromRGB(255, 255, 255),
            titletextcolor = Color3.fromRGB(255, 255, 255),
            placeholdercolor = Color3.fromRGB(255, 255, 255),
            strokecolor = Color3.fromRGB(0, 0, 0),
            titlestrokecolor = Color3.fromRGB(0, 0, 0),
        },
        Midnight = {
            topcolor = Color3.fromRGB(20, 20, 30),
            bgcolor = Color3.fromRGB(25, 25, 35),
            boxcolor = Color3.fromRGB(25, 25, 35),
            btncolor = Color3.fromRGB(30, 30, 40),
            dropcolor = Color3.fromRGB(30, 30, 40),
            sectncolor = Color3.fromRGB(20, 20, 30),
            bordercolor = Color3.fromRGB(80, 80, 120),
            underlinecolor = Color3.fromRGB(100, 100, 255),
            textcolor = Color3.fromRGB(200, 200, 255),
            titletextcolor = Color3.fromRGB(200, 200, 255),
            placeholdercolor = Color3.fromRGB(150, 150, 200),
            strokecolor = Color3.fromRGB(0, 0, 0),
            titlestrokecolor = Color3.fromRGB(0, 0, 0),
        },
        Cherry = {
            topcolor = Color3.fromRGB(40, 20, 20),
            bgcolor = Color3.fromRGB(45, 25, 25),
            boxcolor = Color3.fromRGB(45, 25, 25),
            btncolor = Color3.fromRGB(35, 15, 15),
            dropcolor = Color3.fromRGB(35, 15, 15),
            sectncolor = Color3.fromRGB(35, 15, 15),
            bordercolor = Color3.fromRGB(120, 60, 60),
            underlinecolor = Color3.fromRGB(255, 50, 50),
            textcolor = Color3.fromRGB(255, 200, 200),
            titletextcolor = Color3.fromRGB(255, 200, 200),
            placeholdercolor = Color3.fromRGB(200, 150, 150),
            strokecolor = Color3.fromRGB(0, 0, 0),
            titlestrokecolor = Color3.fromRGB(0, 0, 0),
        },
        Mint = {
            topcolor = Color3.fromRGB(20, 35, 25),
            bgcolor = Color3.fromRGB(25, 40, 30),
            boxcolor = Color3.fromRGB(25, 40, 30),
            btncolor = Color3.fromRGB(15, 30, 20),
            dropcolor = Color3.fromRGB(15, 30, 20),
            sectncolor = Color3.fromRGB(15, 30, 20),
            bordercolor = Color3.fromRGB(60, 120, 80),
            underlinecolor = Color3.fromRGB(50, 255, 100),
            textcolor = Color3.fromRGB(200, 255, 200),
            titletextcolor = Color3.fromRGB(200, 255, 200),
            placeholdercolor = Color3.fromRGB(150, 200, 150),
            strokecolor = Color3.fromRGB(0, 0, 0),
            titlestrokecolor = Color3.fromRGB(0, 0, 0),
        },
        Ocean = {
            topcolor = Color3.fromRGB(20, 25, 35),
            bgcolor = Color3.fromRGB(25, 30, 40),
            boxcolor = Color3.fromRGB(25, 30, 40),
            btncolor = Color3.fromRGB(15, 20, 30),
            dropcolor = Color3.fromRGB(15, 20, 30),
            sectncolor = Color3.fromRGB(15, 20, 30),
            bordercolor = Color3.fromRGB(60, 80, 120),
            underlinecolor = Color3.fromRGB(50, 150, 255),
            textcolor = Color3.fromRGB(200, 220, 255),
            titletextcolor = Color3.fromRGB(200, 220, 255),
            placeholdercolor = Color3.fromRGB(150, 180, 220),
            strokecolor = Color3.fromRGB(0, 0, 0),
            titlestrokecolor = Color3.fromRGB(0, 0, 0),
        },
        Sunset = {
            topcolor = Color3.fromRGB(40, 25, 20),
            bgcolor = Color3.fromRGB(45, 30, 25),
            boxcolor = Color3.fromRGB(45, 30, 25),
            btncolor = Color3.fromRGB(35, 20, 15),
            dropcolor = Color3.fromRGB(35, 20, 15),
            sectncolor = Color3.fromRGB(35, 20, 15),
            bordercolor = Color3.fromRGB(120, 80, 60),
            underlinecolor = Color3.fromRGB(255, 150, 50),
            textcolor = Color3.fromRGB(255, 220, 200),
            titletextcolor = Color3.fromRGB(255, 220, 200),
            placeholdercolor = Color3.fromRGB(220, 180, 150),
            strokecolor = Color3.fromRGB(0, 0, 0),
            titlestrokecolor = Color3.fromRGB(0, 0, 0),
        },
    }

    function library:SetTheme(themeName)
        if library.themes[themeName] then
            pcall(function()
                -- Update options properly
                for k, v in pairs(library.themes[themeName]) do
                    library.options[k] = v
                end
                
                -- Update all existing UI elements
                for _, data in pairs(library.queue) do
                    pcall(function()
                        local w = data.w
                        w.BackgroundColor3 = library.options.topcolor
                        
                        -- Update underline
                        local underline = w:FindFirstChild('Underline')
                        if underline and library.options.underlinecolor ~= "rainbow" then
                            underline.BackgroundColor3 = library.options.underlinecolor
                        end
                        
                        -- Update container backgrounds
                        local container = w:FindFirstChild('container')
                        if container then
                            container.BackgroundColor3 = library.options.bgcolor
                        end
                    end)
                end
            end)
        end
    end

    local types = {}; do
        types.__index = types;
        function types.window(name, options)
            library.count = library.count + 1
            local newWindow = library:Create('Frame', {
                Name = name;
                Size = UDim2.new(0, 190, 0, 30);
                BackgroundColor3 = options.topcolor;
                BorderSizePixel = 0;
                Parent = library.container;
                Position = UDim2.new(0, (15 + (200 * library.count) - 200), 0, 0);
                ZIndex = 3;
                library:Create('TextLabel', {
                    Text = name;
                    Size = UDim2.new(1, -10, 1, 0);
                    Position = UDim2.new(0, 5, 0, 0);
                    BackgroundTransparency = 1;
                    Font = Enum.Font.Code;
                    TextSize = options.titlesize;
                    Font = options.titlefont;
                    TextColor3 = options.titletextcolor;
                    TextStrokeTransparency = library.options.titlestroke;
                    TextStrokeColor3 = library.options.titlestrokecolor;
                    ZIndex = 3;
                });
                library:Create("TextButton", {
                    Size = UDim2.new(0, 30, 0, 30);
                    Position = UDim2.new(1, -35, 0, 0);
                    BackgroundTransparency = 1;
                    Text = "-";
                    TextSize = options.titlesize;
                    Font = options.titlefont;
                    Name = 'window_toggle';
                    TextColor3 = options.titletextcolor;
                    TextStrokeTransparency = library.options.titlestroke;
                    TextStrokeColor3 = library.options.titlestrokecolor;
                    ZIndex = 3;
                });
                library:Create("Frame", {
                    Name = 'Underline';
                    Size = UDim2.new(1, 0, 0, 2);
                    Position = UDim2.new(0, 0, 1, -2);
                    BackgroundColor3 = (options.underlinecolor ~= "rainbow" and options.underlinecolor or Color3.new());
                    BorderSizePixel = 0;
                    ZIndex = 3;
                });
                library:Create('Frame', {
                    Name = 'container';
                    Position = UDim2.new(0, 0, 1, 0);
                    Size = UDim2.new(1, 0, 0, 0);
                    BorderSizePixel = 0;
                    BackgroundColor3 = options.bgcolor;
                    ClipsDescendants = false;
                    library:Create('UIListLayout', {
                        Name = 'List';
                        SortOrder = Enum.SortOrder.LayoutOrder;
                    })
                });
            })
            
            if options.underlinecolor == "rainbow" then
                table.insert(library.rainbowtable, newWindow:FindFirstChild('Underline'))
            end

            local window = setmetatable({
                count = 0;
                object = newWindow;
                container = newWindow.container;
                toggled = true;
                flags   = {};

            }, types)

            table.insert(library.queue, {
                w = window.object;
                p = window.object.Position;
            })

            newWindow:FindFirstChild("window_toggle").MouseButton1Click:Connect(function()
                window.toggled = not window.toggled;
                newWindow:FindFirstChild("window_toggle").Text = (window.toggled and "-" or "+")
                if (not window.toggled) then
                    window.container.ClipsDescendants = true;
                end
                task.wait();
                local y = 0;
                for i, v in next, window.container:GetChildren() do
                    if (not v:IsA('UIListLayout')) then
                        y = y + v.AbsoluteSize.Y;
                    end
                end 

                local targetSize = window.toggled and UDim2.new(1, 0, 0, y+5) or UDim2.new(1, 0, 0, 0);
                local targetDirection = window.toggled and "In" or "Out"

                pcall(function()
                    window.container:TweenSize(targetSize, targetDirection, "Quint", .3, true)
                end)
                task.wait(.3)
                if window.toggled then
                    window.container.ClipsDescendants = false;
                end
            end)

            return window;
        end
        
        function types:Resize()
            pcall(function()
                local y = 0;
                for i, v in next, self.container:GetChildren() do
                    if (not v:IsA('UIListLayout')) then
                        y = y + v.AbsoluteSize.Y;
                    end
                end 
                self.container.Size = UDim2.new(1, 0, 0, y+5)
            end)
        end
        
        function types:GetOrder() 
            local c = 0;
            for i, v in next, self.container:GetChildren() do
                if (not v:IsA('UIListLayout')) then
                    c = c + 1
                end
            end
            return c
        end

        function types:Label(text)
            local check = library:Create('Frame', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, 25);
                LayoutOrder = self:GetOrder();
                library:Create('TextLabel', {
                    Text = text;
                    BackgroundTransparency = 1;
                    TextColor3 = library.options.textcolor;
                    TextStrokeTransparency = library.options.textstroke;
                    TextStrokeColor3 = library.options.strokecolor;
                    Position = UDim2.new(0, 5, 0, 0);
                    Size     = UDim2.new(1, -10, 1, 0);
                    TextXAlignment = Enum.TextXAlignment.Left;
                    Font = library.options.font;
                    TextSize = library.options.fontsize;
                    TextWrapped = true;
                });
                Parent = self.container;
            });
            
            self:Resize();
        end
        
        function types:Toggle(name, options, callback)
            local default  = options.default or false;
            local location = options.location or self.flags;
            local flag     = options.flag or "";
            local callback = callback or function() end;
            
            pcall(function()
                location[flag] = default;
            end)

            local check = library:Create('Frame', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, 25);
                LayoutOrder = self:GetOrder();
                library:Create('TextLabel', {
                    Name = name;
                    Text = "\r" .. name;
                    BackgroundTransparency = 1;
                    TextColor3 = library.options.textcolor;
                    Position = UDim2.new(0, 5, 0, 0);
                    Size     = UDim2.new(1, -5, 1, 0);
                    TextXAlignment = Enum.TextXAlignment.Left;
                    Font = library.options.font;
                    TextSize = library.options.fontsize;
                    TextStrokeTransparency = library.options.textstroke;
                    TextStrokeColor3 = library.options.strokecolor;
                    library:Create('TextButton', {
                        Text = (location[flag] and utf8.char(10003) or "");
                        Font = library.options.font;
                        TextSize = library.options.fontsize;
                        Name = 'Checkmark';
                        Size = UDim2.new(0, 20, 0, 20);
                        Position = UDim2.new(1, -25, 0, 4);
                        TextColor3 = library.options.textcolor;
                        BackgroundColor3 = library.options.bgcolor;
                        BorderColor3 = library.options.bordercolor;
                        TextStrokeTransparency = library.options.textstroke;
                        TextStrokeColor3 = library.options.strokecolor;
                    })
                });
                Parent = self.container;
            });
                
            local function click(t)
                pcall(function()
                    location[flag] = not location[flag];
                    callback(location[flag])
                    check:FindFirstChild(name).Checkmark.Text = location[flag] and utf8.char(10003) or "";
                end)
            end

            check:FindFirstChild(name).Checkmark.MouseButton1Click:Connect(click)
            library.callbacks[flag] = click;

            if location[flag] == true then
                pcall(function()
                    callback(location[flag])
                end)
            end

            self:Resize();
            return {
                Set = function(self, b)
                    pcall(function()
                        location[flag] = b;
                        callback(location[flag])
                        check:FindFirstChild(name).Checkmark.Text = location[flag] and utf8.char(10003) or "";
                    end)
                end
            }
        end
        
        function types:Button(name, callback)
            callback = callback or function() end;
            
            local check = library:Create('Frame', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, 25);
                LayoutOrder = self:GetOrder();
                library:Create('TextButton', {
                    Name = name;
                    Text = name;
                    BackgroundColor3 = library.options.btncolor;
                    BorderColor3 = library.options.bordercolor;
                    TextStrokeTransparency = library.options.textstroke;
                    TextStrokeColor3 = library.options.strokecolor;
                    TextColor3 = library.options.textcolor;
                    Position = UDim2.new(0, 5, 0, 5);
                    Size     = UDim2.new(1, -10, 0, 20);
                    Font = library.options.font;
                    TextSize = library.options.fontsize;
                });
                Parent = self.container;
            });
            
            check:FindFirstChild(name).MouseButton1Click:Connect(function()
                pcall(callback)
            end)
            self:Resize();

            return {
                Fire = function()
                    pcall(callback)
                end
            }
        end
        
        function types:Box(name, options, callback)
            local type   = options.type or "";
            local default = options.default or "";
            local data = options.data
            local location = options.location or self.flags;
            local flag     = options.flag or "";
            local callback = callback or function() end;
            local min      = options.min or 0;
            local max      = options.max or 9e9;

            if type == 'number' and (not tonumber(default)) then
                pcall(function()
                    location[flag] = default;
                end)
            else
                pcall(function()
                    location[flag] = "";
                end)
                default = "";
            end

            local check = library:Create('Frame', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, 25);
                LayoutOrder = self:GetOrder();
                library:Create('TextLabel', {
                    Name = name;
                    Text = "\r" .. name;
                    BackgroundTransparency = 1;
                    TextColor3 = library.options.textcolor;
                    TextStrokeTransparency = library.options.textstroke;
                    TextStrokeColor3 = library.options.strokecolor;
                    Position = UDim2.new(0, 5, 0, 0);
                    Size     = UDim2.new(1, -5, 1, 0);
                    TextXAlignment = Enum.TextXAlignment.Left;
                    Font = library.options.font;
                    TextSize = library.options.fontsize;
                    library:Create('TextBox', {
                        TextStrokeTransparency = library.options.textstroke;
                        TextStrokeColor3 = library.options.strokecolor;
                        Text = tostring(default);
                        Font = library.options.font;
                        TextSize = library.options.fontsize;
                        Name = 'Box';
                        Size = UDim2.new(0, 60, 0, 20);
                        Position = UDim2.new(1, -65, 0, 3);
                        TextColor3 = library.options.textcolor;
                        BackgroundColor3 = library.options.boxcolor;
                        BorderColor3 = library.options.bordercolor;
                        PlaceholderColor3 = library.options.placeholdercolor;
                    })
                });
                Parent = self.container;
            });
        
            local box = check:FindFirstChild(name):FindFirstChild('Box');
            box.FocusLost:Connect(function(e)
                pcall(function()
                    local old = location[flag];
                    if type == "number" then
                        local num = tonumber(box.Text)
                        if (not num) then
                            box.Text = tonumber(location[flag])
                        else
                            location[flag] = math.clamp(num, min, max)
                            box.Text = tonumber(location[flag])
                        end
                    else
                        location[flag] = tostring(box.Text)
                    end

                    callback(location[flag], old, e)
                end)
            end)
            
            if type == 'number' then
                box:GetPropertyChangedSignal('Text'):Connect(function()
                    pcall(function()
                        box.Text = string.gsub(box.Text, "[%a+]", "");
                    end)
                end)
            end
            
            self:Resize();
            return box
        end
        
        function types:Bind(name, options, callback)
            local location     = options.location or self.flags;
            local keyboardOnly = options.kbonly or false
            local flag         = options.flag or "";
            local callback     = callback or function() end;
            local default      = options.default;

            if keyboardOnly and (not tostring(default):find('MouseButton')) then
                pcall(function()
                    location[flag] = default
                end)
            end
            
            local banned = {
                Return = true;
                Space = true;
                Tab = true;
                Unknown = true;
            }
            
            local shortNames = {
                RightControl = 'RightCtrl';
                LeftControl = 'LeftCtrl';
                LeftShift = 'LShift';
                RightShift = 'RShift';
                MouseButton1 = "Mouse1";
                MouseButton2 = "Mouse2";
            }
            
            local allowed = {
                MouseButton1 = true;
                MouseButton2 = true;
            }      

            local nm = (default and (shortNames[default.Name] or default.Name) or "None");
            local check = library:Create('Frame', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, 30);
                LayoutOrder = self:GetOrder();
                library:Create('TextLabel', {
                    Name = name;
                    Text = "\r" .. name;
                    BackgroundTransparency = 1;
                    TextColor3 = library.options.textcolor;
                    Position = UDim2.new(0, 5, 0, 0);
                    Size     = UDim2.new(1, -5, 1, 0);
                    TextXAlignment = Enum.TextXAlignment.Left;
                    Font = library.options.font;
                    TextSize = library.options.fontsize;
                    TextStrokeTransparency = library.options.textstroke;
                    TextStrokeColor3 = library.options.strokecolor;
                    BorderColor3     = library.options.bordercolor;
                    BorderSizePixel  = 1;
                    library:Create('TextButton', {
                        Name = 'Keybind';
                        Text = nm;
                        TextStrokeTransparency = library.options.textstroke;
                        TextStrokeColor3 = library.options.strokecolor;
                        Font = library.options.font;
                        TextSize = library.options.fontsize;
                        Size = UDim2.new(0, 60, 0, 20);
                        Position = UDim2.new(1, -65, 0, 5);
                        TextColor3 = library.options.textcolor;
                        BackgroundColor3 = library.options.bgcolor;
                        BorderColor3     = library.options.bordercolor;
                        BorderSizePixel  = 1;
                    })
                });
                Parent = self.container;
            });
             
            local button = check:FindFirstChild(name).Keybind;
            button.MouseButton1Click:Connect(function()
                library.binding = true

                button.Text = "..."
                local a, b = cloneref(game:GetService('UserInputService')).InputBegan:Wait();
                local name = tostring(a.KeyCode.Name);
                local typeName = tostring(a.UserInputType.Name);

                if (a.UserInputType ~= Enum.UserInputType.Keyboard and (allowed[a.UserInputType.Name]) and (not keyboardOnly)) or (a.KeyCode and (not banned[a.KeyCode.Name])) then
                    local name = (a.UserInputType ~= Enum.UserInputType.Keyboard and a.UserInputType.Name or a.KeyCode.Name);
                    pcall(function()
                        location[flag] = (a);
                    end)
                    button.Text = shortNames[name] or name;
                    
                else
                    if (location[flag]) then
                        if (not pcall(function()
                            return location[flag].UserInputType
                        end)) then
                            local name = tostring(location[flag])
                            button.Text = shortNames[name] or name
                        else
                            local name = (location[flag].UserInputType ~= Enum.UserInputType.Keyboard and location[flag].UserInputType.Name or location[flag].KeyCode.Name);
                            button.Text = shortNames[name] or name;
                        end
                    end
                end

                task.wait(0.1)  
                library.binding = false;
            end)
            
            if location[flag] then
                button.Text = shortNames[tostring(location[flag].Name)] or tostring(location[flag].Name)
            end

            library.binds[flag] = {
                location = location;
                callback = callback;
            };

            self:Resize();
        end
    
        function types:Section(name)
            local order = self:GetOrder();
            local determinedSize = UDim2.new(1, 0, 0, 25)
            local determinedPos = UDim2.new(0, 0, 0, 4);
            local secondarySize = UDim2.new(1, 0, 0, 20);
                        
            if order == 0 then
                determinedSize = UDim2.new(1, 0, 0, 21)
                determinedPos = UDim2.new(0, 0, 0, -1);
                secondarySize = nil
            end
            
            local check = library:Create('Frame', {
                Name = 'Section';
                BackgroundTransparency = 1;
                Size = determinedSize;
                BackgroundColor3 = library.options.sectncolor;
                BorderSizePixel = 0;
                LayoutOrder = order;
                library:Create('TextLabel', {
                    Name = 'section_lbl';
                    Text = name;
                    BackgroundTransparency = 0;
                    BorderSizePixel = 0;
                    BackgroundColor3 = library.options.sectncolor;
                    TextColor3 = library.options.textcolor;
                    Position = determinedPos;
                    Size     = (secondarySize or UDim2.new(1, 0, 1, 0));
                    Font = library.options.font;
                    TextSize = library.options.fontsize;
                    TextStrokeTransparency = library.options.textstroke;
                    TextStrokeColor3 = library.options.strokecolor;
                });
                Parent = self.container;
            });
        
            self:Resize();
        end

        function types:Slider(name, options, callback)
            local default = options.default or options.min;
            local min     = options.min or 0;
            local max      = options.max or 1;
            local location = options.location or self.flags;
            local precise  = options.precise  or false
            local flag     = options.flag or "";
            local callback = callback or function() end

            pcall(function()
                location[flag] = default;
            end)

            local check = library:Create('Frame', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, 25);
                LayoutOrder = self:GetOrder();
                library:Create('TextLabel', {
                    Name = name;
                    TextStrokeTransparency = library.options.textstroke;
                    TextStrokeColor3 = library.options.strokecolor;
                    Text = "\r" .. name;
                    BackgroundTransparency = 1;
                    TextColor3 = library.options.textcolor;
                    Position = UDim2.new(0, 5, 0, 2);
                    Size     = UDim2.new(1, -5, 1, 0);
                    TextXAlignment = Enum.TextXAlignment.Left;
                    Font = library.options.font;
                    TextSize = library.options.fontsize;
                    library:Create('Frame', {
                        Name = 'Container';
                        Size = UDim2.new(0, 60, 0, 20);
                        Position = UDim2.new(1, -65, 0, 3);
                        BackgroundTransparency = 1;
                        BorderSizePixel = 0;
                        library:Create('TextLabel', {
                            Name = 'ValueLabel';
                            Text = default;
                            BackgroundTransparency = 1;
                            TextColor3 = library.options.textcolor;
                            Position = UDim2.new(0, -10, 0, 0);
                            Size     = UDim2.new(0, 1, 1, 0);
                            TextXAlignment = Enum.TextXAlignment.Right;
                            Font = library.options.font;
                            TextSize = library.options.fontsize;
                            TextStrokeTransparency = library.options.textstroke;
                            TextStrokeColor3 = library.options.strokecolor;
                        });
                        library:Create('TextButton', {
                            Name = 'Button';
                            Size = UDim2.new(0, 5, 1, -2);
                            Position = UDim2.new(0, 0, 0, 1);
                            AutoButtonColor = false;
                            Text = "";
                            BackgroundColor3 = Color3.fromRGB(20, 20, 20);
                            BorderSizePixel = 0;
                            ZIndex = 2;
                            TextStrokeTransparency = library.options.textstroke;
                            TextStrokeColor3 = library.options.strokecolor;
                        });
                        library:Create('Frame', {
                            Name = 'Line';
                            BackgroundTransparency = 0;
                            Position = UDim2.new(0, 0, 0.5, 0);
                            Size     = UDim2.new(1, 0, 0, 1);
                            BackgroundColor3 = library.options.textcolor;
                            BorderSizePixel = 0;
                        });
                    })
                });
                Parent = self.container;
            });

            local overlay = check:FindFirstChild(name);

            local renderSteppedConnection;
            local inputBeganConnection;
            local inputEndedConnection;
            local mouseLeaveConnection;
            local mouseDownConnection;
            local mouseUpConnection;

            check:FindFirstChild(name).Container.MouseEnter:Connect(function()
                local function update()
                    if renderSteppedConnection then renderSteppedConnection:Disconnect() end 
                    

                    renderSteppedConnection = cloneref(game:GetService('RunService')).RenderStepped:Connect(function()
                        pcall(function()
                            local mouse = cloneref(game:GetService("UserInputService")):GetMouseLocation()
                            local percent = (mouse.X - overlay.Container.AbsolutePosition.X) / (overlay.Container.AbsoluteSize.X)
                            percent = math.clamp(percent, 0, 1)
                            percent = tonumber(string.format("%.2f", percent))

                            overlay.Container.Button.Position = UDim2.new(math.clamp(percent, 0, 0.99), 0, 0, 1)
                            
                            local num = min + (max - min) * percent
                            local value = (precise and num or math.floor(num))

                            overlay.Container.ValueLabel.Text = value;
                            callback(tonumber(value))
                            location[flag] = tonumber(value)
                        end)
                    end)
                end

                local function disconnect()
                    if renderSteppedConnection then renderSteppedConnection:Disconnect() end
                    if inputBeganConnection then inputBeganConnection:Disconnect() end
                    if inputEndedConnection then inputEndedConnection:Disconnect() end
                    if mouseLeaveConnection then mouseLeaveConnection:Disconnect() end
                    if mouseUpConnection then mouseUpConnection:Disconnect() end
                end

                inputBeganConnection = check:FindFirstChild(name).Container.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        update()
                    end
                end)

                inputEndedConnection = check:FindFirstChild(name).Container.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        disconnect()
                    end
                end)

                mouseDownConnection = check:FindFirstChild(name).Container.Button.MouseButton1Down:Connect(update)
                mouseUpConnection   = cloneref(game:GetService("UserInputService")).InputEnded:Connect(function(a, b)
                    if a.UserInputType == Enum.UserInputType.MouseButton1 and (mouseDownConnection.Connected) then
                        disconnect()
                    end
                end)
            end)    

            if default ~= min then
                pcall(function()
                    local percent = 1 - ((max - default) / (max - min))
                    local number  = default 

                    number = tonumber(string.format("%.2f", number))
                    if (not precise) then
                        number = math.floor(number)
                    end

                    overlay.Container.Button.Position  = UDim2.new(math.clamp(percent, 0, 0.99), 0,  0, 1) 
                    overlay.Container.ValueLabel.Text  = number
                end)
            end

            self:Resize();
            return {
                Set = function(self, value)
                    pcall(function()
                        local percent = 1 - ((max - value) / (max - min))
                        local number  = value 

                        number = tonumber(string.format("%.2f", number))
                        if (not precise) then
                            number = math.floor(number)
                        end

                        overlay.Container.Button.Position  = UDim2.new(math.clamp(percent, 0, 0.99), 0,  0, 1) 
                        overlay.Container.ValueLabel.Text  = number
                        location[flag] = number
                        callback(number)
                    end)
                end
            }
        end 

        function types:SearchBox(text, options, callback)
            local list = options.list or {};
            local flag = options.flag or "";
            local location = options.location or self.flags;
            local callback = callback or function() end;

            local busy = false;
            local box = library:Create('Frame', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, 25);
                LayoutOrder = self:GetOrder();
                library:Create('TextBox', {
                    Text = "";
                    PlaceholderText = text;
                    PlaceholderColor3 = Color3.fromRGB(60, 60, 60);
                    Font = library.options.font;
                    TextSize = library.options.fontsize;
                    Name = 'Box';
                    Size = UDim2.new(1, -10, 0, 20);
                    Position = UDim2.new(0, 5, 0, 4);
                    TextColor3 = library.options.textcolor;
                    BackgroundColor3 = library.options.dropcolor;
                    BorderColor3 = library.options.bordercolor;
                    TextStrokeTransparency = library.options.textstroke;
                    TextStrokeColor3 = library.options.strokecolor;
                    library:Create('ScrollingFrame', {
                        Position = UDim2.new(0, 0, 1, 1);
                        Name = 'Container';
                        BackgroundColor3 = library.options.btncolor;
                        ScrollBarThickness = 0;
                        BorderSizePixel = 0;
                        BorderColor3 = library.options.bordercolor;
                        Size = UDim2.new(1, 0, 0, 0);
                        library:Create('UIListLayout', {
                            Name = 'ListLayout';
                            SortOrder = Enum.SortOrder.LayoutOrder;
                        });
                        ZIndex = 2;
                    });
                });
                Parent = self.container;
            })

            local function rebuild(text)
                pcall(function()
                    box:FindFirstChild('Box').Container.ScrollBarThickness = 0
                    for i, child in next, box:FindFirstChild('Box').Container:GetChildren() do
                        if (not child:IsA('UIListLayout')) then
                            child:Destroy();
                        end
                    end

                    if #text > 0 then
                        for i, v in next, list do
                            if string.sub(string.lower(v), 1, string.len(text)) == string.lower(text) then
                                local button = library:Create('TextButton', {
                                    Text = v;
                                    Font = library.options.font;
                                    TextSize = library.options.fontsize;
                                    TextColor3 = library.options.textcolor;
                                    BorderColor3 = library.options.bordercolor;
                                    TextStrokeTransparency = library.options.textstroke;
                                    TextStrokeColor3 = library.options.strokecolor;
                                    Parent = box:FindFirstChild('Box').Container;
                                    Size = UDim2.new(1, 0, 0, 20);
                                    LayoutOrder = i;
                                    BackgroundColor3 = library.options.btncolor;
                                    ZIndex = 2;
                                })

                                button.MouseButton1Click:Connect(function()
                                    busy = true;
                                    box:FindFirstChild('Box').Text = button.Text;
                                    task.wait();
                                    busy = false;

                                    location[flag] = button.Text;
                                    callback(location[flag])

                                    box:FindFirstChild('Box').Container.ScrollBarThickness = 0
                                    for i, child in next, box:FindFirstChild('Box').Container:GetChildren() do
                                        if (not child:IsA('UIListLayout')) then
                                            child:Destroy();
                                        end
                                    end
                                    box:FindFirstChild('Box').Container:TweenSize(UDim2.new(1, 0, 0, 0), 'Out', 'Quint', .3, true)
                                end)
                            end
                        end
                    end

                    local c = box:FindFirstChild('Box').Container:GetChildren()
                    local ry = (20 * (#c)) - 20

                    local y = math.clamp((20 * (#c)) - 20, 0, 100)
                    if ry > 100 then
                        box:FindFirstChild('Box').Container.ScrollBarThickness = 5;
                    end

                    box:FindFirstChild('Box').Container:TweenSize(UDim2.new(1, 0, 0, y), 'Out', 'Quint', .3, true)
                    box:FindFirstChild('Box').Container.CanvasSize = UDim2.new(1, 0, 0, (20 * (#c)) - 20)
                end)
            end

            box:FindFirstChild('Box'):GetPropertyChangedSignal('Text'):Connect(function()
                if (not busy) then
                    rebuild(box:FindFirstChild('Box').Text)
                end
            end);

            local function reload(new_list)
                list = new_list;
                rebuild("")
            end
            self:Resize();
            return reload, box:FindFirstChild('Box');
        end
        
        function types:Dropdown(name, options, callback)
            local location = options.location or self.flags;
            local flag = options.flag or "";
            local callback = callback or function() end;
            local list = options.list or {};

            pcall(function()
                location[flag] = list[1]
            end)

            local check = library:Create('Frame', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, 25);
                BackgroundColor3 = Color3.fromRGB(25, 25, 25);
                BorderSizePixel = 0;
                LayoutOrder = self:GetOrder();
                library:Create('Frame', {
                    Name = 'dropdown_lbl';
                    BackgroundTransparency = 0;
                    BackgroundColor3 = library.options.dropcolor;
                    Position = UDim2.new(0, 5, 0, 4);
                    BorderColor3 = library.options.bordercolor;
                    Size     = UDim2.new(1, -10, 0, 20);
                    library:Create('TextLabel', {
                        Name = 'Selection';
                        Size = UDim2.new(1, 0, 1, 0);
                        Text = list[1] or "Select...";
                        TextColor3 = library.options.textcolor;
                        BackgroundTransparency = 1;
                        Font = library.options.font;
                        TextSize = library.options.fontsize;
                        TextStrokeTransparency = library.options.textstroke;
                        TextStrokeColor3 = library.options.strokecolor;
                    });
                    library:Create("TextButton", {
                        Name = 'drop';
                        BackgroundTransparency = 1;
                        Size = UDim2.new(0, 20, 1, 0);
                        Position = UDim2.new(1, -25, 0, 0);
                        Text = 'v';
                        TextColor3 = library.options.textcolor;
                        Font = library.options.font;
                        TextSize = library.options.fontsize;
                        TextStrokeTransparency = library.options.textstroke;
                        TextStrokeColor3 = library.options.strokecolor;
                    })
                });
                Parent = self.container;
            });
            
            local button = check:FindFirstChild('dropdown_lbl').drop;
            local input;
            local container;
            
            button.MouseButton1Click:Connect(function()
                if (input and input.Connected) then
                    return
                end 
                
                pcall(function()
                    check:FindFirstChild('dropdown_lbl'):WaitForChild('Selection').TextColor3 = Color3.fromRGB(60, 60, 60);
                end)
                
                local c = 0;
                for i, v in next, list do
                    c = c + 20;
                end

                local size = UDim2.new(1, 0, 0, c)

                local clampedSize;
                local scrollSize = 0;
                if size.Y.Offset > 100 then
                    clampedSize = UDim2.new(1, 0, 0, 100)
                    scrollSize = 5;
                end
                
                local goSize = (clampedSize ~= nil and clampedSize) or size;    
                container = library:Create('ScrollingFrame', {
                    TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png';
                    BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png';
                    Name = 'DropContainer';
                    Parent = check:FindFirstChild('dropdown_lbl');
                    Size = UDim2.new(1, 0, 0, 0);
                    BackgroundColor3 = library.options.bgcolor;
                    BorderColor3 = library.options.bordercolor;
                    Position = UDim2.new(0, 0, 1, 0);
                    ScrollBarThickness = scrollSize;
                    CanvasSize = UDim2.new(0, 0, 0, size.Y.Offset);
                    ZIndex = 5;
                    ClipsDescendants = true;
                    library:Create('UIListLayout', {
                        Name = 'List';
                        SortOrder = Enum.SortOrder.LayoutOrder
                    })
                })

                for i, v in next, list do
                    local btn = library:Create('TextButton', {
                        Size = UDim2.new(1, 0, 0, 20);
                        BackgroundColor3 = library.options.btncolor;
                        BorderColor3 = library.options.bordercolor;
                        Text = v;
                        Font = library.options.font;
                        TextSize = library.options.fontsize;
                        LayoutOrder = i;
                        Parent = container;
                        ZIndex = 5;
                        TextColor3 = library.options.textcolor;
                        TextStrokeTransparency = library.options.textstroke;
                        TextStrokeColor3 = library.options.strokecolor;
                    })
                    
                    btn.MouseButton1Click:Connect(function()
                        pcall(function()
                            check:FindFirstChild('dropdown_lbl'):WaitForChild('Selection').TextColor3 = library.options.textcolor
                            check:FindFirstChild('dropdown_lbl'):WaitForChild('Selection').Text = btn.Text;

                            location[flag] = tostring(btn.Text);
                            callback(location[flag])

                            if container then
                                container:TweenSize(UDim2.new(1, 0, 0, 0), 'In', 'Quint', .3, true)
                                task.wait(0.15)
                                pcall(function()
                                    cloneref(game:GetService('Debris')):AddItem(container, 0)
                                end)
                                container = nil
                            end
                            if input then
                                input:Disconnect();
                                input = nil
                            end
                        end)
                    end)
                end
                
                container:TweenSize(goSize, 'Out', 'Quint', .3, true)
                
                local function isInGui(frame)
                    local mloc = cloneref(game:GetService('UserInputService')):GetMouseLocation();
                    local mouse = Vector2.new(mloc.X, mloc.Y - 36);
                    
                    local x1, x2 = frame.AbsolutePosition.X, frame.AbsolutePosition.X + frame.AbsoluteSize.X;
                    local y1, y2 = frame.AbsolutePosition.Y, frame.AbsolutePosition.Y + frame.AbsoluteSize.Y;
                
                    return (mouse.X >= x1 and mouse.X <= x2) and (mouse.Y >= y1 and mouse.Y <= y2)
                end
                
                input = cloneref(game:GetService('UserInputService')).InputBegan:Connect(function(a)
                    if a.UserInputType == Enum.UserInputType.MouseButton1 and (not isInGui(container)) then
                        pcall(function()
                            check:FindFirstChild('dropdown_lbl'):WaitForChild('Selection').TextColor3 = library.options.textcolor
                            
                            if container then
                                container:TweenSize(UDim2.new(1, 0, 0, 0), 'In', 'Quint', .3, true)
                                task.wait(0.15)
                                pcall(function()
                                    cloneref(game:GetService('Debris')):AddItem(container, 0)
                                end)
                                container = nil
                            end
                            if input then
                                input:Disconnect();
                                input = nil
                            end
                        end)
                    end
                end)
            end)
            
            self:Resize();
            
            local function reload(self, array)
                list = array;
                location[flag] = array[1];
                pcall(function()
                    if input then
                        input:Disconnect()
                        input = nil
                    end
                end)
                pcall(function()
                    check:WaitForChild('dropdown_lbl').Selection.Text = location[flag] or "Select..."
                    check:FindFirstChild('dropdown_lbl'):WaitForChild('Selection').TextColor3 = library.options.textcolor
                end)
                pcall(function()
                    if container then
                        cloneref(game:GetService('Debris')):AddItem(container, 0)
                        container = nil
                    end
                end)
            end

            return {
                Refresh = reload;
            }
        end

        function types:ColorSettings()
            local self = self;
            
            self:Section("Theme Selector")
            
            local themeNames = {};
            for name, _ in pairs(library.themes) do
                table.insert(themeNames, name);
            end

            local dropdown = self:Dropdown("Choose Theme", {
                list = themeNames,
                flag = "theme_selector_" .. tostring(self.object.Name),
            }, function(value)
                if value and library.themes[value] then
                    library:SetTheme(value)
                end
            end)

            self:Resize();
            return dropdown;
        end
    end
    
    function library:Create(class, data)
        local obj = Instance.new(class);
        for i, v in next, data do
            if i ~= 'Parent' then
                
                if typeof(v) == "Instance" then
                    v.Parent = obj;
                else
                    pcall(function()
                        obj[i] = v
                    end)
                end
            end
        end
        
        pcall(function()
            obj.Parent = data.Parent;
        end)
        return obj
    end
    
    function library:Notify(title, text, duration)
        duration = duration or 3
        
        local notificationCount = #library.notifications
        local startPos = UDim2.new(1, 210, 1, -10 - (60 * (notificationCount + 1)))
        local endPos = UDim2.new(1, -210, 1, -10 - (60 * (notificationCount + 1)))
        
        local notificationFrame = library:Create('Frame', {
            Name = 'Notification';
            Size = UDim2.new(0, 200, 0, 50);
            Position = startPos;
            BackgroundColor3 = library.options.topcolor;
            BorderColor3 = library.options.bordercolor;
            BorderSizePixel = 1;
            Parent = library.screenGui;
            ClipsDescendants = true;
            ZIndex = 100;
        });
        
        library:Create('TextLabel', {
            Text = title or "Notification";
            Size = UDim2.new(1, -10, 0, 20);
            Position = UDim2.new(0, 5, 0, 5);
            BackgroundTransparency = 1;
            TextColor3 = library.options.titletextcolor;
            Font = library.options.titlefont or Enum.Font.Code;
            TextSize = 14;
            TextXAlignment = Enum.TextXAlignment.Left;
            Parent = notificationFrame;
        });
        
        library:Create('TextLabel', {
            Text = text or "";
            Size = UDim2.new(1, -10, 0, 20);
            Position = UDim2.new(0, 5, 0, 25);
            BackgroundTransparency = 1;
            TextColor3 = library.options.textcolor;
            Font = library.options.font;
            TextSize = 12;
            TextXAlignment = Enum.TextXAlignment.Left;
            TextWrapped = true;
            Parent = notificationFrame;
        });

        table.insert(library.notifications, notificationFrame)
        
        -- Animate in
        pcall(function()
            notificationFrame:TweenPosition(endPos, 'Out', 'Quad', 0.3, true)
        end)
        
        -- Remove after duration
        task.delay(duration, function()
            pcall(function()
                if notificationFrame and notificationFrame.Parent then
                    notificationFrame:TweenPosition(UDim2.new(1, 210, endPos.Y.Scale, endPos.Y.Offset), 'In', 'Quad', 0.3, true)
                    task.wait(0.3)
                    notificationFrame:Destroy()
                    
                    -- Remove from table
                    for i, v in pairs(library.notifications) do
                        if v == notificationFrame then
                            table.remove(library.notifications, i)
                            break
                        end
                    end
                    
                    -- Reposition remaining notifications
                    for i, notif in pairs(library.notifications) do
                        pcall(function()
                            local newPos = UDim2.new(1, -210, 1, -10 - (60 * i))
                            notif:TweenPosition(newPos, 'Out', 'Quad', 0.3, true)
                        end)
                    end
                end
            end)
        end)
    end

	default = {
        topcolor       = Color3.fromRGB(30, 30, 30);
        titlecolor     = Color3.fromRGB(255, 255, 255);
        
        underlinecolor = Color3.fromRGB(0, 255, 140);
        bgcolor        = Color3.fromRGB(35, 35, 35);
        boxcolor       = Color3.fromRGB(35, 35, 35);
        btncolor       = Color3.fromRGB(25, 25, 25);
        dropcolor      = Color3.fromRGB(25, 25, 25);
        sectncolor     = Color3.fromRGB(25, 25, 25);
        bordercolor    = Color3.fromRGB(60, 60, 60);

        font           = Enum.Font.SourceSans;
        titlefont      = Enum.Font.Code;

        fontsize       = 17;
        titlesize      = 18;

        textstroke     = 1;
        titlestroke    = 1;

        strokecolor    = Color3.fromRGB(0, 0, 0);

        textcolor      = Color3.fromRGB(255, 255, 255);
        titletextcolor = Color3.fromRGB(255, 255, 255);

        placeholdercolor = Color3.fromRGB(255, 255, 255);
        titlestrokecolor = Color3.fromRGB(0, 0, 0);
    }
	
    function library:CreateWindow(name, options)
        if (not library.container) then
            local screenGui = self:Create("ScreenGui", {
                Name = "UILibrary";
                self:Create('Frame', {
                    Name = 'Container';
                    Size = UDim2.new(1, -30, 1, 0);
                    Position = UDim2.new(0, 20, 0, 20);
                    BackgroundTransparency = 1;
                    Active = false;
                });
                Parent = pcall(function() return gethui() end) and gethui() or 
                         pcall(function() return cloneref(game:GetService("CoreGui")) end) and cloneref(game:GetService("CoreGui")) or
                         pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui") or
                         game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
            });
            library.screenGui = screenGui
            library.container = screenGui:FindFirstChild('Container');
        end
        if (not library.options) then
			library.options = setmetatable(options or {}, {__index = defaults})
        end
		if (options) then
			for k, v in pairs(options) do
                library.options[k] = v
            end
		end
		
        local window = types.window(name, library.options);
        dragger.new(window.object);
        return window
    end

    library.options = setmetatable({}, {__index = default})

    task.spawn(function()
        while true do
            for i=0, 1, 1 / 300 do              
                for _, obj in next, library.rainbowtable do
                    pcall(function()
                        obj.BackgroundColor3 = Color3.fromHSV(i, 1, 1);
                    end)
                end
                task.wait()
            end;
        end
    end)

    local function isreallypressed(bind, inp)
        local key = bind
        if typeof(key) == "Instance" then
            if key.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode == key.KeyCode then
                return true;
            elseif tostring(key.UserInputType):find('MouseButton') and inp.UserInputType == key.UserInputType then
                return true
            end
        end
        if tostring(key):find'MouseButton1' then
            return key == inp.UserInputType
        else
            return key == inp.KeyCode
        end
    end

    cloneref(game:GetService("UserInputService")).InputBegan:Connect(function(input)
        if (not library.binding) then
            for idx, binds in next, library.binds do
                local real_binding = binds.location[idx];
                if real_binding and isreallypressed(real_binding, input) then
                    pcall(binds.callback)
                end
            end
        end
    end)
end

return library
