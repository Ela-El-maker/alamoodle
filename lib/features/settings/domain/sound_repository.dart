import '../../../platform/guardian_platform_models.dart';

abstract class SoundRepository {
  Future<List<SoundProfileModel>> getSoundCatalog();
  Future<bool> previewSound(String soundId);
  Future<bool> stopSoundPreview();
}
