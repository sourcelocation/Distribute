import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
abstract class LoggedInUser with _$LoggedInUser {
  factory LoggedInUser({
    @Default('') String id,
    @Default('') String username,
    @Default('') String token,
    String? rootFolderId,
  }) = _LoggedInUser;

  factory LoggedInUser.fromJson(Map<String, dynamic> json) =>
      _$LoggedInUserFromJson(json);
}
