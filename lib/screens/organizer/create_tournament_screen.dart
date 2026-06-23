import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../models/tournament_model.dart';
import '../../models/team_model.dart';
import '../../constants/app_colors.dart';
import '../main_navigation_screen.dart';

class CreateTournamentScreen extends StatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  String _selectedType = 'League'; // 'League' or 'Knockout'
  final List<Team> _selectedTeams = [];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final teams = appState.teams;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
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
          title: const Text('Create Tournament', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('TOURNAMENT CONFIG', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              const SizedBox(height: 16),
              
              // Name
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                decoration: _buildInputDecoration('Tournament Name (e.g. CricX Cup 2026)'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter tournament name' : null,
              ),
              const SizedBox(height: 16),

              // Type Selector
              const Text('Tournament Type', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buildSelectionTile(
                      label: '🏆 League Format',
                      isSelected: _selectedType == 'League',
                      onTap: () => setState(() => _selectedType = 'League'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSelectionTile(
                      label: '⚔️ Knockout Format',
                      isSelected: _selectedType == 'Knockout',
                      onTap: () => setState(() => _selectedType = 'Knockout'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Multi-select Teams
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('PARTICIPATING TEAMS', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  Text('${_selectedTeams.length} Selected', style: const TextStyle(color: AppColors.accentCrease, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              
              if (teams.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderGreen),
                  ),
                  child: const Center(
                    child: Text('No teams available. Create teams first!', style: TextStyle(color: AppColors.textDarkMuted, fontSize: 13)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: teams.length,
                  itemBuilder: (context, index) {
                    final team = teams[index];
                    final isChecked = _selectedTeams.any((t) => t.id == team.id);

                    return Card(
                      color: AppColors.cardBg,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: isChecked ? AppColors.accentCrease : AppColors.borderGreen),
                      ),
                      child: CheckboxListTile(
                        value: isChecked,
                        activeColor: AppColors.accentCrease,
                        checkColor: Colors.black,
                        title: Text(team.name, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text('Squad Size: ${team.players.length}', style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 11)),
                        secondary: Text(team.logoEmoji, style: const TextStyle(fontSize: 20)),
                        onChanged: (bool? checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedTeams.add(team);
                            } else {
                              _selectedTeams.removeWhere((t) => t.id == team.id);
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
              const SizedBox(height: 36),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTurf,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saveTournament,
                  child: const Text('CREATE TOURNAMENT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionTile({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTurf.withOpacity(0.12) : AppColors.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primaryTurf : AppColors.borderGreen,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primaryTurf : AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
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
    );
  }

  void _saveTournament() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTeams.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 2 teams to register')),
      );
      return;
    }

    final id = 'tour_new_${DateTime.now().millisecondsSinceEpoch}';
    final newTour = Tournament(
      id: id,
      name: _nameController.text.trim(),
      type: _selectedType,
      teams: List.from(_selectedTeams),
      matches: [],
      status: 'Ongoing',
    );

    newTour.updatePointsTable();

    final appState = Provider.of<AppState>(context, listen: false);
    appState.createTournament(newTour);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tournament "${newTour.name}" launched successfully!')),
    );
    Navigator.pop(context);
  }
}
