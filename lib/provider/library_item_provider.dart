import 'dart:io';

import 'package:abs_api/abs_api.dart';
import 'package:abs_flutter/models/file.dart';
import 'package:abs_flutter/provider/download_provider.dart';
import 'package:abs_flutter/provider/log_provider.dart';
import 'package:abs_flutter/provider/user_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

final itemProvider =
    FutureProvider.family<LibraryItemBase?, String>((ref, id) async {
  final api = ref.watch(apiProvider);

  if (api == null) {
    return null;
  }

  final downloads = ref.read(downloadListProvider);
  final DownloadInfo? download =
      downloads.where((element) => element.itemId == id).firstOrNull;

  log(download.toString());

  if (download == null || download.filePath == null) {
    try {
      final response = await api.getLibraryItemApi().getLibraryItem(id: id);
      if (response.data == null || response.data!.oneOf.value == null) {
        return null;
      }
      if (response.data!.oneOf.value is LibraryItemBase) {
        return response.data!.oneOf.value as LibraryItemBase;
      }
      return null;
    } catch (e) {
      if (e is DioException) {
        if (e.response != null && e.response!.data != null) {
          log(e.response!.data!.toString(), name: 'itemProvider');
          return null;
        }
        log(e.toString(), name: 'itemProvider');
        return null;
      }

      return null;
    }
  } else {
    final String originalFilePath = download.filePath!;
    late final String directory;
    if (download.type == MediaTypeDownload.podcast) {
      directory = Directory(originalFilePath).parent.parent.path;
    } else {
      directory = Directory(originalFilePath).parent.path;
    }

    final String newFilePath = p.join(directory, 'meta.json');
    final File file = File(newFilePath);

    log('Reading file: $newFilePath');

    return api.serializers
        .fromJson(LibraryItemBase.serializer, file.readAsStringSync());
  }
});
