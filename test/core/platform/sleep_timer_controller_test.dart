import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lizunemu/core/audio/i_audio_player_service.dart';
import 'package:lizunemu/core/platform/sleep_timer_controller.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';

/// 仅记录 pause() / setVolume；其余接口测试不触达 → noSuchMethod 抛错暴露误用。
class _FakeAudioService implements IAudioPlayerService {
  int pauseCount = 0;
  double _volume = 1.0;

  @override
  double get volume => _volume;

  @override
  Future<void> pause({bool fade = true}) async => pauseCount++;

  @override
  Future<void> setVolume(double volume, {bool persist = true}) async {
    _volume = volume;
  }

  double _speed = 1.0;

  @override
  double get playbackSpeed => _speed;

  @override
  Future<void> setPlaybackSpeed(double speed, {bool persist = true}) async {
    _speed = speed;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('未预期调用: ${invocation.memberName}');
}

void main() {
  late _FakeAudioService audio;
  late AppSettingsService settings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    settings = AppSettingsService(prefs);
    audio = _FakeAudioService();
  });

  SleepTimerController controller() => SleepTimerController(audio, settings);

  group('SleepTimerController', () {
    test('初始状态：未设置、未激活、不暂停', () {
      final c = controller();
      expect(c.minutes, isNull);
      expect(c.isActive, isFalse);
      expect(audio.pauseCount, 0);
    });

    test('setMinutes 设定时长 → minutes/isActive 反映', () {
      final c = controller();
      c.setMinutes(30);
      expect(c.minutes, 30);
      expect(c.isActive, isTrue);
    });

    test('setMinutes(null) / cancel() 取消并复位', () {
      final c = controller();
      c.setMinutes(30);
      c.setMinutes(null);
      expect(c.minutes, isNull);
      expect(c.isActive, isFalse);

      c.setMinutes(45);
      c.cancel();
      expect(c.minutes, isNull);
      expect(c.isActive, isFalse);
    });

    test('setMinutes(<=0) 视为取消', () {
      final c = controller();
      c.setMinutes(30);
      c.setMinutes(0);
      expect(c.minutes, isNull);
      expect(c.isActive, isFalse);
    });

    test('到点：调用一次 pause() 并自动复位', () {
      fakeAsync((async) {
        final c = controller();
        c.setMinutes(1);
        async.elapse(const Duration(seconds: 59));
        expect(audio.pauseCount, 0);
        async.elapse(const Duration(seconds: 1));
        expect(audio.pauseCount, 1);
        expect(c.minutes, isNull);
        expect(c.isActive, isFalse);
      });
    });

    test('重新设定会取消旧 Timer（不重复 pause）', () {
      fakeAsync((async) {
        final c = controller();
        c.setMinutes(15);
        async.elapse(const Duration(minutes: 10));
        c.setMinutes(45);
        async.elapse(const Duration(minutes: 10));
        expect(audio.pauseCount, 0);
        async.elapse(const Duration(minutes: 35));
        expect(audio.pauseCount, 1);
      });
    });

    test('cancel 后不再触发 pause', () {
      fakeAsync((async) {
        final c = controller();
        c.setMinutes(5);
        async.elapse(const Duration(minutes: 2));
        c.cancel();
        async.elapse(const Duration(minutes: 10));
        expect(audio.pauseCount, 0);
      });
    });

    test('dispose 取消 Timer', () {
      fakeAsync((async) {
        final c = controller();
        c.setMinutes(5);
        c.dispose();
        async.elapse(const Duration(minutes: 10));
        expect(audio.pauseCount, 0);
      });
    });

    test('最后 30 秒淡出音量，到点后恢复并 pause', () {
      fakeAsync((async) {
        final c = controller();
        c.setMinutes(1);
        for (var i = 0; i < 30; i++) {
          async.elapse(const Duration(seconds: 1));
        }
        expect(audio.volume, 1.0);
        for (var i = 0; i < 15; i++) {
          async.elapse(const Duration(seconds: 1));
        }
        expect(audio.volume, lessThan(1.0));
        expect(audio.volume, greaterThan(0.0));
        for (var i = 0; i < 15; i++) {
          async.elapse(const Duration(seconds: 1));
        }
        async.flushMicrotasks();
        expect(audio.pauseCount, 1);
        expect(audio.volume, 1.0);
      });
    });

    test('cancel 中淡出会恢复音量', () {
      fakeAsync((async) {
        final c = controller();
        c.setMinutes(1);
        for (var i = 0; i < 45; i++) {
          async.elapse(const Duration(seconds: 1));
        }
        expect(audio.volume, lessThan(1.0));
        c.cancel();
        async.flushMicrotasks();
        expect(audio.volume, 1.0);
        async.elapse(const Duration(minutes: 2));
        expect(audio.pauseCount, 0);
      });
    });
  });

  group('SleepTimerController.computeDimOpacity', () {
    test('inactive → 0', () {
      expect(
        SleepTimerController.computeDimOpacity(
          isActive: false,
          dimEnabled: true,
          fadeEnabled: true,
          remaining: const Duration(minutes: 5),
        ),
        0,
      );
    });

    test('active base dim before fade window', () {
      expect(
        SleepTimerController.computeDimOpacity(
          isActive: true,
          dimEnabled: true,
          fadeEnabled: true,
          remaining: const Duration(seconds: 60),
        ),
        SleepTimerController.baseDimOpacity,
      );
    });

    test('ramps toward max inside fade window', () {
      final opacity = SleepTimerController.computeDimOpacity(
        isActive: true,
        dimEnabled: true,
        fadeEnabled: true,
        remaining: const Duration(seconds: 15),
      );
      expect(opacity, greaterThan(SleepTimerController.baseDimOpacity));
      expect(opacity, lessThan(SleepTimerController.maxDimOpacity));
    });
  });
}
