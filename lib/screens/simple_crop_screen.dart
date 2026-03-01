import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'dart:typed_data';
import '../theme/app_theme.dart';

class SimpleCropScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final Function(dynamic) onCropped;

  const SimpleCropScreen({
    super.key,
    required this.imageBytes,
    required this.onCropped,
  });

  @override
  State<SimpleCropScreen> createState() => _SimpleCropScreenState();
}

class _SimpleCropScreenState extends State<SimpleCropScreen> {
  final CropController _cropController = CropController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Crop Photo',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _cropController.crop(),
            child: const Text(
              'Done',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Crop(
                    image: widget.imageBytes,
                    controller: _cropController,
                    onCropped: (cropResult) {
                      widget.onCropped(cropResult);
                      Navigator.pop(context);
                    },
                    aspectRatio: 1.0,
                    maskColor: Colors.black.withOpacity(0.6),
                    baseColor: Colors.white,
                    fixCropRect: false,
                    withCircleUi: false,
                    cornerDotBuilder: (size, edgeAlignment) => Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppTheme.primaryColor, width: 3),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Drag the corners to adjust your crop area',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}