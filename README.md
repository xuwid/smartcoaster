# Smart Coaster

Smart Coaster is an intelligent drink coaster (a plate you place a glass on) that detects the **weight** and **quantity** of the liquid in the glass above it. When only ~20% of the drink remains, it sends a notification to waiters (or staff) to refill or serve, and users (or staff) can monitor **live quantity** left in the glass. It communicates via **Bluetooth Low Energy (BLE)** and **MQTT**, enabling both local control and cloud / network-based monitoring.

This repository hosts the firmware, mobile app, backend code, and documentation for Smart Coaster.

---

## 🚀 Key Features

| Feature | Description |
|---|---|
| Liquid weight & quantity detection | The coaster senses how much liquid is in the glass by weight sensors / load cells |
| Live updates | The system continuously tracks the remaining quantity in real time |
| Low-level alert (≈ 20%) | When drink level drops below a threshold (default ~20%), a notification is triggered |
| BLE communication | The mobile app or local device can connect to the coaster over BLE to read data / control settings |
| MQTT integration | Data and alerts can be published via MQTT, enabling remote monitoring and integration |
| Cross-platform app / UI | Mobile or web UI to view live status, history, and alerts |
| Configurable thresholds | You can adjust the alert threshold, calibration, and sensitivity |
| Reconnection & reliability | Handles BLE reconnections, error recovery, network disconnects, etc. |

---

## 🧩 Architecture & Communication Flow

Below is a high-level architecture and data flow for Smart Coaster:

