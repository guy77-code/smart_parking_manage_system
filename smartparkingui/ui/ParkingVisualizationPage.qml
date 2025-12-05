import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import SmartParking 1.0

Page {
    id: parkingVisualizationPage
    title: "车位可视化"

    property var stackView: null
    property int lotId: 0
    property int currentLevel: 1
    property int maxLevel: 1
    property bool isAdmin: false  // 是否为管理员模式，可以编辑车位
    
    onLotIdChanged: {
        if (lotId > 0) {
            // 当 lotId 改变时，重新加载停车场信息和车位数据
            apiClient.getParkingLotById(lotId)
            apiClient.getParkingSpaces(lotId)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // 管理按钮（管理员模式下不显示返回按钮）
        RowLayout {
            Layout.fillWidth: true
            Button {
                text: "返回"
                visible: !isAdmin  // 管理员模式下隐藏返回按钮
                onClicked: {
                    if (stackView) {
                        stackView.pop()
                    } else {
                        console.log("stackView is null, cannot pop ParkingVisualizationPage")
                    }
                }
            }
            Item { Layout.fillWidth: true }
            Button {
                text: "添加车位"
                visible: isAdmin
                onClicked: addSpaceDialog.open()
            }
            Button {
                text: "刷新"
                onClicked: {
                    if (lotId > 0) {
                        apiClient.getParkingSpaces(lotId)
                    }
                }
            }
        }

        // Level selector
        RowLayout {
            Layout.fillWidth: true
            Text { text: "楼层:" }
            SpinBox {
                id: levelSpinBox
                from: 1
                to: maxLevel
                value: currentLevel
                onValueChanged: {
                    currentLevel = value
                    filterSpacesByLevel()
                }
            }
            Item { Layout.fillWidth: true }
        }

        // Legend
        RowLayout {
            Layout.fillWidth: true
            Rectangle {
                width: 30
                height: 30
                color: "green"
                border.color: "black"
            }
            Text { text: "可用" }
            Rectangle {
                width: 30
                height: 30
                color: "red"
                border.color: "black"
            }
            Text { text: "占用" }
            Rectangle {
                width: 30
                height: 30
                color: "blue"
                border.color: "black"
            }
            Text { text: "已预订" }
            Rectangle {
                width: 30
                height: 30
                color: "yellow"
                border.color: "black"
            }
            Text { text: "禁用" }
        }

        // Parking spaces grid
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            GridLayout {
                id: spaceGrid
                columns: 10
                width: parent.width

                Repeater {
                    model: spaceModel
                    delegate: Rectangle {
                        width: 100
                        height: 100
                        color: getSpaceColor(model.status, model.isOccupied, model.isReserved)
                        border.color: "black"
                        border.width: 2
                        radius: 5

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2
                            Text {
                                text: {
                                    var num = model.spaceNumber || model.space_number || ""
                                    return num || "未知"
                                }
                                font.pixelSize: 14
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                            }
                            Text {
                                text: {
                                    var type = model.spaceType || model.space_type || "普通"
                                    return type || "普通"
                                }
                                font.pixelSize: 11
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (isAdmin) {
                                    // 管理员模式：显示编辑对话框
                                    var spaceId = model.spaceId !== undefined ? model.spaceId : (model.space_id !== undefined ? model.space_id : 0)
                                    var spaceNumber = model.spaceNumber || model.space_number || ""
                                    var spaceType = model.spaceType || model.space_type || "普通"
                                    var status = model.status !== undefined ? model.status : 1
                                    var isOccupied = model.isOccupied !== undefined ? model.isOccupied : (model.is_occupied !== undefined ? model.is_occupied : 0)
                                    var isReserved = model.isReserved !== undefined ? model.isReserved : (model.is_reserved !== undefined ? model.is_reserved : 0)
                                    
                                    editSpaceDialog.spaceId = spaceId
                                    editSpaceDialog.spaceNumber = spaceNumber
                                    editSpaceDialog.spaceType = spaceType
                                    editSpaceDialog.currentStatus = status
                                    editSpaceDialog.currentIsOccupied = isOccupied
                                    editSpaceDialog.currentIsReserved = isReserved
                                    editSpaceDialog.open()
                                } else {
                                    // 普通用户模式：显示车位详情
                                    var num = model.spaceNumber || model.space_number || ""
                                    console.log("Space clicked:", num)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    ListModel {
        id: spaceModel
    }

    ListModel {
        id: allSpacesModel  // 存储所有楼层的车位数据
    }

    function getSpaceColor(status, isOccupied, isReserved) {
        if (status === 0) return "yellow"  // Disabled
        if (isOccupied === 1) return "red"  // Occupied
        if (isReserved === 1) return "blue"  // Reserved
        return "green"  // Available
    }

    function sanitizeSpace(space) {
        if (!space || typeof space !== "object")
            return null

        var spaceId = space.space_id !== undefined ? space.space_id :
                      (space.spaceId !== undefined ? space.spaceId :
                      (space.SpaceID !== undefined ? space.SpaceID : 0))
        return {
            spaceId: spaceId,
            space_id: spaceId,
            level: space.level !== undefined ? space.level :
                   (space.Level !== undefined ? space.Level : 1),
            spaceNumber: space.space_number !== undefined ? space.space_number :
                         (space.spaceNumber !== undefined ? space.spaceNumber : ""),
            spaceType: space.space_type !== undefined ? space.space_type :
                       (space.spaceType !== undefined ? space.spaceType : "普通"),
            status: space.status !== undefined ? space.status : 1,
            isOccupied: space.is_occupied !== undefined ? space.is_occupied :
                        (space.isOccupied !== undefined ? space.isOccupied : 0),
            isReserved: space.is_reserved !== undefined ? space.is_reserved :
                        (space.isReserved !== undefined ? space.isReserved : 0),
            lotId: space.lot_id !== undefined ? space.lot_id :
                   (space.lotId !== undefined ? space.lotId : 0)
        }
    }

    function filterSpacesByLevel() {
        spaceModel.clear()
        for (var i = 0; i < allSpacesModel.count; i++) {
            var space = allSpacesModel.get(i)
            var spaceLevel = space.level !== undefined ? space.level : (space.Level !== undefined ? space.Level : 1)
            if (spaceLevel === currentLevel || spaceLevel === currentLevel.toString() || parseInt(spaceLevel) === currentLevel) {
                spaceModel.append(space)
            }
        }
    }

    Component.onCompleted: {
        if (lotId > 0) {
            // 先获取停车场信息以获取最大楼层数
            apiClient.getParkingLotById(lotId)
            // 然后获取车位数据
            apiClient.getParkingSpaces(lotId)
        }
    }

    Connections {
        target: apiClient

        function onRequestFinished(response) {
            if (response.hasOwnProperty("error")) {
                console.log("Error:", response.error)
                return
            }

            var url = response.url || ""
            
            // 处理停车场信息响应（获取最大楼层数）
            if (url.indexOf("/api/v2/getparkinglot/") >= 0) {
                var lotData = response.data || response
                if (lotData.total_levels !== undefined) {
                    maxLevel = lotData.total_levels
                    levelSpinBox.to = maxLevel
                } else if (lotData.totalLevels !== undefined) {
                    maxLevel = lotData.totalLevels
                    levelSpinBox.to = maxLevel
                }
            }
            
            // 处理车位数据响应
            if (url.indexOf("/parking/lots/") >= 0 && url.indexOf("/spaces") >= 0) {
                var spaces = response.data || response
                if (Array.isArray(spaces)) {
                    allSpacesModel.clear()
                    for (var i = 0; i < spaces.length; i++) {
                        var space = sanitizeSpace(spaces[i])
                        if (space) {
                            allSpacesModel.append(space)
                        }
                    }
                    filterSpacesByLevel()
                } else if (response.hasOwnProperty("data") && Array.isArray(response.data)) {
                    allSpacesModel.clear()
                    for (var j = 0; j < response.data.length; j++) {
                        var space2 = sanitizeSpace(response.data[j])
                        if (space2) {
                            allSpacesModel.append(space2)
                        }
                    }
                    filterSpacesByLevel()
                }
            }
            
            // 处理车位添加/更新响应
            if (url.indexOf("/addparkingspace") >= 0 || url.indexOf("/updatespacestatus/") >= 0) {
                // 刷新车位列表
                if (lotId > 0) {
                    apiClient.getParkingSpaces(lotId)
                }
            }
        }
    }

    // 添加车位对话框
    Dialog {
        id: addSpaceDialog
        modal: true
        title: "添加车位"
        standardButtons: Dialog.Ok | Dialog.Cancel
        width: 400

        property alias spaceNumber: spaceNumberField.text
        property alias spaceType: spaceTypeComboBox.currentText
        property alias spaceLevel: spaceLevelSpinBox.value

        onAccepted: {
            var number = spaceNumber.trim()
            var type = spaceType
            var level = spaceLevel

            if (number.length === 0) {
                console.log("车位编号不能为空")
                return
            }

            apiClient.addParkingSpace(lotId, level, number, type, 1)
            addSpaceDialog.close()
        }

        contentItem: ColumnLayout {
            anchors.margins: 20
            spacing: 10

            Text { text: "车位编号:" }
            TextField {
                id: spaceNumberField
                Layout.fillWidth: true
                placeholderText: "例如: A-001"
            }
            
            Text { text: "车位类型:" }
            ComboBox {
                id: spaceTypeComboBox
                Layout.fillWidth: true
                model: ["普通", "充电桩", "残疾人", "VIP"]
                currentIndex: 0
            }
            
            Text { text: "楼层:" }
            SpinBox {
                id: spaceLevelSpinBox
                from: 1
                to: maxLevel
                value: currentLevel
            }
        }
    }

    // 编辑车位对话框
    Dialog {
        id: editSpaceDialog
        modal: true
        title: "编辑车位"
        standardButtons: Dialog.Ok | Dialog.Cancel | Dialog.Apply
        width: 400

        property int spaceId: 0
        property string spaceNumber: ""
        property string spaceType: ""
        property int currentStatus: 1
        property int currentIsOccupied: 0
        property int currentIsReserved: 0

        onAccepted: {
            // 保存更改
            var status = statusComboBox.currentIndex === 0 ? 1 : 0
            var isOccupied = isOccupiedComboBox.currentIndex === 0 ? 0 : 1
            var isReserved = isReservedComboBox.currentIndex === 0 ? 0 : 1
            
            apiClient.updateParkingSpaceStatus(spaceId, status, isOccupied, isReserved)
            editSpaceDialog.close()
        }

        onApplied: {
            // 删除车位（实际是设置为禁用状态）
            apiClient.deleteParkingSpace(spaceId)
            editSpaceDialog.close()
        }

        contentItem: ColumnLayout {
            anchors.margins: 20
            spacing: 10

            Text { 
                text: "车位编号: " + editSpaceDialog.spaceNumber
                font.bold: true
            }
            
            Text { text: "车位类型: " + editSpaceDialog.spaceType }
            
            Text { text: "状态:" }
            ComboBox {
                id: statusComboBox
                Layout.fillWidth: true
                model: ["可用", "禁用"]
                currentIndex: editSpaceDialog.currentStatus === 0 ? 1 : 0
            }
            
            Text { text: "占用状态:" }
            ComboBox {
                id: isOccupiedComboBox
                Layout.fillWidth: true
                model: ["未占用", "已占用"]
                currentIndex: editSpaceDialog.currentIsOccupied
            }
            
            Text { text: "预订状态:" }
            ComboBox {
                id: isReservedComboBox
                Layout.fillWidth: true
                model: ["未预订", "已预订"]
                currentIndex: editSpaceDialog.currentIsReserved
            }
        }
    }
}
