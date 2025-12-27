import 'package:flutter/material.dart';
import '../widgets/my_hangouts_tab.dart';
import '../widgets/upcoming_hangouts_tab.dart';
import '../theme/app_theme.dart';
import '../widgets/tutorial_overlay.dart';
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
  
  // Tutorial keys
  final GlobalKey _createdTabKey = GlobalKey();
  final GlobalKey _matchedTabKey = GlobalKey();
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2, 
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _checkAndShowTutorial();
  }
  
  void _checkAndShowTutorial() async {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showTutorial = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchesContent = Scaffold(
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
                      key: _createdTabKey,
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
                      key: _matchedTabKey,
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
    
    if (_showTutorial) {
      return TutorialOverlay(
        steps: [
          TutorialStep(
            title: 'Your Hangouts Hub',
            description: 'This is where you manage all your hangout activities - both created and matched.',
            bubblePosition: const Offset(20, 150),
          ),
          TutorialStep(
            title: 'Created Hangouts',
            description: 'View hangouts you\'ve created and manage people who want to join you.',
            targetKey: _createdTabKey,
            bubblePosition: const Offset(20, 200),
          ),
          TutorialStep(
            title: 'Matched Hangouts',
            description: 'See hangouts you\'ve been accepted to join and chat with your matches.',
            targetKey: _matchedTabKey,
            bubblePosition: const Offset(20, 200),
          ),
        ],
        onComplete: () {
          setState(() {
            _showTutorial = false;
          });
          TutorialService.markTutorialCompleted('matches_screen');
        },
        child: matchesContent,
      );
    }
    
    return matchesContent;
  }

}