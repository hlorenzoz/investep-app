import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../domain/product.dart';
import 'store_providers.dart';
import '../../../shared/widgets/app_bar_actions.dart';

class AdminStoreFormScreen extends ConsumerStatefulWidget {
  const AdminStoreFormScreen({super.key, this.productId, this.product});

  final int? productId;
  final Product? product;

  @override
  ConsumerState<AdminStoreFormScreen> createState() =>
      _AdminStoreFormScreenState();
}

class _AdminStoreFormScreenState extends ConsumerState<AdminStoreFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _slugController;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _currencyController;
  late TextEditingController _amazonUrlController;
  late TextEditingController _imageController;

  ProductCategory _category = ProductCategory.book;
  ProductGender? _gender;
  ProductTheme? _theme;
  bool _active = true;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      _slugController = TextEditingController(text: p.slug);
      _nameController = TextEditingController(text: p.name);
      _descriptionController = TextEditingController(text: p.description ?? '');
      _priceController = TextEditingController(text: p.price?.toString() ?? '');
      _currencyController = TextEditingController(text: p.currency);
      _amazonUrlController = TextEditingController(text: p.amazonUrl ?? '');
      _imageController = TextEditingController(text: p.image ?? '');
      _category = p.category;
      _gender = p.gender;
      _theme = p.theme;
      _active = p.active;
      _isInitialized = true;
    } else {
      _slugController = TextEditingController();
      _nameController = TextEditingController();
      _descriptionController = TextEditingController();
      _priceController = TextEditingController();
      _currencyController = TextEditingController(text: 'USD');
      _amazonUrlController = TextEditingController();
      _imageController = TextEditingController();
    }
  }

  void _initializeWith(Product p) {
    _slugController.text = p.slug;
    _nameController.text = p.name;
    _descriptionController.text = p.description ?? '';
    _priceController.text = p.price?.toString() ?? '';
    _currencyController.text = p.currency;
    _amazonUrlController.text = p.amazonUrl ?? '';
    _imageController.text = p.image ?? '';
    _category = p.category;
    _gender = p.gender;
    _theme = p.theme;
    _active = p.active;
  }

  @override
  void dispose() {
    _slugController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _currencyController.dispose();
    _amazonUrlController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context);

    // Validaciones contractuales adicionales del lado del cliente
    final priceText = _priceController.text.trim();
    final price = double.tryParse(priceText);
    final amazonUrl = _amazonUrlController.text.trim();

    // 1. Definir al menos un precio o enlace de Amazon
    if (price == null && amazonUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.storeFormValidationPriceOrAmazon),
          backgroundColor: AppColors.negative,
        ),
      );
      return;
    }

    final slug = _slugController.text.trim();
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final currency = _currencyController.text.trim();
    final image = _imageController.text.trim();

    // 2. gender y theme solo si es tshirt. En otro caso, forzar null.
    final finalGender = _category == ProductCategory.tshirt ? _gender : null;
    final finalTheme = _category == ProductCategory.tshirt ? _theme : null;

    final data = <String, dynamic>{
      'slug': slug,
      'name': name,
      'description': description.isEmpty ? null : description,
      'category': _category.toJson(),
      'gender': finalGender?.toJson(),
      'theme': finalTheme?.toJson(),
      'price': price,
      'currency': currency.isEmpty ? 'USD' : currency,
      'amazonUrl': amazonUrl.isEmpty ? null : amazonUrl,
      'image': image.isEmpty ? null : image,
      'active': _active,
    };

    setState(() => _isLoading = true);

    final success = widget.productId != null
        ? await ref
              .read(storeAdminControllerProvider.notifier)
              .updateProduct(widget.productId!, data)
        : await ref
              .read(storeAdminControllerProvider.notifier)
              .createProduct(data);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.storeSaveSuccess),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final glassTheme = context.glass;
    final isEdit = widget.productId != null;

    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 600;

    // Escuchar el controlador admin para mostrar Snackbars de error
    ref.listen<AsyncValue<void>>(storeAdminControllerProvider, (prev, next) {
      next.whenOrNull(
        error: (err, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $err'),
              backgroundColor: AppColors.negative,
            ),
          );
        },
      );
    });

    final productAsync = widget.productId != null && widget.product == null
        ? ref.watch(productDetailProvider(widget.productId!.toString()))
        : null;

    if (productAsync != null) {
      return productAsync.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, _) => Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: Center(child: Text('Error al cargar producto: $err')),
        ),
        data: (loadedProduct) {
          if (!_isInitialized) {
            _initializeWith(loadedProduct);
            _isInitialized = true;
          }
          return _buildForm(
            context,
            l10n,
            glassTheme,
            isEdit,
            isLargeScreen,
            screenWidth,
          );
        },
      );
    }

    return _buildForm(
      context,
      l10n,
      glassTheme,
      isEdit,
      isLargeScreen,
      screenWidth,
    );
  }

  Widget _buildForm(
    BuildContext context,
    AppLocalizations l10n,
    GlassThemeExtension glassTheme,
    bool isEdit,
    bool isLargeScreen,
    double screenWidth,
  ) {
    Widget formContent = Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // Slug
          TextFormField(
            controller: _slugController,
            decoration: InputDecoration(
              labelText: 'Slug',
              hintText: 'ej: libro-aprender-invertir',
              prefixIcon: const Icon(LucideIcons.link2, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            style: TextStyle(color: glassTheme.textPrimary),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El slug es obligatorio.';
              }
              final slugRegex = RegExp(r'^[a-z0-9_-]+$');
              if (!slugRegex.hasMatch(value.trim())) {
                return l10n.storeFormValidationSlug;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Name
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nombre',
              prefixIcon: const Icon(LucideIcons.tag, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            style: TextStyle(color: glassTheme.textPrimary),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El nombre es obligatorio.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Description
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Descripción (Opcional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            style: TextStyle(color: glassTheme.textPrimary),
          ),
          const SizedBox(height: 16),

          // Category
          DropdownButtonFormField<ProductCategory>(
            initialValue: _category,
            decoration: InputDecoration(
              labelText: 'Categoría',
              prefixIcon: const Icon(LucideIcons.layers, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            dropdownColor: Colors.grey.shade900,
            style: TextStyle(color: glassTheme.textPrimary),
            items: [
              DropdownMenuItem(
                value: ProductCategory.book,
                child: Text(l10n.storeCategoryBooks),
              ),
              DropdownMenuItem(
                value: ProductCategory.tshirt,
                child: Text(l10n.storeCategoryTshirts),
              ),
              DropdownMenuItem(
                value: ProductCategory.cap,
                child: Text(l10n.storeCategoryCaps),
              ),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _category = val;
                  // Si no es tshirt, limpiamos las variantes
                  if (_category != ProductCategory.tshirt) {
                    _gender = null;
                    _theme = null;
                  }
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // Tshirt Variants (Gender and Theme)
          if (_category == ProductCategory.tshirt) ...[
            DropdownButtonFormField<ProductGender>(
              initialValue: _gender,
              decoration: InputDecoration(
                labelText: 'Género (Opcional)',
                prefixIcon: const Icon(LucideIcons.user, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              dropdownColor: Colors.grey.shade900,
              style: TextStyle(color: glassTheme.textPrimary),
              items: const [
                DropdownMenuItem(value: null, child: Text('No definido')),
                DropdownMenuItem(
                  value: ProductGender.men,
                  child: Text('Hombres'),
                ),
                DropdownMenuItem(
                  value: ProductGender.women,
                  child: Text('Mujeres'),
                ),
              ],
              onChanged: (val) => setState(() => _gender = val),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ProductTheme>(
              initialValue: _theme,
              decoration: InputDecoration(
                labelText: 'Tema (Opcional)',
                prefixIcon: const Icon(LucideIcons.palette, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              dropdownColor: Colors.grey.shade900,
              style: TextStyle(color: glassTheme.textPrimary),
              items: const [
                DropdownMenuItem(value: null, child: Text('No definido')),
                DropdownMenuItem(
                  value: ProductTheme.light,
                  child: Text('Claro'),
                ),
                DropdownMenuItem(
                  value: ProductTheme.dark,
                  child: Text('Oscuro'),
                ),
              ],
              onChanged: (val) => setState(() => _theme = val),
            ),
            const SizedBox(height: 16),
          ],

          // Price & Currency
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Precio (Opcional)',
                    prefixIcon: const Icon(LucideIcons.dollarSign, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: TextStyle(color: glassTheme.textPrimary),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final val = double.tryParse(value);
                      if (val == null || val <= 0) {
                        return 'Debe ser un precio válido y mayor a 0.';
                      }
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: TextFormField(
                  controller: _currencyController,
                  decoration: InputDecoration(
                    labelText: 'Moneda',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: TextStyle(color: glassTheme.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Amazon URL
          TextFormField(
            controller: _amazonUrlController,
            decoration: InputDecoration(
              labelText: 'Enlace de Amazon (Opcional)',
              prefixIcon: const Icon(LucideIcons.externalLink, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            style: TextStyle(color: glassTheme.textPrimary),
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                final uri = Uri.tryParse(value.trim());
                if (uri == null ||
                    !uri.isAbsolute ||
                    (uri.scheme != 'http' && uri.scheme != 'https')) {
                  return 'Debe ser un enlace URL absoluto válido.';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Image Path
          TextFormField(
            controller: _imageController,
            decoration: InputDecoration(
              labelText: 'Ruta de la imagen (Opcional)',
              hintText: 'ej: store/ebooks/tmpjficd54i.webp',
              prefixIcon: const Icon(LucideIcons.image, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            style: TextStyle(color: glassTheme.textPrimary),
          ),
          const SizedBox(height: 16),

          // Active
          SwitchListTile(
            title: Text(
              'Producto Activo',
              style: TextStyle(color: glassTheme.textPrimary),
            ),
            subtitle: Text(
              'Indica si el producto se muestra en el catálogo público.',
              style: TextStyle(color: glassTheme.textSecondary, fontSize: 12),
            ),
            value: _active,
            onChanged: (val) => setState(() => _active = val),
          ),
          const SizedBox(height: 32),

          // Submit Button
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    isEdit ? 'Guardar Cambios' : 'Crear Producto',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );

    if (isLargeScreen) {
      formContent = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: screenWidth * 0.8),
          child: formContent,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(gradient: glassTheme.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(isEdit ? 'Editar Producto' : 'Crear Producto'),
          actions: buildAppBarActions(context),
        ),
        body: SafeArea(child: formContent),
      ),
    );
  }
}
