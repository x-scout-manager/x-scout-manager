import '../data/send_queue_functions_repository.dart';

class CreateSendQueue {
  const CreateSendQueue(this._repository);

  final SendQueueFunctionsRepository _repository;

  Future<String> call(List<String> candidateIds) {
    return _repository.createSendQueue(candidateIds);
  }
}
