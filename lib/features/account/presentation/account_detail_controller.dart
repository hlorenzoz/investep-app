import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../capital/domain/allocation.dart';
import '../../plans/domain/compound_interest_calculator.dart';

class AccountDetailState {
  final CompoundInterestGrouping grouping;
  final DateTime? drillDownDate;
  final int activeTab; // 0: Registros, 1: Plan

  const AccountDetailState({
    this.grouping = CompoundInterestGrouping.monthly,
    this.drillDownDate,
    this.activeTab = 1,
  });

  AccountDetailState copyWith({
    CompoundInterestGrouping? grouping,
    DateTime? drillDownDate,
    int? activeTab,
    bool clearDrillDown = false,
  }) {
    return AccountDetailState(
      grouping: grouping ?? this.grouping,
      drillDownDate: clearDrillDown
          ? null
          : (drillDownDate ?? this.drillDownDate),
      activeTab: activeTab ?? this.activeTab,
    );
  }
}

class AccountDetailController extends Notifier<AccountDetailState> {
  AccountDetailController(this.allocationId);

  final String allocationId;

  @override
  AccountDetailState build() {
    return const AccountDetailState();
  }

  void setGrouping(CompoundInterestGrouping grouping) {
    state = state.copyWith(grouping: grouping, clearDrillDown: true);
  }

  void setTab(int tab) {
    state = state.copyWith(activeTab: tab);
  }

  void handleDrillDown(DateTime date) {
    if (state.grouping == CompoundInterestGrouping.yearly) {
      state = state.copyWith(
        grouping: CompoundInterestGrouping.monthly,
        drillDownDate: DateTime(date.year, 1, 1),
      );
    } else if (state.grouping == CompoundInterestGrouping.monthly) {
      state = state.copyWith(
        grouping: CompoundInterestGrouping.daily,
        drillDownDate: DateTime(date.year, date.month, 1),
      );
    } else if (state.grouping == CompoundInterestGrouping.weekly) {
      state = state.copyWith(
        grouping: CompoundInterestGrouping.daily,
        drillDownDate: date,
      );
    }
  }

  void clearDrillDown() {
    state = state.copyWith(
      grouping: CompoundInterestGrouping.monthly,
      clearDrillDown: true,
    );
  }

  List<CompoundInterestPeriodResult> getProjections(Allocation allocation) {
    final now = DateTime.now();
    final creationDate = allocation.createdAt ?? now;

    DateTime? filterStart;
    DateTime? filterEnd;

    if (state.drillDownDate != null) {
      final drillDate = state.drillDownDate!;
      if (state.grouping == CompoundInterestGrouping.monthly) {
        filterStart = DateTime(drillDate.year, 1, 1);
        filterEnd = DateTime(drillDate.year, 12, 31);
      } else if (state.grouping == CompoundInterestGrouping.daily) {
        filterStart = DateTime(drillDate.year, drillDate.month, 1);
        filterEnd = DateTime(drillDate.year, drillDate.month + 1, 0);
      }
    } else {
      filterStart = creationDate;
      if (state.grouping == CompoundInterestGrouping.daily ||
          state.grouping == CompoundInterestGrouping.weekly) {
        filterEnd = DateTime(
          creationDate.year + 1,
          creationDate.month,
          creationDate.day,
        );
      } else if (state.grouping == CompoundInterestGrouping.monthly) {
        filterEnd = DateTime(
          creationDate.year + 3,
          creationDate.month,
          creationDate.day,
        );
      } else if (state.grouping == CompoundInterestGrouping.yearly) {
        filterEnd = DateTime(
          creationDate.year + 5,
          creationDate.month,
          creationDate.day,
        );
      }
    }

    return CompoundInterestCalculator.calculate(
      baseAmount: allocation.initialDeposit.toDouble(),
      monthlyRatePct: allocation.targetMonthlyPct.toDouble(),
      grouping: state.grouping,
      accountCreationDate: creationDate,
      years: 5,
      filterStartDate: filterStart,
      filterEndDate: filterEnd,
    );
  }
}

final accountDetailControllerProvider = NotifierProvider.autoDispose
    .family<AccountDetailController, AccountDetailState, String>(
      AccountDetailController.new,
    );
