import 'dart:io';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'home_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const _bg = Color(0xFF101622);
const _blue = Color(0xFF135BEC);
const _slateDark = Color(0xFF0F172A);
const _slateCard = Color(0xFF1E293B);
const _textSecondary = Color(0xFF94A3B8);

const _baseUrl = String.fromEnvironment('BASE_URL', defaultValue: 'http://10.0.2.2:8000');

const _districts = [
  'Tagamoa',
  'Maadi',
  'Zamalek',
  'Heliopolis',
  'Nasr City',
  'New Cairo',
  'Dokki',
  'Mohandessin',
  'Downtown Cairo',
  'Ain Shams',
  'Shubra',
  'October City',
  'Sheikh Zayed',
];

// ─────────────────────────────────────────────────────────────────────────────
// FoundScreen
// ─────────────────────────────────────────────────────────────────────────────

class FoundScreen extends StatefulWidget {
  const FoundScreen({super.key});

  @override
  State<FoundScreen> createState() => _FoundScreenState();
}

class _FoundScreenState extends State<FoundScreen> {
  // ── State ──────────────────────────────────────────────────────────────────

  final List<File> _photos = [];
  String? _selectedDistrict;
  final TextEditingController _descCtrl = TextEditingController();
  bool _isSubmitting = false;
  bool _isRecording = false;

