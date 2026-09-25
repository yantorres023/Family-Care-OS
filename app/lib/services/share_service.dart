import 'dart:convert';

import 'package:share_plus/share_plus.dart';

/// Hands text to the OS share sheet (WhatsApp, SMS, email…). The user always
/// sees and confirms what is shared.
abstract class ShareService {
  /// Returns false only if the user dismissed the sheet.
  Future<bool> shareText(String text, {String? subject});

  Future<bool> shareFile(String fileName, String contents, String mimeType);
}

class SystemShareService implements ShareService {
  const SystemShareService();

  @override
  Future<bool> shareText(String text, {String? subject}) async {
    final result = await SharePlus.instance.share(
      ShareParams(text: text, subject: subject),
    );
    return result.status != ShareResultStatus.dismissed;
  }

  @override
  Future<bool> shareFile(
    String fileName,
    String contents,
    String mimeType,
  ) async {
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(utf8.encode(contents), mimeType: mimeType)],
        fileNameOverrides: [fileName],
      ),
    );
    return result.status != ShareResultStatus.dismissed;
  }
}

/// Records shares instead of showing a sheet (tests, demo).
class RecordingShareService implements ShareService {
  final shared = <String>[];
  bool nextResult = true;

  @override
  Future<bool> shareText(String text, {String? subject}) async {
    shared.add(text);
    return nextResult;
  }

  @override
  Future<bool> shareFile(
    String fileName,
    String contents,
    String mimeType,
  ) async {
    shared.add('$fileName\n$contents');
    return nextResult;
  }
}
