import 'package:eventmanagment/core/widgets/event_card.dart';
import 'package:eventmanagment/features/attendance/models/attendance_model.dart';
import 'package:eventmanagment/features/auth/models/user_model.dart';
import 'package:eventmanagment/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:eventmanagment/features/auth/views/login_screen.dart';
import 'package:eventmanagment/features/events/models/event_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthViewModel extends AuthViewModel {
  @override
  AuthState build() => const AuthState(isInitialized: true);
}

void main() {
  group('Domain Models', () {
    test('UserModel.fromJson parses student role correctly', () {
      final user = UserModel.fromJson({
        'id': 3,
        'full_name': 'Aarav Patel',
        'email': 'student@campus.edu',
        'role': 'student',
        'student_id_number': '24CE001',
        'department': 'Computer Engineering',
        'is_active': 1,
      });

      expect(user.id, 3);
      expect(user.isStudent, isTrue);
      expect(user.isOrganizer, isFalse);
      expect(user.studentIdNumber, '24CE001');
    });

    test('EventModel.fromJson computes isFull accurately', () {
      final event = EventModel.fromJson({
        'id': 1,
        'organizer_id': 2,
        'category_id': 5,
        'title': 'Flutter Bootcamp',
        'description': 'Learn Flutter & PHP',
        'venue': 'Main Auditorium',
        'start_time': '2026-12-01 10:00:00',
        'end_time': '2026-12-01 16:00:00',
        'max_capacity': 50,
        'registered_count': 50,
        'status': 'published',
        'category_name': 'Workshop',
      });

      expect(event.isFull, isTrue);
      expect(event.categoryName, 'Workshop');
    });

    test('AttendanceSessionModel and StudentPassModel parse session window correctly', () {
      final session = AttendanceSessionModel.fromJson({
        'event_id': 1,
        'is_active': true,
        'expires_at': '2026-11-20 10:30:00',
        'remaining_seconds': 1800,
        'duration_minutes': 30,
        'session_token': 'CAMPUS_SESSION_1_abc',
      });

      expect(session.eventId, 1);
      expect(session.isActive, isTrue);
      expect(session.remainingSeconds, 1800);
      expect(session.durationMinutes, 30);

      final pass = StudentPassModel.fromJson({
        'event_id': 1,
        'event_title': 'Flutter Bootcamp',
        'registration_id': 10,
        'user_id': 3,
        'student_name': 'Aarav Patel',
        'student_id_number': '24CE001',
        'is_attended': false,
        'session_active': true,
        'session_expires_at': '2026-11-20 10:30:00',
      });

      expect(pass.studentName, 'Aarav Patel');
      expect(pass.studentIdNumber, '24CE001');
      expect(pass.isAttended, isFalse);
      expect(pass.sessionActive, isTrue);
    });
  });

  group('Widgets', () {
    testWidgets('EventCard displays title, venue, and seat count',
        (tester) async {
      const event = EventModel(
        id: 1,
        organizerId: 2,
        categoryId: 1,
        title: 'Campus Hackathon',
        description: '24-hour coding event',
        venue: 'Innovation Lab',
        startTime: '2026-12-01 10:00:00',
        endTime: '2026-12-02 10:00:00',
        maxCapacity: 80,
        registeredCount: 25,
        status: 'published',
        categoryName: 'Technical',
      );

      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventCard(
              event: event,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Campus Hackathon'), findsOneWidget);
      expect(find.text('Innovation Lab'), findsOneWidget);
      expect(find.text('25/80 seats'), findsOneWidget);

      await tester.tap(find.byType(EventCard));
      expect(tapped, isTrue);
    });

    testWidgets('LoginScreen validates empty email and password',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authViewModelProvider.overrideWith(_FakeAuthViewModel.new),
          ],
          child: const MaterialApp(home: LoginScreen()),
        ),
      );

      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });
  });
}
