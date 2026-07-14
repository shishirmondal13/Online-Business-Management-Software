# I-Buzz BD Management - Quick Start Guide

## ✅ Installation Complete

Your I-Buzz BD Management application has been successfully analyzed, debugged, built, and installed on your Windows PC.

---

## How to Run the Application

### Method 1: Direct Execution (Recommended)
Navigate to the application folder and double-click the executable:
```
d:\web app\I-buzz bd mangement\build\windows\x64\runner\Release\ibuzz_bd_management.exe
```

### Method 2: Command Line
Open PowerShell or Command Prompt and run:
```powershell
cd "d:\web app\I-buzz bd mangement\build\windows\x64\runner\Release"
.\ibuzz_bd_management.exe
```

### Method 3: Create Desktop Shortcut (Recommended for Easy Access)
1. Right-click on the Desktop
2. Select "New" → "Shortcut"
3. Paste this path:
   ```
   d:\web app\I-buzz bd mangement\build\windows\x64\runner\Release\ibuzz_bd_management.exe
   ```
4. Click "Next" and name it "I-Buzz Management"
5. Click "Finish"

Now you can double-click the shortcut to launch the app anytime.

---

## Application Features

### 📊 Dashboard
- Real-time business overview
- Total sales, costs, profits, and losses
- Stock value analysis
- Quick access to all modules

### 📱 Mobile Sector Management
- Add/Edit mobile phones
- Track IMEI numbers
- Manage inventory and pricing
- Mark as sold/in-stock

### 🎮 Gadget Sector Management
- Manage gadget inventory
- Track product codes
- Monitor stock levels
- Price management

### 💰 Sales Management
- Record new sales
- View sales history
- Analyze sales data
- Generate sales reports

### 💸 Financial Management
- Track profit/loss
- Manage capital
- Record expenses
- View financial summaries

### 💼 Reports & Analytics
- Profit/Loss reports
- Excel export (XLSX)
- PDF export with detailed analytics
- Transaction history
- Financial summaries

### 💰 Salary Management
- Manage employee salaries
- Track salary payments
- View payment history

### 👥 Customer Management
- Track customer due amounts (Baki)
- Manage due payments
- View customer payment history

### ⚙️ Settings
- Application preferences
- Data management
- Export/Import functionality

---

## System Requirements

✅ **Windows 10 or later**
- No additional software required
- All dependencies bundled with executable
- ~250 MB free disk space for application + data

---

## First Time Setup

### 1. Launch the App
Double-click `ibuzz_bd_management.exe`

### 2. Authentication
- The app uses Firebase authentication
- Sign up or log in with your credentials
- Your data is securely stored in Firestore

### 3. Initial Configuration
- Set up your business name
- Configure currency (Default: ৳ - Bengali Taka)
- Add initial capital
- Start managing your inventory

---

## Key Shortcuts & Tips

| Feature | How to Access |
|---------|--------------|
| Dashboard | Home tab / Main screen |
| Add Mobile | Mobile Sector → Add New |
| Add Gadget | Gadget Sector → Add New |
| New Sale | Sales → New Sale |
| View Reports | Reports → Profit/Loss |
| Export Data | Settings → Export as Excel/PDF |
| Search | Use Global Search feature |

---

## Important Notes

### Database
- All data is backed up in Firebase Firestore
- Local cache enabled for offline access
- Data syncs automatically when online

### Backups
The app automatically:
- Syncs data to Firestore (requires internet)
- Maintains local cache
- Exports can be done manually from Settings

### Data Export
You can export your business data as:
- **Excel (.xlsx)** - Full detailed reports
- **PDF** - Professional formatted reports

---

## Troubleshooting

### App won't start
- Ensure Windows 10 or later is installed
- Try restarting your computer
- Delete the app and rebuild if issues persist

### Firebase connection issues
- Check your internet connection
- Verify your Firebase configuration
- Check firewall settings if behind a corporate network

### Data not syncing
- Check internet connection
- Go to Settings → Sync Data
- Restart the application

### Performance issues
- Close other applications
- Clear app cache from Settings
- Reduce the number of items displayed per page

---

## Rebuild Instructions (If Needed)

To rebuild the app after making code changes:

```powershell
cd "d:\web app\I-buzz bd mangement"
flutter clean
flutter pub get
flutter build windows
```

Then run the new executable from:
```
build\windows\x64\runner\Release\ibuzz_bd_management.exe
```

---

## Support Resources

### Documentation
- See `README.md` for project information
- Check `FIREBASE_SETUP.md` for Firebase configuration

### Code Analysis
- See `ANALYSIS_AND_FIX_REPORT.md` for detailed error fixes

### Application Files
- Configuration: `pubspec.yaml`
- Firebase Config: `firebase.json` and `google-services.json`
- Settings: `firebase_options.dart`

---

## Current Status

✅ **Analysis:** Complete - No critical errors
✅ **Build:** Successful 
✅ **Installation:** Complete on Windows
✅ **Runtime:** Application is running
✅ **Ready to Use:** Yes

---

**Last Updated:** March 17, 2026
**Version:** 1.0.1
**Platform:** Windows 10+

Happy managing! 🎉
