package app.arduino.esp32.controller.com

import android.app.Activity
import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothClass
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.util.Locale
import java.util.UUID

class MainActivity : FlutterActivity() {
    private val CHANNEL_NAME = "app.arduino.esp32.controller.com/bluetooth"
    private val SPP_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

    private var channel: MethodChannel? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    private val bluetoothAdapter: BluetoothAdapter? by lazy {
        val bluetoothManager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        bluetoothManager?.adapter ?: BluetoothAdapter.getDefaultAdapter()
    }

    private var discoveryReceiver: BroadcastReceiver? = null
    private val discoveredDevices = mutableListOf<Map<String, Any>>()

    private var activeSocket: BluetoothSocket? = null
    private var outputStream: OutputStream? = null
    private var inputStream: InputStream? = null
    private var readThread: Thread? = null
    @Volatile private var isConnected = false

    private var speechRecognizer: SpeechRecognizer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        channel?.setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            when (call.method) {
                "isBluetoothAvailable" -> {
                    result.success(bluetoothAdapter != null)
                }
                "isBluetoothEnabled" -> {
                    result.success(bluetoothAdapter?.isEnabled == true)
                }
                "requestEnableBluetooth" -> {
                    requestEnableBluetooth(result)
                }
                "requestPermissions" -> {
                    requestBluetoothPermissions()
                    result.success(true)
                }
                "getBondedDevices" -> {
                    val devices = getBondedDevices()
                    result.success(devices)
                }
                "startDiscovery" -> {
                    startDiscovery(result)
                }
                "stopDiscovery" -> {
                    stopDiscovery()
                    result.success(true)
                }
                "connect" -> {
                    val address = call.argument<String>("address")
                    val pin = call.argument<String>("pin")
                    if (address.isNullOrEmpty()) {
                        result.error("INVALID_ARG", "Device address is required", null)
                    } else {
                        connectToDevice(address, pin, result)
                    }
                }
                "disconnect" -> {
                    disconnectInternal()
                    result.success(true)
                }
                "sendData" -> {
                    val data = call.argument<String>("data") ?: ""
                    sendData(data, result)
                }
                "startSpeechRecognition" -> {
                    startSpeechRecognition(result)
                }
                "stopSpeechRecognition" -> {
                    stopSpeechRecognition(result)
                }
                "startGoogleVoiceDialog" -> {
                    startGoogleVoiceDialog(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        registerBluetoothStateReceiver()
    }

    private fun hasBluetoothPermissions(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED &&
            ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED
        } else {
            ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH) == PackageManager.PERMISSION_GRANTED &&
            ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun requestBluetoothPermissions() {
        val permsList = mutableListOf<String>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            permsList.add(Manifest.permission.BLUETOOTH_CONNECT)
            permsList.add(Manifest.permission.BLUETOOTH_SCAN)
        } else {
            permsList.add(Manifest.permission.BLUETOOTH)
            permsList.add(Manifest.permission.BLUETOOTH_ADMIN)
            permsList.add(Manifest.permission.ACCESS_FINE_LOCATION)
            permsList.add(Manifest.permission.ACCESS_COARSE_LOCATION)
        }
        permsList.add(Manifest.permission.RECORD_AUDIO)
        ActivityCompat.requestPermissions(this, permsList.toTypedArray(), 1001)
    }

    private fun isRelevantBluetoothDevice(dev: BluetoothDevice): Boolean {
        val name = dev.name?.lowercase() ?: ""
        // Always include devices with hardware/controller keywords
        if (name.contains("hc-") || name.contains("hc0") || 
            name.contains("esp") || name.contains("arduino") || 
            name.contains("serial") || name.contains("robot") || 
            name.contains("car") || name.contains("controller") || 
            name.contains("spp") || name.contains("uart") || 
            name.contains("ble") || name.contains("diy")) {
            return true
        }

        // Filter out non-serial devices: headphones, earbuds, car audio, smartwatches, and other phones
        val major = dev.bluetoothClass?.majorDeviceClass
        if (major == BluetoothClass.Device.Major.AUDIO_VIDEO ||
            major == BluetoothClass.Device.Major.WEARABLE ||
            major == BluetoothClass.Device.Major.PHONE) {
            return false
        }
        return true
    }

    private fun getBondedDevices(): List<Map<String, Any>> {
        if (!hasBluetoothPermissions()) {
            requestBluetoothPermissions()
            return emptyList()
        }
        val devices = mutableListOf<Map<String, Any>>()
        try {
            bluetoothAdapter?.bondedDevices?.forEach { dev ->
                if (isRelevantBluetoothDevice(dev)) {
                    val name = if (!dev.name.isNullOrBlank()) dev.name else "Arduino BT (${dev.address.takeLast(5)})"
                    devices.add(
                        mapOf(
                            "name" to name,
                            "address" to dev.address,
                            "isPaired" to true,
                            "rssi" to -55
                        )
                    )
                }
            }
        } catch (e: SecurityException) {
            e.printStackTrace()
        }
        return devices
    }

    private fun startDiscovery(result: MethodChannel.Result) {
        if (!hasBluetoothPermissions()) {
            requestBluetoothPermissions()
            result.error("PERMISSION_DENIED", "Bluetooth permission not granted", null)
            return
        }
        try {
            discoveredDevices.clear()
            // 1. Immediately emit all relevant bonded/paired devices to Flutter!
            bluetoothAdapter?.bondedDevices?.forEach { dev ->
                if (isRelevantBluetoothDevice(dev)) {
                    val name = if (!dev.name.isNullOrBlank()) dev.name else "Arduino BT (${dev.address.takeLast(5)})"
                    val devMap = mapOf(
                        "name" to name,
                        "address" to dev.address,
                        "isPaired" to true,
                        "rssi" to -55
                    )
                    discoveredDevices.add(devMap)
                    mainHandler.post {
                        channel?.invokeMethod("onDeviceDiscovered", devMap)
                    }
                }
            }

            discoveryReceiver?.let {
                try { unregisterReceiver(it) } catch (_: Exception) {}
            }

            discoveryReceiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {
                    when (intent?.action) {
                        BluetoothDevice.ACTION_FOUND -> {
                            val device: BluetoothDevice? =
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                    intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
                                } else {
                                    @Suppress("DEPRECATION")
                                    intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                                }
                            val rssi = intent.getShortExtra(BluetoothDevice.EXTRA_RSSI, Short.MIN_VALUE).toInt()
                            device?.let { d ->
                                if (isRelevantBluetoothDevice(d)) {
                                    val addr = d.address
                                    if (discoveredDevices.none { it["address"] == addr }) {
                                        val name = if (!d.name.isNullOrBlank()) d.name else "BT Device (${addr.takeLast(5)})"
                                        val devMap = mapOf(
                                            "name" to name,
                                            "address" to addr,
                                            "isPaired" to (d.bondState == BluetoothDevice.BOND_BONDED),
                                            "rssi" to rssi
                                        )
                                        discoveredDevices.add(devMap)
                                        mainHandler.post {
                                            channel?.invokeMethod("onDeviceDiscovered", devMap)
                                        }
                                    }
                                }
                            }
                        }
                        BluetoothAdapter.ACTION_DISCOVERY_FINISHED -> {
                            mainHandler.post {
                                channel?.invokeMethod("onDiscoveryFinished", null)
                            }
                        }
                    }
                }
            }

            val filter = IntentFilter().apply {
                addAction(BluetoothDevice.ACTION_FOUND)
                addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED)
            }
            registerReceiver(discoveryReceiver, filter)

