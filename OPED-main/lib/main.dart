import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_blue/gen/flutterblue.pbserver.dart';
import 'package:flutter_countdown_timer/index.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_countdown_timer/countdown.dart';
import 'package:flutter_blue/flutter_blue.dart' as fb;
import 'DevicesList.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'history.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:nearby_connections/nearby_connections.dart';

import 'dart:convert' show utf8;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MenuPrincipal(),
    );
  }
}

class MenuPrincipal extends StatefulWidget {
  MenuPrincipal({super.key});

  @override
  State<MenuPrincipal> createState() => _MenuPrincipalState();
}

class _MenuPrincipalState extends State<MenuPrincipal> {
  List<fb.BluetoothDevice> _connectedDevice =
      <fb.BluetoothDevice>[]; //Variable for the connected Bluetooth device
  List<fb.BluetoothService> services =
      <fb.BluetoothService>[]; //Variable for the services of the device
  List<String> strength = <String>[];
  bool connected = false;
  String coTxt = "ouhou";
  @override
  Widget build(BuildContext context) {
    coTxt = _getCoText(connected,
        _connectedDevice); //Makes the bottom text of the home menu, giving the information on the connected device
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            appBar: AppBar(
              title: Text('Home Menu'),
              centerTitle: true,
              backgroundColor: Colors.black,
            ),
            body: Container(
                child: Column(
              //Creating a column with the different elements on the screen
              children: <Widget>[
                Align(alignment: Alignment.center),
                Image.asset(
                    'assets/images/smellful.png', //The logo of the application
                    height: 225,
                    width: 225),
                Text("Smellful",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 65,
                    )),
                Text('An Olfactory Experience',
                    style: TextStyle(
                      fontSize: 10,
                    )),
              ],
            )),
            floatingActionButton: Stack(
              children: [
                Positioned(
                  left: 107,
                  top: 475,
                  child: FloatingActionButton.extended(
                      label: Text('Calendar Programming'),
                      backgroundColor: Colors.black,
                      heroTag: 'bouton1',
                      onPressed: () async {
                        if (connected == true) {
                          //Checks if the phone is connected to a device
                          List<Appointment> ds = <
                              Appointment>[]; //Starts to read the saved data and implement it
                          String data = await _readMyFile();
                          DateTime start = DateTime.now();
                          DateTime end = DateTime.now();
                          strength = <String>[];
                          String subject = "";
                          String value = "";
                          bool tdone = false;
                          Color couleur = Colors.black;
                          int y = 1;
                          for (int i = 0; i < data.length; i++) {
                            //Decoding loop of the saved string
                            if (data[i] != "." && data[i] != ";") {
                              if (y == 1 || y == 2) {
                                if (data[i] == " " && tdone == false) {
                                  value += "T";
                                  tdone = true;
                                } else if (data[i] == " " && tdone == true) {
                                } else if (data[i] == "–") {
                                } else {
                                  value += data[i];
                                }
                              } else {
                                value += data[i];
                              }
                            }
                            if (data[i] == ".") {
                              switch (y) {
                                case 1:
                                  {
                                    start = DateTime.parse(value);
                                  }
                                  break;
                                case 2:
                                  {
                                    end = DateTime.parse(value);
                                  }
                                  break;
                                case 3:
                                  {
                                    strength.add(value);
                                  }
                                  break;
                              }
                              value = "";
                              y += 1;
                              tdone = false;
                            }
                            if (data[i] == ";") {
                              subject = value;
                              if (value.contains("Energy")) {
                                couleur = Colors.green;
                              } else if (subject.contains("Wellbeing")) {
                                couleur = Colors.purple;
                              } else if (subject.contains("Relaxation")) {
                                couleur = Colors.orange;
                              }

                              value = "";
                              y = 1;

                              Appointment z = Appointment(
                                  //Add the decoded data into an appointment and into the data source of the calendar
                                  startTime: start,
                                  endTime: end,
                                  subject: subject,
                                  color: couleur);
                              if (start.day == DateTime.now().day &&
                                  end.day == DateTime.now().day) {
                                ds.add(z);
                              }
                            }
                          } //Finished to implement the saved data

                          Navigator.push(
                              //Opens the calendar screen
                              context,
                              MaterialPageRoute(
                                  builder: (context) => MyCalendar(
                                      device: _connectedDevice,
                                      services: services,
                                      events: DataSource(ds))));
                        } else {
                          //Show a text if there is no device connected
                          showDialog(
                              context: context,
                              builder: ((context) => const AlertDialog(
                                  content: Text(
                                      'You should connect to a device first.'))));
                        }
                      }),
                ),
                Positioned(
                  left: 112,
                  top: 575,
                  child: FloatingActionButton.extended(
                    label: Text('Manual Programming'),
                    backgroundColor: Colors.black,
                    heroTag: 'bouton2',
                    onPressed: () {
                      if (connected == true) {
                        //Check if the phone is connected to a device
                        Navigator.push(
                            //Opens the manual screen
                            context,
                            MaterialPageRoute(
                                builder: (context) => ModeManuel(
                                    device: _connectedDevice,
                                    services: services)));
                      } else {
                        //Show a text if there is no device connected
                        showDialog(
                            context: context,
                            builder: ((context) => const AlertDialog(
                                content: Text(
                                    'You should connect to a device first.'))));
                      }
                    },
                  ),
                ),
                Positioned(
                  left: 107,
                  top: 675,
                  child: FloatingActionButton.extended(
                    //Button to connect to a device, or disconnect if already connected
                    label: Text('Connect to your device'),
                    backgroundColor: Colors.black,
                    heroTag: 'bouton3',
                    onPressed: () async {
                      bool permGranted = true;

                      if (await Nearby().checkBluetoothPermission()) {
                        //Checking on the necessary Bluetooth permissions
                      } else {
                        permGranted = false;
                        Nearby().askBluetoothPermission();
                        if (await Nearby().checkBluetoothPermission()) {
                          permGranted = true;
                        }
                      }

                      if (connected == false && permGranted == true) {
                        //Checking if there is no device connected and the permissions are good
                        final results = await Navigator.push(
                            context, //Opens the device connection page
                            MaterialPageRoute(
                                builder: (context) => MyHomePage(title: "")));
                        if (results != null) {
                          //If the page returns a device for connection
                          connected = true;
                          services = await results
                              .discoverServices(); //Saves its services

                          setState(() {
                            _connectedDevice
                                .add(results); //Save it as the connected device
                          });
                        }
                      } else {
                        if (_connectedDevice.length != 0) {
                          //If a device is connected
                          _connectedDevice[0].disconnect(); //Disconnects it
                          _connectedDevice.clear();

                          connected = false;
                          coTxt = _getCoText(connected, _connectedDevice);
                          setState(() {}); //Actualize the page
                        }
                      }
                    },
                  ),
                ),
                Positioned(
                  left: 180,
                  top: 775,
                  child: FloatingActionButton.extended(
                    label: Text('STOP'), //Stops all diffusions
                    backgroundColor: Colors.black,
                    heroTag: 'bouton4',
                    onPressed: () {
                      if (connected == true) {
                        for (fb.BluetoothService s in services) {
                          for (fb.BluetoothCharacteristic c
                              in s.characteristics) {
                            if (c.properties.write) {
                              c.write(utf8.encode("xxx"));
                            }
                          }
                        }

                        showDialog(
                            context: context,
                            builder: ((context) => const AlertDialog(
                                content: Text(
                                    'All diffusions have been stopped.'))));
                      } else {
                        showDialog(
                            context: context,
                            builder: ((context) => const AlertDialog(
                                content: Text(
                                    'You should connect to a device first.'))));
                      }
                    },
                  ),
                ),
                _makeCoText(coTxt, connected)
              ],
            )));
  }
}

