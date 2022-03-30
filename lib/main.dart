import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geoflutterfire/geoflutterfire.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Google Maps Demo',
      home: MapSample(),
    );
  }
}

class MapSample extends StatefulWidget {
  const MapSample({Key? key}) : super(key: key);

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  late GoogleMapController _mapController;

  //初期位置を札幌駅に設定してます
  final CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(43.0686606, 141.3485613),
    zoom: 10,
  );

  final _firestore = FirebaseFirestore.instance;
  final geo = Geoflutterfire();

  List<Shop> shops = [];
  late Stream<List<DocumentSnapshot>> stream;

  @override
  void initState() {
    super.initState();

    GeoFirePoint center = geo.point(
      latitude: _initialCameraPosition.target.latitude,
      longitude: _initialCameraPosition.target.longitude,
    );

    var collectionReference = _firestore.collection('shop');

    double radius = 50;
    String field = 'position';

    stream = geo.collection(collectionRef: collectionReference).within(
          center: center,
          radius: radius,
          field: field,
          strictMode: true,
        );

    Future(() async {
      final snapshots = await stream.first;
      shops = snapshots.map((doc) => Shop(doc)).toList();
      print(shops);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DocumentSnapshot>>(
        stream: stream,
        builder: (
          BuildContext context,
          AsyncSnapshot<List<DocumentSnapshot>> snapshot,
        ) {
          if (!snapshot.hasData) {
            return const CircularProgressIndicator();
          }
          final shops = snapshot.data!.map((doc) => Shop(doc)).toList();
          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              _mapSection(shops),
              ElevatedButton(
                onPressed: () async {
                  final myLocation =
                      geo.point(latitude: 43.1711192, longitude: 141.3111701);
                  await _firestore
                      .collection('shop')
                      .add({'position': myLocation.data});
                },
                child: const Text('add'),
              ),
            ],
          );
        });
  }

  Widget _mapSection(List<Shop> shops) {
    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: _initialCameraPosition,
      myLocationEnabled: true,
      //現在位置をマップ上に表示
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
      },
      markers: shops.map(
            (selectedShop) {
          return Marker(
            markerId: MarkerId(selectedShop.uid!),
            icon: BitmapDescriptor.defaultMarker,
            onTap: () async {
              //タップしたマーカー(shop)のindexを取得
              final index = shops.indexWhere((shop) => shop == selectedShop);
              //タップしたお店がPageViewで表示されるように飛ばす
            },
          );
        },
      ).toSet(),
    );
  }
}

class Shop {
  Shop(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    uid = doc.id;
    name = data['name'] as String?;
    position = data['position'] as Map?;
  }

  String? uid;
  String? name;
  Map? position;
}
