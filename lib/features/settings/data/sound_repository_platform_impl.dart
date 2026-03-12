import '../../../platform/guardian_platform_api.dart';
import '../../../platform/guardian_platform_models.dart';
import '../domain/sound_repository.dart';

class SoundRepositoryPlatformImpl implements SoundRepository {
  SoundRepositoryPlatformImpl({GuardianPlatformApi? api})
    : _api = api ?? GuardianPlatformApi.instance;

  final GuardianPlatformApi _api;

  @override
  Future<List<SoundProfileModel>> getSoundCatalog() => _api.getSoundCatalog();

  @override
  Future<bool> previewSound(String soundId) => _api.previewSound(soundId);

  @override
  Future<bool> stopSoundPreview() => _api.stopSoundPreview();
}
