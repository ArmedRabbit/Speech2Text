// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, depend_on_referenced_packages

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import "package:cool_alert/cool_alert.dart";
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whisper_dart/whisper_dart.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Whisper Speech to Text'),
    ),
  );
}

class MyHomePage extends StatefulWidget {
  final String title;
  const MyHomePage({
    super.key,
    required this.title,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String model = "";
  String audio = "";
  String result = "";
  bool is_procces = false;
  Whisper whisper = Whisper(whisperLib: "libwhisper.so");

  loadModel() async {
    final bytes = await rootBundle.load('assets/ggml-tiny.bin');
    final directory = await getApplicationDocumentsDirectory();
    final modelPath = '${directory.path}/ggml-tiny.bin';
    final file = File(modelPath);
    await file.writeAsBytes(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));

    setState(() {
      model = modelPath;
    });
  }

  @override
  void initState() {
    loadModel();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Speech to Text'),
        ),
        body: LayoutBuilder(builder: (context, constraints) {
          double height = 0;
          if (constraints.maxHeight - 300 > 0) {
            height = constraints.maxHeight - 300;
          } else {
            height = 300;
          }
          return SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Visibility(
                  visible: !is_procces,
                  replacement: const CircularProgressIndicator(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: () async {
                          FilePickerResult? resul =
                              await FilePicker.platform.pickFiles();

                          if (resul != null) {
                            File file = File(resul.files.single.path!);
                            if (file.existsSync()) {
                              setState(() {
                                audio = file.path;
                              });
                            }
                          }
                        },
                        child: const Text("set audio"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (is_procces) {
                            return await CoolAlert.show(
                              context: context,
                              type: CoolAlertType.info,
                              text: "Please wait for the process to finish",
                            );
                          }
                          if (audio.isEmpty) {
                            await CoolAlert.show(
                              context: context,
                              type: CoolAlertType.info,
                              text:
                                  "Sorry, the audio is empty, please set it first",
                            );
                            if (kDebugMode) {
                              print("audio is empty");
                            }
                            return;
                          }

                          Future<List<File>> splitAudioFile(
                              String filePath) async {
                            // This is where you'd split the audio file into smaller chunks
                            // For simplicity, assume that this function returns a list of audio files (chunks)
                            // In practice, you may use FFmpeg or another tool to split the file
                            List<File> chunks =
                                []; // Populate with actual chunks

                            // For demonstration, we'll just return the original file as a single chunk
                            chunks.add(File(filePath));
                            return chunks;
                          }

                          Future(() async {
                            // ignore: avoid_print
                            print("Started transcribe ===> ${DateTime.now()}");
                            setState(() {
                              is_procces = true;
                              result = ""; // Clear previous result
                            });

                            // Split the audio file into chunks
                            List<File> chunks = await splitAudioFile(audio);

                            for (File chunk in chunks) {
                              var res = await whisper.request(
                                whisperRequest: WhisperRequest.fromWavFile(
                                  audio: chunk,
                                  model: File(
                                      model), // Replace with your model path
                                  language: "en",
                                ),
                              );

                              setState(() {
                                result += res["text"] + " ";
                              });
                            }
                            setState(() {
                              result = res.toString();
                              is_procces = false;
                            });
                          });
                        },
                        child: const Text("Start"),
                      ),
                    ],
                  ),
                ),
                // Padding(
                //   padding: const EdgeInsets.all(10),
                //   child: Text("model: ${model}"),
                // ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text("audio: ${audio}"),
                ),
                // Padding(
                //   padding: const EdgeInsets.all(10),
                //   child: Text("Result: ${result}"),
                // ),
                Container(
                  color: Theme.of(context).secondaryHeaderColor,
                  height: height,
                  child: Center(
                    child: Text(
                      result.isEmpty ? "No words recognized yet" : result,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        ),
      ),
    );
  }
}
