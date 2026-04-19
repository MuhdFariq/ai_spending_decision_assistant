class ExplainabilityService {
  static String formatResponse({
    required String answer,
    required String reason,
    required String basedOn,
  }) {
    return 'Answer: $answer\n\n'
        'Reason: $reason\n\n'
        'Based on: $basedOn';
  }
}