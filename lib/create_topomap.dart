import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;

class CreateTopomap extends StatefulWidget {
  const CreateTopomap({Key? key}) : super(key: key);

  @override
  _CreateTopomapState createState() => _CreateTopomapState();
}

class _CreateTopomapState extends State<CreateTopomap> {
  RTCPeerConnection? _peerConnection;
  final _localRenderer = RTCVideoRenderer();

  MediaStream? _localStream;

  RTCDataChannelInit? _dataChannelDict;
  RTCDataChannel? _dataChannel;
  String routeName = "topomap";

  // MediaStream? _localStream;
  bool _inCalling = false;

  // DateTime? _timeStart;

  bool _loading = false;

  final TextEditingController _routeController = TextEditingController();

  void _onTrack(RTCTrackEvent event) {
    print("TRACK EVENT: ${event.streams.map((e) => e.id)}, ${event.track.id}");
    if (event.track.kind == "video") {
      print("HERE");
      _localRenderer.srcObject = event.streams[0];
    }
  }

  void _onDataChannelState(RTCDataChannelState? state) {
    switch (state) {
      case RTCDataChannelState.RTCDataChannelClosed:
        print("Camera Closed!!!!!!!");
        break;
      case RTCDataChannelState.RTCDataChannelOpen:
        print("Camera Opened!!!!!!!");
        break;
      default:
        print("Data Channel State: $state");
    }
  }

  Future<bool> _waitForGatheringComplete(_) async {
    print("WAITING FOR GATHERING COMPLETE");
    if (_peerConnection!.iceGatheringState ==
        RTCIceGatheringState.RTCIceGatheringStateComplete) {
      return true;
    } else {
      await Future.delayed(Duration(seconds: 1));
      return await _waitForGatheringComplete(_);
    }
  }

  void _toggleCamera() async {
    if (_localStream == null) throw Exception('Stream is not initialized');

    final videoTrack = _localStream!
        .getVideoTracks()
        .firstWhere((track) => track.kind == 'video');
    await Helper.switchCamera(videoTrack);
  }

  Future<void> _negotiateRemoteConnection() async {
    return _peerConnection!
        .createOffer()
        .then((offer) {
          return _peerConnection!.setLocalDescription(offer);
        })
        .then(_waitForGatheringComplete)
        .then((_) async {
          var des = await _peerConnection!.getLocalDescription();
          var headers = {
            'Content-Type': 'application/json',
          };
          var request = http.Request(
            'POST',
            Uri.http(
                '192.168.42.101:9999','/offer'), // CHANGE URL HERE TO LOCAL SERVER
          );
          request.body = json.encode(
            {
              "sdp": des!.sdp,
              "type": des.type,
              "dir": routeName,
            },
          );
          request.headers.addAll(headers);

          http.StreamedResponse response = await request.send();

          String data = "";
          print(response);
          if (response.statusCode == 200) {
            data = await response.stream.bytesToString();
            var dataMap = json.decode(data);
            print(dataMap);
            await _peerConnection!.setRemoteDescription(
              RTCSessionDescription(
                dataMap["sdp"],
                dataMap["type"],
              ),
            );
          } else {
            print(response.reasonPhrase);
          }
        });
  }

  Future<void> _makeCall() async {
    setState(() {
      _loading = true;
    });
    var configuration = <String, dynamic>{
      'sdpSemantics': 'unified-plan',
    };

    //* Create Peer Connection
    if (_peerConnection != null) return;
    _peerConnection = await createPeerConnection(
      configuration,
    );

    _peerConnection!.onTrack = _onTrack;
    // _peerConnection!.onAddTrack = _onAddTrack;

    //* Create Data Channel
    _dataChannelDict = RTCDataChannelInit();
    _dataChannelDict!.ordered = true;
    _dataChannel = await _peerConnection!.createDataChannel(
      "chat",
      _dataChannelDict!,
    );
    _dataChannel!.onDataChannelState = _onDataChannelState;
    // _dataChannel!.onMessage = _onDataChannelMessage;

    final mediaConstraints = <String, dynamic>{
      'audio': false,
      'video': {
        'mandatory': {
          // 'minWidth':
          //     '1920', // Provide your own width, height and frame rate here
          // 'minHeight': '1080',
          'minFrameRate': '15',
          'maxFrameRate':'15',
        },
        // 'facingMode': 'user',
        'facingMode': 'environment',
        'optional': [],
      }
    };

    try {
      var stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      // _mediaDevicesList = await navigator.mediaDevices.enumerateDevices();
      _localStream = stream;
      // _localRenderer.srcObject = _localStream;

      stream.getTracks().forEach((element) {
        _peerConnection!.addTrack(element, stream);
      });

      print("NEGOTIATE");
      await _negotiateRemoteConnection();
    } catch (e) {
      print(e.toString());
    }
    if (!mounted) return;

    setState(() {
      _inCalling = true;
      _loading = false;
    });
  }

  Future<void> _stopCall() async {
    try {
      // await _localStream?.dispose();
      await _dataChannel?.close();
      await _peerConnection?.close();
      _peerConnection = null;
      _localRenderer.srcObject = null;
    } catch (e) {
      print(e.toString());
    }
    setState(() {
      _inCalling = false;
    });
  }

  Future<void> initLocalRenderers() async {
    await _localRenderer.initialize();
  }

  @override
  void initState() {
    super.initState();

    initLocalRenderers();
        _routeController.addListener(() {
      setState(() {
        routeName = _routeController.text;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
    title: const Text('Create Topomap'),
    leading: IconButton(
    icon: Icon(Icons.arrow_back),
    onPressed: () {
      Navigator.pop(context);
        },
      )
    ),
    body: OrientationBuilder(
      builder: (context, orientation) {
        return SafeArea(
          child: Stack(
            children: [
              // Video view in the background
              Positioned.fill(
                child: Container(
                  color: Colors.black,
                  child: _loading
                      ? Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                          ),
                        )
                      : RTCVideoView(
                          _localRenderer,
                        ),
                ),
              ),
              // Overlay controls
              Positioned(
                bottom: 20,
                left: 10,
                right: 10,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Route: ",
                              style: TextStyle(color: Colors.white),
                            ),
                              SizedBox(
                                width: 280,
                                child: TextField(
                                  controller: _routeController,
                                  style: TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.black54,
                                    hintText: 'N001 -> N005',
                                    hintStyle: TextStyle(color: Colors.white54),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                  onSubmitted: (value) {
                                    setState(() {
                                      routeName = value;
                                    });
                                  },
                                ),
                              ),
                          ],
                        ),
                        SizedBox(width: 20),
                      ],
                    ),
                    SizedBox(height: 10),
                    InkWell(
                      onTap: _loading
                          ? () {}
                          : _inCalling
                              ? _stopCall
                              : _makeCall,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _loading
                              ? Colors.amber
                              : _inCalling
                                  ? Colors.red
                                  : Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          child: _loading
                              ? Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(),
                                )
                              : Text(
                                  _inCalling ? "STOP" : "START",
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
              // Camera switch button
              if (_inCalling)
                Positioned(
                  bottom: 100,
                  right: 10,
                  child: InkWell(
                    onTap: _toggleCamera,
                    child: Container(
                      height: 50,
                      width: 50,
                      color: Colors.black26,
                      child: Center(
                        child: Icon(
                          Icons.cameraswitch,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}


}
