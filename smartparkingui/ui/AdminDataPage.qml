import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtCharts 2.15
import SmartParking 1.0

Page {
    id: adminDataPage
    title: "数据分析"

    property int lotId: 0
    // 用于返回管理员主页面
    property var stackView: null

    // 显示数据的文本
    property string occupancyDataText: "使用率分析结果将显示在这里"
    property string violationDataText: "违规分析结果将显示在这里"
    property string reportDataText: "报表内容将显示在这里"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // 返回管理员主页面按钮
        RowLayout {
            Layout.fillWidth: true
            Button {
                text: "返回管理员主页"
                onClicked: {
                    if (stackView) {
                        stackView.pop()
                    } else {
                        console.log("stackView is null, cannot pop AdminDataPage")
                    }
                }
            }
            Item { Layout.fillWidth: true }
        }

        TabBar {
            id: tabBar
            Layout.fillWidth: true

            TabButton { text: "使用率分析" }
            TabButton { text: "违规分析" }
            TabButton { text: "报表生成" }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabBar.currentIndex

            // 使用率分析
            ScrollView {
                Item {
                    anchors.fill: parent
                    anchors.margins: 20

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 20

                        Text {
                            text: "车位使用率分析"
                            font.pixelSize: 20
                            font.bold: true
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "开始时间:" }
                            SpinBox { id: startYear; from: 2020; to: 2100; value: new Date().getFullYear() }
                            SpinBox { id: startMonth; from: 1; to: 12; value: new Date().getMonth() + 1 }
                            SpinBox { id: startDay; from: 1; to: 31; value: new Date().getDate() }
                            Text { text: "结束时间:" }
                            SpinBox { id: endYear; from: 2020; to: 2100; value: new Date().getFullYear() }
                            SpinBox { id: endMonth; from: 1; to: 12; value: new Date().getMonth() + 1 }
                            SpinBox { id: endDay; from: 1; to: 31; value: new Date().getDate() }
                            Button {
                                text: "查询"
                                onClicked: {
                                    if (authManager.userType !== "lot_admin") {
                                        occupancyDataText = "当前登录为系统管理员账号，车位使用率分析仅支持停车场管理员。"
                                        return
                                    }
                                    var start = formatDateTime(startYear, startMonth, startDay, false)
                                    var end = formatDateTime(endYear, endMonth, endDay, true)
                                    if (start && end) {
                                        apiClient.getOccupancyAnalysis(start, end)
                                    } else {
                                        occupancyDataText = "请填写开始时间和结束时间"
                                    }
                                }
                            }
                        }

                        ScrollView {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 400
                            
                            Rectangle {
                                width: parent.width
                                height: Math.max(occupancyTable.height + 20, 400)
                                border.color: "gray"
                                border.width: 1
                                radius: 5
                                
                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 10
                                    
                                    Text {
                                        text: occupancyDataText.indexOf("使用率分析结果") >= 0 ? occupancyDataText : "车位使用率分析结果"
                                        color: occupancyDataText.indexOf("使用率分析结果") >= 0 ? "gray" : "black"
                                        visible: occupancyTable.count === 0
                                    }
                                    
                                    ListView {
                                        id: occupancyTable
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        model: occupancyModel
                                        delegate: Rectangle {
                                            width: ListView.view.width
                                            height: 60
                                            border.color: "lightgray"
                                            border.width: 1
                                            radius: 3
                                            
                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.margins: 10
                                                spacing: 10
                                                
                                                Text {
                                                    Layout.preferredWidth: 100
                                                    text: model.label || ""
                                                    font.bold: true
                                                }
                                                Text {
                                                    Layout.fillWidth: true
                                                    text: model.value || ""
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // 使用率图表（饼图）
                        ChartView {
                            id: occupancyChart
                            Layout.fillWidth: true
                            Layout.preferredHeight: 300
                            antialiasing: true
                            title: "车位使用率分布"
                            legend.alignment: Qt.AlignBottom
                            visible: occupancyPie.count > 0

                            PieSeries {
                                id: occupancyPie
                            }
                        }
                        
                        ListModel {
                            id: occupancyModel
                        }
                    }
                }
            }

            // 违规分析
            ScrollView {
                Item {
                    anchors.fill: parent
                    anchors.margins: 20

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 20

                        Text {
                            text: "违规行为分析"
                            font.pixelSize: 20
                            font.bold: true
                        }

                        RowLayout {
                            Layout.fillWidth: true
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
                                    if (authManager.userType !== "lot_admin") {
                                        violationDataText = "当前登录为系统管理员账号，违规分析仅支持停车场管理员。"
                                        return
                                    }
                                    apiClient.getViolationAnalysis(yearSpinBox.value, monthSpinBox.value)
                                }
                            }
                        }

                        ScrollView {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 400
                            
                            Rectangle {
                                width: parent.width
                                height: Math.max(violationTable.height + 20, 400)
                                border.color: "gray"
                                border.width: 1
                                radius: 5
                                
                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 10
                                    
                                    Text {
                                        text: violationDataText.indexOf("违规分析结果") >= 0 ? violationDataText : "违规行为分析结果"
                                        color: violationDataText.indexOf("违规分析结果") >= 0 ? "gray" : "black"
                                        visible: violationTable.count === 0
                                    }
                                    
                                    ListView {
                                        id: violationTable
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        model: violationModel
                                        delegate: Rectangle {
                                            width: ListView.view.width
                                            height: 60
                                            border.color: "lightgray"
                                            border.width: 1
                                            radius: 3
                                            
                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.margins: 10
                                                spacing: 10
                                                
                                                Text {
                                                    Layout.preferredWidth: 150
                                                    text: model.label || ""
                                                    font.bold: true
                                                }
                                                Text {
                                                    Layout.fillWidth: true
                                                    text: model.value || ""
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // 违规类型分布图（饼图）
                        ChartView {
                            id: violationTypeChart
                            Layout.fillWidth: true
                            Layout.preferredHeight: 280
                            antialiasing: true
                            title: "违规类型分布"
                            legend.alignment: Qt.AlignBottom
                            visible: violationTypePie.count > 0

                            PieSeries {
                                id: violationTypePie
                            }
                        }

                        // 违规状态分布图（饼图）
                        ChartView {
                            id: violationStatusChart
                            Layout.fillWidth: true
                            Layout.preferredHeight: 240
                            antialiasing: true
                            title: "违规状态分布"
                            legend.alignment: Qt.AlignBottom
                            visible: violationStatusPie.count > 0

                            PieSeries {
                                id: violationStatusPie
                            }
                        }
                        
                        ListModel {
                            id: violationModel
                        }
                    }
                }
            }

            // 报表生成
            ScrollView {
                Item {
                    anchors.fill: parent
                    anchors.margins: 20

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 20

                        Text {
                            text: "报表生成"
                            font.pixelSize: 20
                            font.bold: true
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "报表类型:" }
                            ComboBox {
                                id: reportTypeComboBox
                                model: ["monthly", "annual"]
                            }
                            Text { text: "年份:" }
                            SpinBox {
                                id: reportYearSpinBox
                                from: 2020
                                to: 2030
                                value: new Date().getFullYear()
                            }
                            Text {
                                text: "月份:"
                                visible: reportTypeComboBox.currentText === "monthly"
                            }
                            SpinBox {
                                id: reportMonthSpinBox
                                from: 1
                                to: 12
                                value: new Date().getMonth() + 1
                                visible: reportTypeComboBox.currentText === "monthly"
                            }
                            Button {
                                text: "生成报表"
                                onClicked: {
                                    if (authManager.userType !== "lot_admin") {
                                        reportDataText = "当前登录为系统管理员账号，报表生成仅支持停车场管理员。"
                                        return
                                    }
                                    var month = reportTypeComboBox.currentText === "monthly" ? reportMonthSpinBox.value : 0
                                    apiClient.generateReport(reportTypeComboBox.currentText, reportYearSpinBox.value, month)
                                }
                            }
                        }

                        ScrollView {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 400
                            
                            Rectangle {
                                width: parent.width
                                height: Math.max(reportTable.height + 20, 400)
                                border.color: "gray"
                                border.width: 1
                                radius: 5
                                
                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 10
                                    
                                    Text {
                                        text: reportDataText.indexOf("报表内容") >= 0 ? reportDataText : "报表内容"
                                        color: reportDataText.indexOf("报表内容") >= 0 ? "gray" : "black"
                                        visible: reportTable.count === 0
                                    }
                                    
                                    ListView {
                                        id: reportTable
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        model: reportModel
                                        delegate: Rectangle {
                                            width: ListView.view.width
                                            height: 60
                                            border.color: "lightgray"
                                            border.width: 1
                                            radius: 3
                                            
                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.margins: 10
                                                spacing: 10
                                                
                                                Text {
                                                    Layout.preferredWidth: 150
                                                    text: model.label || ""
                                                    font.bold: true
                                                }
                                                Text {
                                                    Layout.fillWidth: true
                                                    text: model.value || ""
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        ListModel {
                            id: reportModel
                        }
                    }
                }
            }
        }
    }

    // 将年月日 SpinBox 组合转换为 RFC3339 字符串（起始/结束日）
    function formatDateTime(y, m, d, isEnd) {
        if (!y || !m || !d)
            return ""
        function pad2(n) { return n < 10 ? "0" + n : "" + n }
        var year = y.value
        var month = pad2(m.value)
        var day = pad2(d.value)
        var timePart = isEnd ? "23:59:59" : "00:00:00"
        return year + "-" + month + "-" + day + "T" + timePart + "Z"
    }

    Connections {
        target: apiClient

        function onRequestFinished(response) {
            if (response.hasOwnProperty("error")) {
                console.log("Error:", response.error)
                var url = response.url || ""
                if (url.indexOf("/admin/occupancy") >= 0) {
                    occupancyDataText = "查询失败: " + (response.error || "未知错误")
                } else if (url.indexOf("/admin/violations") >= 0) {
                    violationDataText = "查询失败: " + (response.error || "未知错误")
                } else if (url.indexOf("/admin/report") >= 0) {
                    reportDataText = "生成报表失败: " + (response.error || "未知错误")
                }
                return
            }

            var url = response.url || ""
            
            if (url.indexOf("/admin/occupancy") >= 0) {
                // 车位使用率分析
                occupancyModel.clear()
                var data = response.data || {}
                
                if (data.total_spaces !== undefined) {
                    occupancyModel.append({label: "总车位数", value: data.total_spaces})
                }
                if (data.occupied_spaces !== undefined) {
                    occupancyModel.append({label: "已占用车位数", value: data.occupied_spaces})
                }
                if (data.reserved_spaces !== undefined) {
                    occupancyModel.append({label: "已预订车位数", value: data.reserved_spaces})
                }
                if (data.occupancy_rate !== undefined) {
                    occupancyModel.append({label: "使用率", value: (data.occupancy_rate.toFixed(2) + "%")})
                }
                if (data.total_income !== undefined) {
                    occupancyModel.append({label: "总收入", value: "¥" + data.total_income.toFixed(2)})
                }
                if (data.avg_daily_income !== undefined) {
                    occupancyModel.append({label: "平均日收入", value: "¥" + data.avg_daily_income.toFixed(2)})
                }
                if (data.avg_parking_hours !== undefined) {
                    occupancyModel.append({label: "平均停车时长", value: data.avg_parking_hours.toFixed(2) + "小时"})
                }
                
                if (occupancyModel.count === 0) {
                    occupancyDataText = "使用率分析结果将显示在这里"
                } else {
                    occupancyDataText = ""
                }

                updateOccupancyChart(data)
            } else if (url.indexOf("/admin/violations") >= 0) {
                // 违规行为分析
                violationModel.clear()
                var vData = response.data || {}
                
                if (vData.total_violations !== undefined) {
                    violationModel.append({label: "总违规次数", value: vData.total_violations})
                }
                if (vData.total_fines !== undefined) {
                    violationModel.append({label: "罚款总额", value: "¥" + vData.total_fines.toFixed(2)})
                }
                if (vData.collected_fines !== undefined) {
                    violationModel.append({label: "已收罚款", value: "¥" + vData.collected_fines.toFixed(2)})
                }
                
                // 违规类型统计
                if (vData.violations_by_type && Array.isArray(vData.violations_by_type)) {
                    violationModel.append({label: "---", value: "---"})
                    violationModel.append({label: "违规类型统计", value: ""})
                    for (var i = 0; i < vData.violations_by_type.length; i++) {
                        var vt = vData.violations_by_type[i]
                        violationModel.append({
                            label: "  " + (vt.violation_type || ""),
                            value: vt.count || 0
                        })
                    }
                }
                
                // 违规状态统计
                if (vData.violations_by_status && Array.isArray(vData.violations_by_status)) {
                    violationModel.append({label: "---", value: "---"})
                    violationModel.append({label: "违规状态统计", value: ""})
                    for (var j = 0; j < vData.violations_by_status.length; j++) {
                        var vs = vData.violations_by_status[j]
                        var statusText = vs.status === 0 ? "未处理" : "已处理"
                        violationModel.append({
                            label: "  " + statusText,
                            value: vs.count || 0
                        })
                    }
                }
                
                if (violationModel.count === 0) {
                    violationDataText = "违规分析结果将显示在这里"
                } else {
                    violationDataText = ""
                }

                updateViolationCharts(vData)
            } else if (url.indexOf("/admin/report") >= 0) {
                // 报表生成
                reportModel.clear()
                var reportData = response.report || response.data || {}
                
                if (reportData.report_type) {
                    reportModel.append({label: "报表类型", value: reportData.report_type === "monthly" ? "月度报表" : "年度报表"})
                }
                if (reportData.period) {
                    reportModel.append({label: "统计周期", value: reportData.period})
                }
                if (reportData.generated_at) {
                    reportModel.append({label: "生成时间", value: reportData.generated_at})
                }
                
                // 停车统计
                if (reportData.parking_statistics) {
                    reportModel.append({label: "---", value: "---"})
                    reportModel.append({label: "停车统计", value: ""})
                    var ps = reportData.parking_statistics
                    if (ps.total_parking_records !== undefined) {
                        reportModel.append({label: "  总停车记录", value: ps.total_parking_records})
                    }
                    if (ps.total_revenue !== undefined) {
                        reportModel.append({label: "  总收入", value: "¥" + ps.total_revenue.toFixed(2)})
                    }
                }
                
                // 违规统计
                if (reportData.violation_statistics) {
                    reportModel.append({label: "---", value: "---"})
                    reportModel.append({label: "违规统计", value: ""})
                    var vs = reportData.violation_statistics
                    if (vs.total_violations !== undefined) {
                        reportModel.append({label: "  总违规次数", value: vs.total_violations})
                    }
                    if (vs.total_fines !== undefined) {
                        reportModel.append({label: "  罚款总额", value: "¥" + vs.total_fines.toFixed(2)})
                    }
                }
                
                // 收入统计
                if (reportData.revenue_statistics) {
                    reportModel.append({label: "---", value: "---"})
                    reportModel.append({label: "收入统计", value: ""})
                    var rs = reportData.revenue_statistics
                    if (rs.total_revenue !== undefined) {
                        reportModel.append({label: "  总收入", value: "¥" + rs.total_revenue.toFixed(2)})
                    }
                    if (rs.avg_daily_revenue !== undefined) {
                        reportModel.append({label: "  平均日收入", value: "¥" + rs.avg_daily_revenue.toFixed(2)})
                    }
                }
                
                if (reportModel.count === 0) {
                    reportDataText = "报表内容将显示在这里"
                } else {
                    reportDataText = ""
                }
            }
        }
    }

    // 更新车位使用率饼图
    function updateOccupancyChart(data) {
        occupancyPie.clear()
        var hasData = false

        function appendSlice(label, value) {
            if (value !== undefined && value !== null && !isNaN(value) && Number(value) >= 0) {
                occupancyPie.append(label, Number(value))
                hasData = true
            }
        }

        appendSlice("已占用", data.occupied_spaces)
        appendSlice("已预订", data.reserved_spaces)
        // 剩余车位 = 总车位 - 已占用 - 已预订（若可计算）
        if (data.total_spaces !== undefined && data.occupied_spaces !== undefined && data.reserved_spaces !== undefined) {
            var remaining = Number(data.total_spaces) - Number(data.occupied_spaces) - Number(data.reserved_spaces)
            if (!isNaN(remaining) && remaining >= 0) {
                appendSlice("空闲", remaining)
            }
        }

        occupancyChart.visible = hasData
    }

    // 更新违规分析饼图
    function updateViolationCharts(vData) {
        violationTypePie.clear()
        violationStatusPie.clear()

        var hasType = false
        var hasStatus = false

        if (vData.violations_by_type && Array.isArray(vData.violations_by_type)) {
            for (var i = 0; i < vData.violations_by_type.length; i++) {
                var vt = vData.violations_by_type[i]
                if (vt && vt.violation_type !== undefined && vt.count !== undefined && !isNaN(vt.count)) {
                    violationTypePie.append(vt.violation_type, Number(vt.count))
                    hasType = true
                }
            }
        }

        if (vData.violations_by_status && Array.isArray(vData.violations_by_status)) {
            for (var j = 0; j < vData.violations_by_status.length; j++) {
                var vs = vData.violations_by_status[j]
                if (vs && vs.status !== undefined && vs.count !== undefined && !isNaN(vs.count)) {
                    var statusText = vs.status === 0 ? "未处理" : "已处理"
                    violationStatusPie.append(statusText, Number(vs.count))
                    hasStatus = true
                }
            }
        }

        violationTypeChart.visible = hasType
        violationStatusChart.visible = hasStatus
    }
}

