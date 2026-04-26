import 'package:atlas/features/home/domain/usecases/get_hot_places_usecase.dart';
import 'package:atlas/features/home/domain/usecases/sync_hot_places_usecase.dart';
import 'package:atlas/features/home/presentation/bloc/hot_places_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HotPlacesCubit extends Cubit<HotPlacesState> {
  final GetHotPlacesUseCase _getHotPlaces;
  final SyncHotPlacesUseCase _syncHotPlaces;

  HotPlacesCubit({
    required GetHotPlacesUseCase getHotPlaces,
    required SyncHotPlacesUseCase syncHotPlaces,
  }) : _getHotPlaces = getHotPlaces,
       _syncHotPlaces = syncHotPlaces,
       super(HotPlacesInitial());

  Future<void> loadHotPlaces() async {
    emit(HotPlacesLoading());
    await _syncHotPlaces();
    final result = await _getHotPlaces();
    result.fold(
      (error) => emit(HotPlacesError(error.message)),
      (places) => emit(HotPlacesLoaded(places: places)),
    );
  }

  Future<void> reload() async {
    final current = state;
    if (current is HotPlacesError) {
      emit(HotPlacesError(current.message, isReloading: true));
    }
    await loadHotPlaces();
  }
}
