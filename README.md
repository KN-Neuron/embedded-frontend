# <div align="center"> EEG dashboard 🧠

**A cross-platform Flutter dashboard for EEG signal processing, visualization, and AI-powered neural interpretation.**
---

<img width="2545" height="1433" alt="obraz" src="https://github.com/user-attachments/assets/433f9c6b-73f6-4490-a8a1-967a2bf7afee" />


## Key Features

* **Real-time DSP**: Live signal processing featuring Hann windowing and Fast Fourier Transform (FFT).
* **Neural Band Analysis**: Power calculation for Delta, Theta, Alpha, and Beta frequency bands based on custom configurations.
* **AI Neuro-Interpreter**: Integration with Google Gemini for automated cognitive state analysis and reports.
* **10-20 System Educational View**: Interactive electrode mapping with functional descriptions of brain regions.
---

## Tech Stack
* **Framework:** [![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
* **State Management:** [Provider](https://pub.dev/packages/provider)
* **Data Visualization:** [fl_chart](https://pub.dev/packages/fl_chart)
* **AI Integration:** Google Gemini API
* **Signal Processing:** Custom Dart implementation of Fast Fourier Transform (FFT) and Hjorth Parameters.

---

## Getting started

### Prerequisites
* Flutter SDK (3.x or higher)
* An API Key for Gemini (optional, required for AI analysis features)

### Installation
1.  **Clone the repository:**
    ```bash
    git clone https://github.com/KN-Neuron/embedded-frontend.git
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
<div align="center"> Created with ❤️ for the Neuroscience.
