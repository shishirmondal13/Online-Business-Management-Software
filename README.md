# 📊 I-Buzz BD Management

> **I-Buzz BD Management** is a premium, robust business management desktop and mobile application tailored for mobile phone and gadget retail businesses in Bangladesh. Built on **Flutter** and powered by **Firebase**, it delivers real-time synchronization, offline support, and advanced financial analytics.

---

## 🚀 Key Features

### 📱 Mobile Phone Inventory & Tracking
- **IMEI Serial Tracking:** Strict serial/IMEI recording for every device entering or leaving inventory.
- **Cost Accumulation:** Automatic calculation of the final unit purchase price by combining unit cost and transport overhead.
- **Dynamic Valuation:** Real-time stock levels, purchase rates, and expected profit estimation.

### 🎮 Gadget & Accessory Inventory
- **Separate Margins:** Independent tracking of smaller gadgets, electronics, and accessories.
- **Automated Profit Logic:** Dynamic retail calculation based on purchase rates, margins, and taxes.

### 🛒 Sales & Transaction Ledger
- **Flexible Payments:** Support for full, partial, and installment payments.
- **Baki (Customer Dues):** Comprehensive ledger to track unpaid balances, client names, and contact details.
- **Sales History:** Full log of transactions with quick-search filters.

### 💰 Financial Engine
- **Capital Tracker:** Manage capital investments and partner contributions.
- **Operational Expense Book:** Categorized logging of rent, utility, and miscellaneous costs.
- **Payroll (Salary Ledger):** Record employee salary scales, advances, and monthly payouts.
- **Consolidated P&L:** Net profits computed correctly by deducting costs and expenses from overall revenues.

### 📈 Reports & Exports
- **Excel & PDF Exports:** Seamless exporting of inventory lists and sales reports using native Excel sheet generation and PDF layouts.
- **Advanced Charts:** Interactive charts demonstrating trends in revenue, expenditures, and net profits over time.

---

## 🏗️ Architecture & Directory Layout

The project follows a **feature-first** package organization. It utilizes **Riverpod** for declarative state management.

```text
lib/
├── main.dart                  # Application entry point
├── app.dart                   # MaterialApp initialization, localization, and AuthWrapper
├── firebase_options.dart      # Auto-generated Firebase configurations
├── auth/                      # Authentication (Login, Users state)
├── admin/                     # Store administration and privileges
├── mobile_sector/             # Mobile inventory data models & views
├── gadget_sector/             # Gadgets inventory data models & views
├── sales/                     # Store checkout, invoices, and sales logs
├── baki_due/                  # Client credit tracking and outstanding dues
├── capital/                   # Investment and capital records
├── expenses/                  # Shop maintenance, rent, and bill tracking
├── salary/                    # Payroll and worker advances
├── reports/                   # Excel/PDF report compilers & export services
├── dashboard/                 # Central overview, charts, and metrics
├── search/                    # Global inventory search
├── settings/                  # App configuration & dark mode toggles
└── shared/                    # Shared widgets, constants, and utilities
```

---

## 🛠️ Technology Stack

| Component | Library / Framework | Purpose |
| :--- | :--- | :--- |
| **Frontend Core** | Flutter (SDK `^3.10.4`) | High-performance desktop and mobile UI rendering |
| **Backend / DB** | Cloud Firestore | Scalable real-time document store with offline persistence |
| **Auth** | Firebase Authentication | Secure login with email and password |
| **State Management** | Riverpod (`flutter_riverpod`) | Predictable, reactive, and testable application state |
| **Local Storage** | SharedPreferences / Hive | Local persistence of offline settings and session markers |
| **Reporting** | `excel` / `pdf` / `printing` | Generating structured spreadsheets and printable PDF receipts |
| **Data Viz** | `fl_chart` | Interactive graphical representation of financial performance |

---

## ⚙️ Development & Local Setup

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (recommended `3.10.x` or later)
- [Git](https://git-scm.com/) version control client
- Node.js (optional, for running Firebase CLI commands locally)

### Step-by-Step Installation

1. **Clone the Repository:**
   ```bash
   git clone <your-private-repo-url>
   cd "I-buzz bd mangement"
   ```

2. **Retrieve Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Establish Firebase Project Linkage:**
   - Place your Android `google-services.json` inside `android/app/`
   - Place your iOS `GoogleService-Info.plist` inside `ios/Runner/`
   - Update `lib/firebase_options.dart` configuration block.

4. **Run the Code Generator (for Riverpod):**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

5. **Start Debug Execution:**
   ```bash
   flutter run
   ```

---

## 📦 Building for Production (Windows x64)

To build a standalone Windows executable with all bundled DLLs:

```bash
flutter build windows
```
The compiled output is located at:
`build\windows\x64\runner\Release\`

---

## 📖 Developer Guides & Logs
For troubleshooting or detailed design parameters, reference the following repository documents:
- [DEPLOYMENT_GUIDE.md](file:///d:/web%20app/I-buzz%20bd%20mangement/DEPLOYMENT_GUIDE.md) - Deploying the app on Windows environments.
- [CALCULATION_LOGIC_FIXES.md](file:///d:/web%20app/I-buzz%20bd%20mangement/CALCULATION_LOGIC_FIXES.md) - Notes on the updated profit logic equations.
- [FIREBASE_SETUP.md](file:///d:/web%20app/I-buzz%20bd%20mangement/FIREBASE_SETUP.md) - Step-by-step instructions on setting up Firebase databases.
