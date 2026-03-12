import '../../../platform/guardian_platform_models.dart';
import '../domain/sound_repository.dart';

class SoundController {
  SoundController(this._repository);

  final SoundRepository _repository;

  Future<List<SoundProfileModel>> getSoundCatalog() =>
      _repository.getSoundCatalog();

  Future<bool> previewSound(String soundId) =>
      _repository.previewSound(soundId);

  Future<bool> stopSoundPreview() => _repository.stopSoundPreview();
}
