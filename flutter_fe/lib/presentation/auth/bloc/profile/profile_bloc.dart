import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/datasources/auth_datasource.dart';
import '../../../../data/datasources/auth_remote_datasource.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final AuthDatasource _authDatasource;

  ProfileBloc({
    AuthDatasource? authDatasource,
  })  : _authDatasource = authDatasource ?? AuthRemoteDatasource(),
        super(ProfileInitial()) {
    on<GetProfile>(_onGetProfile);
    on<RefreshProfile>(_onRefreshProfile);
  }

  Future<void> _onGetProfile(
    GetProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    await _fetchProfile(emit);
  }

  Future<void> _onRefreshProfile(
    RefreshProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    await _fetchProfile(emit);
  }

  Future<void> _fetchProfile(Emitter<ProfileState> emit) async {
    final result = await _authDatasource.getProfile();

    result.fold(
      (error) => emit(ProfileError(error)),
      (data) => emit(ProfileLoaded(data.$1, company: data.$2)),
    );
  }
}
