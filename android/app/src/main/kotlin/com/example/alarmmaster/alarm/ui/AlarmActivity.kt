package com.example.alarmmaster.alarm.ui

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.text.format.DateFormat
import android.view.WindowManager
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.alarmmaster.alarm.core.AlarmRuntime
import com.example.alarmmaster.alarm.notification.AlarmIntentExtras
import com.example.alarmmaster.alarm.service.AlarmRingingService
import kotlinx.coroutines.runBlocking
import java.time.LocalTime
import java.time.format.DateTimeFormatter
import java.util.Locale
import java.util.Timer
import java.util.TimerTask
import kotlin.random.Random

class AlarmActivity : ComponentActivity() {
    private var alarmId: Long = -1L
    private var triggerId: String = ""
    private var sessionId: String = ""
    private var generation: Int = -1
    private var title: String = "Alarm"
    private var localTimeLabel by mutableStateOf("")
    private var amPmLabel by mutableStateOf("")
    private var challengeMode by mutableStateOf("none")
    private var challengeSolved by mutableStateOf(true)
    private var mathPrompt by mutableStateOf("")
    private var mathExpectedAnswer: Int = 0
    private var mathInput by mutableStateOf("")
    private var memoryCode by mutableStateOf("")
    private var memoryInput by mutableStateOf("")
    private var selectedSnoozeMinutes by mutableStateOf(5)
    private var heroCtaLabel by mutableStateOf("WAKE UP")
    private var dismissHintLabel by mutableStateOf("wake up")

