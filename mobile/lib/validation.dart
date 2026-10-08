/// Проверка формы до отправки. Те же правила ещё раз проверяет сервер.
///
/// Время передаётся в минутах от начала дня. Возвращает текст ошибки или null.
String? validateTrip({
  required int? startMinutes,
  required int? endMinutes,
  required int? amount,
  required int? commission,
}) {
  if (startMinutes == null || endMinutes == null) {
    return 'Укажите время начала и окончания';
  }
  if (endMinutes <= startMinutes) {
    return 'Окончание должно быть позже начала';
  }
  if (amount == null || amount <= 0) {
    return 'Сумма должна быть целым числом больше нуля';
  }
  if (commission == null || commission < 0) {
    return 'Комиссия не может быть отрицательной';
  }
  if (commission > amount) {
    return 'Комиссия не может быть больше суммы';
  }
  return null;
}
