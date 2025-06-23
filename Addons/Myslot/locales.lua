local _, MySlot = ...

local L = setmetatable({}, {
    __index = function(table, key)
        if key then
            table[key] = tostring(key)
        end
        return tostring(key)
    end,
})


MySlot.L = L

--
-- Use http://www.wowace.com/addons/myslot/localization/ to translate thanks
-- 
local locale = GetLocale()

if locale == 'enUs' then
L[" before Import"] = true
L[" during Export"] = true
L[" during Import"] = true
L["[WARN] Ignore slot due to an unknown error DEBUG INFO = [S=%s T=%s I=%s] Please send Importing Text and DEBUG INFO to %s"] = true
L["[WARN] Ignore unsupported Key Binding [ %s ] , contact %s please"] = true
L["[WARN] Ignore unsupported Slot Type [ %s ] , contact %s please"] = true
L["<- share your profile here"] = true
L["All slots were restored"] = true
L["Allow"] = true
L["Are you SURE to delete '%s'?"] = true
L["Are you SURE to import ?"] = true
L["Backup failed"] = true
L["Bad importing text [CRC32]"] = true
L["Bad importing text [TEXT]"] = true
L["Before Last Import"] = true
L["CLEAR"] = true
L["DANGEROUS"] = true
L["Export"] = true
L["Feedback"] = true
L["Force Import"] = true
L["IGNORE"] = true
L["Ignore missing item [id=%s]"] = true
L["Ignore unattained companion [id=%s], %s"] = true
L["Ignore unattained pet [id=%s]"] = true
L["Ignore unknown macro [id=%s]"] = true
L["Ignore unlearned skill [flyoutid=%s], %s"] = true
L["Ignore unlearned skill [id=%s], %s"] = true
L["Import"] = true
L["Import is not allowed when you are in combat"] = true
L["Key Binding"] = true
L["Macro %s was ignored, check if there is enough space to create"] = true
L["Main Action Bar Page"] = true
L["Minimap Icon"] = true
L["Myslot"] = true
L["Name of exported text"] = true
L["Open Myslot"] = true
L["Please type %s to confirm"] = true
L["Remove all Key Bindings"] = true
L["Remove all Macros"] = true
L["Remove everything in ActionBar"] = true
L["Rename"] = true
L["Skip bad CRC32"] = true
L["Skyriding Bar"] = true
L["Stance Action Bar"] = true
L["Starting backup..."] = true
L["Time"] = true
L["TOC_NOTES"] = "Myslot is for transferring settings between accounts. Feedback farmer1992@gmail.com"
L["Too many profiles, please delete before create new one."] = true
L["Try force importing"] = true
L["Unsaved"] = true
L["Use random mount instead of an unattained mount"] = true

elseif locale == 'deDE' then
L[" before Import"] = " vor dem Importieren"
L[" during Export"] = " während des Exportierens"
L[" during Import"] = " während des Importierens"
L["[WARN] Ignore slot due to an unknown error DEBUG INFO = [S=%s T=%s I=%s] Please send Importing Text and DEBUG INFO to %s"] = "[WARN] Slot aufgrund eines unbekannten Fehlers ignorieren DEBUG INFO = [S=%s T=%s I=%s] Bitte senden Sie den Import-Text und DEBUG-INFO an %s"
L["[WARN] Ignore unsupported Key Binding [ %s ] , contact %s please"] = "[WARN] Nicht unterstützte Tastenbelegung [ %s ] ignorieren, bitte kontaktieren Sie %s"
L["[WARN] Ignore unsupported Slot Type [ %s ] , contact %s please"] = "[WARN] Nicht unterstützten Slot-Typ [ %s ] ignorieren, bitte kontaktieren Sie %s"
L["<- share your profile here"] = "<- Teilen Sie Ihr Profil hier"
L["All slots were restored"] = "Alle Slots wurden wiederhergestellt"
L["Allow"] = "Erlauben"
L["Are you SURE to delete '%s'?"] = "Sind Sie SICHER, '%s' zu löschen?"
L["Are you SURE to import ?"] = "Sind Sie SICHER, zu importieren?"
L["Backup failed"] = "Backup fehlgeschlagen"
L["Bad importing text [CRC32]"] = "Fehlerhafter Import-Text [CRC32]"
L["Bad importing text [TEXT]"] = "Fehlerhafter Import-Text [TEXT]"
L["Before Last Import"] = "Vor dem letzten Import"
L["CLEAR"] = "LÖSCHEN"
L["DANGEROUS"] = "GEFÄHRLICH"
L["Export"] = "Exportieren"
L["Feedback"] = "Feedback"
L["Force Import"] = "Import erzwingen"
L["IGNORE"] = "IGNORIEREN"
L["Ignore missing item [id=%s]"] = "Fehlenden Gegenstand ignorieren [id=%s]"
L["Ignore unattained companion [id=%s], %s"] = "Nicht erhaltenen Begleiter ignorieren [id=%s], %s"
L["Ignore unattained pet [id=%s]"] = "Nicht erhaltenes Haustier ignorieren [id=%s]"
L["Ignore unknown macro [id=%s]"] = "Unbekanntes Makro ignorieren [id=%s]"
L["Ignore unlearned skill [flyoutid=%s], %s"] = "Ungelernte Fertigkeit ignorieren [flyoutid=%s], %s"
L["Ignore unlearned skill [id=%s], %s"] = "Ungelernte Fertigkeit ignorieren [id=%s], %s"
L["Import"] = "Importieren"
L["Import is not allowed when you are in combat"] = "Importieren ist im Kampf nicht erlaubt"
L["Key Binding"] = "Tastenbelegung"
L["Macro %s was ignored, check if there is enough space to create"] = "Makro %s wurde ignoriert, prüfen Sie, ob genügend Platz vorhanden ist"
L["Main Action Bar Page"] = "Haupt-Aktionsleisten-Seite"
L["Minimap Icon"] = "Minikarten-Symbol"
L["Myslot"] = "Myslot"
L["Name of exported text"] = "Name des exportierten Textes"
L["Open Myslot"] = "Myslot öffnen"
L["Please type %s to confirm"] = "Bitte geben Sie %s ein, um zu bestätigen"
L["Remove all Key Bindings"] = "Alle Tastenbelegungen entfernen"
L["Remove all Macros"] = "Alle Makros entfernen"
L["Remove everything in ActionBar"] = "Alles in der Aktionsleiste entfernen"
L["Rename"] = "Umbenennen"
L["Skip bad CRC32"] = "Fehlerhafte CRC32 überspringen"
L["Skyriding Bar"] = "Himmelsreiten-Leiste"
L["Stance Action Bar"] = "Haltungs-Aktionsleiste"
L["Starting backup..."] = "Backup wird gestartet..."
L["Time"] = "Zeit"
L["TOC_NOTES"] = "Myslot dient zum Übertragen von Einstellungen zwischen Konten. Feedback farmer1992@gmail.com"
L["Too many profiles, please delete before create new one."] = "Zu viele Profile, bitte löschen Sie eines, bevor Sie ein neues erstellen."
L["Try force importing"] = "Versuchen Sie, den Import zu erzwingen"
L["Unsaved"] = "Nicht gespeichert"
L["Use random mount instead of an unattained mount"] = "Verwenden Sie ein zufälliges Reittier anstelle eines nicht erhaltenen"

