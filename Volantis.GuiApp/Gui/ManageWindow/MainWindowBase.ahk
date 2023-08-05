class MainWindowBase extends ManageWindowBase {
    listViewColumns := ["ITEMS"]
    lvResizeOpts := "h"
    entityMgr := ""
    hasAddButton := false

    __New(container, entityMgr, themeObj, config) {
        this.entityMgr := entityMgr
        this.lvCount := entityMgr.Count(true)
        super.__New(container, themeObj, config)
    }

    GetDefaultConfig(container, config) {
        defaults := super.GetDefaultConfig(container, config)
        defaults["ownerOrParent"] := ""
        defaults["child"] := false
        defaults["title"] := container.GetApp().appName
        defaults["titleIsMenu"] := true
        defaults["showDetailsPane"] := false
        defaults["addButtonText"] := "Add"
        defaults["actionButtonsHeight"] := 30
        defaults["actionButtons"] := []
        defaults["defaultIconPath"] := ""
        return defaults
    }

    AddBottomControls(y) {
        position := "x" . this.margin . " y" . y
        this.AddManageButton("AddButton", position, "add", true, this.config["addButtonText"])
        this.hasAddButton := true

        if (this.config["actionButtons"].Length) {
            this.AddActionButtons()
        }

    }

    ; Start the buttons on across the left, then get their width and move them to the right
    AddActionButtons() {
        if (this.config["actionButtons"].Length) {
            firstX := "x" . this.margin
            mainX := "x+" . this.margin
            position := "yp h" . this.config["actionButtonsHeight"] . " Section"
            buttons := []
            actionButtonsW := 0

            for index, actionButton in this.config["actionButtons"] {
                itemPos := index == 1 ? firstX : mainX
                itemPos .= " " . position
                guiObj := this.Add("ButtonControl", "v" . actionButton["key"] . " " . itemPos, actionButton["label"], "", "primary")
                guiObj.GetPos(,, &buttonW)

                buttons.Push(Map(
                    "key", actionButton["key"],
                    "guiObj", guiObj,
                    "width", buttonW
                ))

                if (actionButtonsW > 0) {
                    actionButtonsW += this.margin
                }

                actionButtonsW += buttonW
            }

            nextX := this.margin + this.windowSettings["contentWidth"] - actionButtonsW

            for index, buttonInfo in buttons {
                buttonInfo["guiObj"].Move(nextX)
                nextX += buttonInfo["width"] + this.margin
            }
        }
    }

    ShowListViewContextMenu(lv, item, isRightClick, X, Y) {
        entityId := this.listView.GetRowKey(item)

        if (entityId) {
            entityObj := this.entityMgr[entityId]

            menuItems := this.GetListViewContextMenuItems()

            result := this.container["manager.gui"].Menu(menuItems, this)

            this.ProcessListViewContextMenuResult(result, entityId, item)
        }
    }

    GetListViewContextMenuItems() {
        menuItems := []
        menuItems.Push(Map("label", "Edit", "name", "EditEntity"))
        menuItems.Push(Map("label", "Delete", "name", "DeleteEntity"))
        return menuItems
    }

    ProcessListViewContextMenuResult(result, entityId, lvItem) {
        if (result == "EditEntity") {
            this.EditEntity(entityId)
        } else if (result == "DeleteEntity") {
            this.DeleteEntity(entityId, lvItem)
        }
    }

    DeleteEntity(entityId, rowNum := "") {
        entityObj := this.entityMgr[entityId]
        result := this.container["manager.gui"].Dialog(Map(
            "type", "EntityDeleteWindow",
            "ownerOrParent", this.guiId,
            "child", true,
        ), entityObj, this.entityMgr)

        if (result == "Delete") {
            if (rowNum == "") {
                selected := this.listView.GetSelected()

                if (selected.Length > 0) {
                    rowNum := selected[1]
                }
            }

            this.guiObj["ListView"].Delete(rowNum)
        }
    }

    ShowTitleMenu() {
        this.app.MainMenu(
            this,
            this.guiObj["WindowTitleText"],
            false
        )
    }

    FormatDate(timestamp) {
        shortDate := FormatTime(timestamp, "ShortDate")
        shortTime := FormatTime(timestamp, "Time")
        return shortDate . " " . shortTime
    }

    GetDetailsFieldData(entityObj) {
        data := Map()
        data
    }

    AddDetailsPaneHeaderTop(y, paneX, paneW) {
        return false
    }

    AddDetailsPane(y, key := "") {
        entityObj := ""
        iconPath := ""
        displayName := ""

        if (key) {
            entityObj := this.entityMgr[key]

            if (entityObj) {
                iconPath := this.GetItemImage(entityObj)
                displayName := entityObj["name"]
            }
        }

        paneW := this.windowSettings["contentWidth"] - this.lvWidth - this.margin
        paneX := this.margin + this.lvWidth + (this.margin * 2)

        headerTopShown := this.AddDetailsPaneHeaderTop(y, paneX, paneW)

        yVal := headerTopShown ? "+" . (this.margin*2) : y
        imgW := 48
        opts := "vDetailsIcon x" . paneX . " y" . yVal . " h" . imgW . " w" . imgW
        if (!key) {
            opts .= " Hidden"
        }
        this.guiObj.AddPicture(opts, iconPath)
        this.detailsFields.Push("DetailsIcon")

        textW := paneW - imgW - this.margin
        opts := "vDetailsTitle x+" . this.margin . " yp h" . imgW . " w" . textW
        if (!key) {
            opts .= " Hidden"
        }
        this.AddText(displayName, opts, "large", "Bold")
        this.detailsFields.Push("DetailsTitle")

        optsFirst := ["x" . paneX, "y+" . (this.margin*2), "h25"]
        optsMain := ["x+" . this.margin, "yp", "h25"]

        for index, detailsButton in this.GetDetailsButtons() {
            opts := index == 1 ? optsFirst : optsMain
            newOpts := ["v" . detailsButton["key"]]

            for opt in opts {
                newOpts.Push(opt)
            }

            opts := newOpts

            if (!key) {
                opts.Push("Hidden")
            }

            this.Add("ButtonControl", opts, detailsButton["label"], detailsButton["action"], "detailsButton")
        }

        yFirst := "+" . (this.margin*2)
        yMain := ""

        for index, fieldInfo in this.GetDetailsFields() {
            yVal := index == 1 ? yFirst : yMain
            hasIcon := fieldInfo.Has("icon") && fieldInfo["icon"]
            iconPath := hasIcon ? fieldInfo["icon"] : ""

            this.AddDetailsField(fieldInfo["key"], fieldInfo["label"], fieldInfo["value"], yVal, hasIcon, iconPath)
        }
    }

    GetDetailsFields(entityObj := "") {
        fields := []

        fields.Push(Map(
            "label", "Id",
            "key", "Id",
            "value", entityObj ? entityObj.Id : ""
        ))

        return fields
    }

    GetDetailsButtons() {
        buttons := []

        buttons.Push(Map(
            "label", "Edit",
            "key", "DetailsEditButton",
            "action", "OnDetailsEditButton",
        ))

        buttons.Push(Map(
            "label", "Delete",
            "key", "DetailsDeleteButton",
            "action", "OnDetailsDeleteButton",
        ))

        return buttons
    }

    AddDetailsField(fieldName, label, text, y := "", useIcon := false, icon := "") {
        if (!y) {
            y := "+" . (this.margin/2)
        }

        ctlH := 16
        imgW := useIcon ? ctlH : 0

        paneX := this.margin + this.lvWidth + (this.margin*2)
        paneW := this.windowSettings["contentWidth"] - this.lvWidth - this.margin
        opts := "vDetails" . fieldName . "Label x" . paneX . " y" . y . " h" . ctlH
        if (!text && !icon) {
            opts .= " Hidden"
        }
        ctl := this.AddText(label . ": ", opts, "normal", "Bold")
        ctl.GetPos(,, &w)

        textX := paneX + this.margin + w

        if (useIcon) {
            imgH := ctlH
            opts := "vDetails" . fieldName . "DetailIcon x" . textX . " yp h" . imgW . " w" . imgW
            if (!icon) {
                opts .= " Hidden"
            }
            this.guiObj.AddPicture(opts, icon)
            this.detailsFields.Push("Details" . fieldName . "DetailIcon")
        }

        fieldW := paneW - w - this.margin
        if (useIcon) {
            textX += (this.margin/2) + imgW
            fieldW -= ((this.margin/2) + imgW)
        }
        ; TODO: Set status text color based on status
        opts := "vDetails" . fieldName . "Text x" . textX . " yp w" . fieldW
        if (!text) {
            opts .= " Hidden"
        }
        this.AddText(text, opts)
        this.detailsFields.Push("Details" . fieldName . "Text")
    }

    OnDetailsEditButton(btn, info) {
        selected := this.listView.GetSelected("", true)

        if (selected.Length > 0) {
            this.EditEntity(selected[1])
        }
    }

    OnDetailsDeleteButton(btn, info) {
        selected := this.listView.GetSelected("", true)

        if (selected.Length > 0) {
            this.DeleteEntity(selected[1])
        }
    }

    UpdateDetailsPane(key := "") {
        iconPath := ""
        displayName := ""

        if (key != "") {
            entityObj := this.entityMgr[key]
            iconPath := this.GetItemImage(entityObj)
            displayName := entityObj["name"]
        }

        this.guiObj["DetailsIcon"].Value := iconPath
        this.guiObj["DetailsIcon"].Move(,, 48, 48)
        this.guiObj["DetailsIcon"].Visible := (key != "")
        this.guiObj["DetailsTitle"].Text := displayName
        this.guiObj["DetailsTitle"].Visible := (key != "")
        this.guiObj["DetailsEditButton"].Visible := (key != "")
        this.guiObj["DetailsDeleteButton"].Visible := (key != "")

        for index, fieldInfo in this.GetDetailsFields() {
            this.guiObj["Details" . fieldInfo["key"] . "Label"].Visible := (key != "")
            this.guiObj["Details" . fieldInfo["key"] . "Text"].Text := fieldInfo["value"]
            this.guiObj["Details" . fieldInfo["key"] . "Text"].Visible := (key != "")
        }
    }

    GetListViewData(lv) {
        data := Map()

        for key, entityObj in this.entityMgr {
            data[key] := this.GetListViewEntityData(entityObj)
        }

        return data
    }

    GetListViewEntityData(entityObj) {
        return [entityObj["name"]]
    }

    GetViewMode() {
        return "Report"
    }

    ShouldHighlightRow(key, data) {
        return false
    }

    GetListViewImgList(lv, large := false) {
        IL := IL_Create(this.entityMgr.Count(true), 1, large)
        iconNum := 1

        for key, entityObj in this.entityMgr {
            iconSrc := this.GetItemImage(entityObj)
            newIndex := IL_Add(IL, iconSrc)

            if (!newIndex) {
                IL_Add(IL, this.config["defaultIconPath"])
            }

            iconNum++
        }

        return IL
    }

    GetItemImage(entityObj) {
        return this.config["defaultIconPath"]
    }

    OnDoubleClick(LV, rowNum) {
        key := this.listView.GetRowKey(rowNum)
        this.EditEntity(key)
    }

    EditEntity(key) {
        entity := this.entityMgr[key]
        diff := entity.Edit("config", this.guiId)
        keyChanged := (entity.Id != key)

        if (keyChanged || diff != "" && diff.HasChanges()) {
            if (keyChanged) {
                this.entityMgr.RemoveEntity(key)
                this.entityMgr.AddEntity(entity.Id, entity)
            }

            entity.SaveEntity()
            entity.UpdateDefaults()
            this.UpdateListView()
        }
    }

    OnAddButton(btn, info) {

    }

    OnSize(guiObj, minMax, width, height) {
        super.OnSize(guiObj, minMax, width, height)

        if (minMax == -1) {
            return
        }

        if (this.hasAddButton) {
            this.AutoXYWH("y", ["AddButton"])
        }
    }

    Destroy() {
        currentApp := this.app
        super.Destroy()
        currentApp.ExitApp()
    }
}