  // ── Services ───────────────────────────────────────────────────────────────

  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));
  final _storage = const FlutterSecureStorage();
  final _recorder = FlutterSoundRecorder();
  String? _recordingPath;
  bool _recorderReady = false;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _openRecorder();
  }

  Future<void> _openRecorder() async {
    try {
      await _recorder.openRecorder();
      setState(() => _recorderReady = true);
    } catch (_) {
      // flutter_sound not available or permission denied at init — handle at use time
    }
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── Derived state ──────────────────────────────────────────────────────────

  /// Number of slots that should be visible (progressive reveal up to 5).
  int get _visibleSlots => (_photos.length + 1).clamp(1, 5);

  // ── Photo logic ────────────────────────────────────────────────────────────

  Future<void> _tapSlot(int slotIndex) async {
    // Only the first empty slot (the "next" slot) is tappable.
    if (slotIndex != _photos.length) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: _slateDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _PhotoSourceSheet(),
    );
    if (source == null || !mounted) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _photos.add(File(picked.path)));
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  // ── Voice logic ────────────────────────────────────────────────────────────

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopAndTranscribe();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _snackbar('Microphone permission denied');
      return;
    }

    if (!_recorderReady) {
      _snackbar('Recorder not ready. Please try again.');
      return;
    }

    final dir = await getTemporaryDirectory();
    _recordingPath = '${dir.path}/ifind_voice_${DateTime.now().millisecondsSinceEpoch}.aac';

    await _recorder.startRecorder(
      toFile: _recordingPath,
      codec: Codec.aacADTS,
    );

    setState(() => _isRecording = true);
  }

  Future<void> _stopAndTranscribe() async {
    await _recorder.stopRecorder();
    setState(() => _isRecording = false);

    final path = _recordingPath;
    if (path == null) return;

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(path, filename: 'voice.aac'),
      });
      final response = await _dio.post('$_baseUrl/ai/transcribe-voice', data: formData);
      final transcription = (response.data as Map<String, dynamic>)['transcription'] as String? ?? '';
      if (transcription.isNotEmpty && mounted) {
        final current = _descCtrl.text;
        final joined = current.isEmpty ? transcription : '$current $transcription';
        setState(() {
          _descCtrl.value = TextEditingValue(
            text: joined,
            selection: TextSelection.collapsed(offset: joined.length),
          );
        });
      }
    } on DioException {
      _snackbar('Voice transcription failed. Please type manually.');
    }
  }

  // ── Submit logic ───────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_photos.isEmpty) {
      _snackbar('Please add at least one photo');
      return;
    }
    if (_selectedDistrict == null) {
      _snackbar('Please select a district');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        _snackbar('Session expired — please log in again');
        return;
      }

      // Build multipart: "photos" key repeated for each file (Dio list support)
      final photoFiles = await Future.wait(
        _photos.map(
          (f) => MultipartFile.fromFile(
            f.path,
            filename: f.path.split(Platform.pathSeparator).last,
          ),
        ),
      );

      final formData = FormData.fromMap({
        'photos': photoFiles,
        'district': _selectedDistrict!,
        'description': _descCtrl.text.trim(),
      });

      final response = await _dio.post(
        '$_baseUrl/items/found/photo',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 201) {
        _snackbar('Item reported successfully!', success: true);
        setState(() {
          _photos.clear();
          _selectedDistrict = null;
          _descCtrl.clear();
        });
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = (data is Map) ? (data['detail'] ?? 'Submission failed') : 'Submission failed';
      _snackbar(msg.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── District sheet ─────────────────────────────────────────────────────────

  Future<void> _showDistrictSheet() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _slateDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DistrictSheet(current: _selectedDistrict),
    );
    if (selected != null && mounted) {
      setState(() => _selectedDistrict = selected);
    }
  }

  // ── Snackbar helper ────────────────────────────────────────────────────────

  void _snackbar(String message, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.manrope(color: Colors.white)),
        backgroundColor: success ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // Custom top bar — no AppBar
            _TopBar(onBack: () => Navigator.pop(context)),

            // Scrollable form body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Photo grid
                    _PhotoHeader(count: _photos.length),
                    const SizedBox(height: 12),
                    _PhotoGrid(
                      photos: _photos,
                      visibleSlots: _visibleSlots,
                      onTapSlot: _tapSlot,
                      onRemove: _removePhoto,
                    ),

                    const SizedBox(height: 28),

                    // District dropdown
                    const _SectionLabel('Where did you find it?'),
                    const SizedBox(height: 10),
                    _DistrictField(
                      selected: _selectedDistrict,
                      onTap: _showDistrictSheet,
                    ),

                    const SizedBox(height: 28),

                    // Description + mic
                    const _SectionLabel('Describe the item'),
                    const SizedBox(height: 10),
                    _DescriptionField(
                      controller: _descCtrl,
                      isRecording: _isRecording,
                      onMicTap: _toggleRecording,
                    ),

                    const SizedBox(height: 36),

                    // Submit
                    _ConfirmButton(
                      isLoading: _isSubmitting,
                      onTap: _submit,
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom nav
            _BottomNav(onHomeTap: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TopBar
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 20, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _slateCard,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          Text(
            'iFind',
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _blue,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Photo section
// ─────────────────────────────────────────────────────────────────────────────

class _PhotoHeader extends StatelessWidget {
  final int count;
  const _PhotoHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Add photos',
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        Text(
          '$count/5',
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _blue,
          ),
        ),
      ],
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  final List<File> photos;
  final int visibleSlots;
  final void Function(int) onTapSlot;
  final void Function(int) onRemove;

  const _PhotoGrid({
    required this.photos,
    required this.visibleSlots,
    required this.onTapSlot,
    required this.onRemove,
  });

  Widget _slot(int i) => _PhotoSlot(
        index: i,
        file: i < photos.length ? photos[i] : null,
        isNextSlot: i == photos.length,
        onTap: () => onTapSlot(i),
        onRemove: () => onRemove(i),
      );

  Widget _visibilityWrapped(int i, {double rightPad = 0}) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: rightPad),
        child: Visibility(
          visible: i < visibleSlots,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: _slot(i),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top row: slots 0, 1, 2
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _visibilityWrapped(0, rightPad: 8),
            _visibilityWrapped(1, rightPad: 8),
            _visibilityWrapped(2),
          ],
        ),
        // Bottom row: slots 3, 4 — only rendered once 4th slot unlocks
        if (visibleSlots > 3) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _visibilityWrapped(3, rightPad: 8),
              _visibilityWrapped(4),
            ],
          ),
        ],
      ],
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  final int index;
  final File? file;
  final bool isNextSlot; // the one that opens picker on tap
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _PhotoSlot({
    required this.index,
    required this.file,
    required this.isNextSlot,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isFilled = file != null;

    return AspectRatio(
      aspectRatio: 1,
      child: GestureDetector(
        onTap: isNextSlot ? onTap : null,
        child: Stack(
          children: [
            // Background + image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: _slateCard,
                child: isFilled
                    ? Image.file(file!, fit: BoxFit.cover)
                    : isNextSlot
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.camera_alt_outlined,
                                color: _textSecondary,
                                size: 26,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tap to take\na photo',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.manrope(
                                  fontSize: 10,
                                  color: _textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          )
                        : null,
              ),
            ),

            // Dashed / solid border overlay
            Positioned.fill(
              child: CustomPaint(
                painter: _SlotBorderPainter(
                  color: isFilled
                      ? _blue.withValues(alpha: 0.7)
                      : _textSecondary.withValues(alpha: 0.35),
                  dashed: !isFilled,
                  borderRadius: 12,
                ),
              ),
            ),

            // Remove button
            if (isFilled)
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 13),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Paints a rounded-rect border, optionally dashed.
class _SlotBorderPainter extends CustomPainter {
  final Color color;
  final bool dashed;
  final double borderRadius;

  const _SlotBorderPainter({
    required this.color,
    required this.dashed,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    const inset = 0.7; // half stroke width
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2),
      Radius.circular(borderRadius),
    );

    if (!dashed) {
      canvas.drawRRect(rrect, paint);
      return;
    }

    // Dashed path
    final path = Path()..addRRect(rrect);
    final dashPath = Path();
    const dashLen = 5.0;
    const gapLen = 4.0;

    for (final metric in path.computeMetrics()) {
      double dist = 0;
      bool drawing = true;
      while (dist < metric.length) {
        final segLen = drawing ? dashLen : gapLen;
        final end = (dist + segLen).clamp(0.0, metric.length);
        if (drawing) {
          dashPath.addPath(metric.extractPath(dist, end), Offset.zero);
        }
        dist += segLen;
        drawing = !drawing;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(_SlotBorderPainter old) =>
      color != old.color || dashed != old.dashed;
}

// ─────────────────────────────────────────────────────────────────────────────
// District section
// ─────────────────────────────────────────────────────────────────────────────

class _DistrictField extends StatelessWidget {
  final String? selected;
  final VoidCallback onTap;

  const _DistrictField({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: _slateCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _textSecondary.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selected ?? 'Select District',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: selected != null ? Colors.white : _textSecondary,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: _textSecondary, size: 22),
          ],
        ),
      ),
    );
  }
}