elseif locale == 'esES' then
L[" before Import"] = " antes de importar"
L[" during Export"] = " durante la exportación"
L[" during Import"] = " durante la importación"
L["[WARN] Ignore slot due to an unknown error DEBUG INFO = [S=%s T=%s I=%s] Please send Importing Text and DEBUG INFO to %s"] = "[ADVERTENCIA] Ignorar ranura debido a un error desconocido INFO DEBUG = [S=%s T=%s I=%s] Por favor envía el texto de importación y la INFO DEBUG a %s"
L["[WARN] Ignore unsupported Key Binding [ %s ] , contact %s please"] = "[ADVERTENCIA] Ignorar tecla no soportada [ %s ], por favor contacta con %s"
L["[WARN] Ignore unsupported Slot Type [ %s ] , contact %s please"] = "[ADVERTENCIA] Ignorar tipo de ranura no soportado [ %s ], por favor contacta con %s"
L["<- share your profile here"] = "<- comparte tu perfil aquí"
L["All slots were restored"] = "Todas las ranuras fueron restauradas"
L["Allow"] = "Permitir"
L["Are you SURE to delete '%s'?"] = "¿Estás SEGURO de eliminar '%s'?"
L["Are you SURE to import ?"] = "¿Estás SEGURO de importar?"
L["Backup failed"] = "La copia de seguridad falló"
L["Bad importing text [CRC32]"] = "Texto de importación erróneo [CRC32]"
L["Bad importing text [TEXT]"] = "Texto de importación erróneo [TEXT]"
L["Before Last Import"] = "Antes del último importado"
L["CLEAR"] = "LIMPIAR"
L["DANGEROUS"] = "PELIGROSO"
L["Export"] = "Exportar"
L["Feedback"] = "Comentarios"
L["Force Import"] = "Forzar importación"
L["IGNORE"] = "IGNORAR"
L["Ignore missing item [id=%s]"] = "Ignorar objeto faltante [id=%s]"
L["Ignore unattained companion [id=%s], %s"] = "Ignorar compañero no obtenido [id=%s], %s"
L["Ignore unattained pet [id=%s]"] = "Ignorar mascota no obtenida [id=%s]"
L["Ignore unknown macro [id=%s]"] = "Ignorar macro desconocida [id=%s]"
L["Ignore unlearned skill [flyoutid=%s], %s"] = "Ignorar habilidad no aprendida [flyoutid=%s], %s"
L["Ignore unlearned skill [id=%s], %s"] = "Ignorar habilidad no aprendida [id=%s], %s"
L["Import"] = "Importar"
L["Import is not allowed when you are in combat"] = "No se permite importar mientras estás en combate"
L["Key Binding"] = "Atajo de teclado"
L["Macro %s was ignored, check if there is enough space to create"] = "La macro %s fue ignorada, verifica si hay suficiente espacio para crearla"
L["Main Action Bar Page"] = "Página de barra de acción principal"
L["Minimap Icon"] = "Icono del minimapa"
L["Myslot"] = "Myslot"
L["Name of exported text"] = "Nombre del texto exportado"
L["Open Myslot"] = "Abrir Myslot"
L["Please type %s to confirm"] = "Por favor, escribe %s para confirmar"
L["Remove all Key Bindings"] = "Eliminar todas las asignaciones de teclas"
L["Remove all Macros"] = "Eliminar todas las macros"
L["Remove everything in ActionBar"] = "Eliminar todo en la barra de acción"
L["Rename"] = "Renombrar"
L["Skip bad CRC32"] = "Saltar CRC32 erróneo"
L["Skyriding Bar"] = "Barra de vuelo"
L["Stance Action Bar"] = "Barra de acción de postura"
L["Starting backup..."] = "Iniciando copia de seguridad..."
L["Time"] = "Tiempo"
L["TOC_NOTES"] = "Myslot es para transferir configuraciones entre cuentas. Comentarios: farmer1992@gmail.com"
L["Too many profiles, please delete before create new one."] = "Demasiados perfiles, por favor elimina antes de crear uno nuevo."
L["Try force importing"] = "Intentar forzar la importación"
L["Unsaved"] = "No guardado"
L["Use random mount instead of an unattained mount"] = "Usar montura aleatoria en lugar de una no obtenida"

