import 'dart:async';
import 'dart:developer';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:fmp/widgets.dart';
import 'package:just_audio/just_audio.dart';

List<String> urlList = [];
List<String> nameList = [];

_backgroundTaskEntrypoint() {
  AudioServiceBackground.run(() => AudioPlayerTask());
}

class AudioPlayerTask extends BackgroundAudioTask {
  final _audioPlayer = AudioPlayer();

  MediaItem generateMediaItem(index) {
    return MediaItem(
      id: urlList[index],
      title: nameList[index],
    );
  }

  Future<void> onStartPlaying(dynamic arguments) async {
    AudioServiceBackground.setState(controls: [
      MediaControl.pause,
      MediaControl.stop,
      MediaControl.skipToNext,
      MediaControl.skipToPrevious
    ], systemActions: [
      MediaAction.seekTo
    ], playing: true, processingState: AudioProcessingState.connecting);

    print(arguments);

    urlList = List<String>.from(arguments['urlList']);
    nameList = List<String>.from(arguments['nameList']);

    await _audioPlayer.setAudioSource(
        ConcatenatingAudioSource(
          useLazyPreparation: true, // default
          shuffleOrder: DefaultShuffleOrder(),
          children: List<AudioSource>.generate(urlList.length, (index) => AudioSource.uri(Uri.parse(urlList[index]))),
        ),
        initialIndex: arguments['index'],
        initialPosition: Duration.zero
    );
    AudioServiceBackground.setMediaItem(generateMediaItem(arguments['index']));
    _audioPlayer.play();

    // Broadcast that we're playing, and what controls are available.
    AudioServiceBackground.setState(controls: [
      MediaControl.pause,
      MediaControl.stop,
      MediaControl.skipToNext,
      MediaControl.skipToPrevious
    ], systemActions: [
      MediaAction.seekTo
    ], playing: true, processingState: AudioProcessingState.ready);
  }

  @override
  Future<void> onStart(Map<String, dynamic> params) async {
    await onStartPlaying(params);
    _audioPlayer.currentIndexStream.listen((event) {
      AudioServiceBackground.setMediaItem(generateMediaItem(event));
    });
    // _audioPlayer.durationStream.listen((event) {
    //   if (event != null) {
    //     _currentDurationMilliseconds = event.inMilliseconds;
    //     print("current duration set to: ------------------------- " +
    //         _currentDurationMilliseconds.toString());
    //   }
    // });
  }

  @override
  Future<void> onStop() async {
    AudioServiceBackground.setState(
        controls: [],
        playing: false,
        processingState: AudioProcessingState.ready);
    await _audioPlayer.stop();
    await super.onStop();
  }

  @override
  Future<void> onPlay() async {
    AudioServiceBackground.setState(controls: [
      MediaControl.pause,
      MediaControl.stop,
      MediaControl.skipToNext,
      MediaControl.skipToPrevious
    ], systemActions: [
      MediaAction.seekTo
    ], playing: true, processingState: AudioProcessingState.ready);
    await _audioPlayer.play();
    return super.onPlay();
  }

  @override
  Future<void> onPause() async {
    AudioServiceBackground.setState(controls: [
      MediaControl.play,
      MediaControl.stop,
      MediaControl.skipToNext,
      MediaControl.skipToPrevious
    ], systemActions: [
      MediaAction.seekTo
    ], playing: false, processingState: AudioProcessingState.ready);
    await _audioPlayer.pause();
    return super.onPause();
  }

  @override
  Future<void> onSkipToNext() async {

    if (_audioPlayer.hasNext) {
      AudioServiceBackground.setMediaItem(generateMediaItem(_audioPlayer.currentIndex + 1));
      await _audioPlayer.seekToNext();
      AudioServiceBackground.setState(position: Duration.zero);
    }
  }

  @override
  Future<void> onSkipToPrevious() async {

    if (_audioPlayer.hasPrevious) {
      AudioServiceBackground.setMediaItem(generateMediaItem(_audioPlayer.currentIndex - 1));
      await _audioPlayer.seekToPrevious();
      AudioServiceBackground.setState(position: Duration.zero);
    }
    return super.onSkipToPrevious();
  }

  @override
  Future<void> onRewind() async {
    await _audioPlayer.seek(_audioPlayer.position - Duration(seconds: 10));
    return super.onRewind();
  }
  @override
  Future<void> onFastForward() async {
    await _audioPlayer.seek(_audioPlayer.position + Duration(seconds: 10));
    return super.onFastForward();
  }


  @override
  Future onCustomAction(String name, arguments) async {
    switch(name) {
      case "reset":
        await onStartPlaying(arguments);
        break;
      case "volume":
        _audioPlayer.setVolume(arguments);
        break;
      // case "setPosition":
      //   _audioPlayer.seek(Duration(milliseconds: newMilliseconds));
      //   break;
    }

    return super.onCustomAction(name, arguments);
  }
}

