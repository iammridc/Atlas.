import 'package:atlas/core/consts/app_colors.dart';
import 'package:atlas/core/utils/app_snackbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ReviewEditorResult {
  final String placeName;
  final int rating;
  final String text;

  const ReviewEditorResult({
    required this.placeName,
    required this.rating,
    required this.text,
  });
}

class ReviewEditorPage extends StatefulWidget {
  final String title;
  final String initialPlaceName;
  final bool allowPlaceNameEditing;
  final int initialRating;
  final String initialText;

  const ReviewEditorPage({
    super.key,
    required this.title,
    required this.initialPlaceName,
    required this.allowPlaceNameEditing,
    required this.initialRating,
    required this.initialText,
  });

  @override
  State<ReviewEditorPage> createState() => _ReviewEditorPageState();
}

class _ReviewEditorPageState extends State<ReviewEditorPage> {
  late final TextEditingController _placeNameController;
  late final TextEditingController _textController;
  late int _rating;

  @override
  void initState() {
    super.initState();
    _placeNameController = TextEditingController(text: widget.initialPlaceName);
    _textController = TextEditingController(text: widget.initialText);
    _rating = widget.initialRating.clamp(1, 5);
  }

  @override
  void dispose() {
    _placeNameController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _save() {
    final placeName = _placeNameController.text.trim();
    final text = _textController.text.trim();

    if (widget.allowPlaceNameEditing && placeName.isEmpty) {
      AppSnackbar.show(
        context,
        message: 'Place name is required.',
        type: SnackbarType.error,
      );
      return;
    }

    if (text.isEmpty) {
      AppSnackbar.show(
        context,
        message: 'Review text is required.',
        type: SnackbarType.error,
      );
      return;
    }

    Navigator.of(context).pop(
      ReviewEditorResult(placeName: placeName, rating: _rating, text: text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            if (widget.allowPlaceNameEditing) ...[
              TextField(
                controller: _placeNameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Place name'),
              ),
              const SizedBox(height: 24),
            ] else ...[
              Text(
                widget.initialPlaceName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
            ],
            const Text(
              'Rating',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _StarRatingField(
              value: _rating,
              onChanged: (value) => setState(() => _rating = value),
            ),
            const SizedBox(height: 8),
            Text(
              '$_rating of 5 stars',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _textController,
              minLines: 5,
              maxLines: 8,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: 'Review text',
                hintText: 'Write what stood out to you',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Text('Save review'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarRatingField extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _StarRatingField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark
        ? AppColors.appPrimaryWhite
        : AppColors.appPrimaryBlack;
    final inactiveColor = isDark ? Colors.white24 : Colors.black26;

    return Wrap(
      spacing: 8,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return InkResponse(
          onTap: () => onChanged(starValue),
          radius: 24,
          child: Icon(
            starValue <= value ? CupertinoIcons.star_fill : CupertinoIcons.star,
            size: 32,
            color: starValue <= value ? activeColor : inactiveColor,
          ),
        );
      }),
    );
  }
}
