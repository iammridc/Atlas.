import 'dart:async';

class PlannedTripsSyncService {
  final _controller = StreamController<int>.broadcast();
  int _version = 0;

  Stream<int> get changes => _controller.stream;

  void notifyChanged() {
    _version += 1;
    _controller.add(_version);
  }
}
