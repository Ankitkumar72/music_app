import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

void main() {
  runApp(const PixelPlay());
}

class PixelPlay extends StatelessWidget {
  const PixelPlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MusicPlayer(),
    );
  }
}

class MusicPlayer extends StatefulWidget {
  const MusicPlayer({super.key});

  @override
  State<MusicPlayer> createState() => _MusicPlayerState();
}

class _MusicPlayerState extends State<MusicPlayer> {
  final AudioPlayer player = AudioPlayer();
  final OnAudioQuery audioQuery = OnAudioQuery();

  // ValueNotifiers for high-FPS rebuild isolation
  final ValueNotifier<Duration> position = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> duration = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> buffered = ValueNotifier(Duration.zero);

  bool isDragging = false;
  double dragValue = 0;

  StreamSubscription? posSub;
  StreamSubscription? durSub;
  StreamSubscription? bufSub;

  @override
  void initState() {
    super.initState();
    _initPlayerStreams();
  }

  void _initPlayerStreams() {
    posSub = player.positionStream.listen((pos) {
      if (!isDragging) {
        position.value = pos;
      }
    });

    durSub = player.durationStream.listen((dur) {
      if (dur != null) {
        duration.value = dur;
      }
    });

    bufSub = player.bufferedPositionStream.listen((buf) {
      buffered.value = buf;
    });
  }

  @override
  void dispose() {
    posSub?.cancel();
    durSub?.cancel();
    bufSub?.cancel();
    player.dispose();
    super.dispose();
  }

  String formatTime(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      appBar: AppBar(backgroundColor: Colors.black, title: const Text('Pixy')),
      body: Column(
        children: [
          const SizedBox(height: 30),

          /// ===================== SEEK BAR =====================
          ValueListenableBuilder<Duration>(
            valueListenable: duration,
            builder: (context, dur, child) {
              final max = dur.inMilliseconds.toDouble();

              return ValueListenableBuilder<Duration>(
                valueListenable: position,
                builder: (context, pos, child) {
                  final currentValue = isDragging
                      ? dragValue
                      : pos.inMilliseconds.clamp(0, max.toInt()).toDouble();

                  return Column(
                    children: [
                      ValueListenableBuilder<Duration>(
                        valueListenable: buffered,
                        builder: (context, buf, child) {
                          final bufferedValue = buf.inMilliseconds
                              .clamp(0, max.toInt())
                              .toDouble();

                          return Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              /// Buffered slider (background)
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 0,
                                  ),
                                  overlayShape: SliderComponentShape.noOverlay,
                                  activeTrackColor: Colors.grey.shade700,
                                  inactiveTrackColor: Colors.grey.shade900,
                                ),
                                child: Slider(
                                  value: bufferedValue,
                                  min: 0,
                                  max: max == 0 ? 1 : max,
                                  onChanged: null,
                                ),
                              ),

                              /// Main draggable slider
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: Colors.greenAccent,
                                  inactiveTrackColor: Colors.transparent,
                                  overlayShape: SliderComponentShape.noOverlay,
                                ),
                                child: Slider(
                                  value: currentValue,
                                  min: 0,
                                  max: max == 0 ? 1 : max,

                                  onChangeStart: (value) {
                                    isDragging = true;
                                    dragValue = value;
                                  },

                                  onChanged: (value) {
                                    dragValue = value;
                                  },

                                  onChangeEnd: (value) async {
                                    isDragging = false;
                                    await player.seek(
                                      Duration(milliseconds: value.toInt()),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formatTime(pos),
                              style: const TextStyle(color: Colors.white),
                            ),
                            Text(
                              formatTime(dur),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),

          const SizedBox(height: 40),

          /// ===================== CONTROLS =====================
          IconButton(
            iconSize: 64,
            color: Colors.white,
            icon: const Icon(Icons.play_arrow),
            onPressed: () async {
              final songs = await audioQuery.querySongs();
              if (songs.isNotEmpty && songs.first.uri != null) {
                await player.setAudioSource(
                  AudioSource.uri(Uri.parse(songs.first.uri!)),
                );
                player.play();
              }
            },
          ),
        ],
      ),
    );
  }
}
