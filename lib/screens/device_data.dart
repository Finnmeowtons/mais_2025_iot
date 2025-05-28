import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mais_2025_iot/screens/raw_data_table.dart';
import 'package:mais_2025_iot/services/api_service.dart';

class DeviceData extends StatefulWidget {
  final int deviceId;
  const DeviceData({super.key, required this.deviceId});

  @override
  State<DeviceData> createState() => _DeviceDataState();
}

class _DeviceDataState extends State<DeviceData> {
  bool isHour = true;
  int duration = 12;
  Map<String, List<FlSpot>> dataLines = {};
  List<String> timestamps = [];
  bool isLoading = true;
  final apiService = ApiService();

  final List<String> metrics = [
    'avg_soil_moisture_percentage',
    'avg_temperature',
    'avg_humidity',
    'avg_soil_temperature',
    'avg_soil_ph',
    'avg_nitrogen',
    'avg_phosphorus',
    'avg_potassium',
  ];

  List<bool> selectedMetrics = List.generate(8, (index) => index == 0);
  final List<Color> lineColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.brown,
    Colors.cyan,
    Colors.teal,
  ];

  void fetchAggregatedData(bool isHour, int duration, int deviceId) async {
    try {
      final data = await apiService.getAggregatedData(isHour, duration, deviceId);

      if (data.isEmpty) {
        setState(() {
          dataLines = {};
          timestamps = [];
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('No data available for the selected range.'),
        ));
        return;
      }

      Map<String, List<FlSpot>> loadedDataLines = {
        for (var metric in metrics) metric: []
      };
      List<String> loadedTimestamps = [];

      for (int i = 0; i < data.length; i++) {
        final point = data[i];
        double x = i.toDouble();

        for (var metric in metrics) {
          final value = point[metric];
          if (value != null) {
            loadedDataLines[metric]?.add(FlSpot(x, double.parse(value.toString())));
          } else {
            loadedDataLines[metric]?.add(FlSpot(x, 0));
          }
        }

        loadedTimestamps.add(formatTimestamp(point['window_start']));
      }

      setState(() {
        dataLines = loadedDataLines;
        timestamps = loadedTimestamps;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to load data.'),
      ));
      print("Error fetching data: $e");
    }
  }



  String formatTimestamp(String timestamp) {
    DateTime dt = DateTime.parse(timestamp);
    return "${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    fetchAggregatedData(isHour, duration, widget.deviceId);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.deviceId != 0 ? Text("Device ${widget.deviceId} Data") : Text("Devices Data"),
        actions: [
          if (widget.deviceId != 0)IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RawDataTable(deviceId: widget.deviceId,)),
              );
            },
            icon: Icon(Icons.table_chart_rounded),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ToggleButtons(
                isSelected: selectedMetrics,
                onPressed: (index) {
                  setState(() {
                    selectedMetrics[index] = !selectedMetrics[index];
                  });
                },
                borderRadius: BorderRadius.circular(20),
                selectedBorderColor: Colors.blueAccent,
                selectedColor: Colors.white,
                fillColor: Colors.blueAccent.withOpacity(0.6),
                color: Colors.black,
                borderColor: Colors.grey,
                constraints: BoxConstraints(minHeight: 40, minWidth: 80),
                children: metrics.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(e, style: TextStyle(fontSize: 11)),
                )).toList(),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Dropdown for Hourly or Daily
                Row(
                  children: [
                    Text("Interval: ", style: TextStyle(fontSize: 14)),
                    SizedBox(width: 8),
                    DropdownButton<bool>(
                      value: isHour,
                      items: [
                        DropdownMenuItem(value: true, child: Text("Hourly")),
                        DropdownMenuItem(value: false, child: Text("Daily")),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            isHour = value;
                            // Adjust default duration depending on mode
                            duration = isHour ? 12 : 7;
                            isLoading = true;
                          });
                          fetchAggregatedData(isHour, duration, widget.deviceId);
                        }
                      },
                    ),
                  ],
                ),
                // Duration Slider
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHour ? "Duration (hours)" : "Duration (days)",
                        style: TextStyle(fontSize: 14),
                      ),
                      Slider(
                        value: duration.toDouble(),
                        min: 1,
                        max: isHour ? 24 : 7,
                        divisions: isHour ? 23 : 6,
                        label: "$duration",
                        onChanged: (value) {
                          setState(() {
                            duration = value.toInt();
                          });
                        },
                        onChangeEnd: (value) {
                          setState(() {
                            isLoading = true;
                          });
                          fetchAggregatedData(isHour, duration, widget.deviceId);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Expanded(
              child: dataLines.isEmpty || timestamps.isEmpty
                  ? Center(child: Text("No data to display."))
                  : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  margin: EdgeInsets.only(top: 16),
                  width: timestamps.length * 50,
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: timestamps.length.toDouble() - 1,
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                "${value.toStringAsFixed(1)}%",
                                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w500),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              final int index = value.toInt();
                              if (index >= 0 && index < timestamps.length) {
                                return Text(
                                  timestamps[index],
                                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w400),
                                );
                              } else {
                                return const SizedBox.shrink();
                              }
                            },
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(show: true),
                      lineBarsData: [
                        for (int i = 0; i < metrics.length; i++)
                          if (selectedMetrics[i])
                            LineChartBarData(
                              spots: dataLines[metrics[i]]!,
                              isCurved: true,
                              color: lineColors[i],
                              barWidth: 2,
                              dotData: FlDotData(show: false),
                            )
                      ],
                      lineTouchData: LineTouchData(
                        handleBuiltInTouches: true,
                        touchTooltipData: LineTouchTooltipData(

                          tooltipRoundedRadius: 8,
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          showOnTopOfTheChartBoxArea: false, // <-- tooltips will go below line
                          tooltipMargin: 16,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((touchedSpot) {
                              final metric = metrics[touchedSpot.barIndex];
                              final value = touchedSpot.y.toStringAsFixed(2);
                              return LineTooltipItem(
                                '$metric\n$value',
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              );
                            }).toList();
                          },
                        ),
                      ),

                      extraLinesData: ExtraLinesData(horizontalLines: []),
                      borderData: FlBorderData(show: true),
                      clipData: FlClipData.all(),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (int i = 0; i < metrics.length; i++)
                  if (selectedMetrics[i])
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          color: lineColors[i],
                        ),
                        SizedBox(width: 4),
                        Text(metrics[i], style: TextStyle(fontSize: 10)),
                      ],
                    )
              ],
            )
          ],
        ),
      ),
    );
  }
}