    private var use24HourFormat: Boolean = false
    private var clockTimer: Timer? = null
    private val challengeCoordinator = ChallengeCoordinator()
    private val qrChallengeLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult(),
    ) { result ->
        if (result.resultCode == RESULT_OK) {
            challengeSolved = true
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        prepareWindow()
        use24HourFormat = DateFormat.is24HourFormat(this)
        readExtras(intent)
        updateClock()
        startClockTicker()

        setContent {
            MaterialTheme(
                colorScheme = darkColorScheme(
                    primary = AlarmAccent,
                    secondary = AlarmAccent,
                    surface = AlarmSurface,
                    background = AlarmBg,
                    onPrimary = Color.White,
                    onSurface = Color.White,
                    onBackground = Color.White,
                ),
            ) {
                AlarmRingingContent(
                    clock = localTimeLabel,
                    amPm = amPmLabel,
                    title = title,
                    heroCtaLabel = heroCtaLabel,
                    dismissHintLabel = dismissHintLabel,
                    challengeMode = challengeMode,
                    challengeSolved = challengeSolved,
                    mathPrompt = mathPrompt,
                    mathInput = mathInput,
                    onMathInputChanged = { mathInput = it },
                    onVerifyMath = { verifyMathChallenge() },
                    memoryCode = memoryCode,
                    memoryInput = memoryInput,
                    onMemoryInputChanged = { memoryInput = it },
                    onVerifyMemory = { verifyMemoryChallenge() },
                    onLaunchQr = { launchChallenge() },
                    selectedSnoozeMinutes = selectedSnoozeMinutes,
                    onSelectSnoozeMinutes = { selectedSnoozeMinutes = it },
                    onDismiss = { sendActionAndFinish(AlarmRingingService.ACTION_DISMISS) },
                    onSnooze = {
                        sendActionAndFinish(
                            action = AlarmRingingService.ACTION_SNOOZE,
                            snoozeMinutes = selectedSnoozeMinutes,
                        )
                    },
                    onPrimaryAction = {
                        sendActionAndFinish(AlarmRingingService.ACTION_PRIMARY_ACTION)
                    },
                )
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        readExtras(intent)
    }

    override fun onDestroy() {
        clockTimer?.cancel()
        clockTimer = null
        super.onDestroy()
    }

    private fun prepareWindow() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
            )
        }
        @Suppress("DEPRECATION")
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    private fun readExtras(intent: Intent?) {
        alarmId = intent?.getLongExtra(AlarmIntentExtras.EXTRA_ALARM_ID, -1L) ?: -1L
        triggerId = intent?.getStringExtra(AlarmIntentExtras.EXTRA_TRIGGER_ID).orEmpty()
        sessionId = intent?.getStringExtra(AlarmIntentExtras.EXTRA_SESSION_ID).orEmpty()
        generation = intent?.getIntExtra(AlarmIntentExtras.EXTRA_GENERATION, -1) ?: -1
        title = intent?.getStringExtra(AlarmIntentExtras.EXTRA_ALARM_TITLE)
            .orEmpty()
            .ifBlank { "Alarm" }
        selectedSnoozeMinutes = (intent?.getIntExtra(AlarmIntentExtras.EXTRA_SNOOZE_MINUTES, 5) ?: 5)
            .takeIf { it in listOf(5, 10, 15) } ?: 5
        updateClock()

        if (alarmId > 0) {
            val plan = runBlocking {
                AlarmRuntime.get(applicationContext).alarmRepository.getById(alarmId)
            }
            challengeMode = challengeCoordinator.normalize(
                challengePolicy = plan?.challengePolicy,
                legacyChallenge = plan?.challenge ?: "none",
            ).mode
            challengeSolved = challengeMode == "none"
            prepareChallengeState()
        } else {
            challengeMode = "none"
            challengeSolved = true
        }
    }

    private fun prepareChallengeState() {
        when (challengeMode) {
            "math" -> {
                val a = Random.nextInt(2, 10)
                val b = Random.nextInt(2, 10)
                mathExpectedAnswer = a + b
                mathPrompt = "What is $a + $b?"
                mathInput = ""
            }
            "memory" -> {
                memoryCode = (1..4)
                    .map { Random.nextInt(0, 10) }
                    .joinToString(separator = "")
                memoryInput = ""
            }
        }
    }

    private fun verifyMathChallenge() {
        val value = mathInput.toIntOrNull() ?: return
        if (value == mathExpectedAnswer) {
            challengeSolved = true
        }
    }

    private fun verifyMemoryChallenge() {
        if (memoryInput.trim() == memoryCode) {
            challengeSolved = true
        }
    }

    private fun launchChallenge() {
        if (challengeMode != "qr") return
        qrChallengeLauncher.launch(Intent(this, QrChallengeActivity::class.java))
    }

    private fun sendActionAndFinish(action: String, snoozeMinutes: Int? = null) {
        val serviceIntent = Intent(this, AlarmRingingService::class.java).apply {
            this.action = action
            putExtra(AlarmIntentExtras.EXTRA_ALARM_ID, alarmId)
            putExtra(AlarmIntentExtras.EXTRA_TRIGGER_ID, triggerId)
            putExtra(AlarmIntentExtras.EXTRA_SESSION_ID, sessionId)
            putExtra(AlarmIntentExtras.EXTRA_GENERATION, generation)
            if (snoozeMinutes != null) {
                putExtra(AlarmIntentExtras.EXTRA_SNOOZE_MINUTES, snoozeMinutes)
            }
        }
        startService(serviceIntent)
        finish()
    }

    private fun startClockTicker() {
        clockTimer?.cancel()
        clockTimer = Timer("alarm-clock-ticker", true).apply {
            scheduleAtFixedRate(object : TimerTask() {
                override fun run() {
                    runOnUiThread { updateClock() }
                }
            }, 0L, 1000L)
        }
    }

    private fun updateClock() {
        val now = LocalTime.now()
        if (use24HourFormat) {
            localTimeLabel = now.format(DateTimeFormatter.ofPattern("HH:mm"))
            amPmLabel = ""
        } else {
            localTimeLabel = now.format(DateTimeFormatter.ofPattern("h:mm"))
            amPmLabel = now
                .format(DateTimeFormatter.ofPattern("a", Locale.getDefault()))
                .uppercase(Locale.getDefault())
        }
        val copy = alarmHeroCopy(now, title)
        heroCtaLabel = copy.hero
        dismissHintLabel = copy.dismissHint
    }

    private fun alarmHeroCopy(now: LocalTime, alarmTitle: String): AlarmHeroCopy {
        val normalizedTitle = alarmTitle.lowercase(Locale.getDefault())
        val eventish = listOf(
            "meeting",
            "event",
            "exam",
            "medication",
            "travel",
            "reminder",
            "appointment",
        ).any { normalizedTitle.contains(it) }
        if (eventish) {
            return AlarmHeroCopy(hero = "BE READY", dismissHint = "be ready")
        }

        return when (now.hour) {
            in 5..11 -> AlarmHeroCopy(hero = "WAKE UP", dismissHint = "wake up")
            in 12..17 -> AlarmHeroCopy(hero = "STAY SHARP", dismissHint = "stay sharp")
            in 18..21 -> AlarmHeroCopy(hero = "EVENING", dismissHint = "stay ready")
            else -> AlarmHeroCopy(hero = "NIGHT ALERT", dismissHint = "stay alert")
        }
    }

    private data class AlarmHeroCopy(
        val hero: String,
        val dismissHint: String,
    )
}

