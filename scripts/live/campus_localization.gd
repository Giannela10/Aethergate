extends Node
var translations: Array[Translation] = []
const EN := {
	"Cerrar":"Close","Volver":"Back","Continuar":"Continue","Cancelar":"Cancel","Confirmar":"Confirm",
	"Nueva partida":"New game","Inventario":"Inventory","Misiones":"Quests","Mapa":"Map",
	"Opciones":"Settings","Controles":"Controls","Volver al menú":"Main menu",
	"ACTIVIDAD RECIENTE":"RECENT ACTIVITY","HISTORIAL DE DIÁLOGO":"DIALOGUE HISTORY",
	"Guardar reporte local":"Save local report","Marcar mi ubicación":"Mark my location",
	"Borrar marcadores":"Clear markers","REINTENTAR BOSS":"RETRY BOSS",
	"Reintentar desde checkpoint":"Retry from checkpoint","Conservar":"Keep","Soltar":"Drop",
	"★ Favorito":"★ Favorite","Usar":"Use","Equipar":"Equip","Guardar equipado":"Stow equipped",
	"PERSONALIZACIÓN":"CUSTOMIZATION","MAPA DEL CAMPUS":"CAMPUS MAP","HAS CAÍDO":"YOU FELL",
	"Hora de almuerzo":"Lunch time","Grupo de estudio":"Study group",
	"Evaluación en curso":"Assessment in progress","Trabajo en grupo":"Group work",
	"Reunión de profesores":"Teachers' meeting","Preparando ataque especial":"Preparing special attack",
	"CAMPUS RESTABLECIDO":"CAMPUS RESTORED","Área descubierta":"Area discovered"
}
func _ready() -> void:
	for locale in ["es","en"]:
		var translation := Translation.new()
		translation.locale = locale
		for key in EN: translation.add_message(key,key if locale == "es" else EN[key])
		TranslationServer.add_translation(translation)
		translations.append(translation)
	TranslationServer.set_locale("es")
func set_language(locale: String) -> bool:
	if locale not in ["es","en"]: return false
	TranslationServer.set_locale(locale)
	return true
func _exit_tree() -> void:
	for translation in translations: TranslationServer.remove_translation(translation)
