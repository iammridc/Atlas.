import 'dart:typed_data';

import 'package:atlas/core/consts/app_colors.dart';
import 'package:atlas/core/utils/app_snackbar.dart';
import 'package:atlas/core/utils/google_places_photo.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  final String? placeSubtitle;
  final String? photoReference;

  const ReviewEditorPage({
    super.key,
    required this.title,
    required this.initialPlaceName,
    required this.allowPlaceNameEditing,
    required this.initialRating,
    required this.initialText,
    this.placeSubtitle,
    this.photoReference,
  });

  @override
  State<ReviewEditorPage> createState() => _ReviewEditorPageState();
}

class _ReviewEditorPageState extends State<ReviewEditorPage> {
  static const _maxReviewLength = 500;
  static const _maxPhotos = 5;
  static const _chips = [
    'Food',
    'Service',
    'Atmosphere',
    'Views',
    'Comfort',
    'Safety',
    'Culture',
    'Quiet',
    'Activities',
  ];

  late final TextEditingController _placeNameController;
  late final TextEditingController _textController;
  final _imagePicker = ImagePicker();
  final _selectedChips = <String>{};
  final _photos = <Uint8List>[];
  late int _rating;

  @override
  void initState() {
    super.initState();
    _placeNameController = TextEditingController(text: widget.initialPlaceName);
    _textController = TextEditingController(text: widget.initialText)
      ..addListener(_handleTextChanged);
    _rating = widget.initialRating.clamp(1, 5);
  }

