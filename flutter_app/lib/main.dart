import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  Image? _serverImage;

  Future<void> _getImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _serverImage = null; // Reinicia la imagen del servidor al elegir una nueva imagen
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
        print('Server response: ${response.body}');

        // Extrae la cadena base64 de la imagen desde la respuesta JSON
        final jsonResponse = jsonDecode(response.body);
        final processedImageBase64 = jsonResponse['processedImage'];

        // Decodifica la imagen en base64 y la muestra
        setState(() {
          _serverImage = Image.memory(base64Decode(processedImageBase64));
        });
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
      body: SingleChildScrollView(
      child: Column(
        children: <Widget>[
            AspectRatio(
              aspectRatio: 1.0, // Proporción de aspecto cuadrado para _image
              child: Center(
                child: _image == null
                    ? const Text('No image selected.')
                    : Image.file(_image!),
              ),
            ),
            const SizedBox(height: 20),
            AspectRatio(
              aspectRatio: 1.0, // Proporción de aspecto cuadrado para _serverImage
              child: Center(
                child: _serverImage == null
                    ? const Text('No processed image.')
                    : Container(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: _serverImage!,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getImage,
        tooltip: 'Pick Image',
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}
