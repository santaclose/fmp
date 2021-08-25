import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fmp/playback.dart';
import 'package:fmp/widgets.dart';

class SongsPage extends StatefulWidget {
  final String url;
  final String album;
  final String cover;
  SongsPage({this.url, this.album, this.cover});

  @override
  _SongsPageState createState() => _SongsPageState.fromUrl(url);
}

class _SongsPageState extends State<SongsPage> {
  static const IconData cloud = IconData(0xe16f, fontFamily: 'MaterialIcons');
  static const IconData file_download = IconData(0xe26a, fontFamily: 'MaterialIcons');

  List<Map> _songList = [];
  String artistName = "Unknown";
  String albumName = "Unknown";
  final songErrorSnackBar = SnackBar(content: Text('Cannot get song list'));

  _SongsPageState.fromUrl(String url) {
    _initAsync(url);
  }

  void _initAsync(String url) async {
    _songList.clear();
    var uri = Uri.parse(url);
    var response = await http.get(uri);

    setState(() {
      if (response.statusCode != 200)
        ScaffoldMessenger.of(context).showSnackBar(songErrorSnackBar);

      var lines = response.body.split('\n');
      var firstLineParts = lines[0].split('\\');
      artistName = firstLineParts[0];
      albumName = firstLineParts[1];
      for (var i = 1; i < lines.length; i++) {
        var line = lines[i];
        if (line.length == 0)
          continue;
        var parts = line.split('\\');
        _songList.add({"name": parts[0], "audioUrl": parts[1], "downloaded": false});
      }
    });
  }

  Widget bodyGenerator(List<Map> list, int length, int Function(int) mapping, {bool shouldPop = false}) {
    return Container(
      color: Color.fromARGB(255, 233, 233, 233),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        itemCount: length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 0,
            child: ListTile(
              leading: Column(
                children: [
                  Spacer(),
                  Text((mapping(index) + 1).toString(), textAlign: TextAlign.center),
                  Spacer(),
                ],
              ),
              // trailing: Icon(list[mapping(index)]["downloaded"] ? file_download : cloud,
              //   size: 14.0,
              //   color: Colors.black,
              // ),
              onTap: () {
                if (shouldPop)
                  Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => PlaybackPage(list, mapping(index)),
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
        title: Text("Songs from " + this.widget.album),
        elevation: 0,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                showSearch(context: context, delegate:
                FmpSearchDelegate(
                    _songList,
                    List.generate(_songList.length, (index) => _songList[index]["name"]),
                    bodyGenerator
                )
                );
              },
              tooltip: "Find",
          ),
          FmpMenuButton(),
        ],
      ),
      body: bodyGenerator(_songList, _songList.length, (index) => index)
    );
  }
}
