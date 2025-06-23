--[[
    Copyright (c) 2023 Krowi

    All Rights Reserved unless otherwise explicitly stated.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
]]

local lib = LibStub("Krowi_Util-1.0");

if not lib then
	return;
end

if lib.IsLoaded_deDE then
	return;
end
lib.IsLoaded_deDE = true;

local L = LibStub("AceLocale-3.0"):NewLocale("Krowi_Util-1.0", "deDE");
if not L then return end

L["Loaded"] = "Geladen";
L["Loaded Desc"] = "Zeigt an, ob das mit dem Plugin verbundene Addon geladen ist oder nicht.";
L["Requires a reload"] = "Funktioniert erst nach einem /reload.";
L["Profiles"] = "Profile";
L["Default value"] = "Vorgabewert (Standard)";
L["Unchecked"] = "Nicht aktiviert";
L["Checked"] = "Aktivert";