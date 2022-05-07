import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rxdart/rxdart.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MaterialApp(
      title: 'Geo Flutter Fire example',
      home: MyApp(),
      debugShowCheckedModeBanner: true,
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  GoogleMapController? _mapController;
  TextEditingController? _latitudeController, _longitudeController;

  // firestore init
  final radius = BehaviorSubject<double>.seeded(1.0);
  final _firestore = FirebaseFirestore.instance;
  final markers = <MarkerId, Marker>{};

  late Stream<List<DocumentSnapshot>> stream;
  late Geoflutterfire geo;

  double _value = 20.0;
  String _label = '';
  double _ratio = 0;

  double screenWidthKms = 600;

  @override
  void initState() {
    super.initState();
    _latitudeController = TextEditingController();
    _longitudeController = TextEditingController();

    geo = Geoflutterfire();
    GeoFirePoint center =
        geo.point(latitude: 43.0779575, longitude: 142.337819);
    stream = radius.switchMap(
      (rad) {
        final collectionReference = _firestore.collection('shop');

        return geo.collection(collectionRef: collectionReference).within(
            center: center, radius: rad, field: 'position', strictMode: true);
      },
    );

    //マップの横幅取得
    Future(() async {
      //_mapControllerがinitializeされるのを待つ1秒
      await Future.delayed(const Duration(seconds: 1));
      final region = await _mapController?.getVisibleRegion();
      final distanceInMeters = Geolocator.distanceBetween(
          region!.northeast.latitude,
          region.northeast.longitude,
          region.southwest.latitude,
          region.northeast.longitude);
      screenWidthKms = distanceInMeters / 1000;
      print('画面の横幅の距離　$screenWidthKms　km');
    });
  }

  @override
  void dispose() {
    _latitudeController?.dispose();
    _longitudeController?.dispose();
    radius.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Center(
              child: Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  height: 500,
                  child: Stack(
                    children: [
                      GoogleMap(
                        onMapCreated: _onMapCreated,
                        initialCameraPosition: const CameraPosition(
                          target: LatLng(43.0779575, 142.337819),
                          zoom: 6.5,
                        ),
                        markers: Set<Marker>.of(markers.values),
                      ),
                      Center(
                        child: Container(
                          width: MediaQuery.of(context).size.width * (_ratio),
                          height: MediaQuery.of(context).size.width * (_ratio),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Slider(
                min: 1,
                max: screenWidthKms / 2,
                divisions: 10,
                value: _value,
                label: _label,
                activeColor: Colors.blue,
                inactiveColor: Colors.blue.withOpacity(0.2),
                onChanged: (double value) {
                  setState(() {
                    _value = value;
                    _label = '${_value.toInt().toString()} kms';
                    _ratio = _value / (screenWidthKms / 2);
                    markers.clear();
                  });
                  radius.add(value);
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _latitudeController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'lat',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _longitudeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: 'lng',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        )),
                  ),
                ),
                MaterialButton(
                  color: Colors.blue,
                  onPressed: () {
                    final lat =
                        double.parse(_latitudeController?.text ?? '0.0');
                    final lng =
                        double.parse(_longitudeController?.text ?? '0.0');
                    _addPoint(lat, lng);
                  },
                  child: const Text(
                    'ADD',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) async {
    setState(() {
      _mapController = controller;
      //start listening after map is created
      stream.listen((List<DocumentSnapshot> documentList) {
        _updateMarkers(documentList);
      });
    });
  }

  void _addPoint(double lat, double lng) {
    GeoFirePoint geoFirePoint = geo.point(latitude: lat, longitude: lng);
    print(geoFirePoint.hash);
    print(geoFirePoint.geoPoint);
    print(geoFirePoint.data);
    print(geoFirePoint);
    _firestore
        .collection('shop')
        .add({'name': 'random name', 'position': geoFirePoint.data}).then((_) {
      print('added ${geoFirePoint.hash} successfully');
    });
  }

  void _addMarker(double lat, double lng) {
    final id = MarkerId(lat.toString() + lng.toString());
    final _marker = Marker(
      markerId: id,
      position: LatLng(lat, lng),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      infoWindow: InfoWindow(title: 'latLng', snippet: '$lat,$lng'),
    );
    setState(() {
      markers[id] = _marker;
    });
  }

  void _updateMarkers(List<DocumentSnapshot> documentList) {
    documentList.forEach((DocumentSnapshot document) {
      final data = document.data() as Map<String, dynamic>;
      final GeoPoint point = data['position']['geopoint'];
      _addMarker(point.latitude, point.longitude);
    });
  }
}
