import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
import 'package:image_picker/image_picker.dart';
const kGoogleApiKey = "YOUR_GOOGLE_MAPS_API_KEY";

class CriminalCars extends StatefulWidget {
  const CriminalCars({super.key});

  @override
  State<CriminalCars> createState() => _CriminalCarsState();
}

class _CriminalCarsState extends State<CriminalCars> {

  // Longitude and latitude of user location
  double lat = 0.0;
  double lang = 0.0;

  // Image of car
  late File _image = File('');
  final picker = ImagePicker();

  // Image url from firebase storage
  String imageUrl = "";

  // Car no
  String carNo = "xxxxxxxxxx";

  DatabaseReference rto = FirebaseDatabase.instance.ref().child("RTO");

  // Pick image from the gallery
  Future getImageFromGallery() async {
    final XFile? pickedFile =
    await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  // Pick image from camera
  Future getImageFromCamera() async {
    final XFile? pickedFile =
    await picker.pickImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  // Image picking options
  Future showOptions() async {
    showCupertinoModalPopup(
      context: context,
      builder: (context) =>
          CupertinoActionSheet(
            actions: [
              CupertinoActionSheetAction(
                child: const Text('Photo Gallery'),
                onPressed: () {
                  // close the options modal
                  Navigator.of(context).pop();
                  // get image from gallery
                  getImageFromGallery();
                },
              ),
              CupertinoActionSheetAction(
                child: const Text('Camera'),
                onPressed: () {
                  // close the options modal
                  Navigator.of(context).pop();
                  // get image from camera
                  getImageFromCamera();
                },
              ),
            ],
          ),
    );
  }

  TextEditingController carLoc = TextEditingController();
  TextEditingController suggestion = TextEditingController();

  Future<void> _getAddressFromMap(double lat, double lang) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lang);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          carLoc.text = '${place.street}, ${place.subLocality}, ${place
              .subAdministrativeArea}, ${place.postalCode}';
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    Position? position;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled.Please enable the services')));
      }
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // return Future.error('Location permissions are denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        }
      }
    }

    if (permission == LocationPermission.deniedForever) {
      //return Future.error('Location permissions are permanently denied, we cannot request permissions.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      }
    }

    // Initialize a timeout duration in milliseconds (adjust as needed)
    const int locationTimeoutMs = 4000; // 4 seconds

    // Use the location package to get the location with a timeout
    try {
      position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          forceAndroidLocationManager: true).timeout(
          const Duration(milliseconds: locationTimeoutMs));
      setState(() {
        lang = position!.longitude;
        lat = position.latitude;
      });
    } catch (e) {
      // Location package didn't provide a location within the timeout, so use Geolocator
      Position? lastKnownLocation = await Geolocator.getLastKnownPosition();
      if (lastKnownLocation != null) {
        setState(() {
          lang = lastKnownLocation.longitude;
          lat = lastKnownLocation.latitude;
        });
      } else {
        // Handle the case where Geolocator also didn't provide a location
        // return Future.error('Unable to retrieve location.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to retrieve location.')));
        }
      }


      _getAddressFromMap(lat, lang);
    }
  }

  @override
  void initState() {
    getUserLocation();
    super.initState();
  }

  void selectLocation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PlacePicker(
              apiKey: Platform.isAndroid ? kGoogleApiKey : "YOUR_IOS_API_KEY",
              onPlacePicked: (result) {
                setState(() {
                  lat = result.geometry!.location.lat;
                  lang = result.geometry!.location.lng;
                });
                _getAddressFromMap(lat, lang);
                Navigator.of(context).pop();
              },
              initialPosition: LatLng(lat, lang),
              useCurrentLocation: true,
              resizeToAvoidBottomInset: false,
            ),
      ),
    );
  }

  // Function to submit report
  void submitReport() async {
    //unique id
    String uniqueFileName = DateTime
        .now()
        .millisecondsSinceEpoch
        .toString();

    //step1: pick image from gallery
    // ImagePicker imagepicker=ImagePicker();
    // XFile? file = await imagepicker.pickImage(source: ImageSource.gallery);

    // pic=file!.path;
    if (_image.path.isEmpty) return;

    //step2: Upload to firebase storage

    //get the ref to storage root
    Reference refenceroot = FirebaseStorage.instance.ref();

    //create a ref for the image to be stored
    Reference refImgtoUpload = refenceroot.child(uniqueFileName);

    //store the file
    try {
      await refImgtoUpload.putFile(_image);
      //get the download url
      imageUrl = await refImgtoUpload.getDownloadURL();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Something went wrong")));
      }
    }

    Map<String, String> data = {

      "ImageUrl": imageUrl,
      "Location": carLoc.text,
      "Lang": lang.toString(),
      "Lat": lat.toString(),
      "Suggestion": suggestion.text,
      "CarNo": carNo
    };

    rto.push().set(data);

    setState(() {
      _image = File('');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Abandoned Car'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: showOptions,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: _image.path.isEmpty
                      ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          size: 40,
                        ),
                        Text('Tap to add image')
                      ],
                    ),
                  )
                      : Image.file(
                    _image,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: carLoc,
                decoration: InputDecoration(
                  labelText: 'Car Location',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.teal),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.teal, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: selectLocation,
                child: const Text('Select Location'),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: suggestion,
                decoration: InputDecoration(
                  labelText: 'Suggestion',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.teal),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.teal, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: submitReport,
                child: const Text('Submit Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
