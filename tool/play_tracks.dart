// Google Play Developer API 로 트랙 상태를 보고, 한 트랙의 활성 릴리스를 특정 versionCode 하나로 바꾼다.
//
//   dart run tool/play_tracks.dart --key <service-account.json> list
//   dart run tool/play_tracks.dart --key <service-account.json> set-track --track alpha --keep 13 [--status completed] [--commit]
//
// 인증: --key <서비스 계정 JSON> 또는 --token <OAuth 액세스 토큰> 또는 --proxy-auth(프록시가 Authorization 을 넣어 주는 환경).
// set-track 은 기본이 미리보기(dry-run)라 실제 반영하려면 --commit 을 붙인다. 커밋 전에 edits.validate 를 먼저 돌린다.
// 키 파일은 저장소에 두지 않는다 (.gitignore: *.json 은 아니므로 프로젝트 밖에 둘 것).
import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

const packageName = 'com.idealworld.recycle_ai';
const scope = 'https://www.googleapis.com/auth/androidpublisher';
const base = 'https://androidpublisher.googleapis.com/androidpublisher/v3/applications/$packageName';

Future<void> main(List<String> args) async {
  final opts = _parse(args);
  final cmd = opts['_cmd'];
  if (cmd == null) {
    stderr.writeln('사용법: play_tracks.dart (--key file.json | --token TOKEN | --proxy-auth) list | set-track --track <internal|alpha|beta|production> --keep <versionCode> [--status completed|draft] [--commit]');
    exit(2);
  }
  final client = await _client(opts);
  try {
    final editId = await _insertEdit(client);
    try {
      if (cmd == 'list') {
        await _list(client, editId);
      } else if (cmd == 'set-track') {
        await _setTrack(client, editId, opts);
      } else {
        stderr.writeln('모르는 명령: $cmd');
        exit(2);
      }
    } finally {
      // commit 되지 않은 edit 은 지운다 (set-track --commit 은 commit 뒤 delete 가 404 지만 무시).
      await client.delete(Uri.parse('$base/edits/$editId'));
    }
  } finally {
    client.close();
  }
}

Map<String, String?> _parse(List<String> args) {
  final m = <String, String?>{};
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a.startsWith('--')) {
      final next = i + 1 < args.length && !args[i + 1].startsWith('--') ? args[++i] : 'true';
      m[a.substring(2)] = next;
    } else {
      m['_cmd'] = a;
    }
  }
  return m;
}

Future<http.Client> _client(Map<String, String?> o) async {
  if (o['key'] != null) {
    final json = jsonDecode(File(o['key']!).readAsStringSync()) as Map<String, dynamic>;
    final creds = ServiceAccountCredentials.fromJson(json);
    return clientViaServiceAccount(creds, [scope]);
  }
  if (o['token'] != null) return _BearerClient(o['token']!);
  if (o['proxy-auth'] == 'true') return http.Client();
  stderr.writeln('인증 방법이 없어요: --key, --token, --proxy-auth 중 하나');
  exit(2);
}

class _BearerClient extends http.BaseClient {
  _BearerClient(this.token);
  final String token;
  final _inner = http.Client();
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $token';
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

Future<Map<String, dynamic>> _json(http.Response r, String what) {
  if (r.statusCode >= 300) {
    throw StateError('$what 실패 HTTP ${r.statusCode}: ${r.body}');
  }
  return Future.value(r.body.isEmpty ? <String, dynamic>{} : jsonDecode(r.body) as Map<String, dynamic>);
}

Future<String> _insertEdit(http.Client c) async {
  final r = await _json(await c.post(Uri.parse('$base/edits'), headers: {'Content-Type': 'application/json'}, body: '{}'), 'edits.insert');
  return r['id'] as String;
}

Future<List<dynamic>> _tracks(http.Client c, String editId) async =>
    (await _json(await c.get(Uri.parse('$base/edits/$editId/tracks')), 'tracks.list'))['tracks'] as List<dynamic>? ?? [];

Future<List<dynamic>> _bundles(http.Client c, String editId) async =>
    (await _json(await c.get(Uri.parse('$base/edits/$editId/bundles')), 'bundles.list'))['bundles'] as List<dynamic>? ?? [];

Future<void> _list(http.Client c, String editId) async {
  final bundles = await _bundles(c, editId);
  stdout.writeln('업로드된 번들 versionCode: ${bundles.map((b) => b['versionCode']).join(', ')}');
  for (final t in await _tracks(c, editId)) {
    stdout.writeln('\n[track] ${t['track']}');
    final releases = t['releases'] as List<dynamic>? ?? [];
    if (releases.isEmpty) stdout.writeln('  (릴리스 없음)');
    for (final r in releases) {
      final codes = (r['versionCodes'] as List<dynamic>? ?? []).join(', ');
      final frac = r['userFraction'] != null ? ' userFraction=${r['userFraction']}' : '';
      stdout.writeln('  - ${r['status']}  versionCodes=[$codes]  name=${r['name'] ?? '-'}$frac');
    }
  }
}

Future<void> _setTrack(http.Client c, String editId, Map<String, String?> o) async {
  final track = o['track'];
  final keep = o['keep'];
  final status = o['status'] ?? 'completed';
  if (track == null || keep == null) {
    stderr.writeln('set-track 에는 --track 과 --keep 이 필요해요');
    exit(2);
  }
  final bundles = await _bundles(c, editId);
  if (!bundles.any((b) => '${b['versionCode']}' == keep)) {
    stderr.writeln('versionCode $keep 이 아직 업로드돼 있지 않아요. 업로드된 코드: ${bundles.map((b) => b['versionCode']).join(', ')}');
    exit(1);
  }
  final current = (await _tracks(c, editId)).where((t) => t['track'] == track).firstOrNull;
  stdout.writeln('현재 $track: ${jsonEncode(current?['releases'] ?? [])}');
  final body = {
    'track': track,
    'releases': [
      {
        'name': o['name'] ?? '1.1.0 ($keep)',
        'status': status,
        'versionCodes': [keep],
        if (o['notes'] != null) 'releaseNotes': [
          {'language': 'ko-KR', 'text': o['notes']},
        ],
      },
    ],
  };
  stdout.writeln('변경 후 $track: ${jsonEncode(body['releases'])}');
  await _json(await c.put(Uri.parse('$base/edits/$editId/tracks/$track'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(body)), 'tracks.update');
  await _json(await c.post(Uri.parse('$base/edits/$editId:validate')), 'edits.validate');
  stdout.writeln('validate 통과.');
  if (o['commit'] != 'true') {
    stdout.writeln('미리보기만 했어요. 실제 반영하려면 --commit 을 붙여 다시 실행하세요.');
    return;
  }
  await _json(await c.post(Uri.parse('$base/edits/$editId:commit')), 'edits.commit');
  stdout.writeln('commit 완료: $track 트랙은 이제 versionCode $keep ($status) 하나예요.');
}