_getCoText(bool connected, List<fb.BluetoothDevice> device) {
  if (connected == true) {
    return "Connected to " + device[0].name;
  } else {
    return "No device connected.";
  }
}

_makeCoText(String coTxt, bool connected) {
  if (connected == true) {
    return Positioned(
      bottom: 0,
      left: 145,
      child: Text(
        coTxt,
        style: TextStyle(color: Colors.grey),
      ),
    );
  } else {
    return Positioned(
      bottom: 0,
      left: 150,
      child: Text(
        coTxt,
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}

class ModeManuel extends StatefulWidget {
  @override
  List<fb.BluetoothDevice> device = <fb.BluetoothDevice>[];
  List<fb.BluetoothService> services = <fb.BluetoothService>[];
  ModeManuel({super.key, required this.device, required this.services});

  @override
  State<ModeManuel> createState() => _ModeManuelState();
}

class _ModeManuelState extends State<ModeManuel> {
  @override
  int rating = 0;
  List<String> values = [
    //Initialize the values for the intensity of the diffusion
    'Weak',
    'Medium',
    'Strong',
  ];
  List<String> liste = [
    'Energy',
    'Wellbeing',
    'Relaxation'
  ]; //Initialize the list of different smells
  late var dropdownValue = liste.first;
  var _startTime =
      TimeOfDay(hour: DateTime.now().hour, minute: DateTime.now().minute);
  var _startDate = DateTime.now();
  int endTime = DateTime.now().millisecondsSinceEpoch + 1000 * 30;
  Duration selectedValue = Duration(hours: 0, minutes: 0, seconds: 0);
  late CountdownTimerController controller;

  final fb.FlutterBlue flutterBlue = fb.FlutterBlue.instance;
  List<fb.BluetoothDevice> device = <fb.BluetoothDevice>[];
  List<fb.BluetoothService> services = <fb.BluetoothService>[];
  TimeOfDay fin =
      TimeOfDay(hour: DateTime.now().hour + 5, minute: DateTime.now().minute);
  int compteur = 0;
  bool envoi = false;
  Duration diff = Duration();
  String hist = "";
  String time = "";

  @override
  void initState() {
    super.initState();
    device = widget.device;
    services = widget.services;
    controller = CountdownTimerController(endTime: endTime);
  }

  Widget build(BuildContext context) {
    return Container(
        width: MediaQuery.of(context).size.width,
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
                appBar: AppBar(
                    backgroundColor: Colors.black,
                    title: Row(children: <Widget>[
                      IconButton(
                        //Button to return to the home page
                        padding: const EdgeInsets.fromLTRB(0, 0, 50, 0),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      const Text(
                        'Manual Programming',
                        textAlign: TextAlign.center,
                      ),
                      IconButton(
                          //Button to consult the history of the manual diffusions.
                          padding: const EdgeInsets.fromLTRB(45, 0, 10, 0),
                          icon: const Icon(
                            Icons.history,
                            color: Colors.white,
                          ),
                          onPressed: () async {
                            SharedPreferences pre =
                                await SharedPreferences.getInstance();
                            Navigator.push(
                                //Opening the history page.
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Historic(pre: pre)));
                          }),
                    ])),
                body: Center(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    DropdownButton<String>(
                      //Dropdown list for choosing between the different smells
                      items:
                          liste.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value,
                              style: TextStyle(
                                  fontSize: 35, color: Colors.black87)),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          dropdownValue = value!;
                        });
                      },
                      value: dropdownValue,
                      elevation: 16,
                      style:
                          const TextStyle(fontSize: 40, color: Colors.black87),
                      underline: SizedBox(),
                    ),
                    SizedBox(height: 100), //Empty space between the widgets
                    GestureDetector(
                        //Button to choose the ending time of the smell release.
                        child: Text(
                          'Ending Time :\n' +
                              DateFormat('HH:mm').format(_startDate),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 35),
                        ),
                        onTap: () async {
                          var time = await showTimePicker(
                              context: context, initialTime: _startTime);
                          if (time != null) {
                            setState(() {
                              _startTime = time;

                              _startDate = DateTime(
                                _startDate.year,
                                _startDate.month,
                                _startDate.day,
                                _startTime.hour,
                                _startTime.minute,
                              );
                              final Duration diff =
                                  DateTime.now().difference(_startDate);
                            });
                          }
                          diff = _startDate.difference(DateTime.now());
                        }),
                    SizedBox(height: 100),
                    Text(
                      values[rating],
                      style: CupertinoTheme.of(context)
                          .textTheme
                          .textStyle
                          .copyWith(fontSize: 20),
                    ),
                    CupertinoSlider(
                      //Slider to choose the intensity of the smell.
                      value: rating.toDouble(),
                      min: 0,
                      max: 2,
                      divisions: 4,
                      activeColor: Colors.black87,
                      thumbColor: Colors.black87,
                      onChanged: (selectedValue) {
                        setState(() {
                          rating = selectedValue.toInt();
                        });
                      },
                    ),
                    SizedBox(height: 100),
                    FloatingActionButton.extended(
                      //Start button, sending data to the device to start the diffusion
                      onPressed: () async {
                        setState(() {
                          CountdownTimer(
                            controller: controller,
                            endTime: _startDate
                                .difference(DateTime.now())
                                .inMilliseconds,
                          );
                        });

                        compteur = diff.inMilliseconds * 100;
                        compteur += rating * 10;
                        compteur += liste.indexOf(dropdownValue);
                        for (fb.BluetoothService s in services) {
                          //Writing the data to the device
                          for (fb.BluetoothCharacteristic c
                              in s.characteristics) {
                            if (c.properties.write) {
                              c.write(utf8.encode("2" + compteur.toString()));
                            }
                          }
                        }
                        var diff2 = diff
                            .inSeconds; //Writing the data in the history list
                        if (diff.inHours > 0) {
                          time += diff.inHours.toString() + " hours ";
                          diff2 -= diff.inHours * 3600;
                        }
                        if (diff2 >= 60) {
                          time += (diff2 ~/ 60).toString() + " minutes ";
                          diff2 = diff2 % 60;
                        }
                        if (diff2 > 0) {
                          time += diff2.toString() + " seconds ";
                        }
                        SharedPreferences pre =
                            await SharedPreferences.getInstance();
                        List<String> historic = pre.getStringList("historic") ??
                            []; //Getting the saved list of past diffusion
                        hist +=
                            "${DateTime.now().day.toString()}/${DateTime.now().month.toString()}/${DateTime.now().year.toString()}" +
                                "\n";
                        hist += time + "\n";
                        hist += dropdownValue.toString() + "\n";
                        hist += values[rating];
                        historic.add(
                            hist); //Adding the latest diffusion to the list
                        pre.setStringList("historic",
                            historic); //Saving locally the list of diffusions
                        hist = "";
                        time = "";
                      },
                      label: Text('START'),
                      backgroundColor: Colors.black87,
                    ),
                  ],
                )))));
  }
}