@Composable
private fun AlarmRingingContent(
    clock: String,
    amPm: String,
    title: String,
    heroCtaLabel: String,
    dismissHintLabel: String,
    challengeMode: String,
    challengeSolved: Boolean,
    mathPrompt: String,
    mathInput: String,
    onMathInputChanged: (String) -> Unit,
    onVerifyMath: () -> Unit,
    memoryCode: String,
    memoryInput: String,
    onMemoryInputChanged: (String) -> Unit,
    onVerifyMemory: () -> Unit,
    onLaunchQr: () -> Unit,
    selectedSnoozeMinutes: Int,
    onSelectSnoozeMinutes: (Int) -> Unit,
    onDismiss: () -> Unit,
    onSnooze: () -> Unit,
    onPrimaryAction: () -> Unit,
) {
    val ringTransition = rememberInfiniteTransition(label = "alarm-ring")
    val pulseScale by ringTransition.animateFloat(
        initialValue = 0.985f,
        targetValue = 1.03f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 1150, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse,
        ),
        label = "pulse-scale",
    )
    val ctaPulse by ringTransition.animateFloat(
        initialValue = 0.98f,
        targetValue = 1.04f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 1450, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse,
        ),
        label = "cta-pulse",
    )
    val glowShift by ringTransition.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 2600, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse,
        ),
        label = "glow-shift",
    )
    val hintAlpha by ringTransition.animateFloat(
        initialValue = 0.34f,
        targetValue = 0.7f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 900, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse,
        ),
        label = "hint-alpha",
    )
    val topTone = lerp(Color(0xFF15100A), Color(0xFF2A1608), glowShift)
    val middleTone = lerp(Color(0xFF090909), Color(0xFF12100E), glowShift * 0.7f)
    val bottomTone = lerp(Color(0xFF050505), Color(0xFF110B06), glowShift * 0.45f)

    Surface(
        modifier = Modifier.fillMaxSize(),
        color = AlarmBg,
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    brush = Brush.verticalGradient(
                        colors = listOf(
                            topTone,
                            middleTone,
                            bottomTone,
                        ),
                    ),
                ),
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 24.dp, vertical = 20.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Text(
                    text = "Swipe up to dismiss",
                    color = AlarmMuted.copy(alpha = hintAlpha),
                    fontSize = 12.sp,
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(text = "^", color = AlarmMuted.copy(alpha = hintAlpha), fontSize = 12.sp)

                Spacer(modifier = Modifier.weight(1f))

                Row(
                    verticalAlignment = Alignment.Top,
                    modifier = Modifier.scale(pulseScale),
                ) {
                    Text(
                        text = clock,
                        color = Color.White,
                        fontSize = 72.sp,
                        fontWeight = FontWeight.W700,
                        letterSpacing = (-1.2).sp,
                    )
                    if (amPm.isNotBlank()) {
                        Text(
                            text = amPm,
                            color = AlarmMuted,
                            fontSize = 26.sp,
                            modifier = Modifier.padding(start = 8.dp, top = 10.dp),
                        )
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                Box(
                    modifier = Modifier
                        .scale(ctaPulse)
                        .clip(RoundedCornerShape(999.dp))
                        .border(BorderStroke(1.dp, AlarmAccent.copy(alpha = 0.45f)), RoundedCornerShape(999.dp))
                        .background(AlarmAccent.copy(alpha = 0.12f + (0.05f * glowShift)))
                        .padding(horizontal = 20.dp, vertical = 8.dp),
                ) {
                    Text(
                        text = heroCtaLabel,
                        color = AlarmAccent,
                        fontSize = 24.sp,
                        fontWeight = FontWeight.W700,
                        letterSpacing = 2.sp,
                    )
                }

                Spacer(modifier = Modifier.height(10.dp))
                Text(
                    text = title,
                    color = AlarmMuted,
                    fontSize = 20.sp,
                    textAlign = TextAlign.Center,
                    maxLines = 1,
                )

                if (!challengeSolved) {
                    Spacer(modifier = Modifier.height(18.dp))
                    ChallengeGateSection(
                        mode = challengeMode,
                        mathPrompt = mathPrompt,
                        mathInput = mathInput,
                        onMathInputChanged = onMathInputChanged,
                        onVerifyMath = onVerifyMath,
                        memoryCode = memoryCode,
                        memoryInput = memoryInput,
                        onMemoryInputChanged = onMemoryInputChanged,
                        onVerifyMemory = onVerifyMemory,
                        onLaunchQr = onLaunchQr,
                    )
                }

                Spacer(modifier = Modifier.weight(1f))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    listOf(5, 10, 15).forEach { minutes ->
                        OutlinedButton(
                            onClick = { onSelectSnoozeMinutes(minutes) },
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(16.dp),
                            border = BorderStroke(
                                width = 1.dp,
                                color = if (minutes == selectedSnoozeMinutes) AlarmAccent else AlarmStroke,
                            ),
                            colors = ButtonDefaults.outlinedButtonColors(
                                containerColor = if (minutes == selectedSnoozeMinutes) {
                                    AlarmAccent.copy(alpha = 0.14f)
                                } else {
                                    AlarmSurface
                                },
                                contentColor = if (minutes == selectedSnoozeMinutes) AlarmAccent else AlarmMuted,
                            ),
                        ) {
                            Text(text = "${minutes}m", fontSize = 13.sp)
                        }
                    }
                }

                Spacer(modifier = Modifier.height(14.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    AlarmActionCard(
                        modifier = Modifier.weight(1f),
                        title = "SNOOZE",
                        subtitle = "$selectedSnoozeMinutes min",
                        accent = false,
                        enabled = challengeSolved,
                        ringPulseScale = 1f,
                        onClick = onSnooze,
                    )
                    AlarmActionCard(
                        modifier = Modifier.weight(1f),
                        title = "DISMISS",
                        subtitle = if (challengeSolved) dismissHintLabel else "solve first",
                        accent = true,
                        enabled = challengeSolved,
                        ringPulseScale = ctaPulse,
                        onClick = onDismiss,
                    )
                }

                Spacer(modifier = Modifier.height(12.dp))

                OutlinedButton(
                    onClick = onPrimaryAction,
                    enabled = challengeSolved,
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(14.dp),
                    border = BorderStroke(1.dp, AlarmStroke),
                    colors = ButtonDefaults.outlinedButtonColors(
                        containerColor = AlarmSurface,
                        contentColor = AlarmMuted,
                    ),
                ) {
                    Text(text = "Do Action", fontSize = 14.sp)
                }

                Spacer(modifier = Modifier.height(16.dp))
                Text(text = "v", color = AlarmMuted, fontSize = 12.sp)
                Text(
                    text = "Swipe down to snooze",
                    color = AlarmMuted.copy(alpha = hintAlpha),
                    fontSize = 12.sp,
                )
            }
        }
    }
}

