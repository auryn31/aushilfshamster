import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui' as ui;

class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  static const MARKERID = "PositionMarkerID";
  static const INITIAL_LOCATION = LatLng(47.42796133580664, -122.085749655962);
  static const ZOOM_LEVEL = 16.4746;
  static var positionWidget = SvgPicture.asset("assets/maps_position.svg");

  Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = Set<Marker>();
  LocationData currentLocation;

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: INITIAL_LOCATION,
    zoom: ZOOM_LEVEL,
  );

  @override
  Widget build(BuildContext context) {
    _trackUser();
    return SafeArea(
      child: CupertinoPageScaffold(
          child: Stack(
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(0),
            child: GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: _kGooglePlex,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
                _setInitialMarker();
              },
              markers: _markers,
              myLocationButtonEnabled: false,
            ),
          ),
          Container(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: CupertinoTextField(
                      placeholder: "Suche", onChanged: (value) => print(value)),
                ),
                CupertinoButton(
                  child: Icon(CupertinoIcons.search),
                  onPressed: () {},
                )
              ],
            ),
            padding: EdgeInsets.all(16),
          ),
          new Positioned(
            child: new Align(
              alignment: FractionalOffset.bottomRight,
              child: CupertinoButton(
                child: Icon(CupertinoIcons.add),
                onPressed: () => _goToCurrentLocation(),
              ),
            ),
          ),
        ],
      )

          // floatingActionButton: CupertinoButton(
          //   onPressed: _goToCurrentLocation,
          //   child: Icon(CupertinoIcons.person),
          // ),
          ),
    );
  }

  Future<void> _setInitialMarker() async {
    BitmapDescriptor bitmapDescriptor = await _bitmapDescriptorFromSvgAsset(
        context, 'assets/maps_position.svg');
    setState(() {
      _markers = {
        Marker(
            markerId: MarkerId(MARKERID),
            position: currentLocation != null
                ? LatLng(currentLocation.latitude, currentLocation.longitude)
                : INITIAL_LOCATION,
            icon: bitmapDescriptor)
      };
    });
  }

  Future<void> _trackUser() async {
    Location location = new Location();

    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.DENIED) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.GRANTED) {
        return;
      }
    }

    location.onLocationChanged().listen((location) {
      _updateCurrentLocation(location);
    });
  }

  Future<void> _updateCurrentLocation(LocationData location) async {
    BitmapDescriptor bitmapDescriptor = await _bitmapDescriptorFromSvgAsset(
        context, 'assets/maps_position.svg');
    var marker = Marker(
        markerId: MarkerId(MARKERID),
        position: LatLng(location.latitude, location.longitude),
        icon: bitmapDescriptor);

    setState(() {
      currentLocation = location;
      _markers.removeWhere((m) => m.markerId.value == MARKERID);
      _markers.add(marker);
    });
  }

  Future<void> _goToCurrentLocation() async {
    if (currentLocation == null) {
      return;
    }
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(currentLocation.latitude, currentLocation.longitude),
          zoom: ZOOM_LEVEL,
        ),
      ),
    );
  }

  Future<BitmapDescriptor> _bitmapDescriptorFromSvgAsset(
      BuildContext context, String assetName) async {
    String svgString =
        await DefaultAssetBundle.of(context).loadString(assetName);
    DrawableRoot svgDrawableRoot = await svg.fromSvgString(svgString, null);

    MediaQueryData queryData = MediaQuery.of(context);
    double devicePixelRatio = queryData.devicePixelRatio;
    double width =
        32 * devicePixelRatio; // where 32 is your SVG's original width
    double height = 32 * devicePixelRatio; // same thing

    ui.Picture picture = svgDrawableRoot.toPicture(size: Size(width, height));

    ui.Image image = await picture.toImage(width.toInt(), height.toInt());
    ByteData bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes.buffer.asUint8List());
  }
}