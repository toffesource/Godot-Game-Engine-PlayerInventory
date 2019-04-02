extends Control

var activeItemSlot:int = -1
var dropItemSlot:int = -1

onready var isDraggingItem:bool = false
onready var mouseButtonReleased:bool = true
var draggedItemSlot:int = -1
onready var initial_mousePos:Vector2 = Vector2()
onready var cursor_insideItemList:bool = false

var isAwaitingSplit:bool = false
var splitItemSlot:int = -1

func _ready() -> void:
	# Initialize Item List
	$Panel/ItemList.set_max_columns(10)
	$Panel/ItemList.set_fixed_icon_size(Vector2(48,48))
	$Panel/ItemList.set_icon_mode($Panel/ItemList.ICON_MODE_TOP)
	$Panel/ItemList.set_select_mode($Panel/ItemList.SELECT_SINGLE)
	$Panel/ItemList.set_same_column_width(true)
	$Panel/ItemList.set_allow_rmb_select(true)
	
	load_items()
	
	set_process(false)
	set_process_input(true)
	
#warning-ignore:unused_argument
func _process(delta) -> void:
	if (isDraggingItem):
		$Panel/Sprite_DraggedItem.global_position = get_viewport().get_mouse_position()


func _input(event) -> void:
	if (!isDraggingItem):
		if event.is_action_pressed("key_shift"):
			isAwaitingSplit = true
		if event.is_action_released("key_shift"):
			isAwaitingSplit = false
	
	if (event is InputEventMouseButton):
		if (!isAwaitingSplit):
			if (event.is_action_pressed("mouse_leftbtn")):
				mouseButtonReleased = false
				initial_mousePos = get_viewport().get_mouse_position()
			if (event.is_action_released("mouse_leftbtn")):
				move_merge_item()
				end_drag_item()
		else:
			if (event.is_action_pressed("mouse_rightbtn")):
				if (activeItemSlot >= 0):
					begin_split_item()
	if (event is InputEventMouseMotion):
		if (cursor_insideItemList):
			activeItemSlot = $Panel/ItemList.get_item_at_position($Panel/ItemList.get_local_mouse_position(),true)
			if (activeItemSlot >= 0):
				$Panel/ItemList.select(activeItemSlot, true)
				if (isDraggingItem or mouseButtonReleased):
					return
				if (!$Panel/ItemList.is_item_selectable(activeItemSlot)): 
					end_drag_item()
				if (initial_mousePos.distance_to(get_viewport().get_mouse_position()) > 0.0): 
					begin_drag_item(activeItemSlot)
		else:
			activeItemSlot = -1
	

func load_items() -> void:
	$Panel/ItemList.clear()
	for slot in range(0, Global_Player.inventory_maxSlots):
		$Panel/ItemList.add_item("", null, false)
		update_slot(slot)


func update_slot(slot:int) -> void:
	if (slot < 0): 
		return
	var inventoryItem:Dictionary = Global_Player.inventory[str(slot)]
	var itemMetaData = Global_ItemDatabase.get_item(str(inventoryItem["id"]))
	var icon = ResourceLoader.load(itemMetaData["icon"])
	var amount = int(inventoryItem["amount"])
	
	itemMetaData["amount"] = amount
	if (!itemMetaData["stackable"]): 
		amount = " "
	$Panel/ItemList.set_item_text(slot, String(amount))
	$Panel/ItemList.set_item_icon(slot, icon)
	$Panel/ItemList.set_item_selectable(slot, int(inventoryItem["id"]) > 0)
	$Panel/ItemList.set_item_metadata(slot, itemMetaData)
	$Panel/ItemList.set_item_tooltip(slot, itemMetaData["name"])
	$Panel/ItemList.set_item_tooltip_enabled(slot, int(inventoryItem["id"]) > 0)

func _on_Button_AddItem_pressed() -> void:
	$Panel/WindowDialog_AddItemWindow.popup()


func _on_AddItemWindow_Button_Close_pressed() -> void:
	$Panel/WindowDialog_AddItemWindow.hide()


func _on_AddItemWindow_Button_AddItem_pressed() -> void:
	var affectedSlot = Global_Player.inventory_addItem($Panel/WindowDialog_AddItemWindow/AddItemWindow_SpinBox_ItemID.get_value())
	if (affectedSlot >= 0): 
		update_slot(affectedSlot)