@Composable
private fun ChallengeGateSection(
    mode: String,
    mathPrompt: String,
    mathInput: String,
    onMathInputChanged: (String) -> Unit,
    onVerifyMath: () -> Unit,
    memoryCode: String,
    memoryInput: String,
    onMemoryInputChanged: (String) -> Unit,
    onVerifyMemory: () -> Unit,
    onLaunchQr: () -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(18.dp))
            .background(AlarmSurface)
            .padding(14.dp),
    ) {
        Text(
            text = "Challenge required: ${mode.uppercase(Locale.getDefault())}",
            color = AlarmAccent,
            fontSize = 14.sp,
            fontWeight = FontWeight.W700,
        )
        Spacer(modifier = Modifier.height(10.dp))
        when (mode) {
            "qr" -> {
                OutlinedButton(
                    onClick = onLaunchQr,
                    modifier = Modifier.fillMaxWidth(),
                    border = BorderStroke(1.dp, AlarmAccent),
                    colors = ButtonDefaults.outlinedButtonColors(
                        containerColor = AlarmAccent.copy(alpha = 0.12f),
                        contentColor = AlarmAccent,
                    ),
                ) {
                    Text("Start QR Challenge")
                }
            }
            "math" -> {
                Text(text = mathPrompt, color = Color.White, fontSize = 16.sp)
                Spacer(modifier = Modifier.height(8.dp))
                OutlinedTextField(
                    value = mathInput,
                    onValueChange = onMathInputChanged,
                    label = { Text("Answer") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                )
                Spacer(modifier = Modifier.height(8.dp))
                Button(
                    onClick = onVerifyMath,
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(containerColor = AlarmAccent),
                ) {
                    Text("Verify", color = Color.White)
                }
            }
            "memory" -> {
                Text(
                    text = "Memorize and enter this code: $memoryCode",
                    color = Color.White,
                    fontSize = 15.sp,
                )
                Spacer(modifier = Modifier.height(8.dp))
                OutlinedTextField(
                    value = memoryInput,
                    onValueChange = onMemoryInputChanged,
                    label = { Text("Code") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                )
                Spacer(modifier = Modifier.height(8.dp))
                Button(
                    onClick = onVerifyMemory,
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(containerColor = AlarmAccent),
                ) {
                    Text("Verify", color = Color.White)
                }
            }
        }
    }
}

@Composable
private fun AlarmActionCard(
    modifier: Modifier = Modifier,
    title: String,
    subtitle: String,
    accent: Boolean,
    enabled: Boolean,
    ringPulseScale: Float = 1f,
    onClick: () -> Unit,
) {
    Button(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier
            .height(104.dp)
            .scale(if (accent && enabled) ringPulseScale else 1f),
        shape = RoundedCornerShape(20.dp),
        colors = ButtonDefaults.buttonColors(
            containerColor = if (accent) AlarmAccent.copy(alpha = 0.16f) else AlarmSurface,
            contentColor = if (accent) AlarmAccent else Color.White,
            disabledContainerColor = AlarmSurface.copy(alpha = 0.65f),
            disabledContentColor = AlarmMuted.copy(alpha = 0.6f),
        ),
        border = BorderStroke(
            width = 1.dp,
            color = if (accent) AlarmAccent else AlarmStroke,
        ),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(
            horizontal = 12.dp,
            vertical = 8.dp,
        ),
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                text = title,
                fontSize = 25.sp,
                fontWeight = FontWeight.W700,
                letterSpacing = 1.2.sp,
                maxLines = 1,
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = subtitle,
                fontSize = 13.sp,
                color = AlarmMuted,
                maxLines = 1,
            )
        }
    }
}

private val AlarmAccent = Color(0xFFFF7A1A)
private val AlarmBg = Color(0xFF050505)
private val AlarmSurface = Color(0xFF111111)
private val AlarmStroke = Color(0xFF2C2C2C)
private val AlarmMuted = Color(0xFF9A9A9A)
