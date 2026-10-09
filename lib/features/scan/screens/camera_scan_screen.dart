import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/camera_overlay_painter.dart';
import 'image_preview_screen.dart';

/// Màn hình Camera chụp hóa đơn (Phase 2)
/// Hỗ trợ: Camera Preview, Bật/tắt Flash, Chạm để lấy nét (Tap-to-focus),
/// Khung ngắm căn chỉnh hóa đơn, Chuyển camera và Chọn ảnh từ thư viện (fallback).
class CameraScanScreen extends StatefulWidget {
  const CameraScanScreen({super.key});

  @override
  State<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen> with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _selectedCameraIndex = 0;
  bool _isInitializing = true;
  String? _errorMessage;

  // Trạng thái Flash: off -> torch -> auto
  FlashMode _currentFlashMode = FlashMode.off;

  // Hiệu ứng lấy nét khi chạm vào màn hình (Tap-to-focus)
  Offset? _focusPoint;
  bool _showFocusIndicator = false;

  // Trạng thái đang chụp
  bool _isCapturing = false;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCameraController(cameraController.description);
    }
  }

  /// Khởi tạo và tìm danh sách camera khả dụng trên thiết bị
  Future<void> _initializeCamera() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Không tìm thấy camera trên thiết bị này.';
        });
        return;
      }

      // Ưu tiên chọn camera sau (back camera) để chụp văn bản rõ nét
      int backCameraIndex = _cameras.indexWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
      );
      _selectedCameraIndex = backCameraIndex != -1 ? backCameraIndex : 0;

      await _initializeCameraController(_cameras[_selectedCameraIndex]);
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Không thể truy cập camera: ${e.toString()}';
      });
    }
  }

  /// Cấu hình CameraController với độ phân giải cao phục vụ OCR
  Future<void> _initializeCameraController(CameraDescription cameraDescription) async {
    final controller = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
    );

    _controller = controller;

    try {
      await controller.initialize();
      await controller.setFlashMode(_currentFlashMode);
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } on CameraException catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Lỗi camera (${e.code}): ${e.description}';
        });
      }
    }
  }

  /// Chuyển đổi Flash: Tắt -> Bật đèn rọi (Torch) -> Tự động (Auto)
  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    FlashMode nextMode;
    switch (_currentFlashMode) {
      case FlashMode.off:
        nextMode = FlashMode.torch;
        break;
      case FlashMode.torch:
        nextMode = FlashMode.auto;
        break;
      default:
        nextMode = FlashMode.off;
        break;
    }

    try {
      await _controller!.setFlashMode(nextMode);
      setState(() {
        _currentFlashMode = nextMode;
      });
    } catch (_) {
      // Một số camera trước hoặc giả lập không hỗ trợ flash
    }
  }

  /// Chuyển đổi giữa camera trước và camera sau
  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    final nextIndex = (_selectedCameraIndex + 1) % _cameras.length;
    _selectedCameraIndex = nextIndex;
    await _controller?.dispose();
    _initializeCameraController(_cameras[_selectedCameraIndex]);
  }

  /// Xử lý lấy nét tại điểm chạm (Tap-to-focus & Exposure)
  Future<void> _handleTapToFocus(TapDownDetails details, BoxConstraints constraints) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );

    setState(() {
      _focusPoint = details.localPosition;
      _showFocusIndicator = true;
    });

    try {
      await _controller!.setFocusPoint(offset);
      await _controller!.setExposurePoint(offset);
    } catch (_) {}

    // Ẩn vòng tròn lấy nét sau 1.2 giây
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _showFocusIndicator = false;
        });
      }
    });
  }

  /// Chụp ảnh hóa đơn từ Camera
  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile photo = await _controller!.takePicture();
      if (!mounted) return;

      // Chuyển sang màn hình xem trước ảnh hóa đơn
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImagePreviewScreen(imagePath: photo.path),
        ),
      );
    } on CameraException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chụp ảnh thất bại: ${e.description}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  /// Chọn ảnh từ thư viện ảnh máy (Hỗ trợ khi camera không khả dụng hoặc test nhanh)
  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (image != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImagePreviewScreen(imagePath: image.path),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể chọn ảnh: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryLight),
            SizedBox(height: 16),
            Text(
              'Đang khởi động máy ảnh...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Trường hợp không có camera (máy ảo không có webcam hoặc web không cấp quyền)
    if (_errorMessage != null || _controller == null || !_controller!.value.isInitialized) {
      return _buildFallbackView();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        // Kích thước khung cắt hóa đơn ở giữa (tỉ lệ hóa đơn giấy dọc ~ 3:4)
        final cutoutWidth = screenWidth * 0.84;
        final cutoutHeight = cutoutWidth * 1.35;
        final cutoutRect = Rect.fromCenter(
          center: Offset(screenWidth / 2, screenHeight * 0.45),
          width: cutoutWidth,
          height: cutoutHeight,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            // 1. Camera Preview với Tap-to-focus
            GestureDetector(
              onTapDown: (details) => _handleTapToFocus(details, constraints),
              child: SizedBox(
                width: screenWidth,
                height: screenHeight,
                child: CameraPreview(_controller!),
              ),
            ),

            // 2. Khung viền Overlay căn hóa đơn
            CustomPaint(
              size: Size(screenWidth, screenHeight),
              painter: CameraOverlayPainter(cutoutRect: cutoutRect),
            ),

            // 3. Chỉ dẫn căn hóa đơn
            Positioned(
              top: cutoutRect.top - 40,
              left: 20,
              right: 20,
              child: const Center(
                child: Text(
                  'Căn chỉnh hóa đơn vuông góc trong khung',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(color: Colors.black, blurRadius: 4),
                    ],
                  ),
                ),
              ),
            ),

            // 4. Hiệu ứng chạm lấy nét (Focus Box Animation)
            if (_showFocusIndicator && _focusPoint != null)
              Positioned(
                left: _focusPoint!.dx - 28,
                top: _focusPoint!.dy - 28,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primaryLight, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

            // 5. Thanh công cụ phía trên (Top Bar): Nút Back, Flash, Chuyển camera
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCircleButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.pop(context),
                  ),
                  Row(
                    children: [
                      // Nút Flash
                      _buildCircleButton(
                        icon: _getFlashIcon(),
                        color: _currentFlashMode != FlashMode.off
                            ? Colors.amber
                            : Colors.white,
                        onPressed: _toggleFlash,
                      ),
                      if (_cameras.length > 1) ...[
                        const SizedBox(width: 12),
                        // Nút chuyển camera trước/sau
                        _buildCircleButton(
                          icon: Icons.flip_camera_ios_rounded,
                          onPressed: _switchCamera,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // 6. Thanh điều khiển phía dưới (Bottom Bar): Thư viện, Nút Chụp
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Nút Chọn ảnh từ thư viện
                  IconButton(
                    onPressed: _pickFromGallery,
                    icon: const Icon(
                      Icons.photo_library_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                    tooltip: 'Chọn ảnh từ bộ sưu tập',
                  ),

                  // Nút chụp ảnh chính (Shutter Button)
                  GestureDetector(
                    onTap: _isCapturing ? null : _capturePhoto,
                    child: Container(
                      width: 76,
                      height: 76,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _isCapturing ? Colors.white54 : AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: _isCapturing
                            ? const Padding(
                                padding: EdgeInsets.all(18.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),

                  // Placeholder cân đối thanh công cụ
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Giao diện dự phòng khi thiết bị không có camera phần cứng (hoặc máy ảo/trình duyệt)
  Widget _buildFallbackView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.no_photography_rounded,
              size: 54,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Camera chưa khả dụng',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Thiết bị hoặc môi trường hiện tại chưa hỗ trợ camera trực tiếp.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 28),

          // Nút chọn ảnh từ thư viện
          ElevatedButton.icon(
            onPressed: _pickFromGallery,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            icon: const Icon(Icons.photo_library_rounded),
            label: const Text('Chọn ảnh hóa đơn từ máy'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Quay lại', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  IconData _getFlashIcon() {
    switch (_currentFlashMode) {
      case FlashMode.off:
        return Icons.flash_off_rounded;
      case FlashMode.torch:
        return Icons.flash_on_rounded;
      case FlashMode.auto:
        return Icons.flash_auto_rounded;
      default:
        return Icons.flash_off_rounded;
    }
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color color = Colors.white,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 22),
        onPressed: onPressed,
      ),
    );
  }
}
