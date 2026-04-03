import 'package:flutter/material.dart';
import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/enums/order_status.dart';

class StatusBadge extends StatefulWidget {
  const StatusBadge({
    super.key,
    required this.status,
  });

  final OrderStatus status;

  @override
  State<StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<StatusBadge>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;
  Animation<double>? _pulseScale;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  @override
  void didUpdateWidget(StatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      _pulseController?.dispose();
      _pulseController = null;
      _pulseScale = null;
      _setupAnimation();
    }
  }

  void _setupAnimation() {
    if (widget.status.isActive) {
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
      );
      _pulseScale = Tween<double>(begin: 1.0, end: 1.05).animate(
        CurvedAnimation(
          parent: _pulseController!,
          curve: Curves.easeInOut,
        ),
      );
      _pulseController!.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  Color get _backgroundColor {
    return switch (widget.status) {
      OrderStatus.placed => AppColors.statusPlaced,
      OrderStatus.confirmed => AppColors.statusConfirmed,
      OrderStatus.preparing => AppColors.statusPreparing,
      OrderStatus.readyForPickup => AppColors.statusReady,
      OrderStatus.pickedUp => AppColors.statusPickedUp,
      OrderStatus.onTheWay => AppColors.statusOnTheWay,
      OrderStatus.delivered => AppColors.statusDelivered,
      OrderStatus.cancelled => AppColors.statusCancelled,
    };
  }

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s12,
        vertical: AppSizes.s4,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: AppSizes.borderRadiusPill,
      ),
      child: Text(
        widget.status.displayName,
        style: AppTypography.labelMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    if (_pulseController != null && _pulseScale != null) {
      return AnimatedBuilder(
        animation: _pulseScale!,
        builder: (context, child) =>
            Transform.scale(scale: _pulseScale!.value, child: child),
        child: badge,
      );
    }

    return badge;
  }
}
