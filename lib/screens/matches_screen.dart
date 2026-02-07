import 'package:flutter/material.dart';
import '../widgets/my_hangouts_tab.dart';
import '../widgets/upcoming_hangouts_tab.dart';
import '../theme/app_theme.dart';
import '../services/hangout_service.dart';
import '../services/match_service.dart';

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
      body: Column(
        children: [
          SizedBox(height: (MediaQuery.of(context).size.height * 0.07).clamp(20.0, 50.0)),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.primaryColor,
              indicatorWeight: 3,
              labelStyle: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: (MediaQuery.of(context).size.width * 0.04).clamp(14.0, 18.0),
              ),
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: (MediaQuery.of(context).size.width * 0.04).clamp(14.0, 18.0),
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
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                interestedCount.toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
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
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                count.toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
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