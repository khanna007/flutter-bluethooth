//import 'package:flutter/material.dart';
//import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
//
//import 'package:provider/provider.dart';
//
//import 'ble_device_connector.dart';
//import 'ble_scanner.dart';
//import 'ble_status_monitor.dart';
//import 'ble_status_screen.dart';
//import 'device_list.dart';
//
//const _themeColor = Colors.lightGreen;
//
//void main() {
//  WidgetsFlutterBinding.ensureInitialized();
//
//  final _ble = FlutterReactiveBle();
//  final _scanner = BleScanner(_ble);
//  final _monitor = BleStatusMonitor(_ble);
//  final _connector = BleDeviceConnector(_ble);
//  runApp(
//    MultiProvider(
//      providers: [
//        Provider.value(value: _scanner),
//        Provider.value(value: _monitor),
//        Provider.value(value: _connector),
//        StreamProvider<BleScannerState>(
//          create: (_) => _scanner.state,
//          initialData: const BleScannerState(
//            discoveredDevices: [],
//            scanIsInProgress: false,
//          ),
//        ),
//        StreamProvider<BleStatus>(
//          create: (_) => _monitor.state,
//          initialData: BleStatus.unknown,
//        ),
//        StreamProvider<ConnectionStateUpdate>(
//          create: (_) => _connector.state,
//          initialData: const ConnectionStateUpdate(
//            deviceId: 'Unknown device',
//            connectionState: DeviceConnectionState.disconnected,
//            failure: null,
//          ),
//        ),
//      ],
//      child: MaterialApp(
//        title: 'Flutter Reactive BLE example',
//        color: _themeColor,
//        theme: ThemeData(primarySwatch: _themeColor),
//        home: HomeScreen(),
//      ),
//    ),
//  );
//}
//
//class HomeScreen extends StatelessWidget {
//  @override
//  Widget build(BuildContext context) => Consumer<BleStatus>(
//    builder: (_, status, __) {
//      if (status == BleStatus.ready) {
//        return DeviceListScreen();
//      } else {
//        return BleStatusScreen(status: status);
//      }
//    },
//  );
//}

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_app_bluethooth/widgets.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

void main() {
  runApp(FlutterBlueApp());
}


class FlutterBlueApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.lightBlue,
      home: StreamBuilder<BluetoothState>(
          stream: FlutterBlue.instance.state,
          initialData: BluetoothState.unknown,
          builder: (c, snapshot) {
            final state = snapshot.data;
            if (state == BluetoothState.on) {
              return FindDevicesScreen();
            }
            return BluetoothOffScreen(state: state);
          }),
    );
  }
}

class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({Key key, this.state}) : super(key: key);

  final BluetoothState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.bluetooth_disabled,
              size: 200.0,
              color: Colors.white54,
            ),
            Text(
              'Bluetooth Adapter is ${state != null ? state.toString().substring(15) : 'not available'}.',
              style: Theme.of(context)
                  .primaryTextTheme
                  .subhead
                  .copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class FindDevicesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Find Devices'),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            FlutterBlue.instance.startScan(timeout: Duration(seconds: 4),
            ),

        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              StreamBuilder<List<ScanResult>>(
                stream: FlutterBlue.instance.scanResults,
                initialData: [],
                builder: (c, snapshot) => Column(
                  children: snapshot.data
                      .map(
                        (r) => ScanResultTile(
                      result: r,
                    ),
                  )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: FlutterBlue.instance.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data) {
            return FloatingActionButton(
              child: Icon(Icons.stop),
              onPressed: () => FlutterBlue.instance.stopScan(),
              backgroundColor: Colors.red,
            );
          } else {
            return FloatingActionButton(
                child: Icon(Icons.search),
                onPressed: () => FlutterBlue.instance
                    .startScan(timeout: Duration(seconds: 4)));
          }
        },
      ),
    );
  }
}

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({Key key, this.device}) : super(key: key);

  final BluetoothDevice device;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(device.name),
        actions: <Widget>[
          StreamBuilder<BluetoothDeviceState>(
            stream: device.state,
            initialData: BluetoothDeviceState.connecting,
            builder: (c, snapshot) {
              VoidCallback onPressed;
              String text;
              switch (snapshot.data) {
                case BluetoothDeviceState.connected:
                  onPressed = () => device.disconnect();
                  text = 'DISCONNECT';
                  break;
                case BluetoothDeviceState.disconnected:
                  onPressed = () => device.connect();
                  text = 'CONNECT';
                  break;
                default:
                  onPressed = null;
                  text = snapshot.data.toString().substring(21).toUpperCase();
                  break;
              }
              return FlatButton(
                  onPressed: onPressed,
                  child: Text(
                    text,
                    style: Theme.of(context)
                        .primaryTextTheme
                        .button
                        .copyWith(color: Colors.white),
                  ));
            },
          )
        ],
      ),
    );
  }
}

