class_name CharacterAppearance
extends RefCounted
## Datos visuales independientes del jugador y de su modelo.
const SKIN = ["f3cbae","e0ac86","c78d65","a66c49","805137","503323"]
const COLORS = ["315e78","723d72","9c403a","376e54","d0b45e","353b46","e1e5e9"]
const HAIR = ["332a25","171719","815430","bd9355","a54038","c4c4c4"]
const HAIR_STYLE_IDS := ["SHORT_1","LONG_1","NONE","SHORT_2","MEDIUM_1","CURLY_1"]
const CLOTHING_SLOTS := ["TOP","BOTTOM","SHOES","BACKPACK","HEAD_ACCESSORY","ACCESSORY"]
const OPTIONS = {
	"skin":["Claro","Durazno","Arena","Cobre","Moreno","Oscuro"],
	"hair":["Corto","Largo","Sin cabello","Corto lateral","Medio","Rizado"],
	"hair_color":["Castaño","Negro","Avellana","Rubio","Rojizo","Gris"],
	"top":["Polera","Polerón","Camisa","Sweater","Chaqueta","Uniforme clínico ficticio","Overol de taller"],
	"bottom_style":["Pantalón casual","Jeans","Pantalón formal","Pantalón de trabajo"],
	"shoe_style":["Zapatillas","Zapatos","Botas de trabajo"],
	"backpack_color":["Azul","Violeta","Rojo","Verde","Mostaza","Grafito","Blanco"],
	"head_accessory":["Ninguno","Audífonos académicos"],
	"clothes":["Azul","Violeta","Rojo","Verde","Mostaza","Grafito","Blanco"],
	"pants":["Azul","Violeta","Rojo","Verde","Mostaza","Grafito","Blanco"],
	"shoes":["Azul","Violeta","Rojo","Verde","Mostaza","Grafito","Blanco"],
	"backpack":["Sin mochila","Mochila clásica","Mochila Informática"],
	"accessory":["Ninguno","Lentes","Accesorio Telecomunicaciones","Guantes de Taller","Casco de Seguridad","Credencial especial","Insignia de Integridad","Bolso del escritor","Dispositivo del Director"],
	"outfit":["Ropa elegida","Delantal del Chef","Polerón Biblioteca","Chaqueta Mecánica","Polerón de campeón","NEXO JACKET","TECH SET","SPORT SET"]
}
const LOCKS = {
	"backpack:2":"mochila_informatica","accessory:2":"telecomunicaciones",
	"accessory:3":"guantes_taller","accessory:4":"casco_seguridad","accessory:5":"credencial",
	"outfit:1":"delantal_chef","outfit:2":"poleron_biblioteca","outfit:3":"chaqueta_mecanica","outfit:4":"poleron_campeon","outfit:5":"nexo_jacket","outfit:6":"telecomunicaciones","outfit:7":"sport_set",
	"head_accessory:1":"audifonos_academicos","accessory:6":"insignia_integridad","accessory:7":"bolso_escritor","accessory:8":"director_tech"
}
const REWARDS = {
	"profesor_redes":["mochila_informatica","telecomunicaciones"],
	"chef":["delantal_chef"],"bibliotecaria":["poleron_biblioteca"],
	"director":["credencial","director_tech"],"profesor_ingles":["audifonos_academicos"],"profesor_lenguaje":["bolso_escritor"],"profesor_etica":["insignia_integridad"],"maestro_soldadura":["guantes_taller","casco_seguridad"],
	"jefe_taller":["chaqueta_mecanica"],"nexo":["poleron_campeon","nexo_jacket"],"punto":["sport_set"]
}
static func normalize(raw: Dictionary, unlocked: Dictionary = {}) -> Dictionary:
	var result := {}
	for key in OPTIONS:
		var value: int = int(raw.get(key,1 if key == "backpack" else 0)) if raw.get(key,0) is float or raw.get(key,0) is int else 0
		value = clampi(value,0,OPTIONS[key].size()-1)
		var required: String = LOCKS.get(key+":"+str(value),"")
		result[key] = value if required.is_empty() or unlocked.get(required,false) == true else 0
	return result

static func unlock_from_progress(bosses: Dictionary, unlocked: Dictionary) -> bool:
	var changed := false
	for boss in REWARDS:
		if bosses.get(boss,false) != true:
			continue
		for cosmetic in REWARDS[boss]:
			if unlocked.get(cosmetic,false) != true:
				unlocked[cosmetic] = true
				changed = true
	return changed
