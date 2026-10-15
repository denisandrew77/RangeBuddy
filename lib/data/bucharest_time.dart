import 'package:timezone/data/latest.dart' as data;
import 'package:timezone/timezone.dart' as tz;

final _bucharest = () {
  data.initializeTimeZones();
  return tz.getLocation('Europe/Bucharest');
}();
DateTime bucharestTime(DateTime instant) =>
    tz.TZDateTime.from(instant, _bucharest);