class ScanResultTile extends StatelessWidget {
  const ScanResultTile({Key key, this.result, this.onTap}) : super(key: key);

  final ScanResult result;
  final VoidCallback onTap;

  Widget _buildTitle(BuildContext context) {
    if (result.device.name.length > 0) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            result.device.name,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            result.device.id.toString(),
            style: Theme.of(context).textTheme.caption,
          )
        ],
      );
    } else {
      return Text(result.device.id.toString());
    }
  }

  Widget _buildAdvRow(BuildContext context, String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.caption),
          SizedBox(
            width: 12.0,
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .caption
                  .apply(color: Colors.black),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  String getNiceHexArray(List<int> bytes) {
    return '[${bytes.map((i) => i.toRadixString(16).padLeft(2, '0')).join(', ')}]'
        .toUpperCase();
  }

  String getNiceManufacturerData(Map<int, List<int>> data) {
    if (data.isEmpty) {
      return null;
    }
    List<String> res = [];
    data.forEach((id, bytes) {
      res.add(
          '${id.toRadixString(16).toUpperCase()}: ${getNiceHexArray(bytes)}');
    });
    return res.join(', ');
  }

  String getNiceServiceData(Map<String, List<int>> data) {
    if (data.isEmpty) {
      return null;
    }
    List<String> res = [];
    data.forEach((id, bytes) {
      res.add('${id.toUpperCase()}: ${getNiceHexArray(bytes)}');
    });
    return res.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: _buildTitle(context),
      leading: Text("rssi${result.rssi.toString()}"),
      trailing: RaisedButton(
        child: Text('CONNECT'),
        color: Colors.black,
        textColor: Colors.white,
        onPressed: (result.advertisementData.connectable) ? onTap : null,
      ),
      children: <Widget>[
        _buildAdvRow(
            context, 'Complete Local Name', result.advertisementData.localName),
        _buildAdvRow(context, 'Tx Power Level',
            '${result.advertisementData.txPowerLevel ?? 'N/A'}'),
        _buildAdvRow(
            context,
            'Manufacturer Data',
            getNiceManufacturerData(
                result.advertisementData.manufacturerData) ??
                'N/A'),
        _buildAdvRow(
            context,
            'Service UUIDs',
            (result.advertisementData.serviceUuids.isNotEmpty)
                ? result.advertisementData.serviceUuids.join(', ').toUpperCase()
                : 'N/A'),
        _buildAdvRow(context, 'Service Data',
            getNiceServiceData(result.advertisementData.serviceData) ?? 'N/A'),
      ],
    );
  }
}

