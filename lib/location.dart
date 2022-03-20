import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as loc;

class LocationService {
  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;

  LocationSettings setupLocationSettings() {
    LocationSettings locationSettings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10,
        //(Optional) Set foreground notification config to keep the app alive
        //when going to the background
        // foregroundNotificationConfig: const ForegroundNotificationConfig(
        //     notificationText:
        //     "Example app will continue to receive your location even when you aren't using it",
        //     notificationTitle: "Running in Background",
        //     enableWakeLock: true,
        // )
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.best,
        activityType: ActivityType.fitness,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: true,
        // Only set to true if our app will be started up in the background.
        showBackgroundLocationIndicator: false,
      );
    } else {
      locationSettings = LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      );
    }
    return locationSettings;
  }

  Future<bool> locationEnabled() async {
    return await _geolocatorPlatform.isLocationServiceEnabled();
  }

  Future<bool> openLocationSettings() async {
    return await _geolocatorPlatform.openLocationSettings();
  }

  Future openAppSettings() async {
    return await _geolocatorPlatform.openAppSettings();
  }

  Future<LocationPermission> checkPermission() async {
    return await _geolocatorPlatform.checkPermission();
  }

  Future<LocationPermission?> requestPermission() async {
    return _geolocatorPlatform.requestPermission();
  }

  Future<Position?> getCurrentPosition() async {
    LocationPermission permission = await handlePermission();
    Position? position;
    Position? lastKnownPosition;
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      // if (Platform.isIOS) {
      //   return await firstIosPosition();
      // } else {
      try {
        lastKnownPosition = await _geolocatorPlatform.getLastKnownPosition();
        if (lastKnownPosition != null) {
          position = lastKnownPosition;
          return position;
        } else {
          position = await _geolocatorPlatform.getCurrentPosition(
            locationSettings: setupLocationSettings(),
          );
          return position;
        }
      } catch (e) {
        print("location error: $e");
      }
    }
    //}
    return position;
  }

  Future<Placemark?> getCurrentLocation() async {
    LocationPermission permission = await checkPermission();

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      Position position = await _geolocatorPlatform.getCurrentPosition();
      List<Placemark> addresses =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      return addresses.first;

      // address = first.locality + ', ' + first.administrativeArea + ', ' + first.isoCountryCode + ', ' + first.postalCode;

      // return address;
    } else {
      await requestPermission();
      return null;
    }
  }

  Stream<ServiceStatus> get locationServiceStatusStream =>
      _geolocatorPlatform.getServiceStatusStream();

  Stream<Position> get locationStream =>
      _geolocatorPlatform.getPositionStream();

  Future<bool> _checkLocationServiceStatus() async {
    return await _geolocatorPlatform.isLocationServiceEnabled();
  }

  Future<bool> requestLocationSettings() async {
    return await loc.Location().requestService();
  }

  Future<Position> firstIosPosition() {
    return _geolocatorPlatform
        .getPositionStream(locationSettings: setupLocationSettings())
        .first;
  }

  Future<Position?> locationSetup() async {
//First check is location setting is enabled on not on the device.
    bool serviceStatus = await _checkLocationServiceStatus();
    if (!serviceStatus) {
      //If location setting is disabled then request user to enable it.
      bool locationSettingEnabled = await requestLocationSettings();
      if (locationSettingEnabled) {
        return await getCurrentPosition();
      } else {
        print("please approve location permission");
      }
    } else {
      return await getCurrentPosition();
    }
    return null;
  }

  Future<LocationPermission> handlePermission() async {
    LocationPermission permission;

    permission = await _geolocatorPlatform.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocatorPlatform.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return permission;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return permission;
    }
    print("_handlePermission $permission");
    return permission;
  }
}
