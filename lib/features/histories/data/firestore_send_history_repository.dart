import 'send_history_repository.dart';
import '../model/send_history.dart';

class FirestoreSendHistoryRepository implements SendHistoryRepository {
  const FirestoreSendHistoryRepository();

  @override
  Stream<List<SendHistory>> watchHistories() {
    return const Stream.empty();
  }
}
