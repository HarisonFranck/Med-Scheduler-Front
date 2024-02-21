class UrlBase {
  static final UrlBase _instance = UrlBase._internal();

  factory UrlBase() {
    return _instance;
  }

  UrlBase._internal();

  final String baseUrl = "https://dev-api-medscheduler.raketa.mg/med_scheduler_api/public/";
}
