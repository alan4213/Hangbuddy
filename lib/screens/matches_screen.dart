import 'package:flutter/material.dart';
import '../widgets/my_hangouts_tab.dart';
import '../widgets/upcoming_hangouts_tab.dart';
import '../theme/app_theme.dart';

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
              tabs: const [
                Tab(text: 'My Hangouts'),
                Tab(text: 'Upcoming Hangouts'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
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