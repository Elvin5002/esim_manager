# 📶 esim_manager

A Flutter plugin to **check eSIM support** and **install eSIM profiles**
on **Android** and **iOS** using official, system-supported provisioning flows.

---

## 📌 Overview

`esim_manager` allows you to:

- Detect whether a device supports **eSIM**
- Install eSIM profiles using a single **LPA string** API on both Android and iOS
- Listen to install result events for advanced integrations

Designed for **travel eSIM apps**, **telecom providers**, **enterprise device onboarding**, and **carrier provisioning flows**.

---

## 🚀 Features

- 🔍 Check if the current device supports **eSIM**
- 📲 Unified install API: `installEsim(lpa)`
- 🤖 **Android** installation using system eSIM setup link
- 🍎 **iOS** installation using Apple’s official **LPA UI**
- 🔁 Stream-based install result callbacks
- 🧩 Clean, platform-agnostic Dart API

---

## 📱 Platform Support

| Platform | eSIM Check | eSIM Install |
|--------|-----------|-------------|
| Android | ✅ | ✅ |
| iOS | ✅ | ✅ (LPA URL) |

---

## 📦 Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  esim_manager: ^0.0.6
```

Then run:

```bash
flutter pub get
```

---

## 📥 Import

```dart
import 'package:esim_manager/esim_manager.dart';
```

---

## 📌 Usage

### 🔍 Check eSIM Support

```dart
final esimManager = EsimManager();

final isSupported = await esimManager.isEsimSupported();
print('eSIM supported: $isSupported');
```

---

### 📲 Install eSIM (Android + iOS)

Use one API for both platforms with a valid LPA string:

```dart
final esimManager = EsimManager();

const lpa = 'LPA:1$YOUR_SMDP_ADDRESS$YOUR_ACTIVATION_CODE';
final ok = await esimManager.installEsim(lpa);

print('Installer opened: $ok');
```

On iOS and Android, this opens the system eSIM installation flow.

---

### 🔁 Listen for Install Result Events

You can listen to installation updates using a stream:

```dart
EsimManager().installEvents.listen((event) {
  print('Request ID: ${event.requestId}');
  print('Status: ${event.result.status}');
  print('Message: ${event.result.message}');
});
```

Useful for:
- Analytics
- Error tracking
- Multi-step provisioning flows

---

## ⚠️ Notes & Limitations

- iOS **does not allow silent eSIM installation**
- Android installation behavior can vary by OEM and OS implementation
- Always test on **real devices** with eSIM support
- Emulator / Simulator **does not support eSIM**

---

## 🧪 Testing

| Platform | Emulator | Real Device |
|--------|----------|-------------|
| Android | ❌ | ✅ |
| iOS | ❌ | ✅ |

---

## 📄 License

MIT License  
Feel free to use, modify, and contribute.

---

## 🤝 Contributions

Pull requests are welcome.  
For major changes, please open an issue first to discuss what you would like to change.

---

## 💬 Support

If you encounter issues or have feature requests, please open an issue on GitHub.
