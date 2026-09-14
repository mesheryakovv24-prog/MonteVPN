class AppConfig {
  static const String appName = 'MonteVPN';
  static const String appTagline = 'Fast • Secure • Unrestricted';
  static const String appVersion = '1.1.0';

  // Ссылка на автоматическую подписку с сервера MonteVPN
  static const String defaultSubscriptionUrl = 'http://87.199.196.244:2096/sub/3bd9599f16b1222c';

  // Прямой VLESS Reality ключ (Google SNI, порт 443)
  static const String defaultVlessKey =
      'vless://105ae052-72c5-42df-84fe-39c18599787a@87.199.196.244:443?flow=xtls-rprx-vision&fp=chrome&pbk=kV_oY6s685dz-O3onYr_De8lbZQvGGLBzuhWXewqEA4&security=reality&sid=949df36a&sni=dl.google.com&type=tcp#MonteVPN-Google';

  // Анти-БПЛА VLESS Reality ключ (ya.ru SNI, порт 8443) - только ASCII во фрагменте!
  static const String antiBplaVlessKey =
      'vless://105ae052-72c5-42df-84fe-39c18599787a@87.199.196.244:8443?flow=xtls-rprx-vision&fp=chrome&pbk=kV_oY6s685dz-O3onYr_De8lbZQvGGLBzuhWXewqEA4&security=reality&sid=949df36a&sni=ya.ru&type=tcp#MonteVPN-AntiBPLA-Yandex';

  // Включение режима Анти-БПЛА по умолчанию
  static const bool defaultAntiBpla = true;

  // Включение обхода российских сайтов по умолчанию (Split Tunneling)
  static const bool defaultBypassRu = true;

  // Сайты и зоны, которые идут напрямую без VPN (domain: правила работают автономно без geosite.dat)
  static const List<String> defaultDirectDomains = [
    'domain:ru',
    'domain:su',
    'domain:xn--p1ai', // .рф
    'domain:gosuslugi.ru',
    'domain:sberbank.ru',
    'domain:tinkoff.ru',
    'domain:t-bank.ru',
    'domain:alfabank.ru',
    'domain:vtb.ru',
    'domain:ozon.ru',
    'domain:wildberries.ru',
    'domain:yandex.ru',
    'domain:ya.ru',
    'domain:vk.com',
    'domain:kinopoisk.ru',
    'domain:avito.ru',
    'domain:dzen.ru',
    'domain:mos.ru',
    'domain:cbr.ru',
    'domain:nalog.gov.ru',
    'domain:eda.yandex.ru',
    'domain:market.yandex.ru',
  ];
}

