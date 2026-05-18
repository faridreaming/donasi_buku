import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Ya',
  String cancelLabel = 'Batal',
  bool isDestructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.black, width: 2.5),
          boxShadow: const [AppColors.neoShadow],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color:
                  isDestructive ? AppColors.dangerSurface : AppColors.primary,
              child: Text(title, style: AppTextStyles.heading2),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(message, style: AppTextStyles.body),
            ),
            // Actions
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.black, width: 1.5),
                ),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    // Cancel
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            cancelLabel,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.button.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(width: 1.5, color: AppColors.black),
                    // Confirm
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          color: isDestructive
                              ? AppColors.dangerSurface
                              : AppColors.primary,
                          child: Text(
                            confirmLabel,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.button,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}
