import 'package:flutter/material.dart';
import 'search_bar.dart' as custom;



enum AppBarMode{ normal, searching }

class CustomSliverAppBar extends StatefulWidget {
  final String? title;
  final List<Widget>? actions;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? themeColor;
  final Widget? leading;
  final bool pinned;
  final bool floating;
  final double? expandedHeight;
  final Widget? flexibleSpace;
  final double elevation;
  final bool isSearchMode;
  final double? titleSpacing;

  final String userEmail;
  final bool hasNotes;
  final List<PopupMenuEntry> menuItems;
  final Function(String)? onSearchChanged;
  final VoidCallback? onToggleView;
  final bool isListView;

  const CustomSliverAppBar({
    super.key,
    this.title,
    this.actions,
    required this.backgroundColor,
    required this.foregroundColor,
    this.themeColor,
    this.leading,
    this.pinned = true,
    this.floating = false,
    this.expandedHeight,
    this.flexibleSpace,
    this.elevation = 0,
    this.isSearchMode = false,
    this.titleSpacing,

    required this.userEmail,
    required this.hasNotes,
    required this.menuItems,
    this.onSearchChanged,
    this.onToggleView,
    required this.isListView,
  });

  @override
  State<CustomSliverAppBar> createState() => _CustomSliverAppBarState();
}


class _CustomSliverAppBarState extends State<CustomSliverAppBar> with TickerProviderStateMixin {
  AppBarMode _currentMode = AppBarMode.normal;
  late AnimationController _modeController;
  late Animation<double> _titleOpacity;
  late Animation<double> _searchOpacity;
  late Animation<Offset> _titleSlide;
  late Animation<Offset> _searchSlide;

  @override
  void initState(){
    super.initState();
    _setupModeAnimations();
  }

  void _setupModeAnimations(){
    _modeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _titleOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
          parent: _modeController,
          curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ));

    _titleSlide = Tween<Offset>(
      begin: const Offset(0.0,0.0),
      end: const Offset(0.0, -0.5),
    ).animate(CurvedAnimation(
        parent: _modeController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
    ));

    _searchOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _modeController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
          ));

    _searchSlide = Tween<Offset>(
      begin: const Offset(0.0, -0.5),
      end: const Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _modeController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    ));
  }

  void _toggleSearchMode(){
    setState(() {
      if (_currentMode == AppBarMode.normal) {
        _modeController.forward();
        _currentMode = AppBarMode.searching;
      } else {
        _modeController.reverse();
        _currentMode = AppBarMode.normal;
      }
    });
  }

  @override
  void dispose(){
    _modeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: widget.pinned,
      floating: widget.floating,
      expandedHeight: widget.expandedHeight,
      backgroundColor: widget.themeColor ?? widget.backgroundColor,
      foregroundColor: widget.foregroundColor,
      elevation: widget.elevation,
      leading: widget.leading,

      titleSpacing: _currentMode == AppBarMode.searching
          ? (widget.titleSpacing ?? 16)
          : (widget.titleSpacing ?? NavigationToolbar.kMiddleSpacing),

      // Dynamic title using Existing Structure
      title: AnimatedBuilder(
        animation: _modeController,
        builder: (context, child) {
          return SizedBox(
            height: kToolbarHeight,
            child: Stack(
              children: [
                // Normal Mode - Use existing title
                _buildNormalMode(),

                // Search Mode - Full Search Bar
                _buildSearchMode(),
              ],
              ),
          );
        },
      ),
      actions: widget.actions ?? [_buildProfileMenu()],


      flexibleSpace: widget.flexibleSpace ??
          (widget.themeColor != null
              ? null
              : LayoutBuilder(
            builder: (context, constraints) {
              bool isDesktop = constraints.maxWidth > 600;
              return Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                      isDesktop
                          ? "assets/images/Web_AppBar_Background.png"
                          : "assets/images/Phone_AppBar_Background.png",
                    ),
                    fit: BoxFit.cover,
                    opacity: (_currentMode == AppBarMode.searching || widget.isSearchMode) ? 0.8 : 1.0,
                  ),
                ),
              );
            },
          ) as Widget?),  // Added explicit cast

    );
  }

  Widget _buildNormalMode(){
    return SlideTransition(
      position: _titleSlide,
      child: FadeTransition(
        opacity: _titleOpacity,
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.title ?? "Notes",  // Simple string handling
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: widget.foregroundColor,
                ),
              ),
            ),
              // Search Icon - if it has notes
              if (widget.hasNotes)
                IconButton(
                  icon: Icon(
                    Icons.search,
                    size: 22,
                    color: widget.foregroundColor.withAlpha(90),
                  ),
                  onPressed: _toggleSearchMode,
                  tooltip: "Search Notes",
                  ),
                          ], // Children
        ), //Row
      ), // FadeTransition
    ); //return statement
  } // Widget _buildNormalMode

Widget _buildSearchMode(){
    return SlideTransition(
      position: _searchSlide,
      child: FadeTransition(
        opacity: _searchOpacity,
        child: custom.SearchBar(
          isExpanded: _currentMode == AppBarMode.searching,
          onChanged: widget.onSearchChanged,
          onToggleView: widget.onToggleView,
          isListView: widget.isListView,
          onClose: _toggleSearchMode,
        ), // Child (custom.SearchBar)
      ),// Child (FadeTransition)
    ); //return statement
    } // Widget _buildSearchMode

Widget _buildProfileMenu(){
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: PopupMenuButton(
        itemBuilder: (context) => widget.menuItems,
        offset: const Offset(0,50),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: Colors.white24,
          child: Text(
            widget.userEmail.isNotEmpty
                ? widget.userEmail[0].toUpperCase()
                : "U",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: widget.foregroundColor,
            ),
         ), // Child (Text0
        ),
      ), // child (PopUpMenuButton)
    ); //return statement
}// Widget _buildProfileMenu

} // State Class
