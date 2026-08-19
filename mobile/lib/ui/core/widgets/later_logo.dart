import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:later/ui/core/theme/later_assets.dart';

class LaterLogo extends StatelessWidget {
  const LaterLogo.mark({
    super.key,
    this.height = 28,
    this.alignment = Alignment.centerLeft,
  }) : asset = LaterAssets.mark;

  const LaterLogo.wordmark({
    super.key,
    this.height = 88,
    this.alignment = Alignment.centerLeft,
  }) : asset = LaterAssets.wordmark;

  const LaterLogo.full({
    super.key,
    this.height = 100,
    this.alignment = Alignment.center,
  }) : asset = LaterAssets.logowithtext;

  final String asset;
  final double height;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return SvgPicture.asset(
      asset,
      height: height,
      alignment: alignment,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      semanticsLabel: 'Later',
    );
  }
}
