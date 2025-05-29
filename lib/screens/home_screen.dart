import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool isOnline = false;
  late AnimationController _pulseController;
  late AnimationController _statusController;
  late AnimationController _heartbeatController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _statusAnimation;
  late Animation<double> _heartbeatAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation for online indicator
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Status transition animation
    _statusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _statusAnimation = CurvedAnimation(
      parent: _statusController,
      curve: Curves.elasticOut,
    );

    // Heartbeat animation for emergency indicator
    _heartbeatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
    _heartbeatAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _heartbeatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _statusController.dispose();
    _heartbeatController.dispose();
    super.dispose();
  }

  void toggleOnline() {
    setState(() {
      isOnline = !isOnline;
    });
    if (isOnline) {
      _statusController.forward();
    } else {
      _statusController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final padding = isSmallScreen ? 16.0 : 20.0;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
            stops: const [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    screenHeight -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                children: [
                  // Premium Header Section
                  Container(
                    margin: EdgeInsets.all(padding),
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        isSmallScreen ? 16 : 24,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Status Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Emergency Response",
                                    style: GoogleFonts.inter(
                                      fontSize: isSmallScreen ? 14 : 16,
                                      color: const Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      AnimatedBuilder(
                                        animation: _pulseAnimation,
                                        builder: (context, child) {
                                          return Transform.scale(
                                            scale:
                                                isOnline
                                                    ? _pulseAnimation.value
                                                    : 1.0,
                                            child: Container(
                                              width: isSmallScreen ? 10 : 12,
                                              height: isSmallScreen ? 10 : 12,
                                              decoration: BoxDecoration(
                                                color:
                                                    isOnline
                                                        ? const Color(
                                                          0xFF10B981,
                                                        )
                                                        : const Color(
                                                          0xFFEF4444,
                                                        ),
                                                shape: BoxShape.circle,
                                                boxShadow:
                                                    isOnline
                                                        ? [
                                                          BoxShadow(
                                                            color: const Color(
                                                              0xFF10B981,
                                                            ).withOpacity(0.4),
                                                            blurRadius: 8,
                                                            spreadRadius: 2,
                                                          ),
                                                        ]
                                                        : [],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          isOnline
                                              ? "ONLINE & READY"
                                              : "OFFLINE",
                                          style: GoogleFonts.inter(
                                            fontSize: isSmallScreen ? 14 : 18,
                                            fontWeight: FontWeight.w700,
                                            color:
                                                isOnline
                                                    ? const Color(0xFF10B981)
                                                    : const Color(0xFFEF4444),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Profile Avatar
                            Container(
                              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF4F46E5),
                                    Color(0xFF7C3AED),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(
                                  isSmallScreen ? 12 : 16,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF4F46E5,
                                    ).withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                FontAwesomeIcons.userDoctor,
                                color: Colors.white,
                                size: isSmallScreen ? 16 : 20,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 24),

                        // Toggle Button
                        GestureDetector(
                          onTap: toggleOnline,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 20 : 24,
                              vertical: isSmallScreen ? 12 : 16,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors:
                                    isOnline
                                        ? [
                                          const Color(0xFF10B981),
                                          const Color(0xFF059669),
                                        ]
                                        : [
                                          const Color(0xFFEF4444),
                                          const Color(0xFFDC2626),
                                        ],
                              ),
                              borderRadius: BorderRadius.circular(
                                isSmallScreen ? 16 : 20,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isOnline
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444))
                                      .withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Icon(
                                    isOnline
                                        ? FontAwesomeIcons.powerOff
                                        : FontAwesomeIcons.play,
                                    key: ValueKey(isOnline),
                                    color: Colors.white,
                                    size: isSmallScreen ? 14 : 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  isOnline ? "Go Offline" : "Go Online",
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: isSmallScreen ? 14 : 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Statistics Cards Row
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: padding),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final cardSpacing = isSmallScreen ? 8.0 : 12.0;
                        final availableWidth =
                            constraints.maxWidth - (cardSpacing * 2);
                        final cardWidth = availableWidth / 3;

                        return IntrinsicHeight(
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  "Shift Time",
                                  "3h 24m",
                                  FontAwesomeIcons.clock,
                                  const Color(0xFF4F46E5),
                                  isSmallScreen,
                                ),
                              ),
                              SizedBox(width: cardSpacing),
                              Expanded(
                                child: _buildStatCard(
                                  "Location",
                                  "Accra, GH",
                                  FontAwesomeIcons.locationDot,
                                  const Color(0xFF10B981),
                                  isSmallScreen,
                                ),
                              ),
                              SizedBox(width: cardSpacing),
                              Expanded(
                                child: _buildStatCard(
                                  "Calls Today",
                                  "7",
                                  FontAwesomeIcons.phone,
                                  const Color(0xFFF59E0B),
                                  isSmallScreen,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 20 : 32),

                  // Emergency Alerts Section
                  Container(
                    constraints: BoxConstraints(
                      minHeight:
                          screenHeight *
                          0.4, // Minimum height for emergency section
                    ),
                    margin: EdgeInsets.symmetric(horizontal: padding),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isSmallScreen ? 20 : 32),
                        topRight: Radius.circular(isSmallScreen ? 20 : 32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 30,
                          offset: const Offset(0, -10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Section Header
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                          child: Row(
                            children: [
                              AnimatedBuilder(
                                animation: _heartbeatAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _heartbeatAnimation.value,
                                    child: Container(
                                      padding: EdgeInsets.all(
                                        isSmallScreen ? 8 : 12,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFEF4444),
                                            Color(0xFFDC2626),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          isSmallScreen ? 12 : 16,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFFEF4444,
                                            ).withOpacity(0.4),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        FontAwesomeIcons.heartPulse,
                                        color: Colors.white,
                                        size: isSmallScreen ? 16 : 20,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Emergency Alerts",
                                      style: GoogleFonts.inter(
                                        fontSize: isSmallScreen ? 16 : 20,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1A1D29),
                                      ),
                                    ),
                                    Text(
                                      "Real-time emergency responses",
                                      style: GoogleFonts.inter(
                                        fontSize: isSmallScreen ? 12 : 14,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 8 : 12,
                                  vertical: isSmallScreen ? 4 : 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFEF4444,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "2 Active",
                                  style: GoogleFonts.inter(
                                    fontSize: isSmallScreen ? 10 : 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFEF4444),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Emergency Cards List
                        Flexible(
                          child:
                              isOnline
                                  ? ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 16 : 24,
                                    ),
                                    itemCount: 3,
                                    itemBuilder:
                                        (context, index) =>
                                            _buildPremiumEmergencyCard(
                                              index,
                                              isSmallScreen,
                                            ),
                                  )
                                  : _buildOfflineState(isSmallScreen),
                        ),
                      ],
                    ),
                  ),

                  // Bottom spacing
                  SizedBox(height: padding),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isSmallScreen,
  ) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
            ),
            child: Icon(icon, color: color, size: isSmallScreen ? 14 : 18),
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: isSmallScreen ? 14 : 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1D29),
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: isSmallScreen ? 10 : 12,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumEmergencyCard(int index, bool isSmallScreen) {
    final emergencies = [
      {
        'type': 'Car Accident',
        'severity': 'CRITICAL',
        'time': '2 min ago',
        'location': 'Osu Oxford St',
        'distance': '1.2 km',
        'color': const Color(0xFFEF4444),
      },
      {
        'type': 'Heart Attack',
        'severity': 'HIGH',
        'time': '5 min ago',
        'location': 'Adabraka Market',
        'distance': '2.8 km',
        'color': const Color(0xFFF59E0B),
      },
      {
        'type': 'Breathing Issue',
        'severity': 'MEDIUM',
        'time': '8 min ago',
        'location': 'East Legon',
        'distance': '4.1 km',
        'color': const Color(0xFF10B981),
      },
    ];

    final emergency = emergencies[index];

    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            (emergency['color'] as Color).withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        border: Border.all(
          color: (emergency['color'] as Color).withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (emergency['color'] as Color).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 6 : 8,
                    vertical: isSmallScreen ? 3 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: emergency['color'] as Color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    emergency['severity'] as String,
                    style: GoogleFonts.inter(
                      fontSize: isSmallScreen ? 8 : 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  emergency['time'] as String,
                  style: GoogleFonts.inter(
                    fontSize: isSmallScreen ? 10 : 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            Text(
              emergency['type'] as String,
              style: GoogleFonts.inter(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1D29),
              ),
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            Row(
              children: [
                Icon(
                  FontAwesomeIcons.locationDot,
                  size: isSmallScreen ? 12 : 14,
                  color: emergency['color'] as Color,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    emergency['location'] as String,
                    style: GoogleFonts.inter(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: const Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 6 : 8,
                    vertical: isSmallScreen ? 3 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: (emergency['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    emergency['distance'] as String,
                    style: GoogleFonts.inter(
                      fontSize: isSmallScreen ? 10 : 12,
                      fontWeight: FontWeight.w600,
                      color: emergency['color'] as Color,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: isSmallScreen ? 40 : 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          emergency['color'] as Color,
                          (emergency['color'] as Color).withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton.icon(
                      icon: Icon(
                        FontAwesomeIcons.check,
                        size: isSmallScreen ? 14 : 16,
                      ),
                      label: Text(
                        "Accept",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                      ),
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: isSmallScreen ? 40 : 44,
                  width: isSmallScreen ? 40 : 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      FontAwesomeIcons.ellipsisVertical,
                      size: isSmallScreen ? 14 : 16,
                    ),
                    color: const Color(0xFF64748B),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineState(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 24 : 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 24),
            ),
            child: Icon(
              FontAwesomeIcons.powerOff,
              size: isSmallScreen ? 32 : 48,
              color: const Color(0xFF64748B),
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 24),
          Text(
            "You're Currently Offline",
            style: GoogleFonts.inter(
              fontSize: isSmallScreen ? 16 : 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1D29),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Text(
            "Go online to start receiving emergency calls",
            style: GoogleFonts.inter(
              fontSize: isSmallScreen ? 12 : 14,
              color: const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
