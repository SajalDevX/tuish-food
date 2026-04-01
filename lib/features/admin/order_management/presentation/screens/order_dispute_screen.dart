import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:tuish_food/core/constants/app_colors.dart';
import 'package:tuish_food/core/constants/app_sizes.dart';
import 'package:tuish_food/core/constants/app_strings.dart';
import 'package:tuish_food/core/constants/app_typography.dart';
import 'package:tuish_food/core/constants/firebase_constants.dart';
import 'package:tuish_food/core/enums/order_status.dart';
import 'package:tuish_food/core/utils/formatters.dart';
import 'package:tuish_food/core/widgets/confirmation_dialog.dart';
import 'package:tuish_food/core/widgets/tuish_app_bar.dart';
import 'package:tuish_food/core/widgets/tuish_button.dart';
import 'package:tuish_food/core/widgets/tuish_text_field.dart';
import 'package:tuish_food/injection_container.dart';

class OrderDisputeScreen extends ConsumerStatefulWidget {
  const OrderDisputeScreen({
    super.key,
    required this.orderId,
  });

  final String orderId;

  @override
  ConsumerState<OrderDisputeScreen> createState() =>
      _OrderDisputeScreenState();
}

class _OrderDisputeScreenState extends ConsumerState<OrderDisputeScreen> {
  final _notesController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _resolveDispute(String resolution) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Resolve Dispute',
      message: 'Are you sure you want to apply "$resolution"?',
      confirmLabel: AppStrings.confirm,
      cancelLabel: AppStrings.cancel,
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      final firestore = ref.read(firestoreProvider);
      await firestore
          .collection(FirebaseConstants.ordersCollection)
          .doc(widget.orderId)
          .update({
        'disputeResolution': resolution,
        'disputeNotes': _notesController.text.trim(),
        'disputeResolvedAt': FieldValue.serverTimestamp(),
        'hasDispute': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dispute resolved: $resolution'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resolve dispute: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(_orderDetailProvider(widget.orderId));

    return Scaffold(
      appBar: const TuishAppBar(title: 'Order Dispute'),
      body: orderAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.error)),
        ),
        data: (data) {
          if (data == null) {
            return const Center(child: Text('Order not found'));
          }

          final orderNumber =
              Formatters.formatOrderNumber(widget.orderId);
          final customerName =
              data['customerName'] as String? ?? 'Unknown';
          final restaurantName =
              data['restaurantName'] as String? ?? 'Unknown';
          final status = OrderStatus.fromString(
              data['status'] as String? ?? 'placed');
          final totalAmount =
              (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
          final complaint =
              data['disputeDescription'] as String? ??
                  data['cancellationReason'] as String? ??
                  'No description provided';
          final createdAt =
              (data['createdAt'] as Timestamp?)?.toDate();
          final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

          return SingleChildScrollView(
            padding: AppSizes.paddingAllM,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order info summary
                Container(
                  padding: AppSizes.paddingAllM,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: AppSizes.borderRadiusM,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order Info',
                          style: AppTypography.titleMedium),
                      const SizedBox(height: AppSizes.s12),
                      _InfoRow(label: 'Order', value: orderNumber),
                      _InfoRow(
                          label: 'Customer', value: customerName),
                      _InfoRow(
                          label: 'Restaurant', value: restaurantName),
                      _InfoRow(
                          label: 'Status', value: status.displayName),
                      _InfoRow(
                        label: 'Amount',
                        value: Formatters.formatCurrency(totalAmount),
                      ),
                      if (createdAt != null)
                        _InfoRow(
                          label: 'Date',
                          value: dateFormat.format(createdAt),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.s24),

                // Customer complaint
                Text('Customer Complaint',
                    style: AppTypography.titleMedium),
                const SizedBox(height: AppSizes.s8),
                Container(
                  width: double.infinity,
                  padding: AppSizes.paddingAllM,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.05),
                    borderRadius: AppSizes.borderRadiusM,
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    complaint,
                    style: AppTypography.bodyMedium,
                  ),
                ),
                const SizedBox(height: AppSizes.s24),

                // Resolution notes
                TuishTextField(
                  label: 'Resolution Notes',
                  hint: 'Add notes about the resolution...',
                  controller: _notesController,
                  maxLines: 3,
                ),
                const SizedBox(height: AppSizes.s24),

                // Resolution actions
                Text('Resolution Actions',
                    style: AppTypography.titleMedium),
                const SizedBox(height: AppSizes.s12),

                TuishButton.primary(
                  label: 'Full Refund',
                  isLoading: _isProcessing,
                  icon: const Icon(Icons.money_off,
                      color: AppColors.onPrimary, size: 20),
                  onPressed: _isProcessing
                      ? null
                      : () => _resolveDispute('Full Refund'),
                ),
                const SizedBox(height: AppSizes.s12),

                TuishButton.secondary(
                  label: 'Partial Refund',
                  isLoading: _isProcessing,
                  icon: const Icon(Icons.attach_money,
                      color: AppColors.onSecondary, size: 20),
                  onPressed: _isProcessing
                      ? null
                      : () => _resolveDispute('Partial Refund'),
                ),
                const SizedBox(height: AppSizes.s12),

                TuishButton.outlined(
                  label: 'Warning to Partner',
                  isLoading: _isProcessing,
                  icon: const Icon(Icons.warning_amber_rounded,
                      color: AppColors.primary, size: 20),
                  onPressed: _isProcessing
                      ? null
                      : () => _resolveDispute('Warning to Partner'),
                ),
                const SizedBox(height: AppSizes.s12),

                TuishButton.text(
                  label: 'Dismiss',
                  isLoading: _isProcessing,
                  icon: const Icon(Icons.close,
                      color: AppColors.primary, size: 20),
                  onPressed: _isProcessing
                      ? null
                      : () => _resolveDispute('Dismissed'),
                ),

                const SizedBox(height: AppSizes.s48),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Internal provider to load single order data.
final _orderDetailProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, orderId) async {
  final firestore = ref.watch(firestoreProvider);
  final doc = await firestore
      .collection(FirebaseConstants.ordersCollection)
      .doc(orderId)
      .get();
  return doc.data();
});

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(value, style: AppTypography.bodyMedium),
          ),
        ],
      ),
    );
  }
}
