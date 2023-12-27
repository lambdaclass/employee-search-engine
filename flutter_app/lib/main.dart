import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final serverIp = dotenv.env['SERVER_IP'] ?? '127.0.0.1';
    final endpointUrl = 'http://$serverIp:3000/process-image';

    return MaterialApp(
      title: 'Image Picker Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Image Picker Demo', endpointUrl: endpointUrl),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title, required this.endpointUrl})
      : super(key: key);

  final String title;
  final String endpointUrl;

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

      // Send the base64-encoded image to the endpoint
      await _sendImageToEndpoint(base64Image);
    }
  }

  Future<void> _sendImageToEndpoint(String base64Image) async {
    print("VOY A ENVIAR UNA PETICION");

    try {
      final response = await http.post(
        Uri.parse(widget.endpointUrl),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'image': base64Image}),
      );
      print('Response: ${response}');
      if (response.statusCode == 200) {
        print('Image sent successfully');
        String base64ServerImage = jsonDecode(response.body)["processedImage"];
        await _loadImageFromServer(base64ServerImage);
      } else {
        print(
            'Image send failed. Server responded with ${response.statusCode}');
      }
    } catch (error) {
      print('Error sending image: $error');
    }
  }

  Future<void> _loadImageFromServer(String base64Image) async {
    try {
      // Limpiar la cadena base64 eliminando espacios en blanco al principio y al final
      final cleanedBase64 = base64Image.trim();

      final bytes = base64Decode(cleanedBase64);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/logs/respuesta_image.jpg');

      // Crea el directorio si no existe
      await Directory('${directory.path}/logs/').create(recursive: true);

      // Escribe la imagen en el archivo
      await file.writeAsBytes(bytes);
      print('Image from server written to file: ${file.path}');

      setState(() {
        _image = file;
      });
    } catch (e) {
      print('Error loading image from server: $e');
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
