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

  static Map<String, String>? parseResponseSections(String responseText) {
    final text = responseText.trim();
    if (text.isEmpty) return null;

    final answer = _extractSection(
      source: text,
      labelPattern: RegExp(r'answer\s*:', caseSensitive: false),
      nextLabelsPattern: RegExp(
        r'(reason\s*:|based\s*on\s*:)',
        caseSensitive: false,
      ),
    );

    final reason = _extractSection(
      source: text,
      labelPattern: RegExp(r'reason\s*:', caseSensitive: false),
      nextLabelsPattern: RegExp(
        r'(answer\s*:|based\s*on\s*:)',
        caseSensitive: false,
      ),
    );

    final basedOn = _extractSection(
      source: text,
      labelPattern: RegExp(r'based\s*on\s*:', caseSensitive: false),
      nextLabelsPattern: RegExp(
        r'(answer\s*:|reason\s*:)',
        caseSensitive: false,
      ),
    );

    if (answer == null || reason == null || basedOn == null) return null;

    return {
      'answer': answer,
      'reason': reason,
      'basedOn': basedOn,
    };
  }

  static String? _extractSection({
    required String source,
    required RegExp labelPattern,
    required RegExp nextLabelsPattern,
  }) {
    final labelMatch = labelPattern.firstMatch(source);
    if (labelMatch == null) return null;

    final start = labelMatch.end;
    final remaining = source.substring(start);
    final nextMatch = nextLabelsPattern.firstMatch(remaining);

    final value = nextMatch == null
        ? remaining.trim()
        : remaining.substring(0, nextMatch.start).trim();

    return value.isEmpty ? null : value;
  }
}