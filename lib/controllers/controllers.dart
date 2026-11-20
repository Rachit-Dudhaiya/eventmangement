// MVC Architecture - Controllers Barrel & Aliases
import '../features/attendance/viewmodels/attendance_viewmodel.dart';
import '../features/auth/viewmodels/auth_viewmodel.dart';
import '../features/events/viewmodels/event_viewmodel.dart';
import '../features/registrations/viewmodels/registration_viewmodel.dart';

export '../features/attendance/viewmodels/attendance_viewmodel.dart';
export '../features/auth/viewmodels/auth_viewmodel.dart';
export '../features/events/viewmodels/event_viewmodel.dart';
export '../features/registrations/viewmodels/registration_viewmodel.dart';

// Type aliases for strict MVC naming conventions
typedef AuthController = AuthViewModel;
typedef EventController = EventViewModel;
typedef RegistrationController = RegistrationViewModel;
typedef AttendanceController = AttendanceViewModel;

// Provider aliases for MVC controllers
final authControllerProvider = authViewModelProvider;
final eventControllerProvider = eventViewModelProvider;
final registrationControllerProvider = registrationViewModelProvider;
final attendanceControllerProvider = attendanceViewModelProvider;
