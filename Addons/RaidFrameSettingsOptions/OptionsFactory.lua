local addon_name, private = ...
local addon = _G["RaidFrameSettings"]
local L = LibStub("AceLocale-3.0"):GetLocale(addon_name)
local media = LibStub("LibSharedMedia-3.0")

local options_frame = private.GetOptionsFrame()
local scroll_view = options_frame.scroll_view
local current_data_provider = "general_settings"

-- Only toggles and dropdowns etc. should update the scroll_view.
-- So menu items that could have an impact on the visibility state of others.
local function update_scroll_view_content()
  -- We have to set a new provider to retain scroll position.
  local data_provider = private.DataHandler.GetDataProvider(current_data_provider)
  scroll_view:SetDataProvider(data_provider, ScrollBoxConstants.RetainScrollPosition)
end

local function reload_associated_modules(associated_modules)
  if type(associated_modules) == "table" then
    for _, module_name in pairs(associated_modules) do
      addon:ReloadModule(module_name)
    end
  elseif type(associated_modules) == "function" then
    associated_modules()
  end
end

--------------
--- Header ---
--------------

local function header_initializer(widget, node)
  local data = node:GetData()
  widget.title:SetText(data.settings_text)
end

-----------------
--- Check Box ---
-----------------

local function toggle_initializer(widget, node)
  -- Get the node data.
  local data = node:GetData()

  -- Set the name of the setting.
  widget.settings_text:SetText(data.settings_text)

  -- Set the initial toggle state.
  widget.toggle:SetChecked(data.db_obj[data.db_key])

  -- Set the click behavior.
  widget.toggle:SetScript("OnClick", function(self)
    data.db_obj[data.db_key]= self:GetChecked()
    reload_associated_modules(data.associated_modules)
    update_scroll_view_content()
  end)
end

----------------
--- Dropdown ---
----------------

local function dropdown_initializer(widget, node)
  -- Get the node data.
  local data = node:GetData()

  -- Set the name of the setting.
  widget.settings_text:SetText(data.settings_text)

    -- Feed the dropdown.
  if data.is_multiple_choice then
    local function is_choosen(key)
      return data.db_obj and data.db_obj[key] or false
    end

    local function set_choosen(key)
      if not data.db_obj then
        return
      end

      data.db_obj[key] = not data.db_obj[key]

      reload_associated_modules(data.associated_modules)
    end

    MenuUtil.CreateCheckboxMenu(widget.dropdown, is_choosen, set_choosen, unpack(data.options))
  else
    local function is_selected(value)
      return data.db_obj[data.db_key] == value
    end

    local function set_selected(value)
      data.db_obj[data.db_key] = value
      reload_associated_modules(data.associated_modules)
      update_scroll_view_content()
    end

    MenuUtil.CreateRadioMenu(widget.dropdown, is_selected, set_selected, unpack(data.options))
  end
end

--------------
--- Slider ---
--------------

local function slider_initializer(widget, node)
  -- Get the node data.
  local data = node:GetData()

  -- Set the name of the setting.
  widget.settings_text:SetText(data.settings_text)

  -- Setup the slider.
  local min_value, max_value = data.slider_options.min_value, data.slider_options.max_value
  local slider = widget.slider
  slider:SetObeyStepOnDrag(true)
  slider:SetWidth(150)
  slider.TopText:SetText(data.db_obj[data.db_key])
  slider.TopText:Show()
  slider.MinText:SetText(min_value)
  slider.MinText:Show()
  slider.MaxText:SetText(max_value)
  slider.MaxText:Show()

  slider:Init(data.db_obj[data.db_key], min_value, max_value, data.slider_options.steps)

  local function round(number)
    return (("%%.%df"):format(data.slider_options.decimals)):format(number)
  end

  slider.Slider:SetScript("OnValueChanged", function(_, raw_value)
    local value = round(raw_value)
    data.db_obj[data.db_key] = value
    slider.TopText:SetText(value)
    reload_associated_modules(data.associated_modules)
  end)

  -- OnValueChanged will fire when the widget is reused.
  slider.Slider:SetScript("OnHide", function(self)
    self:SetScript("OnValueChanged", nil)
  end)
end

--------------------
--- Color Picker ---
--------------------

