import '../data/send_history_repository.dart';
import '../model/send_history.dart';

class LoadSendHistories {
  const LoadSendHistories(this._repository);

  final SendHistoryRepository _repository;

  Stream<List<SendHistory>> call() => _repository.watchHistories();
}
