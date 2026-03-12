import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/history/data/history_repository_platform_impl.dart';
import '../../features/history/domain/history_record.dart';
import '../../features/history/state/history_controller.dart';
import '../../features/reliability/data/reliability_repository_platform_impl.dart';
import '../../features/reliability/state/reliability_controller.dart';
import '../../platform/guardian_platform_models.dart';
import './widgets/permission_status_row_widget.dart';
import './widgets/reliability_header_widget.dart';

class ReliabilitySettingsScreen extends StatefulWidget {
  const ReliabilitySettingsScreen({
    super.key,
    this.reliabilityController,
    this.historyController,
  });

  final ReliabilityController? reliabilityController;
  final HistoryController? historyController;

  @override
  State<ReliabilitySettingsScreen> createState() =>
      _ReliabilitySettingsScreenState();
}

class _ReliabilitySettingsScreenState extends State<ReliabilitySettingsScreen> {
  late final ReliabilityController _reliabilityController;
  late final HistoryController _historyController;

  ReliabilitySnapshotModel? _snapshot;
  OemGuidanceModel? _oemGuidance;
  List<HistoryRecord> _history = const <HistoryRecord>[];
  bool _isLoading = true;
  bool _isRunningTest = false;
  bool _isImportingBackup = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reliabilityController =
        widget.reliabilityController ??
        ReliabilityController(ReliabilityRepositoryPlatformImpl());
    _historyController =
        widget.historyController ??
        HistoryController(HistoryRepositoryPlatformImpl());
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final snapshot = await _reliabilityController.getSnapshot();
      final history = await _historyController.getRecent(limit: 20);
      final guidance = await _reliabilityController.getOemGuidance();
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _oemGuidance = guidance;
        _history = history;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _runTestAlarm() async {
    HapticFeedback.mediumImpact();
    setState(() => _isRunningTest = true);
    try {
      final result = await _reliabilityController.runTestAlarm();
      if (!mounted) return;
      final prefix = result.success ? 'Test scheduled' : 'Test failed';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$prefix: ${result.message}')));
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Test failed: $error')));
    } finally {
      if (mounted) setState(() => _isRunningTest = false);
    }
  }

