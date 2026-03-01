import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'dart:io';
import 'dart:typed_data';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import '../services/user_service.dart';
import '../services/photo_service.dart';

class EditPhotosScreen extends StatefulWidget {
  final List<String>? currentPhotos;
  
  const EditPhotosScreen({super.key, this.currentPhotos});

  @override
  State<EditPhotosScreen> createState() => _EditPhotosScreenState();
}

class _EditPhotosScreenState extends State<EditPhotosScreen> {
  final List<dynamic> _photos = [null, null, null, null];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentPhotos();
  }

  void _loadCurrentPhotos() {
    if (widget.currentPhotos != null) {
      for (int i = 0; i < widget.currentPhotos!.length && i < 4; i++) {
        _photos[i] = widget.currentPhotos![i];
      }
    }
  }

  Future<void> _pickImage(int index) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        print('Image selected: ${image.path}');
        final imageBytes = await image.readAsBytes();
        print('Image bytes loaded: ${imageBytes.length}');
        if (mounted) {
          print('Navigating to crop screen...');
          final result = await Navigator.push<dynamic>(
            context,
            MaterialPageRoute(
              builder: (context) => _CropScreen(
                imageBytes: imageBytes,
                onCropped: (croppedData) {
                  print('Image cropped');
                  _saveCroppedImage(index, croppedData);
                },
              ),
            ),
          );
          print('Returned from crop screen');
        }
      } else {
        print('No image selected');
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  void _saveCroppedImage(int index, dynamic croppedData) async {
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await file.writeAsBytes(croppedData);
    setState(() {
      _photos[index] = file;
    });
  }

  void _removePhoto(int index) {
    setState(() {
      _photos[index] = null;
    });
  }

  int get _photoCount => _photos.where((photo) => photo != null).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Photos',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update your photos',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add up to 4 photos (minimum 2 required)',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              
              // Test button
              ElevatedButton(
                onPressed: () {
                  // Test with a simple image
                  final testBytes = Uint8List.fromList([137, 80, 78, 71]); // PNG header
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => _CropScreen(
                        imageBytes: testBytes,
                        onCropped: (data) => print('Test crop done'),
                      ),
                    ),
                  );
                },
                child: Text('Test Crop Screen'),
              ),
              const SizedBox(height: 16),
              
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    final photo = _photos[index];
                    
                    return GestureDetector(
                      onTap: () {
                        print('Photo slot $index tapped');
                        _pickImage(index);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: photo != null ? AppTheme.primaryColor : Colors.grey.shade300,
                            width: photo != null ? 2 : 1,
                          ),
                        ),
                        child: photo != null
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: photo is File
                                    ? Image.file(
                                        photo,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      )
                                    : Image.network(
                                        photo,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () => _removePhoto(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                if (index == 0)
                                  Positioned(
                                    bottom: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'Main',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
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
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.add_photo_alternate,
                                    size: 32,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  index == 0 ? 'Main Photo' : 'Add Photo',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                      ),
                    );
                  },
                ),
              ),
              
              if (_photoCount > 0) ...[
                Text(
                  '$_photoCount/4 photos',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              LoadingButton(
                isLoading: _isLoading,
                text: _isLoading ? 'Updating Photos...' : 'Save Changes',
                onPressed: () async {
                  if (_photoCount < 2) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please add at least 2 photos')),
                    );
                    return;
                  }
                  
                  setState(() => _isLoading = true);
                  
                  try {
                    final List<String> allUrls = [];
                    final List<File> filesToUpload = [];
                    final List<int> fileIndices = [];
                    
                    // First pass: collect files to upload and their positions
                    for (int i = 0; i < _photos.length; i++) {
                      final photo = _photos[i];
                      if (photo is File) {
                        filesToUpload.add(photo);
                        fileIndices.add(i);
                      }
                    }
                    
                    // Upload new files
                    List<String> uploadedUrls = [];
                    if (filesToUpload.isNotEmpty) {
                      uploadedUrls = await PhotoService.uploadMultiplePhotos(filesToUpload);
                    }
                    
                    // Build final URLs list in correct order
                    int uploadIndex = 0;
                    for (int i = 0; i < _photos.length; i++) {
                      final photo = _photos[i];
                      if (photo is String) {
                        allUrls.add(photo);
                      } else if (photo is File && uploadIndex < uploadedUrls.length) {
                        allUrls.add(uploadedUrls[uploadIndex]);
                        uploadIndex++;
                      }
                    }
                    
                    await UserService.updateUserProfile(
                      photoUrls: allUrls,
                      profileImageUrl: allUrls.isNotEmpty ? allUrls.first : null,
                    );
                    
                    if (mounted) {
                      Navigator.pop(context, true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Photos updated successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating photos: $e')),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CropScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final Function(dynamic) onCropped;

  const _CropScreen({
    required this.imageBytes,
    required this.onCropped,
  });

  @override
  State<_CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<_CropScreen> {
  final CropController _cropController = CropController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Crop Photo'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => _cropController.crop(),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Crop(
          image: widget.imageBytes,
          controller: _cropController,
          onCropped: (cropResult) {
            widget.onCropped(cropResult);
            Navigator.pop(context);
          },
          aspectRatio: 1.0,
          withCircleUi: false,
          maskColor: Colors.black.withOpacity(0.8),
          baseColor: Colors.black,
          radius: 20,
          interactive: true,
        ),
      ),
    );
  }
}