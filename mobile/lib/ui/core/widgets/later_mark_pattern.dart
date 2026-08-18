import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:later/ui/core/theme/later_assets.dart';

/// Single large decorative mark watermark anchored in the bottom right, shifted slightly upper.
class LaterMarkPattern extends StatelessWidget {
  const LaterMarkPattern({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final light = Theme.of(context).brightness == Brightness.light;
    final alpha = light ? 0.055 : 0.075;

    final markWidth = size.width * 0.72;
    final markHeight = markWidth * (852 / 727);

    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomRight,
        child: OverflowBox(
          alignment: Alignment.bottomRight,
          maxWidth: size.width * 1.3,
          maxHeight: size.height * 0.9,
          child: Transform.translate(
            offset: const Offset(20, -130),
            child: SvgPicture.asset(
              LaterAssets.mark,
              width: markWidth,
              height: markHeight,
              colorFilter: ColorFilter.mode(
                onSurface.withValues(alpha: alpha),
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
