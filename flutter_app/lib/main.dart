import 'dart:convert';
import 'dart:io';

import 'package:employee_search_engine/api_service.dart';
import 'package:employee_search_engine/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeData? _themeData;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    _themeData = await ThemeManager.getTheme();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final apiConfig = ApiConfig(
      baseEndpoint: dotenv.env['BASE_ENDPOINT'] ?? 'http://127.0.0.1:3000',
      processImageEndpoint: 'process-image',
      trainVectorEndpoint: 'train-vector',
    );

    final apiService = ApiService(apiConfig);

    return MaterialApp(
      title: 'Employee Search Engine',
      theme: _themeData?.copyWith(
        colorScheme: _themeData?.colorScheme
            .copyWith(secondary: const Color.fromARGB(255, 137, 170, 3)),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          splashColor: Color(0xFFB3D334),
        ),
      ),
      home: MyHomePage(
        title: 'Employee Search Engine',
        apiService: apiService,
        onThemeChanged: _handleThemeChanged,
      ),
    );
  }

  void _handleThemeChanged(bool isDarkMode) async {
    await ThemeManager.setTheme(isDarkMode);
    _loadTheme();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    Key? key,
    required this.title,
    required this.apiService,
    required this.onThemeChanged,
  }) : super(key: key);

  final String title;
  final ApiService apiService;
  final Function(bool) onThemeChanged;

  @override
  createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _image;
  Image? _serverImage;

  Future<void> _showModal(String message) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Information',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFB3D334),
                  ),
                ),
                const SizedBox(height: 10.0),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10.0),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    primary: const Color(0xFFB3D334),
                  ),
                  child: Text('OK'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<File?> _openGallery() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    return pickedFile != null ? File(pickedFile.path) : null;
  }

  Future<void> _getImage() async {
    final pickedFile = await _openGallery();

    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
        _serverImage = null;
      });

      final bytes = await _image!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final processedImageBase64 =
          await widget.apiService.sendImageToProcessImage(base64Image);

      final processedImage = Image.memory(base64Decode(processedImageBase64));
      setState(() {
        _serverImage = processedImage;
      });
    }
  }

  Future<void> _trainVector() async {
    final pickedFile = await _openGallery();

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response =
          await widget.apiService.sendImageToTrainVector(base64Image);

      if (response) {
        await _showModal('Added to the engine');
      }
    } else {
      print('No image selected.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/lc_logo.png',
              width: 40,
              height: 40,
            ),
            const SizedBox(width: 8), // Space between image and title
            Text(
              widget.title,
              style:
                  const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Switch(
            value: Theme.of(context).brightness == Brightness.dark,
            activeColor: const Color(0xFFB3D334),
            onChanged: (value) {
              widget.onThemeChanged(value);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            AspectRatio(
              aspectRatio: 1.0,
              child: Center(
                child: _image == null
                    ? const Text('No image selected.')
                    : Container(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Your photo:',
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Image.file(_image!),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            AspectRatio(
              aspectRatio: 1.0,
              child: Center(
                child: _serverImage == null
                    ? const SizedBox(height: 20)
                    : Container(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'You are this employee of LambdaClass:',
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: _serverImage!,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _getImage,
            tooltip: 'Pick Image',
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFFB3D334),
            child: const Icon(Icons.add_a_photo),
          ),
          const SizedBox(height: 16.0), // Ajusta el espacio entre los botones
          FloatingActionButton(
            onPressed: () {
              _trainVector();
            },
            tooltip: 'Train Vector',
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFFB3D334),
            child: const Icon(Icons.upload),
          ),
        ],
      ),
    );
  }
}
