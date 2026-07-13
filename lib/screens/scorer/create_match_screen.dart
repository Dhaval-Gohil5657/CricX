import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cricx/services/auth_service.dart';
import '../../state/app_state.dart';
import '../../models/match_model.dart';
import '../../models/team_model.dart';
import '../../constants/app_colors.dart';
import '../../constants/custom_snackbar.dart';
import '../main_navigation_screen.dart';
import '../../widgets/dotted_circular_loader.dart';

class CreateMatchScreen extends StatefulWidget {
  const CreateMatchScreen({super.key});

  @override
  State<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _venueController = TextEditingController();
  final _customOversController = TextEditingController();
  
  Team? _teamA;
  Team? _teamB;
  int _selectedOvers = 10;
  bool _isManualOvers = false;
  
  final List<int> _overOptions = [5, 10, 20, 30, 50];

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  bool _isSaving = false;

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(today) ? today : _selectedDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryTurf,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryTurf,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryTurf,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryTurf,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
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
          title: const Text('Schedule New Match', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              const Text('MATCH DETAILS', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              const SizedBox(height: 16),
              
              // Team A Dropdown
              const Text('Team A', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
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
              const Text('Team B', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
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

              // Overs Selection Grid
              const Text('NUMBER OF OVERS', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                childAspectRatio: 2.8,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [
                  ..._overOptions.map((over) {
                    final isSelected = !_isManualOvers && _selectedOvers == over;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedOvers = over;
                          _isManualOvers = false;
                        });
                      },
                      child: Container(
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
                  }).toList(),
                  // Manual option button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isManualOvers = true;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: _isManualOvers ? AppColors.accentCrease.withOpacity(0.2) : AppColors.cardBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isManualOvers ? AppColors.accentCrease : AppColors.borderGreen,
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Manual',
                        style: TextStyle(
                          color: _isManualOvers ? AppColors.accentCrease : AppColors.textDarkSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_isManualOvers) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customOversController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Enter Overs (e.g. 45)',
                    labelStyle: const TextStyle(color: AppColors.textDarkSecondary),
                    filled: true,
                    fillColor: AppColors.cardBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.borderGreen),
                    ),
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter number of overs';
                    }
                    final overs = int.tryParse(value);
                    if (overs == null || overs <= 0) {
                      return 'Enter a valid number of overs';
                    }
                    if (overs > 100) {
                      return 'Overs cannot exceed 100';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 20),

              // Date & Time Picker
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('MATCH DATE', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () => _selectDate(context),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.borderGreen),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, color: AppColors.accentCrease, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                                    style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('START TIME', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () => _selectTime(context),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.borderGreen),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_rounded, color: AppColors.accentCrease, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedTime.format(context),
                                    style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                    backgroundColor: AppColors.primaryTurf,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSaving ? () {} : _createMatch,
                  child: _isSaving
                      ? const DottedCircularLoader(size: 24, color: Colors.white, center: false)
                      : const Text('SCHEDULE MATCH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _venueController.dispose();
    _customOversController.dispose();
    super.dispose();
  }

  void _createMatch() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_teamA == null || _teamB == null) {
      CustomSnackBar.show(
        context,
        message: 'Please select both teams',
        type: SnackBarType.error,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final combinedDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final finalOvers = _isManualOvers
          ? (int.tryParse(_customOversController.text.trim()) ?? 10)
          : _selectedOvers;

      final String? currentUserId = AuthService.instance.currentUser?.uid;
      final id = 'm_new_${DateTime.now().millisecondsSinceEpoch}';
      final newMatch = CricketMatch(
        id: id,
        teamA: _teamA!,
        teamB: _teamB!,
        totalOvers: finalOvers,
        venue: _venueController.text.trim(),
        matchDate: combinedDateTime,
        creatorId: currentUserId,
      );

      await Provider.of<AppState>(context, listen: false).createMatch(newMatch);

      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Match scheduled between ${_teamA!.name} and ${_teamB!.name}!',
          type: SnackBarType.success,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        CustomSnackBar.show(
          context,
          message: 'Failed to schedule match: $e',
          type: SnackBarType.error,
        );
      }
    }
  }
}
