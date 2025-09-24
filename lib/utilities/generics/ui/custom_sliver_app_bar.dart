import 'package:flutter/material.dart';
import 'package:infinity_notes/enums/menu_actions.dart';
import 'package:infinity_notes/utilities/generics/ui/animation/animation_controller.dart';
import 'package:infinity_notes/utilities/generics/ui/animation/animation_storage.dart';
import 'package:infinity_notes/utilities/generics/ui/profile_drawer.dart';
import 'package:infinity_notes/utilities/generics/ui/ui_constants.dart';

import 'search_bar.dart' as custom;

enum AppBarMode { normal, searching }

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
  // final List<PopupMenuEntry> menuItems;
  final Function(String)? onSearchChanged;
  final VoidCallback? onToggleView;
  final bool isListView;
  final bool autoShowSearch;
  final VoidCallback? onLogout;
  final VoidCallback? onProfile;
  final VoidCallback? onSettings
  ;
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
    // required this.menuItems,
    this.onSearchChanged,
    this.onToggleView,
    required this.isListView,
    this.autoShowSearch = false,
    this.onLogout,
    this.onProfile,
    this.onSettings,
  });

  @override
  State<CustomSliverAppBar> createState() => _CustomSliverAppBarState();
}
class _CustomSliverAppBarState extends State<CustomSliverAppBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _titleOpacity;
  late Animation<double> _searchOpacity;

  bool _showTitle = false;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _setupFadeAnimations();
    _checkAndPlayAnimation();
  }
  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _setupFadeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800), // ✅ Shorter for cleaner fade
      vsync: this,
    );

    // ✅ CLEAN: Simple fade out for title
    _titleOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOut,
      ),
    );

    // ✅ CLEAN: Simple fade in for search
    _searchOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeIn,
      ),
    );
  }

  void _checkAndPlayAnimation() {
    // ✅ SIMPLE: Check the global flag
    if (GlobalAnimationController.shouldShowTitleAnimation() && mounted) {
      debugPrint("🎯 ✅ Starting title animation...");

      setState(() {
        _showTitle = true;
        _isAnimating = true;
      });

      // ✅ CONSUME: Mark animation as played to prevent repeat
      GlobalAnimationController.consumeTitleAnimation();

      Future.delayed(Duration(milliseconds: 1500), () {
        if (mounted) {
          _fadeController.forward().then((_) {
            if (mounted) {
              setState(() {
                _showTitle = false;
                _isAnimating = false;
              });
              debugPrint("🎯 ✅ Animation complete!");
            }
          });
        }
      });
    } else {
      debugPrint("🎯 ❌ No animation - showing search directly");
      setState(() {
        _showTitle = false;
        _isAnimating = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: widget.pinned,
      floating: widget.floating,
      expandedHeight: widget.expandedHeight,
      backgroundColor: Colors.transparent,
      foregroundColor: widget.foregroundColor,
      elevation: widget.elevation,
      leading: widget.leading,
      titleSpacing: 8,

      title: SizedBox(
        height: kToolbarHeight - 4,
        child: _isAnimating
            ? AnimatedBuilder(
          animation: _fadeController,
          builder: (context, child) {
            return Stack(
              children: [
                // ✅ CLEAN: Search fades in (no sliding)
                Opacity(
                  opacity: _searchOpacity.value,
                  child: _buildSearchMode(),
                ),

                // ✅ CLEAN: Title fades out (no sliding)
                Opacity(
                  opacity: _titleOpacity.value,
                  child: _buildNormalMode(),
                ),
              ],
            );
          },
        )
            : _showTitle
            ? _buildNormalMode()
            : _buildSearchMode(),
      ),

      actions: widget.actions ?? [_buildProfileMenu()],
      flexibleSpace: null,
    );
  }

  // ✅ CLEAN: No SlideTransition wrappers, just containers
  Widget _buildNormalMode() {
    return Container(
      height: kToolbarHeight - 4,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(100),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withAlpha(40), width: 1.2),
        boxShadow: UIConstants.containerShadow,
      ),
      alignment: Alignment.center,
      child: Text(
        widget.title ?? "Infinity Notes",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.5,
          shadows: UIConstants.textShadow,
        ),
      ),
    );
  }

  Widget _buildSearchMode() {
    return Container(
      height: kToolbarHeight - 4,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: custom.SearchBar(
        isExpanded: true,
        onChanged: widget.onSearchChanged,
        onToggleView: widget.onToggleView,
        isListView: widget.isListView,
        onClose: null,
      ),
    );
  }

  Widget _buildProfileMenu() {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () {
          showProfileDrawer(
            context: context,
            userEmail: widget.userEmail,
            onLogout: () {
              if (widget.onLogout != null) {
                widget.onLogout!();
              } else {
                debugPrint('🚪 No logout handler provided');
              }
            },
            onProfile: () {
              debugPrint('👤 Profile feature coming soon!');
            },
            onSettings: () {
              debugPrint('⚙️ Settings feature coming soon!');
            },
          );
        },
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(80),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withAlpha(90), width: 1.5),
            boxShadow: UIConstants.strongShadow,
          ),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.cyan.withAlpha(20),
            child: Text(
              widget.userEmail.isNotEmpty
                  ? widget.userEmail[0].toUpperCase()
                  : "U",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: UIConstants.textShadow,
              ),
            ),
          ),
        ),
      ),
    );
  }

}