local function color_picker_initializer(widget, node)
  -- Get the node data.
  local data = node:GetData()

  -- Set the name of the setting.
  widget.settings_text:SetText(data.settings_text)

  -- Setup the color picker.
  local color_picker = widget.color_picker
  color_picker.button.background_texture:SetColorTexture(unpack(data.db_obj[data.db_key]))

  color_picker.button:SetScript("OnClick", function(self)
    local function on_color_changed()
      local r, g, b = ColorPickerFrame:GetColorRGB()
      local a = ColorPickerFrame:GetColorAlpha()
      color_picker.button.background_texture:SetColorTexture(r, g, b, a)
      data.db_obj[data.db_key] = {r, g, b, a}
      reload_associated_modules(data.associated_modules)
    end

    -- Save the old colors to restore and set the inital color picker color.
    local old_r, old_g, old_b, old_a = unpack(data.db_obj[data.db_key])
    local function on_cancel()
      color_picker.button.background_texture:SetColorTexture(old_r, old_g, old_b, old_a)
      data.db_obj[data.db_key] = {old_r, old_g, old_b, old_a}
      reload_associated_modules(data.associated_modules)
    end

    -- Setup the color picker options.
    local color_picker_options = {
      swatchFunc = on_color_changed,
      opacityFunc = on_color_changed,
      cancelFunc = on_cancel,
      hasOpacity = false,
      r = old_r,
      g = old_g,
      b = old_b,
      opacity = old_a,
    }

    -- Show the color picker frame.
    ColorPickerFrame:Hide() -- In case an old picker is still open.
    ColorPickerFrame:SetupColorPickerAndShow(color_picker_options)
  end)
end

------------------
--- Color Mode ---
------------------

local color_options = {
  "static_color",
  "gradient_start",
  "gradient_end",
}

local function update_color_mode_widget(widget, data)
  -- This is always called when a db value cahnges which is also when we have to reload modules.
  local db_obj = data.db_obj
  -- Update the color picker colors and visibility.
  -- Static
  local color_picker_static_color = widget["color_picker_static_color"]
  color_picker_static_color:Hide()
  if db_obj.color_mode == 3 then
    color_picker_static_color:Show()
    color_picker_static_color.button.background_texture:SetColorTexture(unpack(db_obj["static_color"]))
  end
  -- Gradient Start
  local color_picker_gradient_start = widget["color_picker_gradient_start"]
  color_picker_gradient_start:Hide()
  if db_obj.color_mode == 4 then
    color_picker_gradient_start:Show()
    color_picker_gradient_start.button.background_texture:SetColorTexture(unpack(db_obj["gradient_start"]))
  end
  -- Gradient End
  local color_picker_gradient_end = widget["color_picker_gradient_end"]
  color_picker_gradient_end:Hide()
  if db_obj.color_mode == 4 then
    color_picker_gradient_end:Show()
    color_picker_gradient_end.button.background_texture:SetColorTexture(unpack(db_obj["gradient_end"]))
  end
end

local function color_mode_initializer(widget, node)
  -- Get the node data.
  local data = node:GetData()

  -- Set the name of the setting.
  widget.settings_text:SetText(data.settings_text)

  -- Setup the dropdown.
  local function is_selected(index)
    update_color_mode_widget(widget, data)
    return data.db_obj.color_mode == index
  end

  -- Setup Gradient End position.
  --widget.color_picker_gradient_end:SetPoint("LEFT", widget.color_picker_gradient_start.text, "RIGHT", 10, 0 )

  local function set_selected(index)
    data.db_obj.color_mode = index
    update_color_mode_widget(widget, data)
    reload_associated_modules(data.associated_modules)
    update_scroll_view_content()
  end

  widget.dropdown:SetWidth(150)
  MenuUtil.CreateRadioMenu(widget.dropdown, is_selected, set_selected, unpack(data.color_modes))

  -- Setup the colors options.
  for _, color_option in pairs(color_options) do
    local color_picker = widget["color_picker_" .. color_option]

    -- Set the text.
    color_picker.text:SetText(L[color_option])

    -- Set the on click behavior.
    color_picker.button:SetScript("OnClick", function(self)
      -- Callback on color change.
      local function on_color_changed()
        local r, g, b = ColorPickerFrame:GetColorRGB()
        local a = ColorPickerFrame:GetColorAlpha()
        color_picker.button.background_texture:SetColorTexture(r, g, b, a)
        data.db_obj[color_option] = {r, g, b, a}
        reload_associated_modules(data.associated_modules)
        update_color_mode_widget(widget, data)
      end

      -- Save the old colors to restore and set the inital color picker color.
      local old_r, old_g, old_b, old_a = unpack(data.db_obj[color_option])
      local function on_cancel()
        color_picker.button.background_texture:SetColorTexture(old_r, old_g, old_b, old_a)
        data.db_obj[color_option] = {old_r, old_g, old_b, old_a}
        reload_associated_modules(data.associated_modules)
        update_color_mode_widget(widget, data)
      end

      -- Setup the color picker options.
      local color_picker_options = {
        swatchFunc = on_color_changed,
        opacityFunc = on_color_changed,
        cancelFunc = on_cancel,
        hasOpacity = false,
        r = old_r,
        g = old_g,
        b = old_b,
        opacity = old_a,
      }

      -- Show the color picker frame.
      ColorPickerFrame:Hide() -- In case an old picker is still open.
      ColorPickerFrame:SetupColorPickerAndShow(color_picker_options)
    end)
  end
