import 'dart:html' as html;

bool isSupported() => html.Notification.supported;

Future<bool> requestPermission() async {
  if (!isSupported()) {
    return false;
  }

  final permission = await html.Notification.requestPermission();
  return permission == 'granted';
}

void showNotification({
  required String title,
  required String body,
}) {
  if (!isSupported()) {
    return;
  }

  html.Notification(
    title,
    body: body,
    icon: 'icons/Icon-192.png',
  );
}
