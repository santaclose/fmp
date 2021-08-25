
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:fmp/settings.dart';

class FmpMenuButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
        onSelected: (val) {
          switch (val) {
            case 0:
              // Navigator.popUntil(context, Route)
              break;
            case 2:
              AudioService.stop();
              break;
            case 3:
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => SettingsPage(),
              ));
              break;
          }
        },
        itemBuilder: (context) => [
          // PopupMenuItem(
          //   child: Text("Library"),
          //   value: 0,
          // ),
          // PopupMenuItem(
          //   child: Text("Playlists"),
          //   value: 1,
          // ),
          PopupMenuItem(
            child: Text("Stop service"),
            value: 2,
          ),
          PopupMenuItem(
            child: Text("Settings"),
            value: 3,
          ),
        ]
    );
  }
}

class FmpSearchDelegate extends SearchDelegate {
  List<Map> list;
  List<String> listToFilter;
  Widget Function(List<Map> list, int length, int Function(int) mapping, {bool shouldPop}) bodyGenerator;

  Map<int, int> resultMapping = {};

  FmpSearchDelegate(
      List<Map> list,
      List<String> listToFilter,
      Widget Function(List<Map> list, int length, int Function(int) mapping, {bool shouldPop}) bodyGenerator) {
    this.list = list;
    this.listToFilter = listToFilter;
    this.bodyGenerator = bodyGenerator;
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  Widget singleBuildResults() {
    resultMapping.clear();

    int i = 0;
    int j = 0;
    for (String item in listToFilter) {
      if (item.toLowerCase().contains(query.toLowerCase())) {
        resultMapping[j] = i;
        j++;
      }
      i++;
    }
    return bodyGenerator(list, j, (index) => resultMapping[index], shouldPop: true);
  }

  @override
  Widget buildResults(BuildContext context) {
    return singleBuildResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return singleBuildResults();
  }
}