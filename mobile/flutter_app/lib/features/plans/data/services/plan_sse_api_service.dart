import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

// ---------------------------------------------------------------------------
// Sealed event hierarchy
// ---------------------------------------------------------------------------

abstract class PlanGenerationEvent {}

class PlanGenerationProgress extends PlanGenerationEvent {
  final String label;
  final int pct;

  PlanGenerationProgress(this.label, this.pct);
}

class PlanGenerationDone extends PlanGenerationEvent {
  final Map<String, dynamic> plan;

  PlanGenerationDone(this.plan);
}

class PlanGenerationError extends PlanGenerationEvent {
  final String message;

  PlanGenerationError(this.message);
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class PlanSseApiService {
  final String baseUrl;
  final String accessToken;

  const PlanSseApiService({required this.baseUrl, required this.accessToken});

  /// Connects to the SSE endpoint and yields [PlanGenerationEvent]s.
  Stream<PlanGenerationEvent> streamGeneration() async* {
    final client = http.Client();
    try {
      final request = http.Request(
        'GET',
        Uri.parse('$baseUrl/api/v1/plans/generate-stream'),
      );
      request.headers[HttpHeaders.authorizationHeader] =
          'Bearer $accessToken';
      request.headers[HttpHeaders.acceptHeader] = 'text/event-stream';

      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 90));

      await for (final line in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (line.startsWith('data: ')) {
          final jsonStr = line.substring(6).trim();
          if (jsonStr.isEmpty) continue;
          try {
            final data = json.decode(jsonStr) as Map<String, dynamic>;
            final step = data['step'] as String? ?? '';
            if (step == 'progress') {
              yield PlanGenerationProgress(
                data['label'] as String? ?? '...',
                (data['pct'] as num?)?.toInt() ?? 0,
              );
            } else if (step == 'done') {
              yield PlanGenerationDone(
                data['plan'] as Map<String, dynamic>? ?? {},
              );
              return;
            } else if (step == 'error') {
              yield PlanGenerationError(
                data['message'] as String? ?? 'Error desconocido',
              );
              return;
            }
          } catch (_) {
            // skip malformed line
          }
        }
      }
    } catch (e) {
      yield PlanGenerationError(e.toString());
    } finally {
      client.close();
    }
  }
}
