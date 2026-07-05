import 'package:equatable/equatable.dart';

class ParsedEvent extends Equatable {
  const ParsedEvent({
    required this.title,
    required this.dateTime,
    this.location,
    required this.hasExplicitDate,
    required this.hasExplicitTime,
    required this.sourceText,
  });

  final String title;
  final DateTime dateTime;
  final String? location;
  final bool hasExplicitDate;
  final bool hasExplicitTime;
  final String sourceText;

  ParsedEvent copyWith({
    String? title,
    DateTime? dateTime,
    String? location,
    bool? hasExplicitDate,
    bool? hasExplicitTime,
    String? sourceText,
  }) {
    return ParsedEvent(
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      hasExplicitDate: hasExplicitDate ?? this.hasExplicitDate,
      hasExplicitTime: hasExplicitTime ?? this.hasExplicitTime,
      sourceText: sourceText ?? this.sourceText,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        title,
        dateTime,
        location,
        hasExplicitDate,
        hasExplicitTime,
        sourceText,
      ];
}
