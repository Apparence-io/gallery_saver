import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:gallery_saver/files.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class GallerySaver {
  static const String channelName = 'gallery_saver';
  static const String methodSaveImage = 'saveImage';
  static const String methodSaveVideo = 'saveVideo';

  static const String pleaseProvidePath = 'Please provide valid file path.';
  static const String fileIsNotVideo = 'File on path is not a video.';
  static const String fileIsNotImage = 'File on path is not an image.';
  static const MethodChannel _channel = const MethodChannel(channelName);

  ///saves video from provided temp path and optional album name in gallery
  static Future<bool> saveVideo(
    String path,
    String fileName, {
    String albumName,
    Map<String, String> headers,
  }) async {
    File tempFile;
    if (path == null || path.isEmpty) {
      throw ArgumentError(pleaseProvidePath);
    }
    if (!isVideo(path)) {
      throw ArgumentError(fileIsNotVideo);
    }
    if (!isLocalFilePath(path)) {
      tempFile = await _downloadFile(
        path,
        fileName,
        MediaType.VIDEO,
        headers: headers,
      );
      path = tempFile.path;
    }
    bool result = await _channel.invokeMethod(
      methodSaveVideo,
      <String, dynamic>{
        'path': path,
        'albumName': albumName,
      },
    );
    if (tempFile != null) {
      tempFile.delete();
    }
    return result;
  }

  ///saves image from provided temp path and optional album name in gallery
  static Future<bool> saveImage(String path, String fileName,
      {String albumName, Map<String, String> headers}) async {
    File tempFile;
    if (path == null || path.isEmpty) {
      throw ArgumentError(pleaseProvidePath);
    }
    if (!isLocalFilePath(path)) {
      tempFile = await _downloadFile(
        path,
        fileName,
        MediaType.IMAGE,
        headers: headers,
      );
      path = tempFile.path;
    }

    bool result = await _channel.invokeMethod(
      methodSaveImage,
      <String, dynamic>{
        'path': path,
        'albumName': albumName,
      },
    );
    if (tempFile != null) {
      tempFile.delete();
    }

    return result;
  }

  static Future<File> _downloadFile(
    String url,
    String fileName,
    MediaType mediaType, {
    Map<String, String> headers,
  }) async {
    http.Client _client = new http.Client();
    var req = await _client.get(Uri.parse(url), headers: headers);
    var bytes = req.bodyBytes;
    String dir = (await getTemporaryDirectory()).path;
    String ext = mediaType == MediaType.IMAGE ? ".jpeg" : ".mp4";
    String fullName = fileName + ext;
    File file = new File('$dir/$fullName');
    await file.writeAsBytes(bytes);
    print('File size:${await file.length()}');
    print(file.path);
    return file;
  }
}
