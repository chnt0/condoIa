import '../../../core/constants/api_constants.dart';
import '../../../shared/services/api_client.dart';
import '../models/confirmar_pago_request.dart';
import '../models/create_cuota_request.dart';
import '../models/cuota_response.dart';
import '../models/cuota_usuario_response.dart';
import '../models/reportar_pago_request.dart';

class CuotaService {
  final ApiClient apiClient;

  CuotaService({required this.apiClient});

  Future<List<CuotaResponse>> listarCuotas() async {
    final response = await apiClient.getList(ApiConstants.cuotas);
    return response
        .map((item) => CuotaResponse.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<CuotaResponse> crearCuota(CreateCuotaRequest request) async {
    final response = await apiClient.post(ApiConstants.cuotas, request.toJson());
    return CuotaResponse.fromJson(response);
  }

  Future<List<CuotaUsuarioResponse>> listarMisCuotas() async {
    final response = await apiClient.getList(ApiConstants.misCuotas);
    return response
        .map((item) => CuotaUsuarioResponse.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<CuotaUsuarioResponse>> obtenerDetalle(int cuotaId) async {
    final response = await apiClient.getList(ApiConstants.cuotaDetalle(cuotaId));
    return response
        .map((item) => CuotaUsuarioResponse.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<CuotaUsuarioResponse> reportarPago(
      int cuotaUsuarioId, ReportarPagoRequest request) async {
    final response = await apiClient.put(
        ApiConstants.reportarPago(cuotaUsuarioId), request.toJson());
    return CuotaUsuarioResponse.fromJson(response);
  }

  Future<CuotaUsuarioResponse> confirmarPago(
      int cuotaUsuarioId, ConfirmarPagoRequest request) async {
    final response = await apiClient.put(
        ApiConstants.confirmarPago(cuotaUsuarioId), request.toJson());
    return CuotaUsuarioResponse.fromJson(response);
  }
}
