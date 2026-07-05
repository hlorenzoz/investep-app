import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../shared/widgets/glass/glass_card.dart';

class RegisterSaleDialog extends StatefulWidget {
  const RegisterSaleDialog({
    super.key,
    required this.onConfirm,
  });

  final void Function(DateTime soldAt, double sellPrice) onConfirm;

  @override
  State<RegisterSaleDialog> createState() => _RegisterSaleDialogState();
}

class _RegisterSaleDialogState extends State<RegisterSaleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  DateTime _soldAt = DateTime.now();

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _soldAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null && mounted) {
      setState(() {
        _soldAt = picked;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final price = double.tryParse(_priceController.text);
      if (price != null && price > 0) {
        widget.onConfirm(_soldAt, price);
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final glassTheme = context.glass;
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      contentPadding: EdgeInsets.zero,
      content: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.banknote, color: theme.colorScheme.primary, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Registrar Venta',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: glassTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Fecha de Venta (soldAt)
              InkWell(
                onTap: () => _selectDate(context),
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Fecha de Venta',
                    labelStyle: TextStyle(color: glassTheme.textSecondary),
                    prefixIcon: Icon(LucideIcons.calendar, color: glassTheme.textSecondary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: glassTheme.glassBorder),
                    ),
                  ),
                  child: Text(
                    _formatDate(_soldAt),
                    style: TextStyle(color: glassTheme.textPrimary),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Precio de Venta (sellPrice)
              TextFormField(
                controller: _priceController,
                style: TextStyle(color: glassTheme.textPrimary),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Precio de Venta (unitario)',
                  labelStyle: TextStyle(color: glassTheme.textSecondary),
                  prefixIcon: Icon(LucideIcons.dollarSign, color: glassTheme.textSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: glassTheme.glassBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El precio de venta es obligatorio';
                  }
                  final numVal = double.tryParse(value);
                  if (numVal == null || numVal <= 0) {
                    return 'Ingrese un precio mayor a 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Confirmar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
