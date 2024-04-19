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

class _MyAppState extends State<MyApp> with AudioRecorderMixin, SaveAudioMixin {
  bool showPlayer = false;
  String? audioPath;
  final addressController = TextEditingController();
  final String url = 'https://example.com/upload';
  // Timer? _timer;
  // final _buffer = <ByteData>[];
  // static const readLength = 1280;
  // RecorderState _rstate = RecorderState.stop;
  // int _readed = 0;

  @override
  void initState() {
    showPlayer = false;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    // _timer?.cancel();
    // _buffer.clear();
  }

  // void _startTimer() {
  //   _timer?.cancel();
  //   if (_buffer.isNotEmpty) {
  //     _buffer.clear();
  //   }
  //   _readed = 0;

  //   _timer = Timer.periodic(const Duration(microseconds: 40), (Timer t) {
  //     if (_buffer.length >= _readed + readLength) {
  //       final data = _buffer.sublist(_readed, readLength);
  //       _readed += readLength;
  //       // process data

  //       if (_rstate == RecorderState.start) {
  //         _rstate = RecorderState.continuing;
  //       }
  //     } else if (_rstate == RecorderState.stop) {
  //       final data = _buffer.sublist(_readed, _buffer.length - _readed);
  //     }
  //   });
  // }

  Future<bool> _uploadAudio(String url, String address, Uint8List data) async {
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
                onStart: () {
                  // _startTimer();
                  // _rstate = RecorderState.start;
                  setState(() {
                    showPlayer = false;
                  });
                },
                onReadStream: (data) {
                  // _buffer.add(ByteData.sublistView(data));
                },
                onStop: (path) {
                  // _rstate = RecorderState.stop;
                  if (kDebugMode) print('Recorded file path: $path');
                  if (path == null) {
                    // stream
                    // saveAudio(_buffer, (spath) {
                    //   audioPath = spath;
                    //   setState(() {
                    //     showPlayer = false;
                    //   });
                    // });
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
                            final buffer = await getFileData(audioPath!);
                            final result = await _uploadAudio(
                                url, addressController.text, buffer);
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
