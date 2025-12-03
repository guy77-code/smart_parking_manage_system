import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
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
                            TextField {
                                id: startTimeField
                                Layout.fillWidth: true
                                placeholderText: "2025-01-01T00:00:00Z"
                            }
                            Text { text: "结束时间:" }
                            TextField {
                                id: endTimeField
                                Layout.fillWidth: true
                                placeholderText: "2025-01-31T23:59:59Z"
                            }
                            Button {
                                text: "查询"
                                onClicked: {
                                    if (authManager.userType !== "lot_admin") {
                                        occupancyDataText = "当前登录为系统管理员账号，车位使用率分析仅支持停车场管理员。"
                                        return
                                    }
                                    // 允许输入日期或完整时间，自动转换为RFC3339
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
}

