artisan_procurement_vendor_conv = ConvoTemplate:new {
    initialScreen = "first_screen",
    templateType = "Lua",
    luaClassHandler = "conv_handler",
    screens = {}
}

first_screen = ConvoScreen:new {
    id = "first_screen",
    leftDialog = "",
    customDialogText = "Welcome, artisan. I post rotating procurement orders for the trade ledger.",
    stopConversation = "false",
    options = {
        {"View current contract", "procurement_contract_status"},
        {"Submit contract items", "procurement_submit_contract"},
        {"Goodbye", "bye"}
    }
}
artisan_procurement_vendor_conv:addScreen(first_screen)

procurement_contract_status = ConvoScreen:new {
    id = "procurement_contract_status",
    leftDialog = "",
    customDialogText = "Let me consult the current order...",
    stopConversation = "false",
    options = {
        {"View current contract", "procurement_contract_status"},
        {"Submit contract items", "procurement_submit_contract"},
        {"Goodbye", "bye"}
    }
}
artisan_procurement_vendor_conv:addScreen(procurement_contract_status)

procurement_submit_contract = ConvoScreen:new {
    id = "procurement_submit_contract",
    leftDialog = "",
    customDialogText = "Present your goods and I will inspect the shipment...",
    stopConversation = "false",
    options = {
        {"View current contract", "procurement_contract_status"},
        {"Submit contract items", "procurement_submit_contract"},
        {"Goodbye", "bye"}
    }
}
artisan_procurement_vendor_conv:addScreen(procurement_submit_contract)

bye = ConvoScreen:new {
    id = "bye",
    leftDialog = "",
    customDialogText = "Travel safe. Return when you are ready to fulfill an order.",
    stopConversation = "true",
    options = {}
}
artisan_procurement_vendor_conv:addScreen(bye)

addConversationTemplate("artisan_procurement_vendor_conv", artisan_procurement_vendor_conv)
