import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/api_error.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final ApiError? apiError;

  ApiException(this.message, {this.statusCode, this.apiError});

  @override
  String toString() => message;
}

class ApiClient {
  final String baseUrl;
  final Duration timeout;
  String? _token;

  ApiClient({
    required this.baseUrl,
    this.timeout = ApiConstants.defaultTimeout,
  });

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> _getHeaders({Map<String, String>? additionalHeaders}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http
          .post(
            url,
            headers: _getHeaders(additionalHeaders: headers),
            body: jsonEncode(body),
          )
          .timeout(timeout);

      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(
        'La solicitud tardó demasiado tiempo. Por favor, intente nuevamente.',
        statusCode: 408,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Error de conexión. Verifique su internet e intente nuevamente.',
      );
    }
  }

  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) async {
    try {
      var url = Uri.parse('$baseUrl$endpoint');
      if (queryParameters != null && queryParameters.isNotEmpty) {
        url = url.replace(queryParameters: queryParameters);
      }

      final response = await http
          .get(
            url,
            headers: _getHeaders(additionalHeaders: headers),
          )
          .timeout(timeout);

      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(
        'La solicitud tardó demasiado tiempo. Por favor, intente nuevamente.',
        statusCode: 408,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Error de conexión. Verifique su internet e intente nuevamente.',
      );
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        throw ApiException(
          'Error al procesar la respuesta del servidor.',
          statusCode: statusCode,
        );
      }
    }

    // Handle error responses
    ApiError? apiError;
    try {
      if (response.body.isNotEmpty) {
        final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
        apiError = ApiError.fromJson(errorJson);
      }
    } catch (e) {
      // If we can't parse the error, continue with generic message
    }

    final errorMessage = apiError?.message ?? _getDefaultErrorMessage(statusCode);

    throw ApiException(
      errorMessage,
      statusCode: statusCode,
      apiError: apiError,
    );
  }

  String _getDefaultErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Solicitud inválida. Verifique los datos ingresados.';
      case 401:
        return 'No autorizado. Por favor, inicie sesión nuevamente.';
      case 403:
        return 'No tiene permisos para realizar esta acción.';
      case 404:
        return 'Recurso no encontrado.';
      case 500:
        return 'Error interno del servidor. Intente más tarde.';
      case 503:
        return 'Servicio no disponible. Intente más tarde.';
      default:
        return 'Error del servidor (código: $statusCode).';
    }
  }
}
