// ignore_for_file: avoid_print

import 'dart:io';
// import 'package:tflite/tflite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class MaskDetectorView extends StatefulWidget {
  const MaskDetectorView({super.key});

  @override
  State<MaskDetectorView> createState() => _MaskDetectorViewState();
}

class _MaskDetectorViewState extends State<MaskDetectorView> {
  File? _imageFile;
  List? _classifiedResult;
  late Interpreter _interpreter;
  late List<String> _labels;
  Image? _imagefile;
  

  @override
  void initState() {
    super.initState();
    _loadModel();
   
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mask Detection")),
      body: Center(
        child: Column(
          children: [
            Container(
                margin: const EdgeInsets.all(15),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(15),
                  ),
                  border: Border.all(color: Colors.white),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      offset: Offset(2, 2),
                      spreadRadius: 2,
                      blurRadius: 1,
                    ),
                  ],
                ),
                child: (_imageFile != null)
                    ? Image.file(_imageFile!)
                    : Image.network('https://i.imgur.com/sUFH1Aq.png')),
            ElevatedButton(
              onPressed: () {
                selectImage();
              },
              child: const Icon(Icons.camera),
            ),
            const SizedBox(height: 20),
            if(_imagefile != null) _imagefile ?? Container(),
            // SingleChildScrollView(
            //   child: Column(
            //     children: _classifiedResult == null
            //         ? <Widget>[]
            //         : List.generate(
            //             _classifiedResult!.length,
            //             (index) {
            //               final result = _classifiedResult![index];
            //               return Card(
            //                 elevation: 0.0,
            //                 color: Colors.lightBlue,
            //                 child: Container(
            //                   width: 300,
            //                   margin: const EdgeInsets.all(10),
            //                   child: Center(
            //                     child: Text(
            //                       "${result["label"]} :  ${(result["confidence"] * 100).toStringAsFixed(1)}%",
            //                       style: const TextStyle(
            //                           color: Colors.black,
            //                           fontSize: 18.0,
            //                           fontWeight: FontWeight.bold),
            //                     ),
            //                   ),
            //                 ),
            //               );
            //             },
            //           ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Future selectImage() async {
    final picker = ImagePicker();
    var _image = await picker.pickImage(source: ImageSource.gallery);
    final imageData = File(_image!.path).readAsBytesSync();

// Decoding image
    final image = img.decodeImage(imageData);

// Resizing image fpr model, [300, 300]
    final imageInput = img.copyResize(
      image!,
      width: 300,
      height: 300,
    );

// Creating matrix representation, [300, 300, 3]
    final imageMatrix = List.generate(
      imageInput.height,
      (y) => List.generate(
        imageInput.width,
        (x) {
          final pixel = imageInput.getPixel(x, y);
          return [pixel.r, pixel.g, pixel.b];
        },
      ),
    );

// pass the imageMatrix to run on model
    final output = _runInference(imageMatrix);
    print('Processing outputs...');
// Location
    final locationsRaw = output.first.first as List<List<double>>;
    final locations = locationsRaw.map((list) {
      return list.map((value) => (value * 300).toInt()).toList();
    }).toList();
    print('Locations: $locations');

// Classes
    final classesRaw = output.elementAt(1).first as List<double>;
    final classes = classesRaw.map((value) => value.toInt()).toList();
    print('Classes: $classes');

// Scores
    final scores = output.elementAt(2).first as List<double>;
    print('Scores: $scores');

// Number of detections
    final numberOfDetectionsRaw = output.last.first as double;
    final numberOfDetections = numberOfDetectionsRaw.toInt();
    print('Number of detections: $numberOfDetections');

    print('Classifying detected objects...');
    final List<String> classication = [];
    for (var i = 0; i < numberOfDetections; i++) {
      classication.add(_labels![classes[i]]);
    }

    print('Outlining objects...');
    for (var i = 0; i < numberOfDetections; i++) {
      if (scores[i] > 0.6) {
        // Rectangle drawing
        img.drawRect(
          imageInput,
          x1: locations[i][1],
          y1: locations[i][0],
          x2: locations[i][3],
          y2: locations[i][2],
          color: img.ColorRgb8(255, 0, 0),
          thickness: 3,
        );

        // Label drawing
        img.drawString(
          imageInput,
          '${classication[i]} ${scores[i]}',
          font: img.arial14,
          x: locations[i][1] + 1,
          y: locations[i][0] + 1,
          color: img.ColorRgb8(255, 0, 0),
        );
      }
    }

    print('Done.');

    final outputImage = img.encodeJpg(imageInput);
    _imagefile = Image.memory(outputImage!);
  }

  /// Load tflite model from assets
  Future<void> _loadModel() async {
    print('Loading interpreter options...');
    final interpreterOptions = InterpreterOptions();

    // Use XNNPACK Delegate
    if (Platform.isAndroid) {
      interpreterOptions.addDelegate(XNNPackDelegate());
    }

    // Use Metal Delegate
    if (Platform.isIOS) {
      interpreterOptions.addDelegate(GpuDelegate());
    }

    print('Loading interpreter...');
    _interpreter = await Interpreter.fromAsset(
      'assets/model.tflite',
      options: interpreterOptions,
    );
    _loadLabels();
  }

  /// Load Labels from assets
  Future<void> _loadLabels() async {
    print('Loading labels...');
    final labelsRaw =
        await rootBundle.loadString('assets/labels.txt');
    _labels = labelsRaw.split('\n');
  }

  List<List<Object>> _runInference(
    List<List<List<num>>> imageMatrix,
  ) {
    print('Running inference...');

    // Set input tensor [1, 300, 300, 3]
    final input = [imageMatrix];

    // Set output tensor
    // Locations: [1, 10, 4]
    // Classes: [1, 10],
    // Scores: [1, 10],
    // Number of detections: [1]
    final output = {
      0: [List<List<num>>.filled(10, List<num>.filled(4, 0))],
      1: [List<num>.filled(10, 0)],
      2: [List<num>.filled(10, 0)],
      3: [0.0],
    };

    _interpreter!.runForMultipleInputs([input], output);
    return output.values.toList();
  }
}
