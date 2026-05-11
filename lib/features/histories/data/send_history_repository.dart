import '../model/send_history.dart';

abstract interface class SendHistoryRepository {
  Stream<List<SendHistory>> watchHistories();
}
