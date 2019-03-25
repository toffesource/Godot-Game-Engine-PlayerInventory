# Global_Player.gd

extends Node

var url_PlayerData = "user://PlayerData.bin"
var inventory = {}
var inventory_maxSlots = 45
onready var playerData = Global_DataParser.load_data(url_PlayerData)


func _ready():
	load_data()


func load_data():
	if (playerData == null):
		var dict = {"inventory":{}}
		for slot in range (0, inventory_maxSlots):
			dict["inventory"][String(slot)] = {"id": "0", "amount": 0}
		Global_DataParser.write_data(url_PlayerData, dict)
		inventory = dict["inventory"]
	else:
		inventory = playerData["inventory"]


func save_data():
	Global_DataParser.write_data(url_PlayerData, {"inventory": inventory})

func inventory_getItem(slot):
	return inventory[String(slot)]

func inventory_getEmptySlot():
	for slot in range(0, inventory_maxSlots):
		if (inventory[String(slot)]["id"] == "0"): 
			return int(slot)
	print ("Inventory is full!")
	return -1

func inventory_splitItem(slot, split_amount):
	if (split_amount <= 0):
		return -1
	var emptySlot = inventory_getEmptySlot()
	if emptySlot < 0:
		return emptySlot
		
	var new_amount = int(inventory_getItem(slot)["amount"]) - split_amount
	inventory[String(slot)]["amount"] = new_amount
	inventory[String(emptySlot)] = {"id": inventory[String(slot)]["id"], "amount": split_amount}
	return emptySlot

func inventory_addItem(itemId):
	var itemData = Global_ItemDatabase.get_item(String(itemId))
	if (itemData == null): 
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


func inventory_removeItem(slot):
	var newAmount = inventory[String(slot)]["amount"] - 1
	if (newAmount < 1):
		inventory_updateItem(slot, 0, 0)
		return 0
	inventory[String(slot)]["amount"] = newAmount
	return newAmount

func inventory_updateItem(slot, new_id, new_amount):
	if (slot < 0):
		return
	if (new_amount < 0):
		return
	if (Global_ItemDatabase.get_item(new_id) == null):
		return
	inventory[String(slot)] = {"id": String(new_id), "amount": int(new_amount)}
	
func inventory_mergeItem(fromSlot, toSlot):
	if (fromSlot < 0 or toSlot < 0):
		return
	
	var fromSlot_invData = inventory[String(fromSlot)]
	var toSlot_invData = inventory[String(toSlot)]
	
	var toSlot_stackLimit = int(Global_ItemDatabase.get_item(inventory[String(toSlot)]["id"])["stack_limit"])
	var fromSlot_stackLimit = int(Global_ItemDatabase.get_item(inventory[String(fromSlot)]["id"])["stack_limit"])
	
	if (toSlot_stackLimit <= 1 or fromSlot_stackLimit <=1):
		return
	
	
	if (fromSlot_invData["id"] != toSlot_invData["id"]):
		return
	if (int(toSlot_invData["amount"]) >= toSlot_stackLimit or int(fromSlot_invData["amount"] >= toSlot_stackLimit)):
		inventory_moveItem(fromSlot, toSlot)
		return
	
	var toSlot_newAmount = int(toSlot_invData["amount"]) + int(fromSlot_invData["amount"])
	var fromSlot_newAmount = 0
	if (toSlot_newAmount > toSlot_stackLimit):
		fromSlot_newAmount = toSlot_newAmount - toSlot_stackLimit
		inventory_updateItem(toSlot, inventory[String(toSlot)]["id"], toSlot_stackLimit)
		inventory_updateItem(fromSlot, inventory[String(fromSlot)]["id"], fromSlot_newAmount)
	else:
		inventory_updateItem(toSlot, inventory[String(toSlot)]["id"], toSlot_newAmount)
		inventory_updateItem(fromSlot, 0, 0)
		

func inventory_moveItem(fromSlot, toSlot):
	var temp_ToSlotItem = inventory[String(toSlot)]
	inventory[String(toSlot)] = inventory[String(fromSlot)]
	inventory[String(fromSlot)] = temp_ToSlotItem
