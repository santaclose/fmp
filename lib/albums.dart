import 'package:flutter/material.dart';
import 'package:fmp/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:fmp/songs.dart';

class AlbumsPage extends StatefulWidget {
  final String url;
  final String artist;
  AlbumsPage({this.url, this.artist});

  @override
  _AlbumsPageState createState() => _AlbumsPageState.fromUrl(url);
}

class _AlbumsPageState extends State<AlbumsPage> {
  List<Map> _albumList = [];
  final albumErrorSnackBar = SnackBar(content: Text('Cannot get album list'));

  _AlbumsPageState.fromUrl(String url) {
    _initAsync(url);
  }

  void _initAsync(String url) async {
    _albumList.clear();
    var uri = Uri.parse(url);
    var response = await http.get(uri);

    setState(() {
      if (response.statusCode != 200)
        ScaffoldMessenger.of(context).showSnackBar(albumErrorSnackBar);

      for (var line in response.body.split('\n')) {
        if (line.length == 0)
          continue;
        var parts = line.split('\\');
        _albumList.add({"name": parts[0], "songsUrl": parts[1], "cover": parts[2]});
      }
    });
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
            child: InkWell(
              borderRadius: BorderRadius.circular(4.0),
              onTap: () {
                if (shouldPop)
                  Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => SongsPage(url: list[mapping(index)]["songsUrl"], album: list[mapping(index)]["name"], cover: list[mapping(index)]["cover"]),
                ));
              },
              child: Ink(
                height: 150,
                width: double.infinity,
                color: Colors.transparent,
                child:
                Row(
                  children: [
                    AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                            padding: EdgeInsets.all(4),
                            child: Image.network(list[mapping(index)]["cover"],
                                fit: BoxFit.cover)
                        )
                    ),
                    Spacer(),
                    Container(
                      width: 200,
                      child: Text(list[mapping(index)]["name"],
                        overflow: TextOverflow.visible,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Spacer(),
                  ],
                ),
              ),
            ),
          );
        },
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 233, 233, 233),
      appBar: AppBar(
        title: Text("Albums from " + this.widget.artist),
        elevation: 0,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate:
              FmpSearchDelegate(
                  _albumList,
                  List.generate(_albumList.length, (index) => _albumList[index]["name"]),
                  bodyGenerator
              )
              );
            },
            tooltip: "Find",
          ),
          FmpMenuButton(),
        ],
      ),
      body: bodyGenerator(_albumList, _albumList.length, (index) => index)
    );
  }
}
