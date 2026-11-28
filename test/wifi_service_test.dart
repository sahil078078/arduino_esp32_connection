import 'package:arduino_control_app/services/wifi_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('posts text and reads ADC with a query parameter', () async {
    final requests = <http.Request>[];
    final service = DefaultWifiService(
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response('OK', 200);
      }),
    );
    addTearDown(service.dispose);

    expect(await service.connect(ip: '192.168.4.1', port: 80), isTrue);
    expect(await service.sendText('RGB:1:2:3 & +'), isTrue);
    expect(await service.requestAdc(34), isTrue);

    expect(requests[0].method, 'GET');
    expect(requests[0].url.path, '/ping');
    expect(requests[1].method, 'POST');
    expect(requests[1].url.path, '/text');
    expect(requests[1].bodyFields, {'t': 'RGB:1:2:3 & +'});
    expect(requests[2].method, 'GET');
    expect(requests[2].url.path, '/adc');
    expect(requests[2].url.queryParameters, {'pin': '34'});
  });

  test('falls back to GET when the firmware lacks a POST route', () async {
    final requests = <http.Request>[];
    final service = DefaultWifiService(
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response('', request.method == 'POST' ? 404 : 200);
      }),
    );
    addTearDown(service.dispose);

    expect(await service.connect(ip: '192.168.4.1', port: 80), isTrue);
    expect(await service.sendChar('A'), isTrue);

    expect(requests.map((request) => request.method), ['GET', 'POST', 'GET']);
    expect(requests.last.url.path, '/cmd');
    expect(requests.last.url.queryParameters, {'c': 'A'});
  });

  test('rejects failed HTTP probes even if both routes respond', () async {
    final service = DefaultWifiService(
      httpClient: MockClient((_) async => http.Response('', 404)),
    );
    addTearDown(service.dispose);

    expect(await service.connect(ip: '192.168.4.1', port: 80), isFalse);
    expect(service.isConnected, isFalse);
  });
}
