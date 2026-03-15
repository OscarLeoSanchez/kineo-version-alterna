import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';

// ─── Shopping List Page — T-20 ────────────────────────────────────────────────
//
// Receives weekly meals from the nutrition plan, consolidates all
// ingredients_with_quantities, groups by category, and provides checkboxes
// plus a clipboard-based share button.

class ShoppingListPage extends StatefulWidget {
  const ShoppingListPage({super.key, required this.weeklyMeals});

  final List<dynamic> weeklyMeals;

  @override
  State<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  late List<_ShoppingItem> _items;

  // ── Category keyword maps ──────────────────────────────────────────────────

  static const _proteinKeywords = [
    'pollo',
    'carne',
    'pescado',
    'huevo',
    'atun',
    'pavo',
    'salmon',
    'tofu',
    'res',
    'cerdo',
    'jamon',
    'sardina',
    'langostino',
    'camaron',
  ];

  static const _vegetableKeywords = [
    'brocoli',
    'espinaca',
    'zanahoria',
    'lechuga',
    'tomate',
    'pepino',
    'cebolla',
    'calabacin',
    'pimiento',
    'berenjena',
    'coliflor',
    'apio',
    'puerro',
    'champiñon',
    'champiñones',
    'espárragos',
    'esparragos',
    'pepinillo',
  ];

  static const _grainKeywords = [
    'arroz',
    'pasta',
    'avena',
    'pan',
    'quinoa',
    'lenteja',
    'frijol',
    'garbanzo',
    'harina',
    'maiz',
    'tortilla',
    'cuscus',
    'cereal',
    'trigo',
    'centeno',
  ];

  static const _dairyKeywords = [
    'leche',
    'yogur',
    'queso',
    'crema',
    'mantequilla',
    'lacteo',
    'kefir',
    'nata',
    'requesón',
    'requeson',
  ];

  // ── Data processing ────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _items = _buildItems();
  }

  List<_ShoppingItem> _buildItems() {
    // Collect all ingredients_with_quantities from every meal in the week
    final consolidated = <String, String>{};

    for (final meal in widget.weeklyMeals) {
      final mealMap = meal as Map<String, dynamic>;
      final raw = mealMap['ingredients_with_quantities'];
      if (raw == null) continue;

      if (raw is List) {
        for (final entry in raw) {
          final text = entry.toString().trim();
          if (text.isEmpty) continue;
          // Use lowercase ingredient name as key to deduplicate
          final key = text.toLowerCase();
          consolidated.putIfAbsent(key, () => text);
        }
      } else if (raw is String && raw.isNotEmpty) {
        // Sometimes it may be a comma-separated string
        final parts = raw.split(RegExp(r'[,\n]'));
        for (final part in parts) {
          final text = part.trim();
          if (text.isEmpty) continue;
          consolidated.putIfAbsent(text.toLowerCase(), () => text);
        }
      } else if (raw is Map) {
        raw.forEach((ingredient, quantity) {
          final text =
              '$ingredient${quantity != null ? ": $quantity" : ""}'.trim();
          if (text.isEmpty) return;
          consolidated.putIfAbsent(text.toLowerCase(), () => text);
        });
      }
    }

    // Build items with category
    return consolidated.values.map((text) {
      return _ShoppingItem(
        name: text,
        category: _classify(text),
        checked: false,
      );
    }).toList()
      ..sort((a, b) => a.category.index.compareTo(b.category.index));
  }

  _ShoppingCategory _classify(String text) {
    final lower = _removeDiacritics(text.toLowerCase());
    for (final kw in _proteinKeywords) {
      if (lower.contains(kw)) return _ShoppingCategory.protein;
    }
    for (final kw in _vegetableKeywords) {
      if (lower.contains(kw)) return _ShoppingCategory.vegetable;
    }
    for (final kw in _grainKeywords) {
      if (lower.contains(kw)) return _ShoppingCategory.grain;
    }
    for (final kw in _dairyKeywords) {
      if (lower.contains(kw)) return _ShoppingCategory.dairy;
    }
    return _ShoppingCategory.other;
  }

  String _removeDiacritics(String s) {
    const withDiacritics =
        'áàäâãéèëêíìïîóòöôõúùüûñç';
    const withoutDiacritics =
        'aaaaaeeeeiiiioooooouuuunc';
    var result = s;
    for (var i = 0; i < withDiacritics.length; i++) {
      result = result.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }
    return result;
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _toggleItem(int index) {
    setState(() {
      _items[index] = _items[index].copyWith(checked: !_items[index].checked);
    });
  }

  void _clearChecked() {
    setState(() {
      for (var i = 0; i < _items.length; i++) {
        if (_items[i].checked) {
          _items[i] = _items[i].copyWith(checked: false);
        }
      }
    });
  }

  void _copyToClipboard() {
    final buffer = StringBuffer();
    _ShoppingCategory? lastCategory;
    for (final item in _items) {
      if (item.category != lastCategory) {
        if (lastCategory != null) buffer.writeln();
        buffer.writeln(item.category.label);
        lastCategory = item.category;
      }
      final mark = item.checked ? '[x]' : '[ ]';
      buffer.writeln('  $mark ${item.name}');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lista copiada al portapapeles')),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasItems = _items.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de compras'),
        actions: [
          if (hasItems) ...[
            IconButton(
              icon: const Icon(Icons.copy_outlined),
              tooltip: 'Copiar lista',
              onPressed: _copyToClipboard,
            ),
            IconButton(
              icon: const Icon(Icons.check_box_outline_blank_rounded),
              tooltip: 'Limpiar marcados',
              onPressed: _clearChecked,
            ),
          ],
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: hasItems ? _buildList() : _buildEmpty(),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: AppColors.textDisabled,
            ),
            SizedBox(height: 16),
            Text(
              'No hay ingredientes disponibles en tu plan semanal.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    // Group items by category for display
    final grouped = <_ShoppingCategory, List<_ShoppingItem>>{};
    for (final item in _items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        for (final category in _ShoppingCategory.values)
          if (grouped.containsKey(category)) ...[
            _CategoryHeader(category: category),
            const SizedBox(height: 8),
            ...grouped[category]!.map((item) {
              final globalIndex = _items.indexOf(item);
              return _IngredientTile(
                item: item,
                onToggle: () => _toggleItem(globalIndex),
              );
            }),
            const SizedBox(height: 16),
          ],
      ],
    );
  }
}