func _on_ItemList_item_rmb_selected(index:int, atpos:Vector2) -> void:
	if (isDraggingItem):
		return
	if (isAwaitingSplit):
		return
	
	dropItemSlot = index
	var itemData:Dictionary = $Panel/ItemList.get_item_metadata(index)
	if (int(itemData["id"])) < 1: return
	var strItemInfo:String = ""
	
	$Panel/WindowDialog_ItemMenu.set_position(get_viewport().get_mouse_position())
	$Panel/WindowDialog_ItemMenu.set_title(itemData["name"])
	$Panel/WindowDialog_ItemMenu/ItemMenu_TextureFrame_Icon.set_texture($Panel/ItemList.get_item_icon(index))
	
	strItemInfo = "Name: [color=#00aedb] " + itemData["name"] + "[/color]\n"
	strItemInfo = strItemInfo + "Type: [color=#f37735] " + itemData["type"] + "[/color]\n"
	strItemInfo = strItemInfo + "Weight: [color=#00b159] " + String(itemData["weight"]) + "[/color]\n"
	strItemInfo = strItemInfo + "Sell Price: [color=#ffc425] " + String(itemData["sell_price"]) + "[/color] gold\n"
	strItemInfo = strItemInfo + "\n[color=#b3cde0]" + itemData["description"] + "[/color]"
	
	$Panel/WindowDialog_ItemMenu/ItemMenu_RichTextLabel_ItemInfo.set_bbcode(strItemInfo)
	$Panel/WindowDialog_ItemMenu/ItemMenu_Button_DropItem.set_text("(" + String(itemData["amount"]) + ") Drop" )
	activeItemSlot = index
	$Panel/WindowDialog_ItemMenu.popup()


func _on_ItemMenu_Button_DropItem_pressed() -> void:
	var newAmount = Global_Player.inventory_removeItem(dropItemSlot)
	if (newAmount < 1):
		$Panel/WindowDialog_ItemMenu.hide()
	else:
		$Panel/WindowDialog_ItemMenu/ItemMenu_Button_DropItem.set_text("(" + String(newAmount) + ") Drop")
	update_slot(dropItemSlot)


func _on_Button_Save_pressed() -> void:
	Global_Player.save_data()

func begin_split_item() -> void:
	if activeItemSlot < 0:
		return
	splitItemSlot = activeItemSlot
	var itemMetaData = $Panel/ItemList.get_item_metadata(splitItemSlot)
	var availableAmount = int(itemMetaData["amount"])
	if (availableAmount > 1):
		$Panel/WindowDialog_SplitItemWindow/SplitItemWindow_HSlider_Amount.min_value = 1
		$Panel/WindowDialog_SplitItemWindow/SplitItemWindow_HSlider_Amount.max_value = availableAmount -1
		$Panel/WindowDialog_SplitItemWindow/SplitItemWindow_HSlider_Amount.value = 1
		$Panel/WindowDialog_SplitItemWindow.popup()


func _on_SplitItemWindow_Button_Split_pressed() -> void:
	update_slot(Global_Player.inventory_splitItem(splitItemSlot, int($Panel/WindowDialog_SplitItemWindow/SplitItemWindow_HSlider_Amount.value)))
	update_slot(splitItemSlot)
	splitItemSlot = -1
	$Panel/WindowDialog_SplitItemWindow.hide()
	

func begin_drag_item(index:int) -> void:
	if (isDraggingItem): 
		return
	if (index < 0): 
		return
	
	set_process(true)
	$Panel/Sprite_DraggedItem.texture = $Panel/ItemList.get_item_icon(index)
	$Panel/Sprite_DraggedItem.show()
	
	$Panel/ItemList.set_item_text(index, " ")
	$Panel/ItemList.set_item_icon(index, ResourceLoader.load(Global_ItemDatabase.get_item("0")["icon"]))
	
	draggedItemSlot = index
	isDraggingItem = true
	mouseButtonReleased = false
	$Panel/Sprite_DraggedItem.global_translate(get_viewport().get_mouse_position())


func end_drag_item() -> void:
	set_process(false)
	draggedItemSlot = -1
	$Panel/Sprite_DraggedItem.hide()
	mouseButtonReleased = true
	isDraggingItem = false
	activeItemSlot = -1


func move_merge_item() -> void:
	if (draggedItemSlot < 0): 
		return
	if (activeItemSlot < 0):
		update_slot(draggedItemSlot)
		return
		
	if (activeItemSlot == draggedItemSlot):
		update_slot(draggedItemSlot)
	else:
		if ($Panel/ItemList.get_item_metadata(activeItemSlot)["id"] == $Panel/ItemList.get_item_metadata(draggedItemSlot)["id"]):
			var itemData = $Panel/ItemList.get_item_metadata(activeItemSlot)
			if (int(itemData["stack_limit"]) >= 2):
				Global_Player.inventory_mergeItem(draggedItemSlot, activeItemSlot)
				update_slot(draggedItemSlot)
				update_slot(activeItemSlot)
				return
			else:
				update_slot(draggedItemSlot)
				return
		else:
			Global_Player.inventory_moveItem(draggedItemSlot, activeItemSlot)
			update_slot(draggedItemSlot)
			update_slot(activeItemSlot)
			
			
func _on_ItemList_mouse_entered() -> void:
	cursor_insideItemList = true;


func _on_ItemList_mouse_exited() -> void:
	cursor_insideItemList = false;

func _on_SplitItemWindow_Button_Cancel_pressed() -> void:
	$Panel/WindowDialog_SplitItemWindow.hide()


func _on_SplitItemWindow_HSlider_Amount_value_changed(value:int) -> void:
	$Panel/WindowDialog_SplitItemWindow/SplitItemWindow_Label_Amount.text = String(value)


