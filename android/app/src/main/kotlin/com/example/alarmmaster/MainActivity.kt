package com.example.alarmmaster

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import androidx.lifecycle.lifecycleScope
import com.example.alarmmaster.alarm.bridge.AlarmCoreService
import com.example.alarmmaster.alarm.core.AlarmRuntime
import com.example.alarmmaster.alarm.bridge.GuardianAlarmHostApiImpl
import com.example.alarmmaster.bridge.gen.GuardianAlarmHostApi
import kotlinx.coroutines.launch

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val runtime = AlarmRuntime.get(applicationContext)
        runtime.ensureChannels()
        lifecycleScope.launch {
            runtime.startupSanityChecker.run()
        }
        val coreService = AlarmCoreService(applicationContext)
        GuardianAlarmHostApi.setUp(
            flutterEngine.dartExecutor.binaryMessenger,
            GuardianAlarmHostApiImpl(coreService),
        )
    }
}
