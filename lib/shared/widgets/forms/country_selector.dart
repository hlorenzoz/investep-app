// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:investep_app/core/config/countries.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CountrySelector extends StatefulWidget {
  final Country? selectedCountry;
  final List<Country> availableCountries;
  final ValueChanged<Country?> onSelected;
  final bool enabled;

  const CountrySelector({
    super.key,
    required this.selectedCountry,
    required this.availableCountries,
    required this.onSelected,
    this.enabled = true,
  });

  @override
  State<CountrySelector> createState() => _CountrySelectorState();
}

class _CountrySelectorState extends State<CountrySelector> {
  final MenuController _menuController = MenuController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.availableCountries.where((c) {
      final q = _searchQuery.toLowerCase().trim();
      if (q.isEmpty) return true;
      return c.name.toLowerCase().contains(q) || c.dialCode.contains(q);
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return MenuAnchor(
          controller: _menuController,
          style: MenuStyle(
            fixedSize: WidgetStateProperty.all(Size(width, 360)),
            backgroundColor: WidgetStateProperty.all(
              Theme.of(context).colorScheme.surface,
            ),
            surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
              ),
            ),
            elevation: WidgetStateProperty.all(8.0),
          ),
          onOpen: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _searchFocusNode.requestFocus();
            });
          },
          onClose: () {
            _searchController.clear();
          },
          menuChildren: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: TextFormField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar país o prefijo (+34)...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surface.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            SizedBox(
              height: 280,
              child: filtered.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No se encontraron países',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          final isSelected = widget.selectedCountry == null;
                          return ListTile(
                            dense: true,
                            leading: const Icon(LucideIcons.globe, size: 18),
                            title: const Text(
                              'Sin País',
                              style: TextStyle(fontSize: 14),
                            ),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    size: 18,
                                  )
                                : null,
                            onTap: () {
                              widget.onSelected(null);
                              _menuController.close();
                            },
                          );
                        }
                        final country = filtered[index - 1];
                        final isSelected =
                            widget.selectedCountry?.code == country.code;
                        return ListTile(
                          dense: true,
                          leading: Text(
                            country.flag,
                            style: const TextStyle(fontSize: 18),
                          ),
                          title: Text(
                            country.displayName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 18,
                                )
                              : null,
                          onTap: () {
                            widget.onSelected(country);
                            _menuController.close();
                          },
                        );
                      },
                    ),
            ),
          ],
          builder: (context, controller, child) {
            final displayText = widget.selectedCountry != null
                ? '${widget.selectedCountry!.flag}  ${widget.selectedCountry!.name}'
                : 'Sin País';

            return InkWell(
              onTap: widget.enabled
                  ? () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    }
                  : null,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'País (Opcional)',
                  prefixIcon: const Icon(LucideIcons.globe, size: 20),
                  suffixIcon: Icon(
                    controller.isOpen
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    size: 20,
                  ),
                ),
                isEmpty: false,
                child: Text(
                  displayText,
                  style: TextStyle(
                    fontSize: 16,
                    color: widget.enabled
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : Theme.of(context).disabledColor,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
