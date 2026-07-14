# 🚀 Installation Complete (Updated May 21, 2026)

The latest production version of **I-Buzz BD Management** has been successfully compiled and installed on your Windows PC!

---

## 🎯 Quick Start: How to Run the App

We have simplified the launching process by creating a direct shortcut for you.

### 1. Direct Desktop Shortcut (Recommended)
We have automatically created a shortcut directly on your desktop:
* **Shortcut Name:** `I-Buzz BD Management`
* **Desktop Path:** `C:\Users\Muhammad Raihan\Desktop\I-Buzz BD Management.lnk`
* **Action:** Just double-click this shortcut to launch the app instantly!

### 2. Standalone Release Bundle Folder
We have assembled a self-contained folder that you can copy anywhere (e.g., to a USB drive or another directory):
* **Path:** `d:\web app\I-buzz bd mangement\ReleaseBundle\`
* **Primary Executable:** `d:\web app\I-buzz bd mangement\ReleaseBundle\ibuzz_bd_management.exe`

---

## 🛠️ Installation & Compilation Summary

| Step | Action Taken | Status | Detail |
| :--- | :--- | :---: | :--- |
| **1** | Source Code Audit | **Passed** | Inspected the modified files in `lib/`. |
| **2** | Production Compile | **Success** | Executed `flutter build windows` (Completed in 79.8s). |
| **3** | Bundle Assembly | **Success** | Packaged the runner `.exe` and all dynamic plugin libraries (`.dll`) to `ReleaseBundle`. |
| **4** | Shortcut Automation | **Success** | Wrote and executed `create_desktop_shortcut.ps1` to place a shortcut on your Desktop. |

---

## 📊 Application Core Features

* **📊 Real-time Dashboard:** Track total sales, costs, stocks, capital, expenses, and net profit or loss at a single glance.
* **📱 Mobile Sector:** Complete inventory log with IMEI tracking, product specifications, status tracking (in-stock/sold), and price points.
* **🎮 Gadget Sector:** Flexible catalog management for smart accessories and electronic products with SKU/code tracking.
* **💰 Sales & Baki (Dues):** Record sales transactions, print receipt slips, and manage customer credit accounts (Baki) with payment histories.
* **💸 Financial Ledger:** Monitor business capital, track operational expenses, analyze profit/loss metrics, and run salary logs.
* **📂 Advanced Data Exporter:** Generate beautifully structured Excel reports (`.xlsx`) or professional formatted PDF summaries directly from the settings page.

---

## 🔧 First-Time Launch & Configuration

When you run the application for the first time, follow these simple steps to set up your business:

1. **Authentication:** Sign in or register a new administrator account. All authentication is securely processed by Firebase Auth.
2. **Business Profile:** Navigate to the **Settings** menu and enter your business name, contact details, and address.
3. **Currency & Region:** Set your primary currency (Default: Bengali Taka `৳`).
4. **Capital Input:** Input your starting capital inside the Financial module to initialize your profit-and-loss baseline.

---

## 🆘 Troubleshooting & Rebuilds

### Firebase Connection or Offline Mode
The application is built with a resilient offline-first design. It automatically caches data locally and synchronizes it with the Firebase cloud database once an active internet connection is restored.

### Regenerating the Shortcut
If you accidentally delete the Desktop shortcut, you can recreate it instantly:
1. Open PowerShell.
2. Navigate to the project root: `cd "d:\web app\I-buzz bd mangement"`
3. Run the helper script: `powershell -File create_desktop_shortcut.ps1`

### Rebuilding the Application
If you make additional source changes in the future, you can rebuild the release bundle by running:
```powershell
flutter build windows
powershell -File assemble_release.ps1
```
