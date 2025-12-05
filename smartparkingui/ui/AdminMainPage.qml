import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtCharts 2.15
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
        currentIndex: 0  // 默认值，会在Component.onCompleted中更新

        TabButton { 
            id: lotManagementTab
            text: "停车场管理"; 
            visible: userType === "system_admin" 
        }
        TabButton { 
            id: spaceManagementTab
            text: "车位管理"; 
            visible: userType === "lot_admin" 
        }
        TabButton { 
            id: dataAnalysisTab
            text: "数据分析"; 
            visible: userType === "lot_admin" 
        }
        TabButton { 
            id: violationAnalysisTab
            text: "违规分析"; 
            visible: userType === "lot_admin" 
        }
    }

    StackLayout {
        id: stackLayout
        anchors.top: tabBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        currentIndex: tabBar.currentIndex

        // 1. Parking Lot Management (System Admin) - 保持不变
        ScrollView {
            visible: userType === "system_admin"
            Item {
                anchors.fill: parent
                anchors.margins: 20
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 20

                    RowLayout {
                        Text { text: "停车场管理"; font.pixelSize: 20; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Button { text: "添加停车场"; onClicked: addLotDialog.open() }
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
                                    Text {
                                        text: {
                                            var rate = 0
                                            if (model.hourlyRate !== undefined) rate = model.hourlyRate
                                            else if (model.hourly_rate !== undefined) rate = model.hourly_rate
                                            return "费率: ¥" + rate + "/小时"
                                        }
                                    }
                                }
                                Item { Layout.fillWidth: true }
                                Button {
                                    text: "查看详情"
                                    onClicked: {
                                        if (!stackView) return
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

        // 2. Space Management (Lot Admin) - 保持不变
        ScrollView {
            visible: userType === "lot_admin"
            Item {
                anchors.fill: parent
                anchors.margins: 20
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 20
                    Text { text: "车位管理（实时可视化）"; font.pixelSize: 20; font.bold: true }
                    Loader {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        id: lotSpaceLoader
                        active: userType === "lot_admin" && visible
                        source: userType === "lot_admin" ? "ParkingVisualizationPage.qml" : ""
                        onLoaded: {
                            if (!item) return
                            try {
                                var info = authManager.userInfo
                                if (!info) {
                                    console.log("Warning: authManager.userInfo is null")
                                    return
                                }
                                var lotIdValue = info.lot_id !== undefined ? info.lot_id : 
                                                 (info.lotId !== undefined ? info.lotId : 0)
                                if (lotIdValue > 0) {
                                    item.lotId = lotIdValue
                                }
                                if (stackView) {
                                    item.stackView = stackView
                                }
                                item.isAdmin = true
                            } catch (e) {
                                console.log("Error loading ParkingVisualizationPage:", e)
                            }
                        }
                    }
                }
            }
        }

        // 3. Data Analysis（优化：图表化）
        ScrollView {
            visible: userType === "lot_admin"
            contentHeight: 800 // 增加高度以容纳图表
            Item {
                width: parent.width
                height: 800
                anchors.margins: 20
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    Text { text: "数据分析仪表盘"; font.pixelSize: 20; font.bold: true }

                    // 时间选择栏
                    RowLayout {
                        Text { text: "范围:" }
                        SpinBox { id: adminStartYear; from: 2020; to: 2100; value: new Date().getFullYear(); width: 80 }
                        Text { text: "年" }
                        SpinBox { id: adminStartMonth; from: 1; to: 12; value: new Date().getMonth() + 1; width: 60 }
                        Text { text: "月" }
                        SpinBox { id: adminStartDay; from: 1; to: 31; value: new Date().getDate(); width: 60 }
                        Text { text: "日  至" }
                        SpinBox { id: adminEndYear; from: 2020; to: 2100; value: new Date().getFullYear(); width: 80 }
                        Text { text: "年" }
                        SpinBox { id: adminEndMonth; from: 1; to: 12; value: new Date().getMonth() + 1; width: 60 }
                        Text { text: "月" }
                        SpinBox { id: adminEndDay; from: 1; to: 31; value: new Date().getDate(); width: 60 }
                        Text { text: "日" }
                        Button {
                            text: "生成报表"
                            highlighted: true
                            onClicked: {
                                function pad2(n) { return n < 10 ? "0" + n : "" + n }
                                var startYear = adminStartYear.value
                                var startMonth = pad2(adminStartMonth.value)
                                var startDay = pad2(adminStartDay.value)
                                var start = startYear + "-" + startMonth + "-" + startDay + "T00:00:00Z"
                                
                                var endYear = adminEndYear.value
                                var endMonth = pad2(adminEndMonth.value)
                                var endDay = pad2(adminEndDay.value)
                                var end = endYear + "-" + endMonth + "-" + endDay + "T23:59:59Z"
                                
                                if (start && end) {
                                    apiClient.getOccupancyAnalysis(start, end)
                                }
                            }
                        }
                    }

                    // 财务概览卡片
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 20
                        
                        Repeater {
                            model: incomeModel
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 80
                                color: "#f5f5f5"
                                radius: 8
                                border.color: "#e0e0e0"
                                ColumnLayout {
                                    anchors.centerIn: parent
                                    Text { text: model.title; font.pixelSize: 14; color: "#666" }
                                    Text { text: model.value; font.pixelSize: 20; font.bold: true; color: "#333" }
                                }
                            }
                        }
                    }
                    ListModel { id: incomeModel }

                    // 图表区域
                    GridLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        columns: 2
                        columnSpacing: 20
                        rowSpacing: 20

                        // 图表1：整体占用情况（饼图）
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 400
                            border.color: "#e0e0e0"
                            radius: 5
                            visible: userType === "lot_admin"

                            ChartView {
                                id: occupancyPieChart
                                anchors.fill: parent
                                title: "车位占用状态概览"
                                antialiasing: true
                                legend.alignment: Qt.AlignBottom

                                PieSeries {
                                    id: occupancySeries
                                }
                            }
                        }

                        // 图表2：按车位类型统计（柱状图）
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 400
                            border.color: "#e0e0e0"
                            radius: 5
                            visible: userType === "lot_admin"

                            ChartView {
                                id: typeBarChart
                                anchors.fill: parent
                                title: "各类型车位使用详情"
                                antialiasing: true
                                legend.alignment: Qt.AlignBottom

                                BarSeries {
                                    id: typeBarSeries
                                    axisX: BarCategoryAxis { id: typeAxisX }
                                    axisY: ValueAxis { id: typeAxisY; min: 0; tickCount: 5; labelFormat: "%.0f" }
                                    
                                    BarSet { id: setTotal; label: "总数"; color: "#2196F3" }
                                    BarSet { id: setOccupied; label: "已占用"; color: "#F44336" }
                                }
                            }
                        }
                    }
                }
            }
        }

        // 4. Violation Analysis（优化：图表化）
        ScrollView {
            visible: userType === "lot_admin"
            contentHeight: 700
            Item {
                width: parent.width
                height: 700
                anchors.margins: 20
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    Text { text: "违规行为分析"; font.pixelSize: 20; font.bold: true }

                    RowLayout {
                        Text { text: "统计周期:" }
                        SpinBox { id: yearSpinBox; from: 2020; to: 2030; value: new Date().getFullYear() }
                        Text { text: "年" }
                        SpinBox { id: monthSpinBox; from: 1; to: 12; value: new Date().getMonth() + 1 }
                        Text { text: "月" }
                        Button {
                            text: "查询数据"
                            highlighted: true
                            onClicked: {
                                apiClient.getViolationAnalysis(yearSpinBox.value, monthSpinBox.value)
                            }
                        }
                    }
                    
                    // 摘要文字
                    Text {
                        id: violationSummaryText
                        text: "暂无数据"
                        font.pixelSize: 16
                        color: "#555"
                    }

                    // 图表区域
                    GridLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        columns: 2
                        columnSpacing: 20

                        // 图表1：违规类型分布
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 400
                            border.color: "#e0e0e0"
                            radius: 5
                            visible: userType === "lot_admin"

                            ChartView {
                                id: violationTypeChart
                                anchors.fill: parent
                                title: "违规类型分布"
                                antialiasing: true
                                legend.alignment: Qt.AlignRight

                                PieSeries {
                                    id: violationTypeSeries
                                    holeSize: 0.35
                                }
                            }
                        }

                        // 图表2：违规处理状态
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 400
                            border.color: "#e0e0e0"
                            radius: 5
                            visible: userType === "lot_admin"

                            ChartView {
                                id: violationStatusChart
                                anchors.fill: parent
                                title: "违规处理状态"
                                antialiasing: true
                                legend.alignment: Qt.AlignRight

                                PieSeries {
                                    id: violationStatusSeries
                                    holeSize: 0.35
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // 模型定义
    ListModel { id: parkingLotModel }
    ListModel { id: spaceModel }

    Component.onCompleted: {
        console.log("AdminMainPage loaded, userType:", userType, "userId:", userId)
        // 确保userType已正确设置
        if (!userType || userType === "") {
            console.log("Warning: userType is empty, cannot proceed")
            return
        }
        
        // 设置TabBar的currentIndex
        if (userType === "lot_admin") {
            tabBar.currentIndex = 1
        } else {
            tabBar.currentIndex = 0
        }
        
        // 加载数据
        if (userType === "system_admin") {
            apiClient.getParkingLots()
        }
    }

    Connections {
        target: apiClient

        function onParkingLotsReceived(lots) {
            try {
                parkingLotModel.clear()
                if (lots && Array.isArray(lots)) {
                    for (var i = 0; i < lots.length; i++) {
                        var cleanLot = sanitizeLot(lots[i])
                        if (cleanLot) {
                            parkingLotModel.append(cleanLot)
                        }
                    }
                }
                // 只在system_admin时处理pending spaces
                if (userType === "system_admin") {
                    handlePendingSpaces()
                }
            } catch (e) {
                console.log("Error in onParkingLotsReceived:", e)
            }
        }

        function onRequestFinished(response) {
            if (response.hasOwnProperty("error")) {
                console.log("Error:", response.error)
                return
            }
            var url = response.url || ""
            if (url.indexOf("/api/v2/addparkinglot") >= 0 || url.indexOf("/api/v2/deleteparkinglot/") >= 0) {
                apiClient.getParkingLots()
            } else if (url.indexOf("/admin/occupancy") >= 0) {
                updateOccupancyCharts(response.data || response)
            } else if (url.indexOf("/admin/violations") >= 0) {
                updateViolationCharts(response.data || response)
            }
        }

        // ------------------ 数据处理逻辑更新 ------------------

        function updateOccupancyCharts(data) {
            if (!data || typeof data !== 'object') return

            // 1. 更新顶部财务卡片
            incomeModel.clear()
            incomeModel.append({ "title": "总收入", "value": "¥" + (parseFloat(data.total_income) || 0).toFixed(2) })
            incomeModel.append({ "title": "日均收入", "value": "¥" + (parseFloat(data.avg_daily_income) || 0).toFixed(2) })
            incomeModel.append({ "title": "平均使用率", "value": (parseFloat(data.occupancy_rate) || 0).toFixed(2) + "%" })
            incomeModel.append({ "title": "平均停车时长", "value": (parseFloat(data.avg_parking_hours) || 0).toFixed(1) + "h" })

            // 2. 更新饼图（整体状态）
            try {
                if (occupancySeries) {
                    occupancySeries.clear()
                    var occ = Number(data.occupied_spaces || 0)
                    var res = Number(data.reserved_spaces || 0)
                    var avail = Number(data.available_spaces || 0)
                    
                    if (occ + res + avail === 0) {
                        occupancySeries.append("暂无数据", 1)
                    } else {
                        var s1 = occupancySeries.append("已占用 (" + occ + ")", occ)
                        s1.color = "#FF5252"
                        s1.exploded = true
                        var s2 = occupancySeries.append("已预订 (" + res + ")", res)
                        s2.color = "#FFC107"
                        var s3 = occupancySeries.append("空闲 (" + avail + ")", avail)
                        s3.color = "#4CAF50"
                    }
                }
            } catch (e) {
                console.log("Error updating occupancy chart:", e)
            }

            // 3. 更新柱状图（分类统计）
            try {
                if (setTotal) setTotal.clear()
                if (setOccupied) setOccupied.clear()
                if (typeAxisX) typeAxisX.categories = []
            } catch (e) {
                console.log("Error clearing bar chart:", e)
            }

            var maxVal = 0
            if (Array.isArray(data.occupancy)) {
                var categories = []
                for (var i = 0; i < data.occupancy.length; i++) {
                    var item = data.occupancy[i]
                    var cat = item.space_type || "未知"
                    var t = Number(item.total || 0)
                    var o = Number(item.occupied || 0)
                    categories.push(cat)
                    if (setTotal) setTotal.append(t)
                    if (setOccupied) setOccupied.append(o)
                    if (t > maxVal) maxVal = t
                }
                if (typeAxisX) typeAxisX.categories = categories
            }
            if (typeAxisY) typeAxisY.max = maxVal > 0 ? maxVal * 1.2 : 10
        }

        function updateViolationCharts(data) {
            if (!data || typeof data !== 'object') return

            // 1. 更新摘要文本
            var summary = "总违规次数: " + (data.total_violations || 0) + 
                          " | 罚款总额: ¥" + (parseFloat(data.total_fines) || 0).toFixed(2)
            violationSummaryText.text = summary

            // 2. 更新类型饼图
            try {
                if (violationTypeSeries) {
                    violationTypeSeries.clear()
                    if (Array.isArray(data.violations_by_type) && data.violations_by_type.length > 0) {
                        for (var i = 0; i < data.violations_by_type.length; i++) {
                            var tItem = data.violations_by_type[i]
                            var count = Number(tItem.count || 0)
                            violationTypeSeries.append((tItem.violation_type || "未知") + ": " + count, count)
                        }
                    } else {
                        violationTypeSeries.append("无数据", 1)
                    }
                }
            } catch (e) {
                console.log("Error updating violation type chart:", e)
            }

            // 3. 更新状态饼图
            try {
                if (violationStatusSeries) {
                    violationStatusSeries.clear()
                    if (Array.isArray(data.violations_by_status) && data.violations_by_status.length > 0) {
                        for (var k = 0; k < data.violations_by_status.length; k++) {
                            var sItem = data.violations_by_status[k]
                            var name = sItem.status === 1 ? "已处理" : "未处理"
                            var cnt = Number(sItem.count || 0)
                            var slice = violationStatusSeries.append(name + ": " + cnt, cnt)
                            if (sItem.status === 1) slice.color = "#4CAF50"
                            else slice.color = "#FF5252"
                        }
                    } else {
                        violationStatusSeries.append("无数据", 1)
                    }
                }
            } catch (e) {
                console.log("Error updating violation status chart:", e)
            }
        }

        function formatDateTime(y, m, d, isEnd) {
            if (!y || !m || !d) return ""
            function pad2(n) { return n < 10 ? "0" + n : "" + n }
            var timePart = isEnd ? "23:59:59" : "00:00:00"
            return y.value + "-" + pad2(m.value) + "-" + pad2(d.value) + "T" + timePart + "Z"
        }

        function sanitizeLot(lot) {
            if (!lot || typeof lot !== "object") return null
            var lotId = lot.lot_id !== undefined ? lot.lot_id :
                        (lot.lotId !== undefined ? lot.lotId :
                        (lot.LotID !== undefined ? lot.LotID : 0))
            return {
                lotId: lotId, lot_id: lotId,
                name: lot.name || lot.Name || "",
                address: lot.address || lot.Address || "",
                totalLevels: lot.total_levels || lot.totalLevels || 1,
                totalSpaces: lot.total_spaces || lot.totalSpaces || 0,
                hourlyRate: lot.hourly_rate || lot.hourlyRate || 0,
                status: lot.status !== undefined ? lot.status : 1,
                description: lot.description || lot.Description || ""
            }
        }

        function handlePendingSpaces() {
            try {
                if (!addLotDialog) {
                    console.log("Warning: addLotDialog is not available")
                    return
                }
                if (addLotDialog.pendingNormalSpaces > 0 || addLotDialog.pendingChargingSpaces > 0) {
                    var newLotId = 0
                    if (parkingLotModel && parkingLotModel.count > 0) {
                        var lastLot = parkingLotModel.get(parkingLotModel.count - 1)
                        if (lastLot) {
                            newLotId = lastLot.lot_id !== undefined ? lastLot.lot_id : (lastLot.lotId || 0)
                        }
                    }
                    if (newLotId > 0) {
                        var totalPending = addLotDialog.pendingNormalSpaces + addLotDialog.pendingChargingSpaces
                        var levels = addLotDialog.pendingLevels || 1
                        var normal = addLotDialog.pendingNormalSpaces
                        
                        if (normal > 0 && levels > 0) {
                            for (var n = 1; n <= normal; n++) {
                                var lvl = Math.floor((n - 1) / (normal / levels)) + 1
                                if (lvl > levels) lvl = levels
                                if (lvl < 1) lvl = 1
                                apiClient.addParkingSpace(newLotId, lvl, "N" + (n<10?"0":"")+n, "普通", 1)
                            }
                        }
                        if (addLotDialog.pendingChargingSpaces > 0 && levels > 0) {
                            for (var c = 1; c <= addLotDialog.pendingChargingSpaces; c++) {
                                var lvl2 = Math.floor((c - 1) / (addLotDialog.pendingChargingSpaces / levels)) + 1
                                if (lvl2 > levels) lvl2 = levels
                                if (lvl2 < 1) lvl2 = 1
                                apiClient.addParkingSpace(newLotId, lvl2, "C" + (c<10?"0":"")+c, "充电桩", 1)
                            }
                        }
                        addLotDialog.pendingNormalSpaces = 0
                        addLotDialog.pendingChargingSpaces = 0
                    }
                }
            } catch (e) {
                console.log("Error in handlePendingSpaces:", e)
            }
        }
    }

    // 弹窗组件保持不变
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
        property int pendingNormalSpaces: 0
        property int pendingChargingSpaces: 0
        property int pendingLevels: 1

        onAccepted: {
            var name = lotName.trim(); var address = lotAddress.trim()
            var levels = parseInt(lotLevels) || 1; var spaces = parseInt(lotSpaces) || 0
            var rate = parseFloat(lotRate) || 0; var desc = lotDesc.trim()
            var nSpaces = parseInt(normalSpacesField.text) || 0
            var cSpaces = parseInt(chargingSpacesField.text) || 0

            if (name.length === 0 || address.length === 0) return
            if (nSpaces + cSpaces !== spaces) return // 简单验证

            apiClient.addParkingLot(name, address, levels, spaces, rate, 1, desc)
            addLotDialog.pendingNormalSpaces = nSpaces
            addLotDialog.pendingChargingSpaces = cSpaces
            addLotDialog.pendingLevels = levels
        }

        contentItem: ColumnLayout {
            anchors.margins: 20
            spacing: 10
            TextField { id: lotNameField; Layout.fillWidth: true; placeholderText: "停车场名称" }
            TextField { id: lotAddressField; Layout.fillWidth: true; placeholderText: "停车场地址" }
            TextField { id: levelsField; Layout.fillWidth: true; placeholderText: "总楼层数"; inputMethodHints: Qt.ImhDigitsOnly }
            TextField { id: spacesField; Layout.fillWidth: true; placeholderText: "总车位数"; inputMethodHints: Qt.ImhDigitsOnly }
            TextField { id: rateField; Layout.fillWidth: true; placeholderText: "小时费率" }
            TextField { id: descField; Layout.fillWidth: true; placeholderText: "说明（可选）" }
            Text { text: "车位配置"; font.bold: true }
            TextField { id: normalSpacesField; Layout.fillWidth: true; placeholderText: "普通车位数"; inputMethodHints: Qt.ImhDigitsOnly }
            TextField { id: chargingSpacesField; Layout.fillWidth: true; placeholderText: "充电桩车位数"; inputMethodHints: Qt.ImhDigitsOnly }
        }
    }

    Dialog {
        id: deleteLotDialog
        modal: true
        title: "删除停车场"
        standardButtons: Dialog.Ok | Dialog.Cancel
        property int lotId: 0
        property string lotName: ""
        onAccepted: if (lotId > 0) apiClient.deleteParkingLot(lotId)
        contentItem: ColumnLayout {
            anchors.margins: 20
            spacing: 10
            Text { text: "确定要删除停车场 \"" + deleteLotDialog.lotName + "\" 吗？"; Layout.fillWidth: true; wrapMode: Text.Wrap }
            Text { text: "警告：删除停车场将同时删除所有关联的车位数据！"; color: "red"; Layout.fillWidth: true; wrapMode: Text.Wrap }
        }
    }

    header: ToolBar {
        RowLayout {
            anchors.fill: parent
            Text { text: "智能停车系统 - 管理员中心"; font.pixelSize: 18 }
            Item { Layout.fillWidth: true }
            Button { text: "退出登录"; onClicked: logout() }
        }
    }
}