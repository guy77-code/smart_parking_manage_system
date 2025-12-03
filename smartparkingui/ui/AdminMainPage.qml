import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import SmartParking 1.0

Page {
    id: adminMainPage
    title: "管理员中心"

    property var stackView: null
    property int userId: 0
    property string userType: ""
    signal logout()

    TabBar {
        id: tabBar
        width: parent.width
        // 停车场管理员默认显示车位管理标签（索引1）
        currentIndex: userType === "lot_admin" ? 1 : 0

        TabButton { text: "停车场管理"; visible: userType === "system_admin" }
        TabButton { text: "车位管理"; visible: userType === "lot_admin" }
        // 数据分析和违规分析仅对停车场管理员开放（后端分析接口依赖 lot_id）
        TabButton { text: "数据分析"; visible: userType === "lot_admin" }
        TabButton { text: "违规分析"; visible: userType === "lot_admin" }
    }

    StackLayout {
        anchors.top: tabBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        currentIndex: tabBar.currentIndex

        // Parking Lot Management (System Admin)
        ScrollView {
            visible: userType === "system_admin"
            Item {
                anchors.fill: parent
                anchors.margins: 20
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 20

                    RowLayout {
                        Text {
                            text: "停车场管理"
                            font.pixelSize: 20
                            font.bold: true
                        }
                        Item { Layout.fillWidth: true }
                        Button {
                            text: "添加停车场"
                            onClicked: addLotDialog.open()
                        }
                    }

                ListView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 500
                    model: parkingLotModel
                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 100
                        border.color: "gray"
                        border.width: 1
                        radius: 5

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            ColumnLayout {
                                Text { text: model.name || "" }
                                Text { text: model.address || "" }
                                // 兼容后端字段 hourly_rate
                                Text {
                                    text: {
                                        var rate = 0
                                        if (model.hourlyRate !== undefined)
                                            rate = model.hourlyRate
                                        else if (model.hourly_rate !== undefined)
                                            rate = model.hourly_rate
                                        return "费率: ¥" + rate + "/小时"
                                    }
                                }
                            }
                            Item { Layout.fillWidth: true }
                            Button {
                                text: "查看详情"
                                onClicked: {
                                    if (!stackView) {
                                        console.log("stackView is null, cannot navigate to detail page")
                                        return
                                    }
                                    // 系统管理员查看停车场详情时，优先展示车位可视化
                                    var lotIdValue = model.lotId !== undefined ? model.lotId : (model.lot_id || 0)
                                    stackView.push(Qt.resolvedUrl("ParkingVisualizationPage.qml"), {
                                                       lotId: lotIdValue,
                                                       stackView: stackView
                                                   })
                                }
                            }
                            Button {
                                text: "删除"
                                onClicked: {
                                    var lotIdValue = model.lotId !== undefined ? model.lotId : (model.lot_id || 0)
                                    deleteLotDialog.lotId = lotIdValue
                                    deleteLotDialog.lotName = model.name || ""
                                    deleteLotDialog.open()
                                }
                            }
                        }
                    }
                    }
                }
            }
        }

        // Space Management (Lot Admin) - 实时车位可视化
        ScrollView {
            visible: userType === "lot_admin"
            Item {
                anchors.fill: parent
                anchors.margins: 20
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 20

                    Text {
                        text: "车位管理（实时可视化）"
                        font.pixelSize: 20
                        font.bold: true
                    }

                    Loader {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        id: lotSpaceLoader
                        source: "ParkingVisualizationPage.qml"
                        onLoaded: {
                            if (!item)
                                return
                            var info = authManager.userInfo
                            var lotIdValue = info && (info.lot_id || info.lotId || 0)
                            item.lotId = lotIdValue
                            item.stackView = stackView
                            item.isAdmin = true  // 管理员模式，可以编辑车位
                        }
                    }
                }
            }
        }

        // Data Analysis（仅停车场管理员）
        ScrollView {
            visible: userType === "lot_admin"
            Item {
                anchors.fill: parent
                anchors.margins: 20
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 20

                    Text {
                        text: "数据分析"
                        font.pixelSize: 20
                        font.bold: true
                    }

                    RowLayout {
                        Text { text: "开始时间:" }
                        TextField {
                            id: startTimeField
                            placeholderText: "2025-01-01T00:00:00Z"
                        }
                        Text { text: "结束时间:" }
                        TextField {
                            id: endTimeField
                            placeholderText: "2025-01-31T23:59:59Z"
                        }
                        Button {
                            text: "查询"
                            onClicked: {
                                // 接受用户输入的日期或完整时间，统一转换为RFC3339
                                function normalizeTime(t, isEnd) {
                                    if (!t || t.length === 0)
                                        return ""
                                    // 如果已经包含T，直接返回
                                    if (t.indexOf("T") >= 0)
                                        return t
                                    // 确保日期格式为 YYYY-MM-DD（补零并验证有效性）
                                    var parts = t.split("-")
                                    if (parts.length === 3) {
                                        var year = parseInt(parts[0])
                                        var month = parseInt(parts[1].length === 1 ? "0" + parts[1] : parts[1])
                                        var day = parseInt(parts[2].length === 1 ? "0" + parts[2] : parts[2])
                                        
                                        // 验证日期有效性
                                        var daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
                                        // 检查闰年
                                        if (month === 2 && ((year % 4 === 0 && year % 100 !== 0) || year % 400 === 0)) {
                                            daysInMonth[1] = 29
                                        }
                                        
                                        if (month < 1 || month > 12) {
                                            console.log("无效的月份:", month)
                                            return ""
                                        }
                                        
                                        if (day < 1 || day > daysInMonth[month - 1]) {
                                            console.log("无效的日期:", day, "月份:", month)
                                            // 如果是结束日期且日期无效，使用该月最后一天
                                            if (isEnd) {
                                                day = daysInMonth[month - 1]
                                            } else {
                                                return ""
                                            }
                                        }
                                        
                                        var monthStr = month < 10 ? "0" + month : "" + month
                                        var dayStr = day < 10 ? "0" + day : "" + day
                                        t = year + "-" + monthStr + "-" + dayStr
                                    }
                                    return t + (isEnd ? "T23:59:59Z" : "T00:00:00Z")
                                }
                                var start = normalizeTime(startTimeField.text, false)
                                var end = normalizeTime(endTimeField.text, true)
                                if (start && end) {
                                    apiClient.getOccupancyAnalysis(start, end)
                                } else {
                                    console.log("请填写开始时间和结束时间")
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 400
                        border.color: "gray"
                        border.width: 1
                        radius: 5

                        ScrollView {
                            anchors.fill: parent
                            anchors.margins: 10
                            
                            ColumnLayout {
                                width: parent.width
                                spacing: 10
                                
                                Text {
                                    Layout.fillWidth: true
                                    text: occupancyDataText
                                    color: "gray"
                                    wrapMode: Text.Wrap
                                    visible: occupancyDataText.indexOf("{") < 0 && occupancyDataText.indexOf("[") < 0
                                }
                                
                                // 表格显示
                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: 2
                                    visible: occupancyDataText.indexOf("{") >= 0 || occupancyDataText.indexOf("[") >= 0
                                    
                                    Repeater {
                                        model: occupancyTableModel
                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 30
                                            border.color: "lightgray"
                                            border.width: 1
                                            
                                            Text {
                                                anchors.centerIn: parent
                                                text: model.display || ""
                                                font.pixelSize: 12
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    ListModel {
                        id: occupancyTableModel
                    }
                }
            }
        }

        // Violation Analysis（仅停车场管理员）
        ScrollView {
            visible: userType === "lot_admin"
            Item {
                anchors.fill: parent
                anchors.margins: 20
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 20

                    Text {
                        text: "违规分析"
                        font.pixelSize: 20
                        font.bold: true
                    }

                    RowLayout {
                        Text { text: "年份:" }
                        SpinBox {
                            id: yearSpinBox
                            from: 2020
                            to: 2030
                            value: new Date().getFullYear()
                        }
                        Text { text: "月份:" }
                        SpinBox {
                            id: monthSpinBox
                            from: 1
                            to: 12
                            value: new Date().getMonth() + 1
                        }
                        Button {
                            text: "查询"
                            onClicked: {
                                violationDataText = "查询中..."
                                apiClient.getViolationAnalysis(yearSpinBox.value, monthSpinBox.value)
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 400
                        border.color: "gray"
                        border.width: 1
                        radius: 5

                        ScrollView {
                            anchors.fill: parent
                            anchors.margins: 10
                            
                            ColumnLayout {
                                width: parent.width
                                spacing: 10
                                
                                Text {
                                    Layout.fillWidth: true
                                    text: violationDataText
                                    color: "gray"
                                    wrapMode: Text.Wrap
                                    visible: violationDataText.indexOf("{") < 0 && violationDataText.indexOf("[") < 0
                                }
                                
                                // 表格显示
                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: 2
                                    visible: violationDataText.indexOf("{") >= 0 || violationDataText.indexOf("[") >= 0
                                    
                                    Repeater {
                                        model: violationTableModel
                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 30
                                            border.color: "lightgray"
                                            border.width: 1
                                            
                                            Text {
                                                anchors.centerIn: parent
                                                text: model.display || ""
                                                font.pixelSize: 12
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    ListModel {
                        id: violationTableModel
                    }
                }
            }
        }
    }

    ListModel {
        id: parkingLotModel
    }

    ListModel {
        id: spaceModel
    }

    property string violationDataText: "违规分析结果将显示在这里"
    property string occupancyDataText: "数据分析结果将显示在这里"

    Component.onCompleted: {
        if (userType === "system_admin") {
            apiClient.getParkingLots()
        } else if (userType === "lot_admin") {
            // Loader 中的 ParkingVisualizationPage 会在加载完成后自行读取 lot_id 并加载车位
        }
    }

    Connections {
        target: apiClient

        function onParkingLotsReceived(lots) {
            parkingLotModel.clear()
            for (var i = 0; i < lots.length; i++) {
                parkingLotModel.append(lots[i])
            }
            
            // 如果刚刚创建了停车场，创建车位
            if (addLotDialog.pendingNormalSpaces > 0 || addLotDialog.pendingChargingSpaces > 0) {
                var newLotId = 0
                if (parkingLotModel.count > 0) {
                    var lastLot = parkingLotModel.get(parkingLotModel.count - 1)
                    newLotId = lastLot.lot_id !== undefined ? lastLot.lot_id : (lastLot.lotId || 0)
                }
                
                if (newLotId > 0) {
                    // 创建普通车位
                    var normalCount = 0
                    for (var j = 0; j < addLotDialog.pendingNormalSpaces; j++) {
                        normalCount++
                        var level = Math.floor((normalCount - 1) / (addLotDialog.pendingNormalSpaces / addLotDialog.pendingLevels)) + 1
                        if (level > addLotDialog.pendingLevels) level = addLotDialog.pendingLevels
                        var spaceNum = "N" + (normalCount < 10 ? "0" : "") + normalCount
                        apiClient.addParkingSpace(newLotId, level, spaceNum, "普通", 1)
                    }
                    
                    // 创建充电桩车位
                    var chargingCount = 0
                    for (var k = 0; k < addLotDialog.pendingChargingSpaces; k++) {
                        chargingCount++
                        var level2 = Math.floor((chargingCount - 1) / (addLotDialog.pendingChargingSpaces / addLotDialog.pendingLevels)) + 1
                        if (level2 > addLotDialog.pendingLevels) level2 = addLotDialog.pendingLevels
                        var spaceNum2 = "C" + (chargingCount < 10 ? "0" : "") + chargingCount
                        apiClient.addParkingSpace(newLotId, level2, spaceNum2, "充电桩", 1)
                    }
                    
                    // 重置待处理参数
                    addLotDialog.pendingNormalSpaces = 0
                    addLotDialog.pendingChargingSpaces = 0
                }
            }
        }

        function onRequestFinished(response) {
            if (response.hasOwnProperty("error")) {
                console.log("Error:", response.error)
                var url = response.url || ""
                if (url.indexOf("/admin/occupancy") >= 0) {
                    occupancyDataText = "查询失败: " + (response.error || response.message || "未知错误")
                } else if (url.indexOf("/admin/violations") >= 0) {
                    violationDataText = "查询失败: " + (response.error || response.message || "未知错误")
                }
                return
            }
            // 添加或删除停车场成功后刷新列表
            var url = response.url || ""
            if (url.indexOf("/api/v2/addparkinglot") >= 0 || url.indexOf("/api/v2/deleteparkinglot/") >= 0) {
                apiClient.getParkingLots()
            } else if (url.indexOf("/admin/occupancy") >= 0) {
                // 处理使用率分析结果
                var occupancyData = response.data || response
                occupancyDataText = formatDataAsTable(occupancyData, "使用率分析")
                updateOccupancyTable(occupancyData)
            } else if (url.indexOf("/admin/violations") >= 0) {
                // 处理违规分析结果
                var violationData = response.data || response
                violationDataText = formatDataAsTable(violationData, "违规分析")
                updateViolationTable(violationData)
            }
        }
        
        function formatDataAsTable(data, title) {
            if (!data || typeof data !== 'object') {
                return title + "：无数据"
            }
            
            var result = title + "结果：\n\n"
            
            // 处理对象
            if (Array.isArray(data)) {
                if (data.length === 0) {
                    return title + "：无数据"
                }
                // 显示数组中的对象
                for (var i = 0; i < Math.min(data.length, 10); i++) {
                    var item = data[i]
                    if (typeof item === 'object') {
                        for (var key in item) {
                            if (item.hasOwnProperty(key) && typeof item[key] !== 'object') {
                                result += key + ": " + item[key] + "\n"
                            }
                        }
                        result += "---\n"
                    }
                }
            } else {
                // 显示对象的键值对
                for (var key in data) {
                    if (data.hasOwnProperty(key)) {
                        var value = data[key]
                        if (typeof value !== 'object' || value === null) {
                            result += key + ": " + value + "\n"
                        } else if (Array.isArray(value)) {
                            result += key + ": [" + value.length + " 项]\n"
                        }
                    }
                }
            }
            
            return result
        }
        
        function updateOccupancyTable(data) {
            occupancyTableModel.clear()
            if (data && typeof data === 'object') {
                if (Array.isArray(data)) {
                    for (var i = 0; i < data.length; i++) {
                        var item = data[i]
                        if (typeof item === 'object') {
                            for (var key in item) {
                                if (item.hasOwnProperty(key) && typeof item[key] !== 'object') {
                                    occupancyTableModel.append({
                                        display: key + ": " + item[key]
                                    })
                                }
                            }
                        }
                    }
                } else {
                    for (var key in data) {
                        if (data.hasOwnProperty(key) && typeof data[key] !== 'object') {
                            occupancyTableModel.append({
                                display: key + ": " + data[key]
                            })
                        }
                    }
                }
            }
        }
        
        function updateViolationTable(data) {
            violationTableModel.clear()
            if (data && typeof data === 'object') {
                if (Array.isArray(data)) {
                    for (var i = 0; i < data.length; i++) {
                        var item = data[i]
                        if (typeof item === 'object') {
                            for (var key in item) {
                                if (item.hasOwnProperty(key) && typeof item[key] !== 'object') {
                                    violationTableModel.append({
                                        display: key + ": " + item[key]
                                    })
                                }
                            }
                        }
                    }
                } else {
                    for (var key in data) {
                        if (data.hasOwnProperty(key) && typeof data[key] !== 'object') {
                            violationTableModel.append({
                                display: key + ": " + data[key]
                            })
                        }
                    }
                }
            }
        }
    }

    // 添加停车场对话框
    Dialog {
        id: addLotDialog
        modal: true
        title: "添加停车场"
        standardButtons: Dialog.Ok | Dialog.Cancel

        property alias lotName: lotNameField.text
        property alias lotAddress: lotAddressField.text
        property alias lotLevels: levelsField.text
        property alias lotSpaces: spacesField.text
        property alias lotRate: rateField.text
        property alias lotDesc: descField.text

        onAccepted: {
            var name = lotName.trim()
            var address = lotAddress.trim()
            var levels = parseInt(lotLevels) || 1
            var spaces = parseInt(lotSpaces) || 0
            var rate = parseFloat(lotRate) || 0
            var desc = lotDesc.trim()
            var normalSpaces = parseInt(normalSpacesField.text) || 0
            var chargingSpaces = parseInt(chargingSpacesField.text) || 0

            if (name.length === 0 || address.length === 0) {
                console.log("停车场名称和地址不能为空")
                return
            }

            if (normalSpaces + chargingSpaces !== spaces) {
                console.log("普通车位和充电桩车位数量之和必须等于总车位数")
                return
            }

            // 先创建停车场
            apiClient.addParkingLot(name, address, levels, spaces, rate, 1, desc)
            
            // 注意：车位创建需要在停车场创建成功后进行，这里先保存参数
            addLotDialog.pendingNormalSpaces = normalSpaces
            addLotDialog.pendingChargingSpaces = chargingSpaces
            addLotDialog.pendingLevels = levels
        }
        
        property int pendingNormalSpaces: 0
        property int pendingChargingSpaces: 0
        property int pendingLevels: 1

        contentItem: ColumnLayout {
            anchors.margins: 20
            spacing: 10

            TextField {
                id: lotNameField
                Layout.fillWidth: true
                placeholderText: "停车场名称"
            }
            TextField {
                id: lotAddressField
                Layout.fillWidth: true
                placeholderText: "停车场地址"
            }
            TextField {
                id: levelsField
                Layout.fillWidth: true
                placeholderText: "总楼层数（如：3）"
                inputMethodHints: Qt.ImhDigitsOnly
            }
            TextField {
                id: spacesField
                Layout.fillWidth: true
                placeholderText: "总车位数（如：200）"
                inputMethodHints: Qt.ImhDigitsOnly
            }
            TextField {
                id: rateField
                Layout.fillWidth: true
                placeholderText: "小时费率（如：5.0）"
            }
            TextField {
                id: descField
                Layout.fillWidth: true
                placeholderText: "说明（可选）"
            }
            
            Text {
                text: "车位配置"
                font.pixelSize: 14
                font.bold: true
            }
            
            Text {
                text: "普通车位数:"
            }
            TextField {
                id: normalSpacesField
                Layout.fillWidth: true
                placeholderText: "普通车位数（如：80）"
                inputMethodHints: Qt.ImhDigitsOnly
            }
            
            Text {
                text: "充电桩车位数:"
            }
            TextField {
                id: chargingSpacesField
                Layout.fillWidth: true
                placeholderText: "充电桩车位数（如：20）"
                inputMethodHints: Qt.ImhDigitsOnly
            }
        }
    }

    // 删除停车场确认对话框
    Dialog {
        id: deleteLotDialog
        modal: true
        title: "删除停车场"
        standardButtons: Dialog.Ok | Dialog.Cancel

        property int lotId: 0
        property string lotName: ""

        onAccepted: {
            if (lotId > 0) {
                apiClient.deleteParkingLot(lotId)
            }
        }

        contentItem: ColumnLayout {
            anchors.margins: 20
            spacing: 10

            Text {
                Layout.fillWidth: true
                text: "确定要删除停车场 \"" + deleteLotDialog.lotName + "\" 吗？"
                wrapMode: Text.Wrap
            }
            Text {
                Layout.fillWidth: true
                text: "警告：删除停车场将同时删除所有关联的车位数据！"
                color: "red"
                wrapMode: Text.Wrap
            }
        }
    }

    header: ToolBar {
        RowLayout {
            anchors.fill: parent
            Text {
                text: "智能停车系统 - 管理员中心"
                font.pixelSize: 18
            }
            Item { Layout.fillWidth: true }
            Button {
                text: "退出登录"
                onClicked: logout()
            }
        }
    }
}

