import 'package:flutter/material.dart';
import '../../services/language_service.dart';

class SearchBarField extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onFilter;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final String hintText;
  
  const SearchBarField({
    super.key, 
    required this.controller, 
    this.onFilter, 
    this.onChanged,
    this.onSubmitted,
    this.hintText = 'lo', // Will be replaced with translation
  });

  @override
  State<SearchBarField> createState() => _SearchBarFieldState();
}

class _SearchBarFieldState extends State<SearchBarField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {}); // Rebuild to show/hide clear button
  }

  @override
  Widget build(BuildContext context) {
    // Get language code from context or default to Lao
    final languageCode = Localizations.maybeLocaleOf(context)?.languageCode ?? 'lo';
    
    // Get translations
    final hintText = AppLocalizations.translate('search_jobs', languageCode);
    final filterTooltip = AppLocalizations.translate('filter', languageCode);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: widget.controller,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted != null ? (_) => widget.onSubmitted!() : null,
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  suffixIcon: widget.controller.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          onPressed: () {
                            widget.controller.clear();
                            if (widget.onChanged != null) widget.onChanged!('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, 
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: widget.onFilter,
              icon: Icon(
                Icons.tune,
                color: Theme.of(context).colorScheme.primary,
              ),
              tooltip: filterTooltip,
            ),
          ),
        ],
      ),
    );
  }
}