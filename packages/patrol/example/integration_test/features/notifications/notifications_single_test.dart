@Tags(['android', 'ios'])

import 'dart:io';

import '../../common.dart';

void main() {
  patrol(
    'sends a notification, verifies that it is visible and taps on it by index',
    ($) async {
      await $.pumpWidgetAndSettle(ExampleApp());

      await $('Open notifications screen').tap();
      await $(RegExp('someone liked')).tap();

      if (await $.native.isPermissionDialogVisible()) {
        print('Dialog is visible');
        await $.native.grantPermissionWhenInUse();
      }

      if (Platform.isIOS) {
        await $.native.closeHeadsUpNotification();
      }

      await $.native.openNotifications();
      final notifications = await $.native.getNotifications();
      print('Found ${notifications.length} notifications');
      notifications.forEach(print);

      expect(notifications.length, equals(1));
      await $.native.tapOnNotificationByIndex(0);
    },
  );

  patrol(
    'sends a notification, verifies that it is visible and taps on it by text',
    ($) async {
      await $.pumpWidgetAndSettle(ExampleApp());

      await $('Open notifications screen').tap();
      await $(RegExp('someone liked')).tap();

      if (await $.native.isPermissionDialogVisible()) {
        print('Dialog is visible');
        await $.native.grantPermissionWhenInUse();
      }

      if (Platform.isIOS) {
        await $.native.closeHeadsUpNotification();
      }

      await $.native.openNotifications();
      final notifications = await $.native.getNotifications();
      print('Found ${notifications.length} notifications');
      notifications.forEach(print);

      expect(notifications.length, equals(1));
      await $.native.tapOnNotificationBySelector(
        Selector(textContains: 'Tap to see who'),
      );
    },
  );
}
