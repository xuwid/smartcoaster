import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smartcoaster/model/model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:smartcoaster/provider/provider.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  _DeviceScreenState createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(_controller)
      ..addListener(() {
        setState(() {});
      });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color getBarColor(int level) {
    if (level >= 75) {
      return Colors.green;
    } else if (level >= 50) {
      return Colors.blue;
    } else if (level >= 20) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<DrinkLevel> data =
        Provider.of<DeviceProvider>(context).currentDevice!.data;

    List<BarChartGroupData> barGroups = data.asMap().entries.map((entry) {
      int index = entry.key;
      DrinkLevel level = entry.value;
      return BarChartGroupData(
        x: index * 2,
        barRods: [
          BarChartRodData(
            toY: level.level.toDouble() * _animation.value,
            color: getBarColor(level.level),
            width: 20,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8), bottom: Radius.circular(8)),
          ),
        ],
      );
    }).toList();

    return Scaffold(
      body: Container(
        color: Colors.black,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AppBar(
            automaticallyImplyLeading: false,
            title: const Text('Stats',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.grey[875],
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Drink level for past time',
                  style: GoogleFonts.robotoMono(
                    fontSize: 16,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    height: 400,
                    width: data.length * 90.0,
                    child: BarChart(
                      BarChartData(
                        maxY: 110,
                        barGroups: barGroups,
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                // Show x-axis values below the graph
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    data[value.toInt() ~/ 2].time,
                                    style: GoogleFonts.robotoMono(
                                        color: Colors.white, fontSize: 11),
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(
                              // Hide x-axis values above the graph
                              showTitles: false,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                if (value == 20 ||
                                    value == 40 ||
                                    value == 60 ||
                                    value == 80 ||
                                    value == 100) {
                                  return Text(
                                    '${value.toInt()}%',
                                    style: GoogleFonts.robotoMono(
                                        color: Colors.white, fontSize: 12),
                                  );
                                }
                                return Container();
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawHorizontalLine: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) {
                            if (value == 10 ||
                                value == 30 ||
                                value == 50 ||
                                value == 70 ||
                                value == 90) {
                              return const FlLine(
                                color: Colors.transparent,
                                strokeWidth: 0,
                              );
                            }
                            return const FlLine(
                              color: Colors.white,
                              strokeWidth: 1,
                              dashArray: [4, 8],
                            );
                          },
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: const Border(
                            bottom: BorderSide(color: Colors.grey),
                            left: BorderSide(color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ]),
      ),
    );
  }
}
