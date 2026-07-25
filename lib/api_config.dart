const String apiBase = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://hazrat233.pythonanywhere.com',
);

String api(String path) => apiBase + path;
