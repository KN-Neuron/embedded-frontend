# EEG dashboard 🧠

**A cross-platform Flutter dashboard for EEG signal processing, visualization, and AI-powered neural interpretation.**
---

## Key Features

* **Real-time DSP Engine**: Live signal processing featuring Hann windowing and Fast Fourier Transform (FFT).
* **Neural Band Analysis**: Power calculation for Delta, Theta, Alpha, and Beta frequency bands based on custom configurations.
* **AI Neuro-Interpreter**: Integration with OpenAI and Google Gemini for automated cognitive state analysis and reports.
* **10-20 System Educational View**: Interactive electrode mapping with functional descriptions of brain regions.
---

## Project architecture

The project follows a **Clean Architecture** pattern, ensuring a strict separation between mathematical models, business logic, and the presentation layer.

```text
lib/
├── core/               # Domain Layer: data models & configurations
│   ├── band_config.dart      # EEG frequency band definitions
│   ├── complex.dart          # complex number math for FFT
│   ├── constants.dart        # global constants (sample rates, colors)
│   └── eeg_metrics.dart      # standardized EEG data model
├── logic/              # Business Logic Layer: Processing & Services
│   ├── ai_analysis_service.dart     # OpenAI/Gemini integration
│   ├── eeg_analysis_processor.dart  # main signal pipeline
│   ├── eeg_data_controller.dart     # provider state management
│   └── signal_processor.dart        # static math & DSP utilities
├── ui/                 # Presentation Layer
│   ├── screens/        # full-page views (Dashboard, Home, Educational)
│   └── widgets/        # modular UI components (charts, power cards)
└── main.dart           # application entry point & Dependency Injection
```
---

## Tech Stack

* **Framework:** [Flutter](https://flutter.dev) (Cross-platform UI)
* **State Management:** [Provider](https://pub.dev/packages/provider) (Reactive data flow)
* **Data Visualization:** [fl_chart](https://pub.dev/packages/fl_chart) (High-performance real-time plotting)
* **AI Integration:** OpenAI GPT API & Google Gemini API
* **Signal Processing:** Custom Dart implementation of Fast Fourier Transform (FFT) and Hjorth Parameters.

---

## Getting started

### Prerequisites
* Flutter SDK (3.x or higher)
* An API Key for OpenAI or Gemini (optional, required for AI analysis features)

### Installation
1.  **Clone the repository:**
    ```bash
    git clone https://github.com/BinaryWiz4rd/eeg-dashboard.git
    ```
2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Run the application:**
    ```bash
    flutter run
    ```
---
Created with ❤️ for the Neuroscience.
