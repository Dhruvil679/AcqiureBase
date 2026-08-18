import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

// Calls user-facing Firebase Cloud Functions for projects. Rate limiting and
// view counters live on the server so users can't game them from the client.
//
// When Cloud Functions aren't deployed yet (e.g. still on the Spark plan), the
// non-admin methods fall back to permissive defaults so the rest of the app
// keeps working. Admin-only functions don't get client fallbacks because their
// security rules intentionally block direct client writes.
class ProjectFunctionsService {
  const ProjectFunctionsService(this._functions);

  final FirebaseFunctions _functions;

  HttpsCallable get _checkProjectSubmissionRate =>
      _functions.httpsCallable('checkProjectSubmissionRate');
  HttpsCallable get _recordProjectSubmission =>
      _functions.httpsCallable('recordProjectSubmission');
  HttpsCallable get _incrementProjectView =>
      _functions.httpsCallable('incrementProjectView');

  // Checks whether the user can submit another project within the 24h window.
  // If the Cloud Function isn't reachable (not deployed, offline, etc.) we
  // default to allowed so project creation isn't blocked in dev/demo mode.
  Future<SubmissionRateStatus> checkProjectSubmissionRate() async {
    try {
      final result = await _checkProjectSubmissionRate.call();
      final data = result.data as Map<String, dynamic>? ?? {};
      return SubmissionRateStatus(
        allowed: data['allowed'] as bool? ?? false,
        remaining: (data['remaining'] as num?)?.toInt() ?? 0,
        resetAt: data['resetAt'] as String?,
      );
    } on FirebaseFunctionsException catch (e) {
      _logFunctionFallback('checkProjectSubmissionRate', e);
      return const SubmissionRateStatus(allowed: true, remaining: 1);
    } on Exception catch (e) {
      _logFunctionFallback('checkProjectSubmissionRate', e);
      return const SubmissionRateStatus(allowed: true, remaining: 1);
    }
  }

  // Records a project submission in the sliding rate-limit window.
  // We swallow errors here because the project is already created; missing a
  // rate-limit record is fine in demo mode.
  Future<void> recordProjectSubmission() async {
    try {
      await _recordProjectSubmission.call();
    } on FirebaseFunctionsException catch (e) {
      _logFunctionFallback('recordProjectSubmission', e);
    } on Exception catch (e) {
      _logFunctionFallback('recordProjectSubmission', e);
    }
  }

  // Increments the view counter for [projectId] with a server-side cooldown.
  // Errors are swallowed so viewing a project never breaks when the backend
  // function isn't deployed.
  Future<void> incrementProjectView({required String projectId}) async {
    try {
      await _incrementProjectView.call({'projectId': projectId});
    } on FirebaseFunctionsException catch (e) {
      _logFunctionFallback('incrementProjectView', e);
    } on Exception catch (e) {
      _logFunctionFallback('incrementProjectView', e);
    }
  }

  void _logFunctionFallback(String name, Exception error) {
    if (kDebugMode) {
      debugPrint(
        'Cloud Function "$name" unavailable (likely not deployed). '
        'Using fallback. Error: $error',
      );
    }
  }
}

class SubmissionRateStatus {
  const SubmissionRateStatus({
    required this.allowed,
    required this.remaining,
    this.resetAt,
  });

  final bool allowed;
  final int remaining;
  final String? resetAt;
}