elseif locale == 'esMX' then
--[[Translation missing --]]
--[[ L[" before Import"] = " before Import"--]] 
--[[Translation missing --]]
--[[ L[" during Export"] = " during Export"--]] 
--[[Translation missing --]]
--[[ L[" during Import"] = " during Import"--]] 
--[[Translation missing --]]
--[[ L["[WARN] Ignore slot due to an unknown error DEBUG INFO = [S=%s T=%s I=%s] Please send Importing Text and DEBUG INFO to %s"] = "[WARN] Ignore slot due to an unknown error DEBUG INFO = [S=%s T=%s I=%s] Please send Importing Text and DEBUG INFO to %s"--]] 
--[[Translation missing --]]
--[[ L["[WARN] Ignore unsupported Key Binding [ %s ] , contact %s please"] = "[WARN] Ignore unsupported Key Binding [ %s ] , contact %s please"--]] 
--[[Translation missing --]]
--[[ L["[WARN] Ignore unsupported Slot Type [ %s ] , contact %s please"] = "[WARN] Ignore unsupported Slot Type [ %s ] , contact %s please"--]] 
--[[Translation missing --]]
--[[ L["<- share your profile here"] = "<- share your profile here"--]] 
--[[Translation missing --]]
--[[ L["All slots were restored"] = "All slots were restored"--]] 
--[[Translation missing --]]
--[[ L["Allow"] = "Allow"--]] 
--[[Translation missing --]]
--[[ L["Are you SURE to delete '%s'?"] = "Are you SURE to delete '%s'?"--]] 
--[[Translation missing --]]
--[[ L["Are you SURE to import ?"] = "Are you SURE to import ?"--]] 
--[[Translation missing --]]
--[[ L["Backup failed"] = "Backup failed"--]] 
--[[Translation missing --]]
--[[ L["Bad importing text [CRC32]"] = "Bad importing text [CRC32]"--]] 
--[[Translation missing --]]
--[[ L["Bad importing text [TEXT]"] = "Bad importing text [TEXT]"--]] 
--[[Translation missing --]]
--[[ L["Before Last Import"] = "Before Last Import"--]] 
--[[Translation missing --]]
--[[ L["CLEAR"] = "CLEAR"--]] 
--[[Translation missing --]]
--[[ L["DANGEROUS"] = "DANGEROUS"--]] 
--[[Translation missing --]]
--[[ L["Export"] = "Export"--]] 
--[[Translation missing --]]
--[[ L["Feedback"] = "Feedback"--]] 
--[[Translation missing --]]
--[[ L["Force Import"] = "Force Import"--]] 
--[[Translation missing --]]
--[[ L["IGNORE"] = "IGNORE"--]] 
--[[Translation missing --]]
--[[ L["Ignore missing item [id=%s]"] = "Ignore missing item [id=%s]"--]] 
--[[Translation missing --]]
--[[ L["Ignore unattained companion [id=%s], %s"] = "Ignore unattained companion [id=%s], %s"--]] 
--[[Translation missing --]]
--[[ L["Ignore unattained pet [id=%s]"] = "Ignore unattained pet [id=%s]"--]] 
--[[Translation missing --]]
--[[ L["Ignore unknown macro [id=%s]"] = "Ignore unknown macro [id=%s]"--]] 
--[[Translation missing --]]
--[[ L["Ignore unlearned skill [flyoutid=%s], %s"] = "Ignore unlearned skill [flyoutid=%s], %s"--]] 
--[[Translation missing --]]
--[[ L["Ignore unlearned skill [id=%s], %s"] = "Ignore unlearned skill [id=%s], %s"--]] 
--[[Translation missing --]]
--[[ L["Import"] = "Import"--]] 
--[[Translation missing --]]
--[[ L["Import is not allowed when you are in combat"] = "Import is not allowed when you are in combat"--]] 
--[[Translation missing --]]
--[[ L["Key Binding"] = "Key Binding"--]] 
--[[Translation missing --]]
--[[ L["Macro %s was ignored, check if there is enough space to create"] = "Macro %s was ignored, check if there is enough space to create"--]] 
--[[Translation missing --]]
--[[ L["Main Action Bar Page"] = "Main Action Bar Page"--]] 
--[[Translation missing --]]
--[[ L["Minimap Icon"] = "Minimap Icon"--]] 
--[[Translation missing --]]
--[[ L["Myslot"] = "Myslot"--]] 
--[[Translation missing --]]
--[[ L["Name of exported text"] = "Name of exported text"--]] 
--[[Translation missing --]]
--[[ L["Open Myslot"] = "Open Myslot"--]] 
--[[Translation missing --]]
--[[ L["Please type %s to confirm"] = "Please type %s to confirm"--]] 
--[[Translation missing --]]
--[[ L["Remove all Key Bindings"] = "Remove all Key Bindings"--]] 
--[[Translation missing --]]
--[[ L["Remove all Macros"] = "Remove all Macros"--]] 
--[[Translation missing --]]
--[[ L["Remove everything in ActionBar"] = "Remove everything in ActionBar"--]] 
--[[Translation missing --]]
--[[ L["Rename"] = "Rename"--]] 
--[[Translation missing --]]
--[[ L["Skip bad CRC32"] = "Skip bad CRC32"--]] 
--[[Translation missing --]]
--[[ L["Skyriding Bar"] = "Skyriding Bar"--]] 
--[[Translation missing --]]
--[[ L["Stance Action Bar"] = "Stance Action Bar"--]] 
--[[Translation missing --]]
--[[ L["Starting backup..."] = "Starting backup..."--]] 
--[[Translation missing --]]
--[[ L["Time"] = "Time"--]] 
--[[Translation missing --]]
--[[ L["TOC_NOTES"] = "Myslot is for transferring settings between accounts. Feedback farmer1992@gmail.com"--]] 
--[[Translation missing --]]
--[[ L["Too many profiles, please delete before create new one."] = "Too many profiles, please delete before create new one."--]] 
--[[Translation missing --]]
--[[ L["Try force importing"] = "Try force importing"--]] 
--[[Translation missing --]]
--[[ L["Unsaved"] = "Unsaved"--]] 
--[[Translation missing --]]
--[[ L["Use random mount instead of an unattained mount"] = "Use random mount instead of an unattained mount"--]] 

