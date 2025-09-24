// States
import 'package:equatable/equatable.dart';
import 'package:infinity_notes/services/cloud/cloud_note.dart';

abstract class SummarizationState extends Equatable {}

class SummarizationInitial extends SummarizationState {
  @override
  // TODO: implement props
  List<Object?> get props => throw UnimplementedError();
}

class SummarizationLoading extends SummarizationState {
  final double? progress;
  SummarizationLoading({this.progress});

  @override
  // TODO: implement props
  List<Object?> get props => throw UnimplementedError();
}

class SummarizationSuccess extends SummarizationState {
  final String summary;
  final CloudNote originalNote;
  SummarizationSuccess({required this.summary, required this.originalNote});

  @override
  // TODO: implement props
  List<Object?> get props => throw UnimplementedError();
}

class SummarizationError extends SummarizationState {
  final String error;
  SummarizationError(this.error);

  @override
  // TODO: implement props
  List<Object?> get props => throw UnimplementedError();
}
