-- luacheck: no max line length
-- luacheck: globals LibStub

local L = LibStub("AceLocale-3.0"):NewLocale("NameplateCooldowns", "ptBR");
L = L or {} -- luacheck: ignore
--@non-debug@
--[[Translation missing --]]
L["anchor-point:bottom"] = "Bottom"
--[[Translation missing --]]
L["anchor-point:bottomleft"] = "Bottom left"
--[[Translation missing --]]
L["anchor-point:bottomright"] = "Bottom right"
--[[Translation missing --]]
L["anchor-point:center"] = "Center"
--[[Translation missing --]]
L["anchor-point:left"] = "Left"
--[[Translation missing --]]
L["anchor-point:right"] = "Right"
--[[Translation missing --]]
L["anchor-point:top"] = "Top"
--[[Translation missing --]]
L["anchor-point:topleft"] = "Top left"
--[[Translation missing --]]
L["anchor-point:topright"] = "Top right"
--[[Translation missing --]]
L["anchor-point:x-offset"] = "X offset"
--[[Translation missing --]]
L["anchor-point:y-offset"] = "Y offset"
L["chat:addon-is-disabled-note"] = "Nota: este addon está desativado. Você pode ativá-lo na janela de opções (/nc)"
L["chat:default-spell-is-added-to-ignore-list"] = "Feitiço padrão adicionado à lista de ignorados: %s. Você não receberá atualizações do tempo de recarga para este feitiço."
L["chat:enable-only-for-target-nameplate"] = "Recargas serão exibidas somente no nameplate do seu alvo"
L["chat:print-updated-spells"] = "%s: sua recarga: %s seg, nova recarga: %s seg"
L["Click on icon to enable/disable tracking"] = "Clique no ícone para ativar/desativar o rastreamento."
L["Copy"] = "Copiar"
L["Copy other profile to current profile:"] = "Copiar outro perfil para o perfil atual:"
L["Current profile: [%s]"] = "Perfil atual: [%s]"
L["Data from '%s' has been successfully copied to '%s'"] = "Dados de '%s' foram copiados para '%s' com sucesso "
L["Delete"] = "Deletar"
L["Delete profile:"] = "Deletar perfil:"
L["Filters"] = "Filtros"
L["filters.instance-types"] = [=[Configurar a visbilidade das recargas
em diferentes tipos de localidades]=]
L["Font:"] = "Fonte:"
L["General"] = "Geral"
L["general.sort-mode"] = "Ordenação:"
L["Icon size"] = "Tamanho do ícone"
L["Icon X-coord offset"] = "Coordenada X do Ícone"
L["Icon Y-coord offset"] = "Coordenada Y do Ícone"
--[[Translation missing --]]
L["icon-grow-direction:down"] = "Down"
--[[Translation missing --]]
L["icon-grow-direction:left"] = "Left"
--[[Translation missing --]]
L["icon-grow-direction:right"] = "Right"
--[[Translation missing --]]
L["icon-grow-direction:up"] = "Up"
L["instance-type:arena"] = "Arena"
L["instance-type:none"] = "Mundo"
L["instance-type:party"] = "Masmorras de 5 pessoas"
L["instance-type:pvp"] = "Campos de batalha"
--[[Translation missing --]]
L["instance-type:pvp_bg_40ppl"] = "Epic Battlegrounds"
L["instance-type:raid"] = "Raides"
L["instance-type:scenario"] = "Cenários"
L["instance-type:unknown"] = "Masmorras desconhecidas (por exemplo de missões)"
L["MISC"] = "Outros"
L["msg:question:import-existing-spells"] = [=[NameplateCooldows
Existem recargas atualizadas para algumas de seus feitiços. Você deseja atualizar?]=]
L["New spell has been added: %s"] = "Um novo feitiço foi adicionado: %s"
L["Options are not available in combat!"] = "Opções não estão disponíveis em combate!"
--[[Translation missing --]]
L["options:borders:show-blizz-borders"] = "Show Blizzard's borders around icons"
--[[Translation missing --]]
L["options:building-cache"] = [=[Loading spells info (%s%%)...
Some functions may be unavailable]=]
--[[Translation missing --]]
L["options:category:borders"] = "Borders"
L["options:category:spells"] = "Feitiços"
--[[Translation missing --]]
L["options:category:text"] = "Text"
--[[Translation missing --]]
L["options:general:anchor-point"] = "Anchor point"
--[[Translation missing --]]
L["options:general:anchor-point-to-parent"] = "Anchor point (to parent)"
L["options:general:enable-only-for-target-nameplate"] = "Exibir Recargas somente no nameplate do seu alvo"
--[[Translation missing --]]
L["options:general:full-opacity-always"] = "Icons are always completely opaque"
--[[Translation missing --]]
L["options:general:full-opacity-always:tooltip"] = "If this option is enabled, the icons will always be completely opaque. If not, the opacity will be the same as the health bar"
--[[Translation missing --]]
L["options:general:icon-grow-direction"] = "Icons' growth direction"
--[[Translation missing --]]
L["options:general:ignore-nameplate-scale"] = "Ignore nameplate scale"
--[[Translation missing --]]
L["options:general:ignore-nameplate-scale:tooltip"] = [=[If this option is checked, icon size will not
change accordingly to nameplate scale
(for example, if nameplate of your target becomes bigger)]=]
--[[Translation missing --]]
L["options:general:inverse-logic"] = "Inverse logic"
--[[Translation missing --]]
L["options:general:inverse-logic:tooltip"] = "Display icon if player IS ABLE to cast certain spell"
--[[Translation missing --]]
L["options:general:show-cd-on-allies"] = "Show cooldowns on nameplates of allies"
--[[Translation missing --]]
L["options:general:show-cooldown-animation"] = "Enable cooldown animation"
--[[Translation missing --]]
L["options:general:show-cooldown-animation:tooltip"] = "Enables spin animation on cooldown icons"
--[[Translation missing --]]
L["options:general:show-cooldown-tooltip"] = "Show cooldown tooltip"
--[[Translation missing --]]
L["options:general:show-inactive-cd"] = "Show inactive cooldowns"
--[[Translation missing --]]
L["options:general:show-inactive-cd:tooltip"] = [=[Pay attention: you will NOT be able to see all available cooldowns!
You will see ONLY those cooldowns that foe has already used]=]
L["options:general:space-between-icons"] = "Espaço entre ícones (px)"
--[[Translation missing --]]
L["options:general:test-mode"] = "Test mode"
--[[Translation missing --]]
L["options:profiles"] = "Profiles"
L["options:spells:add-new-spell"] = "Adicionar novo feitiço (nome ou id):"
L["options:spells:add-spell"] = "Adicionar feitiço"
L["options:spells:click-to-select-spell"] = "Clique para selecionar feitiço"
--[[Translation missing --]]
L["options:spells:click-to-select-spell:test-mode"] = "You can't edit spells in test mode"
L["options:spells:cooldown-time"] = "Tempo de Recarga"
--[[Translation missing --]]
L["options:spells:custom-cooldown"] = "Custom cooldown value"
--[[Translation missing --]]
L["options:spells:custom-cooldown-value"] = "Cooldown (sec)"
L["options:spells:delete-all-spells"] = "Deletar todos os feitiços"
L["options:spells:delete-all-spells-confirmation"] = "Você realmente quer deletar TODOS os feitiços?"
L["options:spells:delete-spell"] = "Deletar feitiço"
--[[Translation missing --]]
L["options:spells:disable-all-spells"] = "Disable all spells"
--[[Translation missing --]]
L["options:spells:enable-all-spells"] = "Enable all spells"
L["options:spells:enable-tracking-of-this-spell"] = "Ativar acompanhamento deste feitiço"
L["options:spells:icon-glow"] = "Brilho do ícone está desativado"
L["options:spells:icon-glow-always"] = "Ícone do feitiço irá brilhar durante a recarga"
L["options:spells:icon-glow-threshold"] = "Ícone irá brilhar se o tempo restante for menos que"
--[[Translation missing --]]
L["options:spells:please-push-once-more"] = "Please push once more"
L["options:spells:track-only-this-spellid"] = [=[Acompanhar apenas estes IDs de feitiço
(separados por vírgula)]=]
--[[Translation missing --]]
L["options:text:anchor-point"] = "Anchor point"
--[[Translation missing --]]
L["options:text:anchor-to-icon"] = "Anchor to icon"
--[[Translation missing --]]
L["options:text:color"] = "Text color"
--[[Translation missing --]]
L["options:text:font"] = "Font"
--[[Translation missing --]]
L["options:text:font-scale"] = "Font scale"
--[[Translation missing --]]
L["options:text:font-size"] = "Font size"
--[[Translation missing --]]
L["options:timer-text:scale-font-size"] = [=[Scale font size
according to
icon size]=]
L["Profile '%s' has been successfully deleted"] = "O perfil '%s' foi deletado com sucesso"
L["Show border around interrupts"] = "Mostrar borda em Interrupções"
L["Show border around trinkets"] = "Mostrar borda em Berloques"
L["Unknown spell: %s"] = "Feitiço desconhecido: %s"
L["Value must be a number"] = "Valor deve ser um número"

--@end-non-debug@