  Future<void> _openSettings(String target) async {
    final ok = await _reliabilityController.openSystemSettings(target);
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to open settings screen')),
    );
  }

  Future<void> _importBackupFromClipboard() async {
    setState(() => _isImportingBackup = true);
    try {
      final payload = (await Clipboard.getData('text/plain'))?.text?.trim();
      if (payload == null || payload.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clipboard does not contain backup JSON'),
          ),
        );
        return;
      }
      final result = await _reliabilityController.importBackup(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Backup import failed: $error')));
    } finally {
      if (mounted) setState(() => _isImportingBackup = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Alarm Reliability',
          style: GoogleFonts.manrope(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF7A1A)),
      );
    }

    if (_error != null || _snapshot == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            _error ?? 'Failed to load reliability data',
            style: GoogleFonts.manrope(color: const Color(0xFFB8B8B8)),
          ),
        ),
      );
    }

    final snapshot = _snapshot!;
    final cards = _buildPermissionCards(snapshot);
    final critical = cards
        .where((item) => item.status == PermissionStatus.critical)
        .length;
    final warning = cards
        .where((item) => item.status == PermissionStatus.warning)
        .length;
    final ok = cards.where((item) => item.status == PermissionStatus.ok).length;

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        ReliabilityHeaderWidget(
          criticalCount: critical,
          warningCount: warning,
          okCount: ok,
        ),
        _buildSectionLabel('Health checks'),
        const SizedBox(height: 8),
        ...cards.map(
          (item) => PermissionStatusRowWidget(
            icon: item.icon,
            title: item.title,
            description: item.description,
            statusLabel: item.statusLabel,
            status: item.status,
            onFix: item.fixTarget == null
                ? null
                : () => _openSettings(item.fixTarget!),
          ),
        ),
        _buildSectionLabel('Native state'),
        const SizedBox(height: 12),
        _buildSystemState(snapshot),
        _buildSectionLabel('Actions'),
        const SizedBox(height: 12),
        _buildActionButtons(),
        _buildSectionLabel('Limits and guidance'),
        const SizedBox(height: 12),
        _buildPlatformLimitsNote(),
        if (_oemGuidance != null) ...[
          const SizedBox(height: 12),
          _buildOemGuidanceSection(_oemGuidance!),
        ],
        _buildSectionLabel('Recent events'),
        const SizedBox(height: 12),
        _buildHistorySection(),
      ],
    );
  }

  Widget _buildActionButtons() {
    final runTestButton = ElevatedButton.icon(
      onPressed: _isRunningTest ? null : _runTestAlarm,
      icon: _isRunningTest
          ? const SizedBox(
              height: 14,
              width: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.play_circle_fill_rounded),
      label: const Text('Run Test Alarm'),
    );
    final copyDiagnosticsButton = OutlinedButton.icon(
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        final payload = await _reliabilityController.exportDiagnostics();
        if (!mounted) return;
        await Clipboard.setData(ClipboardData(text: payload));
        messenger.showSnackBar(
          const SnackBar(content: Text('Diagnostics copied to clipboard')),
        );
      },
      icon: const Icon(Icons.copy_rounded),
      label: const Text('Copy Diagnostics'),
    );
    final copyBackupButton = OutlinedButton.icon(
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        final payload = await _reliabilityController.exportBackup();
        if (!mounted) return;
        await Clipboard.setData(ClipboardData(text: payload));
        messenger.showSnackBar(
          const SnackBar(content: Text('Backup JSON copied to clipboard')),
        );
      },
      icon: const Icon(Icons.backup_rounded),
      label: const Text('Copy Backup'),
    );
    final importBackupButton = OutlinedButton.icon(
      onPressed: _isImportingBackup ? null : _importBackupFromClipboard,
      icon: _isImportingBackup
          ? const SizedBox(
              height: 14,
              width: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.restore_rounded),
      label: const Text('Import Backup'),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                runTestButton,
                const SizedBox(height: 10),
                copyDiagnosticsButton,
                const SizedBox(height: 10),
                copyBackupButton,
                const SizedBox(height: 10),
                importBackupButton,
              ],
            );
          }
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(width: 190, child: runTestButton),
              copyDiagnosticsButton,
              copyBackupButton,
              importBackupButton,
            ],
          );
        },
      ),
    );
  }

  Widget _buildOemGuidanceSection(OemGuidanceModel guidance) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OEM Guidance',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${guidance.manufacturer.toUpperCase()} · ${guidance.title}',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFFFA24A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            guidance.summary,
            style: GoogleFonts.manrope(
              color: const Color(0xFFB8B8B8),
              fontSize: 12,
            ),
          ),
          if (guidance.steps.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...guidance.steps.map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $step',
                  style: GoogleFonts.manrope(
                    color: const Color(0xFFB8B8B8),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlatformLimitsNote() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Platform Limits',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Some behaviors are controlled by Android and OEM firmware. Force-stopped apps and powered-off phones may not trigger alarms until the app/device is active again.',
            style: GoogleFonts.manrope(
              color: const Color(0xFFB8B8B8),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemState(ReliabilitySnapshotModel snapshot) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Native Reliability State',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          _stateRow('Engine mode', snapshot.engineMode),
          _stateRow(
            'Native ring pipeline',
            snapshot.nativeRingPipelineEnabled ? 'enabled' : 'disabled',
          ),
          _stateRow(
            'Legacy fallback default',
            snapshot.legacyFallbackDefaultEnabled ? 'enabled' : 'disabled',
          ),
          _stateRow('Scheduler health', snapshot.schedulerHealth),
          _stateRow('Channel health', snapshot.channelHealth),
          _stateRow('Registry health', snapshot.scheduleRegistryHealth),
          _stateRow('Battery risk', snapshot.batteryOptimizationRisk),
          _stateRow('Last recovery', snapshot.lastRecoveryReason),
          _stateRow('Recovery status', snapshot.lastRecoveryStatus),
        ],
      ),
    );
  }

  Widget _stateRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                color: const Color(0xFF9C9C9C),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: const Color(0xFF6A6A6A),
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Native History',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          if (_history.isEmpty)
            Text(
              'No native history yet.',
              style: GoogleFonts.manrope(color: const Color(0xFF9C9C9C)),
            )
          else
            ..._history
                .take(8)
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${entry.eventType} · alarm ${entry.alarmId} · ${entry.meta}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        color: const Color(0xFFB8B8B8),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  List<_PermissionCard> _buildPermissionCards(
    ReliabilitySnapshotModel snapshot,
  ) {
    return [
      _PermissionCard(
        icon: Icons.alarm_rounded,
        title: 'Exact Alarms',
        description: 'Native exact scheduling capability for MAIN/PRE/SNOOZE.',
        statusLabel: snapshot.canScheduleExactAlarms ? 'Allowed' : 'Denied',
        status: snapshot.canScheduleExactAlarms
            ? PermissionStatus.ok
            : PermissionStatus.critical,
        fixTarget: snapshot.canScheduleExactAlarms ? null : 'exact_alarm',
      ),
      _PermissionCard(
        icon: Icons.notifications_active_rounded,
        title: 'Notifications',
        description: 'Required for lock-screen controls and ring visibility.',
        statusLabel: snapshot.notificationsPermissionGranted
            ? 'Allowed'
            : 'Denied',
        status: snapshot.notificationsPermissionGranted
            ? PermissionStatus.ok
            : PermissionStatus.critical,
        fixTarget: snapshot.notificationsPermissionGranted
            ? null
            : 'notifications',
      ),
      _PermissionCard(
        icon: Icons.fullscreen_rounded,
        title: 'Full-screen alarm',
        description:
            'Controls whether native full-screen interrupt can launch.',
        statusLabel: snapshot.fullScreenReady ? 'Ready' : 'Blocked',
        status: snapshot.fullScreenReady
            ? PermissionStatus.ok
            : PermissionStatus.warning,
        fixTarget: snapshot.fullScreenReady ? null : 'notifications',
      ),
      _PermissionCard(
        icon: Icons.battery_charging_full_rounded,
        title: 'Battery optimization',
        description: 'High risk can delay/interrupt alarms on some devices.',
        statusLabel: snapshot.batteryOptimizationRisk,
        status: snapshot.batteryOptimizationRisk == 'low'
            ? PermissionStatus.ok
            : PermissionStatus.warning,
        fixTarget: snapshot.batteryOptimizationRisk == 'low'
            ? null
            : 'battery_optimization',
      ),
      _PermissionCard(
        icon: Icons.lock_clock_rounded,
        title: 'Direct Boot readiness',
        description: 'Pre-unlock survivability and post-unlock reconciliation.',
        statusLabel: snapshot.directBootReady ? 'Ready' : 'Not ready',
        status: snapshot.directBootReady
            ? PermissionStatus.ok
            : PermissionStatus.warning,
      ),
    ];
  }
}

class _PermissionCard {
  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.statusLabel,
    required this.status,
    this.fixTarget,
  });

  final IconData icon;
  final String title;
  final String description;
  final String statusLabel;
  final PermissionStatus status;
  final String? fixTarget;
}
