import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhotoService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<String?> uploadProfilePhoto(File photo, {int index = 0}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      final fileName = 'profile_${index}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('users/${user.uid}/photos/$fileName');
      
      final uploadTask = ref.putFile(photo);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading photo: $e');
      return null;
    }
  }

  static Future<List<String>> uploadMultiplePhotos(List<File> photos) async {
    final List<String> urls = [];
    
    for (int i = 0; i < photos.length; i++) {
      final url = await uploadProfilePhoto(photos[i], index: i);
      if (url != null) {
        urls.add(url);
      }
    }
    
    return urls;
  }

  static Future<void> deletePhoto(String photoUrl) async {
    try {
      final ref = _storage.refFromURL(photoUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting photo: $e');
    }
  }
}