elseif locale == 'frFR' then
L[" before Import"] = " avant l'importation"
L[" during Export"] = " pendant l'exportation"
L[" during Import"] = " pendant l'importation"
L["[WARN] Ignore slot due to an unknown error DEBUG INFO = [S=%s T=%s I=%s] Please send Importing Text and DEBUG INFO to %s"] = "[AVERTISSEMENT] Ignorer l'emplacement en raison d'une erreur inconnue INFO DEBUG = [S=%s T=%s I=%s] Veuillez envoyer le texte d'importation et les INFOS DEBUG à %s"
L["[WARN] Ignore unsupported Key Binding [ %s ] , contact %s please"] = "[AVERTISSEMENT] Ignorer la liaison de touche non prise en charge [ %s ], veuillez contacter %s"
L["[WARN] Ignore unsupported Slot Type [ %s ] , contact %s please"] = "[AVERTISSEMENT] Ignorer le type d'emplacement non pris en charge [ %s ], veuillez contacter %s"
L["<- share your profile here"] = "<- partagez votre profil ici"
L["All slots were restored"] = "Tous les emplacements ont été restaurés"
L["Allow"] = "Autoriser"
L["Are you SURE to delete '%s'?"] = "Êtes-vous SÛR de supprimer '%s' ?"
L["Are you SURE to import ?"] = "Êtes-vous SÛR d'importer ?"
L["Backup failed"] = "Échec de la sauvegarde"
L["Bad importing text [CRC32]"] = "Texte d'importation incorrect [CRC32]"
L["Bad importing text [TEXT]"] = "Texte d'importation incorrect [TEXT]"
L["Before Last Import"] = "Avant le dernier import"
L["CLEAR"] = "EFFACER"
L["DANGEROUS"] = "DANGEREUX"
L["Export"] = "Exporter"
L["Feedback"] = "Retour"
L["Force Import"] = "Forcer l'importation"
L["IGNORE"] = "IGNORER"
L["Ignore missing item [id=%s]"] = "Ignorer l'objet manquant [id=%s]"
L["Ignore unattained companion [id=%s], %s"] = "Ignorer le compagnon non obtenu [id=%s], %s"
L["Ignore unattained pet [id=%s]"] = "Ignorer le familier non obtenu [id=%s]"
L["Ignore unknown macro [id=%s]"] = "Ignorer la macro inconnue [id=%s]"
L["Ignore unlearned skill [flyoutid=%s], %s"] = "Ignorer la compétence non apprise [flyoutid=%s], %s"
L["Ignore unlearned skill [id=%s], %s"] = "Ignorer la compétence non apprise [id=%s], %s"
L["Import"] = "Importer"
L["Import is not allowed when you are in combat"] = "L'importation n'est pas autorisée en combat"
L["Key Binding"] = "Raccourci clavier"
L["Macro %s was ignored, check if there is enough space to create"] = "La macro %s a été ignorée, vérifiez s'il y a suffisamment d'espace pour la créer"
L["Main Action Bar Page"] = "Page de la barre d'action principale"
L["Minimap Icon"] = "Icône de la minimap"
L["Myslot"] = "Myslot"
L["Name of exported text"] = "Nom du texte exporté"
L["Open Myslot"] = "Ouvrir Myslot"
L["Please type %s to confirm"] = "Veuillez taper %s pour confirmer"
L["Remove all Key Bindings"] = "Supprimer tous les raccourcis"
L["Remove all Macros"] = "Supprimer toutes les macros"
L["Remove everything in ActionBar"] = "Supprimer tout dans la barre d'action"
L["Rename"] = "Renommer"
L["Skip bad CRC32"] = "Ignorer les CRC32 incorrects"
L["Skyriding Bar"] = "Barre de vol"
L["Stance Action Bar"] = "Barre d'action de posture"
L["Starting backup..."] = "Début de la sauvegarde..."
L["Time"] = "Temps"
L["TOC_NOTES"] = "Myslot permet de transférer des paramètres entre comptes. Retour : farmer1992@gmail.com"
L["Too many profiles, please delete before create new one."] = "Trop de profils, veuillez en supprimer avant d'en créer un nouveau."
L["Try force importing"] = "Essayer de forcer l'importation"
L["Unsaved"] = "Non sauvegardé"
L["Use random mount instead of an unattained mount"] = "Utiliser une monture aléatoire au lieu d'une non obtenue"

