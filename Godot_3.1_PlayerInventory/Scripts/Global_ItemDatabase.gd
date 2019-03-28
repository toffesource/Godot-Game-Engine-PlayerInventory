# Global_ItemDatabase.gd
extends Node

var url_database_item:String = "res://Database//Database_Items.json"


func get_item(id:String) -> Dictionary:
	var itemData = {}
	itemData = Global_DataParser.load_data(url_database_item)
	
	if !itemData.has(id):
		print("Item does not exist.")
		return {}
	
	itemData[(id)]["id"] = (id)
	return itemData[(id)]