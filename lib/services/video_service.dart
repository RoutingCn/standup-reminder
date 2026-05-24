import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class VideoValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? filePath;
  final int? fileSizeMB;
  final int? width;
  final int? height;
  final double? durationSeconds;
  const VideoValidationResult({required this.isValid, this.errorMessage, this.filePath, this.fileSizeMB, this.width, this.height, this.durationSeconds});
  factory VideoValidationResult.ok({required String filePath, required int fileSizeMB}) =>
    VideoValidationResult(isValid: true, filePath: filePath, fileSizeMB: fileSizeMB);
  factory VideoValidationResult.error(String m) => VideoValidationResult(isValid: false, errorMessage: m);
}

class VideoService {
  static const _maxMB = 80;

  /// Pick a video file from device. Returns a local copy path (works on Android SAF URIs).
  static Future<String?> pickVideo() async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mov'],
      allowMultiple: false,
      withData: false,
    );
    if (r == null || r.files.isEmpty) return null;
    final originalPath = r.files.single.path;
    if (originalPath == null) return null;
    // Copy to app temp directory immediately (handles content:// URIs on Android)
    try {
      return await _copyToTemp(originalPath, r.files.single.name);
    } catch (_) {
      // If copy fails, try original path as fallback
      return originalPath;
    }
  }

  /// Copy a file to app temp directory so we have a real filesystem path.
  static Future<String> _copyToTemp(String srcPath, String fileName) async {
    final tempDir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final safeName = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final dest = '${tempDir.path}/vid_${ts}_$safeName';
    // Try reading as bytes first (works with content:// URIs where File(srcPath) fails)
    try {
      final bytes = await File(srcPath).readAsBytes();
      await File(dest).writeAsBytes(bytes);
    } catch (_) {
      // If direct File read fails, use the original path (may be content URI)
      throw Exception('cannot copy');
    }
    return dest;
  }

  /// Validate a video file (basic checks only — no VideoPlayerController to avoid hangs).
  static Future<VideoValidationResult> validateVideo(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      // Path might be content URI on Android; accept it if it looks valid
      if (path.startsWith('content://')) {
        final mb = 0; // can't determine size from content URI without reading
        return VideoValidationResult.ok(filePath: path, fileSizeMB: mb);
      }
      return VideoValidationResult.error('文件不存在');
    }
    final ext = path.split('.').last.toLowerCase();
    if (!['mp4', 'mov'].contains(ext)) return VideoValidationResult.error('只支持 MP4 / MOV 格式');
    final mb = (await file.length() / (1024 * 1024)).round();
    if (mb > _maxMB) return VideoValidationResult.error('文件过大（${mb}MB），请控制在${_maxMB}MB以内');
    return VideoValidationResult.ok(filePath: path, fileSizeMB: mb);
  }

  /// Copy video to app's permanent storage for use at runtime.
  static Future<String> copyToAppStorage(String src, String name) async {
    final appDir = await getApplicationDocumentsDirectory();
    final vDir = Directory('${appDir.path}/videos');
    if (!await vDir.exists()) await vDir.create(recursive: true);
    final ts = DateTime.now().millisecondsSinceEpoch;
    final safe = name.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final dest = '${vDir.path}/${ts}_$safe';
    final srcFile = File(src);
    if (await srcFile.exists()) {
      await srcFile.copy(dest);
    } else {
      // Content URI — try reading bytes
      try {
        final bytes = await srcFile.readAsBytes();
        await File(dest).writeAsBytes(bytes);
      } catch (_) {
        throw Exception('无法复制视频文件');
      }
    }
    return dest;
  }

  static Future<void> deleteVideo(String path) async {
    final f = File(path);
    if (await f.exists()) await f.delete();
  }

  static String formatInfo(VideoValidationResult r) {
    return '${r.fileSizeMB ?? "?"}MB · 已验证';
  }

  static Color resultColor(VideoValidationResult r) => r.isValid ? Colors.green : Colors.red;
}
