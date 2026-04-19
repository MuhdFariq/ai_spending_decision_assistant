import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  // Step 4: Create the instance as a private variable
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Getter to use in MaterialApp for screen tracking
  FirebaseAnalyticsObserver getAnalyticsObserver() =>
      FirebaseAnalyticsObserver(analytics: _analytics);
}
