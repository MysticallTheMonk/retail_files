
StubbyConfig = {
	["addinfo"] = {
		["Informant"] = "Informant|Displays detailed item information in tooltips, such as use, vendor sales information, and more.",
		["Enchantrix"] = "Enchantrix|Display information in item tooltips pertaining to disenchanting, prospecting, and milling results.  [8.2.6506] This AddOn is licensed under the GNU GPL, see GPL.txt for details.",
	},
	["inspected"] = {
		["Informant"] = true,
		["Enchantrix"] = true,
	},
	["configs"] = {
		["enchantrix"] = {
			["loadtype"] = "always",
		},
		["informant"] = {
			["loadtype"] = "always",
		},
	},
	["boots"] = {
		["enchantrix"] = {
			["commandhandler"] = "		local function cmdHandler(msg)\n			local i,j, cmd, param = msg:lower():find(\"^([^ ]+) (.+)$\")\n			if (not cmd) then cmd = msg:lower() end\n			if (not cmd) then cmd = \"\" end\n			if (not param) then param = \"\" end\n			if (cmd == \"load\") then\n				if (param == \"\") then\n					Stubby.Print(\"Manually loading Enchantrix...\")\n					LoadAddOn(\"Enchantrix\")\n				elseif (param == \"always\") then\n					Stubby.Print(\"Setting Enchantrix to always load for this character\")\n					Stubby.SetConfig(\"Enchantrix\", \"LoadType\", param)\n					LoadAddOn(\"Enchantrix\")\n				elseif (param == \"never\") then\n					Stubby.Print(\"Setting Enchantrix to never load automatically for this character (you may still load manually)\")\n					Stubby.SetConfig(\"Enchantrix\", \"LoadType\", param)\n				else\n					Stubby.Print(\"Your command was not understood\")\n				end\n			else\n				Stubby.Print(\"Enchantrix is currently not loaded.\")\n				Stubby.Print(\"  You may load it now by typing |cffffffff/enchantrix load|r\")\n				Stubby.Print(\"  You may also set your loading preferences for this character by using the following commands:\")\n				Stubby.Print(\"  |cffffffff/enchantrix load always|r - Enchantrix will always load for this character\")\n				Stubby.Print(\"  |cffffffff/enchantrix load never|r - Enchantrix will never load automatically for this character (you may still load it manually)\")\n			end\n		end\n		SLASH_ENCHANTRIX1 = \"/enchantrix\"\n		SLASH_ENCHANTRIX2 = \"/enchant\"\n		SLASH_ENCHANTRIX3 = \"/enx\"\n		SlashCmdList[\"ENCHANTRIX\"] = cmdHandler\n	",
			["triggers"] = "		if Stubby.GetConfig(\"Enchantrix\", \"LoadType\") == \"always\" then\n			LoadAddOn(\"Enchantrix\")\n		else\n			Stubby.Print(\"Enchantrix is not loaded. Type /enchantrix for more info.\")\n		end\n	",
		},
		["informant"] = {
			["commandhandler"] = "		local function cmdHandler(msg)\n			local cmd, param = msg:lower():match(\"^(%w+)%s*(.*)$\")\n			cmd = cmd or msg:lower() or \"\";\n			param = param or \"\";\n			if (cmd == \"load\") then\n				if (param == \"\") then\n					Stubby.Print(\"Manually loading Informant...\")\n					LoadAddOn(\"Informant\")\n				elseif (param == \"always\") then\n					Stubby.Print(\"Setting Informant to always load for this character\")\n					Stubby.SetConfig(\"Informant\", \"LoadType\", param)\n					LoadAddOn(\"Informant\")\n				elseif (param == \"never\") then\n					Stubby.Print(\"Setting Informant to never load automatically for this character (you may still load manually)\")\n					Stubby.SetConfig(\"Informant\", \"LoadType\", param)\n				else\n					Stubby.Print(\"Your command was not understood\")\n				end\n			else\n				Stubby.Print(\"Informant is currently not loaded.\")\n				Stubby.Print(\"  You may load it now by typing |cffffffff/informant load|r\")\n				Stubby.Print(\"  You may also set your loading preferences for this character by using the following commands:\")\n				Stubby.Print(\"  |cffffffff/informant load always|r - Informant will always load for this character\")\n				Stubby.Print(\"  |cffffffff/informant load never|r - Informant will never load automatically for this character (you may still load it manually)\")\n			end\n		end\n		SLASH_INFORMANT1 = \"/informant\"\n		SLASH_INFORMANT2 = \"/inform\"\n		SLASH_INFORMANT3 = \"/info\"\n		SLASH_INFORMANT4 = \"/inf\"\n		SlashCmdList[\"INFORMANT\"] = cmdHandler\n	",
			["triggers"] = "		local loadType = Stubby.GetConfig(\"Informant\", \"LoadType\")\n		if (loadType == \"always\") then\n			LoadAddOn(\"Informant\")\n		else\n			Stubby.Print(\"Informant is not loaded. Type /informant for more info.\");\n		end\n	",
		},
	},
}
