extends Node

var url_PlayerData:String = "user://PlayerData.bin"
var inventory:Dictionary = {}
var inventory_maxSlots:int = 45
onready var playerData:Dictionary = Global_DataParser.load_data(url_PlayerData)


func _ready() -> void:
	load_data()


func load_data() -> void:
	if (playerData.empty()):
		var dict:Dictionary = {"inventory":{}}
		for slot in range (0, inventory_maxSlots):
			dict["inventory"][str(slot)] = {"id": "0", "amount": 0}
		Global_DataParser.write_data(url_PlayerData, dict)
		inventory = dict["inventory"]
	else:
		inventory = playerData["inventory"]


func save_data() -> void:
	Global_DataParser.write_data(url_PlayerData, {"inventory": inventory})

func inventory_getItem(slot:int) -> Dictionary:
	return inventory[str(slot)]

func inventory_getEmptySlot() -> int:
	for slot in range(0, inventory_maxSlots):
		if (inventory[str(slot)]["id"] == "0"): 
			return int(slot)
	print ("Inventory is full!")
	return -1

func inventory_splitItem(slot, split_amount) -> int:
	if (split_amount <= 0):
		return -1
	var emptySlot = inventory_getEmptySlot()
	if emptySlot < 0:
		return emptySlot
		
	var new_amount = int(inventory_getItem(slot)["amount"]) - split_amount
	inventory[str(slot)]["amount"] = new_amount
	inventory[str(emptySlot)] = {"id": inventory[str(slot)]["id"], "amount": split_amount}
	return emptySlot

func inventory_addItem(itemId:int) -> int:
	var itemData:Dictionary = Global_ItemDatabase.get_item(str(itemId))
	if (itemData.empty()): 
		return -1
	if (int(itemData["stack_limit"]) <= 1):
		var slot = inventory_getEmptySlot()
		if (slot < 0): 
			return -1
		inventory[String(slot)] = {"id": String(itemId), "amount": 1}
		return slot
		
	
	for slot in range (0, inventory_maxSlots):
		if (inventory[String(slot)]["id"] == String(itemId)):
			if (int(itemData["stack_limit"]) > int(inventory[String(slot)]["amount"])):
				inventory[String(slot)]["amount"] = int(inventory[String(slot)]["amount"] + 1)
				return slot

	var slot = inventory_getEmptySlot()
	if (slot < 0): 
		return -1
	inventory[String(slot)] = {"id": String(itemId), "amount": 1}
	return slot


func inventory_removeItem(slot) -> int:
	var newAmount = inventory[String(slot)]["amount"] - 1
	if (newAmount < 1):
		inventory_updateItem(slot, 0, 0)
		return 0
	inventory[String(slot)]["amount"] = newAmount
	return newAmount

func inventory_updateItem(slot:int, new_id:int, new_amount:int) -> void:
	if (slot < 0):
		return
	if (new_amount < 0):
		return
	if (Global_ItemDatabase.get_item(str(new_id)).empty()):
		return
	inventory[str(slot)] = {"id": str(new_id), "amount": int(new_amount)}
	
func inventory_mergeItem(fromSlot:int, toSlot:int) -> void:
	if (fromSlot < 0 or toSlot < 0):
		return
	
	var fromSlot_invData:Dictionary = inventory[str(fromSlot)]
	var toSlot_invData:Dictionary = inventory[str(toSlot)]
	
	var toSlot_stackLimit:int = (Global_ItemDatabase.get_item(inventory[str(toSlot)]["id"])["stack_limit"])
	var fromSlot_stackLimit:int = (Global_ItemDatabase.get_item(inventory[str(fromSlot)]["id"])["stack_limit"])
	
	if (toSlot_stackLimit <= 1 or fromSlot_stackLimit <=1):
		return
	
	
	if (fromSlot_invData["id"] != toSlot_invData["id"]):
		return
	if (int(toSlot_invData["amount"]) >= toSlot_stackLimit or int(fromSlot_invData["amount"] >= toSlot_stackLimit)):
		inventory_moveItem(fromSlot, toSlot)
		return
	
	var toSlot_newAmount:int = (toSlot_invData["amount"]) + (fromSlot_invData["amount"])
	var fromSlot_newAmount:int = 0
	if (toSlot_newAmount > toSlot_stackLimit):
		fromSlot_newAmount = toSlot_newAmount - toSlot_stackLimit
		inventory_updateItem(toSlot, int(inventory[str(toSlot)]["id"]), toSlot_stackLimit)
		inventory_updateItem(fromSlot, int(inventory[str(fromSlot)]["id"]), fromSlot_newAmount)
	else:
		inventory_updateItem(toSlot, int(inventory[str(toSlot)]["id"]), toSlot_newAmount)
		inventory_updateItem(fromSlot, 0, 0)
		

func inventory_moveItem(fromSlot:int, toSlot:int) -> void:
	var temp_ToSlotItem:Dictionary = inventory[str(toSlot)]
	inventory[str(toSlot)] = inventory[str(fromSlot)]
	inventory[str(fromSlot)] = temp_ToSlotItem