end

--------------
--- Anchor ---
--------------

local function anchor_initializer(widget, node)
  -- Get the node data.
  local data = node:GetData()

  -- Set the name of the setting.
  widget.settings_text:SetText(data.settings_text)

  -- Setup the Layout.
  widget.dropdown_transition_text:SetText(L["to_frames"] )
  widget.dropdown_transition_text:SetPoint("LEFT", widget.point_dropdown, "RIGHT", 15, 0)
  widget.relative_point_dropdown:SetPoint("LEFT", widget.dropdown_transition_text, "RIGHT", 15, 0)

  -- Setup the dropdown menus.
  for _, v in pairs({
    "point",
    "relative_point",
  }) do
    local dropdown = widget[v .. "_dropdown"]

    local function is_selected(string)
      return data.db_obj[v] == string
    end

    local function set_selected(string)
      data.db_obj[v] = string
      reload_associated_modules(data.associated_modules)
    end

    MenuUtil.CreateRadioMenu(dropdown, is_selected, set_selected,
      {L["frame_point_top_left"], "TOPLEFT"},
      {L["frame_point_top"], "TOP"},
      {L["frame_point_top_right"], "TOPRIGHT"},
      {L["frame_point_right"], "RIGHT"},
      {L["frame_point_bottom_right"], "BOTTOMRIGHT"},
      {L["frame_point_bottom"], "BOTTOM"},
      {L["frame_point_bottom_left"], "BOTTOMLEFT"},
      {L["frame_point_left"], "LEFT"},
      {L["frame_point_center"], "CENTER"}
    )
  end

  -- Setup the offset sliders.
  local min_value, max_value = -25, 25
  for _, v in pairs({
    "offset_x",
    "offset_y",
  }) do
    local slider = widget[v .. "_slider"]
    slider:SetWidth(150)
    slider.TopText:SetText(L[v] .." (" .. data.db_obj[v] .. ")")
    slider.TopText:Show()
    slider.MinText:SetText(min_value)
    slider.MinText:Show()
    slider.MaxText:SetText(max_value)
    slider.MaxText:Show()

    slider:Init(data.db_obj[v], min_value, max_value, (math.abs(min_value) + max_value) / 1)

    slider.Slider:SetScript("OnValueChanged", function(_, value, user_input)
      data.db_obj[v] = value
      slider.TopText:SetText(L[v] .." (" .. value.. ")")
      reload_associated_modules(data.associated_modules)
    end)

    -- OnValueChanged will fire when the widget is reused.
    slider.Slider:SetScript("OnHide", function(self)
      self:SetScript("OnValueChanged", nil)
    end)
  end

  widget.offset_x_slider:SetPoint("LEFT", widget.relative_point_dropdown, "RIGHT", 10 + widget.offset_x_slider.LeftText:GetUnboundedStringWidth(), 0)
  widget.offset_y_slider:SetPoint("LEFT", widget.offset_x_slider, "RIGHT", 10 + widget.offset_y_slider.LeftText:GetUnboundedStringWidth(), 0)
end

-------------------------
--- Texture Selection ---
-------------------------
local statusbars = media:HashTable("statusbar")

