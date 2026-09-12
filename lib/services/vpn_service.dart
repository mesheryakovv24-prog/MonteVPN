import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

enum ConnectionStatus { disconnected, connecting, connected }

class MonteVpnService extends ChangeNotifier {
  static final MonteVpnService _instance = MonteVpnService._internal();
  factory MonteVpnService() => _instance;
  MonteVpnService._internal();

  late final FlutterV2ray _v2ray = FlutterV2ray(
    onStatusChanged: (status) {
      _v2rayStatus = status;
      if (status.state == 'CONNECTED') {
        _status = ConnectionStatus.connected;
      } else if (status.state == 'CONNECTING') {
        _status = ConnectionStatus.connecting;
      } else {
        _status = ConnectionStatus.disconnected;
      }
      notifyListeners();
    },
  );

  ConnectionStatus _status = ConnectionStatus.disconnected;
  V2RayStatus _v2rayStatus = V2RayStatus();
  bool _antiBpla = AppConfig.defaultAntiBpla;
  bool _bypassRu = AppConfig.defaultBypassRu;
  String _currentServerName = 'MonteVPN Анти-БПЛА (ya.ru)';
  int _pingDelay = -1;
  String _serverConfig = '';

  ConnectionStatus get status => _status;
  V2RayStatus get v2rayStatus => _v2rayStatus;
  bool get antiBpla => _antiBpla;
  bool get bypassRu => _bypassRu;
  String get currentServerName => _currentServerName;
  int get pingDelay => _pingDelay;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _antiBpla = prefs.getBool('anti_bpla') ?? AppConfig.defaultAntiBpla;
    _bypassRu = prefs.getBool('bypass_ru') ?? AppConfig.defaultBypassRu;
    _serverConfig = prefs.getString('server_config') ?? '';
    _currentServerName = _antiBpla ? 'MonteVPN Анти-БПЛА (ya.ru)' : 'MonteVPN Cloud (443)';

    await _v2ray.initializeV2Ray();
    notifyListeners();
  }

  Future<void> toggleAntiBpla(bool value) async {
    _antiBpla = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('anti_bpla', value);
    _currentServerName = _antiBpla ? 'MonteVPN Анти-БПЛА (ya.ru)' : 'MonteVPN Cloud (443)';
    notifyListeners();

    if (_status == ConnectionStatus.connected) {
      await disconnect();
      await connect();
    }
  }

  Future<void> toggleBypassRu(bool value) async {
    _bypassRu = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bypass_ru', value);
    notifyListeners();

    if (_status == ConnectionStatus.connected) {
      await disconnect();
      await connect();
    }
  }

  Future<void> setCustomConfig(String config) async {
    _serverConfig = config;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_config', config);
    notifyListeners();
  }

  Future<String> _fetchSubscriptionConfig(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        String body = response.body.trim();
        try {
          final decoded = utf8.decode(base64.decode(body));
          final lines = decoded.split(RegExp(r'[\r\n]+')).where((l) => l.isNotEmpty).toList();
          if (lines.isNotEmpty) return lines.first;
        } catch (_) {
          final lines = body.split(RegExp(r'[\r\n]+')).where((l) => l.isNotEmpty).toList();
          if (lines.isNotEmpty) return lines.first;
        }
        return body;
      }
    } catch (e) {
      debugPrint('Subscription fetch error: $e');
    }
    return '';
  }

  Future<void> connect() async {
    if (_status == ConnectionStatus.connected || _status == ConnectionStatus.connecting) {
      return;
    }

    _status = ConnectionStatus.connecting;
    notifyListeners();

    try {
      if (!await _v2ray.requestPermission()) {
        _status = ConnectionStatus.disconnected;
        notifyListeners();
        return;
      }

      String configToUse = _serverConfig;
      if (configToUse.isEmpty) {
        configToUse = _antiBpla ? AppConfig.antiBplaVlessKey : AppConfig.defaultVlessKey;
      }

      List<String> bypassRules = [];
      if (_bypassRu) {
        bypassRules = AppConfig.defaultDirectDomains;
      }

      final v2rayURL = FlutterV2ray.parseFromURL(configToUse);
      _currentServerName = v2rayURL.remark.isNotEmpty 
          ? v2rayURL.remark 
          : (_antiBpla ? 'MonteVPN Анти-БПЛА (ya.ru)' : 'MonteVPN Reality');

      await _v2ray.startV2Ray(
        remark: _currentServerName,
        config: v2rayURL.getFullConfiguration(),
        bypassSubnets: bypassRules,
        proxyOnly: false,
      );

      _measurePing();
    } catch (e) {
      debugPrint('Connection error: $e');
      _status = ConnectionStatus.disconnected;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    _status = ConnectionStatus.connecting;
    notifyListeners();
    await _v2ray.stopV2Ray();
    _status = ConnectionStatus.disconnected;
    _pingDelay = -1;
    notifyListeners();
  }

  Future<void> toggleConnection() async {
    if (_status == ConnectionStatus.connected) {
      await disconnect();
    } else {
      await connect();
    }
  }

  Future<void> _measurePing() async {
    try {
      final delay = await _v2ray.getConnectedServerDelay();
      _pingDelay = delay;
      notifyListeners();
    } catch (_) {
      _pingDelay = -1;
    }
  }
}