// ─── Data models ──────────────────────────────────────────────────────────────

enum _ShoppingCategory {
  protein,
  vegetable,
  grain,
  dairy,
  other;

  String get label {
    switch (this) {
      case _ShoppingCategory.protein:
        return 'Proteinas';
      case _ShoppingCategory.vegetable:
        return 'Verduras';
      case _ShoppingCategory.grain:
        return 'Granos y Carbos';
      case _ShoppingCategory.dairy:
        return 'Lacteos';
      case _ShoppingCategory.other:
        return 'Otros';
    }
  }

  String get emoji {
    switch (this) {
      case _ShoppingCategory.protein:
        return '🥩';
      case _ShoppingCategory.vegetable:
        return '🥦';
      case _ShoppingCategory.grain:
        return '🌾';
      case _ShoppingCategory.dairy:
        return '🥛';
      case _ShoppingCategory.other:
        return '🫙';
    }
  }

  Color get color {
    switch (this) {
      case _ShoppingCategory.protein:
        return const Color(0xFFFEE2E2);
      case _ShoppingCategory.vegetable:
        return const Color(0xFFDCFCE7);
      case _ShoppingCategory.grain:
        return const Color(0xFFFEF3C7);
      case _ShoppingCategory.dairy:
        return const Color(0xFFDBEAFE);
      case _ShoppingCategory.other:
        return const Color(0xFFF3F4F6);
    }
  }
}

class _ShoppingItem {
  const _ShoppingItem({
    required this.name,
    required this.category,
    required this.checked,
  });

  final String name;
  final _ShoppingCategory category;
  final bool checked;

  _ShoppingItem copyWith({String? name, _ShoppingCategory? category, bool? checked}) {
    return _ShoppingItem(
      name: name ?? this.name,
      category: category ?? this.category,
      checked: checked ?? this.checked,
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.category});

  final _ShoppingCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: category.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(category.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Text(
            category.label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientTile extends StatelessWidget {
  const _IngredientTile({required this.item, required this.onToggle});

  final _ShoppingItem item;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Checkbox(
              value: item.checked,
              onChanged: (_) => onToggle(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  fontSize: 14,
                  decoration: item.checked
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  color: item.checked ? AppColors.textDisabled : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
