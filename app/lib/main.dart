import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Upload Form',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const UploadFormPage(),
    );
  }
}

class UploadFormPage extends StatefulWidget {
  const UploadFormPage({super.key});

  @override
  _UploadFormPageState createState() => _UploadFormPageState();
}

class _UploadFormPageState extends State<UploadFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? _image1; // URL or null
  String? _image2; // URL or null
  String? _image3; // URL or null

  XFile? _selectedImage1; // For first image binary upload
  XFile? _selectedImage2; // For second image binary upload
  XFile? _selectedImage3; // For third image binary upload

  final List<String> dummyImages = [
    'https://picsum.photos/200/300',
    'https://picsum.photos/250/300',
    'https://picsum.photos/300/300',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-load dummy images on start
    _image1 = dummyImages[0];
    _image2 = dummyImages[1];
    _image3 = dummyImages[2];
  }

  Future<void> _pickImage(int imageIndex) async {
    final pickedImage = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        switch (imageIndex) {
          case 1:
            _selectedImage1 = pickedImage;
            _image1 = pickedImage.path;
            print("Selected first image: ${pickedImage.path}");
            break;
          case 2:
            _selectedImage2 = pickedImage;
            _image2 = pickedImage.path;
            print("Selected second image: ${pickedImage.path}");
            break;
          case 3:
            _selectedImage3 = pickedImage;
            _image3 = pickedImage.path;
            print("Selected third image: ${pickedImage.path}");
            break;
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() == true) {
      final formToSubmit = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.18.7:3000'),
      );

      print('Preparing request...');

      // Function to append valid images
      Future<void> appendImage(
          String keyPrefix, String? imageUrl, XFile? file, int index) async {
        if (file != null) {
          print('Appending binary file to request: ${file.path}');
          formToSubmit.files.add(
            await http.MultipartFile.fromPath(
              keyPrefix,
              file.path,
              filename: file.path.split('/').last,
            ),
          );
        } else if (imageUrl != null && imageUrl.isNotEmpty) {
          print('Appending string URL to request: $imageUrl');
          formToSubmit.fields['$keyPrefix[$index]'] = imageUrl;
        }
      }

      try {
        // List of images (can include null or empty values)
        final List<Map<String, dynamic>> images = [
          {'imageUrl': _image1, 'file': _selectedImage1},
          {'imageUrl': _image2, 'file': _selectedImage2},
          {'imageUrl': _image3, 'file': _selectedImage3},
        ];

        int validIndex = 0; // Counter for valid images
        final List<String> validImageUrls = []; // To store valid image URLs

        for (var image in images) {
          final imageUrl = image['imageUrl'] as String?;
          final file = image['file'] as XFile?;

          // Append only if the image URL or file is valid
          if ((imageUrl != null && imageUrl.isNotEmpty) || file != null) {
            await appendImage('images', imageUrl, file, validIndex);

            // Add to valid image URLs list only if it's a URL (not a file path)
            if (imageUrl != null && imageUrl.isNotEmpty && file == null) {
              validImageUrls.add(imageUrl);
              validIndex++; // Increment index only for valid images
            }
          }
        }

        // Log the valid image URLs to verify no temporary file paths are included
        print('Valid image URLs being sent: $validImageUrls');

        // Add the text field to the request
        formToSubmit.fields['textField'] = _textController.text;

        print('Sending request...');
        final response = await formToSubmit.send();

        if (response.statusCode == 200) {
          final responseBody = await response.stream.bytesToString();
          print('Response received: $responseBody');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Uploaded Successfully: $responseBody')),
          );
        } else {
          print('Upload failed with status code ${response.statusCode}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Upload failed')),
          );
        }
      } catch (e) {
        print('Exception during submission: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _resetForm() {
    setState(() {
      _textController.clear();
      _image1 = dummyImages[0];
      _image2 = dummyImages[1];
      _image3 = dummyImages[2];
      _selectedImage1 = null;
      _selectedImage2 = null;
      _selectedImage3 = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Form reset successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Form'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _textController,
                  decoration: const InputDecoration(labelText: 'Enter text'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'This field is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _imageSection(1, _image1, () => _pickImage(1)),
                const SizedBox(height: 16),
                _imageSection(2, _image2, () => _pickImage(2)),
                const SizedBox(height: 16),
                _imageSection(3, _image3, () => _pickImage(3)),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightGreen,
                  ),
                  child: const Text('Submit'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _resetForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlueAccent,
                  ),
                  child: const Text('Reset Form'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imageSection(int index, String? imagePath, VoidCallback onPressed) {
    return Row(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          child: Text('Select Image $index'),
        ),
        const SizedBox(width: 8),
        imagePath != null
            ? (imagePath.startsWith('http')
                ? Image.network(
                    imagePath,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    File(imagePath),
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ))
            : Image.network(
                dummyImages[index - 1],
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
      ],
    );
  }
}
