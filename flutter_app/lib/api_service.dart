import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiConfig {
  late final String baseEndpoint;
  late final String processImageEndpoint;
  late final String trainVectorEndpoint;

  ApiConfig({
    required this.baseEndpoint,
    required this.processImageEndpoint,
    required this.trainVectorEndpoint,
  });
}

class ApiService {
  late ApiConfig _apiConfig;

  ApiService(this._apiConfig);

  Future<String> sendImageToProcessImage(String base64Image) async {
    final String endpointUrl = '${_apiConfig.baseEndpoint}/process-image';
    print("SENDING REQUEST: $endpointUrl");

    try {
      final response = await http.post(
        Uri.parse(endpointUrl),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'image': base64Image}),
      );

      if (response.statusCode == 200) {
        print('Image sent successfully');
        print('Server response: ${response.body}');
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['processedImage'];
      } else {
        print(
            'Image send failed. Server responded with ${response.statusCode}');
        throw Exception('Image send failed');
      }
    } catch (error) {
      print('Error sending image: $error');
      throw Exception('Error sending image');
    }
  }

  Future<void> sendImageToTrainVector(String base64Image) async {
    final String endpointUrl = '${_apiConfig.baseEndpoint}/train-vector';
    print("TRAIN-VECTOR: $endpointUrl");

    try {
      final response = await http.post(
        Uri.parse(endpointUrl),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'image': base64Image}),
      );

      if (response.statusCode == 200) {
        print('Image sent successfully');
        print('Server response: ${response.body}');
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['processedImage'];
      } else {
        print(
            'Image send failed. Server responded with ${response.statusCode}');
        throw Exception('Image send failed');
      }
    } catch (error) {
      print('Error sending image: $error');
      throw Exception('Error sending image');
    }
    ;
  }
}
