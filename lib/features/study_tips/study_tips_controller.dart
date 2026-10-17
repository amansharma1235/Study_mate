import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/study_tip_model.dart';
import '../../data/repositories/study_tips_repository.dart';

final selectedTipCategoryProvider = StateProvider<String>((ref) => 'All');

final studyTipsControllerProvider =
    StateNotifierProvider<StudyTipsController, AsyncValue<List<StudyTipModel>>>(
      (ref) {
        final repo = ref.watch(studyTipsRepositoryProvider);
        return StudyTipsController(repo);
      },
    );

final filteredTipsProvider = Provider<List<StudyTipModel>>((ref) {
  final tipsState = ref.watch(studyTipsControllerProvider);
  final category = ref.watch(selectedTipCategoryProvider);

  return tipsState.maybeWhen(
    data: (tips) {
      if (category == 'All') return tips;
      return tips.where((t) => t.category == category).toList();
    },
    orElse: () => [],
  );
});

final savedTipsProvider = FutureProvider<List<StudyTipModel>>((ref) async {
  final repo = ref.watch(studyTipsRepositoryProvider);
  return await repo.getSavedTips();
});

class StudyTipsController
    extends StateNotifier<AsyncValue<List<StudyTipModel>>> {
  final StudyTipsRepository _repo;

  StudyTipsController(this._repo) : super(const AsyncValue.loading()) {
    loadTips();
  }

  Future<void> loadTips() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async => await _repo.getAllTips());
  }

  Future<void> toggleFavorite(StudyTipModel tip) async {
    await _repo.toggleFavorite(tip);
    await loadTips();
  }
}
