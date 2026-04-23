import '../models/expenses.dart';

enum SpendingRiskLevel { safe, warning, overspending }

class DashboardMetrics {
	const DashboardMetrics({
		required this.monthlyBudget,
		required this.totalSpent,
		required this.remainingBudget,
		required this.projectedEndBalance,
		required this.projectedMonthEndSpend,
		required this.dailyAverageSpend,
		required this.daysUntilDepleted,
		required this.categorySpending,
		required this.riskLevel,
		required this.forecastMessage,
		required this.monthExpenses,
	});

	final double monthlyBudget;
	final double totalSpent;
	final double remainingBudget;
	final double projectedEndBalance;
	final double projectedMonthEndSpend;
	final double dailyAverageSpend;
	final int? daysUntilDepleted;
	final Map<String, double> categorySpending;
	final SpendingRiskLevel riskLevel;
	final String forecastMessage;
	final List<Expense> monthExpenses;
}

class BudgetService {
	static const double defaultMonthlyBudget = 2000;
	static const List<String> supportedCategories = <String>[
		'Food',
		'Transport',
		'Shopping',
		'Bills',
		'Others',
	];

	static DashboardMetrics buildDashboardMetrics(
		List<Expense> expenses, {
		double monthlyBudget = defaultMonthlyBudget,
		DateTime? now,
	}) {
		final DateTime referenceDate = now ?? DateTime.now();
		final List<Expense> monthExpenses = getCurrentMonthExpenses(
			expenses,
			now: referenceDate,
		);
		final double totalSpent = getTotalSpentThisMonth(
			expenses,
			now: referenceDate,
		);
		final double remainingBudget = getRemainingBudget(
			expenses,
			monthlyBudget: monthlyBudget,
			now: referenceDate,
		);
		final double projectedMonthEndSpend = getProjectedMonthEndSpend(
			expenses,
			now: referenceDate,
		);
		final double projectedEndBalance = getProjectedEndBalance(
			expenses,
			monthlyBudget: monthlyBudget,
			now: referenceDate,
		);
		final double dailyAverageSpend = getDailyAverageSpend(
			expenses,
			now: referenceDate,
		);
		final int? daysUntilDepleted = getDaysUntilDepleted(
			expenses,
			monthlyBudget: monthlyBudget,
			now: referenceDate,
		);
		final Map<String, double> categorySpending = getSpendingByCategory(
			expenses,
			now: referenceDate,
		);
		final SpendingRiskLevel riskLevel = getRiskLevel(
			expenses,
			monthlyBudget: monthlyBudget,
			now: referenceDate,
		);

		return DashboardMetrics(
			monthlyBudget: monthlyBudget,
			totalSpent: totalSpent,
			remainingBudget: remainingBudget,
			projectedEndBalance: projectedEndBalance,
			projectedMonthEndSpend: projectedMonthEndSpend,
			dailyAverageSpend: dailyAverageSpend,
			daysUntilDepleted: daysUntilDepleted,
			categorySpending: categorySpending,
			riskLevel: riskLevel,
			forecastMessage: buildForecastMessage(
				projectedEndBalance: projectedEndBalance,
				daysUntilDepleted: daysUntilDepleted,
				riskLevel: riskLevel,
			),
			monthExpenses: monthExpenses,
		);
	}

	static List<Expense> getCurrentMonthExpenses(
		List<Expense> expenses, {
		DateTime? now,
	}) {
		final DateTime referenceDate = now ?? DateTime.now();
		return expenses.where((Expense expense) {
			return expense.date.year == referenceDate.year &&
					expense.date.month == referenceDate.month;
		}).toList();
	}

	static double getTotalSpentThisMonth(
		List<Expense> expenses, {
		DateTime? now,
	}) {
		return getCurrentMonthExpenses(expenses, now: now).fold<double>(
			0,
			(double total, Expense expense) => total + expense.amount,
		);
	}

	static double getRemainingBudget(
		List<Expense> expenses, {
		double monthlyBudget = defaultMonthlyBudget,
		DateTime? now,
	}) {
		return monthlyBudget - getTotalSpentThisMonth(expenses, now: now);
	}

