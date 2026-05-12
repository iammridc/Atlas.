import 'package:flutter/material.dart';

class FittedSingleLineText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final Alignment alignment;

  const FittedSingleLineText(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.start,
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth) {
          return Text(
            text,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            textAlign: textAlign,
            style: style,
          );
        }

        return SizedBox(
          width: constraints.maxWidth,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: alignment,
            child: Text(
              text,
              maxLines: 1,
              softWrap: false,
              textAlign: textAlign,
              style: style,
            ),
          ),
        );
      },
    );
  }
}
