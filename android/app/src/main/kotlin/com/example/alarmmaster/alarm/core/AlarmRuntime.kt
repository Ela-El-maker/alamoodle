package com.example.alarmmaster.alarm.core

import android.content.Context
import com.example.alarmmaster.alarm.data.BackupExporter
import com.example.alarmmaster.alarm.data.BackupImporter
import com.example.alarmmaster.alarm.data.DeviceProtectedRecoveryStore
import com.example.alarmmaster.alarm.data.GuardianDatabase
import com.example.alarmmaster.alarm.diagnostics.DiagnosticsExporter
import com.example.alarmmaster.alarm.diagnostics.EventLogger
import com.example.alarmmaster.alarm.diagnostics.HistoryReadService
import com.example.alarmmaster.alarm.diagnostics.StatsAggregationService
import com.example.alarmmaster.alarm.notification.AlarmFullScreenLauncher
import com.example.alarmmaster.alarm.notification.AlarmNotificationFactory
import com.example.alarmmaster.alarm.notification.ChannelRegistry
import com.example.alarmmaster.alarm.notification.NotificationPermissionHelper
import com.example.alarmmaster.alarm.reliability.RecoveryCoordinator
import com.example.alarmmaster.alarm.reliability.ReliabilityChecker
import com.example.alarmmaster.alarm.reliability.SettingsNavigator
import com.example.alarmmaster.alarm.reliability.StartupSanityChecker
import com.example.alarmmaster.alarm.reliability.TestAlarmRunner
import com.example.alarmmaster.alarm.reliability.OemGuidanceProvider
import com.example.alarmmaster.alarm.recurrence.NativeRecurrenceEngineAdapter
import com.example.alarmmaster.alarm.repository.AlarmRepository
import com.example.alarmmaster.alarm.repository.AlarmRepositoryImpl
import com.example.alarmmaster.alarm.repository.HistoryRepository
import com.example.alarmmaster.alarm.repository.HistoryRepositoryImpl
import com.example.alarmmaster.alarm.repository.RingSessionRepository
import com.example.alarmmaster.alarm.repository.RingSessionRepositoryImpl
import com.example.alarmmaster.alarm.repository.TemplateRepository
import com.example.alarmmaster.alarm.repository.TemplateRepositoryImpl
import com.example.alarmmaster.alarm.repository.TriggerRepository
import com.example.alarmmaster.alarm.repository.TriggerRepositoryImpl
import com.example.alarmmaster.alarm.scheduler.AlarmIntentFactory
import com.example.alarmmaster.alarm.scheduler.AlarmPlanner
import com.example.alarmmaster.alarm.scheduler.AlarmScheduler
import com.example.alarmmaster.alarm.scheduler.AndroidAlarmScheduler
import com.example.alarmmaster.alarm.scheduler.ExactAlarmPermissionGate
import com.example.alarmmaster.alarm.scheduler.ScheduleRepairer
import com.example.alarmmaster.alarm.scheduler.TriggerIdFactory
import com.example.alarmmaster.alarm.service.AlarmAudioController
import com.example.alarmmaster.alarm.service.SoundCatalogRepository

class AlarmRuntime private constructor(context: Context) {
    private val appContext = context.applicationContext

    val database: GuardianDatabase = GuardianDatabase.getInstance(appContext)
    val alarmRepository: AlarmRepository = AlarmRepositoryImpl(database.alarmPlanDao())
    val triggerRepository: TriggerRepository = TriggerRepositoryImpl(database.triggerInstanceDao())
    val statsAggregationService = StatsAggregationService(database.dailyAlarmStatsDao())
    val historyRepository: HistoryRepository = HistoryRepositoryImpl(
        database.alarmHistoryDao(),
        statsAggregationService,
    )
    val ringSessionRepository: RingSessionRepository = RingSessionRepositoryImpl(database.ringSessionDao())
    val templateRepository: TemplateRepository = TemplateRepositoryImpl(database.alarmTemplateDao())

    val triggerIdFactory = TriggerIdFactory()
    val recurrenceEngine = NativeRecurrenceEngineAdapter()
    val planner = AlarmPlanner(triggerIdFactory, recurrenceEngine)
    val alarmScheduler: AlarmScheduler = AndroidAlarmScheduler(
        appContext,
        database.scheduleRegistryDao(),
        AlarmIntentFactory(appContext),
    )
    val exactAlarmPermissionGate = ExactAlarmPermissionGate(appContext)
    val notificationPermissionHelper = NotificationPermissionHelper(appContext)
    val repairer = ScheduleRepairer(triggerRepository, alarmScheduler, database.scheduleRegistryDao())
    val recoveryStore = DeviceProtectedRecoveryStore(appContext)
    val eventLogger = EventLogger(appContext)
    val channelRegistry = ChannelRegistry(appContext)
    val fullScreenLauncher = AlarmFullScreenLauncher(appContext)
    val notificationFactory = AlarmNotificationFactory(appContext, fullScreenLauncher)
    val soundCatalogRepository = SoundCatalogRepository(appContext)
    val previewAudioController = AlarmAudioController(appContext)

    val recoveryCoordinator = RecoveryCoordinator(
        alarmRepository = alarmRepository,
        triggerRepository = triggerRepository,
        historyRepository = historyRepository,
        alarmScheduler = alarmScheduler,
        repairer = repairer,
        recoveryStore = recoveryStore,
        triggerIdFactory = triggerIdFactory,
        eventLogger = eventLogger,
    )

    val reliabilityChecker = ReliabilityChecker(
        appContext,
        exactAlarmPermissionGate,
        notificationPermissionHelper,
        channelRegistry = channelRegistry,
        scheduleRegistryDao = database.scheduleRegistryDao(),
        recoveryStateProvider = recoveryCoordinator,
    )
    val settingsNavigator = SettingsNavigator(appContext, notificationPermissionHelper)
    val testAlarmRunner = TestAlarmRunner(
        alarmRepository = alarmRepository,
        triggerRepository = triggerRepository,
        historyRepository = historyRepository,
        alarmScheduler = alarmScheduler,
        triggerIdFactory = triggerIdFactory,
        exactAlarmPermissionGate = exactAlarmPermissionGate,
    )
    val diagnosticsExporter = DiagnosticsExporter(
        context = appContext,
        alarmRepository = alarmRepository,
        triggerRepository = triggerRepository,
        historyRepository = historyRepository,
        reliabilityChecker = reliabilityChecker,
        exactAlarmPermissionGate = exactAlarmPermissionGate,
    )
    val historyReadService = HistoryReadService(historyRepository)
    val startupSanityChecker = StartupSanityChecker(recoveryCoordinator)
    val backupExporter = BackupExporter(
        alarmRepository = alarmRepository,
        templateRepository = templateRepository,
        dailyAlarmStatsDao = database.dailyAlarmStatsDao(),
        backupMetadataDao = database.backupMetadataDao(),
    )
    val backupImporter = BackupImporter(
        alarmRepository = alarmRepository,
        triggerRepository = triggerRepository,
        historyRepository = historyRepository,
        templateRepository = templateRepository,
        dailyAlarmStatsDao = database.dailyAlarmStatsDao(),
        backupMetadataDao = database.backupMetadataDao(),
        planner = planner,
        alarmScheduler = alarmScheduler,
    )
    val oemGuidanceProvider = OemGuidanceProvider()

    fun ensureChannels() {
        channelRegistry.ensureChannels()
    }

    companion object {
        @Volatile
        private var INSTANCE: AlarmRuntime? = null

        fun get(context: Context): AlarmRuntime {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: AlarmRuntime(context).also { INSTANCE = it }
            }
        }
    }
}
