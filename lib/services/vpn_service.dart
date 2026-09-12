import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
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
  String? _lastError;

  ConnectionStatus get status => _status;
  V2RayStatus get v2rayStatus => _v2rayStatus;
  bool get antiBpla => _antiBpla;
  bool get bypassRu => _bypassRu;
  String get currentServerName => _currentServerName;
  int get pingDelay => _pingDelay;
  String? get lastError => _lastError;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _antiBpla = prefs.getBool('anti_bpla') ?? AppConfig.defaultAntiBpla;
      _bypassRu = prefs.getBool('bypass_ru') ?? AppConfig.defaultBypassRu;
      _serverConfig = prefs.getString('server_config') ?? '';
      _currentServerName = _antiBpla ? 'MonteVPN Анти-БПЛА (ya.ru)' : 'MonteVPN Cloud (443)';

      await _v2ray.initializeV2Ray();
    } catch (e) {
      debugPrint('V2Ray initialization error: $e');
    }
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

  Future<void> connect() async {
    if (_status == ConnectionStatus.connected || _status == ConnectionStatus.connecting) {
      return;
    }

    _status = ConnectionStatus.connecting;
    _lastError = null;
    notifyListeners();

    try {
      final hasPermission = await _v2ray.requestPermission();
      if (!hasPermission) {
        _status = ConnectionStatus.disconnected;
        _lastError = 'Разрешение на VPN не получено';
        notifyListeners();
        return;
      }

      String configToUse = _serverConfig.trim();
      if (configToUse.isEmpty) {
        configToUse = _antiBpla ? AppConfig.antiBplaVlessKey : AppConfig.defaultVlessKey;
      }

      final v2rayURL = FlutterV2ray.parseFromURL(configToUse);
      _currentServerName = _antiBpla ? 'MonteVPN Анти-БПЛА (ya.ru)' : 'MonteVPN Cloud (443)';

      // Configure clean DNS servers
      v2rayURL.dns = {
        "servers": ["1.1.1.1", "8.8.8.8", "77.88.8.8"]
      };

      // Enable sniffing on inbound to intercept hostnames for smart routing
      v2rayURL.inbound["sniffing"] = {
        "enabled": true,
        "destOverride": ["http", "tls"]
      };

      // Configure Xray routing rules
      if (_bypassRu) {
        v2rayURL.routing["domainStrategy"] = "IPIfNonMatch";
        v2rayURL.routing["rules"] = [
          {
            "type": "field",
            "outboundTag": "direct",
            "domain": AppConfig.defaultDirectDomains,
          },
          {
            "type": "field",
            "outboundTag": "proxy",
            "network": "tcp,udp"
          }
        ];
      } else {
        v2rayURL.routing["rules"] = [
          {
            "type": "field",
            "outboundTag": "proxy",
            "network": "tcp,udp"
          }
        ];
      }

      // CRITICAL: bypassSubnets MUST BE null!
      // In flutter_v2ray Android VpnService:
      // When bypassSubnets is null, it executes: builder.addRoute("0.0.0.0", 0);
      // which properly routes all system traffic into the VPN tunnel.
      await _v2ray.startV2Ray(
        remark: _currentServerName,
        config: v2rayURL.getFullConfiguration(),
        bypassSubnets: null,
        proxyOnly: false,
      );

      _measurePing();
    } catch (e) {
      debugPrint('Connection error: $e');
      _lastError = e.toString();
      _status = ConnectionStatus.disconnected;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    _status = ConnectionStatus.connecting;
    notifyListeners();
    try {
      await _v2ray.stopV2Ray();
    } catch (e) {
      debugPrint('Disconnect error: $e');
    }
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

