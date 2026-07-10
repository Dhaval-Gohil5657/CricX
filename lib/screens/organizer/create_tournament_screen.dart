import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cricx/services/auth_service.dart';
import '../../state/app_state.dart';
import '../../models/tournament_model.dart';
import '../../models/team_model.dart';
import '../../constants/app_colors.dart';
import '../../constants/custom_snackbar.dart';
import '../main_navigation_screen.dart';

class CreateTournamentScreen extends StatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _venueController = TextEditingController(text: 'CricX Turf Arena');
  final _oversController = TextEditingController(text: '10');
  
  String _selectedPlayoffType = 'Direct Final'; // 'Direct Final' or 'Semifinals & Final'
  DateTime _selectedStartDate = DateTime.now();
  final List<Team> _selectedTeams = [];

  @override
  void dispose() {
    _nameController.dispose();
    _venueController.dispose();
    _oversController.dispose();
    super.dispose();
  }

  void _checkPlayoffFormat() {
    if (_selectedPlayoffType == 'Semifinals & Final' && _selectedTeams.length < 8) {
      setState(() {
        _selectedPlayoffType = 'Direct Final';
      });
      CustomSnackBar.show(
        context,
        message: 'Playoff format reverted to Direct Final. Semifinals & Final requires at least 8 teams.',
        type: SnackBarType.warning,
        duration: const Duration(seconds: 3),
      );
    }
  }

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

              // Venue
              TextFormField(
                controller: _venueController,
                style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                decoration: _buildInputDecoration('Default Venue (e.g. CricX Turf Arena)'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter default venue' : null,
              ),
              const SizedBox(height: 4),
              const Text(
                'Note: You can customize the venue for individual matches during fixture generation.',
                style: TextStyle(color: AppColors.textDarkMuted, fontSize: 10, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),

              // Overs & Start Date Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overs
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Overs', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _oversController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                          decoration: _buildInputDecoration('Overs (e.g. 10)'),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Enter overs';
                            final o = int.tryParse(value);
                            if (o == null || o <= 0) return 'Invalid';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Start Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Start Date', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12)),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedStartDate,
                              firstDate: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
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
                                _selectedStartDate = picked;
                              });
                            }
                          },
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.borderGreen),
                            ),
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${_selectedStartDate.day}/${_selectedStartDate.month}/${_selectedStartDate.year}",
                                  style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                                ),
                                const Icon(Icons.calendar_today, size: 16, color: AppColors.primaryTurf),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Multi-select Teams
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('PARTICIPATING TEAMS', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      const SizedBox(width: 8),
                      Text('(${_selectedTeams.length} Selected)', style: const TextStyle(color: AppColors.accentCrease, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (teams.isNotEmpty)
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(60, 24),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: AppColors.primaryTurf,
                      ),
                      onPressed: () {
                        setState(() {
                          if (_selectedTeams.length == teams.length) {
                            _selectedTeams.clear();
                          } else {
                            _selectedTeams.clear();
                            _selectedTeams.addAll(teams);
                          }
                          _checkPlayoffFormat();
                        });
                      },
                      child: Text(
                        _selectedTeams.length == teams.length ? 'Deselect All' : 'Select All',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
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
                            _checkPlayoffFormat();
                          });
                        },
                      ),
                    );
                  },
                ),
              const SizedBox(height: 24),

              // Playoff stage selector
              const Text('Playoff Stage Format', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buildSelectionTile(
                      label: '🏆 Direct Final\n(Top 2 Teams)',
                      isSelected: _selectedPlayoffType == 'Direct Final',
                      onTap: () => setState(() => _selectedPlayoffType = 'Direct Final'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSelectionTile(
                      label: '⚡ Semi-Finals & Final\n(Top 4 Teams)',
                      isSelected: _selectedPlayoffType == 'Semifinals & Final',
                      onTap: () {
                        if (_selectedTeams.length < 8) {
                          CustomSnackBar.show(
                            context,
                            message: 'Semifinals & Final format is only available for tournaments with 8 or more teams.',
                            type: SnackBarType.warning,
                          );
                        } else {
                          setState(() => _selectedPlayoffType = 'Semifinals & Final');
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Playoff stage selector note
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _selectedPlayoffType == 'Semifinals & Final'
                      ? AppColors.primaryTurf.withOpacity(0.08)
                      : AppColors.woodMahogany.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _selectedPlayoffType == 'Semifinals & Final'
                        ? AppColors.primaryTurf.withOpacity(0.2)
                        : AppColors.woodMahogany.withOpacity(0.2),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedPlayoffType == 'Semifinals & Final'
                          ? Icons.info_outline_rounded
                          : Icons.emoji_events_outlined,
                      size: 16,
                      color: _selectedPlayoffType == 'Semifinals & Final'
                          ? AppColors.primaryTurf
                          : AppColors.woodMahogany,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedPlayoffType == 'Semifinals & Final'
                            ? 'Note: This format requires a minimum of 8 participating teams. Top 4 teams will qualify for the Semi-Finals.'
                            : 'Note: Top 2 teams will qualify directly for a Final match.',
                        style: const TextStyle(
                          color: AppColors.textDarkSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? AppColors.primaryTurf : AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 12,
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

    final playoffReqTeams = _selectedPlayoffType == 'Semifinals & Final' ? 4 : 2;
    if (_selectedTeams.length < playoffReqTeams) {
      CustomSnackBar.show(
        context,
        message: 'Please select at least $playoffReqTeams teams for this format',
        type: SnackBarType.error,
      );
      return;
    }

    if (_selectedPlayoffType == 'Semifinals & Final' && _selectedTeams.length < 8) {
      CustomSnackBar.show(
        context,
        message: 'Semifinals & Final format requires at least 8 participating teams.',
        type: SnackBarType.error,
      );
      return;
    }

    final id = 'tour_new_${DateTime.now().millisecondsSinceEpoch}';
    final overs = int.tryParse(_oversController.text.trim()) ?? 10;

    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final tourStartDate = DateTime(_selectedStartDate.year, _selectedStartDate.month, _selectedStartDate.day);
    final String initialStatus = tourStartDate.isAfter(today) ? 'Upcoming' : 'Ongoing';

    final String? currentUserId = AuthService.instance.currentUser?.uid;
    final newTour = Tournament(
      id: id,
      name: _nameController.text.trim(),
      type: 'League',
      teams: List.from(_selectedTeams),
      matches: [],
      status: initialStatus,
      playoffType: _selectedPlayoffType,
      defaultOvers: overs,
      startDate: _selectedStartDate,
      venue: _venueController.text.trim(),
      creatorId: currentUserId,
    );

    newTour.updatePointsTable();

    final appState = Provider.of<AppState>(context, listen: false);
    appState.createTournament(newTour);

    CustomSnackBar.show(
      context,
      message: 'Tournament "${newTour.name}" launched successfully!',
      type: SnackBarType.success,
    );
    Navigator.pop(context);
  }
}
