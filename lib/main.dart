import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
import 'package:http/http.dart' as http;

import './audio_player.dart';
import './audio_recorder.dart';

Future<Uint8List> getBlobData(String blobUrl) async {
  // 创建一个HttpRequest
  final request = html.HttpRequest();
  // 打开请求
  request.open('GET', blobUrl, async: true);
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
  // 返回数据
  return data;
}

Future<bool> uploadAudio(String url, String address, String blobUrl) async {
  final data = await getBlobData(blobUrl);

  // 创建一个URI，并添加address参数
  final uri = Uri.parse(url).replace(queryParameters: {'address': address});

  // 创建一个HTTP客户端
  final client = http.Client();

  // 发送数据
  final response = await client.post(
    uri,
    body: data,
    headers: {
      'Content-Type': 'application/octet-stream', // 根据你的音频格式设置正确的MIME类型
    },
  );

  if (response.statusCode == 200) {
    return true;
  } else {
    debugPrint('上传失败：${response.statusCode}');
    return false;
  }
}

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool showPlayer = false;
  String? audioPath;
  final addressController = TextEditingController();
  final String url = 'https://example.com/upload';

  @override
  void initState() {
    showPlayer = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center, // 添加这一行
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('请输入你的地址：', style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 540,
                    child: TextField(
                      // 添加这个输入框
                      controller: addressController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '地址',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('请点击下方麦克风按钮，并朗读红色文字: ',
                      style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 10),
                  const Text('芝麻开门',
                      style: TextStyle(color: Colors.red, fontSize: 24)),
                ],
              ),
              const SizedBox(
                height: 32,
              ),
              Recorder(
                onStop: (path) {
                  if (kDebugMode) print('Recorded file path: $path');
                  setState(() {
                    audioPath = path;
                    showPlayer = true;
                  });
                },
              ),
              showPlayer
                  ? Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: AudioPlayer(
                            source: audioPath!,
                            onDelete: () {
                              setState(() => showPlayer = false);
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            final result = await uploadAudio(
                                url, addressController.text, audioPath!);
                            if (!result) {
                              debugPrint('上传失败');
                            }
                          },
                          child: const Text('发送录音'),
                        ),
                      ],
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }
}
