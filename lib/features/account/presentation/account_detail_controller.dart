import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../capital/domain/allocation.dart';
import '../../capital/presentation/capital_controller.dart';
import '../../plans/data/projection_repository.dart';
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
}

final accountDetailControllerProvider = NotifierProvider.autoDispose
    .family<AccountDetailController, AccountDetailState, String>(
      AccountDetailController.new,
    );

final accountProjectionProvider = FutureProvider.autoDispose
    .family<List<CompoundInterestPeriodResult>, String>((
      ref,
      allocationId,
    ) async {
      final overview = await ref.watch(capitalControllerProvider.future);
      final matching = overview.allocations.where((a) => a.id == allocationId);
      if (matching.isEmpty) return const [];
      final Allocation allocation = matching.first;

      final state = ref.watch(accountDetailControllerProvider(allocationId));
      if (allocation.investmentPlanId == null ||
          allocation.initialDeposit <= 0) {
        return const [];
      }

      final creationDate = allocation.createdAt ?? DateTime.now();

      final series = await ref
          .read(projectionRepositoryProvider)
          .getProjection(
            planId: allocation.investmentPlanId!,
            baseAmount: allocation.initialDeposit.toDouble(),
            startDate: creationDate,
            grouping: state.grouping,
          );

      return _applyDrillDownFilter(series, state, creationDate);
    });

List<CompoundInterestPeriodResult> _applyDrillDownFilter(
  List<CompoundInterestPeriodResult> rawPeriods,
  AccountDetailState state,
  DateTime creationDate,
) {
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

  var filtered = rawPeriods;
  if (filterStart != null) {
    final start = filterStart;
    filtered = filtered
        .where((p) => p.date.isAfter(start) || p.date.isAtSameMomentAs(start))
        .toList();
  }
  if (filterEnd != null) {
    final end = filterEnd;
    filtered = filtered
        .where((p) => p.date.isBefore(end) || p.date.isAtSameMomentAs(end))
        .toList();
  }

  return List.generate(filtered.length, (index) {
    final p = filtered[index];
    return CompoundInterestPeriodResult(
      periodIndex: index + 1,
      label: p.label,
      startBalance: p.startBalance,
      yieldAmount: p.yieldAmount,
      endBalance: p.endBalance,
      date: p.date,
    );
  });
}