            bluetoothAdapter?.cancelDiscovery()
            bluetoothAdapter?.startDiscovery()
            result.success(true)
        } catch (e: Exception) {
            result.error("DISCOVERY_ERROR", e.message, null)
        }
    }

    private fun stopDiscovery() {
        try {
            bluetoothAdapter?.cancelDiscovery()
            discoveryReceiver?.let {
                try { unregisterReceiver(it) } catch (_: Exception) {}
                discoveryReceiver = null
            }
        } catch (_: Exception) {}
    }

    private fun connectToDevice(address: String, pin: String?, result: MethodChannel.Result) {
        if (!hasBluetoothPermissions()) {
            requestBluetoothPermissions()
            result.error("PERMISSION_DENIED", "Bluetooth permission not granted", null)
            return
        }

        Thread {
            var socket: BluetoothSocket? = null
            var pairingReceiver: BroadcastReceiver? = null
            try {
                // Settle Bluetooth hardware by cancelling any ongoing discovery
                try {
                    bluetoothAdapter?.cancelDiscovery()
                } catch (_: Exception) {}
                Thread.sleep(250)

                val device = bluetoothAdapter?.getRemoteDevice(address)
                if (device == null) {
                    mainHandler.post { result.error("DEVICE_NOT_FOUND", "Device not found for $address", null) }
                    return@Thread
                }

                // If not already bonded and PIN is provided, automate pairing via ACTION_PAIRING_REQUEST
                if (!pin.isNullOrEmpty() && device.bondState != BluetoothDevice.BOND_BONDED) {
                    val currentPin = pin
                    pairingReceiver = object : BroadcastReceiver() {
                        override fun onReceive(context: Context?, intent: Intent?) {
                            if (intent?.action == BluetoothDevice.ACTION_PAIRING_REQUEST) {
                                val dev = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                    intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
                                } else {
                                    @Suppress("DEPRECATION")
                                    intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                                }
                                if (dev?.address == address) {
                                    try {
                                        dev.setPin(currentPin.toByteArray(Charsets.UTF_8))
                                    } catch (_: Exception) {}
                                }
                            }
                        }
                    }
                    val pFilter = IntentFilter(BluetoothDevice.ACTION_PAIRING_REQUEST)
                    registerReceiver(pairingReceiver, pFilter)

                    try {
                        device.createBond()
                        var waitMs = 0
                        while (device.bondState == BluetoothDevice.BOND_BONDING && waitMs < 4000) {
                            Thread.sleep(200)
                            waitMs += 200
                        }
                    } catch (_: Exception) {}
                }

                disconnectInternal()

                // Robust Multi-Method RFCOMM Socket Connection:
                // HC-05/HC-06 modules work best with Insecure RFCOMM SPP!
                var connected = false
                var lastEx: Exception? = null

                // Method 1: Insecure RFCOMM SPP (Standard for HC-05 / HC-06)
                try {
                    socket = device.createInsecureRfcommSocketToServiceRecord(SPP_UUID)
                    socket.connect()
                    connected = true
                } catch (e: Exception) {
                    lastEx = e
                    try { socket?.close() } catch (_: Exception) {}
                    socket = null
                }

                // Method 2: Standard Secure RFCOMM SPP (for ESP32 and encrypted modules)
                if (!connected) {
                    try {
                        socket = device.createRfcommSocketToServiceRecord(SPP_UUID)
                        socket.connect()
                        connected = true
                    } catch (e: Exception) {
                        lastEx = e
                        try { socket?.close() } catch (_: Exception) {}
                        socket = null
                    }
                }

                // Method 3: Insecure Reflection Channel 1
                if (!connected) {
                    try {
                        val m = device.javaClass.getMethod("createInsecureRfcommSocket", Int::class.javaPrimitiveType)
                        socket = m.invoke(device, 1) as BluetoothSocket
                        socket.connect()
                        connected = true
                    } catch (e: Exception) {
                        lastEx = e
                        try { socket?.close() } catch (_: Exception) {}
                        socket = null
                    }
                }

                // Method 4: Secure Reflection Channel 1
                if (!connected) {
                    try {
                        val m = device.javaClass.getMethod("createRfcommSocket", Int::class.javaPrimitiveType)
                        socket = m.invoke(device, 1) as BluetoothSocket
                        socket.connect()
                        connected = true
                    } catch (e: Exception) {
                        lastEx = e
                        try { socket?.close() } catch (_: Exception) {}
                        socket = null
                    }
                }

                pairingReceiver?.let {
                    try { unregisterReceiver(it) } catch (_: Exception) {}
                }

                if (!connected || socket == null) {
                    val msg = lastEx?.message ?: "Unable to connect to $address"
                    mainHandler.post {
                        result.error("CONNECT_FAILED", "Failed to connect: $msg", null)
                    }
                    return@Thread
                }

                activeSocket = socket
                outputStream = socket.outputStream
                inputStream = socket.inputStream
                isConnected = true

                startListening(socket.inputStream)

                mainHandler.post {
                    result.success(true)
                    channel?.invokeMethod("onConnectionStateChanged", mapOf("connected" to true, "address" to address))
                }
            } catch (e: Exception) {
                pairingReceiver?.let {
                    try { unregisterReceiver(it) } catch (_: Exception) {}
                }
                mainHandler.post {
                    result.error("CONNECT_ERROR", e.message, null)
                }
            }
        }.start()
    }

    private fun startListening(stream: InputStream) {
        readThread?.interrupt()
        readThread = Thread {
            val buffer = ByteArray(1024)
            while (isConnected) {
                try {
                    val bytesRead = stream.read(buffer)
                    if (bytesRead > 0) {
                        val message = String(buffer, 0, bytesRead)
                        mainHandler.post {
                            channel?.invokeMethod("onDataReceived", message)
                        }
                    }
                } catch (e: IOException) {
                    if (isConnected) {
                        disconnectInternal()
                        mainHandler.post {
                            channel?.invokeMethod("onConnectionStateChanged", mapOf("connected" to false, "error" to "Connection closed"))
                        }
                    }
                    break
                }
            }
        }.apply { start() }
    }

    private fun sendData(data: String, result: MethodChannel.Result) {
        if (!isConnected || outputStream == null) {
            result.error("NOT_CONNECTED", "Bluetooth is not connected", null)
            return
        }
        Thread {
            try {
                outputStream?.write(data.toByteArray(Charsets.UTF_8))
                outputStream?.flush()
                mainHandler.post { result.success(true) }
            } catch (e: Exception) {
                mainHandler.post { result.error("SEND_ERROR", e.message, null) }
            }
        }.start()
    }

    // Voice Command Speech Recognition
    private fun getGoogleRecognitionComponent(): ComponentName? {
        return try {
            ComponentName(
                "com.google.android.googlequicksearchbox",
                "com.google.android.voicesearch.serviceapi.GoogleRecognitionService"
            )
        } catch (_: Exception) {
            null
        }
    }

    private fun startSpeechRecognition(result: MethodChannel.Result) {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.RECORD_AUDIO), 1002)
            result.error("PERMISSION_DENIED", "Microphone permission required for Voice Commands", null)
            return
        }

        mainHandler.post {
            try {
                speechRecognizer?.destroy()
                val googleComp = getGoogleRecognitionComponent()
                speechRecognizer = try {
                    if (googleComp != null) {
                        SpeechRecognizer.createSpeechRecognizer(this, googleComp)
                    } else {
                        SpeechRecognizer.createSpeechRecognizer(this)
                    }
                } catch (_: Exception) {
                    SpeechRecognizer.createSpeechRecognizer(this)
                }

                speechRecognizer?.setRecognitionListener(object : RecognitionListener {
                    override fun onReadyForSpeech(params: Bundle?) {
                        channel?.invokeMethod("onSpeechStatus", "LISTENING")
                    }
                    override fun onBeginningOfSpeech() {}
                    override fun onRmsChanged(rmsdB: Float) {
                        channel?.invokeMethod("onSpeechRms", rmsdB)
                    }
                    override fun onBufferReceived(buffer: ByteArray?) {}
                    override fun onEndOfSpeech() {
                        channel?.invokeMethod("onSpeechStatus", "PROCESSING")
                    }
                    override fun onError(error: Int) {
                        val msg = when (error) {
                            SpeechRecognizer.ERROR_NO_MATCH -> "No voice match found"
                            SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "Speech timeout"
                            SpeechRecognizer.ERROR_AUDIO -> "Audio recording error"
                            SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "Recognizer busy"
                            else -> "Speech recognition error ($error)"
                        }
                        channel?.invokeMethod("onSpeechError", msg)
                        channel?.invokeMethod("onSpeechStatus", "IDLE")
                    }
                    override fun onResults(results: Bundle?) {
                        val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                        val text = matches?.firstOrNull() ?: ""
                        if (text.isNotBlank()) {
                            channel?.invokeMethod("onSpeechResult", text)
                        }
                        channel?.invokeMethod("onSpeechStatus", "IDLE")
                    }
                    override fun onPartialResults(partialResults: Bundle?) {
                        val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                        val text = matches?.firstOrNull() ?: ""
                        if (text.isNotBlank()) {
                            channel?.invokeMethod("onSpeechPartial", text)
                        }
                    }
                    override fun onEvent(eventType: Int, params: Bundle?) {}
                })

                val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                    putExtra(RecognizerIntent.EXTRA_CALLING_PACKAGE, packageName)
                    putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
                    putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 5)
                    putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, false)
                    // Quick silence detection for short single words like "one", "zero", "on", "off"
                    putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 800L)
                    putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, 800L)
                    // Allow ultra-short single-syllable commands (no 2-second minimum block)
                    putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS, 100L)
                }
                speechRecognizer?.startListening(intent)
                result.success(true)
            } catch (e: Exception) {
                result.error("SPEECH_ERROR", e.message, null)
            }
        }
    }

    private fun stopSpeechRecognition(result: MethodChannel.Result) {
        mainHandler.post {
            try {
                speechRecognizer?.stopListening()
                result.success(true)
            } catch (e: Exception) {
                result.error("SPEECH_ERROR", e.message, null)
            }
        }
    }

    private val REQUEST_SPEECH_INPUT = 1004

    private fun startGoogleVoiceDialog(result: MethodChannel.Result) {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.RECORD_AUDIO), 1002)
            result.error("PERMISSION_DENIED", "Microphone permission required for Voice Commands", null)
            return
        }

        try {
            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                putExtra(RecognizerIntent.EXTRA_PROMPT, "Speak command (e.g. 'one', 'zero', 'on', 'off')...")
                putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 5)
                putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, false)
            }
            startActivityForResult(intent, REQUEST_SPEECH_INPUT)
            channel?.invokeMethod("onSpeechStatus", "LISTENING")
            result.success(true)
        } catch (e: Exception) {
            result.error("GOOGLE_VOICE_ERROR", e.message, null)
        }
    }

    private val REQUEST_ENABLE_BT = 1003
    private var pendingEnableBtResult: MethodChannel.Result? = null
    private var btStateReceiver: BroadcastReceiver? = null

    private fun requestEnableBluetooth(result: MethodChannel.Result) {
        if (bluetoothAdapter == null) {
            result.error("NO_BT_ADAPTER", "Bluetooth is not supported on this device", null)
            return
        }
        if (bluetoothAdapter?.isEnabled == true) {
            result.success(true)
            return
        }
        pendingEnableBtResult = result
        try {
            val enableBtIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
            startActivityForResult(enableBtIntent, REQUEST_ENABLE_BT)
        } catch (e: Exception) {
            pendingEnableBtResult = null
            result.error("ENABLE_ERROR", e.message, null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_ENABLE_BT) {
            val isEnabled = (resultCode == Activity.RESULT_OK) || (bluetoothAdapter?.isEnabled == true)
            pendingEnableBtResult?.success(isEnabled)
            pendingEnableBtResult = null
            channel?.invokeMethod("onBluetoothStateChanged", isEnabled)
        } else if (requestCode == REQUEST_SPEECH_INPUT) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val matches = data.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)
                val text = matches?.firstOrNull() ?: ""
                if (text.isNotBlank()) {
                    channel?.invokeMethod("onSpeechResult", text)
                }
            }
            channel?.invokeMethod("onSpeechStatus", "IDLE")
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 1001) {
            if (hasBluetoothPermissions()) {
                // Immediately emit relevant bonded devices now that permissions are granted!
                bluetoothAdapter?.bondedDevices?.forEach { dev ->
                    if (isRelevantBluetoothDevice(dev)) {
                        val name = if (!dev.name.isNullOrBlank()) dev.name else "Arduino BT (${dev.address.takeLast(5)})"
                        val devMap = mapOf(
                            "name" to name,
                            "address" to dev.address,
                            "isPaired" to true,
                            "rssi" to -55
                        )
                        mainHandler.post {
                            channel?.invokeMethod("onDeviceDiscovered", devMap)
                        }
                    }
                }
            }
        }
    }

    private fun registerBluetoothStateReceiver() {
        if (btStateReceiver != null) return
        btStateReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action == BluetoothAdapter.ACTION_STATE_CHANGED) {
                    val state = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR)
                    val isEnabled = state == BluetoothAdapter.STATE_ON
                    mainHandler.post {
                        channel?.invokeMethod("onBluetoothStateChanged", isEnabled)
                    }
                }
            }
        }
        try {
            val filter = IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED)
            registerReceiver(btStateReceiver, filter)
        } catch (_: Exception) {}
    }

    private fun disconnectInternal() {
        isConnected = false
        try { readThread?.interrupt() } catch (_: Exception) {}
        readThread = null
        try { inputStream?.close() } catch (_: Exception) {}
        inputStream = null
        try { outputStream?.close() } catch (_: Exception) {}
        outputStream = null
        try { activeSocket?.close() } catch (_: Exception) {}
        activeSocket = null
    }

    override fun onDestroy() {
        stopDiscovery()
        disconnectInternal()
        try {
            btStateReceiver?.let { unregisterReceiver(it) }
            btStateReceiver = null
        } catch (_: Exception) {}
        try { speechRecognizer?.destroy() } catch (_: Exception) {}
        speechRecognizer = null
        super.onDestroy()
    }
}