-- Sort alphabetically without changing the origin.
local sorted_statusbars = {}
for k in pairs(statusbars) do
  table.insert(sorted_statusbars, k)
end
table.sort(sorted_statusbars)

local function texture_selection_initializer(widget, node)
  -- Get the node data.
  local data = node:GetData()

  -- Set the name of the setting.
  widget.settings_text:SetText(data.settings_text)

  -- Setup the dropdown.
  local function is_selected(texture_name)
    return data.db_obj["texture"] == texture_name
  end

  local function set_selected(texture_name)
    data.db_obj["texture"] = texture_name
    reload_associated_modules(data.associated_modules)
  end

  local extent = 20
  local max_characters = 12
  local max_sroll_extent = extent * max_characters

  widget.dropdown:SetWidth(150)
  widget.dropdown:SetupMenu(function(dropdown, root_description)
    root_description:SetScrollMode(max_sroll_extent)

    for _, texture_name in pairs(sorted_statusbars) do
      local radio = root_description:CreateRadio(texture_name, is_selected, set_selected, texture_name)

      radio:AddInitializer(function(widget, _, _)
        local texture = widget:AttachTexture()
        texture:SetSize(150, 18)
        texture:SetPoint("RIGHT")
        texture:SetTexture(statusbars[texture_name])

        local font_string = widget.fontString
        font_string:SetPoint("RIGHT", texture, "LEFT")
        font_string:SetTextColor(NORMAL_FONT_COLOR:GetRGB())

        local pad = 20
        local width = pad + font_string:GetUnboundedStringWidth() + texture:GetWidth()
        local height = extent

        return width, height
      end)
    end
  end)
end

----------------------
--- Font Selection ---
----------------------
local fonts = media:HashTable("font")

-- Sort alphabetically without changing the origin.
local sorted_fonts = {}
for k in pairs(fonts) do
  table.insert(sorted_fonts, k)
end
table.sort(sorted_fonts)

-- Feels kinda dirty but SetFont on an menu child is disallowed by compositor and this is the best i came up  with.
-- Anchoring to the widget itself gets ignored but anchoring to widget.fontString is possible.
-- By setting widget.fontString to an empty string we avoid it displaying anything but still rendering.
local font_frame = CreateFrame("Frame")
local font_string_pool = {}
for _, v in pairs(sorted_fonts) do
  local font_string = font_frame:CreateFontString()
  font_string:SetFont(media:Fetch("font", v), 14, nil)
  font_string:SetText(v)
  font_string_pool[v] = font_string
end

local function on_font_menu_release()
  for _, v in pairs(font_string_pool) do
    v:ClearAllPoints()
    v:SetParent(font_frame) -- This can crash the game.
  end
end

local function font_selection_initializer(widget, node)
  -- Get the node data.
  local data = node:GetData()

  -- Set the name of the setting.
  widget.settings_text:SetText(data.settings_text)

  -- Set up font selection dropdown.
  local function is_selected(font_name)
    return data.db_obj["font"] == font_name
  end

  local function set_selected(font_name)
    data.db_obj["font"] = font_name
    reload_associated_modules(data.associated_modules)
  end

  local extent = 20
  local max_characters = 12
  local max_sroll_extent = extent * max_characters

  widget.dropdown:SetWidth(150)
  widget.dropdown:SetupMenu(function(dropdown, root_description)
    root_description:SetScrollMode(max_sroll_extent)
    root_description:AddMenuReleasedCallback(on_font_menu_release)
    for _, font_name in pairs(sorted_fonts) do
      local radio = root_description:CreateRadio(font_name, is_selected, set_selected, font_name)

      radio:AddInitializer(function(widget, _, _)
        local base_font_string = widget.fontString
        base_font_string:SetText("")
        -- A bit hacky. See above note.
        local font_string = font_string_pool[font_name]
        font_string:ClearAllPoints()
        font_string:SetParent(widget)
        font_string:SetPoint("LEFT", base_font_string, "RIGHT", 5, 0)

        local pad = 20
        local width = pad + font_string:GetUnboundedStringWidth()
        local height = extent

        return width, height
      end)
    end
  end)

  -- Set up flags selection dropdown.
  local function is_choosen(flag)
    local flags = data.db_obj and data.db_obj.flags
    return flags and flags[flag] == flag or false
  end

  local function set_choosen(flag)
    local flags = data.db_obj and data.db_obj.flags
    if not flags then
        return
    end

    if flags[flag] ~= "" then
        flags[flag] = ""
    else
        flags[flag] = flag
    end

    reload_associated_modules(data.associated_modules)
  end

  widget.flags_dropdown:SetWidth(150)
  MenuUtil.CreateCheckboxMenu(widget.flags_dropdown, is_choosen, set_choosen,
    {L["outline"], "OUTLINE"},
    {L["thick"], "THICK"},
    {L["monochrome"], "MONOCHROME"}
  )

  -- Setup the font height slider.
  local min_value, max_value = 1, 30
  local slider = widget.height_slider
  slider:SetWidth(150)
  slider.TopText:SetText(L["font_height"] .." (" .. data.db_obj.height .. ")")
  slider.TopText:Show()
  slider.MinText:SetText(min_value)
  slider.MinText:Show()
  slider.MaxText:SetText(max_value)
  slider.MaxText:Show()

  slider:Init(data.db_obj.height, min_value, max_value, (max_value - min_value) / 1)

  slider.Slider:SetScript("OnValueChanged", function(_, value, user_input)
    data.db_obj.height = value
    slider.TopText:SetText(L["font_height"] .." (" .. value.. ")")
    reload_associated_modules(data.associated_modules)
  end)

  -- OnValueChanged will fire when the widget is reused.
  slider.Slider:SetScript("OnHide", function(self)
    self:SetScript("OnValueChanged", nil)
  end)
