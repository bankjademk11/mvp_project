import 'package:flutter/material.dart';

class SkillsSelectionDialog extends StatefulWidget {
  final List<String> allSkills;
  final List<String> initialSelectedSkills;

  const SkillsSelectionDialog({
    super.key,
    required this.allSkills,
    required this.initialSelectedSkills,
  });

  @override
  State<SkillsSelectionDialog> createState() => _SkillsSelectionDialogState();
}

class _SkillsSelectionDialogState extends State<SkillsSelectionDialog> {
  late final Set<String> _selectedSkills;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedSkills = Set.from(widget.initialSelectedSkills);
  }

  List<String> get _filteredSkills {
    if (_searchQuery.isEmpty) {
      return widget.allSkills;
    }
    return widget.allSkills
        .where((skill) =>
            skill.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _onSkillToggle(String skill) {
    setState(() {
      if (_selectedSkills.contains(skill)) {
        _selectedSkills.remove(skill);
      } else {
        _selectedSkills.add(skill);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Using a Dialog instead of AlertDialog for more control over padding and shape
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Your Skills', // TODO: Localize
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(
                labelText: 'Search Skills', // TODO: Localize
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Use a container with a specific height to prevent overflow
            SizedBox(
              height: 300, // Adjust height as needed
              width: double.maxFinite,
              child: ListView.builder(
                itemCount: _filteredSkills.length,
                itemBuilder: (context, index) {
                  final skill = _filteredSkills[index];
                  return CheckboxListTile(
                    title: Text(skill),
                    value: _selectedSkills.contains(skill),
                    onChanged: (_) => _onSkillToggle(skill),
                    activeColor: Theme.of(context).colorScheme.primary,
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'), // TODO: Localize
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selectedSkills.toList()),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text('Done'), // TODO: Localize
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
