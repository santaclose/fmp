import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  List<Map> settingList = [{"name": "Library URL", "key": "library_url", "value": ""}];

  _SettingsPageState() {
    _initAsync();
  }

  void _initAsync() async {
    final prefs = await SharedPreferences.getInstance();
    final library_url = prefs.getString('library_url') ?? "";
    settingList[0]["value"] = library_url;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
        elevation: 0,
      ),
      body: Container(
          color: Color.fromARGB(255, 233, 233, 233),
          child: ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
            itemCount: settingList.length,
            itemBuilder: (context, index){
              return Card(
                elevation: 0,
                child: ListTile(
                  onTap: () {},
                  title:
                    // Text(settingList[index]["name"]),
                  TextFormField(
                    decoration: InputDecoration(
                      border: UnderlineInputBorder(),
                      labelText: settingList[index]["name"]
                    ),
                    initialValue: settingList[index]["value"],
                    onChanged: (newText) async {
                      final prefs = await SharedPreferences.getInstance();
                      prefs.setString('library_url', newText);
                    },
                  ),
                )
              );
            },
          )
      )
    );
  }
}
