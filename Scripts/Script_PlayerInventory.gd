# Script_PlayerInventory.gd

extends Node

onready var itemList = get_node("Panel/ItemList")

# WindowDialog_AddItemWindow Variables.
onready var addItemWindow = get_node("Panel/WindowDialog_AddItemWindow")
onready var addItemWindow_SpinBox_ItemId = get_node("Panel/WindowDialog_AddItemWindow/AddItemWindow_SpinBox_ItemID")

# WindowDialog_ItemMenu Variables.
onready var itemMenu = get_node("Panel/WindowDialog_ItemMenu")
onready var itemMenu_TextureFrame_Icon = get_node("Panel/WindowDialog_ItemMenu/ItemMenu_TextureFrame_Icon")
onready var itemMenu_RichTextLabel_ItemInfo = get_node("Panel/WindowDialog_ItemMenu/ItemMenu_RichTextLabel_ItemInfo")
onready var itemMenu_Button_DropItem = get_node("Panel/WindowDialog_ItemMenu/ItemMenu_Button_DropItem")
var activeItemSlot = -1
var dropItemSlot = -1

onready var isDraggingItem = false
var draggedItemTexture
onready var draggedItem = get_node("Panel/Sprite_DraggedItem")
onready var mouseButtonReleased = true
var draggedItemSlot = -1
onready var initial_mousePos = Vector2()
onready var cursor_insideItemList = false

func _ready():
	# Initialize Item List
	itemList.set_max_columns(10)
	itemList.set_fixed_icon_size(Vector2(48,48))
	itemList.set_icon_mode(ItemList.ICON_MODE_TOP)
	itemList.set_select_mode(ItemList.SELECT_SINGLE)
	itemList.set_same_column_width(true)
	itemList.set_allow_rmb_select(true)
	
	load_items()
	
	set_process(true)
	set_process_input(true)
	
func _process(delta):
	if isDraggingItem:
		draggedItem.global_position = get_viewport().get_mouse_position()


func _input(event):
	if event is InputEventMouseButton:
		if event.is_action_pressed("mouse_leftbtn"):
			mouseButtonReleased = false
			initial_mousePos = get_viewport().get_mouse_position()
		if event.is_action_released("mouse_leftbtn"):
			move_item()
			end_drag_item()
			
	if event is InputEventMouseMotion:
		if cursor_insideItemList:
			activeItemSlot = itemList.get_item_at_position(itemList.get_local_mouse_position(),true)
			if activeItemSlot >= 0:
				itemList.select(activeItemSlot, true)
				if isDraggingItem or mouseButtonReleased:
					return
				if !itemList.is_item_selectable(activeItemSlot): 
					end_drag_item()
				if initial_mousePos.distance_to(get_viewport().get_mouse_position()) > 0.0: 
					begin_drag_item(activeItemSlot)
		else:
			activeItemSlot = -1


func load_items():
	itemList.clear()
	for slot in range(0, Global_Player.inventory_maxSlots):
		var inventoryItem = Global_Player.inventory[String(slot)]
		var itemMetaData = Global_ItemDatabase.get_item(inventoryItem["id"])
		var icon = ResourceLoader.load(itemMetaData["icon"])
		var amount = int(inventoryItem["amount"])
		
		itemMetaData["amount"] = amount
		if !itemMetaData["stackable"]: amount = " "
		itemList.add_item(String(amount), icon, true)
		itemList.set_item_metadata(slot, itemMetaData)
		itemList.set_item_tooltip(slot, itemMetaData["name"])
		if inventoryItem["id"] == "0": 
			itemList.set_item_text(slot, " ")
			itemList.set_item_tooltip_enabled(slot, false)
			itemList.set_item_selectable(slot, false)


func _on_Button_AddItem_pressed():
	addItemWindow.popup()


func _on_AddItemWindow_Button_Close_pressed():
	addItemWindow.hide()


func _on_AddItemWindow_Button_AddItem_pressed():
	Global_Player.inventory_addItem(addItemWindow_SpinBox_ItemId.get_value())
	load_items()


func _on_ItemList_item_rmb_selected( index, atpos ):	
	if isDraggingItem: return
	
	dropItemSlot = index
	
	var itemData = itemList.get_item_metadata(index)
	if int(itemData["id"]) < 1: return
	var strItemInfo = ""
	
	itemMenu.set_position(get_viewport().get_mouse_position())
	
	itemMenu.set_title(itemData["name"])
	itemMenu_TextureFrame_Icon.set_texture(itemList.get_item_icon(index))
	
	strItemInfo = "Name: [color=#00aedb] " + itemData["name"] + "[/color]\n"
	strItemInfo = strItemInfo + "Type: [color=#f37735] " + itemData["type"] + "[/color]\n"
	strItemInfo = strItemInfo + "Weight: [color=#00b159] " + String(itemData["weight"]) + "[/color]\n"
	strItemInfo = strItemInfo + "Sell Price: [color=#ffc425] " + String(itemData["sell_price"]) + "[/color] gold\n"
	strItemInfo = strItemInfo + "\n[color=#b3cde0]" + itemData["description"] + "[/color]"
	
	itemMenu_RichTextLabel_ItemInfo.set_bbcode(strItemInfo)
	itemMenu_Button_DropItem.set_text("(" + String(itemData["amount"]) + ") Drop" )
	activeItemSlot = index
	itemMenu.popup()


func _on_ItemMenu_Button_DropItem_pressed():
	var newAmount = Global_Player.inventory_removeItem(dropItemSlot)
	if newAmount < 1:
		itemMenu.hide()
	else:
		itemMenu_Button_DropItem.set_text("(" + String(newAmount) + ") Drop")
	load_items()


func _on_Button_Save_pressed():
	Global_Player.save_data()


func begin_drag_item(index):
	if isDraggingItem: return
	if index < 0: return
	draggedItem.texture = itemList.get_item_icon(index)
	draggedItem.show()
	
	itemList.set_item_text(index, " ")
	itemList.set_item_icon(index, ResourceLoader.load(Global_ItemDatabase.get_item(0)["icon"]))
	
	draggedItemSlot = index
	isDraggingItem = true
	mouseButtonReleased = false
	draggedItem.global_translate(get_viewport().get_mouse_position())


func end_drag_item():
	draggedItemSlot = -1
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	draggedItem.hide()
	mouseButtonReleased = true
	isDraggingItem = false
	activeItemSlot = -1
	return


func move_item():
	if draggedItemSlot < 0: return
	if activeItemSlot == draggedItemSlot or activeItemSlot < 0:
		load_items()
		return
	Global_Player.inventory_moveItem(draggedItemSlot, activeItemSlot)
	load_items()


func _on_ItemList_mouse_entered():
	cursor_insideItemList = true;


func _on_ItemList_mouse_exited():
	cursor_insideItemList = false;
