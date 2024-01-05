import 'dart:typed_data';

import 'package:biopassid_face_sdk/biopassid_face_sdk.dart';
import 'package:flutter/material.dart';

class BioPassView extends StatefulWidget {
  const BioPassView({super.key});

  @override
  State<BioPassView> createState() => _BioPassViewState();
}

class _BioPassViewState extends State<BioPassView> {
  late FaceController controller;
  Uint8List? img;

  @override
  void initState() {
    super.initState();
    final config = FaceConfig(
      licenseKey: 'H5XH-2ERS-4CJJ-W4FA',
      titleText: FaceTextOptions(
        content: 'Align your face in the center of screen',
      ),
      loadingText: FaceTextOptions(
        enabled: true,
        content: 'Processing...',
        textColor: const Color(0xFFFFFFFF),
        textSize: 14,
      ),
      helpText: FaceTextOptions(
        enabled: true,
        content: 'Fit your face into the shape above',
        textColor: const Color(0xFFFFFFFF),
        textSize: 14,
      ),
      feedbackText: FaceFeedbackTextOptions(
        enabled: true,
        messages: FaceFeedbackTextMessages(
          noFaceDetectedMessage: 'No faces detected',
          multipleFacesDetectedMessage: 'Multiple faces detected',
          detectedFaceIsCenteredMessage: 'Keep your cell phone still',
          detectedFaceIsTooCloseMessage: 'Turn your face away from the camera',
          detectedFaceIsTooFarMessage: 'Move your face closer to the camera',
          detectedFaceIsOnTheLeftMessage: 'Move the cell phone to the right',
          detectedFaceIsOnTheRightMessage: 'Move the cell phone to the left',
          detectedFaceIsTooUpMessage: 'Move the cell phone down',
          detectedFaceIsTooDownMessage: 'Move the cell phone up',
          faceDetectionDisabledMessage: 'Facial detection disabled',
        ),
        textColor: const Color(0xFFFFFFFF),
        textSize: 14,
      ),
      faceDetection: FaceDetectionOptions(),
      mask: FaceMaskOptions(enabled: true),
    );
    controller = FaceController(
      config: config,
      onFaceCapture: (Uint8List image) {
        print('Image: $image');
        img = image;
        setState(() {});
      },
    );
  }

  void takeFace() async {
    await controller.takeFace();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Face Demo')),
      body: img != null
          ? Image.memory(img!)
          : Center(
              child: ElevatedButton(
                onPressed: takeFace,
                child: const Text('Capture Face'),
              ),
            ),
    );
  }
}