elseif locale == 'itIT' then
L[" before Import"] = " prima dell'importazione"
L[" during Export"] = " durante l'esportazione"
L[" during Import"] = " durante l'importazione"
L["[WARN] Ignore slot due to an unknown error DEBUG INFO = [S=%s T=%s I=%s] Please send Importing Text and DEBUG INFO to %s"] = "[ATTENZIONE] Ignora slot a causa di un errore sconosciuto INFO DEBUG = [S=%s T=%s I=%s] Invia il testo di importazione e le INFO DEBUG a %s"
L["[WARN] Ignore unsupported Key Binding [ %s ] , contact %s please"] = "[ATTENZIONE] Ignora assegnazione di tasto non supportata [ %s ], contatta %s per favore"
L["[WARN] Ignore unsupported Slot Type [ %s ] , contact %s please"] = "[ATTENZIONE] Ignora tipo di slot non supportato [ %s ], contatta %s per favore"
L["<- share your profile here"] = "<- condividi il tuo profilo qui"
L["All slots were restored"] = "Tutti gli slot sono stati ripristinati"
L["Allow"] = "Permetti"
L["Are you SURE to delete '%s'?"] = "Sei SICURO di eliminare '%s'?"
L["Are you SURE to import ?"] = "Sei SICURO di importare?"
L["Backup failed"] = "Backup fallito"
L["Bad importing text [CRC32]"] = "Testo di importazione non valido [CRC32]"
L["Bad importing text [TEXT]"] = "Testo di importazione non valido [TEXT]"
L["Before Last Import"] = "Prima dell'ultimo import"
L["CLEAR"] = "CANCELLA"
L["DANGEROUS"] = "PERICOLOSO"
L["Export"] = "Esporta"
L["Feedback"] = "Feedback"
L["Force Import"] = "Forza Importazione"
L["IGNORE"] = "IGNORA"
L["Ignore missing item [id=%s]"] = "Ignora oggetto mancante [id=%s]"
L["Ignore unattained companion [id=%s], %s"] = "Ignora compagno non ottenuto [id=%s], %s"
L["Ignore unattained pet [id=%s]"] = "Ignora mascotte non ottenuta [id=%s]"
L["Ignore unknown macro [id=%s]"] = "Ignora macro sconosciuta [id=%s]"
L["Ignore unlearned skill [flyoutid=%s], %s"] = "Ignora abilità non appresa [flyoutid=%s], %s"
L["Ignore unlearned skill [id=%s], %s"] = "Ignora abilità non appresa [id=%s], %s"
L["Import"] = "Importa"
L["Import is not allowed when you are in combat"] = "L'importazione non è consentita durante il combattimento"
L["Key Binding"] = "Assegnazione tasti"
L["Macro %s was ignored, check if there is enough space to create"] = "La macro %s è stata ignorata, verifica se c'è spazio sufficiente per crearla"
L["Main Action Bar Page"] = "Pagina principale della barra delle azioni"
L["Minimap Icon"] = "Icona minimappa"
L["Myslot"] = "Myslot"
L["Name of exported text"] = "Nome del testo esportato"
L["Open Myslot"] = "Apri Myslot"
L["Please type %s to confirm"] = "Digita %s per confermare"
L["Remove all Key Bindings"] = "Rimuovi tutte le assegnazioni tasti"
L["Remove all Macros"] = "Rimuovi tutte le macro"
L["Remove everything in ActionBar"] = "Rimuovi tutto dalla barra delle azioni"
L["Rename"] = "Rinomina"
L["Skip bad CRC32"] = "Ignora CRC32 errati"
L["Skyriding Bar"] = "Barra di volo"
L["Stance Action Bar"] = "Barra azioni postura"
L["Starting backup..."] = "Inizio backup..."
L["Time"] = "Tempo"
L["TOC_NOTES"] = "Myslot serve per trasferire impostazioni tra account. Feedback: farmer1992@gmail.com"
L["Too many profiles, please delete before create new one."] = "Troppi profili, eliminane uno prima di crearne uno nuovo."
L["Try force importing"] = "Prova a forzare l'importazione"
L["Unsaved"] = "Non salvato"
L["Use random mount instead of an unattained mount"] = "Usa una cavalcatura casuale invece di una non ottenuta"

elseif locale == 'koKR' then
L[" before Import"] = " 가져오기 전"
L[" during Export"] = " 내보내는 중"
L[" during Import"] = " 가져오는 중"
L["[WARN] Ignore slot due to an unknown error DEBUG INFO = [S=%s T=%s I=%s] Please send Importing Text and DEBUG INFO to %s"] = "[경고] 알 수 없는 오류로 슬롯을 무시했습니다. 디버그 정보 = [S=%s T=%s I=%s] 가져오기 텍스트와 디버그 정보를 %s로 보내주세요."
L["[WARN] Ignore unsupported Key Binding [ %s ] , contact %s please"] = "[경고] 지원되지 않는 키 설정 [ %s ] 무시, %s에게 문의해주세요."
L["[WARN] Ignore unsupported Slot Type [ %s ] , contact %s please"] = "[경고] 지원되지 않는 슬롯 유형 [ %s ] 무시, %s에게 문의해주세요."
L["<- share your profile here"] = "<- 여기에서 프로필 공유"
L["All slots were restored"] = "모든 슬롯이 복원되었습니다."
L["Allow"] = "허용"
L["Are you SURE to delete '%s'?"] = "'%s'를 정말 삭제하시겠습니까?"
L["Are you SURE to import ?"] = "정말 가져오시겠습니까?"
L["Backup failed"] = "백업 실패"
L["Bad importing text [CRC32]"] = "잘못된 가져오기 텍스트 [CRC32]"
L["Bad importing text [TEXT]"] = "잘못된 가져오기 텍스트 [TEXT]"
L["Before Last Import"] = "마지막 가져오기 전"
L["CLEAR"] = "지우기"
L["DANGEROUS"] = "위험"
L["Export"] = "내보내기"
L["Feedback"] = "피드백"
L["Force Import"] = "강제 가져오기"
L["IGNORE"] = "무시"
L["Ignore missing item [id=%s]"] = "누락된 아이템 무시 [id=%s]"
L["Ignore unattained companion [id=%s], %s"] = "획득하지 않은 동반자 무시 [id=%s], %s"
L["Ignore unattained pet [id=%s]"] = "획득하지 않은 애완동물 무시 [id=%s]"
L["Ignore unknown macro [id=%s]"] = "알 수 없는 매크로 무시 [id=%s]"
L["Ignore unlearned skill [flyoutid=%s], %s"] = "배우지 않은 스킬 무시 [flyoutid=%s], %s"
L["Ignore unlearned skill [id=%s], %s"] = "배우지 않은 스킬 무시 [id=%s], %s"
L["Import"] = "가져오기"
L["Import is not allowed when you are in combat"] = "전투 중에는 가져오기가 허용되지 않습니다."
L["Key Binding"] = "키 설정"
L["Macro %s was ignored, check if there is enough space to create"] = "매크로 %s이 무시되었습니다. 생성할 공간이 충분한지 확인하세요."
L["Main Action Bar Page"] = "주 행동바 페이지"
L["Minimap Icon"] = "미니맵 아이콘"
L["Myslot"] = "Myslot"
L["Name of exported text"] = "내보낸 텍스트의 이름"
L["Open Myslot"] = "Myslot 열기"
L["Please type %s to confirm"] = "확인하려면 %s를 입력하세요."
L["Remove all Key Bindings"] = "모든 키 설정 제거"
L["Remove all Macros"] = "모든 매크로 제거"
L["Remove everything in ActionBar"] = "행동바의 모든 항목 제거"
L["Rename"] = "이름 변경"
L["Skip bad CRC32"] = "잘못된 CRC32 건너뛰기"
L["Skyriding Bar"] = "비행바"
L["Stance Action Bar"] = "태세 행동바"
L["Starting backup..."] = "백업 시작 중..."
L["Time"] = "시간"
L["TOC_NOTES"] = "Myslot은 계정 간 설정 전송에 사용됩니다. 피드백: farmer1992@gmail.com"
L["Too many profiles, please delete before create new one."] = "프로필이 너무 많습니다. 새로 만들기 전에 삭제하세요."
L["Try force importing"] = "강제 가져오기 시도"
L["Unsaved"] = "저장되지 않음"
L["Use random mount instead of an unattained mount"] = "획득하지 않은 탈것 대신 랜덤 탈것 사용"

