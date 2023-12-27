import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Picker Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Image Picker Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _image;

  Future<void> _getImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });

      // Convert the image to base64
      final bytes = await _image!.readAsBytes();
      final base64Image = base64Encode(bytes);

      await _logBase64ImageToFile(base64Image);

      // Send the base64-encoded image to the endpoint
      await _sendImageToEndpoint(base64Image);
    }
  }

  Future<void> _logBase64ImageToFile(String base64Image) async {
    try {
      // Get the documents directory
      final appDocumentsDirectory = await getApplicationDocumentsDirectory();

      // Relative path within the documents directory
      final relativePath = 'logs/base64_image_log.txt';
      final filePath = '${appDocumentsDirectory.path}/$relativePath';

      final file = File(filePath);

      // Ensure the directory exists
      await file.parent.create(recursive: true);

      // Write the base64-encoded image to the file
      await file.writeAsString(base64Image);
      print("Base64-encoded image logged to $filePath");
    } catch (e) {
      print("Error writing to file: $e");
    }
  }

  Future<void> _sendImageToEndpoint(String base64Image) async {
    final endpointUrl = 'YOUR_ENDPOINT_URL';

    try {
      final response = await http.post(
        Uri.parse(endpointUrl),
        body: {'image': base64Image},
      );

      if (response.statusCode == 200) {
        print('Image sent successfully');
        print('Server response: ${response.body}');
      } else {
        print(
            'Image send failed. Server responded with ${response.statusCode}');
      }
    } catch (error) {
      print('Error sending image: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: _image == null
            ? const Text('No image selected.')
            : Image.file(_image!),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getImage,
        tooltip: 'Pick Image',
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}