var _selectedAppointment = null;
void calendarTapped(CalendarTapDetails calendarTapDetails) {
  //Getting the details of the appointment selected by tapping on the calendar
  if (calendarTapDetails.targetElement == CalendarElement.agenda ||
      calendarTapDetails.targetElement == CalendarElement.appointment) {
    final Appointment appointment = calendarTapDetails.appointments![0];
    _selectedAppointment = appointment;
  }
}

_writeMyFile(String text) async {
  //Saving locally a text.
  final Directory directory = await getApplicationDocumentsDirectory();
  final File file = File('${directory.path}/my_file.txt');
  await file.writeAsString(text);
}

_emptyMyfile() async {
  //Emptying a local file.
  final Directory directory = await getApplicationDocumentsDirectory();
  final File file = File('${directory.path}/my_file.txt');
  await file.delete();
  await file.writeAsString("");
}

Future<String> _readMyFile() async {
  //Reading a local string file.
  String txt = "";
  try {
    final Directory directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/my_file.txt');
    txt = await file.readAsString();
  } catch (e) {
    print("Couldn't read file");
  }
  return txt;
}

class MyCalendar extends StatefulWidget {
  //Start of the calendar page
  var events = DataSource(<Appointment>[]);
  List<fb.BluetoothDevice> device = <fb.BluetoothDevice>[];
  List<fb.BluetoothService> services = <fb.BluetoothService>[];
  MyCalendar(
      {super.key,
      required this.device, //Gets the required connected device information
      required this.services, //Gets the required connected device's services information
      required this.events //Gets the required data source for the calendar
      });
  @override
  State<MyCalendar> createState() => _MyCalendarState();
}

