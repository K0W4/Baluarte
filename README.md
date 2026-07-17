# App DeMolay

> Smart and gamified management application for DeMolay Order Chapters.

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-17.0%2B-blue.svg)](https://developer.apple.com/ios/)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-green.svg)](https://supabase.com)
[![Architecture](https://img.shields.io/badge/Architecture-MVVM-lightgrey.svg)]()

## 📖 Overview

The **App DeMolay** was designed to revolutionize chapter management, providing modern and predictive tools for attendance tracking (Roster), event calendar, financial management, and member engagement through a goal-tracking system.

The project was built focusing on scalability principles, using cutting-edge technologies from the Apple ecosystem and maintaining an architecture that will allow for a smooth and future expansion to Android.

## ✨ Key Features

* **🔒 Robust Authentication:** Secure login and role-based permission control via Supabase.
* **📅 Smart Calendar:** Visual management of meetings, rituals, and events.
* **📊 Goal Management:** Gamified tracking of goals (financial, initiations, etc.) with automatic progression calculation.
* **📜 Roster:** Overview and attendance control of all active members.
* **🤖 Integrated CoreML (Coming soon):** Predictive reading of documents and minutes using on-device Artificial Intelligence.

## 🛠️ Technology Stack & Architecture

This project strictly follows the **MVVM** (Model-View-ViewModel) pattern using Apple's new observation system (iOS 17+).

* **Language:** Swift
* **UI Framework:** SwiftUI
* **Design System:** Standardized components and tokens (Protocol-Oriented).
* **State Management:** `@Observable` (Replacing the legacy `@ObservableObject`).
* **Dependency Injection:** Protocols (Services) injected via `@Environment`, allowing isolated testing via Mocks.
* **Backend:** Supabase (PostgreSQL, PostgREST) configured as BaaS.
* **Package Manager:** Swift Package Manager (SPM).

## 🚀 Getting Started

### Prerequisites
* macOS Sonoma (14.0) or higher.
* Xcode 15 or higher.
* Active Supabase account (for the database).

### Installation

1. Clone the repository:
```bash
git clone https://github.com/YOUR_USERNAME/app-demolay.git
```

2. Open the project file:
```bash
cd app-demolay
open "App DeMolay.xcodeproj"
```

3. Swift Package Manager will automatically download the Supabase SDK.
4. Select the desired simulator (e.g., iPhone 15 Pro) and click **Run** (`Cmd + R`).

## 🗄️ Database Structure (Supabase)

The application consumes a dynamically generated API by Supabase, based on the following schema:

- `chapter`
- `member`
- `event`
- `goal` (Goals with progression percentage)
- `committee`

> **Security Note:** The tables use RLS (Row Level Security) to ensure that members only access information related to their respective Chapter.

## 📐 Ponytail Philosophy (Design Principles)

Developed under strict engineering principles:
- **KISS & YAGNI:** Absolute prioritization of native iOS solutions (Minimum Viable Code). No third-party libraries are used unless strictly necessary (e.g., Supabase SDK).
- **Test-Driven:** Decoupled architecture via protocols, ready for unit testing.
- **Aesthetics First:** Use of micro-animations, semantic contrasts, and fluid typography to generate engagement through Interface Design.

## 📄 License

This project is developed for internal use by Chapters of the DeMolay Order. All rights reserved.
