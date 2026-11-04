import '../core/api_client.dart';
import '../core/api_response.dart';
import '../core/app_config.dart';
import '../models/app_notification.dart';

/// The notification inbox (SRS FR-10, FR-11, FR-12).
abstract class NotificationService {
  /// Mocked alongside the rest of the app, so the inbox has something to
  /// show while the endpoint is still being built.
  factory NotificationService.create() => AppConfig.useMockVenues
      ? MockNotificationService()
      : ApiNotificationService();

  Future<ApiResponse<List<AppNotification>>> list({int page = 1});

  /// Marks one as read. The screen updates only after this succeeds.
  Future<ApiResponse<void>> markRead(int id);
}

/// Both paths are confirmed with the backend. The response shape is still
/// read on assumption — see [AppNotification.fromJson].
class ApiNotificationService implements NotificationService {
  ApiNotificationService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  @override
  Future<ApiResponse<List<AppNotification>>> list({int page = 1}) {
    return _client.get<List<AppNotification>>(
      '/notifications',
      authenticated: true,
      query: <String, String>{'page': '$page'},
      parseData: (dynamic data) {
        // Laravel returns either a bare array or a paginated envelope.
        final List<dynamic> items = data is Map<String, dynamic>
            ? (data['data'] as List<dynamic>? ?? <dynamic>[])
            : (data as List<dynamic>);
        return items
            .map((dynamic n) =>
                AppNotification.fromJson(n as Map<String, dynamic>))
            .toList();
      },
    );
  }

  @override
  Future<ApiResponse<void>> markRead(int id) {
    return _client.put<void>('/notifications/$id/read', authenticated: true);
  }
}

/// Sample data, so the screen can be reviewed without the endpoint.
class MockNotificationService implements NotificationService {
  MockNotificationService();

  late final List<AppNotification> _items = <AppNotification>[
    AppNotification(
      id: 1,
      title: 'تم تأكيد الحجز',
      body: 'تم تأكيد حجزك لملعب غزة الرياضي يوم السبت 28 سبتمبر، '
          'الساعة 6:00 مساءً.',
      type: NotificationType.bookingConfirmed,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    AppNotification(
      id: 2,
      title: 'تذكير بالحجز',
      body: 'غداً لديك حجز في ملعب الرمال الساعة 5:00 مساءً. '
          'نتمنى لك مباراة ممتعة!',
      type: NotificationType.bookingReminder,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    AppNotification(
      id: 3,
      title: 'عرض خاص',
      body: 'احصل على خصم 20% على حجوزات الملاعب هذا الأسبوع!',
      type: NotificationType.offer,
      createdAt: DateTime.now().subtract(const Duration(hours: 7)),
    ),
    AppNotification(
      id: 4,
      title: 'انتهت المباراة',
      body: 'تم إنهاء حجزك في ملعب المدينة. شكراً لاستخدامك التطبيق!',
      type: NotificationType.matchFinished,
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      isRead: true,
    ),
    AppNotification(
      id: 5,
      title: 'ملعب جديد متاح',
      body: 'تم إضافة ملعب جديد في منطقتك: ملعب الشهداء. احجز الآن!',
      type: NotificationType.general,
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
      isRead: true,
    ),
  ];

  @override
  Future<ApiResponse<List<AppNotification>>> list({int page = 1}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return ApiResponse<List<AppNotification>>(
      success: true,
      message: '',
      data: page == 1 ? List<AppNotification>.of(_items) : <AppNotification>[],
    );
  }

  @override
  Future<ApiResponse<void>> markRead(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final int index = _items.indexWhere((AppNotification n) => n.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(isRead: true);
    }
    return const ApiResponse<void>(success: true, message: '');
  }
}
