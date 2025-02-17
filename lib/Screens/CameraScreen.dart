import 'dart:math';
import 'package:camera/camera.dart';
import 'package:chatapp/Screens/CameraView.dart';
import 'package:chatapp/Screens/VideoView.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

// Initialize cameras outside the class to avoid null issues
List<CameraDescription> cameras = [];

class CameraScreen extends StatefulWidget {
  CameraScreen({Key? key}) : super(key: key); // Use Key?

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController; // Make it nullable
  Future<void>? cameraValue; // Make it nullable
  bool isRecoring = false;
  bool flash = false;
  bool iscamerafront = true;
  double transform = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (cameras.isNotEmpty) {
      _cameraController = CameraController(cameras[0], ResolutionPreset.high);
      try {
        cameraValue = _cameraController!.initialize(); // Use ! to assert non-null
      } catch (e) {
        print("Error initializing camera: $e");
        // Handle the error appropriately, e.g., show an error message
      }
    } else {
      print("No cameras available.");
      // Handle the case where no cameras are available
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose(); // Use ?. to avoid errors if null
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FutureBuilder(
            future: cameraValue,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: CameraPreview(_cameraController!), // Use ! here
                );
              } else {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          ),
          Positioned(
            bottom: 0.0,
            child: Container(
              color: Colors.black,
              padding: EdgeInsets.only(top: 5, bottom: 5),
              width: MediaQuery.of(context).size.width,
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(
                          flash ? Icons.flash_on : Icons.flash_off,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          setState(() {
                            flash = !flash;
                          });
                          if (_cameraController != null) {
                            flash
                                ? _cameraController!.setFlashMode(FlashMode.torch)
                                : _cameraController!.setFlashMode(FlashMode.off);
                          }
                        },
                      ),
                      GestureDetector(
                        onLongPress: () async {
                          if (_cameraController != null) {
                            await _cameraController!.startVideoRecording();
                            setState(() {
                              isRecoring = true;
                            });
                          }
                        },
                        onLongPressUp: () async {
                          if (_cameraController != null) {
                            XFile videopath =
                            await _cameraController!.stopVideoRecording();
                            setState(() {
                              isRecoring = false;
                            });
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (builder) => VideoViewPage(
                                  path: videopath.path,
                                ),
                              ),
                            );
                          }
                        },
                        onTap: () {
                          if (!isRecoring) takePhoto(context);
                        },
                        child: isRecoring
                            ? Icon(
                          Icons.radio_button_on,
                          color: Colors.red,
                          size: 80,
                        )
                            : Icon(
                          Icons.panorama_fish_eye,
                          color: Colors.white,
                          size: 70,
                        ),
                      ),
                      IconButton(
                        icon: Transform.rotate(
                          angle: transform,
                          child: Icon(
                            Icons.flip_camera_ios,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        onPressed: () async {
                          setState(() {
                            iscamerafront = !iscamerafront;
                            transform = transform + pi;
                          });
                          int cameraPos = iscamerafront ? 0 : 1;
                          if (cameras.length > cameraPos) {
                            _cameraController = CameraController(
                                cameras[cameraPos], ResolutionPreset.high);
                            try {
                              cameraValue = _cameraController!.initialize();
                            } catch (e) {
                              print("Error initializing camera: $e");
                            }
                          } else {
                            print("Camera position not available.");
                          }
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Hold for Video, tap for photo",
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void takePhoto(BuildContext context) async {
    if (_cameraController != null) {
      XFile file = await _cameraController!.takePicture();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (builder) => CameraViewPage(
            path: file.path,
          ),
        ),
      );
    }
  }
}