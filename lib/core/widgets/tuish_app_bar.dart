import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:tuish_food/core/constants/app_colors.dart';

class TuishAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TuishAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.centerTitle = true,
    this.elevation,
    this.backgroundColor,
  }) : assert(
          title == null || titleWidget == null,
          'Cannot provide both title and titleWidget',
        );

  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final bool centerTitle;
  final double? elevation;
  final Color? backgroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textOnDark : AppColors.textPrimary;
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: AppBar(
          title: titleWidget ??
              (title != null
                  ? Text(title!, style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ))
                  : null),
          centerTitle: centerTitle,
          elevation: 0,
          backgroundColor: backgroundColor ?? Colors.transparent,
          surfaceTintColor: Colors.transparent,
          iconTheme: IconThemeData(color: textColor),
          leading: leading ??
              (showBackButton && canPop
                  ? IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
                      onPressed: () => Navigator.of(context).maybePop(),
                    )
                  : null),
          automaticallyImplyLeading: showBackButton,
          actions: actions,
        ),
      ),
    );
  }
}
