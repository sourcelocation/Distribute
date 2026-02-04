import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_response.freezed.dart';
part 'login_response.g.dart';

@freezed
abstract class LoginResponse with _$LoginResponse {
  factory LoginResponse({
    required String token,
    required String username,
    required String id,
    required LoginUserDetailResponse user,
  }) = _LoginResponse;

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);
}

@freezed
abstract class LoginUserDetailResponse with _$LoginUserDetailResponse {
  factory LoginUserDetailResponse({
    @JsonKey(name: 'root_folder_id') String? rootFolderId,
    @JsonKey(name: 'is_admin') @Default(false) bool isAdmin,
  }) = _LoginUserDetailResponse;

  factory LoginUserDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginUserDetailResponseFromJson(json);
}
