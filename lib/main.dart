import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Center(
            child: Text('セブの両替所'),
          ),
        ),
        body: MapCebu(),
      ),
    );
  }
}

class ExchangeMap extends StatefulWidget {
  @override
  _ExchangeMapState createState() => _ExchangeMapState();
}

class _ExchangeMapState extends State<ExchangeMap> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class MapCebu extends StatefulWidget {
  @override
  State<MapCebu> createState() => MapCebuState();
}

class MapCebuState extends State<MapCebu> {
  BitmapDescriptor pinLocationIcon = BitmapDescriptor.defaultMarkerWithHue(100);

  Future<Uint8List?> imageChangeUint8List(
      String path, int height, int width) async {
    //画像のpathを読み込む
    final ByteData byteData = await rootBundle.load(path);
    final Codec codec = await instantiateImageCodec(
      byteData.buffer.asUint8List(),
      //高さ
      targetHeight: height,
      //幅
      targetWidth: width,
    );
    final FrameInfo uiFI = await codec.getNextFrame();
    return (await uiFI.image.toByteData(format: ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  Future<void> pinMaker() async {
    final Uint8List? uintData =
        await imageChangeUint8List('assets/car_bus_11917.png', 100, 100);
    setState(() {
      pinLocationIcon = BitmapDescriptor.fromBytes(uintData!);
    });
  }

  @override
  void initState() {
    super.initState();

    Future(() async {
      await pinMaker();
    });

    setCustomMapPin();
  }

  Completer<GoogleMapController> _controller = Completer();

  final Set<Marker> markers = {};
  final List<LatLng> _markerLocations = [
    // Ayala
    const LatLng(10.318158, 123.904936),
    // IT Park
    const LatLng(10.328352, 123.905714),
    const LatLng(10.330698, 123.907295),
    // SM
    const LatLng(10.312147, 123.918603),
    // Banilad
    const LatLng(10.340961, 123.913004),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: 100, child: Image.asset('assets/car_bus_11917.png')),
          SizedBox(
            height: 600,
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(10.318158, 123.904936),
                bearing: 30,
                zoom: 13.4746,
              ),
              compassEnabled: false,
              myLocationEnabled: true,
              padding: const EdgeInsets.only(
                top: 400.0,
              ),
              markers: Set.from(
                _createMarker(),
              ),
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
            ),
          ),
        ],
      ),
    );
  }

  Set<Marker> _createMarker() {
    _markerLocations.asMap().forEach((i, markerLocation) {
      markers.add(
        Marker(
          markerId: MarkerId('myMarker{$i}'),
          position: markerLocation,
          icon: pinLocationIcon,
        ),
      );
    });

    return markers;
  }

  void setCustomMapPin() async {
    final pinLocationIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(devicePixelRatio: 100),
        'assets/car_bus_11917.png');
    setState(() {
      this.pinLocationIcon = pinLocationIcon;
    });
  }
}
