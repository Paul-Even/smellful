import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'main.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter BLE Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key, required this.title});
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  final List<BluetoothDevice> devicesList = <BluetoothDevice>[];

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<BluetoothDevice> _connectedDevice = <BluetoothDevice>[];
  final _writeController = TextEditingController();
  _addDeviceTolist(final BluetoothDevice device) {
    //Adding devices to the list of available devices
    if (!widget.devicesList.contains(device) && device.name == "smellful") {
      //Checking if it is not already in the list
      //and filters the name (otherwise there are too much devices)
      setState(() {
        widget.devicesList.add(device);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    widget.flutterBlue.connectedDevices
        .asStream()
        .listen((List<BluetoothDevice> devices) {
      //Looks at every Bluetooth devices available
      for (BluetoothDevice device in devices) {
        _addDeviceTolist(device); //Adding the convenient devices to the list
      }
    });
    widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
      //Doing it in another way
      for (ScanResult result in results) {
        _addDeviceTolist(result.device);
      }
    });
    widget.flutterBlue.stopScan();
    widget.flutterBlue.startScan();
  }

  ListView _buildListViewOfDevices() {
    List<BluetoothDevice> _connectedDevices = <BluetoothDevice>[];
    List<Container> containers = <Container>[];
    var title = "";
    for (BluetoothDevice device in widget.devicesList) {
      //Builds a list of every selected devices
      containers.add(
        Container(
          height: 50,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    SizedBox(
                      height: 15,
                    ),
                    Text(
                      device.name == ''
                          ? '(unknown device)'
                          : device.name, //Checking if the device name is null
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold), //Writing the device's name
                    ),
                  ],
                ),
              ),
              TextButton(
                  //Button to connect to the device
                  style: TextButton.styleFrom(backgroundColor: Colors.black),
                  child: Text(
                    'Connect',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    if (_connectedDevice.length == 0 ||
                        _connectedDevice.length == 1 &&
                            _connectedDevice[0] != device) {
                      widget.flutterBlue.stopScan();
                      await device.connect(); //Connect to the device
                      showDialog(
                          context: context,
                          builder: ((context) => const AlertDialog(
                              content: Text('Successfully connected.'))));

                      _connectedDevice.add(device);
                      List<BluetoothService> _services =
                          await device.discoverServices();

                      _buildView(_connectedDevice, _services);
                      if (device != null) {}
                      widget.flutterBlue.stopScan();
                      Navigator.pop(context);
                      Navigator.pop(context, device);
                    } else {
                      //If already connected (which it shouldn't), disconnect from the device
                      device.disconnect();
                      _connectedDevice.clear();
                      showDialog(
                          context: context,
                          builder: ((context) =>
                              const AlertDialog(content: Text('Déconnecté'))));
                    }
                  }),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }

  ListView _buildView(_connectedDevice, _services) {
    return _buildListViewOfDevices();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text("Select your device"),
          backgroundColor: Colors.black,
        ),
        body: _buildView(null, null),
      );
}