class _MyCalendarState extends State<MyCalendar> {
  final _controller = CalendarController();
  var events = DataSource(<Appointment>[]);
  List<fb.BluetoothDevice> device = <fb.BluetoothDevice>[];
  List<fb.BluetoothService> services = <fb.BluetoothService>[];
  void initState() {
    events = widget.events;
    device = widget.device;
    services = widget.services;
  }

  List<String> strength = <String>[];
  String envoiBT = "1";
  String writeFile = "";
  late Directory directory;
  late String filePath;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          appBar: AppBar(
              backgroundColor: Colors.black,
              title: Row(children: <Widget>[
                IconButton(
                  padding: const EdgeInsets.fromLTRB(0, 0, 90, 0),
                  icon: const Icon(
                    //AppBar button to come back to the home page
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(
                        context); //Closes the current page to go back to the previous one
                  },
                ),
                const Text(
                  //Title of this page
                  'Your Calendar',
                  textAlign: TextAlign.center,
                ),
                IconButton(
                    //Button to delete the saved events of the calendar
                    onPressed: () async {
                      setState(() {
                        _emptyMyfile();
                        events = DataSource(<Appointment>[]);
                      });
                    },
                    padding: const EdgeInsets.fromLTRB(30, 0, 15, 0),
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    )),
                IconButton(
                    //Button to save the current events of the calendar
                    padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
                    icon: const Icon(
                      Icons.save,
                      color: Colors.white,
                    ),
                    onPressed: () async {
                      writeFile = "";
                      if (strength.length > 0 &&
                          strength[0] != null &&
                          events.appointments!.length > 0 &&
                          events.appointments![0] != null) {
                        for (int i = 0; i < events.appointments!.length; i++) {
                          writeFile += DateFormat('yyyy-MM-dd – kk:mm')
                                  .format(events.appointments![i].startTime) +
                              ".";
                          writeFile += DateFormat('yyyy-MM-dd – kk:mm')
                                  .format(events.appointments![i].endTime) +
                              ".";
                          writeFile += strength[i] + ".";
                          writeFile += events.appointments![i].subject + ";";
                        }
                      }
                      await _writeMyFile(writeFile);
                    }),
              ])),
          floatingActionButton: Stack(
            children: [
              Positioned(
                right: 54,
                bottom: 20,
                child: FloatingActionButton.extended(
                    //Button to add an event on the calendar
                    backgroundColor: Colors.black,
                    heroTag: 'bouton1',
                    label: const Text('+'),
                    onPressed: () {
                      if (events.appointments!.length < 10) {
                        //Checks if the limit of daily appointment is reached
                        _secondPage(BuildContext context, Widget page) async {
                          final dataFromSecondPage = await Navigator.push(
                              //Opens the event adding page
                              context,
                              MaterialPageRoute(
                                builder: ((context) => page),
                              )) /*as Appointment*/;
                          if (dataFromSecondPage != null) {
                            //If an added event is received, adds it to the calendar
                            events.appointments!.add(dataFromSecondPage.event);
                            events.notifyListeners(CalendarDataSourceAction.add,
                                <Appointment>[dataFromSecondPage.event]);
                            strength = dataFromSecondPage.strength;
                          }
                        }

                        _secondPage(
                            context,
                            SecondRoute(
                              strength: strength,
                            ));
                      } else {
                        //If the limit of daily events is reached, show a warning text.
                        showDialog(
                            context: context,
                            builder: ((context) => const AlertDialog(
                                content: Text(
                                    'You already reached the limit of daily events.'))));
                      }
                    }),
              ),
              Positioned(
                left: 118,
                bottom: 20,
                child: FloatingActionButton.extended(
                  //Button to delete an event
                  backgroundColor: Colors.black,
                  heroTag: 'bouton2',
                  label: Text('-'),
                  onPressed: () {
                    if (_selectedAppointment != null) {
                      //Checks if an appointment is selected
                      events.appointments!.removeAt(
                          events.appointments!.indexOf(_selectedAppointment));
                      events.notifyListeners(CalendarDataSourceAction.remove,
                          <Appointment>[]..add(_selectedAppointment));
                    } else {}
                  },
                ),
              ),
              Positioned(
                left: 165,
                bottom: 20,
                child: FloatingActionButton.extended(
                  //Button to send the calendar data to the device
                  backgroundColor: Colors.black,
                  heroTag: 'bouton3',
                  label: Text("Synchronize"),
                  onPressed: () async {
                    writeFile = "";
                    if (envoiBT != "1") {
                      //Start the data to send with a "1", indicating the programming mode used
                      envoiBT = "1";
                    }
                    if (strength.length > 0 &&
                        strength[0] != null &&
                        events.appointments!.length > 0 &&
                        events.appointments![0] != null) {
                      for (int i = 0; i < events.appointments!.length; i++) {
                        //Adds the data of each event to a string
                        envoiBT += events.appointments![i].startTime
                            .difference(DateTime.now())
                            .inMilliseconds
                            .toString();
                        envoiBT += '.';

                        envoiBT += events.appointments![i].endTime
                            .difference(events.appointments![i].startTime)
                            .inMilliseconds
                            .toString();
                        envoiBT += '.';
                        envoiBT += strength[i] + ';';
                        writeFile += DateFormat('yyyy-MM-dd – kk:mm')
                                .format(events.appointments![i].startTime) +
                            ".";
                        writeFile += DateFormat('yyyy-MM-dd – kk:mm')
                                .format(events.appointments![i].endTime) +
                            ".";
                        writeFile += strength[i] + ".";
                        writeFile += events.appointments![i].subject + ";";
                      }
                    }
                    await _writeMyFile(
                        writeFile); //Save locally the data of all events
                    for (fb.BluetoothService s in services) {
                      for (fb.BluetoothCharacteristic c in s.characteristics) {
                        if (c.properties.write) {
                          c.write(utf8
                              .encode(envoiBT)); //Send the data of all events
                        }
                      }
                    }
                    Navigator.pop(context); //Close the current page
                  },
                ),
              )
            ],
          ),
          body: SfCalendar(
            //The body of the calendar page : the calendar
            selectionDecoration:
                BoxDecoration(border: Border.all(color: Colors.black)),
            view: CalendarView.day, //Put the calendar on a daily view
            minDate: DateTime(
                //Limits the view on the current day
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day),
            maxDate: DateTime(DateTime.now().year, DateTime.now().month,
                DateTime.now().day, 23, 59, 59),
            showDatePickerButton: false,
            controller: _controller,
            dataSource: events, //Puts the events on the calendar
            todayHighlightColor: Colors.black,
            onTap: calendarTapped,
          )),
    );
  }
}

