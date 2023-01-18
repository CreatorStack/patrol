import 'dart:convert' show base64Encode, utf8;

import 'package:dispose_scope/dispose_scope.dart';
import 'package:file/file.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path/path.dart' show basename;
import 'package:patrol_cli/src/common/extensions/process.dart';
import 'package:patrol_cli/src/common/logger.dart';
import 'package:patrol_cli/src/features/run_commons/device.dart';
import 'package:patrol_cli/src/features/test/app_options.dart';
import 'package:process/process.dart';

class AndroidTestRunner {
  AndroidTestRunner({
    required ProcessManager processManager,
    required FileSystem fs,
    required DisposeScope parentDisposeScope,
    required Logger logger,
  })  : _processManager = processManager,
        _fs = fs,
        _disposeScope = DisposeScope(),
        _logger = logger {
    _disposeScope.disposedBy(parentDisposeScope);
  }

  final ProcessManager _processManager;
  final FileSystem _fs;
  final DisposeScope _disposeScope;
  final Logger _logger;

  Future<void> run(AppOptions options, Device device) async {
    final targetName = basename(options.target);
    final task = _logger
        .task('Building apk for $targetName and running it on ${device.id}');

    final process = await _processManager.start(
      translate(options),
      runInShell: true,
      environment: {
        'ANDROID_SERIAL': device.id,
      },
      workingDirectory: _fs.currentDirectory.childDirectory('android').path,
    );

    process
        .listenStdOut((line) => _logger.detail('\t: $line'))
        .disposedBy(_disposeScope);
    process
        .listenStdErr((line) => _logger.err('\t$line'))
        .disposedBy(_disposeScope);

    final exitCode = await process.exitCode;

    if (exitCode == 0) {
      task.complete('Built and ran apk for $targetName on ${device.id}');
    } else {
      task.fail(
        'Failed to build and run apk for $targetName and run ${device.id}',
      );
      throw Exception('Gradle exited with code $exitCode');
    }
  }

  /// Translates [AppOptions] into a proper Gradle invocation.
  @visibleForTesting
  static List<String> translate(AppOptions appOptions) {
    final cmd = <String>['./gradlew'];

    // Add Gradle task
    var flavor = appOptions.flavor ?? '';
    if (flavor.isNotEmpty) {
      flavor = flavor[0].toUpperCase() + flavor.substring(1);
    }
    final gradleTask = ':app:connected${flavor}DebugAndroidTest';
    cmd.add(gradleTask);

    // Add Dart test target
    final target = '-Ptarget=${appOptions.target}';
    cmd.add(target);

    // Add Dart defines encoded in base64
    if (appOptions.dartDefines.isNotEmpty) {
      final dartDefinesString = StringBuffer();
      for (var i = 0; i < appOptions.dartDefines.length; i++) {
        final entry = appOptions.dartDefines.entries.toList()[i];
        dartDefinesString.write('${entry.key}=${entry.value}');
        if (i != appOptions.dartDefines.length - 1) {
          dartDefinesString.write(',');
        }
      }

      final dartDefines = utf8.encode(dartDefinesString.toString());
      cmd.add('-Pdart-defines=${base64Encode(dartDefines)}');
    }

    return cmd;
  }
}