  @override
  void dispose() {
    _placeNameController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _pickPhotos() async {
    if (_photos.length >= _maxPhotos) return;

    try {
      final pickedFiles = await _imagePicker.pickMultiImage(imageQuality: 85);
      if (pickedFiles.isEmpty || !mounted) return;

      final remainingSlots = _maxPhotos - _photos.length;
      final bytes = <Uint8List>[];
      for (final file in pickedFiles.take(remainingSlots)) {
        bytes.add(await file.readAsBytes());
      }

      if (!mounted) return;
      setState(() => _photos.addAll(bytes));
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        message: 'Failed to open photo library. Please try again.',
        type: SnackbarType.error,
      );
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
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
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _ReviewHero(
              placeName: _placeNameController.text.trim().isEmpty
                  ? 'New place'
                  : _placeNameController.text.trim(),
              subtitle: _placeSubtitle,
              photoReference: widget.photoReference,
              allowPlaceNameEditing: widget.allowPlaceNameEditing,
              placeNameController: _placeNameController,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RatingBlock(
                    rating: _rating,
                    onChanged: (value) => setState(() => _rating = value),
                  ),
                  const SizedBox(height: 26),
                  _ChipBlock(
                    selected: _selectedChips,
                    onToggle: (chip) {
                      setState(() {
                        if (!_selectedChips.add(chip)) {
                          _selectedChips.remove(chip);
                        }
                      });
                    },
                    chips: _chips,
                  ),
                  const SizedBox(height: 26),
                  _ReviewTextField(controller: _textController),
                  const SizedBox(height: 24),
                  _PhotoPickerBlock(
                    photos: _photos,
                    onAdd: _pickPhotos,
                    onRemove: _removePhoto,
                    maxPhotos: _maxPhotos,
                  ),
                  const SizedBox(height: 22),
                  _SubmitReviewButton(
                    isEditing: widget.title.toLowerCase().contains('edit'),
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _placeSubtitle {
    final subtitle = widget.placeSubtitle?.trim();
    if (subtitle != null && subtitle.isNotEmpty) return subtitle;
    return 'Share details from your visit';
  }
}

class _SubmitReviewButton extends StatelessWidget {
  final bool isEditing;
  final VoidCallback onPressed;

  const _SubmitReviewButton({required this.isEditing, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: onPressed,
        child: Text(isEditing ? 'Update review' : 'Submit review'),
      ),
    );
  }
}

class _ReviewHero extends StatelessWidget {
  final String placeName;
  final String subtitle;
  final String? photoReference;
  final bool allowPlaceNameEditing;
  final TextEditingController placeNameController;

  const _ReviewHero({
    required this.placeName,
    required this.subtitle,
    required this.photoReference,
    required this.allowPlaceNameEditing,
    required this.placeNameController,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final imageUrl = _imageUrl;

    return SizedBox(
      height: allowPlaceNameEditing ? 372 : 326,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            height: 256 + topInset,
            width: double.infinity,
            child: imageUrl == null
                ? _HeroFallback(isDark: isDark)
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _HeroFallback(isDark: isDark),
                  ),
          ),
          Positioned.fill(
            bottom: allowPlaceNameEditing ? 116 : 70,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.42),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.36),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: topInset + 12,
            left: 14,
            right: 14,
            child: SizedBox(
              height: 44,
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton.filled(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(CupertinoIcons.chevron_left, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                    foregroundColor: isDark
                        ? AppColors.appPrimaryWhite
                        : AppColors.appPrimaryBlack,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    fixedSize: const Size(42, 42),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: allowPlaceNameEditing ? 30 : 18,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 62,
                      height: 62,
                      child: imageUrl == null
                          ? _ThumbFallback(isDark: isDark)
                          : Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _ThumbFallback(isDark: isDark),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: allowPlaceNameEditing
                        ? TextField(
                            controller: placeNameController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Place name',
                              isDense: true,
                              border: InputBorder.none,
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                placeName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? get _imageUrl {
    final reference = photoReference?.trim();
    if (reference == null || reference.isEmpty) return null;
    return buildGooglePlacePhotoUrl(reference, maxWidthPx: 1200);
  }
}

class _HeroFallback extends StatelessWidget {
  final bool isDark;

  const _HeroFallback({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black),
      child: Center(
        child: Icon(
          CupertinoIcons.location_solid,
          size: 52,
          color: isDark ? Colors.white54 : Colors.white70,
        ),
      ),
    );
  }
}

class _ThumbFallback extends StatelessWidget {
  final bool isDark;

  const _ThumbFallback({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.08),
      ),
      child: Icon(
        CupertinoIcons.photo,
        color: isDark ? Colors.white54 : Colors.black45,
      ),
    );
  }
}

class _RatingBlock extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onChanged;

  const _RatingBlock({required this.rating, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          'How was your visit?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Your feedback helps other travelers',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? Colors.white60 : Colors.black54,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 18),
        _StarRatingField(value: rating, onChanged: onChanged),
        const SizedBox(height: 10),
        Text(
          _ratingLabel(rating),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  String _ratingLabel(int value) {
    return switch (value) {
      1 => 'Not great',
      2 => 'Could be better',
      3 => 'Good',
      4 => 'Great!',
      _ => 'Amazing!',
    };
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
    final inactiveColor = isDark ? Colors.white24 : Colors.black12;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return Semantics(
          button: true,
          label: '$starValue star${starValue == 1 ? '' : 's'}',
          child: InkResponse(
            onTap: () => onChanged(starValue),
            radius: 24,
            child: SizedBox(
              width: 46,
              height: 46,
              child: Icon(
                starValue <= value
                    ? CupertinoIcons.star_fill
                    : CupertinoIcons.star,
                size: 36,
                color: starValue <= value ? activeColor : inactiveColor,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _ChipBlock extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final List<String> chips;

  const _ChipBlock({
    required this.selected,
    required this.onToggle,
    required this.chips,
  });

  @override
  Widget build(BuildContext context) {
    return _FieldGroup(
      title: 'What did you like the most?',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: chips.map((chip) {
          final isSelected = selected.contains(chip);
          return _ChoiceChipButton(
            label: chip,
            selected: isSelected,
            onTap: () => onToggle(chip),
          );
        }).toList(),
      ),
    );
  }
}

class _ChoiceChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = selected
        ? (isDark
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.black.withValues(alpha: 0.12))
        : (isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08));
    final foregroundColor = isDark ? Colors.white : Colors.black87;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(999)),
          child: Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewTextField extends StatelessWidget {
  final TextEditingController controller;

  const _ReviewTextField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final count = controller.text.characters.length;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.black12;

    return _FieldGroup(
      title: 'Write your review',
      child: TextField(
        controller: controller,
        minLines: 5,
        maxLines: 7,
        maxLength: _ReviewEditorPageState._maxReviewLength,
        textInputAction: TextInputAction.newline,
        decoration: InputDecoration(
          hintText: 'Add details about your experience...',
          counterText: '$count/${_ReviewEditorPageState._maxReviewLength}',
          alignLabelWithHint: true,
          filled: true,
          fillColor: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.025),
          contentPadding: const EdgeInsets.all(14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoPickerBlock extends StatelessWidget {
  final List<Uint8List> photos;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final int maxPhotos;

  const _PhotoPickerBlock({
    required this.photos,
    required this.onAdd,
    required this.onRemove,
    required this.maxPhotos,
  });

  @override
  Widget build(BuildContext context) {
    return _FieldGroup(
      title: 'Add photos',
      subtitle: 'Optional',
      child: SizedBox(
        height: 74,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: photos.length < maxPhotos ? photos.length + 1 : maxPhotos,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            if (index >= photos.length) {
              return _AddPhotoTile(onTap: onAdd);
            }
            return _PhotoTile(
              bytes: photos[index],
              onRemove: () => onRemove(index),
            );
          },
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final Uint8List bytes;
  final VoidCallback onRemove;

  const _PhotoTile({required this.bytes, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(bytes, width: 74, height: 74, fit: BoxFit.cover),
        ),
        Positioned(
          top: -8,
          right: -8,
          child: IconButton.filled(
            tooltip: 'Remove photo',
            onPressed: onRemove,
            icon: const Icon(CupertinoIcons.xmark, size: 13),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              fixedSize: const Size(28, 28),
              minimumSize: const Size(28, 28),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AddPhotoTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        ),
        child: Icon(
          CupertinoIcons.plus,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }
}

class _FieldGroup extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _FieldGroup({required this.title, required this.child, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black45,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}
