import 'package:geolocator/geolocator.dart';

import '../core/api_client.dart';
import '../core/api_response.dart';
import '../core/diagnostics.dart';
import '../core/location_service.dart';
import '../models/assistant_reply.dart';

/// The smart assistant (`POST /assistant/query`).
///
/// The route is authenticated, player-only and rate limited
/// (`auth:sanctum`, `role:player`, `throttle:assistant`).
///
/// The body takes EITHER `query_text` — a typed question — OR `option_id`,
/// which picks one of the choices the previous answer offered. Both carry
/// `conversation_id` once there is one, which is what lets the assistant
/// remember the question before.
class AssistantService {
  AssistantService({ApiClient? client, LocationService? locationService})
      : _client = client ?? ApiClient(),
        _locationService = locationService ?? LocationService();

  final ApiClient _client;
  final LocationService _locationService;

  static const String _path = '/assistant/query';

  /// Confirmed against the deployment, which answered a request keyed
  /// `query` with "The query text field is required". Kept adjustable so
  /// a rename corrects itself rather than silencing the assistant.
  static String _field = 'query_text';

  /// The thread the answers belong to. A string, since the backend sends
  /// an opaque identifier rather than a number.
  String? _conversationId;

  /// Sends a typed question.
  Future<ApiResponse<AssistantReply>> ask(String question) {
    return _send(<String, dynamic>{_field: question});
  }

  /// Picks one of the choices the last answer offered. The id is a name
  /// such as `cheapest`, `all_venues` or `city_3`.
  ///
  /// `use_location` is the one choice that cannot be answered by its id
  /// alone, so the coordinates travel in the SAME request rather than in a
  /// second one the backend would have no way to tie to it.
  Future<ApiResponse<AssistantReply>> choose(String optionId) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'option_id': optionId,
    };

    if (optionId == 'use_location') {
      final Position? position = await _position();
      if (position != null) {
        body['latitude'] = position.latitude;
        body['longitude'] = position.longitude;
      }
    }

    return _send(body);
  }

  /// Forgets the thread, so a fresh screen starts a fresh conversation.
  void reset() => _conversationId = null;

  /// The player's coordinates, or null when they cannot be read. A refused
  /// permission must not swallow the choice: the request still goes, and
  /// the backend answers with whatever it can without a location.
  Future<Position?> _position() async {
    try {
      return await _locationService.currentPosition();
    } on Object catch (error) {
      Diagnostics.add('assistant: location unavailable ($error)');
      return null;
    }
  }

  Future<ApiResponse<AssistantReply>> _send(Map<String, dynamic> body) async {
    ApiResponse<AssistantReply> response = await _post(body);

    // A 422 names the field the endpoint wanted. Retry once under that
    // name rather than losing the question.
    if (response.statusCode == 422 && body.containsKey(_field)) {
      final String? wanted = _missingField(response);
      if (wanted != null && wanted != _field) {
        Diagnostics.add('assistant: server wants "$wanted", retrying');
        final Object? question = body[_field];
        _field = wanted;
        response = await _post(<String, dynamic>{_field: question});
      }
    }

    final AssistantReply? reply = response.data;
    // Adopt the newest thread id the server sends; it may change when the
    // assistant starts a new conversation on its own.
    if (reply?.conversationId != null) {
      _conversationId = reply!.conversationId;
    }

    Diagnostics.add(
      'assistant -> ${response.statusCode} success=${response.success} '
      'text=${reply?.hasText ?? false} options=${reply?.options.length ?? 0} '
      'suggestions=${reply?.suggestions.length ?? 0} '
      'intent=${reply?.intent} conv=$_conversationId',
    );

    return response;
  }

  Future<ApiResponse<AssistantReply>> _post(Map<String, dynamic> body) {
    return _client.post<AssistantReply>(
      _path,
      authenticated: true,
      body: <String, dynamic>{
        ...body,
        if (_conversationId != null) 'conversation_id': _conversationId,
      },
      parseData: (dynamic data) =>
          AssistantReply.fromJson(data as Map<String, dynamic>),
    );
  }

  /// The first field named in a validation error is the missing one.
  static String? _missingField(ApiResponse<AssistantReply> response) {
    final Map<String, List<String>>? errors = response.errors;
    if (errors == null || errors.isEmpty) {
      return null;
    }
    return errors.keys.first;
  }
}
