import 'package:alarmmaster/features/settings/domain/sound_repository.dart';
import 'package:alarmmaster/features/settings/state/sound_controller.dart';
import 'package:alarmmaster/platform/guardian_platform_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sound controller returns native-backed catalog', () async {
    final controller = SoundController(_FakeSoundRepository());

    final sounds = await controller.getSoundCatalog();

    expect(sounds, hasLength(1));
    expect(sounds.first.id, 'default_alarm');
  });

  test('sound preview delegates to repository', () async {
    final repo = _FakeSoundRepository();
    final controller = SoundController(repo);

    final ok = await controller.previewSound('default_alarm');
    await controller.stopSoundPreview();

    expect(ok, isTrue);
    expect(repo.lastPreviewId, 'default_alarm');
    expect(repo.stopCalled, isTrue);
  });
}

class _FakeSoundRepository implements SoundRepository {
  String? lastPreviewId;
  bool stopCalled = false;

  @override
  Future<List<SoundProfileModel>> getSoundCatalog() async {
    return const [
      SoundProfileModel(
        id: 'default_alarm',
        name: 'Default Alarm',
        tag: 'Classic',
        category: 'recommended',
        vibrationProfileIds: ['default', 'strong'],
      ),
    ];
  }

  @override
  Future<bool> previewSound(String soundId) async {
    lastPreviewId = soundId;
    return true;
  }

  @override
  Future<bool> stopSoundPreview() async {
    stopCalled = true;
    return true;
  }
}
