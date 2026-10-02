# Research

## Native flow

Swift передаёт выбранный JPEG через `handleNativeProductImage(dataUrl, localImageId)`, а повторное
чтение локального файла завершает promise через `handleNativeProductImageRead(requestId, dataUrl)`.
Session token защищает открытую карточку от результата старого picker request.

## Browser flow

Fallback использует FileReader, Image и canvas. До восьми масштабов и три значения JPEG quality
подбирают data URL не длиннее 800023 символов. Эти значения остаются без изменения.

## Extraction decision

Весь contiguous photo block переносится механически. Persistence module продолжает вызывать
`readNativeProductImage` только после durable local product write.
