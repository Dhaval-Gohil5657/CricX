import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../models/match_model.dart';
import '../../models/team_model.dart';
import '../../constants/app_colors.dart';

class CreateMatchScreen extends StatefulWidget {
  const CreateMatchScreen({super.key});

  @override
  State<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _venueController = TextEditingController();
  
  Team? _teamA;
  Team? _teamB;
  int _selectedOvers = 10;
  
  final List<int> _overOptions = [5, 8, 10, 12, 15, 20];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final teams = appState.teams;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.appBarBg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Schedule New Match', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('MATCH DETAILS', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              const SizedBox(height: 16),
              
              // Team A Dropdown
              const Text('Team A (Home)', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderGreen),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Team>(
                    value: _teamA,
                    hint: const Text('Select Team A', style: TextStyle(color: AppColors.textDarkMuted, fontSize: 13)),
                    isExpanded: true,
                    dropdownColor: AppColors.appBarBg,
                    icon: const Icon(Icons.arrow_drop_down, color: AppColors.accentCrease),
                    style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                    onChanged: (Team? val) {
                      setState(() {
                        _teamA = val;
                        if (_teamB == val) _teamB = null; // Prevent selecting the same team
                      });
                    },
                    items: teams.map((team) {
                      return DropdownMenuItem(
                        value: team,
                        child: Row(
                          children: [
                            Text(team.logoEmoji, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(team.name),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Team B Dropdown
              const Text('Team B (Away)', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderGreen),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Team>(
                    value: _teamB,
                    hint: const Text('Select Team B', style: TextStyle(color: AppColors.textDarkMuted, fontSize: 13)),
                    isExpanded: true,
                    dropdownColor: AppColors.appBarBg,
                    icon: const Icon(Icons.arrow_drop_down, color: AppColors.accentCrease),
                    style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                    onChanged: (Team? val) {
                      setState(() {
                        _teamB = val;
                      });
                    },
                    items: teams.where((t) => t.id != _teamA?.id).map((team) {
                      return DropdownMenuItem(
                        value: team,
                        child: Row(
                          children: [
                            Text(team.logoEmoji, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(team.name),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Overs Selection (Dropdown)
              const Text('NUMBER OF OVERS', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _overOptions.length,
                  itemBuilder: (context, index) {
                    final over = _overOptions[index];
                    final isSelected = _selectedOvers == over;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedOvers = over),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accentCrease.withOpacity(0.2) : AppColors.cardBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? AppColors.accentCrease : AppColors.borderGreen,
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$over Overs',
                          style: TextStyle(
                            color: isSelected ? AppColors.accentCrease : AppColors.textDarkSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Venue
              const Text('VENUE / GROUND NAME', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _venueController,
                style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. Wankhede Cricket Turf',
                  hintStyle: const TextStyle(color: AppColors.textDarkMuted, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.cardBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.borderGreen),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.accentCrease),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.redAccent),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.redAccent),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter venue' : null,
              ),
              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentCrease,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _createMatch,
                  child: const Text('SCHEDULE MATCH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createMatch() {
    if (!_formKey.currentState!.validate()) return;
    
    if (_teamA == null || _teamB == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both teams')),
      );
      return;
    }

    final id = 'm_new_${DateTime.now().millisecondsSinceEpoch}';
    final newMatch = CricketMatch(
      id: id,
      teamA: _teamA!,
      teamB: _teamB!,
      totalOvers: _selectedOvers,
      venue: _venueController.text.trim(),
      matchDate: DateTime.now(),
    );

    Provider.of<AppState>(context, listen: false).createMatch(newMatch);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Match scheduled between ${_teamA!.name} and ${_teamB!.name}!')),
    );
    Navigator.pop(context);
  }
}
