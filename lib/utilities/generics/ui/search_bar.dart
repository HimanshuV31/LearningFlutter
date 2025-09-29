import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinity_notes/services/search/bloc/search_bloc.dart';
import 'package:infinity_notes/services/search/bloc/search_event.dart';
import 'package:infinity_notes/utilities/generics/ui/ui_constants.dart';

class SearchBar extends StatefulWidget {
  final bool isExpanded;
  final Function(String)? onChanged;
  final VoidCallback? onToggleView;
  final bool isListView;
  final VoidCallback? onClose;
  const SearchBar({
    super.key,
    required this.isExpanded,
    this.onChanged,
    this.onToggleView,
    required this.isListView,
    this.onClose,
  });

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> with TickerProviderStateMixin {
  final _controller = TextEditingController();
  Timer? _debounceTimer;
  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      context.read<SearchBloc>().add(SearchQueryChanged(_controller.text));
    });
    if (widget.onChanged != null) {
      widget.onChanged!(_controller.text);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  // In search_bar.dart, simplify the build method:
  @override
  Widget build(BuildContext context) {
    if (!widget.isExpanded) {
      return const SizedBox.shrink();
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(102),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withAlpha(153), width: 1.5),
        boxShadow: UIConstants.containerShadow,
      ),
      child: Row(
        children: [
          // Search Icon
          Padding(
            padding: EdgeInsets.only(left: 16, right: 12),
            child: Icon(
              Icons.search,
              color: Colors.white,
              size: 22,
              shadows: UIConstants.iconShadow,
            ),
          ),

          // TextField
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: false,
              textAlignVertical: TextAlignVertical.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.0,
                shadows: UIConstants.textShadow,
              ),
              decoration: InputDecoration(
                hintText: "Search Notes",
                hintStyle: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.0,
                  shadows: UIConstants.textShadow,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 0),
                alignLabelWithHint: true,
              ),
              onChanged: (text) => _onTextChanged(),
            ),
          ),
          _buildActionIcons(),
        ],
      ),
    );
  }


  //Build overlayed action icons
  Widget _buildActionIcons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        //Clear Search (only when text exists)
        if (_controller.text.isNotEmpty)
          IconButton(
            icon: const Icon(
              Icons.clear,
              size: 20,
              color: Colors.white,
              shadows: UIConstants.iconShadow,
            ),
            onPressed: () {
              _controller.clear();
              context.read<SearchBloc>().add(const SearchCleared());
            },
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),

        // View Toggle (List/Grid)
        if (widget.onToggleView != null)
          IconButton(
            icon: Icon(
              widget.isListView ? Icons.grid_view : Icons.view_agenda,
              size: 20,
              color: Colors.white,
              shadows: UIConstants.iconShadow,
            ),
            onPressed: widget.onToggleView,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),

        //Close Search
        if (widget.onClose != null)
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: Colors.white70),
            onPressed: widget.onClose,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        const SizedBox(width: 8), // Right Padding
      ],
    );
  }
}
