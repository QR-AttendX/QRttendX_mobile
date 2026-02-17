import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:qr_attendx_mobile/core/utils/duplicate_utils.dart';
import 'package:qr_attendx_mobile/core/utils/navigation_state.dart';
import 'package:qr_attendx_mobile/core/utils/navigation_utils.dart';
import 'package:qr_attendx_mobile/features/attendance/attendance_controller.dart';
import 'package:qr_attendx_mobile/features/onboarding/onboarding_controller.dart';
import 'package:qr_attendx_mobile/features/qr/qr_controller.dart';
import 'package:qr_attendx_mobile/models/user_profile_model.dart';
import 'package:qr_flutter/qr_flutter.dart';

const String _repositoryUrl = 'https://github.com/QR-AttendX/QRttendX_mobile';

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> with WidgetsBindingObserver {
  late final MobileScannerController _scannerController;
  late final QrController _qrController;

  bool _isOnQrTab = false;
  bool _isCameraRunning = false;
  bool _showMyQrCode = false;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerController = MobileScannerController(
      autoStart: false,
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
    _qrController = QrController();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    _qrController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    unawaited(_syncCameraState());
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (capture.barcodes.isEmpty) {
      return;
    }

    final rawValue = capture.barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) {
      return;
    }
    final attendanceController = context.read<AttendanceController>();

    await _qrController.processScan(
      rawValue: rawValue,
      attendanceController: attendanceController,
      resolveDuplicate: (candidateData, existingMatchData) {
        return handleDuplicateDetection(
          context: context,
          candidateData: candidateData,
          existingMatchData: existingMatchData,
        );
      },
    );
  }

  void _updateTabVisibility(bool isOnQrTab) {
    if (_isOnQrTab == isOnQrTab) {
      return;
    }
    _isOnQrTab = isOnQrTab;
    unawaited(_syncCameraState());
  }

  Future<void> _syncCameraState() async {
    final shouldRun = _isOnQrTab &&
        !_showMyQrCode &&
        _lifecycleState == AppLifecycleState.resumed;
    if (shouldRun == _isCameraRunning) {
      return;
    }

    _isCameraRunning = shouldRun;
    if (shouldRun) {
      await _scannerController.start();
    } else {
      await _scannerController.stop();
    }
  }

  Future<void> _toggleCamera() async {
    if (_showMyQrCode) {
      return;
    }
    await _scannerController.switchCamera();
  }

  void _toggleQrMode() {
    setState(() {
      _showMyQrCode = !_showMyQrCode;
    });
    unawaited(_syncCameraState());
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<QrController>.value(
      value: _qrController,
      child: Consumer<QrController>(
        builder: (context, controller, child) {
          final activeTabIndex =
              context.watch<NavigationStateController>().currentIndex;
          _updateTabVisibility(
            activeTabIndex == AppNavigationUtils.qrTabIndex,
          );

          final profile = context.watch<OnboardingController>().profile;
          final ownQrPayload = profile == null ? null : _buildOwnQrPayload(profile);

          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Expanded(
                  child: _showMyQrCode
                      ? _MyQrCodePanel(payload: ownQrPayload)
                      : _CameraPanel(
                          scannerController: _scannerController,
                          onDetect: _onDetect,
                        ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          controller.isProcessing
                              ? Icons.hourglass_top
                              : Icons.info_outline,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(controller.statusMessage),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: ownQrPayload == null ? null : _toggleQrMode,
                        icon: Icon(
                          _showMyQrCode
                              ? Icons.qr_code_scanner
                              : Icons.qr_code_2,
                        ),
                        label: Text(
                          _showMyQrCode
                              ? 'Use Scanner instead'
                              : 'Use QR Code instead',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _showMyQrCode ? null : _toggleCamera,
                        icon: const Icon(Icons.cameraswitch_outlined),
                        label: const Text('Rotate Camera'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  _OwnQrPayload _buildOwnQrPayload(UserProfileModel profile) {
    final payloadMap = <String, String>{
      'id': profile.id,
      'fullname': profile.fullName,
      'username': profile.username,
      'role': profile.role,
    };
    final payloadJson = jsonEncode(payloadMap);
    final qrData = '$_repositoryUrl?profile=${Uri.encodeComponent(payloadJson)}';
    return _OwnQrPayload(
      qrData: qrData,
      payloadJson: const JsonEncoder.withIndent('  ').convert(payloadMap),
    );
  }
}

class _CameraPanel extends StatelessWidget {
  const _CameraPanel({
    required this.scannerController,
    required this.onDetect,
  });

  final MobileScannerController scannerController;
  final void Function(BarcodeCapture) onDetect;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: MobileScanner(
          controller: scannerController,
          onDetect: onDetect,
        ),
      ),
    );
  }
}

class _MyQrCodePanel extends StatelessWidget {
  const _MyQrCodePanel({required this.payload});

  final _OwnQrPayload? payload;

  @override
  Widget build(BuildContext context) {
    if (payload == null) {
      return Card(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No local account profile found. Complete onboarding first.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: payload!.qrData,
                    size: 240,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ),
            Text(
              'Your local account QR payload (JSON):',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Text(
                payload!.payloadJson,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnQrPayload {
  const _OwnQrPayload({
    required this.qrData,
    required this.payloadJson,
  });

  final String qrData;
  final String payloadJson;
}
