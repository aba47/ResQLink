package com.disasterready.app

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.InputStream
import java.io.OutputStream
import java.util.UUID

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.disasterready.app/bluetooth"
    private val APP_UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB") // Standard SPP UUID

    private var bluetoothAdapter: BluetoothAdapter? = null
    private var connectedSocket: BluetoothSocket? = null
    private var outputStream: OutputStream? = null
    private var inputStream: InputStream? = null
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isSupported" -> {
                    result.success(bluetoothAdapter != null)
                }
                "isEnabled" -> {
                    result.success(bluetoothAdapter?.isEnabled == true)
                }
                "requestPermissions" -> {
                    // For Android 12+ (API 31+), runtime permissions are requested via system dialogs
                    result.success(true)
                }
                "getDiscoveredDevices" -> {
                    val devicesList = mutableListOf<Map<String, String>>()
                    try {
                        val pairedDevices: Set<BluetoothDevice>? = bluetoothAdapter?.bondedDevices
                        pairedDevices?.forEach { device ->
                            devicesList.add(mapOf(
                                "name" to (device.name ?: "Unknown Device"),
                                "address" to device.address
                            ))
                        }
                    } catch (e: SecurityException) {
                        // Permissions not yet granted
                    }
                    result.success(devicesList)
                }
                "stopDiscovery" -> {
                    try {
                        bluetoothAdapter?.cancelDiscovery()
                    } catch (e: SecurityException) {}
                    result.success(null)
                }
                "connect" -> {
                    val address = call.argument<String>("address")
                    if (address == null || bluetoothAdapter == null) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    // Connection placeholder for physical devices
                    result.success(true)
                }
                "disconnect" -> {
                    try {
                        connectedSocket?.close()
                        connectedSocket = null
                    } catch (e: Exception) {}
                    result.success(null)
                }
                "sendData" -> {
                    val data = call.argument<String>("data")
                    // Stream out if physical socket connected
                    try {
                        outputStream?.write(data?.toByteArray() ?: byteArrayOf())
                        outputStream?.flush()
                    } catch (e: Exception) {}
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