class DataSource extends CalendarDataSource {
  DataSource(List<Appointment> source) {
    appointments = source;
  }
}

class SecondRoute extends StatefulWidget {
  List<String> strength = <String>[];
  SecondRoute({super.key, required this.strength});
  @override
  _SecondRouteState createState() => _SecondRouteState();
}

class PassageInfos {
  List<String> strength = <String>[];
  Appointment event =
      Appointment(startTime: DateTime.now(), endTime: DateTime.now());

  PassageInfos(List<String> strength) {
    this.strength = strength;
  }
}

class _SecondRouteState extends State<SecondRoute> {
  //Beginning of the event adding page
  final _ColorPicker = ColorPicker(
    pickerColor: Colors.black,
    onColorChanged: (Color color) {
      print(color);
    },
  );
  var _subject;
  var _isAllDay = false;
  DateTime _startDate = DateTime.now();
  var _endDate = DateTime.now();
  var _startTime = TimeOfDay(
    hour: DateTime.now().hour,
    minute: DateTime.now().minute,
  );
  var _endTime = TimeOfDay(
    hour: DateTime.now().hour,
    minute: DateTime.now().minute,
  );

  List<String> liste = <String>[
    'Energy',
    'Wellbeing',
    'Relaxation'
  ]; //Listing of the different smells

