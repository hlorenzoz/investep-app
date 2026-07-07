import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../domain/recommended_book.dart';
import 'books_providers.dart';
import '../../../shared/widgets/app_bar_actions.dart';

class AdminBookFormScreen extends ConsumerStatefulWidget {
  const AdminBookFormScreen({super.key, this.bookId, this.book});

  final int? bookId;
  final RecommendedBook? book;

  @override
  ConsumerState<AdminBookFormScreen> createState() =>
      _AdminBookFormScreenState();
}

class _AdminBookFormScreenState extends ConsumerState<AdminBookFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _slugController;
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _descriptionController;
  late TextEditingController _urlController;
  late TextEditingController _imageController;
  late TextEditingController _sortOrderController;

  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    final b = widget.book;
    if (b != null) {
      _slugController = TextEditingController(text: b.slug);
      _titleController = TextEditingController(text: b.title);
      _authorController = TextEditingController(text: b.author);
      _descriptionController = TextEditingController(text: b.description);
      _urlController = TextEditingController(text: b.url);
      _imageController = TextEditingController(text: b.image);
      _sortOrderController = TextEditingController(
        text: b.sortOrder.toString(),
      );
      _isInitialized = true;
    } else {
      _slugController = TextEditingController();
      _titleController = TextEditingController();
      _authorController = TextEditingController();
      _descriptionController = TextEditingController();
      _urlController = TextEditingController();
      _imageController = TextEditingController();
      _sortOrderController = TextEditingController(text: '0');
    }
  }

  void _initializeWith(RecommendedBook b) {
    _slugController.text = b.slug;
    _titleController.text = b.title;
    _authorController.text = b.author;
    _descriptionController.text = b.description;
    _urlController.text = b.url;
    _imageController.text = b.image;
    _sortOrderController.text = b.sortOrder.toString();
  }

  @override
  void dispose() {
    _slugController.dispose();
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    _imageController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final slug = _slugController.text.trim();
    final title = _titleController.text.trim();
    final author = _authorController.text.trim();
    final description = _descriptionController.text.trim();
    final url = _urlController.text.trim();
    final image = _imageController.text.trim();
    final sortOrder = int.parse(_sortOrderController.text.trim());

    final data = <String, dynamic>{
      'slug': slug,
      'title': title,
      'author': author,
      'description': description,
      'url': url,
      'image': image,
      'sortOrder': sortOrder,
    };

    setState(() => _isLoading = true);

    final success = widget.bookId != null
        ? await ref
              .read(booksAdminControllerProvider.notifier)
              .updateRecommendedBook(widget.bookId!, data)
        : await ref
              .read(booksAdminControllerProvider.notifier)
              .createRecommendedBook(data);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Libro guardado correctamente.'),
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
    final isEdit = widget.bookId != null;

    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 600;

    // Escuchar el controlador admin para mostrar Snackbars de error
    ref.listen<AsyncValue<void>>(booksAdminControllerProvider, (prev, next) {
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

    final bookAsync = widget.bookId != null && widget.book == null
        ? ref.watch(bookDetailProvider(widget.bookId!.toString()))
        : null;

    if (bookAsync != null) {
      return bookAsync.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, _) => Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: Center(child: Text('Error al cargar el libro: $err')),
        ),
        data: (loadedBook) {
          if (!_isInitialized) {
            _initializeWith(loadedBook);
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
              hintText: 'ej: habitos-atomicos',
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
                return 'El slug solo permite minúsculas, números y guiones.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Title
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Título',
              prefixIcon: const Icon(LucideIcons.tag, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            style: TextStyle(color: glassTheme.textPrimary),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El título es obligatorio.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Author
          TextFormField(
            controller: _authorController,
            decoration: InputDecoration(
              labelText: 'Autor',
              prefixIcon: const Icon(LucideIcons.user, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            style: TextStyle(color: glassTheme.textPrimary),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El autor es obligatorio.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Description
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Descripción',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            style: TextStyle(color: glassTheme.textPrimary),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La descripción es obligatoria.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // URL
          TextFormField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: 'Enlace externo (URL)',
              prefixIcon: const Icon(LucideIcons.externalLink, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            style: TextStyle(color: glassTheme.textPrimary),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El enlace es obligatorio.';
              }
              final uri = Uri.tryParse(value.trim());
              if (uri == null ||
                  !uri.isAbsolute ||
                  (uri.scheme != 'http' && uri.scheme != 'https')) {
                return 'Debe ser un enlace URL absoluto válido.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Image
          TextFormField(
            controller: _imageController,
            decoration: InputDecoration(
              labelText: 'Ruta de la imagen',
              hintText: 'ej: books/habitos-atomicos.webp',
              prefixIcon: const Icon(LucideIcons.image, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            style: TextStyle(color: glassTheme.textPrimary),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La ruta de la imagen es obligatoria.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // SortOrder
          TextFormField(
            controller: _sortOrderController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Orden de visualización (sortOrder)',
              prefixIcon: const Icon(LucideIcons.sortAsc, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            style: TextStyle(color: glassTheme.textPrimary),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El orden es obligatorio.';
              }
              if (int.tryParse(value.trim()) == null) {
                return 'Debe ser un número entero válido.';
              }
              return null;
            },
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
                    isEdit ? 'Guardar Cambios' : 'Crear Libro',
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
          title: Text(isEdit ? 'Editar Libro' : 'Crear Libro'),
          actions: buildAppBarActions(context),
        ),
        body: SafeArea(child: formContent),
      ),
    );
  }
}
