import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/music_provider.dart';
import '../constants/ui_constants.dart';

class MiniPlayerSafeScroll extends StatelessWidget {
  final Widget child;

  const MiniPlayerSafeScroll({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, _) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: provider.currentSong != null
                ? UiConstants.miniPlayerTotalHeight
                : 0,
          ),
          child: child,
        );
      },
    );
  }
}
