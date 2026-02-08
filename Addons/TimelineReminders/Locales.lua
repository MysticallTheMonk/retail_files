local _, LRP = ...

local locales = {
    deDE = {
        ragnaros_intermission_end1 = "Sulfuras wird Euer Ende sein.",
        ragnaros_intermission_end2 = "Auf die Knie, Sterbliche! Das ist das Ende.",
        ragnaros_intermission_end3 = "Genug! Ich werde dem ein Ende machen.",
        ragnaros_phase_4 = "Zu früh"
    },
        enGB = {
        ragnaros_intermission_end1 = "Sulfuras will be your end",
        ragnaros_intermission_end2 = "Fall to your knees",
        ragnaros_intermission_end3 = "I will finish this",
        ragnaros_phase_4 = "Too soon..."
    },
	enUS = {
        ragnaros_intermission_end1 = "Sulfuras will be your end",
        ragnaros_intermission_end2 = "Fall to your knees",
        ragnaros_intermission_end3 = "I will finish this",
        ragnaros_phase_4 = "Too soon..."
    },
	esES = {
        ragnaros_intermission_end1 = "Sulfuras será vuestro fin.",
        ragnaros_intermission_end2 = "¡De rodillas, mortales! Esto termina ahora.",
        ragnaros_intermission_end3 = "¡Basta! Yo terminaré esto.",
        ragnaros_phase_4 = "¡Pronto!..."
	},
    esMX = {
        ragnaros_intermission_end1 = "Sulfuras será vuestro fin.",
        ragnaros_intermission_end2 = "¡De rodillas, mortales! Esto termina ahora.",
        ragnaros_intermission_end3 = "¡Basta! Yo terminaré esto.",
        ragnaros_phase_4 = "¡Pronto!..."
	},
    frFR = {
        ragnaros_intermission_end1 = "Sulfuras sera votre fin",
        ragnaros_intermission_end2 = "À genoux, mortels",
        ragnaros_intermission_end3 = "Je vais en finir",
        ragnaros_phase_4 = "Trop tôt..."
	},
    itIT = {
        ragnaros_intermission_end1 = "Sulfuras sarà la vostra fine",
        ragnaros_intermission_end2 = "In ginocchio mortali",
        ragnaros_intermission_end3 = "Basta così! Ora ci penso io",
        ragnaros_phase_4 = "Troppo presto..."
	},
    koKR = {
        ragnaros_intermission_end1 = "설퍼라스로 숨통을 끊어 주마.",
        ragnaros_intermission_end2 = "무릎 꿇어라, 필멸자여! 끝낼 시간이다.",
        ragnaros_intermission_end3 = "여기까지! 이제 끝내주마.",
        ragnaros_phase_4 = "너무 일러..."
    },
	ptBR = {
        ragnaros_intermission_end1 = "Sulfuras trará sua ruína.",
        ragnaros_intermission_end2 = "Ajoelhem-se, mortais! Isso acaba agora.",
        ragnaros_intermission_end3 = "Chega! Vou acabar com isso."
	},
	ptPT = {
        ragnaros_intermission_end1 = "Sulfuras trará sua ruína.",
        ragnaros_intermission_end2 = "Ajoelhem-se, mortais! Isso acaba agora.",
        ragnaros_intermission_end3 = "Chega! Vou acabar com isso.",
        ragnaros_phase_4 = "Cedo demais!..."
	},
	ruRU = {
        ragnaros_intermission_end1 = "Сульфурас уничтожит вас!",
        ragnaros_intermission_end2 = "На колени, смертные!",
        ragnaros_intermission_end3 = "Пора покончить с этим.",
        ragnaros_phase_4 = "Слишком рано…"
	},
	zhCN = {
        ragnaros_intermission_end1 = "萨弗拉斯将会是你的末日。",
        ragnaros_intermission_end2 = "跪下吧，凡人们！一切都结束了。",
        ragnaros_intermission_end3 = "够了！我会亲自解决。",
        ragnaros_phase_4 = "太早了……"
    },
	zhTW = {
        ragnaros_intermission_end1 = "薩弗拉斯將終結你。",
        ragnaros_intermission_end2 = "跪下吧，凡人們!一切都將結束。",
        ragnaros_intermission_end3 = "夠了!我將結束這一切。",
        ragnaros_phase_4 = "太早了!..."
    },
}

LRP.L = locales[GetLocale()] or locales.enUS