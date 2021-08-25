import 'package:flutter/material.dart';
import 'package:fmp/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:fmp/albums.dart';
import 'package:fmp/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ArtistsPage extends StatefulWidget {
  @override
  _ArtistsPageState createState() => _ArtistsPageState();
  // _ArtistsPageState createState() => _ArtistsPageState.fromUrl(
  //       'https://raw.githubusercontent.com/shiabehugo/48otw/master/data/artists.dat');
}

class _ArtistsPageState extends State<ArtistsPage> {

  List<Map> _artistList = [];
  final artistErrorSnackBar = SnackBar(content: Text('Cannot get artist list'));

  _ArtistsPageState() {
    _initAsync();
  }

  void _initAsync() async {
    _artistList.clear();

    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('library_url');

    if (url == null || url.length == 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Library url not set')));
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => SettingsPage(),
      ));
      return;
    }

    var uri = Uri.parse(url);
    var response = await http.get(uri);


    if (response.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cannot get artist list')));
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => SettingsPage(),
      ));
      return;
    }

    for (var line in response.body.split('\n')) {
      if (line.length == 0)
        continue;
      var parts = line.split('\\');
      _artistList.add({"name": parts[0], "albumsUrl": parts[1]});
    }
    setState(() {});
  }

  Widget bodyGenerator(List<Map> list, int length, int Function(int) mapping, {bool shouldPop = false}) {
    return Container(
      color: Color.fromARGB(255, 233, 233, 233),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        itemCount: length,
        itemBuilder: (context, index){
          return Card(
            elevation: 0,
            child: ListTile(
              onTap: () {
                if (shouldPop)
                  Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => AlbumsPage(url: list[mapping(index)]["albumsUrl"], artist: list[mapping(index)]["name"]),
                ));
              },
              title: Text(list[mapping(index)]["name"]),
            ),
          );
        },
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Library"),
        elevation: 0,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate:
              FmpSearchDelegate(
                    _artistList,
                    List.generate(_artistList.length, (index) => _artistList[index]["name"]),
                    bodyGenerator
                )
              );
            },
            tooltip: "Find",
          ),
          FmpMenuButton(),
        ],
      ),
      body: bodyGenerator(_artistList, _artistList.length, (index) => index),
    );
  }
}
