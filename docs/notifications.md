# Notifications

This document describes the notification implementation that exists in the app and functions today.

## Source Of Truth

- Client service: `lib/core/services/notification_service.dart`
- Function triggers/callables:
  - `functions/src/notifications/send_chat_notification.ts`
  - `functions/src/notifications/send_order_notification.ts`
  - `functions/src/notifications/send_promo_notification.ts`
  - `functions/src/notifications/fcm_helpers.ts`

## Client Behavior

`NotificationService` currently handles:

- Firebase Messaging background registration
- Android high-importance notification channel setup
- local notification display for foreground messages
- FCM token retrieval and token refresh stream
- notification permission requests
- access to:
  - foreground messages
  - background-opened messages
  - initial launch message

Important current detail:

- local notification payload uses `message.data['route']`
- the service itself does not perform navigation
- app-level code is expected to handle opened-message routing

## Current Payload Conventions

The backend currently sends typed notification payloads with fields like:

- `type`
- `orderId`
- `orderNumber`
- `chatId`
- `senderId`

Current code does not establish a single universal `screen` payload contract.
Older docs that rely on `screen` should be considered outdated unless a sender explicitly adds it.

For app-side deep linking, prefer a `route` string that matches `GoRouter` paths.

## Implemented Notification Sources

### Order Updates

Order update push behavior is triggered from order change flows and uses:

- `type: order_update`
- order status fields
- user-facing status-specific title/body generation

Order statuses currently recognized by functions:

- `placed`
- `confirmed`
- `preparing`
- `readyForPickup`
- `pickedUp`
- `onTheWay`
- `delivered`
- `cancelled`

### Chat Notifications

`sendChatNotification` fires when a message is created in:

- `chats/{chatId}/messages/{messageId}`

It resolves the other participant and sends:

- `type: chat`
- `chatId`
- `senderId`

### Promotion Notifications

`sendPromoNotification` is an admin-only callable that can send:

- to specific users
- to users filtered by role
- to all active users

It writes notification documents and sends FCM payloads with:

- `type: promotion`

## Current Deep Link Targets

If a payload includes a `route`, it should use actual app paths such as:

- `/customer/orders/{orderId}/tracking`
- `/customer/orders/{orderId}/chat`
- `/delivery/orders/{orderId}/chat`
- `/delivery/orders/{orderId}/navigate`
- `/delivery/home`
- `/delivery/earnings`
- `/customer/home`

Do not use stale paths such as:

- `/verification-pending`
- `/login`
- `/signup`
- `/otp-verification`

Use the actual route constants in `lib/routing/route_paths.dart`.

## Current Limitations

- Notification tap navigation is not fully centralized in the current client code.
- The service exposes message streams but leaves route handling to app-level integration.
- The docs should not claim a fully implemented generic deep-link resolver beyond what exists in `NotificationService`.
