import '../models/user.dart';
import '../repositories/user_repository.dart';
import 'api_client.dart';
import 'api_mappers.dart';

class ApiUserRepository implements UserRepository {
  ApiUserRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<AppUser>> fetchUsers() async {
    final data = await _api.call('GET', '/api/users') as List<dynamic>;
    return [for (final e in data) userFromJson(e as Map<String, dynamic>)];
  }

  @override
  Future<AppUser> save(
    AppUser user, {
    String? password,
    required bool isNew,
  }) async {
    final body = {
      'userId': user.id,
      if (password != null && password.isNotEmpty) 'password': password,
      'userName': user.name,
      'role': roleToServer(user.role),
      'major': user.major,
      'active': user.active,
    };
    final data = isNew
        ? await _api.call('POST', '/api/users', body: body)
        : await _api.call(
            'PUT',
            '/api/users/${Uri.encodeComponent(user.id)}',
            body: body,
          );
    return userFromJson(data as Map<String, dynamic>);
  }
}
