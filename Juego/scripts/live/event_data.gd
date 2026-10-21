extends Resource
@export var event_id := ""
@export var title := ""
@export var floors: Array[String] = []
@export var anchor := "npc"
@export var sector := ""
@export var action := "READ"
@export var prop := "BOOK"
@export_range(60,180) var duration := 90.0
@export var unique := false
@export var rare := false
@export_range(0,3) var minimum_anomaly := 0
@export var nexo := false
@export var minute_start := 0
@export var minute_end := 1440
@export var situation := ""
@export var required_flags: Dictionary = {}
