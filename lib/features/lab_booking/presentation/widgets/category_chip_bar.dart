import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:med_super/core/theme/app_colors.dart';
import 'package:med_super/features/lab_booking/domain/entities/lab_test_category.dart';

class CategoryChipBar extends StatefulWidget {
  const CategoryChipBar({
    required this.categories,
    required this.activeId,
    required this.onSelected,
    super.key,
  });

  final List<LabTestCategory> categories;
  final String? activeId;
  final ValueChanged<String?> onSelected;

  @override
  State<CategoryChipBar> createState() => _CategoryChipBarState();
}

class _CategoryChipBarState extends State<CategoryChipBar> {
  final _itemKeys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    // The default active category (e.g. the pre-selected "packages" chip)
    // can start outside the visible scroll extent — in RTL, an unreversed
    // horizontal ListView's initial viewport shows its *first* array item,
    // so a later/default-selected chip is off to the side until scrolled,
    // reading as "half cut off". Bring it fully into view once, after the
    // first frame lays out real chip sizes.
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollActiveIntoView());
  }

  @override
  void didUpdateWidget(CategoryChipBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeId != oldWidget.activeId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollActiveIntoView());
    }
  }

  void _scrollActiveIntoView() {
    final key = _itemKeys[widget.activeId];
    final context = key?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 250),
      alignment: 0.5,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: widget.categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = widget.categories[index];
          final isActive = category.id == widget.activeId;
          final key = _itemKeys.putIfAbsent(category.id, () => GlobalKey());
          return ChoiceChip(
            key: key,
            label: Text(category.labelKey.tr()),
            selected: isActive,
            onSelected: (_) =>
                widget.onSelected(isActive ? null : category.id),
            backgroundColor: AppColors.surfaceApp,
            selectedColor: AppColors.tealBg,
            side: BorderSide(
              color: isActive
                  ? AppColors.tealAccent.withValues(alpha: 0.2)
                  : AppColors.borderLight,
            ),
            labelStyle: TextStyle(
              color: isActive ? AppColors.tealAccent : AppColors.bodyText,
              fontWeight: FontWeight.w500,
            ),
            shape: const StadiumBorder(),
          );
        },
      ),
    );
  }
}
