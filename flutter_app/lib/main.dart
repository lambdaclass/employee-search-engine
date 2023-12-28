import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme_manager.dart';

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
  late ThemeData _themeData;

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
    final serverIp = dotenv.env['SERVER_IP'] ?? '127.0.0.1';
    final endpointUrl = 'http://$serverIp:3000/process-image';
    return MaterialApp(
      title: 'Employee Search Engine',
      theme: _themeData.copyWith(
        // Cambia el colorScheme para afectar los colores primarios y secundarios
        colorScheme: _themeData.colorScheme.copyWith(
          primary: const Color(0xFFB3D334),
          secondary: const Color.fromARGB(255, 137, 170, 3)
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          splashColor: Color(0xFFB3D334), // Cambia el color de splash
        ),
      ),
      home: MyHomePage(
        title: 'Employee Search Engine',
        endpointUrl: endpointUrl,
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
    required this.endpointUrl,
    required this.onThemeChanged,
  }) : super(key: key);

  final String title;
  final String endpointUrl;
  final Function(bool) onThemeChanged;

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
        title: Row(
          children: [
            Image.asset(
              'assets/lc_logo.png',
              width: 40,
              height: 40,
            ),
            const SizedBox(width: 8), // Espacio entre la imagen y el título
            Text(
              widget.title,
              style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Switch(
            value: Theme.of(context).brightness == Brightness.dark,
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
                          const Text('Your photo:',
                              style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold)),
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
                                  'You are this LambdaClass employee:',
                                  style: TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold)),
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
                        )
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getImage,
        tooltip: 'Pick Image',
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}