	static Map<String, double> getSpendingByCategory(
		List<Expense> expenses, {
		DateTime? now,
	}) {
		final Map<String, double> totals = <String, double>{
			for (final String category in supportedCategories) category: 0,
		};

		for (final Expense expense in getCurrentMonthExpenses(expenses, now: now)) {
			totals.update(
				expense.category,
				(double current) => current + expense.amount,
				ifAbsent: () => expense.amount,
			);
		}

		return totals;
	}

	static double getDailyAverageSpend(
		List<Expense> expenses, {
		DateTime? now,
	}) {
		final DateTime referenceDate = now ?? DateTime.now();
		final int daysPassed = referenceDate.day;
		if (daysPassed <= 0) {
			return 0;
		}

		return getTotalSpentThisMonth(expenses, now: referenceDate) / daysPassed;
	}

	static double getProjectedMonthEndSpend(
		List<Expense> expenses, {
		DateTime? now,
	}) {
		final DateTime referenceDate = now ?? DateTime.now();
		final double dailyAverageSpend = getDailyAverageSpend(
			expenses,
			now: referenceDate,
		);
		return dailyAverageSpend * _daysInMonth(referenceDate);
	}

	static double getProjectedEndBalance(
		List<Expense> expenses, {
		double monthlyBudget = defaultMonthlyBudget,
		DateTime? now,
	}) {
		return monthlyBudget - getProjectedMonthEndSpend(expenses, now: now);
	}

	static int? getDaysUntilDepleted(
		List<Expense> expenses, {
		double monthlyBudget = defaultMonthlyBudget,
		DateTime? now,
	}) {
		final DateTime referenceDate = now ?? DateTime.now();
		final double remainingBudget = getRemainingBudget(
			expenses,
			monthlyBudget: monthlyBudget,
			now: referenceDate,
		);

		if (remainingBudget <= 0) {
			return 0;
		}

		final double dailyAverageSpend = getDailyAverageSpend(
			expenses,
			now: referenceDate,
		);
		if (dailyAverageSpend <= 0) {
			return null;
		}

		final int daysRemainingInMonth = _daysInMonth(referenceDate) - referenceDate.day;
		final int projectedDays = (remainingBudget / dailyAverageSpend).floor();

		if (projectedDays > daysRemainingInMonth) {
			return null;
		}

		return projectedDays;
	}

	static SpendingRiskLevel getRiskLevel(
		List<Expense> expenses, {
		double monthlyBudget = defaultMonthlyBudget,
		DateTime? now,
	}) {
		if (monthlyBudget <= 0) {
			return SpendingRiskLevel.overspending;
		}

		final double projectedMonthEndSpend = getProjectedMonthEndSpend(
			expenses,
			now: now,
		);
		final double usageRatio = projectedMonthEndSpend / monthlyBudget;

		if (usageRatio >= 1) {
			return SpendingRiskLevel.overspending;
		}
		if (usageRatio >= 0.9) {
			return SpendingRiskLevel.warning;
		}
		return SpendingRiskLevel.safe;
	}

	static String buildForecastMessage({
		required double projectedEndBalance,
		required int? daysUntilDepleted,
		required SpendingRiskLevel riskLevel,
	}) {
		if (riskLevel == SpendingRiskLevel.overspending) {
			if (daysUntilDepleted != null) {
				return 'At this rate, you may exhaust your budget in $daysUntilDepleted day${daysUntilDepleted == 1 ? '' : 's'}.';
			}
			return 'At this rate, you are likely to exceed your budget before month end.';
		}

		if (riskLevel == SpendingRiskLevel.warning) {
			return 'You are close to your monthly limit. A few high-spend days could push you over budget.';
		}

		return 'You are on track to finish the month with RM${projectedEndBalance.toStringAsFixed(2)} remaining.';
	}

	static String getRiskLabel(SpendingRiskLevel riskLevel) {
		switch (riskLevel) {
			case SpendingRiskLevel.safe:
				return 'Safe';
			case SpendingRiskLevel.warning:
				return 'Warning';
			case SpendingRiskLevel.overspending:
				return 'Overspending';
		}
	}

	static int _daysInMonth(DateTime date) {
		final DateTime firstDayNextMonth = date.month == 12
				? DateTime(date.year + 1, 1, 1)
				: DateTime(date.year, date.month + 1, 1);
		return firstDayNextMonth.subtract(const Duration(days: 1)).day;
	}
}