class PlaybackPage extends StatefulWidget {
  List<Map> _songList = [];
  int _currentlyPlaying = 0;
  PlaybackPage(List<Map> songList, int currentlyPlaying) {
    _songList = songList;
    _currentlyPlaying = currentlyPlaying;


    var args = {
      "index": this._currentlyPlaying,
      "urlList": List<String>.generate(this._songList.length, (index) => this._songList[index]["audioUrl"]),
      "nameList": List<String>.generate(this._songList.length, (index) => this._songList[index]["name"]),
    };
    if (!AudioService.running) {
      AudioService.start(
        backgroundTaskEntrypoint: _backgroundTaskEntrypoint,
        params: args,
      );
    }
    else {
        AudioService.customAction("reset", args);
    }
  }

  @override
  _PlaybackPageState createState() => _PlaybackPageState();
}

class _PlaybackPageState extends State<PlaybackPage> {

  static const IconData pause_rounded = IconData(0xf0056, fontFamily: 'MaterialIcons');
  static const IconData play_arrow_rounded = IconData(0xf00a0, fontFamily: 'MaterialIcons');
  static const IconData volume_up_rounded = IconData(0xf029a, fontFamily: 'MaterialIcons');
  static const IconData skip_next_rounded = IconData(0xf0192, fontFamily: 'MaterialIcons');
  static const IconData skip_previous_rounded = IconData(0xf0193, fontFamily: 'MaterialIcons');
  static const IconData fast_rewind_rounded = IconData(0xf735, fontFamily: 'MaterialIcons');
  static const IconData fast_forward_rounded = IconData(0xf734, fontFamily: 'MaterialIcons');

  var sliderValue = 1.0;
  var startedPlaying = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              elevation: 0,
              title: StreamBuilder<MediaItem>(
                  stream: AudioService.currentMediaItemStream,
                  builder: (_, snapshot) {
                    return Text("Playing " + (snapshot.data?.title ?? "nothing"));
                  }),
              actions: [
                FmpMenuButton()
              ],
            ),
            body: Center(
              child: Column(
                children: [
                  Spacer(),
                  Slider(
                    value: sliderValue,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (val) {
                      setState(() {
                        sliderValue = val;
                        AudioService.customAction("volume", val);
                      });
                    },
                  ),
                  Spacer(),
                  Row(
                  children: [
                    Spacer(),
                    IconButton(
                      iconSize: 48.0,
                      icon: Icon(fast_rewind_rounded),
                      onPressed: () {
                        AudioService.rewind();
                      },
                    ),
                    Spacer(),
                    IconButton(
                        iconSize: 48.0,
                        icon: Icon(skip_previous_rounded),
                        onPressed: () {
                          AudioService.skipToPrevious();
                        }
                    ),
                    StreamBuilder<PlaybackState>(
                        stream: AudioService.playbackStateStream,
                        builder: (context, snapshot) {
                          final playing = snapshot.data?.playing ?? false;
                          if (playing)
                            return IconButton(
                                iconSize: 48.0,
                                onPressed: () {
                                    AudioService.pause();
                                  },
                                icon: Icon(pause_rounded)
                              );
                          else
                            return IconButton(
                                iconSize: 48.0,
                                icon: Icon(play_arrow_rounded),
                                onPressed: () {
                                  if (AudioService.running) {
                                    AudioService.play();
                                  } else {
                                    AudioService.start(
                                      backgroundTaskEntrypoint:
                                          _backgroundTaskEntrypoint,
                                      params: {
                                        "index": this.widget._currentlyPlaying,
                                        "urlList": List<String>.generate(this.widget._songList.length, (index) => this.widget._songList[index]["audioUrl"]),
                                        "nameList": List<String>.generate(this.widget._songList.length, (index) => this.widget._songList[index]["name"]),
                                      }
                                    );
                                  }
                                });
                        }),
                    IconButton(
                        iconSize: 48.0,
                        icon: Icon(skip_next_rounded),
                        onPressed: () {
                          AudioService.skipToNext();
                        },
                    ),
                    Spacer(),
                    IconButton(
                      iconSize: 48.0,
                      icon: Icon(fast_forward_rounded),
                      onPressed: () {
                        AudioService.fastForward();
                      },
                    ),
                    Spacer(),
                    // StreamBuilder<Duration>(
                    //   stream: AudioService.positionStream,
                    //   builder: (_, snapshot) {
                    //     final mediaState = snapshot.data;
                    //     return Slider(
                    //       value: mediaState?.inSeconds?.toDouble() ?? 0,
                    //       min: 0.0,
                    //       max: 1.0,
                    //       onChanged: (val) {
                    //         AudioService.seekTo(Duration(seconds: val.toInt()));
                    //       },
                    //     );
                    //   },
                    // )
                  ],
                ),
                Spacer(),
              ]
            ),
          )
        )
    );
  }
}
