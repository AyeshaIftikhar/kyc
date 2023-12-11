// ignore_for_file: avoid_print

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kyc/face_matching.dart';
import 'package:kyc/views/face_detector_view.dart';
import 'package:kyc/painter/face_painter.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
  String image = '', newImage = '';
  bool processing = false;
  FaceDetector faceDetector = GoogleMlKit.vision.faceDetector(
    FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
    ),
  );
  CustomPaint? customPaint;

  Future<void> processImage(InputImage inputImage) async {
    if (processing) return;
    processing = true;
    final faces = await faceDetector.processImage(inputImage);
    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      final painter = FaceDetectorPainter(
        faces,
        inputImage.metadata!.size,
        inputImage.metadata!.rotation,
        CameraLensDirection.external,
      );
      customPaint = CustomPaint(painter: painter);
    } else {
      String text = 'Faces found: ${faces.length}\n\n';
      print(text);
      if (faces.isNotEmpty) {
        newImage = inputImage.filePath!;
      }
      customPaint = null;
    }

    processing = false;
    if (mounted) setState(() {});
  }

  void _incrementCounter() async {
    await ImagePicker()
        .pickImage(source: ImageSource.gallery)
        .then((value) async {
      if (value != null) {
        await processImage(InputImage.fromFilePath(value.path));
      }
    });
    setState(() {});
  }

  @override
  void dispose() {
    faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              processing
                  ? 'Processing'
                  : 'You have pushed the button this many times:',
            ),
            ExpansionTile(
              title: const Text('Vision APIs'),
              children: [
                CustomCard(
                  'Face Detection',
                  FaceDetectorView(
                    onDetected: (value) {
                      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                        setState(() {
                          image = value;
                        });
                      });
                    },
                  ),
                ),
                CustomCard('Match Faces', FaceMatchingScreen(image: image)),
              ],
            ),
            if (image != '') Image.file(File(image)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class CustomCard extends StatelessWidget {
  final String _label;
  final Widget _viewPage;
  final bool featureCompleted;

  const CustomCard(this._label, this._viewPage,
      {super.key, this.featureCompleted = true});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        tileColor: Theme.of(context).primaryColor,
        title: Text(
          _label,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onTap: () {
          if (!featureCompleted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('This feature has not been implemented yet')));
          } else {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => _viewPage));
          }
        },
      ),
    );
  }
}
