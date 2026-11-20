import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../events/views/event_list_screen.dart';
import '../../profile/views/profile_screen.dart';
import '../../registrations/views/my_registrations_screen.dart';
import 'admin_dashboard_tab.dart';
import 'organizer_dashboard_tab.dart';
import 'student_home_tab.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authViewModelProvider).currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    late final List<Widget> pages;
    late final List<NavigationDestination> destinations;

    if (user.isOrganizer) {
      pages = const [
        OrganizerDashboardTab(),
        EventListScreen(mineOnly: true),
        EventListScreen(),
        ProfileScreen(),
      ];
      destinations = const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.edit_calendar_outlined),
          selectedIcon: Icon(Icons.edit_calendar_rounded),
          label: 'Manage',
        ),
        NavigationDestination(
          icon: Icon(Icons.explore_outlined),
          selectedIcon: Icon(Icons.explore_rounded),
          label: 'Explore',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ];
    } else if (user.isAdmin) {
      pages = const [
        AdminDashboardTab(),
        EventListScreen(),
        ProfileScreen(),
      ];
      destinations = const [
        NavigationDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings_rounded),
          label: 'Admin',
        ),
        NavigationDestination(
          icon: Icon(Icons.event_outlined),
          selectedIcon: Icon(Icons.event_rounded),
          label: 'Events',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ];
    } else {
      pages = [
        StudentHomeTab(
          onSwitchTab: (i) => setState(() => _selectedIndex = i),
        ),
        const EventListScreen(),
        const MyRegistrationsScreen(),
        const ProfileScreen(),
      ];
      destinations = const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.explore_outlined),
          selectedIcon: Icon(Icons.explore_rounded),
          label: 'Explore',
        ),
        NavigationDestination(
          icon: Icon(Icons.confirmation_number_outlined),
          selectedIcon: Icon(Icons.confirmation_number_rounded),
          label: 'My Events',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ];
    }

    final safeIndex = _selectedIndex >= pages.length ? 0 : _selectedIndex;

    return Scaffold(
      backgroundColor: AppTheme.surfaceBg,
      body: IndexedStack(index: safeIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppTheme.cardBorder, width: 1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NavigationBar(
              selectedIndex: safeIndex,
              onDestinationSelected: (index) =>
                  setState(() => _selectedIndex = index),
              destinations: destinations,
              height: 64,
            ),
            // Android bottom gesture indicator
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              width: 120,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
