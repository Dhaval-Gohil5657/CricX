import 'package:flutter/material.dart';
import 'teams_screen.dart';
import 'players_screen.dart';
import '../constants/app_colors.dart';

class DirectoryScreen extends StatelessWidget {
  final GlobalKey? directoryTabsKey;

  const DirectoryScreen({
    super.key,
    this.directoryTabsKey,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.transparent,
            height: 38,
            child: TabBar(
              key: directoryTabsKey,
              indicatorColor: AppColors.primaryTurf,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              indicatorPadding: EdgeInsets.only(bottom: 4),
              labelColor: AppColors.primaryTurf,
              unselectedLabelColor: AppColors.textDarkMuted,
              dividerColor: Colors.transparent,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              tabs: [
                Tab(text: 'TEAMS'),
                Tab(text: 'PLAYERS'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                TeamsScreen(),
                PlayersScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
