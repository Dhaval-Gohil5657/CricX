import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../models/team_model.dart';
import '../../models/player_model.dart';
import '../../constants/app_colors.dart';

class CreateTeamScreen extends StatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teamNameController = TextEditingController();
  final _abbController = TextEditingController();
  
  String _selectedEmoji = '🔥';
  int _selectedColorHex = 0xFF4CAF50; // default green
  
  final List<Player> _addedPlayers = [];
  final _playerNameController = TextEditingController();
  String _selectedPlayerRole = 'Batsman';
  String _selectedBattingStyle = 'Right-hand bat';
  String _selectedBowlingStyle = 'Right-arm medium';

  final List<String> _emojis = ['🔥', '⚡', '🌪️', '🦁', '🦅', '🦈', '⚔️', '🛡️', '👑', '⭐️'];
  final List<int> _colors = [0xFF4CAF50, 0xFF2196F3, 0xFFFF9800, 0xFFE91E63, 0xFF9C27B0, 0xFF00BCD4, 0xFFF44336, 0xFFFFEB3B];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.appBarBg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create New Team', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Team Info Section
              const Text('TEAM INFO', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _teamNameController,
                style: const TextStyle(color: AppColors.textDark),
                decoration: _buildInputDecoration('Team Name (e.g. Mumbai Warriors)'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter team name' : null,
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _abbController,
                maxLength: 4,
                style: const TextStyle(color: AppColors.textDark),
                textCapitalization: TextCapitalization.characters,
                decoration: _buildInputDecoration('Abbreviation (e.g. MW)'),
                validator: (value) => value == null || value.isEmpty ? 'Enter abbreviation' : null,
              ),
              const SizedBox(height: 16),
              
              // Emoji Selector
              const Text('SELECT LOGO EMOJI', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _emojis.length,
                  itemBuilder: (context, index) {
                    final emoji = _emojis[index];
                    final isSelected = _selectedEmoji == emoji;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedEmoji = emoji),
                      child: Container(
                        width: 44,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accentCrease.withOpacity(0.2) : AppColors.cardBg,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.accentCrease : AppColors.borderGreen,
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(emoji, style: const TextStyle(fontSize: 20)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Color Selector
              const Text('SELECT TEAM COLOR', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _colors.length,
                  itemBuilder: (context, index) {
                    final colorHex = _colors[index];
                    final isSelected = _selectedColorHex == colorHex;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColorHex = colorHex),
                      child: Container(
                        width: 36,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Color(colorHex),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),

              // Add Players Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('PLAYING SQUAD', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  Text('${_addedPlayers.length} Added', style: const TextStyle(color: AppColors.accentCrease, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              
              // Added Players List
              if (_addedPlayers.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderGreen, width: 1),
                  ),
                  child: const Center(
                    child: Text('No players added yet. Add players below.', style: TextStyle(color: AppColors.textDarkMuted, fontSize: 13)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _addedPlayers.length,
                  itemBuilder: (context, index) {
                    final p = _addedPlayers[index];
                    return Card(
                      color: AppColors.cardBg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.dividerGreen,
                          child: Text('${index + 1}', style: const TextStyle(color: AppColors.textDark)),
                        ),
                        title: Text(p.name, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
                        subtitle: Text('${p.role} • ${p.battingStyle}', style: const TextStyle(color: AppColors.textDarkSecondary)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                          onPressed: () => setState(() => _addedPlayers.removeAt(index)),
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 20),

              // Player Adder Form Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.appBarBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderGreen, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ADD PLAYER TO SQUAD', style: TextStyle(color: AppColors.accentCrease, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _playerNameController,
                      style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                      decoration: _buildInputDecoration('Player Name (e.g. Virat Sharma)'),
                    ),
                    const SizedBox(height: 12),
                    
                    // Role Dropdown
                    _buildDropdown('Player Role', _selectedPlayerRole, ['Batsman', 'Bowler', 'All-Rounder', 'Wicketkeeper'], (val) {
                      if (val != null) setState(() => _selectedPlayerRole = val);
                    }),
                    const SizedBox(height: 12),
                    
                    // Batting Style
                    _buildDropdown('Batting Style', _selectedBattingStyle, ['Right-hand bat', 'Left-hand bat'], (val) {
                      if (val != null) setState(() => _selectedBattingStyle = val);
                    }),
                    const SizedBox(height: 12),

                    // Bowling Style
                    _buildDropdown('Bowling Style', _selectedBowlingStyle, ['Right-arm medium', 'Right-arm spin', 'Left-arm orthodox', 'None'], (val) {
                      if (val != null) setState(() => _selectedBowlingStyle = val);
                    }),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTurf,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _addPlayerToSquad,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Player to List', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Save Team Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentCrease,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saveTeam,
                  child: const Text('SAVE & CREATE TEAM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addPlayerToSquad() {
    final name = _playerNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter player name')),
      );
      return;
    }
    
    final id = 'p_new_${DateTime.now().millisecondsSinceEpoch}';
    final newPlayer = Player(
      id: id,
      name: name,
      role: _selectedPlayerRole,
      battingStyle: _selectedBattingStyle,
      bowlingStyle: _selectedBowlingStyle == 'None' ? '-' : _selectedBowlingStyle,
    );

    setState(() {
      _addedPlayers.add(newPlayer);
      _playerNameController.clear();
    });
  }

  void _saveTeam() {
    if (!_formKey.currentState!.validate()) return;
    
    if (_addedPlayers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least 1 player to the squad')),
      );
      return;
    }

    final teamId = 't_new_${DateTime.now().millisecondsSinceEpoch}';
    final newTeam = Team(
      id: teamId,
      name: _teamNameController.text.trim(),
      abbreviation: _abbController.text.trim().toUpperCase(),
      logoEmoji: _selectedEmoji,
      logoColorHex: _selectedColorHex,
      players: _addedPlayers,
    );

    final appState = Provider.of<AppState>(context, listen: false);
    appState.addTeam(newTeam);
    
    // Register players in global list too
    for (var player in _addedPlayers) {
      appState.players.add(player);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Team "${newTeam.name}" created successfully!')),
    );
    Navigator.pop(context);
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textDarkMuted, fontSize: 13),
      filled: true,
      fillColor: AppColors.cardBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      counterStyle: const TextStyle(color: AppColors.textDarkMuted),
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

  Widget _buildDropdown(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderGreen),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.appBarBg,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.accentCrease),
          style: const TextStyle(color: AppColors.textDark, fontSize: 14),
          onChanged: onChanged,
          items: options.map((opt) {
            return DropdownMenuItem(value: opt, child: Text(opt));
          }).toList(),
        ),
      ),
    );
  }
}