class _DistrictSheet extends StatelessWidget {
  final String? current;
  const _DistrictSheet({this.current});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.85,
      minChildSize: 0.4,
      expand: false,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: _slateDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Select District',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.07)),
              Expanded(
                child: ListView.separated(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: _districts.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.white.withValues(alpha: 0.05)),
                  itemBuilder: (_, i) {
                    final d = _districts[i];
                    final isActive = d == current;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      title: Text(
                        d,
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          color: isActive ? _blue : Colors.white,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                      trailing: isActive
                          ? const Icon(Icons.check_rounded, color: _blue, size: 20)
                          : null,
                      onTap: () => Navigator.pop(ctx, d),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Description section
// ─────────────────────────────────────────────────────────────────────────────

class _DescriptionField extends StatelessWidget {
  final TextEditingController controller;
  final bool isRecording;
  final VoidCallback onMicTap;

  const _DescriptionField({
    required this.controller,
    required this.isRecording,
    required this.onMicTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: _slateCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRecording
                  ? _blue.withValues(alpha: 0.5)
                  : _textSecondary.withValues(alpha: 0.18),
            ),
          ),
          child: Stack(
            children: [
              TextField(
                controller: controller,
                maxLines: 5,
                minLines: 5,
                style: GoogleFonts.manrope(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Describe what you found — colour, brand, size…',
                  hintStyle: GoogleFonts.manrope(
                    color: _textSecondary,
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  // bottom-right space reserved for mic button
                  contentPadding: const EdgeInsets.fromLTRB(16, 14, 50, 44),
                ),
              ),
              // Mic button — bottom right
              Positioned(
                bottom: 10,
                right: 12,
                child: GestureDetector(
                  onTap: onMicTap,
                  behavior: HitTestBehavior.opaque,
                  child: isRecording
                      ? const Icon(Icons.mic_rounded, color: _blue, size: 26)
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scaleXY(
                            begin: 1.0,
                            end: 1.35,
                            duration: 550.ms,
                            curve: Curves.easeInOut,
                          )
                      : const Icon(Icons.mic_rounded, color: _textSecondary, size: 26),
                ),
              ),
            ],
          ),
        ),
        if (isRecording)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: _blue,
                    shape: BoxShape.circle,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fadeIn(duration: 500.ms),
                const SizedBox(width: 6),
                Text(
                  'Recording… tap mic to stop',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: _blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Confirm & Save button
// ─────────────────────────────────────────────────────────────────────────────

class _ConfirmButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _ConfirmButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _blue,
          disabledBackgroundColor: _blue.withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.2,
                ),
              )
            : Text(
                'Confirm & Save',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom nav bar
// ─────────────────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final VoidCallback onHomeTap;
  const _BottomNav({required this.onHomeTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _slateDark,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                label: 'Home',
                active: false,
                onTap: onHomeTap,
              ),
              _NavItem(
                icon: Icons.add_circle_outline_rounded,
                label: 'I Found',
                active: true,
                onTap: () {},
              ),
              _NavItem(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Chat',
                active: false,
                onTap: () {},
              ),
              _NavItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                active: false,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? _blue : _textSecondary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Photo source bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _PhotoSourceSheet extends StatelessWidget {
  const _PhotoSourceSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Add a Photo',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          _SourceTile(
            icon: Icons.camera_alt_outlined,
            label: 'Take a photo',
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          const SizedBox(height: 10),
          _SourceTile(
            icon: Icons.photo_library_outlined,
            label: 'Choose from gallery',
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: _slateCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: _blue, size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.manrope(fontSize: 15, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared label widget
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }
}
