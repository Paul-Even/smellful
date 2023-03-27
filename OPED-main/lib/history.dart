import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'main.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {}

class Historic extends StatelessWidget {
  SharedPreferences pre;
  Historic({super.key, required this.pre});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.black,
          title: Row(children: <Widget>[
            const Text(
              'Manual Diffusions History',
              textAlign: TextAlign.center,
            ),
            IconButton(
                //AppBar button to delete the diffusions' history
                padding: const EdgeInsets.fromLTRB(15, 0, 10, 0),
                icon: const Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
                onPressed: () async {
                  pre.setStringList("historic", []);
                  (context as Element).markNeedsBuild();
                }),
          ])),
      body: history(title: 'Your history', pre: pre),
    );
  }
}

class history extends StatefulWidget {
  history({super.key, required this.title, required this.pre});
  SharedPreferences pre;
  final String title;

  @override
  State<history> createState() => _historyState();
}

class _historyState extends State<history> {
  @override
  void initState() {
    super.initState();
  }

  ListView _buildListViewOfEvents(List<String> eventsList) {
    //Building the list's view
    List<Container> containers = <Container>[];
    for (int i = eventsList.length - 1; i >= 0; i--) {
      //Makes a loop to write every diffusion in the list
      containers.add(
        Container(
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text(
                      eventsList[i],
                      textAlign: TextAlign.center,
                    ),
                    const Divider(
                      height: 30,
                      thickness: 5,
                      indent: 0,
                      endIndent: 0,
                      color: Colors.black,
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        Column(),
        ...containers,
      ],
    );
  }

  Widget _buildView(eventsList) {
    return _buildListViewOfEvents(eventsList);
  }

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: _buildView(_getHistoric(widget.pre)));
}

List<String> _getHistoric(SharedPreferences pre) {
  //Retireving the list of saved diffusions
  return pre.getStringList("historic") ?? [];
}