end

-----------------------------
--- Input box with button ---
-----------------------------

local function input_with_button_initializer(widget, node)
  -- Get the node data.
  local data = node:GetData()

  -- Set the name of the setting.
  widget.settings_text:SetText(data.settings_text)

  -- Set the button text.
  widget.button:SetText(data.button_text)

  -- Set the button on click behavior.
  widget.button:SetScript("OnClick", function()
    local input = widget.editbox:GetText()
    data.button_callback(input)
    update_scroll_view_content()
  end)
end

--------------
--- Button ---
--------------

local function button_initializer(widget, node)
  -- Get the node data.
  local data = node:GetData()

  -- Set the name of the setting.
  widget.settings_text:SetText(data.settings_text)

  -- Set the button text.
  widget.button:SetText(data.button_text)

  -- Set the button on click behavior.
  widget.button:SetScript("OnClick", data.button_callback)
end

local function custom_element_factory(factory, node)
  local data = node:GetData()
  if data.type == "title" then
    factory("RaidFrameSettings_HeaderTemplate", header_initializer)
  elseif data.type == "color_mode" then
    factory("RaidFrameSettings_ColorModeTemplate", color_mode_initializer)
  elseif data.type == "lsm_texture" then
    factory("RaidFrameSettings_DropdownSelectionTemplate_Texture", texture_selection_initializer)
  elseif data.type == "toggle" then
    factory("RaidFrameSettings_ToggleTemplate", toggle_initializer)
  elseif data.type == "anchor" then
    factory("RaidFrameSettings_AnchorTemplate", anchor_initializer)
  elseif data.type == "font_selection" then
    factory("RaidFrameSettings_FontSelectionTemplate", font_selection_initializer)
  elseif data.type == "color" then
    factory("RaidFrameSettings_SingleChoiceColorPicker", color_picker_initializer)
  elseif data.type == "dropdown" then
    factory("RaidFrameSettings_DropdownSelectionTemplate", dropdown_initializer)
  elseif data.type == "slider" then
    factory("RaidFrameSettings_SliderTemplate", slider_initializer)
  elseif data.type == "input_with_button" then
    factory("RaidFrameSettings_EditBoxAndButtonTemplate", input_with_button_initializer)
  elseif data.type == "button" then
    factory("RaidFrameSettings_ButtonTemplate", button_initializer)
  end
end
scroll_view:SetElementFactory(custom_element_factory)

function private.SetDataProvider(data_provider_name)
  local data_provider = private.DataHandler.GetDataProvider(data_provider_name)
  current_data_provider = data_provider_name
  scroll_view:Flush() -- This will make it jump back to the start of the scroll view.
  scroll_view:SetDataProvider(data_provider)
end


-- On first launch set to general.
private.SetDataProvider("general_settings")
