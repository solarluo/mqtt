# main.py
import sys
import json
import paho.mqtt.client as mqtt
from datetime import datetime
from PySide6.QtCore import QObject, Slot, Signal, Property
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine


class MQTTClient(QObject):
    def __init__(self, parent=None):
        super().__init__(parent)
        self._status = "未连接"
        self._receivedMessages = []
        self._lastWillTopic = ""
        self._lastWillMessage = ""
        self._lastWillQos = 0
        self._lastWillRetain = False

        # 使用最新的回调API版本
        self._client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
        self._client.on_connect = self.on_connect
        self._client.on_message = self.on_message
        self._client.on_disconnect = self.on_disconnect

    # 信号定义
    statusChanged = Signal(str)
    messageReceived = Signal()
    connectionFailed = Signal(str)

    # 状态属性
    @Property(str, notify=statusChanged)
    def status(self):
        return self._status

    @status.setter
    def status(self, value):
        if self._status != value:
            self._status = value
            self.statusChanged.emit(value)

    # 接收到的消息列表
    @Property('QVariantList', notify=messageReceived)
    def receivedMessages(self):
        return self._receivedMessages

    # MQTT 连接回调
    def on_connect(self, client, userdata, flags, reason_code, properties):
        if reason_code == 0:
            self.status = "Connected"
        else:
            self.status = f"Connection failed ({reason_code})"
            self.connectionFailed.emit(f"Connection failed with code {reason_code}")

    # MQTT 消息接收回调
    def on_message(self, client, userdata, message):
        try:
            payload = message.payload.decode("utf-8")
            # 尝试解析JSON格式
            try:
                payload_obj = json.loads(payload)
                formatted_payload = json.dumps(payload_obj, indent=2)
            except:
                formatted_payload = payload

            # 获取当前时间
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

            message_info = {
                "topic": message.topic,
                "payload": formatted_payload,
                "qos": str(message.qos),
                "retained": "Yes" if message.retain else "No",
                "timestamp": timestamp
            }
            self._receivedMessages.insert(0, message_info)
            self.messageReceived.emit()
        except Exception as e:
            print(f"Error processing message: {e}")

    # MQTT 断开连接回调
    def on_disconnect(self, client, userdata, disconnect_flags, reason_code, properties):
        self.status = "Disconnected"


    # 设置遗嘱消息
    @Slot(str, str, int, bool)
    def setLastWill(self, topic, message, qos, retain):
        self._lastWillTopic = topic
        self._lastWillMessage = message
        self._lastWillQos = qos
        self._lastWillRetain = retain
        # 调用will_set设置遗嘱
        self._client.will_set(topic, message, qos, retain)

    # 连接到MQTT代理
    @Slot(str, int, str, str)
    def connectToBroker(self, host, port, username, password):
        try:
            self.status = "Connecting..."
            port = int(port)

            # 注意：遗嘱已经在setLastWill方法中设置，这里不需要再次设置

            if username and password:
                self._client.username_pw_set(username, password)

            self._client.connect(host, port, 60)
            self._client.loop_start()
        except Exception as e:
            self.status = f"Error: {str(e)}"
            self.connectionFailed.emit(str(e))

    # 断开MQTT连接
    @Slot()
    def disconnectFromBroker(self):
        # 先停止网络循环
        self._client.loop_stop()
        # 然后断开连接
        self._client.disconnect()
        # 注意：断开连接是异步的，实际状态会在on_disconnect回调中更新
        self.status = "Disconnecting..."

    # 订阅主题
    @Slot(str, int)
    def subscribe(self, topic, qos):
        if self._status == "Connected":
            result, mid = self._client.subscribe(topic, qos)
            if result == mqtt.MQTT_ERR_SUCCESS:
                print(f"Subscribed to {topic} with QoS {qos}")
            else:
                print(f"Subscription failed: {result}")

    # 发布消息
    @Slot(str, str, int, bool)
    def publish(self, topic, message, qos, retain):
        if self._status == "Connected":
            self._client.publish(topic, message, qos, retain)

    # 清空消息列表
    @Slot()
    def clearMessages(self):
        self._receivedMessages.clear()
        self.messageReceived.emit()


if __name__ == "__main__":
    app = QGuiApplication(sys.argv)

    # 创建MQTT客户端实例
    mqtt_client = MQTTClient()

    # 设置QML引擎
    engine = QQmlApplicationEngine()

    # 将Python对象暴露给QML
    engine.rootContext().setContextProperty("mqttClient", mqtt_client)

    # 加载QML文件
    engine.load("main.qml")

    if not engine.rootObjects():
        sys.exit(-1)
    print("进入主循环...")
    sys.exit(app.exec())
