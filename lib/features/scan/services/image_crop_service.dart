import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../core/constants/app_colors.dart';

/// Service xử lý cắt (crop) và xoay ảnh hóa đơn trước khi đưa vào OCR
class ImageCropService {
  ImageCropService._();

  static final ImageCropper _cropper = ImageCropper();

  /// Thực hiện cắt ảnh hóa đơn
  /// Trả về đường dẫn ảnh sau khi cắt, hoặc null nếu người dùng hủy
  static Future<String?> cropImage({
    required BuildContext context,
    required String sourcePath,
  }) async {
    try {
      final CroppedFile? croppedFile = await _cropper.cropImage(
        sourcePath: sourcePath,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Cắt Hóa Đơn',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            statusBarLight: false,
            activeControlsWidgetColor: AppColors.primaryLight,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          IOSUiSettings(
            title: 'Cắt Hóa Đơn',
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
            size: const CropperSize(width: 500, height: 500),
          ),
        ],
      );

      return croppedFile?.path;
    } catch (e) {
      debugPrint('Lỗi trong quá trình cắt ảnh: $e');
      return null;
    }
  }
}
