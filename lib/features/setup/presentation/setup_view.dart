import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/file_reader_facade.dart';
import '../providers/setup_provider.dart';

class SetupView extends ConsumerStatefulWidget {
  const SetupView({super.key});

  @override
  ConsumerState<SetupView> createState() => _SetupViewState();
}

class _SetupViewState extends ConsumerState<SetupView> {
  final TextEditingController _urlController      = TextEditingController();
  final TextEditingController _driveUrlController = TextEditingController();
  List<CameraDescription> _availableCameras = [];
  bool _isLoadingCameras = true;
  String? _cameraPermissionError;
  bool _configLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadCameras();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Isi text field dari konfigurasi yang tersimpan (hanya sekali)
    if (!_configLoaded) {
      _configLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final cfg = ref.read(setupProvider);
        if (cfg.scriptUrl != null && cfg.scriptUrl!.isNotEmpty) {
          _urlController.text = cfg.scriptUrl!;
        }
        // Tampilkan folder ID sebagai Drive URL di field Drive
        if (cfg.folderId != null && cfg.folderId!.isNotEmpty) {
          _driveUrlController.text =
              'https://drive.google.com/drive/folders/${cfg.folderId}';
        }
      });
    }
  }

  Future<void> _loadCameras() async {
    setState(() {
      _isLoadingCameras = true;
      _cameraPermissionError = null;
    });

    try {
      final cameras = await availableCameras();
      if (mounted) {
        setState(() {
          _availableCameras = cameras;
          _isLoadingCameras = false;
        });

        if (cameras.isNotEmpty && ref.read(setupProvider).selectedCamera == null) {
          final defaultCam = cameras.firstWhere(
            (cam) => cam.lensDirection == CameraLensDirection.front,
            orElse: () => cameras.first,
          );
          ref.read(setupProvider.notifier).setSelectedCamera(defaultCam);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCameras = false;
          _cameraPermissionError =
              'Izin kamera belum diberikan atau diblokir oleh Browser/OS. Pastikan izin kamera telah diizinkan.';
        });
      }
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _driveUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickTemplateFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final bytes = await readFileBytesSafe(
        directBytes: file.bytes,
        path: file.path,
      );
      if (bytes != null) {
        await ref.read(setupProvider.notifier).setTemplateBytes(bytes);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final setupConfig = ref.watch(setupProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.6, -0.6),
            radius: 1.3,
            colors: [
              Color(0xFF1E1035),
              Color(0xFF0F0B18),
              Color(0xFF07050B),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1050),
                decoration: BoxDecoration(
                  color: const Color(0xFF141220).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFFFF4081).withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF4081).withValues(alpha: 0.12),
                      blurRadius: 45,
                      spreadRadius: 2,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.7),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(36.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Section
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF4081), Color(0xFF7C4DFF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF4081).withValues(alpha: 0.4),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.camera, color: Colors.white, size: 32),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'DiPHOTO Studio Console',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Siapkan konfigurasi hardware kamera, template desain frame, & cloud storage drive.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: setupConfig.isReady
                                  ? const Color(0xFF00E676).withValues(alpha: 0.15)
                                  : Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: setupConfig.isReady ? const Color(0xFF00E676) : Colors.amber,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  setupConfig.isReady ? Icons.check_circle : Icons.pending,
                                  color: setupConfig.isReady ? const Color(0xFF00E676) : Colors.amber,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  setupConfig.isReady ? 'READY TO SHOOT' : 'SETUP REQUIRED',
                                  style: TextStyle(
                                    color: setupConfig.isReady ? const Color(0xFF00E676) : Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Divider(color: Color(0xFF2A243D), height: 1),
                      const SizedBox(height: 32),

                      // Two Column Layout for Tablet
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column: Camera & Google Drive
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 1. Camera Selector Card
                                _buildSectionHeader(
                                  number: '1',
                                  title: 'Pilih Input Kamera',
                                  subtitle: 'Kamera laptop, webcam internal atau kamera eksternal USB',
                                ),
                                const SizedBox(height: 12),
                                _isLoadingCameras
                                    ? Container(
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E1A2E),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: Color(0xFFFF4081),
                                            strokeWidth: 3,
                                          ),
                                        ),
                                      )
                                    : _cameraPermissionError != null
                                        ? Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.redAccent.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(Icons.error_outline, color: Colors.redAccent),
                                                    const SizedBox(width: 10),
                                                    const Expanded(
                                                      child: Text(
                                                        'Akses Kamera Dibatasi / Ditolak',
                                                        style: TextStyle(
                                                          color: Colors.redAccent,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.refresh, color: Colors.white70),
                                                      onPressed: _loadCameras,
                                                      tooltip: 'Muat Ulang Kamera',
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  _cameraPermissionError!,
                                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          )
                                        : _availableCameras.isEmpty
                                            ? Container(
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(16),
                                                  border: Border.all(color: Colors.amber),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.videocam_off, color: Colors.amber),
                                                    const SizedBox(width: 12),
                                                    const Expanded(
                                                      child: Text(
                                                        'Tidak ada kamera ditemukan. Hubungkan webcam atau aktifkan izin kamera perangkat / browser.',
                                                        style: TextStyle(color: Colors.amber, fontSize: 13),
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.refresh, color: Colors.amber),
                                                      onPressed: _loadCameras,
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : DropdownButtonFormField<CameraDescription>(
                                                initialValue: setupConfig.selectedCamera ?? _availableCameras.first,
                                                isExpanded: true,
                                                dropdownColor: const Color(0xFF1E1A2E),
                                                decoration: InputDecoration(
                                                  filled: true,
                                                  fillColor: const Color(0xFF1E1A2E),
                                                  prefixIcon: const Icon(Icons.videocam, color: Color(0xFFFF4081)),
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(16),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                ),
                                                items: _availableCameras.map((cam) {
                                                  String label = cam.name;
                                                  if (cam.lensDirection == CameraLensDirection.front) {
                                                    label += ' (Kamera Depan / Internal)';
                                                  } else if (cam.lensDirection == CameraLensDirection.back) {
                                                    label += ' (Kamera Belakang)';
                                                  } else if (cam.lensDirection == CameraLensDirection.external) {
                                                    label += ' (Webcam Eksternal USB)';
                                                  }
                                                  return DropdownMenuItem<CameraDescription>(
                                                    value: cam,
                                                    child: Text(label, overflow: TextOverflow.ellipsis),
                                                  );
                                                }).toList(),
                                                onChanged: (cam) {
                                                  ref.read(setupProvider.notifier).setSelectedCamera(cam);
                                                },
                                              ),
                                const SizedBox(height: 28),

                                // 2. Google Apps Script Web App URL
                                _buildSectionHeader(
                                  number: '2',
                                  title: 'Google Apps Script URL',
                                  subtitle: 'Deployment Web App URL dari script.google.com',
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _urlController,
                                  onChanged: (val) => ref.read(setupProvider.notifier).setScriptUrl(val),
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'https://script.google.com/macros/s/.../exec',
                                    hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                    filled: true,
                                    fillColor: const Color(0xFF1E1A2E),
                                    prefixIcon: const Icon(Icons.code_rounded, color: Color(0xFF00E676)),
                                    suffixIcon: setupConfig.scriptUrl != null && setupConfig.scriptUrl!.isNotEmpty
                                        ? const Tooltip(
                                            message: 'Tersimpan otomatis',
                                            child: Icon(Icons.cloud_done, color: Color(0xFF00E676)),
                                          )
                                        : null,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // 3. Google Drive Folder Target
                                _buildSectionHeader(
                                  number: '3',
                                  title: 'Google Drive Folder Target',
                                  subtitle: 'URL folder publik tempat menyimpan foto tamu',
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _driveUrlController,
                                  onChanged: (val) => ref.read(setupProvider.notifier).setGoogleDriveUrl(val),
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'https://drive.google.com/drive/folders/1A2B3C...',
                                    hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                    filled: true,
                                    fillColor: const Color(0xFF1E1A2E),
                                    prefixIcon: const Icon(Icons.cloud_queue, color: Color(0xFF00E676)),
                                    suffixIcon: setupConfig.folderId != null
                                        ? const Tooltip(
                                            message: 'Tersimpan otomatis',
                                            child: Icon(Icons.cloud_done, color: Color(0xFF00E676)),
                                          )
                                        : null,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                if (setupConfig.folderId != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00E676).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'ID Terdeteksi: ${setupConfig.folderId}',
                                      style: const TextStyle(
                                        color: Color(0xFF00E676),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 36),

                          // Right Column: Template Frame & Preview
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader(
                                  number: '4',
                                  title: 'Template Frame PNG (1200x1800)',
                                  subtitle: 'PNG transparan dengan 2 slot lubang foto',
                                ),
                                const SizedBox(height: 12),
                                InkWell(
                                  onTap: _pickTemplateFile,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    height: 200,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E1A2E),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: setupConfig.templatePngBytes != null
                                            ? const Color(0xFFFF4081)
                                            : const Color(0xFF352F4F),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: setupConfig.templatePngBytes != null
                                        ? Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(18),
                                                child: Image.memory(
                                                  setupConfig.templatePngBytes!,
                                                  fit: BoxFit.contain,
                                                  height: 180,
                                                ),
                                              ),
                                              Positioned(
                                                bottom: 10,
                                                right: 10,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black.withValues(alpha: 0.75),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.edit, color: Colors.white70, size: 14),
                                                      SizedBox(width: 4),
                                                      Text('Ganti', style: TextStyle(color: Colors.white, fontSize: 12)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFF4081).withValues(alpha: 0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.add_photo_alternate_outlined,
                                                  color: Color(0xFFFF4081),
                                                  size: 36,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              const Text(
                                                'Upload File Template PNG',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Klik untuk memilih dari penyimpanan',
                                                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                                if (setupConfig.templatePngBytes != null) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7C4DFF).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFF7C4DFF).withValues(alpha: 0.5)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.auto_awesome, color: Color(0xFFFF4081), size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            setupConfig.detectedSlots != null
                                                ? 'Terdeteksi ${setupConfig.detectedSlots!.length} slot foto (${setupConfig.photoCount}x jepretan)'
                                                : 'Mode Standar (2 slot foto atas-bawah)',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // Start Action Button
                      Container(
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: setupConfig.isReady
                              ? const LinearGradient(
                                  colors: [Color(0xFFFF4081), Color(0xFF7C4DFF)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                )
                              : null,
                          boxShadow: setupConfig.isReady
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFFF4081).withValues(alpha: 0.4),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ]
                              : [],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: setupConfig.isReady ? () => context.go('/booth') : null,
                          icon: const Icon(Icons.rocket_launch, size: 26),
                          label: Text(
                            'MULAI MESIN PHOTOBOOTH (${setupConfig.photoCount} FOTO)',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFF1E1A2E),
                            disabledForegroundColor: Colors.grey.shade600,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required String number, required String title, required String subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFF4081).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFF4081), width: 1.2),
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: Color(0xFFFF4081),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


