# Table of contents
+ [About](#about) 
+ [API](#api) 
  + [General notes](#general_notes) 
  + [DropdownMenu](#dropdownmenu) 
  + [CheckBox](#checkbox) 
  + [Tri-state checkbox](#tristatecheckbox)
  + [ColorPicker](#colorpickerdesc)
  + [Button](#buttondesc)
  + [Slider](#sliderdesc)
  + [Tooltip](#tooltipdesc)
+ [Examples](#example1) 
 
<a name="about" />

# About 
LibRedDropdown is another library that allows devs to add some standard GUI elements into their addons. Initially this lib was created to replace Blizzard's UIDropDownMenu; now it contains 6 controls.
<a name="api"/>
<br /><br /><br />
# API
<a name="general_notes"/>

## General notes
Getting lib instance:
``` lua
local libRedDropdown = LibStub("LibRedDropdown-1.0");
```
All element constructors are static, you should call it like `lib.CreateControl()` (using dot). All element methods are instance methods, you should call it like `element:SomeMethod()` (using colon).  
Basically, you should call `:SetParent` and `:SetPoint` methods for all elements after creating.  
  
<br /><a name="dropdownmenu"/><br />
## > DropdownMenu
![dropdownmenu.gif](docs/dropdownmenu.gif)  
Replacement for Blizzard's UIDropDownMenu.  
### Constructor
``` lua
local dropdownMenu = libRedDropdown.CreateDropdownMenu();
```
### Methods
| Method | Description |
|--------------------------------------------------------------------------|-----------------------------------------|
| dropdownMenu:SetList(_table_ entities, _boolean_ dontUpdateInternalList) | Sets list of entities. [Details](#example1) |
| dropdownMenu:GetButtonByText(_string_ text)                              | Returns button with specified text on it (or `nil` if no button found). |
  
<br /><a name="checkbox"/><br />
## > CheckBox
Checkbox with clickable label. It's inherited from Blizzard's _CheckButton_ so you can use all its methods
### Constructor  
```lua
local checkbox = libRedDropdown.CreateCheckBox();
```
### Methods  
| Method | Description |
|---------------------------------------------|----------------------------------------------|
| checkbox:SetText(_string_ text)             | Sets text of label.                          |
| checkbox:GetText()                          | Gets text of label. |
| checkbox:GetTextObject()                    | Returns text object of label (_FontString_). |
| checkbox:SetOnClickHandler(_function_ func) | Sets `OnClick` handler. [Details](#example4) |
  
<br /><a name="tristatecheckbox"/><br />
## > Tri-state checkbox
![tristatechckbox.gif](docs/tristatechckbox.gif)  
Checkbox with three states: disabled, enabled#1 and enabled#2
### Constructor  
```lua
local triStateCheckbox = libRedDropdown.CreateCheckBoxTristate();
```
### Methods
| Method | Description |
|--------|-------------|
| triStateCheckbox:SetTextEntries(_table_ entries)    | Sets text values for each state. [Example](#example5)           |
| triStateCheckbox:SetTriState(_number_ state)        | Sets state of checkbox. [Example](#example5)                    |
| triStateCheckbox:GetTriState()                      | Returns the state of checkbox (_number_). [Example](#example5)  |
| triStateCheckbox:SetOnClickHandler(_function_ func) | Sets `OnClick` handler. [Example](#example5)                    |
  
<br /><a name="colorpickerdesc" /><br />
## > ColorPicker
![colorpicker.png](docs/colorpicker.png)  
Small color frame with text label
### Constructor
``` lua
local colorPicker = libRedDropdown.CreateColorPicker();
```
### Methods
| Method | Description |
|--------|-------------|
| colorPicker:GetTextObject()                                                          | Returns text object of label (_FontString_). [Example](#example6)                                                                                                           |
| colorPicker:SetText(_string_ text)                                                   | Sets text of label. [Example](#example6)                                                                                                                                    |
| colorPicker:GetText()                                                                | Returns text of label (_string_). [Example](#example6)                                                                                                                      |
| colorPicker:SetColor(_number_ red, _number_ green, _number_ blue, _number_ alpha)    | Sets color. Color values are between 0.0 and 1.0. If *alpha* is nil, it will be interpreted as 1.0 [Example](#example6)                                                     |
| colorPicker:GetColor()                                                               | Returns color (_number_ red, _number_ green, _number_ blue). [Example](#example6)                                                                                           |
| colorPicker.func                                                                     | You should assign `function(self, r, g, b, a)` to this variable. This function will be executed when any value (red, green, blue, or alpha) is changed [Example](#example6) |
  
<br /><a name="buttondesc" /><br />
## > Button
![buttor.gif](docs/button.gif)  
Just a button. But with optional independent checkbox inside it. Has sharper edges than Blizzard's one!
### Constructor
``` lua
local button = libRedDropdown.CreateButton();
```
### Methods
| Method | Description |
|--------|-------------|
| button:GetTextObject()                            | Returns text object of label (_FontString_).                           |
| button:SetText(_string_ text)                     | Sets text of label. [Example](#example7)                               |
| button:GetText()                                  | Returns text of label (_string_). [Example](#example7)                 |
| button:SetGray(_boolean_ gray)                    | "Disables" button. It's not actually disabled, it's just grayed out.   |
| button:IsGrayed()                                 | Returns "disabled" state (_boolean_).                                  |
| button:SetChecked(_boolean_ checked)              | Check/unchecks internal checkbox.                                      |
| button:GetChecked()                               | Returns true if internal checkbox is checked (_boolean_).              |
| button:SetCheckBoxVisible(_boolean_ enabled)      | Enables/disables internal checkbox                                     |
| button:GetCheckBoxVisible()                       | Returns true if internal checkbox is enabled (_boolean_).              |
| button:SetCheckBoxOnClickHandler(_function_ func) | Sets handler for checkbox-checked event. See [this example](#example4) |

  
<br /><a name="sliderdesc" /><br />
## > Slider
![slider.gif](docs/slider.gif)  
Slider with textbox. [Example](#example_slider)
### Constructor
``` lua
local slider = libRedDropdown.CreateSlider();
```
### Methods
| Method | Description |
|--------|-------------|
| slider:GetTextObject()       | Returns text object of label (_FontString_).                  |
| slider:GetBaseSliderObject() | Returns slider object (_Slider_).                             |
| slider:GetEditboxObject()    | Returns editbox object (_EditBox_).                           |
| slider:GetLowTextObject()    | Returns text object of label of minimum value (_FontString_). |
| slider:GetHighTextObject()   | Returns text object of label of maximum value (_FontString_). |

<br /><a name="tooltipdesc" /><br />
## > Tooltip
Very simple text tooltip. [Example](#example_tooltip)
### Constructor
``` lua
local tooltip = libRedDropdown.CreateTooltip();
```
### Methods
| Method | Description |
|--------|-------------|
| tooltip:SetText(_string_ text, _number_ textureID)       | Sets text (and optionally icon) of tooltip.  |
| tooltip:GetTextObject()                                  | Returns text object of label (_FontString_). |
| tooltip:SetSpellById(_number_ spellid)                   | Sets spell as info for tooltip.              |
  
<br /><br /><a name="example1" /><br />
# Examples  

***
### dropdownMenu:SetList(_table_ entities, _boolean_ dontUpdateInternalList)
_table entites_: it is a table with information about buttons that DropdownMenu should display. Valid fields of each entity:  
  * .text: button's text (string)  
  * .font: button's text font (string)  
  * .icon: button's icon (number)  
  * .func: function that will be executed on user click (function)  
  * .onEnter: function that will be executed on mouse enter (function)  
  * .onLeave: function that will be executed on mouse leave (function)  
  * .disabled: set to true to disable button - will be grayed out (boolean)  
  * .dontCloseOnClick: set to true to prevent DropdownMenu from hiding when user clicks on button in list (boolean)  
  * .checkBoxEnabled: set to true to enable button's internal checkbox (boolean) 
  * .onCheckBoxClick: handler for checkbox-checked event (function) 
  * .checkBoxState: state (checked/unchecked) of button's internal checkbox (boolean) 
  * .onCloseButtonClick: if not nil, then there will be a small "X" buttons at the right of buttons in the list. This callback will be called on press on this button (function) 
  * .buttonColor: if not nil, then button will have this color. Format: { red (0.0 - 1.0), green (0.0 - 1.0), blue (0.0 - 1.0), alpha (0.0 - 1.0) }

_boolean dontUpdateInternalList_: prevents this method from changing internal list of buttons. Used internally by searchbox.  
``` lua
local t = { };
for i = 1, 100 do
  local spellName, spellIcon = GetSpellInfo(i);
  table.insert(t, {
    icon = spellIcon,
    text = spellName,
    onEnter = function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
      GameTooltip:SetSpellByID(i);
      GameTooltip:Show();
    end,
    onLeave = function() GameTooltip:Hide(); end,
    func = function() print(i, spellName); end,
    checkBoxEnabled = true,
    onCheckBoxClick = function(checkbox)
      if (checkbox:GetChecked()) then
        print("Checked!");
      end
    end,
    checkBoxState = false,
	buttonColor = {1, 1, 0, 1},
  });
end
dropdownMenu:SetList(t);
```
***
<a name="example4" />

### checkbox:SetOnClickHandler(_function_ func)
_function func_: function to execute on click
```lua
checkbox:SetOnClickHandler(function() print("Clicked!"); end);
```
***
<a name="example5" />

### Tri-state checkbox
``` lua
local triStateCheckbox = libRedDropdown.CreateCheckBoxTristate();
triStateCheckbox:SetTextEntries({
  "Disabled",
  "Enabled#1",
  "Enabled#2",
});
triStateCheckbox:SetOnClickHandler(function(self)
  if (self:GetTriState() == 0) then
    print("Disabled");
  elseif (self:GetTriState() == 1) then
    print("Enabled#1");
  else
    print("Enabled#2");
  end
end);
triStateCheckbox:SetTriState(1); -- Set to "Enabled#1"
```
***
<a name="example6" />

### ColorPicker
``` lua
local colorPicker = libRedDropdown.CreateColorPicker();
colorPicker:SetParent(UIParent);
colorPicker:SetPoint("CENTER", 0, 0);
colorPicker:SetText("Label");
colorPicker:SetColor(1, 1, 0, 1);
colorPicker.func = function(self, r, g, b, a)
	-- some code that handles new value of r, g, b, a
end
colorPicker:Show();
```
***
<a name="example7" />

### Button
``` lua
local button = libRedDropdown.CreateButton();
button:SetParent(UIParent);
button:SetText("Click me!");
button:SetWidth(110);
button:SetHeight(20);
button:SetPoint("CENTER", 0, 0);
button:SetScript("OnClick", function(self, ...)
  print(string.format("Button with label '%s' is clicked!", self:GetText()));
end);
```
***
<a name="example_slider" />

### Slider
``` lua
local minValue, maxValue = 0.3, 3;
local slider = libRedDropdown.CreateSlider();
slider:SetParent(UIParent);
slider:SetWidth(200);
slider:SetPoint("CENTER", 0, 0);
slider:GetTextObject():SetText("Label");
slider:GetBaseSliderObject():SetValueStep(0.1);
slider:GetBaseSliderObject():SetMinMaxValues(minValue, maxValue);
slider:GetBaseSliderObject():SetValue(1.5);
slider:GetBaseSliderObject():SetScript("OnValueChanged", function(self, value)
  local actualValue = tonumber(string_format("%.1f", value));
  slider:GetEditboxObject():SetText(tostring(actualValue));
end);
slider:GetEditboxObject():SetText("1.5");
slider:GetEditboxObject():SetScript("OnEnterPressed", function(self, value)
  if (slider:GetEditboxObject():GetText() ~= "") then
    local v = tonumber(slider:GetEditboxObject():GetText());
    if (v == nil) then
      -- Value must be a number
      slider:GetEditboxObject():SetText(tostring(1.5));
    else
      if (v > maxValue) then
        v = maxValue;
      end
      if (v < minValue) then
        v = minValue;
      end
      slider:GetBaseSliderObject():SetValue(v);
    end
    slider:GetEditboxObject():ClearFocus();
  end
end);
slider.lowtext:SetText(tostring(minValue));
slider.hightext:SetText(tostring(maxValue));
```
***
<a name="example_tooltip" />

### Tooltip
``` lua
-- self-initialized
local button = libRedDropdown.CreateButton();
button:SetParent(UIParent);
button:SetText("Click me!");
button:SetWidth(110);
button:SetHeight(20);
button:SetPoint("CENTER", 0, 0);
button:SetScript("OnClick", function(self, ...)
  print(string.format("Button with label '%s' is clicked!", self:GetText()));
end);
libRedDropdown.SetTooltip(button, "I'm tooltip!", "LEFT"); -- the last argument is justification of text

-- manual
local button = libRedDropdown.CreateButton();
button:SetParent(UIParent);
button:SetText("Click me!");
button:SetWidth(110);
button:SetHeight(20);
button:SetPoint("CENTER", 0, 0);
button:SetScript("OnClick", function(self, ...)
  print(string.format("Button with label '%s' is clicked!", self:GetText()));
end);
local tooltip = libRedDropdown.CreateTooltip();
button:HookScript("OnEnter", function(self, ...)
	tooltip:ClearAllPoints();
	tooltip:SetPoint("BOTTOM", button, "TOP", 0, 0);
	tooltip:SetText("I'm tooltip!");
	tooltip:Show();
end);
button:HookScript("OnLeave", function(self, ...)
	tooltip:Hide();
end);
```
***
