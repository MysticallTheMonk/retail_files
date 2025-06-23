local E = select(2, ...):unpack()

local spell_highlighted = {}
local spellcast_all = {}
local hash_spelldb = {}

E.wwDamageSpells = {
	[100780] = true,
	[100784] = true,
	[107428] = true,
	[113656] = true,
	[152175] = true,
	[392983] = true,
	[322109] = true,
	[117952] = true,
	[101546] = true,
	[388193] = true,
	[1217413] = true,
}

E.specTalentChangeIDs = {
	[63644] = true,
	[63645] = true,
	[384255] = true,
}


function E:ProcessSpellDB()
	for k, v in pairs(self.spell_db) do
		local n = #v
		for i = n, 1, -1 do
			local t = v[i]
			local id, itemID, stype = t.spellID, t.item, t.type
			if C_Spell.DoesSpellExist(id) then
				t.class = t.class or k

				local name
				if k == "TRINKET" and itemID and itemID > 0 then
					name = C_Item.GetItemNameByID(itemID) or C_Spell.GetSpellName(id)
				else
					name = C_Spell.GetSpellName(id)
				end
				t.name = name or ""


				if k == "TRINKET" or k == "PVPTRINKET" then
					if itemID == 37864 and self.userFaction == "Horde" then
						itemID = 37865
					end
					t.icon = t.icon or C_Item.GetItemIconByID(itemID)
				else
					if id == 2825 and self.userFaction ~= "Horde" then
						t.icon = 132313
					end
					t.icon = t.icon or select(2, C_Spell.GetSpellTexture(id))
				end


				t.buff = t.buff or self.buffFix[id] or id
				if self.L_HIGHLIGHTS[stype] then
					spell_highlighted[t.buff] = true
				end

				if self.spell_requiredLevel then
					self.spell_requiredLevel[id] = t.rlvl
				end

				hash_spelldb[id] = t
				spellcast_all[id] = true
			else
				tremove(v, i)
				--[==[@debug@
				E.write("Removing invalid spell_db ID:" , id)
				--@end-debug@]==]
			end
		end
	end



	for castID in pairs(self.spellcast_merged) do
		spell_highlighted[castID] = true
	end

	for castID in self.pairs(
		self.spellcast_linked,
		self.spellcast_merged,
		self.spellcast_shared_cdstart,
		self.spellcast_cdreset,
		self.spellcast_cdr,
		self.covenant_abilities,
		self.spellcast_cdr_azerite,
		self.wwDamageSpells,
		self.specTalentChangeIDs
		) do
		spellcast_all[castID] = true
	end
	for castID in pairs(E.spell_dispel_cdstart) do
		spellcast_all[castID] = nil
	end
end

if not E.isRetail then
	E.spell_cxmod_azerite = E.BLANK
	E.spellcast_cdr_azerite = E.BLANK
	E.spell_damage_cdr_azerite = E.BLANK
	E.spell_cdmod_essrank23 = E.BLANK
	E.spell_chargemod_essrank3 = E.BLANK
	E.essMajorConflict = E.BLANK
	E.pvpTalentsByEssMajorConflict = E.BLANK
	E.essMinorStrive = E.BLANK
	E.spell_cdmod_ess_strive_mult = E.BLANK
end

E.spell_highlighted = spell_highlighted
E.spellcast_all = spellcast_all
E.hash_spelldb = hash_spelldb
