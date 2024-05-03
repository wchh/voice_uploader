// import 'dart:ffi';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flag/flag.dart';

import './audio_player.dart';
import './audio_recorder.dart';
import './platform/audio_recorder_platform.dart';

enum RecorderState { start, continuing, stop }

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Builder(
        builder: (context) {
          final locale = Localizations.localeOf(context);
          return MyHome(language: locale.languageCode);
        },
      ),
    );
  }
}

class MyHome extends StatefulWidget {
  final String language;
  const MyHome({super.key, required this.language});

  @override
  State<MyHome> createState() => _MyHomeState();
}

class UploadResult {
  final String result;
  final int code;

  UploadResult(this.result, this.code);
}

class _MyHomeState extends State<MyHome>
    with AudioRecorderMixin, SaveAudioMixin {
  bool showPlayer = false;
  String? audioPath;
  final addressController = TextEditingController();
  UploadResult _uploadResult = UploadResult('', 0);
  late String? _apiUrl = '';
  String _language = 'en';

  @override
  void initState() {
    super.initState();
    showPlayer = false;
    _apiUrl = dotenv.env['API_URL'];
    _language = widget.language;
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<UploadResult> _uploadAudio(String address, Uint8List data) async {
    debugPrint('上传音频数据, ${data.length}');
    // 创建一个URI，并添加address参数
    final uri =
        Uri.parse(_apiUrl!).replace(queryParameters: {'address': address});

    // 创建一个HTTP客户端
    final client = http.Client();

    String result = '';
    int code = 0;

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
      code = response.statusCode;
    } catch (e) {
      debugPrint('上传失败：$e');
      result = e.toString();
    } finally {
      client.close();
    }
    return UploadResult(result, code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          color: Colors.grey[200],
          padding: const EdgeInsets.all(20),
          width: 800,
          child: SizedBox(
            height: 600,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    MenuAnchor(
                      builder: (context, controller, child) {
                        return FilledButton.tonal(
                          onPressed: () {
                            if (controller.isOpen) {
                              controller.close();
                            } else {
                              controller.open();
                            }
                          },
                          child: Text(
                              AppLocalizations.of(context)!.selectLanguage),
                        );
                      },
                      menuChildren: [
                        MenuItemButton(
                          child: Row(
                            children: [
                              Flag.fromCode(
                                FlagsCode.US,
                                height: 20,
                                width: 20,
                              ),
                              const SizedBox(width: 10),
                              const Text('English '),
                            ],
                          ),
                          onPressed: () {
                            setState(() {
                              _language = 'en';
                            });
                          },
                        ),
                        MenuItemButton(
                          child: Row(
                            children: [
                              Flag.fromCode(
                                FlagsCode.CN,
                                height: 20,
                                width: 20,
                              ),
                              const SizedBox(width: 10),
                              const Text('中文 '),
                            ],
                          ),
                          onPressed: () {
                            setState(() {
                              _language = 'zh';
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(
                  height: 100,
                ),
                Localizations.override(
                  context: context,
                  locale: Locale(_language),
                  child: Builder(
                    builder: (context) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center, // 添加这一行
                        children: [
                          Text(AppLocalizations.of(context)!.inputYourAddress,
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: 500,
                            height: 40,
                            child: TextField(
                              // 添加这个输入框
                              controller: addressController,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText:
                                    AppLocalizations.of(context)!.address,
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          Text(
                              AppLocalizations.of(context)!
                                  .readRedTextAndRecord,
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 20),
                          Text(AppLocalizations.of(context)!.redText,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 24)),
                        ],
                      );
                    },
                  ),
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
                                  addressController.text, buffer);
                              setState(() {
                                _uploadResult = result;
                              });
                            },
                            child: Text(
                                AppLocalizations.of(context)!.identifySound),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Text(
                              "${_uploadResult.code == 200 ? AppLocalizations.of(context)!.uploadResultOk : AppLocalizations.of(context)!.uploadResultErr}: ${_uploadResult.result}",
                              style: TextStyle(
                                  color: _uploadResult.code == 200
                                      ? Colors.green
                                      : Colors.red)),
                        ],
                      )
                    : Container(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
