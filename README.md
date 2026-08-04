# App DeMolay

> Smart, gamified, and AI-powered management application for DeMolay Chapters.

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-26.0%2B-blue.svg)](https://developer.apple.com/ios/)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-green.svg)](https://supabase.com)
[![Architecture](https://img.shields.io/badge/Architecture-MVVM-lightgrey.svg)]()
[![Design](https://img.shields.io/badge/Design-Heuristics%20%7C%20WCAG-blueviolet.svg)]()

## 📖 Overview

**App DeMolay** was designed to revolutionize Chapter management by providing modern, predictive tools for attendance tracking (Roster), event scheduling, financial management, and member engagement through a gamified goal-tracking system. 

Built with scalability, privacy, and user-centered design in mind, it leverages cutting-edge Apple ecosystem technologies—including on-device Foundation Models for intelligent insights—while maintaining an architecture that allows for smooth expansion.

## ✨ Key Features

* **🔒 Robust Authentication:** Secure login and role-based permissions powered by Supabase.
* **📅 Smart Calendar & App Intents:** Visual management for meetings and rituals. Integrated with Home Screen Widgets and Siri Shortcuts for quick attendance confirmation.
* **🤖 Artificial Intelligence (Foundation Models):** Utilizes Apple's native `NaturalLanguage` framework (Word Embeddings & Sentiment Analysis) running 100% on-device to generate contextual, privacy-preserving management insights based on Chapter events.
* **📊 Gamified Goals:** Track Chapter objectives (finances, initiations, etc.) with automatic progression calculations and dynamic UI feedback.
* **📜 Member Roster:** Comprehensive overview and attendance tracking for all active members.
* **📱 Beautiful iOS Native UI:** Crafted using SwiftUI with custom design system components, micro-animations, and full accessibility support (WCAG).

## 🛠️ Tech Stack & Architecture

The project strictly follows the **MVVM** (Model-View-ViewModel) pattern utilizing Apple's modern observation system (iOS 17+).

* **Language:** Swift
* **UI Framework:** SwiftUI
* **Design System:** Standardized, injectable components and tokens. Built upon **Nielsen's Heuristics**, **WCAG Accessibility**, and **UX Psychology**.
* **State Management:** `@Observable` macro.
* **Dependency Injection:** Protocol-oriented Services injected via `@Environment`, enabling isolated unit testing via Mocks.
* **Backend:** Supabase (PostgreSQL, PostgREST) configured as BaaS with strict Row Level Security (RLS) policies.
* **Package Manager:** Swift Package Manager (SPM).

## 🚀 Getting Started

### Prerequisites
* macOS Tahoe (26.0) or higher.
* Xcode 26 or higher.
* Active Supabase project (for the database backend).

### Installation

1. Clone the repository:
```bash
git clone https://github.com/K0W4/app-demolay.git
```

2. Open the project in Xcode:
```bash
cd app-demolay
open "App DeMolay.xcodeproj"
```

3. Let Swift Package Manager automatically resolve and download the Supabase SDK.
4. Select your preferred iOS simulator (e.g., iPhone 15 Pro) and hit **Run** (`Cmd + R`).

## 🗄️ Database Structure (Supabase)

The application consumes a dynamically generated API via Supabase, based on the following unified schema:

- `chapter`: Core chapter information.
- `member`: Members profiles and roles.
- `event`: Calendar events (supports public anonymous reading for Widgets).
- `goal`: Gamified targets with progression tracking.
- `task`: Delegated activities with deadlines.
- `committee`: Groups and chairmen assignments.

> **Security Note:** All tables utilize **Row Level Security (RLS)** to ensure members only access data related to their own Chapter. We prioritize user privacy, relying on Apple's local Neural Engine for AI processing to avoid sending sensitive Chapter data to third-party servers.

## 📐 Development & Design Philosophy

Developed under strict software engineering and product design principles:
- **KISS & YAGNI:** Absolute prioritization of native iOS solutions (Minimum Viable Code). No third-party libraries are used unless strictly necessary.
- **Test-Driven:** Decoupled architecture via protocols, ready for comprehensive unit testing.
- **Deep UX/UI:** Extensive use of semantic contrast, loading skeletons, and fluid typography to drive engagement. Interfaces are designed to reduce cognitive load (Hick's Law) while putting accessibility at the forefront.

## 📄 License

This project is developed for internal management use by DeMolay Chapters. All rights reserved.
