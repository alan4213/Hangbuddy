import 'package:flutter/material.dart';
import '../widgets/my_hangouts_tab.dart';
import '../widgets/upcoming_hangouts_tab.dart';
import '../theme/app_theme.dart';
import '../services/hangout_service.dart';
import '../services/match_service.dart';
import 'package:google_fonts/google_fonts.dart';

class MatchesScreen extends StatefulWidget {
  final int initialTabIndex;
  
  const MatchesScreen({super.key, this.initialTabIndex = 0});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2, 
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Haule',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF8B5CF6),
              unselectedLabelColor: Colors.grey[500],
              indicatorColor: const Color(0xFF8B5CF6),
              indicatorWeight: 2,
              dividerColor: Colors.grey[200],
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: [
                StreamBuilder<List<dynamic>>(
                  stream: HangoutService.getUserHangouts(),
                  builder: (context, snapshot) {
                    final hangouts = snapshot.data ?? [];
                    final interestedCount = hangouts.fold<int>(0, (sum, hangout) => sum + (hangout.interestedUsers?.length ?? 0) as int);
                    return Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Created'),
                          if (interestedCount > 0) ...
                          [
                            SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF8B5CF6),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                interestedCount.toString(),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: MatchService.getUserMatches(),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.length ?? 0;
                    return Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Matched'),
                          if (count > 0) ...
                          [
                            SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF8B5CF6),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                count.toString(),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                MyHangoutsTab(),
                UpcomingHangoutsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}