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

                        // 图表1：整体占用情况（饼状图）
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
            console.log("updateOccupancyCharts called with data:", JSON.stringify(data))
            if (!data || typeof data !== 'object') {
                console.log("Invalid data in updateOccupancyCharts")
                return
            }

            // 1. 更新顶部财务卡片
            incomeModel.clear()
            incomeModel.append({ "title": "总收入", "value": "¥" + (parseFloat(data.total_income) || 0).toFixed(2) })
            incomeModel.append({ "title": "日均收入", "value": "¥" + (parseFloat(data.avg_daily_income) || 0).toFixed(2) })
            incomeModel.append({ "title": "平均使用率", "value": (parseFloat(data.occupancy_rate) || 0).toFixed(2) + "%" })
            incomeModel.append({ "title": "平均停车时长", "value": (parseFloat(data.avg_parking_hours) || 0).toFixed(1) + "h" })

            // 2. 更新饼状图（整体占用状态）
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
                console.log("Error updating occupancy pie chart:", e)
            }

            // 3. 更新柱状图（分类统计：只显示普通和充电两种类型）
            try {
                console.log("Updating bar chart, data.occupancy:", JSON.stringify(data.occupancy))
                console.log("Full data object keys:", Object.keys(data))
                
                var maxVal = 0
                var categories = []
                var normalTotal = 0
                var normalOccupied = 0
                var chargingTotal = 0
                var chargingOccupied = 0
                
                // 先清空现有数据（BarSet使用remove方法，从后往前删除）
                if (setTotal) {
                    while (setTotal.count > 0) {
                        setTotal.remove(setTotal.count - 1)
                    }
                }
                if (setOccupied) {
                    while (setOccupied.count > 0) {
                        setOccupied.remove(setOccupied.count - 1)
                    }
                }
                
                // 清空categories
                if (typeAxisX) {
                    typeAxisX.categories = []
                }
                
                if (Array.isArray(data.occupancy) && data.occupancy.length > 0) {
                    // 只统计普通和充电两种类型
                    for (var i = 0; i < data.occupancy.length; i++) {
                        var item = data.occupancy[i]
                        var spaceType = item.space_type || ""
                        var t = Number(item.total || 0)
                        var o = Number(item.occupied || 0)
                        
                        console.log("Processing occupancy item:", spaceType, "total:", t, "occupied:", o)
                        
                        if (spaceType === "普通") {
                            normalTotal = t
                            normalOccupied = o
                        } else if (spaceType === "充电") {
                            chargingTotal = t
                            chargingOccupied = o
                        }
                    }
                } else {
                    // 如果后端没有返回occupancy数组，尝试从total_spaces计算
                    console.log("occupancy array not found or empty, trying to calculate from total_spaces")
                    var totalSpaces = Number(data.total_spaces || 0)
                    var occupiedSpaces = Number(data.occupied_spaces || 0)
                    
                    // 简单估算：假设普通车位占80%，充电车位占20%
                    normalTotal = Math.floor(totalSpaces * 0.8)
                    chargingTotal = totalSpaces - normalTotal
                    normalOccupied = Math.floor(occupiedSpaces * 0.8)
                    chargingOccupied = occupiedSpaces - normalOccupied
                    
                    console.log("Estimated - Normal:", normalTotal, normalOccupied, "Charging:", chargingTotal, chargingOccupied)
                }
                
                // 确保显示普通和充电两种类型（即使数据为0）
                categories = ["普通", "充电"]
                console.log("Bar chart data - Normal:", normalTotal, normalOccupied, "Charging:", chargingTotal, chargingOccupied)
                
                // 设置categories（必须在append之前）
                if (typeAxisX) {
                    typeAxisX.categories = categories
                }
                
                // 追加数据
                if (setTotal) {
                    setTotal.append(normalTotal)
                    setTotal.append(chargingTotal)
                }
                if (setOccupied) {
                    setOccupied.append(normalOccupied)
                    setOccupied.append(chargingOccupied)
                }
                
                maxVal = Math.max(normalTotal, chargingTotal, normalOccupied, chargingOccupied, 1)
                if (typeAxisY) {
                    typeAxisY.max = maxVal > 0 ? maxVal * 1.2 : 10
                    typeAxisY.min = 0
                }
                
                console.log("Bar chart updated successfully, setTotal.count:", setTotal ? setTotal.count : "N/A", "setOccupied.count:", setOccupied ? setOccupied.count : "N/A")
            } catch (e) {
                console.log("Error updating bar chart:", e, e.stack)
            }
        }

        function updateViolationCharts(data) {
            console.log("updateViolationCharts called with data:", JSON.stringify(data))
            if (!data || typeof data !== 'object') {
                console.log("Invalid data in updateViolationCharts")
                return
            }

            // 1. 更新摘要文本
            var summary = "总违规次数: " + (data.total_violations || 0) + 
                          " | 罚款总额: ¥" + (parseFloat(data.total_fines) || 0).toFixed(2)
            violationSummaryText.text = summary

            // 2. 更新类型饼图（显示三种类型：超时停车、预订未使用、未支付停车费）
            try {
                console.log("Updating violation type chart, data.violations_by_type:", JSON.stringify(data.violations_by_type))
                
                if (violationTypeSeries) {
                    violationTypeSeries.clear()
                    
                    // 定义三种违规类型及其颜色
                    var typeColors = {
                        "超时停车": "#FF5252",
                        "预订未使用": "#FFC107",
                        "未支付停车费": "#FF9800"
                    }
                    
                    // 构建类型统计map
                    var typeMap = {
                        "超时停车": 0,
                        "预订未使用": 0,
                        "未支付停车费": 0
                    }
                    
                    if (Array.isArray(data.violations_by_type) && data.violations_by_type.length > 0) {
                        for (var i = 0; i < data.violations_by_type.length; i++) {
                            var tItem = data.violations_by_type[i]
                            var vType = tItem.violation_type || ""
                            var count = Number(tItem.count || 0)
                            if (typeMap.hasOwnProperty(vType)) {
                                typeMap[vType] = count
                            }
                        }
                    }
                    
                    // 确保显示三种类型（即使值为0，使用最小值0.01来显示）
                    var requiredTypes = ["超时停车", "预订未使用", "未支付停车费"]
                    var totalCount = typeMap["超时停车"] + typeMap["预订未使用"] + typeMap["未支付停车费"]
                    
                    for (var k = 0; k < requiredTypes.length; k++) {
                        var vType = requiredTypes[k]
                        var count = typeMap[vType] || 0
                        // 如果值为0且总数为0，使用0.01来显示（避免饼图不显示）
                        var displayValue = (count === 0 && totalCount === 0) ? 0.01 : count
                        var label = vType + (count > 0 ? (": " + count) : ": 0")
                        var slice = violationTypeSeries.append(label, displayValue)
                        if (typeColors[vType]) {
                            slice.color = typeColors[vType]
                        }
                        console.log("Added violation type slice:", vType, "count:", count, "displayValue:", displayValue)
                    }
                }
            } catch (e) {
                console.log("Error updating violation type chart:", e, e.stack)
            }

            // 3. 更新状态饼图（显示两种状态：处理、未处理）
            try {
                console.log("Updating violation status chart, data.violations_by_status:", JSON.stringify(data.violations_by_status))
                
                if (violationStatusSeries) {
                    violationStatusSeries.clear()
                    
                    // 构建状态统计map
                    var statusMap = {
                        "处理": 0,
                        "未处理": 0
                    }
                    
                    if (Array.isArray(data.violations_by_status) && data.violations_by_status.length > 0) {
                        for (var k = 0; k < data.violations_by_status.length; k++) {
                            var sItem = data.violations_by_status[k]
                            var cnt = Number(sItem.count || 0)
                            // 注意：status可能是数字或字符串
                            var status = sItem.status
                            if (status === 1 || status === "1") {
                                statusMap["处理"] = cnt
                            } else {
                                statusMap["未处理"] = cnt
                            }
                        }
                    }
                    
                    // 确保显示两种状态（即使为0，使用最小值0.01来显示）
                    var processedCount = statusMap["处理"] || 0
                    var unprocessedCount = statusMap["未处理"] || 0
                    var totalStatusCount = processedCount + unprocessedCount
                    
                    // 如果值为0且总数为0，使用0.01来显示（避免饼图不显示）
                    var processedValue = (processedCount === 0 && totalStatusCount === 0) ? 0.01 : processedCount
                    var unprocessedValue = (unprocessedCount === 0 && totalStatusCount === 0) ? 0.01 : unprocessedCount
                    
                    var processedLabel = "处理" + (processedCount > 0 ? (": " + processedCount) : ": 0")
                    var unprocessedLabel = "未处理" + (unprocessedCount > 0 ? (": " + unprocessedCount) : ": 0")
                    
                    var processedSlice = violationStatusSeries.append(processedLabel, processedValue)
                    processedSlice.color = "#4CAF50"
                    
                    var unprocessedSlice = violationStatusSeries.append(unprocessedLabel, unprocessedValue)
                    unprocessedSlice.color = "#FF5252"
                    
                    console.log("Added violation status slices - Processed:", processedCount, "Unprocessed:", unprocessedCount)
                }
            } catch (e) {
                console.log("Error updating violation status chart:", e, e.stack)
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