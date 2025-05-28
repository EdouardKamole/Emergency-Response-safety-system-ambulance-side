import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String selectedFilter = 'All';

  final List<Map<String, dynamic>> _historyData = [
    {
      "patient": "John Doe",
      "type": "Heart Attack",
      "location": "Osu, Accra",
      "date": "May 18, 2025",
      "time": "14:32",
      "duration": "24 min",
      "status": "Completed",
      "severity": "Critical",
      "outcome": "Stable",
      "distance": "2.1 km",
      "responseTime": "6 min",
      "icon": FontAwesomeIcons.heartPulse,
      "color": const Color(0xFFEF4444),
    },
    {
      "patient": "Jane Smith",
      "type": "Road Accident",
      "location": "East Legon",
      "date": "May 19, 2025",
      "time": "09:15",
      "duration": "31 min",
      "status": "Completed",
      "severity": "High",
      "outcome": "Transferred",
      "distance": "4.7 km",
      "responseTime": "8 min",
      "icon": FontAwesomeIcons.carBurst,
      "color": const Color(0xFFF59E0B),
    },
    {
      "patient": "Samuel Opoku",
      "type": "Seizure",
      "location": "Kanda",
      "date": "May 22, 2025",
      "time": "11:45",
      "duration": "18 min",
      "status": "Completed",
      "severity": "Medium",
      "outcome": "Stable",
      "distance": "1.8 km",
      "responseTime": "5 min",
      "icon": FontAwesomeIcons.brain,
      "color": const Color(0xFF8B5CF6),
    },
    {
      "patient": "Mary Johnson",
      "type": "Breathing Issue",
      "location": "Adabraka",
      "date": "May 23, 2025",
      "time": "16:20",
      "duration": "22 min",
      "status": "Completed",
      "severity": "High",
      "outcome": "Stable",
      "distance": "3.2 km",
      "responseTime": "7 min",
      "icon": FontAwesomeIcons.lungs,
      "color": const Color(0xFF06B6D4),
    },
    {
      "patient": "David Wilson",
      "type": "Fall Injury",
      "location": "Tema",
      "date": "May 24, 2025",
      "time": "13:10",
      "duration": "35 min",
      "status": "Completed",
      "severity": "Medium",
      "outcome": "Transferred",
      "distance": "6.1 km",
      "responseTime": "12 min",
      "icon": FontAwesomeIcons.personFalling,
      "color": const Color(0xFF10B981),
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredData {
    if (selectedFilter == 'All') return _historyData;
    return _historyData
        .where((item) => item['severity'] == selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Emergency History",
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1A1D29),
        shadowColor: Colors.black.withOpacity(0.1),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.chartLine, size: 18),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(FontAwesomeIcons.download, size: 18),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4F46E5),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF4F46E5),
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          tabs: const [Tab(text: "History"), Tab(text: "Analytics")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildHistoryTab(), _buildAnalyticsTab()],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Column(
      children: [
        // Statistics Overview
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F46E5).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  "Total Calls",
                  "${_historyData.length}",
                  FontAwesomeIcons.phone,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  "Avg Response",
                  "7.6 min",
                  FontAwesomeIcons.clock,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  "Success Rate",
                  "96%",
                  FontAwesomeIcons.chartLine,
                ),
              ),
            ],
          ),
        ),

        // Filter Pills
        Container(
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children:
                ['All', 'Critical', 'High', 'Medium'].map((filter) {
                  final isSelected = selectedFilter == filter;
                  return GestureDetector(
                    onTap: () => setState(() => selectedFilter = filter),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? const Color(0xFF4F46E5) : Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color:
                              isSelected
                                  ? const Color(0xFF4F46E5)
                                  : const Color(0xFFE2E8F0),
                        ),
                        boxShadow:
                            isSelected
                                ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF4F46E5,
                                    ).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                                : [],
                      ),
                      child: Text(
                        filter,
                        style: GoogleFonts.inter(
                          color:
                              isSelected
                                  ? Colors.white
                                  : const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // History List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredData.length,
            itemBuilder:
                (context, index) =>
                    _buildPremiumHistoryCard(filteredData[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance Metrics
          Text(
            "Performance Overview",
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1D29),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  "Avg Response Time",
                  "7.6 min",
                  "↓ 12%",
                  const Color(0xFF10B981),
                  FontAwesomeIcons.clock,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  "Total Distance",
                  "18.9 km",
                  "↑ 8%",
                  const Color(0xFF4F46E5),
                  FontAwesomeIcons.route,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  "Calls This Week",
                  "5",
                  "↑ 25%",
                  const Color(0xFFF59E0B),
                  FontAwesomeIcons.phone,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  "Patient Satisfaction",
                  "4.8/5",
                  "→ 0%",
                  const Color(0xFF8B5CF6),
                  FontAwesomeIcons.star,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Emergency Types Distribution
          Text(
            "Emergency Types",
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1D29),
            ),
          ),
          const SizedBox(height: 16),

          _buildEmergencyTypeChart(),

          const SizedBox(height: 32),

          // Recent Trends
          Text(
            "Weekly Trends",
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1D29),
            ),
          ),
          const SizedBox(height: 16),

          _buildTrendsChart(),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumHistoryCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (data['color'] as Color).withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (data['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    data['icon'] as IconData,
                    color: data['color'] as Color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['type'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1D29),
                        ),
                      ),
                      Text(
                        data['patient'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        data['severity'] == 'Critical'
                            ? const Color(0xFFEF4444)
                            : data['severity'] == 'High'
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    data['severity'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Details Grid
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    FontAwesomeIcons.locationDot,
                    "Location",
                    data['location'] as String,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    FontAwesomeIcons.calendar,
                    "Date",
                    "${data['date']} ${data['time']}",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    FontAwesomeIcons.clock,
                    "Duration",
                    data['duration'] as String,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    FontAwesomeIcons.route,
                    "Distance",
                    data['distance'] as String,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Status Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          FontAwesomeIcons.checkCircle,
                          color: Color(0xFF10B981),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          data['outcome'] as String,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Response: ${data['responseTime']}",
                    style: GoogleFonts.inter(
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF1A1D29),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String change,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
              Text(
                change,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:
                      change.startsWith('↑')
                          ? const Color(0xFF10B981)
                          : change.startsWith('↓')
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1D29),
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyTypeChart() {
    final types = [
      'Heart Attack',
      'Road Accident',
      'Seizure',
      'Breathing',
      'Fall',
    ];
    final colors = [
      const Color(0xFFEF4444),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFF06B6D4),
      const Color(0xFF10B981),
    ];
    final percentages = [25, 30, 15, 20, 10];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(types.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors[index],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    types[index],
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ),
                Text(
                  '${percentages[index]}%',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTrendsChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Calls per Day',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              Text(
                'This Week',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar('Mon', 2, 60),
                _buildBar('Tue', 1, 30),
                _buildBar('Wed', 3, 90),
                _buildBar('Thu', 2, 60),
                _buildBar('Fri', 1, 30),
                _buildBar('Sat', 0, 0),
                _buildBar('Sun', 1, 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String day, int calls, double height) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (calls > 0)
          Text(
            calls.toString(),
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        const SizedBox(height: 4),
        Container(
          width: 24,
          height: height,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
