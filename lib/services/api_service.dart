import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../model/user_profile.dart';
import '../model/blood_request_model.dart';
import '../model/blood_donor.dart';

class ApiService {
  // Change this IP if your Linux Mint computer's Wi-Fi IP changes.
  // The phone and computer must be able to reach each other.
  static const String baseUrl = 'http://192.168.222.28:8000/api';

  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  static const Duration _timeout = Duration(seconds: 20);

  // =========================================================
  // COMMON HEADERS
  // =========================================================

  static Map<String, String> _headers({String? token}) {
    return {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  static Map<String, String> _jsonHeaders({String? token}) {
    return {
      ..._headers(token: token),
      'Content-Type': 'application/json',
    };
  }

  static Future<String> _requireToken() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Please log in first.');
    }

    return token;
  }

  static void _checkUnauthorized(int statusCode) {
    if (statusCode == 401) {
      throw Exception(
        'Your session expired. Please log in again.',
      );
    }
  }

  // =========================================================
  // LOGIN
  // =========================================================

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/login'),
          headers: _jsonHeaders(),
          body: jsonEncode({
            'email': email,
            'password': password,
          }),
        )
        .timeout(_timeout);

    final data = _decodeResponse(response.body);

    if (response.statusCode == 200 &&
        data['success'] == true) {
      final token = data['token'];

      if (token is! String || token.isEmpty) {
        throw Exception(
          'The server did not return a login token.',
        );
      }

      await _storage.write(
        key: 'auth_token',
        value: token,
      );

      return data;
    }

    throw Exception(
      data['message']?.toString() ?? 'Login failed.',
    );
  }

  // =========================================================
  // TOKEN MANAGEMENT
  // =========================================================

  static Future<String?> getToken() {
    return _storage.read(key: 'auth_token');
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: 'auth_token');
  }

  // =========================================================
  // REGISTRATION
  // =========================================================

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String contactNumber,
    required String address,
    required String bloodType,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/register'),
          headers: _jsonHeaders(),
          body: jsonEncode({
            'name': name,
            'email': email,
            'contact_number': contactNumber,
            'address': address,
            'blood_type': bloodType,
            'password': password,
            'password_confirmation': password,
          }),
        )
        .timeout(_timeout);

    final data = _decodeResponse(response.body);

    if (response.statusCode == 201 &&
        data['success'] == true) {
      return data;
    }

    if (response.statusCode == 422) {
      throw Exception(_validationMessage(data));
    }

    throw Exception(
      data['message']?.toString() ??
          'Registration failed.',
    );
  }

  // =========================================================
  // GET USER PROFILE
  // =========================================================

  static Future<UserProfile> getProfile() async {
    final token = await _requireToken();

    final response = await http
        .get(
          Uri.parse('$baseUrl/user'),
          headers: _headers(token: token),
        )
        .timeout(_timeout);

    final data = _decodeResponse(response.body);

    if (response.statusCode == 200 &&
        data['success'] == true) {
      final userData = data['user'];

      if (userData is! Map) {
        throw Exception(
          'The server returned invalid profile data.',
        );
      }

      return UserProfile.fromJson(
        Map<String, dynamic>.from(userData),
      );
    }

    if (response.statusCode == 401) {
      await clearToken();
      _checkUnauthorized(response.statusCode);
    }

    throw Exception(
      data['message']?.toString() ??
          'Could not load your profile.',
    );
  }

  // =========================================================
  // SUBMIT DONOR APPLICATION
  // =========================================================

  static Future<Map<String, dynamic>> submitDonorApplication({
    required String bloodType,
    String? dateOfBirth,
    String? phone,
    String? address,
  }) async {
    final token = await _requireToken();

    final body = <String, dynamic>{
      'blood_type': bloodType,
      if (dateOfBirth != null &&
          dateOfBirth.trim().isNotEmpty)
        'date_of_birth': dateOfBirth.trim(),
      if (phone != null && phone.trim().isNotEmpty)
        'phone': phone.trim(),
      if (address != null && address.trim().isNotEmpty)
        'address': address.trim(),
    };

    final response = await http
        .post(
          Uri.parse('$baseUrl/donor-applications'),
          headers: _jsonHeaders(token: token),
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    final data = _decodeResponse(response.body);

    if (response.statusCode == 201 &&
        data['success'] == true) {
      return data;
    }

    if (response.statusCode == 401) {
      await clearToken();
      _checkUnauthorized(response.statusCode);
    }

    if (response.statusCode == 409) {
      throw Exception(
        data['message']?.toString() ??
            'You already have a donor application.',
      );
    }

    if (response.statusCode == 422) {
      throw Exception(_validationMessage(data));
    }

    throw Exception(
      data['message']?.toString() ??
          'Unable to submit your donor application.',
    );
  }

  // =========================================================
  // GET BLOOD REQUESTS
  // =========================================================

  static Future<List<BloodRequest>> getBloodRequests() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/blood-requests'),
          headers: _headers(),
        )
        .timeout(_timeout);

    final data = _decodeResponse(response.body);

    if (response.statusCode == 200 &&
        data['success'] == true) {
      final requests = data['requests'];

      if (requests is! List) {
        throw Exception(
          'The server returned an invalid request list.',
        );
      }

      return requests
          .whereType<Map>()
          .map(
            (item) => BloodRequest.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    }

    throw Exception(
      data['message']?.toString() ??
          'Could not load blood requests.',
    );
  }

  // =========================================================
  // GET MY DONATION RESPONSES
  // =========================================================

  static Future<List<Map<String, dynamic>>>
      getMyDonationResponses() async {
    final token = await _requireToken();

    final response = await http
        .get(
          Uri.parse('$baseUrl/my-donation-responses'),
          headers: _headers(token: token),
        )
        .timeout(_timeout);

    final data = _decodeResponse(response.body);

    if (response.statusCode == 200 &&
        data['success'] == true) {
      final donations = data['data'];

      if (donations is! List) {
        throw Exception(
          'The server returned an invalid donation response list.',
        );
      }

      return donations
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(item),
          )
          .toList();
    }

    if (response.statusCode == 401) {
      await clearToken();
      _checkUnauthorized(response.statusCode);
    }

    if (response.statusCode == 404) {
      throw Exception(
        data['message']?.toString() ??
            'No active donor profile was found.',
      );
    }

    throw Exception(
      data['message']?.toString() ??
          'Unable to load your donation responses.',
    );
  }

  // =========================================================
  // CREATE BLOOD REQUEST
  // =========================================================

  static Future<Map<String, dynamic>> createBloodRequest({
    required String patientName,
    required String bloodType,
    required int unitsNeeded,
    required String hospital,
    String? notes,
  }) async {
    final token = await _requireToken();

    final response = await http
        .post(
          Uri.parse('$baseUrl/blood-requests'),
          headers: _jsonHeaders(token: token),
          body: jsonEncode({
            'patient_name': patientName,
            'blood_type': bloodType,
            'units_needed': unitsNeeded,
            'hospital': hospital,
            'notes': notes,
          }),
        )
        .timeout(_timeout);

    final data = _decodeResponse(response.body);

    if (response.statusCode == 201 &&
        data['success'] == true) {
      return data;
    }

    if (response.statusCode == 401) {
      await clearToken();
      _checkUnauthorized(response.statusCode);
    }

    if (response.statusCode == 422) {
      throw Exception(_validationMessage(data));
    }

    throw Exception(
      data['message']?.toString() ??
          'Could not submit blood request.',
    );
  }

  // =========================================================
  // RESPOND TO BLOOD REQUEST
  // =========================================================

  static Future<Map<String, dynamic>> respondToBloodRequest({
    required String id,
  }) async {
    final token = await _requireToken();
    final requestId = int.tryParse(id);

    if (requestId == null) {
      throw Exception('Invalid blood request ID.');
    }

    final response = await http
        .post(
          Uri.parse('$baseUrl/donations/respond'),
          headers: _jsonHeaders(token: token),
          body: jsonEncode({
            'blood_request_id': requestId,
          }),
        )
        .timeout(_timeout);

    final data = _decodeResponse(response.body);

    if ((response.statusCode == 200 ||
            response.statusCode == 201) &&
        data['success'] == true) {
      return data;
    }

    if (response.statusCode == 401) {
      await clearToken();
      _checkUnauthorized(response.statusCode);
    }

    if (response.statusCode == 403) {
      throw Exception(
        data['message']?.toString() ??
            'Your donor application must be approved first.',
      );
    }

    if (response.statusCode == 422) {
      throw Exception(_validationMessage(data));
    }

    throw Exception(
      data['message']?.toString() ??
          'Unable to respond to this blood request.',
    );
  }

  // =========================================================
  // GET MY BLOOD REQUESTS
  // =========================================================

  static Future<List<Map<String, dynamic>>>
      getMyBloodRequests() async {
    final token = await _requireToken();

    final response = await http
        .get(
          Uri.parse('$baseUrl/my-blood-requests'),
          headers: _headers(token: token),
        )
        .timeout(_timeout);

    final data = _decodeResponse(response.body);

    if (response.statusCode == 200 &&
        data['success'] == true) {
      final requests = data['requests'];

      if (requests is! List) {
        throw Exception(
          'The server returned an invalid request list.',
        );
      }

      return requests
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(item),
          )
          .toList();
    }

    if (response.statusCode == 401) {
      await clearToken();
      _checkUnauthorized(response.statusCode);
    }

    throw Exception(
      data['message']?.toString() ??
          'Unable to load your blood requests.',
    );
  }

  // =========================================================
  // GET ACTIVE DONORS
  // =========================================================

  static Future<List<BloodDonor>> getActiveDonors() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/donors'),
          headers: _headers(),
        )
        .timeout(_timeout);

    final data = _decodeResponse(response.body);

    if (response.statusCode == 200 &&
        data['success'] == true) {
      final donors = data['donors'];

      if (donors is! List) {
        throw Exception(
          'The server returned an invalid donor list.',
        );
      }

      return donors
          .whereType<Map>()
          .map(
            (donor) => BloodDonor.fromJson(
              Map<String, dynamic>.from(donor),
            ),
          )
          .toList();
    }

    throw Exception(
      data['message']?.toString() ??
          'Could not load active donors.',
    );
  }

  // =========================================================
  // GET PUBLISHED BLOOD DRIVE EVENTS
  // Public event list.
  // =========================================================

  static Future<List<Map<String, dynamic>>>
      getPublishedBloodDriveEvents() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/blood-drive-events'),
          headers: _headers(),
        )
        .timeout(_timeout);

    final data = _decodeResponse(response.body);

    if (response.statusCode == 200 &&
        data['success'] == true) {
      final events = data['events'];

      if (events is! List) {
        throw Exception(
          'The server returned an invalid event list.',
        );
      }

      return events
          .whereType<Map>()
          .map(
            (event) => Map<String, dynamic>.from(event),
          )
          .toList();
    }

    throw Exception(
      data['message']?.toString() ??
          'Unable to load published blood drive events.',
    );
  }

  // =========================================================
  // GET MY UPCOMING BLOOD DRIVE EVENTS
  // Requires an authenticated Laravel endpoint.
  // GET /api/my-upcoming-blood-drive-events
  // =========================================================

  static Future<List<Map<String, dynamic>>>
      getMyUpcomingBloodDriveEvents() async {
    final token = await _requireToken();

    final response = await http
        .get(
          Uri.parse(
            '$baseUrl/my-upcoming-blood-drive-events',
          ),
          headers: _headers(token: token),
        )
        .timeout(_timeout);

    final data = _decodeResponse(response.body);

    if (response.statusCode == 200 &&
        data['success'] == true) {
      final events = data['events'] ?? data['data'];

      if (events is! List) {
        throw Exception(
          'The server returned an invalid upcoming event list.',
        );
      }

      return events
          .whereType<Map>()
          .map(
            (event) => Map<String, dynamic>.from(event),
          )
          .toList();
    }

    if (response.statusCode == 401) {
      await clearToken();
      _checkUnauthorized(response.statusCode);
    }

    throw Exception(
      data['message']?.toString() ??
          'Unable to load your upcoming blood drive events.',
    );
  }

  // =========================================================
  // CREATE A REGULAR APPOINTMENT
  // POST /api/appointments
  // =========================================================

  static Future<Map<String, dynamic>> createAppointment({
    required String center,
    required String appointmentDate,
    required String appointmentTime,
    String? notes,
  }) async {
    final token = await _requireToken();

    final response = await http
        .post(
          Uri.parse('$baseUrl/appointments'),
          headers: _jsonHeaders(token: token),
          body: jsonEncode({
            'center': center,
            'appointment_date': appointmentDate,
            'appointment_time': appointmentTime,
            if (notes != null && notes.trim().isNotEmpty)
              'notes': notes.trim(),
          }),
        )
        .timeout(_timeout);

    final data = _decodeResponse(response.body);

    if (response.statusCode == 201 &&
        data['success'] == true) {
      return data;
    }

    if (response.statusCode == 401) {
      await clearToken();
      _checkUnauthorized(response.statusCode);
    }

    if (response.statusCode == 409 ||
        response.statusCode == 422) {
      throw Exception(_validationMessage(data));
    }

    throw Exception(
      data['message']?.toString() ??
          'Unable to submit your appointment.',
    );
  }

  // =========================================================
  // GET MY REGULAR APPOINTMENTS
  // GET /api/my-appointments
  // =========================================================

  static Future<List<Map<String, dynamic>>>
      getMyAppointments() async {
    final token = await _requireToken();

    final response = await http
        .get(
          Uri.parse('$baseUrl/my-appointments'),
          headers: _headers(token: token),
        )
        .timeout(_timeout);

    final data = _decodeResponse(response.body);

    if (response.statusCode == 200 &&
        data['success'] == true) {
      final appointments = data['appointments'];

      if (appointments is! List) {
        throw Exception(
          'The server returned an invalid appointment list.',
        );
      }

      return appointments
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(item),
          )
          .toList();
    }

    if (response.statusCode == 401) {
      await clearToken();
      _checkUnauthorized(response.statusCode);
    }

    throw Exception(
      data['message']?.toString() ??
          'Unable to load your appointments.',
    );
  }

  // =========================================================
  // GET MY BLOOD DRIVE EVENT REGISTRATIONS
  // Requires an authenticated Laravel endpoint.
  // GET /api/my-blood-drive-event-registrations
  // =========================================================

  static Future<List<Map<String, dynamic>>>
      getMyBloodDriveEventRegistrations() async {
    final token = await _requireToken();

    final response = await http
        .get(
          Uri.parse(
            '$baseUrl/my-blood-drive-event-registrations',
          ),
          headers: _headers(token: token),
        )
        .timeout(_timeout);

    final data = _decodeResponse(response.body);

    if (response.statusCode == 200 &&
        data['success'] == true) {
      final registrations =
          data['registrations'] ?? data['data'];

      if (registrations is! List) {
        throw Exception(
          'The server returned an invalid event registration list.',
        );
      }

      return registrations
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(item),
          )
          .toList();
    }

    if (response.statusCode == 401) {
      await clearToken();
      _checkUnauthorized(response.statusCode);
    }

    throw Exception(
      data['message']?.toString() ??
          'Unable to load your event registrations.',
    );
  }
  // =========================================================
  // REGISTER FOR A BLOOD DRIVE EVENT
  // POST /api/blood-drive-events/{id}/register
  // =========================================================

  static Future<Map<String, dynamic>> registerForBloodDriveEvent({
    required int eventId,
  }) async {
    final token = await _requireToken();

    final response = await http
        .post(
          Uri.parse(
            '$baseUrl/blood-drive-events/$eventId/register',
          ),
          headers: _jsonHeaders(token: token),
        )
        .timeout(_timeout);

    final data = _decodeResponse(response.body);

    if ((response.statusCode == 200 ||
            response.statusCode == 201) &&
        data['success'] == true) {
      return data;
    }

    if (response.statusCode == 401) {
      await clearToken();
      _checkUnauthorized(response.statusCode);
    }

    if (response.statusCode == 409 ||
        response.statusCode == 422) {
      throw Exception(_validationMessage(data));
    }

    throw Exception(
      data['message']?.toString() ??
          'Unable to register for this blood drive event.',
    );
  }
  // =========================================================
  // LOGOUT
  // =========================================================

  static Future<void> logout() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      await clearToken();
      return;
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/logout'),
            headers: _headers(token: token),
          )
          .timeout(_timeout);

      if (response.statusCode == 401) {
        return;
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          'Could not log out from the server.',
        );
      }
    } finally {
      // Always remove the local token, even if the
      // server cannot be reached.
      await clearToken();
    }
  }

  // =========================================================
  // SHARED RESPONSE HELPERS
  // Keep exactly one copy of each helper in this class.
  // =========================================================

  static Map<String, dynamic> _decodeResponse(
    String body,
  ) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      throw Exception(
        'The server returned an unexpected response format.',
      );
    } on FormatException {
      throw Exception(
        'The server returned an invalid response. '
        'Check the API URL and Laravel server.',
      );
    } on TypeError {
      throw Exception(
        'The server response contains invalid data.',
      );
    }
  }

  static String _validationMessage(
    Map<String, dynamic> data,
  ) {
    final errors = data['errors'];

    if (errors is Map) {
      final messages = <String>[];

      for (final value in errors.values) {
        if (value is List) {
          messages.addAll(
            value.map((message) => message.toString()),
          );
        } else if (value != null) {
          messages.add(value.toString());
        }
      }

      if (messages.isNotEmpty) {
        return messages.join('\n');
      }
    }

    return data['message']?.toString() ??
        'Please check your submitted details.';
  }
    // =========================================================
  // GET OPEN DONATION CENTERS
  // =========================================================

  static Future<List<Map<String, dynamic>>>
      getOpenDonationCenters() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/donation-centers'),
          headers: _headers(),
        )
        .timeout(_timeout);

    final data = _decodeResponse(response.body);

    if (response.statusCode == 200 &&
        data['success'] == true) {
      final centers = data['centers'];

      if (centers is! List) {
        throw Exception(
          'The server returned an invalid donation center list.',
        );
      }

      return centers
          .whereType<Map>()
          .map(
            (center) => Map<String, dynamic>.from(center),
          )
          .toList();
    }

    throw Exception(
      data['message']?.toString() ??
          'Unable to load donation centers.',
    );
  }
}