elseif locale == 'ptBR' then
L[" before Import"] = " antes da importação"
L[" during Export"] = " durante a exportação"
L[" during Import"] = " durante a importação"
L["[WARN] Ignore slot due to an unknown error DEBUG INFO = [S=%s T=%s I=%s] Please send Importing Text and DEBUG INFO to %s"] = "[AVISO] Ignorar slot devido a um erro desconhecido INFO DE DEPURAÇÃO = [S=%s T=%s I=%s] Por favor, envie o texto de importação e a INFO DE DEPURAÇÃO para %s"
L["[WARN] Ignore unsupported Key Binding [ %s ] , contact %s please"] = "[AVISO] Ignorar atalho de tecla não suportado [ %s ], entre em contato com %s"
L["[WARN] Ignore unsupported Slot Type [ %s ] , contact %s please"] = "[AVISO] Ignorar tipo de slot não suportado [ %s ], entre em contato com %s"
L["<- share your profile here"] = "<- compartilhe seu perfil aqui"
L["All slots were restored"] = "Todos os slots foram restaurados"
L["Allow"] = "Permitir"
L["Are you SURE to delete '%s'?"] = "Você tem CERTEZA de que deseja excluir '%s'?"
L["Are you SURE to import ?"] = "Você tem CERTEZA de que deseja importar?"
L["Backup failed"] = "Falha no backup"
L["Bad importing text [CRC32]"] = "Texto de importação inválido [CRC32]"
L["Bad importing text [TEXT]"] = "Texto de importação inválido [TEXT]"
L["Before Last Import"] = "Antes da última importação"
L["CLEAR"] = "LIMPAR"
L["DANGEROUS"] = "PERIGOSO"
L["Export"] = "Exportar"
L["Feedback"] = "Feedback"
L["Force Import"] = "Forçar Importação"
L["IGNORE"] = "IGNORAR"
L["Ignore missing item [id=%s]"] = "Ignorar item ausente [id=%s]"
L["Ignore unattained companion [id=%s], %s"] = "Ignorar companheiro não obtido [id=%s], %s"
L["Ignore unattained pet [id=%s]"] = "Ignorar mascote não obtido [id=%s]"
L["Ignore unknown macro [id=%s]"] = "Ignorar macro desconhecida [id=%s]"
L["Ignore unlearned skill [flyoutid=%s], %s"] = "Ignorar habilidade não aprendida [flyoutid=%s], %s"
L["Ignore unlearned skill [id=%s], %s"] = "Ignorar habilidade não aprendida [id=%s], %s"
L["Import"] = "Importar"
L["Import is not allowed when you are in combat"] = "A importação não é permitida durante o combate"
L["Key Binding"] = "Atalho de Tecla"
L["Macro %s was ignored, check if there is enough space to create"] = "A macro %s foi ignorada, verifique se há espaço suficiente para criar"
L["Main Action Bar Page"] = "Página da Barra de Ações Principal"
L["Minimap Icon"] = "Ícone do Minimapa"
L["Myslot"] = "Myslot"
L["Name of exported text"] = "Nome do texto exportado"
L["Open Myslot"] = "Abrir Myslot"
L["Please type %s to confirm"] = "Digite %s para confirmar"
L["Remove all Key Bindings"] = "Remover todos os atalhos de teclas"
L["Remove all Macros"] = "Remover todas as macros"
L["Remove everything in ActionBar"] = "Remover tudo na Barra de Ações"
L["Rename"] = "Renomear"
L["Skip bad CRC32"] = "Pular CRC32 inválido"
L["Skyriding Bar"] = "Barra de Voo"
L["Stance Action Bar"] = "Barra de Ações de Postura"
L["Starting backup..."] = "Iniciando backup..."
L["Time"] = "Tempo"
L["TOC_NOTES"] = "Myslot é para transferir configurações entre contas. Feedback: farmer1992@gmail.com"
L["Too many profiles, please delete before create new one."] = "Perfis demais, exclua antes de criar um novo."
L["Try force importing"] = "Tentar forçar a importação"
L["Unsaved"] = "Não Salvo"
L["Use random mount instead of an unattained mount"] = "Usar montaria aleatória em vez de uma não obtida"

