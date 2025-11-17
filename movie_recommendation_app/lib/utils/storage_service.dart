import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:movie_recommendation_app/utils/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final _supabase = Supabase.instance.client;

  Future<String> uploadAvatar({
    required File imageFile,
    required String userId,
    bool isUpdate = false,
  }) async {
    try {
      final String fileExtension = p.extension(imageFile.path);
      final String fileName = '$userId$fileExtension';
      final String filePath = '$kUserImagesPath/$fileName';

      final Uint8List bytes = await imageFile.readAsBytes();

      await _supabase.storage.from(kAvatarsBucket).uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              upsert: isUpdate,
            ),
          );

      final String publicUrl =
          _supabase.storage.from(kAvatarsBucket).getPublicUrl(filePath);

      return publicUrl;
    } on StorageException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}
