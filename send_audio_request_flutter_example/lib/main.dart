import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _fileName;
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  List<PlatformFile>? _paths;
  final FileType _pickingType = FileType.custom;
  bool _isLoading = false;

  // String serverUrl = 'http://54.188.114.42:5000'; //AWS ip address
  String serverUrl = 'http://10.0.2.2:5000'; // Locally

  bool _isUploading = false;
  String? _result;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _uploadFileToServer() async {
    if (kDebugMode) {
      print("uploading ... ");
    }
    setState(() {
      _isUploading = true;
    });
    var url = '$serverUrl/fetch_prediction';
    Map<String, String> headers = {
      "Connection": "Keep-Alive",
      "Keep-Alive": "timeout=10, max=1000"
    };

    String? path = _paths![0].path!.substring(1);
    http.MultipartRequest request =
        http.MultipartRequest('POST', Uri.parse(url));
    request.headers.addAll(headers);
    request.files.add(
      await http.MultipartFile.fromPath(
        'audio',
        path,
        //contentType: MediaType('audio', 'midi'),
      ),
    );
    // The following line will enable the Android and iOS wakelock.

    request.send().then((r) async {
      if (kDebugMode) {
        print(r.statusCode);
      }
      // print(json.decode(await r.stream.transform(utf8.decoder).join()));
      if (r.statusCode == 200) {
        var result = json.decode(await r.stream.transform(utf8.decoder).join());

        setState(() {
          _isUploading = false;
          _result = result;
        });
        // The next line disables the wakelock again.

      } else {
        if (kDebugMode) {
          print("Failed to get the response correctly!");
        }
        setState(() {
          _isUploading = false;
        });
        // The next line disables the wakelock again.

      }
    });
  }

  void _pickFiles() async {
    _resetState();
    try {
      _paths = (await FilePicker.platform.pickFiles(
        type: _pickingType,
        // ignore: avoid_print
        onFileLoading: (FilePickerStatus status) => print(status),
        allowedExtensions: ['mp3', 'wav'],
      ))
          ?.files;
      _isLoading = true;
    } on PlatformException catch (e) {
      _logException('Unsupported operation$e');
    } catch (e) {
      _logException(e.toString());
    }
    if (!mounted) return;
    setState(() {
      _fileName =
          _paths != null ? _paths!.map((e) => e.name).toString() : 'unknown';
    });
  }

  void _logException(String message) {
    if (kDebugMode) {
      print(message);
    }
    _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _resetState() {
    if (!mounted) {
      return;
    }
    setState(() {
      _fileName = null;
      _paths = null;
      _isLoading = false;
      _result = null;
      _isUploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _isLoading ? Text(_fileName!) : const Text('Upload a file'),
            const SizedBox(height: 10),
            Padding(
                padding: const EdgeInsets.all(12.0),
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan[200]),
                    onPressed: _isLoading ? _uploadFileToServer : null,
                    child: const Text(
                      'Analyze',
                    ))),
            _isUploading
                ? const Center(
                  child: CircularProgressIndicator(),
                )
                : Container(),
            _result != null
                ? Text(
                    'Result: $_result',
                    style: const TextStyle(fontSize: 30),
                  )
                : Container(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.cyan[200],
          onPressed: _pickFiles,
          child: const Icon(
            Icons.file_upload,
            color: Colors.white,
            size: 36.0,
            semanticLabel: 'Upload song',
          )),
    );
  }
}
