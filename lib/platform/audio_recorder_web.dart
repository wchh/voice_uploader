// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:typed_data';

import 'package:record/record.dart';

mixin AudioRecorderMixin {
  Future<void> recordFile(AudioRecorder recorder, RecordConfig config) {
    return recorder.start(config, path: '');
  }

  Future<void> recordStream(AudioRecorder recorder, RecordConfig config) async {
    List<int> b = [];
    final stream = await recorder.startStream(config);

    stream.listen(
      (data) => b.addAll(recorder.convertBytesToInt16(data, Endian.little)),
      onDone: () => downloadWebData(html.Url.createObjectUrl(html.Blob(b))),
    );
  }

  void downloadWebData(String path) {
    // Simple download code for web testing
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = path
      ..style.display = 'none'
      ..download = 'audio.wav';
    html.document.body!.children.add(anchor);
    anchor.click();
    html.document.body!.children.remove(anchor);
  }
}

mixin SaveAudioMixin on AudioRecorderMixin {
  Future<void> saveAudio(
      List<ByteData> data, void Function(String) onPath) async {
    final path = html.Url.createObjectUrl(html.Blob(data, 'audio/pcm'));
    onPath(path);
    downloadWebData(path);
  }

  Future<Uint8List> getFileData(String path) async {
    // 创建一个HttpRequest
    final request = html.HttpRequest();
    // 打开请求
    request.open('GET', path, async: true);
    // 设置返回类型为Blob
    request.responseType = 'blob';
    // 发送请求
    request.send();
    // 等待请求完成
    await request.onLoadEnd.first;
    // 获取Blob对象
    final blob = request.response as html.Blob;
    // 创建一个FileReader
    final reader = html.FileReader();
    // 读取Blob对象
    reader.readAsArrayBuffer(blob);
    // 等待读取完成
    await reader.onLoadEnd.first;
    // 获取ArrayBuffer对象
    final data = reader.result as Uint8List;

    // downloadWebData(html.Url.createObjectUrl(html.Blob([data])));
    // 返回数据
    return data;
  }
}
