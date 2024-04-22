// import 'dart:ffi';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;

import './audio_player.dart';
import './audio_recorder.dart';
import './platform/audio_recorder_platform.dart';

enum RecorderState { start, continuing, stop }

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

const registerSuccess = "registerSuccess";
const checkinSuccess = "checkinSuccess";
const registerWithDifferentAddress = "registerWithDifferentAddress";
const serverError = "serverError";
const postError = "postError";

class _MyAppState extends State<MyApp> with AudioRecorderMixin, SaveAudioMixin {
  bool showPlayer = false;
  String? audioPath;
  final addressController = TextEditingController();
  final String url = 'http://localhost/upload';
  String uploadResult = '';

  @override
  void initState() {
    showPlayer = false;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<String> _uploadAudio(
      String url, String address, Uint8List data) async {
    debugPrint('上传音频数据, ${data.length}');
    // 创建一个URI，并添加address参数
    final uri = Uri.parse(url).replace(queryParameters: {'address': address});

    // 创建一个HTTP客户端
    final client = http.Client();

    String result = '';

    // 发送数据
    try {
      final response = await client.post(
        uri,
        body: data,
        headers: {
          'Content-Type': 'application/octet-stream', // 根据你的音频格式设置正确的MIME类型
        },
      );

      if (response.statusCode != 200) {
        debugPrint('上传失败：${response.statusCode}');
        result = '${response.statusCode}: ${response.body}';
      } else {
        debugPrint('上传成功：${response.body}');
        result = response.body;
      }
    } catch (e) {
      debugPrint('上传失败：$e');
      result = e.toString();
    } finally {
      client.close();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.all(20),
            width: 800,
            child: SizedBox(
              height: 600,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center, // 添加这一行
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('请输入你的地址：', style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: 500,
                        height: 40,
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
                      const Text('请朗读红色文字并录音: ',
                          style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 10),
                      const Text('芝麻开门',
                          style: TextStyle(color: Colors.red, fontSize: 24)),
                    ],
                  ),
                  const SizedBox(
                    height: 32,
                  ),
                  Recorder(
                    onStart: () {
                      setState(() {
                        showPlayer = false;
                      });
                    },
                    onReadStream: (data) {},
                    onStop: (path) {
                      if (kDebugMode) print('Recorded file path: $path');
                      if (path == null) {
                      } else {
                        // file
                        audioPath = path;
                        setState(() {
                          showPlayer = true;
                        });
                      }
                    },
                  ),
                  showPlayer
                      ? Column(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 25),
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
                                final buffer = await getFileData(audioPath!);
                                final result = await _uploadAudio(
                                    url, addressController.text, buffer);
                                setState(() {
                                  uploadResult = result;
                                });
                              },
                              child: const Text('发送录音'),
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            Text(uploadResult),
                          ],
                        )
                      : Container(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
