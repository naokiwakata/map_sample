import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
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

  // firestore init
  final radius = BehaviorSubject<double>.seeded(1.0);
  final _firestore = FirebaseFirestore.instance;
  final markers = <MarkerId, Marker>{};

  late Stream<List<DocumentSnapshot>> stream;
  late Geoflutterfire geo;

  @override
  void initState() {
    super.initState();

    geo = Geoflutterfire();
    GeoFirePoint center =
        geo.point(latitude: 43.0779575, longitude: 141.337819);
    stream = radius.switchMap(
      (rad) {
        final collectionReference = _firestore.collection('shop');

        return geo.collection(collectionRef: collectionReference).within(
            center: center, radius: 100, field: 'position', strictMode: false);
      },
    );

    //マップの横幅取得
    Future(() async {});
  }

  @override
  void dispose() {
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
                  height: 800,
                  child: Stack(
                    children: [
                      GoogleMap(
                        onMapCreated: _onMapCreated,
                        initialCameraPosition: const CameraPosition(
                          target: LatLng(43.0779575, 141.337819),
                          zoom: 12,
                        ),
                        markers: Set<Marker>.of(markers.values),
                      ),
                    ],
                  ),
                ),
              ),
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
