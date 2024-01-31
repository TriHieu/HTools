
import 'dart:io';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:permission_handler/permission_handler.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final _outputFolderController = TextEditingController();
  final _inputURLController = TextEditingController();
  final _dialogTitleController = TextEditingController();
  final _initialDirectoryController = TextEditingController();
  String? _fileName;
  List<PlatformFile>? _paths;
  List<String?>? _pathString;
  String? _extension;
  bool _isLoading = false;
  bool _lockParentWindow = false;
  bool _multiPick = false;
  FileType _pickingType = FileType.any;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Colors.deepPurple,
        ),
      ),
      home: LoaderOverlay(
        useDefaultLoading: false,
        overlayColor: Colors.black87.withOpacity(0.8),
        overlayWidgetBuilder: (dynamic? progress) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(
                  height: 50,
                ),
                if (progress != null)
                  Text(
                      progress,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        fontSize: 20,
                        color: Colors.deepPurple
                      )
                  )
              ],
            ),
          );
        },
        child: Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: const Text('M3U8 to MP4'),
          ),
          body: Padding(
            padding: const EdgeInsets.only(left: 5.0, right: 5.0),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 15.0, right: 15.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
                    child: Wrap(
                      spacing: 10.0,
                      runSpacing: 10.0,
                      children: <Widget>[
                        SizedBox(
                          width: 120,
                          child: FloatingActionButton.extended(
                              onPressed: () => _pickFiles(),
                              label:
                              Text(_multiPick ? 'Pick files' : 'Pick file'),
                              icon: const Icon(Icons.description)),
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 10.0,
                    runSpacing: 10.0,
                    children: [
                      SizedBox(
                        width: 400,
                        child: TextField(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Input URL',
                          ),
                          controller: _inputURLController,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(
                    height: 20.0,
                  ),
                  Wrap(
                    spacing: 10.0,
                    runSpacing: 10.0,
                    children: [
                      SizedBox(
                        width: 400,
                        child: TextField(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Output Folder',
                          ),
                          controller: _outputFolderController,
                          onTap: () => _selectFolder(),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(
                    height: 20.0,
                  ),
                  const Text(
                    'File Selected',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Builder(
                    builder: (BuildContext context) =>
                    _isLoading
                        ? const Row(
                      children: [
                        Expanded(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 40.0,
                              ),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                      ],
                    )
                        : _paths != null
                        ? Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20.0,
                      ),
                      height:
                      MediaQuery
                          .of(context)
                          .size
                          .height *
                          0.40,
                      child: Scrollbar(
                          child: ListView.separated(
                            itemCount:
                            _paths != null && _paths!.isNotEmpty
                                ? _paths!.length
                                : 1,
                            itemBuilder:
                                (BuildContext context, int index) {
                              final bool isMultiPath = _paths != null &&
                                  _paths!.isNotEmpty;
                              final String name = 'File $index: ${isMultiPath
                                  ? _paths!.map((e) => e.name).toList()[index]
                                  : _fileName ?? '...'}';
                              final path = kIsWeb
                                  ? null
                                  : _paths!.map((e) => e.path).toList()[index]
                                  .toString();

                              return ListTile(
                                title: Text(
                                  name,
                                ),
                                subtitle: Text(path ?? ''),
                              );
                            },
                            separatorBuilder:
                                (BuildContext context, int index) =>
                            const Divider(),
                          )),
                    )
                        : const SizedBox(),
                  ),
                  const SizedBox(
                    height: 10.0,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
                    child: Wrap(
                      spacing: 10.0,
                      runSpacing: 10.0,
                      children: <Widget>[
                        SizedBox(
                          width: 120,
                          child: FloatingActionButton.extended(
                              onPressed: () => _processFile(),
                              label:
                              const Text('Process'),
                              icon: const Icon(Icons.settings)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _resetState() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = true;
      _fileName = null;
      _paths = null;
    });
  }

  void _pickFiles() async {
    if (kIsWeb) {

    } else if (Platform.isAndroid) {
      var permissionResult = await Permission.storage.request();
      permissionResult = await Permission.manageExternalStorage.request();
      if (permissionResult.isDenied) openAppSettings();

      permissionResult = await Permission.photos.request();
      permissionResult = await Permission.videos.request();
      permissionResult = await Permission.audio.request();
    }
    _resetState();
    try {
      FilePickerResult? result = (await FilePicker.platform.pickFiles(
        type: _pickingType,
        allowMultiple: _multiPick,
        onFileLoading: (FilePickerStatus status) => print(status),
        allowedExtensions: (_extension?.isNotEmpty ?? false)
            ? _extension?.replaceAll(' ', '').split(',')
            : null,
        dialogTitle: _dialogTitleController.text,
        initialDirectory: _initialDirectoryController.text,
        lockParentWindow: _lockParentWindow,
      ));
      _paths = result?.files;
      _pathString = result?.paths;
    } on PlatformException catch (e) {
      _logException('Unsupported operation' + e.toString());
    } catch (e) {
      _logException(e.toString());
    }
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _fileName =
      _paths != null ? _paths!.map((e) => e.name).toString() : '...';
    });
  }

  void _selectFolder() async {
    try {
      String? path = await FilePicker.platform.getDirectoryPath(
        dialogTitle: _dialogTitleController.text,
        initialDirectory: _initialDirectoryController.text,
        lockParentWindow: _lockParentWindow,
      );
      setState(() {
        _outputFolderController.text = path!;
      });
    } on PlatformException catch (e) {
      _logException('Unsupported operation' + e.toString());
    } catch (e) {
      _logException(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _logException(String message) {
    print(message);
    _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _processFile() async {
    context.loaderOverlay.show(
      progress: "Converting to MP4 ..."
    );
    await updateInputFile();
    String cmd = '';
    if (_inputURLController.text.isNotEmpty) {
      cmd = '-y -protocol_whitelist file,http,https,tls,tcp -allowed_extensions ALL -i "${_inputURLController.text}" -acodec copy -bsf:a aac_adtstoasc -vcodec copy "${_outputFolderController.text}"/a.mp4';
    } else {
      cmd = '-y -protocol_whitelist file,http,https,tls,tcp -allowed_extensions ALL -i "${_outputFolderController.text}/${_paths![0]!.name!}" -acodec copy -bsf:a aac_adtstoasc -vcodec copy -c copy "${_outputFolderController.text}/${_paths![0]!.name!.replaceAll('m3u8', 'mp4')}"';
    }
    FFmpegKit.execute(cmd).then((session) async {
      final returnCode = await session.getReturnCode();
      context.loaderOverlay.hide();
      if (ReturnCode.isSuccess(returnCode)) {
        _logException("SUCCESS");
        // SUCCESS
      } else if (ReturnCode.isCancel(returnCode)) {
        _logException("CANCEL");
        // CANCEL
      } else {
        _logException("ERROR");
        // ERROR
      }
      final logs = await session.getLogs();
      for (var element in logs) {
        print(element.getMessage());
      }
    });
  }

  Future<bool> updateInputFile() async {
    try {
      final file = File("${_outputFolderController.text}/${_paths![0]!.name!}");
      // Read the file
      var contents = await file.readAsString();
      contents = contents.replaceFirst("#EXTINF:", "#EXT-X-BYTERANGE:100000000@8\n#EXTINF:");
      file.writeAsString(contents);
      return true;
    } catch (e) {
      // If encountering an error, return 0
      return false;
    }
  }
}
