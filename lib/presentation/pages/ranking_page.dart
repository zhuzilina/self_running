import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/daily_steps.dart';
import '../states/providers.dart';

class RankingPage extends ConsumerWidget {
  const RankingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyAsync = ref.watch(dailyStepsProvider);
    final range = ref.watch(selectedRangeDaysProvider);
    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [7, 30, 90, 365]
              .map(
                (d) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text('$d天'),
                    selected: range == d,
                    onSelected: (_) =>
                        ref.read(selectedRangeDaysProvider.notifier).state = d,
                  ),
                ),
              )
              .toList(),
        ),
        const Divider(height: 1),
        Expanded(
          child: dailyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('加载失败：$e')),
            data: (data) {
              final filtered = _filterRange(data, range);
              final today = filtered.isNotEmpty ? filtered.last : null;
              final sorted = [...filtered]..sort((b, a) => a.steps - b.steps);
              return ListView.separated(
                itemCount: sorted.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final d = sorted[index];
                  final isToday = today != null && d.localDay == today.localDay;
                  return ListTile(
                    leading: Text('${index + 1}'),
                    title: Text('${d.steps} 步'),
                    subtitle: Text(
                      '${d.localDay.year}-${d.localDay.month}-${d.localDay.day}',
                    ),
                    tileColor: isToday
                        ? Colors.blue.withValues(alpha: 0.08)
                        : null,
                    trailing: isToday
                        ? const Text('今天', style: TextStyle(color: Colors.blue))
                        : null,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  List<DailySteps> _filterRange(List<DailySteps> input, int days) {
    if (input.isEmpty) return input;
    final end = input.last.localDay;
    final start = end.subtract(Duration(days: days - 1));
    return input.where((e) => !e.localDay.isBefore(start)).toList();
  }
}
