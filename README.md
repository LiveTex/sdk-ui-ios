# LivetexUICore

## Настройка эндпоинта авторизации

`LivetexUICore` использует `LivetexAuthService` из `LivetexCore`: адрес авторизации берётся из `Info.plist` приложения, ключ `LivetexAuthPath` в словаре `Livetex`. Если ключа нет — используется `https://visitor-api.livetex.ru/v1/auth`. Подробнее — в README пакета `sdk-ios`.

## Корневой сертификат сервера

Корневой сертификат тоже задаётся в `Info.plist`, ключ `LivetexRootCertificate` (имя файла в бандле). Он применяется к авторизации, WebSocket, скачиванию файлов, аватарам и фото. Отдельной настройки в UI-пакете не требуется — достаточно ключа из README `sdk-ios`.