//import 'dart:io';
//
//import 'package:flutter/material.dart';
//import 'dart:async';
//
//import 'package:flutter/services.dart';
//import 'package:flutter_beacon/flutter_beacon.dart';
//
//class FlutterBlueApp extends StatefulWidget {
//  @override
//  _MyAppState createState() => _MyAppState();
//}
//
//class _MyAppState extends State<FlutterBlueApp> with WidgetsBindingObserver {
//  final StreamController<BluetoothState> streamController = StreamController();
//  StreamSubscription<BluetoothState> _streamBluetooth;
//  StreamSubscription<RangingResult> _streamRanging;
//  final _regionBeacons = <Region, List<Beacon>>{};
//  final _beacons = <Beacon>[];
//  bool authorizationStatusOk = false;
//  bool locationServiceEnabled = false;
//  bool bluetoothEnabled = false;
//
//  @override
//  void initState() {
//    WidgetsBinding.instance.addObserver(this);
//    print("_beacons$_beacons");
//    super.initState();
//
//    listeningState();
//  }
//
//  listeningState() async {
//    print('Listening to bluetooth state');
//    _streamBluetooth = flutterBeacon
//        .bluetoothStateChanged()
//        .listen((BluetoothState state) async {
//      print('BluetoothState = $state');
//      streamController.add(state);
//
//      switch (state) {
//        case BluetoothState.stateOn:
//          initScanBeacon();
//          break;
//        case BluetoothState.stateOff:
//          await pauseScanBeacon();
//          await checkAllRequirements();
//          break;
//      }
//    });
//  }
//
//  checkAllRequirements() async {
//    final bluetoothState = await flutterBeacon.bluetoothState;
//    final bluetoothEnabled = bluetoothState == BluetoothState.stateOn;
//    final authorizationStatus = await flutterBeacon.authorizationStatus;
//    final authorizationStatusOk =
//        authorizationStatus == AuthorizationStatus.allowed ||
//            authorizationStatus == AuthorizationStatus.always;
//    final locationServiceEnabled =
//        await flutterBeacon.checkLocationServicesIfEnabled;
//
//    setState(() {
//      this.authorizationStatusOk = authorizationStatusOk;
//      this.locationServiceEnabled = locationServiceEnabled;
//      this.bluetoothEnabled = bluetoothEnabled;
//    });
//  }
//
//  initScanBeacon() async {
//    await flutterBeacon.initializeScanning;
//    await checkAllRequirements();
//    if (!authorizationStatusOk ||
//        !locationServiceEnabled ||
//        !bluetoothEnabled) {
//      print('RETURNED, authorizationStatusOk=$authorizationStatusOk, '
//          'locationServiceEnabled=$locationServiceEnabled, '
//          'bluetoothEnabled=$bluetoothEnabled');
//      return;
//    }
//    final regions = <Region>[
//      Region(
//        identifier: 'Cubeacon',
//        proximityUUID: 'CB10023F-A318-3394-4199-A8730C7C1AEC',
//      ),
//    ];
//
//    if (_streamRanging != null) {
//      if (_streamRanging.isPaused) {
//        _streamRanging.resume();
//        return;
//      }
//    }
//
//    _streamRanging =
//        flutterBeacon.ranging(regions).listen((RangingResult result) {
//      print("result$result");
//      if (result != null && mounted) {
//        setState(() {
//          _regionBeacons[result.region] = result.beacons;
//          _beacons.clear();
//          _regionBeacons.values.forEach((list) {
//            _beacons.addAll(list);
//          });
//          _beacons.sort(_compareParameters);
//        });
//      }
//    });
//  }
//
//  pauseScanBeacon() async {
//    _streamRanging?.pause();
//    if (_beacons.isNotEmpty) {
//      setState(() {
//        _beacons.clear();
//      });
//    }
//  }
//
//  int _compareParameters(Beacon a, Beacon b) {
//    int compare = a.proximityUUID.compareTo(b.proximityUUID);
//
//    if (compare == 0) {
//      compare = a.major.compareTo(b.major);
//    }
//
//    if (compare == 0) {
//      compare = a.minor.compareTo(b.minor);
//    }
//
//    return compare;
//  }
//
//  @override
//  void didChangeAppLifecycleState(AppLifecycleState state) async {
//    print('AppLifecycleState = $state');
//    if (state == AppLifecycleState.resumed) {
//      if (_streamBluetooth != null && _streamBluetooth.isPaused) {
//        _streamBluetooth.resume();
//      }
//      await checkAllRequirements();
//      if (authorizationStatusOk && locationServiceEnabled && bluetoothEnabled) {
//        await initScanBeacon();
//      } else {
//        await pauseScanBeacon();
//        await checkAllRequirements();
//      }
//    } else if (state == AppLifecycleState.paused) {
//      _streamBluetooth?.pause();
//    }
//  }
//
//  @override
//  void dispose() {
//    WidgetsBinding.instance.removeObserver(this);
//    streamController?.close();
//    _streamRanging?.cancel();
//    _streamBluetooth?.cancel();
//    flutterBeacon.close;
//
//    super.dispose();
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    return MaterialApp(
//      theme: ThemeData(
//        brightness: Brightness.light,
//        primaryColor: Colors.white,
//      ),
//      darkTheme: ThemeData(
//        brightness: Brightness.dark,
//      ),
//      home: Scaffold(
//        appBar: AppBar(
//          title: const Text('Flutter Beacon'),
//          centerTitle: false,
//          actions: <Widget>[
//            if (!authorizationStatusOk)
//              IconButton(
//                  icon: Icon(Icons.portable_wifi_off),
//                  color: Colors.red,
//                  onPressed: () async {
//                    await flutterBeacon.requestAuthorization;
//                  }),
//            if (!locationServiceEnabled)
//              IconButton(
//                  icon: Icon(Icons.location_off),
//                  color: Colors.red,
//                  onPressed: () async {
//                    if (Platform.isAndroid) {
//                      await flutterBeacon.openLocationSettings;
//                    } else if (Platform.isIOS) {}
//                  }),
//            StreamBuilder<BluetoothState>(
//              builder: (context, snapshot) {
//                if (snapshot.hasData) {
//                  final state = snapshot.data;
//
//                  if (state == BluetoothState.stateOn) {
//                    return IconButton(
//                      icon: Icon(Icons.bluetooth_connected),
//                      onPressed: () {},
//                      color: Colors.lightBlueAccent,
//                    );
//                  }
//
//                  if (state == BluetoothState.stateOff) {
//                    return IconButton(
//                      icon: Icon(Icons.bluetooth),
//                      onPressed: () async {
//                        if (Platform.isAndroid) {
//                          try {
//                            await flutterBeacon.openBluetoothSettings;
//                          } on PlatformException catch (e) {
//                            print(e);
//                          }
//                        } else if (Platform.isIOS) {}
//                      },
//                      color: Colors.red,
//                    );
//                  }
//
//                  return IconButton(
//                    icon: Icon(Icons.bluetooth_disabled),
//                    onPressed: () {},
//                    color: Colors.grey,
//                  );
//                }
//
//                return SizedBox.shrink();
//              },
//              stream: streamController.stream,
//              initialData: BluetoothState.stateUnknown,
//            ),
//          ],
//        ),
//        body: _beacons == null || _beacons.isEmpty
//            ? Center(child: CircularProgressIndicator())
//            : ListView(
//                children: ListTile.divideTiles(
//                    context: context,
//                    tiles: _beacons.map((beacon) {
//                      return ListTile(
//
//                        title: Text(beacon.proximityUUID),
//                        subtitle: new Row(
//                          mainAxisSize: MainAxisSize.max,
//                          children: <Widget>[
//                            Flexible(
//                                child: Text(
//                                    'Major: ${beacon.major}\nMinor: ${beacon.minor}',
//                                    style: TextStyle(fontSize: 13.0)),
//                                flex: 1,
//                                fit: FlexFit.tight),
//                            Flexible(
//                                child: Text(
//                                    'Accuracy: ${beacon.accuracy}m\nRSSI: ${beacon.rssi}',
//                                    style: TextStyle(fontSize: 13.0)),
//                                flex: 2,
//                                fit: FlexFit.tight)
//                          ],
//                        ),
//                      );
//                    })).toList(),
//              ),
//      ),
//    );
//  }
//}

//class FlutterBlueApp extends StatelessWidget {
//  @override
//  Widget build(BuildContext context) {
//    return MaterialApp(
//      color: Colors.lightBlue,
//      home: StreamBuilder<BluetoothState>(
//          stream: FlutterBlue.instance.state,
//          initialData: BluetoothState.unknown,
//          builder: (c, snapshot) {
//            final state = snapshot.data;
//            if (state == BluetoothState.on) {
//              return FindDevicesScreen();
//            }
//            return BluetoothOffScreen(state: state);
//          }),
//    );
//  }
//}
//
//class BluetoothOffScreen extends StatelessWidget {
//  const BluetoothOffScreen({Key key, this.state}) : super(key: key);
//
//  final BluetoothState state;
//
//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//      backgroundColor: Colors.lightBlue,
//      body: Center(
//        child: Column(
//          mainAxisSize: MainAxisSize.min,
//          children: <Widget>[
//            Icon(
//              Icons.bluetooth_disabled,
//              size: 200.0,
//              color: Colors.white54,
//            ),
//            Text(
//              'Bluetooth Adapter is ${state != null ? state.toString().substring(15) : 'not available'}.',
//              style: Theme.of(context)
//                  .primaryTextTheme
//                  .subhead
//                  .copyWith(color: Colors.white),
//            ),
//          ],
//        ),
//      ),
//    );
//  }
//}
//
//class FindDevicesScreen extends StatelessWidget {
//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//      appBar: AppBar(
//        title: Text('Find Devices'),
//      ),
//      body: RefreshIndicator(
//        onRefresh: () =>
//            FlutterBlue.instance.startScan(timeout: Duration(seconds: 4)),
//        child: SingleChildScrollView(
//          child: Column(
//            children: <Widget>[
//              StreamBuilder<List<BluetoothDevice>>(
//                stream: Stream.periodic(Duration(seconds: 2))
//                    .asyncMap((_) => FlutterBlue.instance.connectedDevices),
//                initialData: [],
//                builder: (c, snapshot) => Column(
//                  children: snapshot.data
//                      .map((d) => ListTile(
//                    title: Text(d.name),
//                    subtitle: Text(d.id.toString()),
//                    trailing: StreamBuilder<BluetoothDeviceState>(
//                      stream: d.state,
//                      initialData: BluetoothDeviceState.disconnected,
//                      builder: (c, snapshot) {
//                        if (snapshot.data ==
//                            BluetoothDeviceState.connected) {
//                          return RaisedButton(
//                            child: Text('OPEN'),
//                            onPressed: () => Navigator.of(context).push(
//                                MaterialPageRoute(
//                                    builder: (context) =>
//                                        DeviceScreen(device: d))),
//                          );
//                        }
//                        return Text(snapshot.data.toString());
//                      },
//                    ),
//                  ))
//                      .toList(),
//                ),
//              ),
//              StreamBuilder<List<ScanResult>>(
//                stream: FlutterBlue.instance.scanResults,
//                initialData: [],
//                builder: (c, snapshot) => Column(
//                  children: snapshot.data
//                      .map(
//                        (r) => ScanResultTile(
//                      result: r,
//                      onTap: () => Navigator.of(context)
//                          .push(MaterialPageRoute(builder: (context) {
//                        r.device.connect();
//                        return DeviceScreen(device: r.device);
//                      })),
//                    ),
//                  )
//                      .toList(),
//                ),
//              ),
//            ],
//          ),
//        ),
//      ),
//      floatingActionButton: StreamBuilder<bool>(
//        stream: FlutterBlue.instance.isScanning,
//        initialData: false,
//        builder: (c, snapshot) {
//          if (snapshot.data) {
//            return FloatingActionButton(
//              child: Icon(Icons.stop),
//              onPressed: () => FlutterBlue.instance.stopScan(),
//              backgroundColor: Colors.red,
//            );
//          } else {
//            return FloatingActionButton(
//                child: Icon(Icons.search),
//                onPressed: () => FlutterBlue.instance
//                    .startScan(timeout: Duration(seconds: 4)));
//          }
//        },
//      ),
//    );
//  }
//}
//
//class DeviceScreen extends StatelessWidget {
//  const DeviceScreen({Key key, this.device}) : super(key: key);
//
//  final BluetoothDevice device;
//
//  List<int> _getRandomBytes() {
//    final math = Random();
//    return [
//      math.nextInt(255),
//      math.nextInt(255),
//      math.nextInt(255),
//      math.nextInt(255)
//    ];
//  }
//
//  List<Widget> _buildServiceTiles(List<BluetoothService> services) {
//    return services
//        .map(
//          (s) => ServiceTile(
//        service: s,
//        characteristicTiles: s.characteristics
//            .map(
//              (c) => CharacteristicTile(
//            characteristic: c,
//            onReadPressed: () => c.read(),
//            onWritePressed: () async {
//              await c.write(_getRandomBytes(), withoutResponse: true);
//              await c.read();
//            },
//            onNotificationPressed: () async {
//              await c.setNotifyValue(!c.isNotifying);
//              await c.read();
//            },
//            descriptorTiles: c.descriptors
//                .map(
//                  (d) => DescriptorTile(
//                descriptor: d,
//                onReadPressed: () => d.read(),
//                onWritePressed: () => d.write(_getRandomBytes()),
//              ),
//            )
//                .toList(),
//          ),
//        )
//            .toList(),
//      ),
//    )
//        .toList();
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//      appBar: AppBar(
//        title: Text(device.name),
//        actions: <Widget>[
//          StreamBuilder<BluetoothDeviceState>(
//            stream: device.state,
//            initialData: BluetoothDeviceState.connecting,
//            builder: (c, snapshot) {
//              VoidCallback onPressed;
//              String text;
//              switch (snapshot.data) {
//                case BluetoothDeviceState.connected:
//                  onPressed = () => device.disconnect();
//                  text = 'DISCONNECT';
//                  break;
//                case BluetoothDeviceState.disconnected:
//                  onPressed = () => device.connect();
//                  text = 'CONNECT';
//                  break;
//                default:
//                  onPressed = null;
//                  text = snapshot.data.toString().substring(21).toUpperCase();
//                  break;
//              }
//              return FlatButton(
//                  onPressed: onPressed,
//                  child: Text(
//                    text,
//                    style: Theme.of(context)
//                        .primaryTextTheme
//                        .button
//                        .copyWith(color: Colors.white),
//                  ));
//            },
//          )
//        ],
//      ),
//      body: SingleChildScrollView(
//        child: Column(
//          children: <Widget>[
//            StreamBuilder<BluetoothDeviceState>(
//              stream: device.state,
//              initialData: BluetoothDeviceState.connecting,
//              builder: (c, snapshot) => ListTile(
//                leading: (snapshot.data == BluetoothDeviceState.connected)
//                    ? Icon(Icons.bluetooth_connected)
//                    : Icon(Icons.bluetooth_disabled),
//                title: Text(
//                    'Device is ${snapshot.data.toString().split('.')[1]}.'),
//                subtitle: Text('${device.id}'),
//                trailing: StreamBuilder<bool>(
//                  stream: device.isDiscoveringServices,
//                  initialData: false,
//                  builder: (c, snapshot) => IndexedStack(
//                    index: snapshot.data ? 1 : 0,
//                    children: <Widget>[
//                      IconButton(
//                        icon: Icon(Icons.refresh),
//                        onPressed: () => device.discoverServices(),
//                      ),
//                      IconButton(
//                        icon: SizedBox(
//                          child: CircularProgressIndicator(
//                            valueColor: AlwaysStoppedAnimation(Colors.grey),
//                          ),
//                          width: 18.0,
//                          height: 18.0,
//                        ),
//                        onPressed: null,
//                      )
//                    ],
//                  ),
//                ),
//              ),
//            ),
//            StreamBuilder<int>(
//              stream: device.mtu,
//              initialData: 0,
//              builder: (c, snapshot) => ListTile(
//                title: Text('MTU Size'),
//                subtitle: Text('${snapshot.data} bytes'),
//                trailing: IconButton(
//                  icon: Icon(Icons.edit),
//                  onPressed: () => device.requestMtu(223),
//                ),
//              ),
//            ),
//            StreamBuilder<List<BluetoothService>>(
//              stream: device.services,
//              initialData: [],
//              builder: (c, snapshot) {
//                return Column(
//                  children: _buildServiceTiles(snapshot.data),
//                );
//              },
//            ),
//          ],
//        ),
//      ),
//    );
//  }
//}