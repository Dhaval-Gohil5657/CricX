import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../models/tournament_model.dart';
import '../../models/match_model.dart';
import '../../models/team_model.dart';
import '../../constants/app_colors.dart';
import '../main_navigation_screen.dart';

class FixtureDraftScreen extends StatefulWidget {
  final Tournament tournament;
  final List<CricketMatch> matches;

  const FixtureDraftScreen({
    super.key,
    required this.tournament,
    required this.matches,
  });

  @override
  State<FixtureDraftScreen> createState() => _FixtureDraftScreenState();
}

class _FixtureDraftScreenState extends State<FixtureDraftScreen> {
  late List<DateTime> _matchDates;
  late List<TextEditingController> _venueControllers;

  @override
  void initState() {
    super.initState();
    final start = widget.tournament.startDate;
    _matchDates = List.generate(widget.matches.length, (index) {
      final match = widget.matches[index];
      if (match.id.contains('_sf') || match.id.contains('_final')) {
        final pDate = match.matchDate;
        return DateTime(pDate.year, pDate.month, pDate.day, 18, 0);
      }
      final date = start.add(Duration(days: index));
      return DateTime(date.year, date.month, date.day, 18, 0);
    });

    _venueControllers = List.generate(widget.matches.length, (index) {
      final match = widget.matches[index];
      if (match.id.contains('_sf') || match.id.contains('_final')) {
        return TextEditingController(text: match.venue);
      }
      final defaultVenue = widget.tournament.venue.isNotEmpty
          ? widget.tournament.venue
          : 'Venue #${index + 1}';
      return TextEditingController(text: defaultVenue);
    });
  }

  String _getMatchHeader(int index, CricketMatch match) {
    if (match.id.contains('_sf1')) return 'SEMI-FINAL 1';
    if (match.id.contains('_sf2')) return 'SEMI-FINAL 2';
    if (match.id.contains('_final')) return 'FINAL';
    return 'MATCH ${index + 1}';
  }

  String get _screenTitle {
    if (widget.matches.any((m) => m.id.contains('_sf'))) {
      return 'Confirm Playoff Fixtures';
    } else if (widget.matches.any((m) => m.id.contains('_final'))) {
      return 'Confirm Final Fixture';
    } else {
      return 'Confirm League Fixtures';
    }
  }