  List<Color> listeCouleurs = <Color>[
    //Listing of the different colors of the events
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.cyan
  ];
  late String dropdownValue = liste.first;
  var _selectedColorIndex = 0;
  int rating = 0;
  List<String> values = [
    //Listing of the different intensity levels
    'Weak',
    'Medium',
    'Strong',
  ];
  String smell = "";
  PassageInfos passage = new PassageInfos(<String>[]);
  @override
  void initState() {
    passage = PassageInfos(widget.strength);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            appBar: AppBar(
                backgroundColor: Colors.black,
                title: Row(
                  children: <Widget>[
                    IconButton(
                      padding: const EdgeInsets.fromLTRB(5, 0, 60, 0),
                      icon: const Icon(
                        //Button to go back to the previous page
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const Text(
                      'Adding a new event',
                      textAlign: TextAlign.center,
                    ),
                    IconButton(
                      padding: const EdgeInsets.fromLTRB(60, 0, 5, 0),
                      icon: const Icon(
                        //Button to add the event to the calendar
                        Icons.done,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        //When the button is pressed, save the data and close the page
                        if (_subject == null) {
                          _subject = "No Title";
                        }
                        String libele = dropdownValue;
                        Color couleur = Colors.blue;
                        if (libele == 'Energy') {
                          couleur = Colors.green;
                          smell = "0";
                        }
                        if (libele == 'Wellbeing') {
                          couleur = Colors.purple;
                          smell = "1";
                        }
                        if (libele == 'Relaxation') {
                          couleur = Colors.orange;
                          smell = "2";
                        }

                        DateTime start = DateTime(
                          _startDate.year,
                          _startDate.month,
                          _startDate.day,
                          _startTime.hour,
                          _startTime.minute,
                        );

                        DateTime end = DateTime(
                          _endDate.year,
                          _endDate.month,
                          _endDate.day,
                          _endTime.hour,
                          _endTime.minute,
                        );

                        passage.event = Appointment(
                            startTime: start,
                            endTime: end,
                            subject:
                                '$_subject \nSmell : $libele\nStrength : ' +
                                    values[rating].toString(),
                            color: couleur);

                        passage.strength.add(rating.toString() + "." + smell);

                        Navigator.pop(context, passage);
                      },
                    )
                  ],
                )),
            body: Container(
              child:
                  ListView(padding: const EdgeInsets.all(0), children: <Widget>[
                ListTile(
                  //First element is a text zone, for the user to write the title of his event
                  contentPadding: const EdgeInsets.fromLTRB(45, 0, 99, 0),
                  leading: const Text(''),
                  title: TextField(
                    controller: TextEditingController(text: _subject),
                    onChanged: (String value) {
                      _subject = value;
                    },
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 25,
                        color: Colors.black,
                        fontWeight: FontWeight.w400),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Add Title',
                    ),
                  ),
                ),
                const Divider(
                  height: 1.0,
                  thickness: 1,
                ),
                SizedBox(height: 50),
                Text(
                  "Starting time :",
                  style: TextStyle(
                      fontSize: 30, decoration: TextDecoration.underline),
                  textAlign: TextAlign.center,
                ),
                ListTile(
                    //Button to choose the starting time of the event
                    contentPadding: const EdgeInsets.fromLTRB(30, 2, 85, 2),
                    leading: const Text(''),
                    title: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Expanded(
                              flex: 7,
                              child: _isAllDay
                                  ? const Text('')
                                  : GestureDetector(
                                      child: Text(
                                          DateFormat('HH:mm')
                                              .format(_startDate),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 50)),
                                      onTap: () async {
                                        //When the user clicks on the time, opens a time picker
                                        var time = await showTimePicker(
                                            context: context,
                                            initialTime: TimeOfDay(
                                                hour: _startTime.hour,
                                                minute: _startTime.minute));
                                        if (time != null &&
                                            time != _startTime) {
                                          setState(() {
                                            _startTime = time;
                                            final Duration difference =
                                                _endDate.difference(_startDate);
                                            _startDate = DateTime(
                                                _startDate.year,
                                                _startDate.month,
                                                _startDate.day,
                                                _startTime.hour,
                                                _startTime.minute,
                                                0);
                                            _endDate =
                                                _startDate.add(difference);
                                          });
                                        }
                                      })),
                        ])),
                SizedBox(height: 25),
                Text(
                  "Ending time :",
                  style: TextStyle(
                      fontSize: 30, decoration: TextDecoration.underline),
                  textAlign: TextAlign.center,
                ),
                ListTile(
                    //Same as the starting time, this time for the ending time of the event
                    contentPadding: const EdgeInsets.fromLTRB(30, 2, 85, 2),
                    leading: const Text(''),
                    title: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Expanded(
                              flex: 7,
                              child: _isAllDay
                                  ? const Text('')
                                  : GestureDetector(
                                      child: Text(
                                          DateFormat('HH:mm').format(_endDate),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 50)),
                                      onTap: () async {
                                        var time = await showTimePicker(
                                            context: context,
                                            initialTime: TimeOfDay(
                                                hour: _endTime.hour,
                                                minute: _endTime.minute));
                                        if (time != null && time != _endTime) {
                                          setState(() {
                                            _endTime = time;
                                            final Duration difference =
                                                _endDate.difference(_startDate);
                                            _endDate = DateTime(
                                                _endDate.year,
                                                _endDate.month,
                                                _endDate.day,
                                                _endTime.hour,
                                                _endTime.minute,
                                                0);
                                            if (_endDate.isBefore(_startDate)) {
                                              _startDate =
                                                  _endDate.subtract(difference);
                                            }
                                          });
                                        }
                                      })),
                        ])),
                SizedBox(height: 35),
                Text(
                  "Smell : ",
                  style: TextStyle(
                      fontSize: 30, decoration: TextDecoration.underline),
                  textAlign: TextAlign.center,
                ),
                ListTile(
                  //Dropdown list to choose the smell wanted
                  contentPadding: const EdgeInsets.fromLTRB(100, 2, 5, 2),
                  leading: DropdownButton<String>(
                      items:
                          liste.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          dropdownValue = value!;
                        });
                      },
                      value: dropdownValue,
                      elevation: 16,
                      style: const TextStyle(fontSize: 28, color: Colors.black),
                      underline: SizedBox()),
                ),
                SizedBox(height: 50),
                Text(
                  "Strength :",
                  style: TextStyle(
                      fontSize: 30, decoration: TextDecoration.underline),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: 20,
                ),
                Text(
                  values[rating],
                  style: CupertinoTheme.of(context)
                      .textTheme
                      .textStyle
                      .copyWith(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                Column(
                  //Slider to choose the intensity of the diffusion
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    CupertinoSlider(
                      value: rating.toDouble(),
                      min: 0,
                      max: 2,
                      divisions: 4,
                      activeColor: Colors.black87,
                      thumbColor: Colors.black87,
                      onChanged: (selectedValue) {
                        setState(() {
                          rating = selectedValue.toInt();
                        });
                      },
                    ),
                  ],
                )
              ]),
            )));
  }
}
