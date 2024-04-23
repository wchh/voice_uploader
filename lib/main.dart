// import 'dart:ffi';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;

import './audio_player.dart';
import './audio_recorder.dart';
import './platform/audio_recorder_platform.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum RecorderState { start, continuing, stop }

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

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
  String uploadResult = '';
  late String? _apiUrl = '';
  late String? _text = '0123456789';

  @override
  void initState() {
    super.initState();
    showPlayer = false;
    _apiUrl = dotenv.env['API_URL'];
    final text = dotenv.env['TEXT'];
    if (text != null) {
      _text = text;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<String> _uploadAudio(String address, Uint8List data) async {
    debugPrint('上传音频数据, ${data.length}');
    // 创建一个URI，并添加address参数
    final uri =
        Uri.parse(_apiUrl!).replace(queryParameters: {'address': address});

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
                      Text(_text!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 24)),
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
                                    addressController.text, buffer);
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