  @override
  void dispose() {
    for (var controller in _venueControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(DateTime date) {
    final int hour = date.hour;
    final int minute = date.minute;
    final String amPm = hour >= 12 ? 'PM' : 'AM';
    final int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $amPm';
  }

  Future<void> _selectDate(BuildContext context, int index) async {
    final DateTime initialDate = _matchDates[index];
    final DateTime tStart = widget.tournament.startDate;
    final DateTime firstPossibleDate = DateTime(tStart.year, tStart.month, tStart.day);
    
    // Safety check: if initialDate is before firstPossibleDate, use firstPossibleDate
    final DateTime pickerInitialDate = initialDate.isBefore(firstPossibleDate) ? firstPossibleDate : initialDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: pickerInitialDate,
      firstDate: firstPossibleDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryTurf,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _matchDates[index] = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _matchDates[index].hour,
          _matchDates[index].minute,
        );
      });
    }
  }

  Future<void> _selectTime(BuildContext context, int index) async {
    final DateTime initialDate = _matchDates[index];
    final TimeOfDay initialTime = TimeOfDay(hour: initialDate.hour, minute: initialDate.minute);
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryTurf,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _matchDates[index] = DateTime(
          initialDate.year,
          initialDate.month,
          initialDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _confirmAndPublish() {
    final appState = Provider.of<AppState>(context, listen: false);

    // 1. Assign selected dates and venues to matches
    final List<CricketMatch> updatedMatches = [];
    for (int i = 0; i < widget.matches.length; i++) {
      final match = widget.matches[i];
      match.matchDate = _matchDates[i];
      match.venue = _venueControllers[i].text.trim().isNotEmpty
          ? _venueControllers[i].text.trim()
          : (widget.tournament.venue.isNotEmpty
              ? widget.tournament.venue
              : 'Venue #${i + 1}');
      updatedMatches.add(match);
    }

    // 2. Sort matches chronologically by matchDate
    updatedMatches.sort((a, b) => a.matchDate.compareTo(b.matchDate));

    // 3. Re-assign final chronological match IDs and keep their custom venues
    final List<CricketMatch> finalizedMatches = [];
    int matchIdCounter = 1;
    for (var match in updatedMatches) {
      String finalId = match.id;
      if (match.id.contains('_league_')) {
        finalId = 'tour_m_${widget.tournament.id}_league_${matchIdCounter}';
        matchIdCounter++;
      }
      finalizedMatches.add(
        CricketMatch(
          id: finalId,
          teamA: match.teamA,
          teamB: match.teamB,
          totalOvers: match.totalOvers,
          venue: match.venue,
          matchDate: match.matchDate,
          tournamentId: match.tournamentId,
          tournamentName: match.tournamentName,
        ),
      );
    }

    // 4. Save to DB
    appState.addTournamentMatches(widget.tournament.id, finalizedMatches);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully confirmed ${finalizedMatches.length} fixtures!'),
        backgroundColor: AppColors.accentCrease,
      ),
    );

    // Pop draft screen and return
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
          flexibleSpace: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
            child: SizedBox.expand(
              child: CustomPaint(
                painter: PitchCreasePainter(
                  groundColorLight: const Color(0xFF2E6B3E),
                  groundColorDark: const Color(0xFF1F4D28),
                ),
              ),
            ),
          ),
          title: Text(
            _screenTitle,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
      body: Column(
        children: [
          // Informational Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.primaryTurf.withOpacity(0.08),
            child: const Row(
              children: [
                Icon(Icons.edit_calendar_rounded, color: AppColors.primaryTurf, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Preview generated fixtures. Customize dates and times for each match before publishing.',
                    style: TextStyle(
                      color: AppColors.textDarkSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Match List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.matches.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final match = widget.matches[index];
                final date = _matchDates[index];
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderGreen),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Match Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getMatchHeader(index, match),
                              style: const TextStyle(
                                color: AppColors.primaryTurf,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: AppColors.dividerGreen, height: 16),
                        
                        // Teams
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Team A
                            Expanded(
                              child: Column(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: Color(match.teamA.logoColorHex).withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(match.teamA.logoEmoji, style: const TextStyle(fontSize: 18)),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    match.teamA.name,
                                    style: const TextStyle(
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            
                            const Text(
                              'VS',
                              style: TextStyle(
                                color: AppColors.woodMahogany,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            
                            // Team B
                            Expanded(
                              child: Column(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: Color(match.teamB.logoColorHex).withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(match.teamB.logoEmoji, style: const TextStyle(fontSize: 18)),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    match.teamB.name,
                                    style: const TextStyle(
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Selectors (Date & Time)
                        Row(
                          children: [
                            // Date Selector Button
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectDate(context, index),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    border: Border.all(color: AppColors.borderGreen),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.primaryTurf),
                                      const SizedBox(width: 6),
                                      Text(
                                        _formatDate(date),
                                        style: const TextStyle(
                                          color: AppColors.textDark,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Time Selector Button
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectTime(context, index),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    border: Border.all(color: AppColors.borderGreen),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.access_time_rounded, size: 16, color: AppColors.primaryTurf),
                                      const SizedBox(width: 6),
                                      Text(
                                        _formatTime(date),
                                        style: const TextStyle(
                                          color: AppColors.textDark,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Match Venue Input Field
                        TextField(
                          controller: _venueControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Match Venue',
                            labelStyle: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 11),
                            hintText: 'Enter venue name',
                            prefixIcon: const Icon(Icons.location_on_rounded, size: 16, color: AppColors.primaryTurf),
                            filled: true,
                            fillColor: AppColors.background,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.borderGreen),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.accentCrease),
                            ),
                          ),
                          style: const TextStyle(color: AppColors.textDark, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Confirm Button Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              border: const Border(top: BorderSide(color: AppColors.borderGreen, width: 1)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTurf,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                ),
                onPressed: _confirmAndPublish,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: const Text(
                  'CONFIRM & PUBLISH FIXTURES',
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