elseif locale == 'ruRU' then
L[" before Import"] = " перед импортом"
L[" during Export"] = " во время экспорта"
L[" during Import"] = " во время импорта"
L["[WARN] Ignore slot due to an unknown error DEBUG INFO = [S=%s T=%s I=%s] Please send Importing Text and DEBUG INFO to %s"] = "[ПРЕДУПРЕЖДЕНИЕ] Слот пропущен из-за неизвестной ошибки DEBUG INFO = [S=%s T=%s I=%s]. Пожалуйста, отправьте текст импорта и DEBUG INFO на %s"
L["[WARN] Ignore unsupported Key Binding [ %s ] , contact %s please"] = "[ПРЕДУПРЕЖДЕНИЕ] Пропущена неподдерживаемая клавиша [ %s ], свяжитесь с %s"
L["[WARN] Ignore unsupported Slot Type [ %s ] , contact %s please"] = "[ПРЕДУПРЕЖДЕНИЕ] Пропущен неподдерживаемый тип слота [ %s ], свяжитесь с %s"
L["<- share your profile here"] = "<- поделитесь вашим профилем здесь"
L["All slots were restored"] = "Все слоты восстановлены"
L["Allow"] = "Разрешить"
L["Are you SURE to delete '%s'?"] = "Вы УВЕРЕНЫ, что хотите удалить '%s'?"
L["Are you SURE to import ?"] = "Вы УВЕРЕНЫ, что хотите импортировать?"
L["Backup failed"] = "Резервное копирование не удалось"
L["Bad importing text [CRC32]"] = "Неверный текст импорта [CRC32]"
L["Bad importing text [TEXT]"] = "Неверный текст импорта [TEXT]"
L["Before Last Import"] = "Перед последним импортом"
L["CLEAR"] = "ОЧИСТИТЬ"
L["DANGEROUS"] = "ОПАСНО"
L["Export"] = "Экспорт"
L["Feedback"] = "Обратная связь"
L["Force Import"] = "Принудительный импорт"
L["IGNORE"] = "ИГНОРИРОВАТЬ"
L["Ignore missing item [id=%s]"] = "Пропустить отсутствующий предмет [id=%s]"
L["Ignore unattained companion [id=%s], %s"] = "Пропустить недоступного спутника [id=%s], %s"
L["Ignore unattained pet [id=%s]"] = "Пропустить недоступного питомца [id=%s]"
L["Ignore unknown macro [id=%s]"] = "Пропустить неизвестную макрос [id=%s]"
L["Ignore unlearned skill [flyoutid=%s], %s"] = "Пропустить невыученный навык [flyoutid=%s], %s"
L["Ignore unlearned skill [id=%s], %s"] = "Пропустить невыученный навык [id=%s], %s"
L["Import"] = "Импорт"
L["Import is not allowed when you are in combat"] = "Импорт запрещен во время боя"
L["Key Binding"] = "Привязка клавиш"
L["Macro %s was ignored, check if there is enough space to create"] = "Макрос %s пропущен, проверьте, достаточно ли места для создания"
L["Main Action Bar Page"] = "Основная панель действий"
L["Minimap Icon"] = "Значок на миникарте"
L["Myslot"] = "Myslot"
L["Name of exported text"] = "Имя экспортированного текста"
L["Open Myslot"] = "Открыть Myslot"
L["Please type %s to confirm"] = "Введите %s для подтверждения"
L["Remove all Key Bindings"] = "Удалить все привязки клавиш"
L["Remove all Macros"] = "Удалить все макросы"
L["Remove everything in ActionBar"] = "Удалить все с панели действий"
L["Rename"] = "Переименовать"
L["Skip bad CRC32"] = "Пропустить неверный CRC32"
L["Skyriding Bar"] = "Панель полета"
L["Stance Action Bar"] = "Панель действий стоек"
L["Starting backup..."] = "Начинается резервное копирование..."
L["Time"] = "Время"
L["TOC_NOTES"] = "Myslot предназначен для передачи настроек между учетными записями. Обратная связь: farmer1992@gmail.com"
L["Too many profiles, please delete before create new one."] = "Слишком много профилей, удалите один перед созданием нового."
L["Try force importing"] = "Попробовать принудительный импорт"
L["Unsaved"] = "Не сохранено"
L["Use random mount instead of an unattained mount"] = "Использовать случайное средство передвижения вместо недоступного"

