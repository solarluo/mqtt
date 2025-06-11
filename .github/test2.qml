// main.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Controls.Material 2.15
ApplicationWindow {
    id: window
    width: 900
    height: 700
    visible: true
    title: "MQTT 客户端"
    color: "#f0f0f0"
    Material.theme: Material.light
    Material.accent: Material.Teal
    // 连接状态显示
    Rectangle {
        id: statusBar
        width: parent.width
        height: 40
        color: {
            if (!mqttClient) return "#FFC107"; // 初始化 - 黄色
            if (mqttClient.status === "Connected") return "#4CAF50";
            if (mqttClient.status.includes("Error")) return "#F44336";
            if (mqttClient.status === "Connecting...") return "#2196F3";
            if (mqttClient.status === "Disconnecting...") return "#FF9800";
            return "#FFC107";
        }

        Text {
            anchors.centerIn: parent
            text: mqttClient.status
            font.bold: true
            font.pixelSize: 16
            color: "white"
        }
    }

    // 主内容区域
    SplitView {
        anchors.top: statusBar.bottom
        anchors.bottom: parent.bottom
        width: parent.width
        orientation: Qt.Horizontal

        // 左侧面板 - 连接和发布
        Rectangle {
            id: leftPanel
            SplitView.preferredWidth: 300
            color: "#e8e8e8"
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                // 连接设置
                GroupBox {
                    title: "连接设置"
                    Layout.fillWidth: true

                    GridLayout {
                        columns: 2
                        anchors.fill: parent

                        Label { text: "网址:" }
                        TextField {
                            id: hostField
                            Layout.fillWidth: true
                            placeholderText: "broker.emqx.io"
                            text: "broker.emqx.io"
                        }

                        Label { text: "端口:" }
                        TextField {
                            id: portField
                            Layout.fillWidth: true
                            placeholderText: "1883"
                            text: "1883"
                            validator: IntValidator { bottom: 1; top: 65535 }
                        }

                        Label { text: "用户名:" }
                        TextField {
                            id: usernameField
                            Layout.fillWidth: true
                            placeholderText: "(你的账号)"
                        }

                        Label { text: "密码:" }
                        TextField {
                            id: passwordField
                            Layout.fillWidth: true
                            placeholderText: "(密码)"
                            echoMode: TextInput.PasswordEchoOnEdit

                        }

                        // 遗嘱设置按钮
                        Button {
                            Layout.columnSpan: 2
                            Layout.fillWidth: true
                            text: "Set Last Will & Testament"
                            onClicked: lastWillDialog.open()
                        }

                        Button {
                            id: connectBtn
                            Layout.columnSpan: 2
                            Layout.fillWidth: true
                            text: "连接"
                            onClicked: {
                                mqttClient.connectToBroker(
                                    hostField.text,
                                    portField.text,
                                    usernameField.text,
                                    passwordField.text
                                )
                            }
                        }

                        Button {
                            id: disconnectBtn
                            Layout.columnSpan: 2
                            Layout.fillWidth: true
                            text: "Disconnect"
                            enabled: mqttClient.status === "Connected"
                            onClicked: mqttClient.disconnectFromBroker()
                        }
                    }
                }
//没写断开
                // 订阅主题
                GroupBox {
                    title: "Subscribe to Topic"
                    Layout.fillWidth: true
                    enabled: mqttClient && mqttClient.status === "Connected"
                    ColumnLayout {
                        anchors.fill: parent

                        TextField {
                            id: subscribeTopic
                            Layout.fillWidth: true
                            placeholderText: "要订阅的主题"
                            text: "myhome/livingroom/temperature"
                        }

                        RowLayout {
                            Label { text: "QoS:" }
                            RadioButton {
                                id: subQos0
                                text: "0"
                                checked: true
                                property int qos: 0
                            }
                            RadioButton {
                                id: subQos1
                                text: "1"
                                property int qos: 1
                            }
                            RadioButton {
                                id: subQos2
                                text: "2"
                                property int qos: 2
                            }
                        }

                        Button {
                            Layout.fillWidth: true
                            text: "订阅"
                            enabled: mqttClient.status === "Connected"
                            onClicked: {
                                var qos = subQos0.checked ? 0 : (subQos1.checked ? 1 : 2);
                                mqttClient.subscribe(subscribeTopic.text, qos)
                            }
                        }
                    }
                }

                // 发布消息
              /*  GroupBox {
                    title: "发布消息"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    enabled: mqttClient && mqttClient.status === "connected"
                    ColumnLayout {
                        anchors.fill: parent

                        TextField {
                            id: publishTopic
                            Layout.fillWidth: true
                            placeholderText: "主题"
                            text: "myhome/livingroom/temperature"
                        }

                        TextArea {
                            id: publishMessage
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            placeholderText: "消息内容"
                            text: '{"value": 23.5, "unit": "C"}'
                        }

                        RowLayout {
                            Label { text: "QoS:" }
                            RadioButton {
                                id: pubQos0
                                text: "0"
                                checked: true
                                property int qos: 0
                            }
                            RadioButton {
                                id: pubQos1
                                text: "1"
                                property int qos: 1
                            }
                            RadioButton {
                                id: pubQos2
                                text: "2"
                                property int qos: 2
                            }

                            CheckBox {
                                id: retainCheck
                                text: "Retain"
                            }
                        }

                        Button {
                            Layout.fillWidth: true
                            text: "发布"
                            enabled: mqttClient.status === "Connected"
                            Material.background: Material.Blue
                            Material.foreground: "white"
                            onClicked: {
                                var qos = pubQos0.checked ? 0 : (pubQos1.checked ? 1 : 2);
                                mqttClient.publish(
                                    publishTopic.text,
                                    publishMessage.text,
                                    qos,
                                    retainCheck.checked
                                )
                            }
                        }
                    }
                }*/
            }
        }
        Rectangle{

            SplitView.fillWidth: true
            GroupBox {
                title: "发布消息"
                Layout.fillWidth: true
                Layout.fillHeight: true
                enabled: mqttClient && mqttClient.status === "Connected"
                ColumnLayout {
                    anchors.fill: parent

                    TextField {
                        id: publishTopic
                        Layout.fillWidth: true
                        placeholderText: "主题"
                        text: "myhome/livingroom/temperature"
                    }

                    TextArea {
                        id: publishMessage
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        placeholderText: "消息内容"
                        text: '{"value": 23.5, "unit": "C"}'
                    }

                    RowLayout {
                        Label { text: "QoS:" }
                        RadioButton {
                            id: pubQos0
                            text: "0"
                            checked: true
                            property int qos: 0
                        }
                        RadioButton {
                            id: pubQos1
                            text: "1"
                            property int qos: 1
                        }
                        RadioButton {
                            id: pubQos2
                            text: "2"
                            property int qos: 2
                        }

                        CheckBox {
                            id: retainCheck
                            text: "Retain"
                        }
                    }

                    Button {
                        Layout.fillWidth: true
                        text: "发布"
                        enabled: mqttClient.status === "Connected"
                        Material.background: Material.Blue
                        Material.foreground: "white"
                        onClicked: {
                            var qos = pubQos0.checked ? 0 : (pubQos1.checked ? 1 : 2);
                            mqttClient.publish(
                                publishTopic.text,
                                publishMessage.text,
                                qos,
                                retainCheck.checked
                            )
                        }
                    }
                }
            }}
        // 右侧面板 - 接收的消息
        Rectangle {
            id: rightPanel
            SplitView.fillHeight:true

            color: "#ccfafa"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                RowLayout {
                    Label {
                        text: "收到的消息"
                        font.bold: true
                        font.pixelSize: 16
                    }

                    Button {
                        text: "Clear"
                        onClicked: mqttClient.clearMessages()
                    }

                    Item { Layout.fillWidth: true }
                }

                ListView {


                    id: messageView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: mqttClient.receivedMessages
                    clip: true
                    spacing: 10
                    delegate: Rectangle {
                        width: messageView.width
                        height: messageColumn.height + 20
                        color: index % 2 === 0 ? "#ffffff" : "#f0f0f0"
                        border.color: "#dddddd"
                        radius: 5

                        ColumnLayout {
                            id: messageColumn
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 10
                            spacing: 5

                            RowLayout {
                                Layout.fillWidth: true
                                Label {
                                    text: "Topic: " + modelData.topic
                                    font.bold: true
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                                Label {
                                    text: "QoS: " + modelData.qos
                                }
                                Label {
                                    text: "Retained: " + modelData.retained
                                }
                            }

                            Label {
                                text: "Received: " + modelData.timestamp
                                color: "#666"
                                font.pixelSize: 12
                            }

                            TextArea {
                                text: modelData.payload
                                readOnly: true
                                wrapMode: Text.Wrap
                                Layout.fillWidth: true
                                background: null
                                padding: 0
                                selectByMouse: true
                                font.family: "Courier New"
                            }
                        }
                    }
                }
            }
        }
    }

    // 遗嘱设置对话框
    Dialog {
        id: lastWillDialog
        title: "Set Last Will & Testament"
        anchors.centerIn: parent
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel

        GridLayout {
            columns: 2
            width: 400

            Label { text: "Topic:" }
            TextField {
                id: willTopic
                Layout.fillWidth: true
                placeholderText: "Enter will topic"
                text: "myhome/client/status"
            }

            Label { text: "Message:" }
            TextField {
                id: willMessage
                Layout.fillWidth: true
                placeholderText: "Enter will message"
                text: "offline"
            }

            Label { text: "QoS:" }
            RowLayout {
                RadioButton {
                    id: willQos0
                    text: "0"
                    checked: true
                    property int qos: 0
                }
                RadioButton {
                    id: willQos1
                    text: "1"
                    property int qos: 1
                }
                RadioButton {
                    id: willQos2
                    text: "2"
                    property int qos: 2
                }
            }

            Label { text: "Retain:" }
            CheckBox {
                id: willRetain
                checked: true
            }
        }

        onAccepted: {
            var qos = willQos0.checked ? 0 : (willQos1.checked ? 1 : 2);
            mqttClient.setLastWill(
                willTopic.text,
                willMessage.text,
                qos,
                willRetain.checked
            )
        }
    }

    // 连接错误提示
    Connections {
        target: mqttClient
        function onConnectionFailed(message) {
            errorDialog.text = message
            errorDialog.open()
        }
    }

    // 错误对话框
    Dialog {
        id: errorDialog
        title: "Connection Error"
        anchors.centerIn: parent
        modal: true
        standardButtons: Dialog.Ok
        property alias text: errorLabel.text

        Label {
            id: errorLabel
            width: 300
            wrapMode: Text.Wrap
        }
    }
}
