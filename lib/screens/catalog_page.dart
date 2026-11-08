import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_providers.dart';

/// Catalog tab: list of categories. Tap a category to view its products.
class CatalogPage extends ConsumerWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriesProvider);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: cats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('خطا در بارگذاری دسته‌بندی‌ها'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(categoriesProvider),
                child: const Text('تلاش مجدد'),
              ),
            ],
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('دسته‌بندی‌ای یافت نشد'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final c = list[i];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: c.image.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: c.image,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                const Icon(Icons.category_outlined),
                          ),
                        )
                      : const Icon(Icons.category_outlined),
                  title: Text(c.name),
                  subtitle: c.count > 0 ? Text('${c.count} محصول') : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(
                    '/category/${c.id}',
                    extra: c.name,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