elseif locale == 'zhCN' then
L[" before Import"] = " 导入前"
L[" during Export"] = " 导出中"
L[" during Import"] = " 导入中"
L["[WARN] Ignore slot due to an unknown error DEBUG INFO = [S=%s T=%s I=%s] Please send Importing Text and DEBUG INFO to %s"] = "[警告] 因未知错误忽略插槽 调试信息 = [S=%s T=%s I=%s] 请发送导入文本和调试信息到 %s"
L["[WARN] Ignore unsupported Key Binding [ %s ] , contact %s please"] = "[警告] 忽略不支持的按键绑定 [ %s ] ，请联系 %s"
L["[WARN] Ignore unsupported Slot Type [ %s ] , contact %s please"] = "[警告] 忽略不支持的插槽类型 [ %s ] ，请联系 %s"
L["<- share your profile here"] = "<- 在这里分享你的配置文件"
L["All slots were restored"] = "所有插槽已恢复"
L["Allow"] = "允许"
L["Are you SURE to delete '%s'?"] = "你确定要删除 '%s' 吗？"
L["Are you SURE to import ?"] = "你确定要导入吗？"
L["Backup failed"] = "备份失败"
L["Bad importing text [CRC32]"] = "无效的导入文本 [CRC32]"
L["Bad importing text [TEXT]"] = "无效的导入文本 [TEXT]"
L["Before Last Import"] = "上次导入之前"
L["CLEAR"] = "清除"
L["DANGEROUS"] = "危险"
L["Export"] = "导出"
L["Feedback"] = "反馈"
L["Force Import"] = "强制导入"
L["IGNORE"] = "忽略"
L["Ignore missing item [id=%s]"] = "忽略缺失的物品 [id=%s]"
L["Ignore unattained companion [id=%s], %s"] = "忽略未获得的伙伴 [id=%s], %s"
L["Ignore unattained pet [id=%s]"] = "忽略未获得的宠物 [id=%s]"
L["Ignore unknown macro [id=%s]"] = "忽略未知的宏 [id=%s]"
L["Ignore unlearned skill [flyoutid=%s], %s"] = "忽略未学会的技能 [flyoutid=%s], %s"
L["Ignore unlearned skill [id=%s], %s"] = "忽略未学会的技能 [id=%s], %s"
L["Import"] = "导入"
L["Import is not allowed when you are in combat"] = "战斗中无法导入"
L["Key Binding"] = "按键绑定"
L["Macro %s was ignored, check if there is enough space to create"] = "宏 %s 被忽略，请检查是否有足够空间创建"
L["Main Action Bar Page"] = "主动作条页面"
L["Minimap Icon"] = "小地图图标"
L["Myslot"] = "我的配置"
L["Name of exported text"] = "导出文本的名称"
L["Open Myslot"] = "打开我的配置"
L["Please type %s to confirm"] = "请输入 %s 以确认"
L["Remove all Key Bindings"] = "移除所有按键绑定"
L["Remove all Macros"] = "移除所有宏"
L["Remove everything in ActionBar"] = "移除动作条上的所有内容"
L["Rename"] = "重命名"
L["Skip bad CRC32"] = "跳过无效的 CRC32"
L["Skyriding Bar"] = "飞行栏"
L["Stance Action Bar"] = "姿态动作条"
L["Starting backup..."] = "正在开始备份..."
L["Time"] = "时间"
L["TOC_NOTES"] = "Myslot 用于在账户之间传输设置。反馈: farmer1992@gmail.com"
L["Too many profiles, please delete before create new one."] = "配置文件过多，请删除后再创建新文件。"
L["Try force importing"] = "尝试强制导入"
L["Unsaved"] = "未保存"
L["Use random mount instead of an unattained mount"] = "使用随机坐骑替代未获得的坐骑"

elseif locale == 'zhTW' then
L[" before Import"] = " 匯入前"
L[" during Export"] = " 匯出中"
L[" during Import"] = " 匯入中"
L["[WARN] Ignore slot due to an unknown error DEBUG INFO = [S=%s T=%s I=%s] Please send Importing Text and DEBUG INFO to %s"] = "[警告] 因未知錯誤忽略插槽 調試信息 = [S=%s T=%s I=%s] 請將匯入文本和調試信息發送至 %s"
L["[WARN] Ignore unsupported Key Binding [ %s ] , contact %s please"] = "[警告] 忽略不支援的按鍵綁定 [ %s ] ，請聯繫 %s"
L["[WARN] Ignore unsupported Slot Type [ %s ] , contact %s please"] = "[警告] 忽略不支援的插槽類型 [ %s ] ，請聯繫 %s"
L["<- share your profile here"] = "<- 在此分享你的設定檔"
L["All slots were restored"] = "所有插槽已恢復"
L["Allow"] = "允許"
L["Are you SURE to delete '%s'?"] = "你確定要刪除 '%s' 嗎？"
L["Are you SURE to import ?"] = "你確定要匯入嗎？"
L["Backup failed"] = "備份失敗"
L["Bad importing text [CRC32]"] = "無效的匯入文本 [CRC32]"
L["Bad importing text [TEXT]"] = "無效的匯入文本 [TEXT]"
L["Before Last Import"] = "上次匯入前"
L["CLEAR"] = "清除"
L["DANGEROUS"] = "危險"
L["Export"] = "匯出"
L["Feedback"] = "反饋"
L["Force Import"] = "強制匯入"
L["IGNORE"] = "忽略"
L["Ignore missing item [id=%s]"] = "忽略缺失的物品 [id=%s]"
L["Ignore unattained companion [id=%s], %s"] = "忽略未獲得的夥伴 [id=%s], %s"
L["Ignore unattained pet [id=%s]"] = "忽略未獲得的寵物 [id=%s]"
L["Ignore unknown macro [id=%s]"] = "忽略未知的巨集 [id=%s]"
L["Ignore unlearned skill [flyoutid=%s], %s"] = "忽略未學會的技能 [flyoutid=%s], %s"
L["Ignore unlearned skill [id=%s], %s"] = "忽略未學會的技能 [id=%s], %s"
L["Import"] = "匯入"
L["Import is not allowed when you are in combat"] = "戰鬥中無法匯入"
L["Key Binding"] = "按鍵綁定"
L["Macro %s was ignored, check if there is enough space to create"] = "巨集 %s 被忽略，請檢查是否有足夠空間創建"
L["Main Action Bar Page"] = "主動作條頁面"
L["Minimap Icon"] = "小地圖圖標"
L["Myslot"] = "我的設定檔"
L["Name of exported text"] = "匯出文本名稱"
L["Open Myslot"] = "開啟我的設定檔"
L["Please type %s to confirm"] = "請輸入 %s 以確認"
L["Remove all Key Bindings"] = "移除所有按鍵綁定"
L["Remove all Macros"] = "移除所有巨集"
L["Remove everything in ActionBar"] = "移除動作條上的所有內容"
L["Rename"] = "重新命名"
L["Skip bad CRC32"] = "跳過無效的 CRC32"
L["Skyriding Bar"] = "飛行欄"
L["Stance Action Bar"] = "姿態動作條"
L["Starting backup..."] = "正在開始備份..."
L["Time"] = "時間"
L["TOC_NOTES"] = "Myslot 用於在帳號之間傳輸設定。反饋: farmer1992@gmail.com"
L["Too many profiles, please delete before create new one."] = "設定檔過多，請刪除後再創建新的。"
L["Try force importing"] = "嘗試強制匯入"
L["Unsaved"] = "未保存"
L["Use random mount instead of an unattained mount"] = "使用隨機坐騎替代未獲得的坐騎"

end

