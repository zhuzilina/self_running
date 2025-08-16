import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/daily_steps.dart';
import '../states/providers.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyAsync = ref.watch(dailyStepsProvider);
    return dailyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败：$e')),
      data: (data) {
        if (data.isEmpty) {
          return const Center(child: Text('暂无数据，授权后下拉刷新获取步数'));
        }
        final recent = _takeLast(data, 30);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: (recent.length - 1).toDouble(),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(
                            recent.length,
                            (i) => FlSpot(
                              i.toDouble(),
                              recent[i].steps.toDouble(),
                            ),
                          ),
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: HeatMap(
                    startDate: data.first.localDay,
                    endDate: data.last.localDay,
                    datasets: {for (final d in data) d.localDay: d.steps},
                    colorMode: ColorMode.color,
                    colorsets: const {
                      2000: Color(0xFFE3F2FD),
                      5000: Color(0xFF90CAF9),
                      8000: Color(0xFF42A5F5),
                      12000: Color(0xFF1E88E5),
                      999999: Color(0xFF1565C0),
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<DailySteps> _takeLast(List<DailySteps> list, int n) {
    if (list.length <= n) return list;
    return list.sublist(list.length - n);
  }
}
