import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SlideToUnlock extends StatefulWidget {
  final VoidCallback onSlideComplete;

  const SlideToUnlock({super.key, required this.onSlideComplete});

  @override
  State<SlideToUnlock> createState() => _SlideToUnlockState();
}

class _SlideToUnlockState extends State<SlideToUnlock> {
  double _dragPosition = 0;
  final double _trackWidth = 360;
  final double _thumbSize = 65;

  double get _maxDrag => _trackWidth - _thumbSize - 8;

  @override
  Widget build(BuildContext context) {
    final progress = _dragPosition / _maxDrag;

    return Center(
      child: SizedBox(
        width: _trackWidth,
        height: _thumbSize + 8,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              width: _trackWidth,
              height: _thumbSize + 8,
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(100),
                // ignore: deprecated_member_use
                border: Border.all(color: Colors.black.withOpacity(0.1)),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: 30),
                  child: AnimatedOpacity(
                    opacity: 1.0 - progress,
                    duration: const Duration(milliseconds: 100),
                    child: const Text(
                      'Slide to continue',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 4 + _dragPosition,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _dragPosition = (_dragPosition + details.delta.dx).clamp(
                      0.0,
                      _maxDrag,
                    );
                  });
                },
                onHorizontalDragEnd: (_) {
                  if (_dragPosition >= _maxDrag * 0.9) {
                    widget.onSlideComplete();
                  } else {
                    setState(() => _dragPosition = 0);
                  }
                },
                child: Container(
                  width: _thumbSize,
                  height: _thumbSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Icon(
                    CupertinoIcons.arrow_right,
                    color: Colors.black,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
