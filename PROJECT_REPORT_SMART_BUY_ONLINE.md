# A Project Report
# on
# SMART BUY ONLINE (I-BUZZ BD MANAGEMENT)
### A Scalable Cross-Platform Inventory, Point-of-Sale, and Financial Analytics Management System for Retail Enterprises

**CSE 400: Software Development Project IV**

---

### SUBMITTED BY:

| Name | ID | Intake | Section |
| :--- | :---: | :---: | :---: |
| **Muhammad Raihan** | 22235103068 | 51 | 2 |
| **Asif Raihan Rafi** | 22235103281 | 51 | 2 |
| **Ehsanul Haque** | 22235103075 | 51 | 2 |
| **Sadia Noor** | 22235103286 | 51 | 2 |

---

### SUPERVISED BY:
**Shampa Banik**  
*Lecturer,*  
*Department of Computer Science and Engineering*

---

**DEPARTMENT OF COMPUTER SCIENCE AND ENGINEERING**  
**BANGLADESH UNIVERSITY OF BUSINESS AND TECHNOLOGY (BUBT)**  
*August 2026*

\newpage

---

## Abstract

Retail smartphone and electronics businesses in emerging markets such as Bangladesh face acute operational inefficiencies due to reliance on fragmented manual ledgers, basic spreadsheets, or generic point-of-sale (POS) systems that fail to address domain-specific complexities. These complexities include mandatory individual device tracking via unique International Mobile Equipment Identity (IMEI) numbers, dynamic cost accumulation incorporating transportation overheads, customer credit ("Baki") tracking with partial payments, and accurate real-time calculation of true net profit after deducting categorized operational expenditures, employee payroll advances, and inventory losses. 

**Smart Buy Online (I-Buzz BD Management)** is an enterprise-grade, cross-platform retail management and financial intelligence platform designed to eliminate these pain points. Built with the **Flutter** framework and powered by a cloud-native **Firebase (Cloud Firestore)** backend with offline-first local synchronization, the platform provides seamless unified operation across Web browsers, Windows desktop environments, and mobile devices (Android and iOS).

The system integrates ten cohesive functional domains:
1. Secure role-based authentication and multi-user access control.
2. IMEI-serialized mobile device inventory management with dynamic net purchase cost accumulation.
3. Gadget and accessory inventory with margin-based pricing algorithms.
4. Fast Point-of-Sale (POS) checkout with split payment options (Cash, Card, MFS, Baki).
5. Comprehensive Customer Due ("Baki") ledger with automated payment reconciliation.
6. Categorized operational expense tracking (rent, utility, transportation, maintenance).
7. Employee payroll, salary scale, and advance disbursement management.
8. Partner capital investment and equity allocation tracking.
9. Interactive financial business intelligence and graphical analytics powered by `fl_chart`.
10. Automated PDF invoice/receipt compilation, thermal printer output, and bulk Excel data import/export with automated integrity auditing.

This report comprehensively documents the operational problem statement, comparative analysis of existing commercial systems, theoretical foundation, Agile/Scrum developmental methodology, system analysis and design (including architectural models, DFDs, ERDs, and core algorithms), front-end and back-end implementation details, a complete user manual of all deployed interfaces, system limitations, and strategic future roadmap.

\newpage

---

## Table of Contents

- **Abstract** ................................................................................................................................. i
- **List of Figures** .................................................................................................................... ii
- **List of Tables** ..................................................................................................................... iii

### Chapter 1: INTRODUCTION ................................................................................................ 1
- **1.1. Problem Specification** ................................................................................................. 1
- **1.2. Objectives** .................................................................................................................. 2
- **1.3. Scope** ......................................................................................................................... 3
  - *In-Scope (Implemented Modules)* ................................................................................. 3
  - *Out-of-Scope (Reserved for Future Roadmap)* ............................................................... 3
- **1.4. Organization of Project Report** .................................................................................... 4

### Chapter 2: BACKGROUND ................................................................................................... 5
- **2.1. Existing System Analysis** ............................................................................................. 5
  - *A. Generic Cloud POS Systems (Square, Lightspeed, Odoo)* .......................................... 5
  - *B. Spreadsheets (Microsoft Excel, Google Sheets)* ....................................................... 5
  - *C. Traditional Manual Paper Ledgers & Desktop Tally* ................................................. 6
  - *Gap Identified* ............................................................................................................. 6
- **2.2. Supporting Literatures & Theoretical Principles** ......................................................... 6
  - *Client-Server & Backend-as-a-Service (BaaS) Architecture* ............................................. 6
  - *NoSQL Document Data Modeling & Eventual Consistency* .............................................. 7
  - *Declarative State Management & Unidirectional Data Flow* ............................................ 7
  - *Cross-Platform Native Rendering Engines* ..................................................................... 8
  - *Double-Entry Accounting & Net Profit Calculation Logic* ................................................ 8

### Chapter 3: SYSTEM ANALYSIS & DESIGN ............................................................................ 9
- **3.1. Technology & Tools** .................................................................................................... 9
- **3.2. Model & Diagrams** .................................................................................................... 10
  - **3.2.1. SDLC Model (Agile / Scrum Methodology)** ......................................................... 10
  - **3.2.2. Layered System Architecture** ............................................................................. 12
  - **3.2.3. Use Case Diagram** ............................................................................................. 14
  - **3.2.4. Context Level Diagram (DFD Level 0)** ................................................................ 16
  - **3.2.5. Data Flow Diagram (DFD Level 1)** ...................................................................... 17
  - **3.2.6. Database Schema & Data Models** ...................................................................... 18
  - **3.2.7. Core Financial & Stock Algorithms & Flowcharts** ................................................ 21

### Chapter 4: IMPLEMENTATION ........................................................................................... 24
- **4.1. Front-End Interface Design & UI/UX Architecture** ..................................................... 24
  - *Design Tokens & Color Palette* ..................................................................................... 24
  - *Localization (Bangla & English)* ................................................................................... 25
  - *Riverpod State Management Implementation* .............................................................. 25
- **4.2. Back-End Services & Persistence Layer** ..................................................................... 26
  - *Cloud Firestore Data Architecture* .............................................................................. 26
  - *Security Rules & Access Control* .................................................................................. 27
  - *Offline Persistence & Synchronization* ......................................................................... 27
- **4.3. Functional Modules Specification** ............................................................................. 28
  - *Module 1: Authentication & Access Control* ................................................................. 28
  - *Module 2: Real-Time Executive Dashboard & KPI Metrics* ............................................ 28
  - *Module 3: Serialized Mobile Phone Inventory* ............................................................. 29
  - *Module 4: Gadget & Accessory Inventory* .................................................................... 29
  - *Module 5: Point-of-Sale (POS) & Multi-Channel Billing* ................................................. 30
  - *Module 6: Customer Due ("Baki") & Credit Reconciliation* ............................................ 30
  - *Module 7: Operational Expense & Rent Book* ............................................................... 31
  - *Module 8: Employee Payroll & Advances* .................................................................... 31
  - *Module 9: Capital Investment & Partner Equity* ........................................................... 31
  - *Module 10: PDF Invoicing, Thermal Receipts & Excel Audit* ........................................... 32

### Chapter 5: USER MANUAL ................................................................................................ 33
- **5.1. System Requirements** .............................................................................................. 33
  - *5.1.1. Hardware Requirements (Client & Web/Desktop/Mobile)* .................................... 33
  - *5.1.2. Software Requirements (Runtime & Cloud Infrastructure)* .................................... 33
- **5.2. User Interface Walkthrough** ...................................................................................... 34
  - *5.2.1. Authentication & Role Gateway* .......................................................................... 34
  - *5.2.2. Executive Dashboard & Real-Time Analytics* ....................................................... 35
  - *5.2.3. Mobile Stock Management & IMEI Registry* ........................................................ 36
  - *5.2.4. Gadget Stock & Margin Controller* ..................................................................... 37
  - *5.2.5. Sales Terminal, Cart & Invoice Generation* .......................................................... 38
  - *5.2.6. Customer Due ("Baki") Ledger & Repayment Interface* ......................................... 39
  - *5.2.7. Expense & Salary Administration* ........................................................................ 40
  - *5.2.8. Comprehensive Financial Reports & Profit/Loss Visualizer* .................................... 41
  - *5.2.9. Bulk Data Import, Export & Integrity Audit* .......................................................... 42
  - *5.2.10. Settings & Theme Customization* ...................................................................... 43

### Chapter 6: CONCLUSION & FUTURE SCOPE ........................................................................ 44
- **6.1. Conclusion** ................................................................................................................ 44
- **6.2. System Limitations** ................................................................................................... 45
- **6.3. Future Works & Enhancements** ................................................................................. 45

### References ......................................................................................................................... 47

### Appendix A ........................................................................................................................ 48
- **A.1. Project Repository & Deployment Details** ................................................................. 48
- **A.2. Complete Directory Structure** ................................................................................... 48
- **A.3. Test Cases & Verification Summary** ......................................................................... 50

\newpage

---

## List of Figures

| Figure No. | Figure Name | Location |
| :---: | :--- | :---: |
| **Figure 1** | Layered System Architecture of Smart Buy Online | Chapter 3 |
| **Figure 2** | Use Case Diagram | Chapter 3 |
| **Figure 3** | Context Level Diagram (DFD Level 0) | Chapter 3 |
| **Figure 4** | Data Flow Diagram (DFD Level 1) | Chapter 3 |
| **Figure 5** | Cloud Firestore NoSQL Entity Relationship / Collection Schema Diagram | Chapter 3 |
| **Figure 6** | Dynamic Unit Cost Accumulation & Sale Flowchart | Chapter 3 |
| **Figure 7** | Net Profit & Loss Calculation Lifecycle Flowchart | Chapter 3 |
| **Figure 8** | Login & Authentication Screen | Chapter 5 |
| **Figure 9** | Executive Dashboard with Financial KPIs & Quick Actions | Chapter 5 |
| **Figure 10** | Mobile Phone Inventory with Search & IMEI Registry | Chapter 5 |
| **Figure 11** | Add / Edit Mobile Stock Dialog with Auto-Calculating Cost Overhead | Chapter 5 |
| **Figure 12** | Gadget Inventory & Stock Level Screen | Chapter 5 |
| **Figure 13** | Point-of-Sale (POS) Screen & Multi-Mode Payment Dialog | Chapter 5 |
| **Figure 14** | Customer Due ("Baki") Ledger & Repayment Dialog | Chapter 5 |
| **Figure 15** | Categorized Expense & Salary Management Screen | Chapter 5 |
| **Figure 16** | Interactive Financial Reports with Revenue/Profit Charts | Chapter 5 |
| **Figure 17** | Printable PDF & Thermal Invoice Generation Layout | Chapter 5 |
| **Figure 18** | Bulk Excel Data Import & Automatic Audit Screen | Chapter 5 |

---

## List of Tables

| Table No. | Table Name | Location |
| :---: | :--- | :---: |
| **Table 1** | Complete Technology Stack Used in Smart Buy Online | Chapter 3 |
| **Table 2** | Core Cloud Firestore Collections and Document Schemas | Chapter 3 |
| **Table 3** | Primary Application Modules and Routes | Chapter 4 |
| **Table 4** | Key Shared Flutter Widgets and Utilities | Chapter 4 |
| **Table 5** | Core Business Calculations & Formula Definitions | Chapter 4 |
| **Table 6** | Client and Deployment Platform Requirements | Chapter 5 |
| **Table 7** | Sample Automated & Manual Test Coverage Results | Appendix A |

\newpage

---

# Chapter 1: INTRODUCTION

## 1.1. Problem Specification

The retail telecommunications and consumer electronics marketplace in Bangladesh is characterized by rapid inventory turnover, high product unit value, slim profit margins, and complex individual device tracking. A typical retail outlet manages hundreds of distinct mobile handsets spanning dozens of brands (e.g., Apple, Samsung, Xiaomi, Realme, Vivo) alongside hundreds of accessory and gadget SKUs. Despite the modern nature of the products sold, the operational management of these establishments remains predominantly outdated, inefficient, and susceptible to severe financial leakage.

Primary operational challenges include:

1. **Lack of Individual Unit (IMEI) Serialization:** Unlike generic retail items identified purely by barcode, mobile handsets are legally and operationally bound to unique 15-digit International Mobile Equipment Identity (IMEI) numbers. Standard retail POS systems treat phones as pooled quantities, making it impossible to trace warranty claims, detect shrinkage, verify purchase sources, or prevent fraudulent customer returns.
2. **Inaccurate Landed Cost Calculation:** In retail electronics, the actual cost of goods sold (COGS) is rarely just the vendor invoice price. Transport fares, courier surcharges, import overheads, and handling fees are incurred per batch. When shop owners calculate profit using only the base purchase price, they suffer from hidden financial losses.
3. **Fragmented Customer Credit ("Baki") Tracking:** In local retail culture, a substantial fraction of transactions involve customer credit or split partial payments. Manual record-keeping in paper notebooks ("Khata") frequently results in forgotten balances, uncollected receivables, disputed figures, and an inability to reconcile shop cash flow.
4. **Distorted Net Profit Assessment:** Store owners frequently conflate Gross Margin (Sales Price − Purchase Price) with True Net Profit. By failing to systematically deduct operational overheads (shop rent, electricity bills, staff refreshments, maintenance), partner withdrawals, and employee salary advances from daily revenues, owners make erroneous business expansion decisions based on fictitious profitability.
5. **Platform Inflexibility & Data Desynchronization:** Shop owners and managers need to monitor operations from multiple touchpoints: desktop terminals at the checkout counter, tablets on the sales floor, and smartphones when away from the shop. Existing desktop-only software lacks real-time cloud synchronization, while pure web apps fail during internet outages common in developing regions.

**Smart Buy Online (I-Buzz BD Management)** directly resolves every one of these problems through a cohesive, cloud-synchronized, and offline-capable cross-platform software system built specifically for electronics retailers.

```
+------------------------------------------------------------------------------------+
|                                THE CORE DILEMMA                                    |
+------------------------------------------------------------------------------------+
|  Manual Khatas / Spreadsheets        vs.        Generic International POS Apps     |
|  - Error-prone calculation                      - No IMEI / Serial tracking        |
|  - High shrinkage & lost Baki                   - Expensive recurring USD fees     |
|  - No real-time multi-device sync               - No localized Baki/Salary logic   |
|  - Inability to compute true Net Profit         - Complete cloud dependency        |
+------------------------------------------------------------------------------------+
                                         |
                                         v
+------------------------------------------------------------------------------------+
|                           SMART BUY ONLINE SOLUTION                                |
|  * Unified Flutter cross-platform architecture (Web, Windows, Android, iOS)       |
|  * Strict IMEI serialization & dynamic landed cost accumulation                    |
|  * Integrated Baki, Expense, Payroll, and Investment financial engine              |
|  * Cloud Firestore real-time synchronization with offline persistence              |
|  * 1-Click Bengali/English PDF invoicing, thermal printing, and Excel audit        |
+------------------------------------------------------------------------------------+
```

---

## 1.2. Objectives

The primary engineering and operational objectives of the **Smart Buy Online** project are to:

- **Deliver Seamless Cross-Platform Parity:** Construct a single unified codebase utilizing Flutter that compiles natively to Web (HTML/CanvasKit/WASM), Windows Desktop (x64), and Mobile (Android and iOS), ensuring 100% feature consistency across all devices.
- **Implement Strict IMEI & Serial Number Governance:** Provide individual serialization for every phone unit from procurement to customer sale, enabling instant IMEI lookup, warranty validation, and return verification.
- **Automate Dynamic Landed Cost Accumulation:** Establish algorithmic cost calculation where per-unit purchase price automatically incorporates distributed transport and logistics expenses:
  $$\text{Net Purchase Cost} = \text{Base Purchase Price} + \text{Allocated Transport Cost}$$
- **Engine a Unified Financial & Net Profit Ecosystem:** Compute true net business performance in real time by evaluating:
  $$\text{Net Profit} = \text{Total Realized Gross Profit} - (\text{Operating Expenses} + \text{Salaries Paid} + \text{Inventory Losses})$$
- **Digitize Customer Credit ("Baki") Lifecycle:** Provide an end-to-end ledger tracking customer balances, partial cash collections, due payment histories, and automated customer statement generation.
- **Enable Resilient Offline-First Operations:** Leverage Cloud Firestore's client cache and local database persistence so checkout staff can continue processing sales even during internet outages, synchronizing seamlessly upon reconnection.
- **Produce High-Fidelity Printable Documents & Data Portability:** Enable instant generation of 80mm thermal receipts, professional A4 Bengali/English PDF invoices, and automated Excel sheet imports/exports with automated anomaly auditing.
- **Provide Role-Based Multi-User Security:** Enforce secure authentication and permission policies distinguishing Store Owners/Administrators, Inventory Managers, and Sales Staff.

---

## 1.3. Scope

### In-Scope (Implemented Modules)
- **Multi-Role Authentication:** Email/password authentication, persistent user sessions, and granular permission boundaries.
- **Executive Dashboard:** Live analytical summary cards (Total Inventory Value, Today's Sales, Month's Net Profit, Outstanding Baki, Stock Counts) and interactive trend charts.
- **Mobile Phone Sector:** Add, edit, search, filter, and delete phone inventory with Model, Brand, Color, Storage/RAM, Purchase Price, Transport Cost, Selling Price, and IMEI registration.
- **Gadget & Accessory Sector:** Bulk SKU inventory tracking, stock replenishment alerts, and automated retail margin calculators.
- **Point-of-Sale (POS) & Checkout:** Instant multi-item cart, dynamic discount calculation, multiple payment methods (Cash, bKash, Nagad, Bank Card, Customer Due/Baki), and customer invoice generation.
- **Customer Dues ("Baki") Ledger:** Customer directory, outstanding debt balances, installment payment recording, and due collection tracking.
- **Operational Expense Book:** Categorized expense tracking (Shop Rent, Electricity, Staff Meals, Marketing, Maintenance) with date filtering.
- **Employee Payroll & Advances:** Staff directory, base salary schedules, advance payment logging, and monthly disbursement calculations.
- **Capital & Partner Investment Tracker:** Investor/Partner equity logging, capital injections, withdrawals, and balance sheets.
- **Financial Analytics & Reporting:** Real-time calculation of Gross Sales, Cost of Goods Sold, Gross Profit, Total Expenses, Net Profit, and Graphical Trend Charts (`fl_chart`).
- **Receipt & Invoice Generator:** Formatted 80mm thermal receipt printing and professional A4 PDF export using Google Noto Sans Bengali font support.
- **Bulk Excel Import/Export & Data Audit:** 1-Click Excel (.xlsx) data import with schema validation, missing field detection, duplicate IMEI checking, and comprehensive CSV/Excel backup exports.

### Out-of-Scope (Reserved for Future Roadmap)
- **Direct Hardware Payment Terminal (EMV POS) Integration:** Credit card swipe transactions are currently recorded manually rather than communicating via direct serial/USB protocol with banking POS hardware.
- **Automated SMS / WhatsApp Gateway Integration:** Sending automated SMS invoice links upon sale completion (currently provided via direct PDF sharing/printing).
- **Multi-Branch Centralized Warehouse Routing:** Real-time stock transfer workflows between physically separate retail branch locations.
- **AI-Powered Predictive Restocking:** Machine learning algorithms forecasting inventory depletion based on seasonal buying patterns.

---

## 1.4. Organization of Project Report

The remainder of this report is structured as follows:
- **Chapter 2 (Background):** Evaluates existing market solutions, identifies key functionality gaps, and details the theoretical, computational, and architectural principles underlying the platform.
- **Chapter 3 (System Analysis & Design):** Presents the complete technology stack, the Agile/Scrum development model, high-level system architecture, Use Case diagrams, DFD Level 0 and Level 1 models, Cloud Firestore database schemas, and core financial algorithms.
- **Chapter 4 (Implementation):** Discusses front-end UI/UX architecture, theme design tokens, Riverpod state management, backend Firestore services, security rules, and detailed functional specifications of all ten operational modules.
- **Chapter 5 (User Manual):** Outlines client and server hardware/software requirements and provides a step-by-step visual walkthrough of all deployed user interfaces.
- **Chapter 6 (Conclusion & Future Scope):** Summarizes project outcomes, technical reflections, system limitations, and the future development roadmap.
- **References & Appendix A:** Academic bibliography, repository deployment instructions, complete directory tree, and test verification matrices.

\newpage

---

# Chapter 2: BACKGROUND

## 2.1. Existing System Analysis

To identify the precise functional and economic gaps in retail management software, three prevailing categories of solutions were critically analyzed:

```
+----------------------------------------------------------------------------------------------------+
|                                    COMPETITIVE ANALYSIS MATRIX                                     |
+----------------------+--------------------+--------------------+--------------------+--------------+
| Feature / Attribute  | Generic Cloud POS  | MS Excel / Sheets  | Desktop Tally/Khata| Smart Buy    |
+----------------------+--------------------+--------------------+--------------------+--------------+
| IMEI Serialization   | Rare / Complex add | Manual text only   | Unsupported        | Native/Strict|
| Transport Cost Add   | Unsupported        | Manual formulas    | Complex config     | Automatic    |
| Local Baki Ledger    | Unsupported (US/EU)| Manual tracking    | Basic              | Full-featured|
| Real-Time Cloud Sync | Yes                | No (collaboration) | No (Local DB only) | Yes (Global) |
| Offline Resilience   | Limited            | Local file only    | Local file only    | Robust Sync  |
| Cross-Platform (Web) | Browser only       | Web / App          | Desktop only       | Web/Desk/Mob |
| Bengali Thermal PDF  | Unsupported        | Unsupported        | Unsupported        | Integrated   |
| Total Cost / License | $40 - $150 / month | Microsoft 365 Sub  | High one-time fee  | Zero license |
+----------------------+--------------------+--------------------+--------------------+--------------+
```

### A. Generic Cloud POS Systems (Square, Lightspeed, Odoo)
International cloud point-of-sale systems offer polished user interfaces and cloud dashboards. However:
- They are designed for standard packaged goods (FMCG) or restaurant hospitality, lacking native IMEI serialization workflows required for mobile handset warranty and anti-theft validation.
- They do not accommodate local credit paradigms such as "Baki", where loyal customers take products with partial down payments and pay variable installments over time.
- Their monthly recurring subscription fees in US Dollars ($40–$150/month) represent a prohibitive ongoing cost for small-to-medium retail shops in developing economies.

### B. Spreadsheets (Microsoft Excel, Google Sheets)
Many shop owners resort to maintaining multiple spreadsheet workbooks for stock, sales, and expenses.
- **Critical Flaws:** Spreadsheets lack data integrity constraints, allowing accidental cell overwrites, duplicate IMEIs, and broken formula references.
- They offer no concurrent multi-user role separation (e.g., preventing a sales clerk from viewing overall shop profit or altering historical purchase prices).
- Point-of-sale checkout is painfully slow, requiring manual data entry without barcode scanning or automated thermal receipt generation.

### C. Traditional Manual Paper Ledgers ("Khatas") & Legacy Desktop Software
A significant portion of retailers still use physical paper notebooks or legacy single-computer desktop applications.
- Paper records are vulnerable to physical damage, fire, loss, and unauthorized tampering.
- Calculating month-end profit and loss requires days of manual tallying, almost always leading to arithmetic errors and overlooked expenses.
- Legacy desktop software ties operations to a single physical computer, making remote monitoring by the business owner impossible.

### Gap Identified
No existing accessible software combines **strict IMEI tracking**, **automatic landed cost accumulation**, **localized Baki credit management**, **integrated P&L financial analytics**, and **cross-platform cloud/offline operation** in a single cohesive solution. **Smart Buy Online** was designed specifically to occupy this crucial niche.

---

## 2.2. Supporting Literatures & Theoretical Principles

The system design and technological selections of **Smart Buy Online** are grounded in established software engineering and computer science principles:

### 1. Client-Server & Backend-as-a-Service (BaaS) Architecture
Rather than building a custom monolithic web server requiring continuous infrastructure maintenance, patch management, and server provisioning, the system adopts a **Serverless / BaaS architecture** utilizing Google Firebase. Client nodes (Flutter Web, Windows Desktop, Android) communicate directly with managed cloud infrastructure over TLS-encrypted HTTPS and WebSocket connections, leveraging Google's global distributed edge network for high availability ($99.95\%$) and low latency.

### 2. NoSQL Document Data Modeling & Eventual Consistency
Cloud Firestore employs a flexible, document-oriented NoSQL model. Data is structured into root-level collections (`mobile_stock`, `gadget_stock`, `sales`, `expenses`, `salary`, `capital`, `customers`) containing JSON-like schema-flexible documents. 
- **Subcollections & Query Efficiency:** Complex relationships (such as payment installment logs under a specific customer document) are maintained as subcollections, ensuring queries scale with the size of the result set rather than the total volume of database records.
- **ACID Batch Operations:** Critical multi-document transactions—such as updating an IMEI device status to `sold`, incrementing total sales counters, creating a customer invoice, and logging a receivable balance—are executed using atomic `WriteBatch` operations to guarantee ACID compliance.

### 3. Declarative Reactive State Management (Riverpod)
The application front-end utilizes **Flutter Riverpod 2.0**, a compile-safe, reactive state management framework. Riverpod ensures unidirectional data flow:
- Global data streams (`StreamProvider`) bind UI widgets directly to Firestore real-time snapshot listeners.
- Any change in the cloud database immediately triggers reactive, granular re-rendering of only the affected UI components, eliminating unnecessary full-screen rebuilds and preventing memory leaks.

### 4. Cross-Platform Native Rendering (Flutter Engine)
Flutter bypasses traditional web views or native platform UI wrappers by compiling Dart source code to native ARM/x86 machine code for Desktop/Mobile and optimized JavaScript/WebAssembly for Web. The internal **Impeller / Skia graphics engine** draws every pixel directly onto a GPU-accelerated canvas at a consistent 60–120 FPS, ensuring consistent typography, animations, and layouts across Windows, macOS, Android, iOS, and Web.

### 5. Double-Entry Principles & Real-Time Financial Engineering
The core financial engine enforces accurate accounting standards:
$$\text{Gross Profit} = \sum_{i=1}^{n} (\text{Selling Price}_i - \text{Net Purchase Price}_i)$$
$$\text{Operating Expenses} = \sum \text{Rent} + \sum \text{Bills} + \sum \text{Meals} + \sum \text{Transport} + \sum \text{Misc}$$
$$\text{Total Employee Payroll} = \sum (\text{Base Salary} + \text{Bonuses} - \text{Advances Deducted})$$
$$\text{True Net Profit} = \text{Gross Profit} - (\text{Operating Expenses} + \text{Total Employee Payroll} + \text{Damaged Stock Write-offs})$$

\newpage

---

# Chapter 3: SYSTEM ANALYSIS & DESIGN

## 3.1. Technology & Tools

Table 1 details the complete enterprise technology stack utilized in the engineering and deployment of **Smart Buy Online**.

| Layer / Concern | Technology / Library Used | Version | Purpose |
| :--- | :--- | :---: | :--- |
| **Core UI Framework** | Flutter SDK (Dart 3) | 3.47.2 / 3.13.2 | Cross-platform declarative UI rendering engine |
| **Target Platforms** | Web, Windows Desktop, Android, iOS | Multi | High-performance client deployment targets |
| **State Management** | Flutter Riverpod & Annotations | ^2.6.1 | Compile-safe reactive state architecture |
| **Cloud Database** | Google Cloud Firestore | ^6.1.1 | Real-time NoSQL cloud persistence & listeners |
| **Authentication** | Firebase Authentication | ^6.1.3 | Secure identity management & token auth |
| **Cloud Storage** | Firebase Storage | ^13.0.5 | Media, receipts, and invoice image storage |
| **Local Cache / Storage** | SharedPreferences & Hive | ^2.3.3 / ^2.2.3 | Offline settings, tokens, and local cache |
| **Data Visualization** | `fl_chart` | ^1.1.1 | Interactive financial line, bar, and pie charts |
| **PDF Compilation** | `pdf` & `printing` | ^3.11.1 / ^5.13.3 | Dynamic PDF document layout & thermal print |
| **Spreadsheet Engine** | `excel` | ^4.0.6 | Binary `.xlsx` generation & parsing engine |
| **Typography** | `google_fonts` (Noto Sans Bengali, Inter) | ^6.2.1 | Unicode Bengali & Latin typography |
| **Vector Icons & UI** | `cupertino_icons`, `flutter_svg`, `shimmer` | Latest | Responsive UI icons, vectors, and skeleton loaders |
| **Network Status** | `connectivity_plus` | ^7.0.0 | Offline/online network connectivity detection |
| **Date & Time Utilities** | `intl`, `table_calendar` | Latest / ^3.1.2 | Localized currency formatting & date pickers |
| **Hosting & CI/CD** | Firebase Hosting & Vercel | Production | High-availability global edge web hosting |
| **Version Control** | Git & GitHub | Latest | Source code management & collaboration |

*Table 1: Complete Technology Stack Used in Smart Buy Online*

---

## 3.2. Model & Diagrams

### 3.2.1. SDLC Model (Agile / Scrum Methodology)

To mitigate integration risks across multiple deployment platforms (Web, Windows, Android) and ensure continuous alignment with retail operational requirements, the team adopted the **Iterative and Incremental (Agile/Scrum)** development model.

```
       +-------------------------------------------------------------+
       |               AGILE SPRINT LIFECYCLE (2 WEEKS)              |
       +-------------------------------------------------------------+
       |                                                             |
       |     [Sprint Planning]  --->  [Design & Architecture]        |
       |            ^                                |               |
       |            |                                v               |
       |   [Sprint Retrospective]       [Implementation & Code]      |
       |            ^                                |               |
       |            |                                v               |
       |     [Review & Demo]    <---   [Testing & Verification]      |
       |                                                             |
       +-------------------------------------------------------------+
```

The project was executed across four structured sprints:

- **Sprint 1: Core Foundation & Inventory Architecture**
  - Project scaffolding, Riverpod architecture, and Firebase Authentication.
  - Mobile phone inventory module with IMEI serialization, purchase price recording, and transport cost accumulation.
  - Gadget inventory module with stock level tracking and margin calculation.
  - Basic Firestore collections and security rules setup.

- **Sprint 2: Point of Sale (POS), Invoicing & Customer Dues**
  - POS checkout terminal with real-time stock deduction.
  - Dynamic invoice generation supporting Cash, bKash, Nagad, Card, and Baki payments.
  - Customer Due ("Baki") ledger with customer profile creation and payment recording.
  - 80mm thermal receipt and A4 PDF invoice compiler with Bengali Unicode font integration.

- **Sprint 3: Operational Accounting & Financial Analytics Engine**
  - Categorized Expense Book (Rent, Utilities, Maintenance, Food).
  - Employee Payroll module (Salary scales, advances, monthly payout reconciliation).
  - Capital & Partner Investment tracking.
  - Real-time P&L computational engine and executive dashboard KPI cards.
  - Graphical data visualization using `fl_chart`.

- **Sprint 4: Data Portability, Bulk Import/Export, Audit & Multi-Platform Deployment**
  - 1-Click Excel (.xlsx) bulk inventory import with automated error detection and IMEI sanitization.
  - Comprehensive CSV/Excel full-database export service.
  - Data audit engine validating collection integrity, negative balances, and orphaned records.
  - Web, Windows Desktop (MSI), and Android APK production build compilation and release.

---

### 3.2.2. Layered System Architecture

**Smart Buy Online** follows a clean, decoupled **Four-Tier Clean Architecture** model, ensuring complete separation of concerns between user interface presentation, state management, business logic services, and cloud persistence.

```
+-----------------------------------------------------------------------------------+
|                           PRESENTATION LAYER (UI)                                 |
|  - Material 3 Responsive Screens (Dashboard, Mobile Stock, POS, Reports, Baki)    |
|  - Custom Atomic Widgets (Summary Cards, IMEI Chips, Data Tables, Dialogs)        |
|  - Theme System (Dark / Light Mode) & Dual-Language Localization (EN / BN)        |
+-----------------------------------------------------------------------------------+
                                         |
                                         v
+-----------------------------------------------------------------------------------+
|                        STATE MANAGEMENT LAYER (RIVERPOD)                          |
|  - StateNotifierProviders & StreamProviders (MobileStockList, SalesProvider)      |
|  - Computed Selectors & AsyncNotifiers for Real-Time UI Reactivity                |
|  - Local Cache State (SharedPreferences, Hive)                                    |
+-----------------------------------------------------------------------------------+
                                         |
                                         v
+-----------------------------------------------------------------------------------+
|                         SERVICE & DOMAIN LOGIC LAYER                              |
|  - Calculations Engine (Net Purchase Cost, Gross Margin, True Net Profit)         |
|  - Receipt & Invoicing Service (pw.Document PDF & Thermal Printing Pipeline)      |
|  - Bulk Import & Data Audit Service (Excel Schema Validator, IMEI Deduplicator)   |
|  - Export Service (Multi-Sheet Excel & CSV Compilers)                             |
+-----------------------------------------------------------------------------------+
                                         |
                                         v
+-----------------------------------------------------------------------------------+
|                       DATA & CLOUD PERSISTENCE LAYER                              |
|  - Google Cloud Firestore (Real-Time NoSQL Collections & Atomic WriteBatches)     |
|  - Firebase Authentication (Secure JWT Token Validation)                          |
|  - Firebase Storage (Digital Receipts & Document Archives)                        |
|  - Offline Persistence Engine (IndexedDB on Web, SQLite on Windows/Android)       |
+-----------------------------------------------------------------------------------+
```

*Figure 1: Layered System Architecture of Smart Buy Online*

---

### 3.2.3. Use Case Diagram

The system supports three distinct operational actors:
1. **Store Owner / Administrator:** Complete authority over capital investments, financial reports, user roles, salary scales, bulk imports, and system settings.
2. **Sales Executive / Staff:** Authorized to perform stock lookups, process POS sales, record partial payments, register customer dues, and generate customer receipts.
3. **Inventory Manager:** Authorized to add incoming mobile stock, enter IMEI numbers, log supplier invoices, record transport costs, and manage gadget stock levels.

```
                  +----------------------------------------------+
                  |           SMART BUY ONLINE SYSTEM            |
                  +----------------------------------------------+
                  |                                              |
(Sales Staff) ----+---> [ Login & Authenticate ]                 |
                  |                                              |
                  +---> [ Search & Lookup Phone Inventory ]      |
                  |                                              |
                  +---> [ Process POS Sale & Checkout ]          |
                  |                                              |
                  +---> [ Generate PDF / Thermal Receipt ]       |
                  |                                              |
                  +---> [ Record Customer Due ("Baki") ]         |
                  |                                              |
(Inv. Manager) ---+---> [ Add / Update Mobile Stock & IMEIs ]    |
                  |                                              |
                  +---> [ Manage Gadget & Accessory Stock ]      |
                  |                                              |
                  +---> [ Record Inward Transport Costs ]        |
                  |                                              |
(Store Owner) ----+---> [ View Executive Dashboard & KPIs ]      |
                  |                                              |
                  +---> [ Monitor Real-Time Net Profit/Loss ]    |
                  |                                              |
                  +---> [ Manage Shop Expenses & Rent Book ]     |
                  |                                              |
                  +---> [ Process Employee Salaries & Advances ] |
                  |                                              |
                  +---> [ Manage Capital & Partner Equity ]      |
                  |                                              |
                  +---> [ Execute Bulk Excel Import & Audit ]    |
                  |                                              |
                  +---> [ Export Financial & Inventory Reports ] |
                  |                                              |
                  +----------------------------------------------+
```

*Figure 2: Use Case Diagram*

---

### 3.2.4. Context Level Diagram (DFD Level 0)

The Context Level Diagram (DFD-0) models the complete application as a single centralized processing entity interacting with external entities.

```
                                  +-----------------------+
                                  |    Firebase Auth &    |
                                  |    Cloud Firestore    |
                                  +-----------------------+
                                     ^                 |
                     Real-time sync  |                 | Document streams &
                     & write batches |                 | Auth validation
                                     |                 v
+------------------+         +-------------------------------+         +------------------+
|                  | Inputs  |                               | Outputs |                  |
|   Store Staff    |-------->|       SMART BUY ONLINE        |-------->|   End Customer   |
| (Admin / Sales / | Sales,  |     MANAGEMENT PLATFORM       | Invoice,| (Physical /      |
|  Inventory)      | Stock,  |                               | Receipt,|  WhatsApp/PDF)   |
|                  | Expense |          (Process 0)          | Ledger  |                  |
+------------------+         +-------------------------------+         +------------------+
                                     |                 ^
                        Print stream |                 | Data streams
                        & downloads  |                 | (.xlsx files)
                                     v                 |
                                  +-----------------------+
                                  |   Hardware Peripherals|
                                  |   & File System       |
                                  |  (Thermal/Excel/PDF)  |
                                  +-----------------------+
```

*Figure 3: Context Level Diagram (DFD Level 0)*

---

### 3.2.5. Data Flow Diagram (DFD Level 1)

The DFD Level 1 decomposes the system into its six core sub-processes and their corresponding Cloud Firestore document data stores:

```
[Store User] ---> (1.0 Auth & User Session) <---> [D1: users]
       |
       +--------> (2.0 Inventory Inwarding)  <---> [D2: mobile_stock / gadget_stock]
       |                     |
       |                     v
       +--------> (3.0 POS Sales & Billing)  <---> [D3: sales]
       |                     |                          |
       |                     v                          v
       +--------> (4.0 Customer Due Mgmt)    <---> [D4: customers / dues]
       |                     |                          |
       |                     v                          v
       +--------> (5.0 Operational Expense)  <---> [D5: expenses / salary / capital]
       |                     |                          |
       |                     +--------------------------+
       |                                                |
       v                                                v
(6.0 Financial Intelligence & Reporting) <==============+
       |
       v
[Executive Dashboard, Charts, PDF Invoices & Excel Exports]
```

*Figure 4: Data Flow Diagram (DFD Level 1)*

---

### 3.2.6. Database Schema & Data Models

Cloud Firestore stores information as JSON-like documents within root collections. Table 2 outlines the primary collections, key fields, data types, and integrity constraints.

| Collection Name | Key Fields & Data Types | Relationships & Constraints | Purpose |
| :--- | :--- | :--- | :--- |
| **`users`** | `uid` (String, PK), `email` (String), `displayName` (String), `role` (admin/staff), `createdAt` (Timestamp) | One-to-many with sales and logs | Authentication and authorization control |
| **`mobile_stock`** | `id` (String, PK), `modelName` (String), `brand` (String), `imei` (String, Unique), `ram` (String), `storage` (String), `color` (String), `purchasePrice` (Number), `transportCost` (Number), `netPurchasePrice` (Number), `sellingPrice` (Number), `status` (in_stock/sold/returned), `createdAt` (Timestamp) | Unique constraint on `imei`; linked to `sales` upon checkout | Complete mobile inventory and individual IMEI tracking |
| **`gadget_stock`** | `id` (String, PK), `productName` (String), `category` (String), `quantity` (Int), `unitCost` (Number), `sellingPrice` (Number), `minStockAlert` (Int), `updatedAt` (Timestamp) | Decremented atomically during POS checkout | Non-serialized gadget and accessory inventory |
| **`sales`** | `id` (String, PK), `invoiceNumber` (String, Unique), `customerName` (String), `customerPhone` (String), `items` (Array of Maps), `subtotal` (Number), `discount` (Number), `totalAmount` (Number), `paidAmount` (Number), `dueAmount` (Number), `paymentMethod` (Cash/Card/MFS/Baki), `soldBy` (String), `createdAt` (Timestamp) | Linked to `mobile_stock` via item IDs; linked to `customers` if `dueAmount > 0` | Complete transaction and invoice history |
| **`customers`** | `id` (String, PK), `name` (String), `phone` (String, Unique), `address` (String), `totalPurchases` (Number), `totalDue` (Number), `lastPaymentDate` (Timestamp) | One-to-many with `payments` subcollection | Customer directory and credit ("Baki") tracking |
| **`expenses`** | `id` (String, PK), `title` (String), `category` (Rent/Electricity/Meals/Transport/Misc), `amount` (Number), `notes` (String), `date` (Timestamp), `recordedBy` (String) | Evaluated in P&L Net Profit engine | Shop operational and overhead expenditure book |
| **`salary`** | `id` (String, PK), `employeeName` (String), `role` (String), `baseSalary` (Number), `advancesTaken` (Number), `paidAmount` (Number), `paymentDate` (Timestamp), `month` (String) | Evaluated in P&L Net Profit engine | Employee payroll, advance deductions, and disbursement |
| **`capital`** | `id` (String, PK), `investorName` (String), `amount` (Number), `type` (Investment/Withdrawal), `date` (Timestamp), `notes` (String) | Evaluated in Balance Sheet & Equity calculations | Partner capital contributions and withdrawals |

*Table 2: Core Cloud Firestore Collections and Document Schemas*

---

### 3.2.7. Core Financial & Stock Algorithms

#### 1. Dynamic Unit Landed Cost Accumulation Algorithm
When a batch of mobile handsets is purchased, transport overhead is allocated per unit to calculate the true Net Purchase Price:

```dart
double calculateNetPurchasePrice({
  required double basePurchasePrice,
  required double totalTransportCost,
  required int totalUnitsInBatch,
}) {
  assert(totalUnitsInBatch > 0, "Batch units must be greater than zero");
  final double transportPerUnit = totalTransportCost / totalUnitsInBatch;
  return basePurchasePrice + transportPerUnit;
}
```

```
[Start: Add Mobile Stock]
          |
          v
[Input: Base Price, Transport Overhead, Quantity]
          |
          v
[Compute: Allocated Transport = Transport Overhead / Quantity]
          |
          v
[Compute: Net Purchase Cost = Base Price + Allocated Transport]
          |
          v
[Store in Firestore: netPurchasePrice & status = 'in_stock']
          |
          v
[End]
```

*Figure 6: Dynamic Unit Cost Accumulation & Sale Flowchart*

#### 2. Consolidated Net Profit Engine Algorithm
Net profit is calculated by aggregating gross sales margins and deducting all operating expenses, salaries, and inventory write-offs:

```dart
double calculateTrueNetProfit({
  required List<Sale> completedSales,
  required List<Expense> operatingExpenses,
  required List<SalaryPayment> salariesPaid,
  required List<DamagedStock> writeOffs,
}) {
  // 1. Calculate Realized Gross Margin
  double totalGrossMargin = 0.0;
  for (final sale in completedSales) {
    for (final item in sale.items) {
      final double profitOnItem = item.sellingPrice - item.netPurchasePrice;
      totalGrossMargin += profitOnItem;
    }
    // Deduct invoice-level discount
    totalGrossMargin -= sale.discount;
  }

  // 2. Aggregate Operational Overheads
  final double totalExpenses = operatingExpenses.fold(
    0.0, (sum, expense) => sum + expense.amount
  );

  // 3. Aggregate Payroll
  final double totalSalaries = salariesPaid.fold(
    0.0, (sum, salary) => sum + salary.paidAmount
  );

  // 4. Aggregate Write-offs
  final double totalLosses = writeOffs.fold(
    0.0, (sum, loss) => sum + loss.lossAmount
  );

  // 5. Compute True Net Profit
  return totalGrossMargin - (totalExpenses + totalSalaries + totalLosses);
}
```

```
+-------------------------------------------------------------------------------+
|                      CONSOLIDATED NET PROFIT PIPELINE                         |
+-------------------------------------------------------------------------------+
|                                                                               |
|  Total Revenue (All Sales)                                                    |
|  [-] Total Cost of Goods Sold (Sum of Net Purchase Prices)                    |
|  ---------------------------------------------------------------------------  |
|  [=] GROSS MARGIN                                                             |
|                                                                               |
|  [-] Operating Overheads (Rent, Electricity, Maintenance, Meals)              |
|  [-] Total Employee Payroll & Salary Disbursements                            |
|  [-] Inventory Damage & Lost Device Write-Offs                                |
|  ---------------------------------------------------------------------------  |
|  [=] TRUE NET OPERATING PROFIT                                                |
|                                                                               |
+-------------------------------------------------------------------------------+
```

*Figure 7: Net Profit & Loss Calculation Lifecycle Flowchart*

\newpage

---

# Chapter 4: IMPLEMENTATION

## 4.1. Interface Design & UI/UX Architecture

The user interface of **Smart Buy Online** is designed around a modern, premium **Material Design 3** visual language. Because retail shop environments range from brightly lit checkout counters to dimly lit back-offices, the interface implements an adaptive Theme Engine with high-contrast Dark and Light modes.

### Design Tokens & Color Palette
- **Primary Color:** Deep Sapphire Navy (`#0F172A` / `#1E293B`) providing professional visual grounding.
- **Accent Brand Color:** Electric Indigo (`#3B82F6` / `#6366F1`) highlighting interactive actions, primary buttons, and active tabs.
- **Success & Profit:** Vibrant Emerald Green (`#10B981`) denoting positive margins, paid invoices, and in-stock items.
- **Warning & Due:** Amber Gold (`#F59E0B`) signaling customer Baki, partial payments, and low stock warnings.
- **Danger & Expense:** Coral Red (`#EF4444`) highlighting shop expenses, outstanding losses, and deleted items.
- **Corner Radii & Elevation:** Consistent 12px and 16px soft rounded cards with subtle drop shadows (`elevation: 2`) for card-based spatial hierarchy.

### Localization (Bangla & English)
The system integrates native **dual-language support (English and Bengali)**:
- All financial metrics format numbers and currency using the local Taka symbol (`৳`) via `intl.NumberFormat.currency(symbol: '৳', decimalDigits: 2)`.
- PDF generation embeds Google's **Noto Sans Bengali** font family, ensuring complex Bengali glyphs, conjunct characters (যুক্তবর্ণ), and numerical digits render with typographic precision on both thermal rolls and A4 invoice pages.

### Riverpod State Architecture
State management is organized into clean, domain-specific modules:
- `mobileStockListProvider`: StreamProvider subscribing directly to `FirebaseFirestore.instance.collection('mobile_stock')`.
- `salesListProvider`: Real-time reactive stream of sales transactions with date-range filtering.
- `dashboardMetricsProvider`: Derived FutureProvider computing aggregate metrics (Stock Value, Gross Margin, Net Profit, Due Balance) in real time.
- `themeModeProvider`: StateNotifier persisting user theme preference to local storage.
- `localeProvider`: StateNotifier toggling between English (`en`) and Bengali (`bn`) locales.

---

## 4.2. Back-End Services & Persistence Layer

### Cloud Firestore Architecture
Data is organized into normalized, top-level collections to optimize query latency and minimize document read costs. Complex sub-aggregations are indexed using multi-field composite indexes (e.g., `sales` indexed by `createdAt DESC` and `paymentMethod ASC`).

### Security Rules & Access Control
Firestore database security is enforced via strict server-side rules in `firestore.rules`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    function isAdmin() {
      return isAuthenticated() && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    // Mobile & Gadget Stock: Authenticated users can read/sell; only Admin can delete
    match /mobile_stock/{document} {
      allow read, create, update: if isAuthenticated();
      allow delete: if isAdmin();
    }
    
    // Financial collections (Expenses, Salary, Capital): Restricted write access
    match /expenses/{document} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
    match /salary/{document} {
      allow read, write: if isAdmin();
    }
    match /capital/{document} {
      allow read, write: if isAdmin();
    }
    
    // Sales: Staff can create; only Admin can modify historical records
    match /sales/{document} {
      allow read, create: if isAuthenticated();
      allow update, delete: if isAdmin();
    }
  }
}
```

### Offline Persistence & Synchronization
To guarantee zero checkout interruptions during internet dropouts:
- Cloud Firestore local persistence is enabled:
  ```dart
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  ```
- All pending writes are queued locally in SQLite (Windows/Android) or IndexedDB (Web) and automatically synchronized with the cloud when connectivity is restored.

---

## 4.3. Functional Modules Specification

| Module Name | Source Directory | Primary Functionality & Features |
| :--- | :--- | :--- |
| **1. Authentication** | `lib/auth/` | Secure email/password login, role verification (`admin`/`staff`), user session persistence, and logout flow. |
| **2. Executive Dashboard** | `lib/dashboard/` | Real-time financial summary cards (Inventory Value, Today's Sales, Net Profit, Baki Due, Stock Count) and interactive revenue/profit line charts. |
| **3. Mobile Phone Sector** | `lib/mobile_sector/` | Individual IMEI entry, brand/model management, automated transport cost allocation, stock search, and status tracking (`in_stock`, `sold`, `returned`). |
| **4. Gadget Sector** | `lib/gadget_sector/` | Bulk SKU accessories tracking, stock replenishment thresholds, purchase cost tracking, and retail margin calculations. |
| **5. POS & Sales** | `lib/sales/` | Dynamic multi-item checkout cart, instant IMEI barcode lookup, discounts, split payment methods (Cash, Card, MFS, Baki), and invoice compilation. |
| **6. Baki / Customer Dues** | `lib/baki_due/` | Customer directory, outstanding debt ledger, partial payment collection, transaction history, and credit settlement statements. |
| **7. Expenses & Rent** | `lib/expenses/` | Categorized operational expense recording (Rent, Electricity, Maintenance, Meals, Transport) with date-range aggregation. |
| **8. Payroll & Salary** | `lib/salary/` | Employee directory, base salary schedules, salary advances logging, and monthly disbursement reconciliation. |
| **9. Capital & Investment** | `lib/capital/` | Partner equity tracking, capital injections, withdrawals, and balance sheet capital valuation. |
| **10. PDF & Thermal Invoicing** | `lib/shared/services/` | Formatted 80mm thermal receipt printing and professional A4 PDF invoice compiler with Bengali Unicode font integration. |
| **11. Bulk Import & Audit** | `lib/admin/`, `lib/reports/` | 1-Click Excel (.xlsx) data import, missing field detection, duplicate IMEI checking, CSV export, and database integrity auditing. |

*Table 3: Primary Application Modules and Directory Mapping*

\newpage

---

# Chapter 5: USER MANUAL

## 5.1. System Requirements

### 5.1.1. Hardware Requirements
Table 6 outlines the minimum and recommended hardware specifications for client devices.

| Specification | Client Device (Web / Desktop / Android) |
| :--- | :--- |
| **Processor** | Dual-core 1.8 GHz+ (Intel/AMD/ARM64) |
| **RAM** | 4 GB minimum (8 GB recommended for smooth multi-tab web operation) |
| **Storage** | 500 MB free local disk space for cache and offline database |
| **Display Resolution** | 1280×720 minimum (optimized for 1920×1080 desktop and responsive down to mobile viewports) |
| **Peripherals** | Standard Keyboard, Mouse, Barcode Scanner (optional), 80mm ESC/POS Thermal Printer or A4 Laser Printer |

### 5.1.2. Software Requirements
- **Web Client:** Modern Chromium-based browser (Google Chrome 110+, Microsoft Edge 110+, Mozilla Firefox 115+) with WebGL / CanvasKit support.
- **Desktop Client:** Microsoft Windows 10 (64-bit) or Windows 11.
- **Mobile Client:** Android 8.0 (API Level 26) or higher.
- **Cloud Infrastructure:** Google Cloud Firestore, Firebase Authentication, and Google Cloud Storage.

---

## 5.2. User Interface Walkthrough

### 5.2.1. Authentication & Role Gateway
Upon launching the application, users are presented with the secure Login screen.
- Users enter their registered email address and password.
- The system validates credentials against Firebase Authentication, verifies account permissions, and routes the user directly to the authenticated Dashboard.
- Role-based UI gating automatically disables sensitive administrative menus (Capital, Salary, and Bulk Delete) for regular sales staff.

*Figure 8: Login & Authentication Screen*

---

### 5.2.2. Executive Dashboard & Real-Time Analytics
The central control center of the application provides immediate visual insight into the health of the retail business:
- **KPI Summary Cards:** Displays real-time metrics including Total Mobile Stock Value, Total Gadget Value, Today's Gross Sales, Current Month's True Net Profit, and Total Outstanding Customer Baki.
- **Interactive Chart (`fl_chart`):** Shows daily revenue and profit trajectories over the past 30 days.
- **Quick Action Bar:** 1-Click access to Add New Phone, Open POS Cart, Record Expense, or Collect Baki.

*Figure 9: Executive Dashboard with Financial KPIs & Quick Actions*

---

### 5.2.3. Mobile Phone Inventory & IMEI Registry
The Mobile Sector screen manages the full lifecycle of serialized phone inventory:
- **Search & Filter:** Instant search bar filtering across Model Name, Brand, Color, Storage, or specific 15-digit IMEI number.
- **Stock Card Details:** Each card clearly displays the Model, IMEI, Color, RAM/Storage, Net Purchase Cost (including allocated transport), Selling Price, and current status (`In Stock`, `Sold`, `Returned`).
- **Add Phone Dialog:** Includes automatic calculation where entering total transport cost and quantity dynamically computes the Net Purchase Cost per unit.

*Figure 10: Mobile Phone Inventory with Search & IMEI Registry*  
*Figure 11: Add / Edit Mobile Stock Dialog with Auto-Calculating Cost Overhead*

---

### 5.2.4. Gadget Stock & Margin Controller
The Gadget Sector screen provides efficient bulk SKU inventory management:
- Lists all accessories (Chargers, Earphones, Smartwatches, Screen Protectors, Power Banks) categorized by type.
- Highlights low-stock items with amber alert badges when quantity drops below the user-defined threshold.
- Allows rapid stock replenishment and retail margin adjustments with a single click.

*Figure 12: Gadget Inventory & Stock Level Screen*

---

### 5.2.5. Point-of-Sale (POS), Cart & Invoicing
The POS screen enables high-speed checkout at the sales counter:
- **Product Selection:** Staff select mobile phones by clicking or scanning the IMEI barcode, alongside non-serialized gadgets.
- **Cart Summary:** Automatically calculates Subtotal, Itemized Margin, and allows entering custom customer discounts.
- **Multi-Payment Modal:** Supports full cash payment, Mobile Financial Services (bKash, Nagad, Rocket), Card POS, or split payment where unpaid balance is automatically logged as Customer Due ("Baki") with customer contact details.
- **Instant Print:** Generates 80mm thermal receipt or full A4 PDF invoice.

*Figure 13: Point-of-Sale (POS) Screen & Multi-Mode Payment Dialog*

---

### 5.2.6. Customer Due ("Baki") Ledger & Repayment
The Baki screen maintains complete financial transparency over customer credit:
- **Customer Profiles:** Lists all customers with outstanding debt balances, phone numbers, and last payment dates.
- **Payment Collection Modal:** Allows recording partial cash repayments against outstanding balances.
- **Ledger Statement:** Automatically updates customer balance and generates printable payment receipts.

*Figure 14: Customer Due ("Baki") Ledger & Repayment Dialog*

---

### 5.2.7. Expense & Salary Administration
Provides structured tracking of shop operational overheads:
- **Expense Book:** Log expenditures categorized under Rent, Electricity Bill, Staff Meals, Store Maintenance, and Miscellaneous with date stamps.
- **Employee Payroll:** Displays staff salary scales, records mid-month salary advances, and calculates remaining monthly payout.

*Figure 15: Categorized Expense & Salary Management Screen*

---

### 5.2.8. Comprehensive Financial Reports & Profit/Loss Visualizer
The reporting suite generates detailed, auditable financial statements:
- **Consolidated P&L:** Breaks down Total Gross Revenue, Total Cost of Goods Sold (COGS), Gross Profit, Operating Expenses, Employee Payroll, and True Net Profit.
- **Export Options:** 1-Click export of complete financial statements and inventory summaries to formatted Excel spreadsheets (.xlsx) and printable PDF documents.

*Figure 16: Interactive Financial Reports with Revenue/Profit Charts*  
*Figure 17: Printable PDF & Thermal Invoice Generation Layout*

---

### 5.2.9. Bulk Data Import, Export & Integrity Audit
The Admin Data Management module allows frictionless migration and safety auditing:
- **1-Click Excel Import:** Upload multi-sheet `.xlsx` workbooks containing hundreds of mobile phones or gadgets. The system automatically verifies columns, ignores duplicate IMEIs, and creates records in batch.
- **Data Integrity Audit:** Runs automated diagnostic algorithms checking for orphaned transactions, negative quantities, missing customer IDs, or calculation inconsistencies.

*Figure 18: Bulk Excel Data Import & Automatic Audit Screen*

---

### 5.2.10. Settings & Customization
Allows store managers to tailor the application environment:
- Toggle between Light Mode and Dark Mode.
- Switch interface language between English and Bengali.
- Configure store metadata (Shop Name, Address, Contact, Vat/Tax Registration Number, Invoice Footer Message).

\newpage

---

# Chapter 6: CONCLUSION & FUTURE SCOPE

## 6.1. Conclusion

**Smart Buy Online (I-Buzz BD Management)** successfully accomplishes its primary mission: delivering a robust, secure, and intuitive cross-platform retail inventory, point-of-sale, and financial intelligence system tailored for retail electronics enterprises.

Key technical and operational outcomes achieved:
1. **Complete Cross-Platform Execution:** A single, clean Flutter codebase running natively across Web browsers (Chrome, Edge, Firefox), Windows Desktop (x64), and Mobile devices (Android, iOS).
2. **Elimination of Inventory Leakage:** Strict 15-digit IMEI serialization ensures every individual handset is tracked from vendor procurement to customer invoice, preventing shrinkage and resolving customer warranty disputes.
3. **Accurate Landed Cost Accounting:** Dynamic allocation of transportation overheads ensures that true purchase cost is never underestimated.
4. **Transparent Financial Clarity:** Real-time computation of True Net Profit—deducting categorized expenses, payroll, and losses from gross margins—provides business owners with an accurate financial dashboard.
5. **High-Performance Architecture:** Declarative Riverpod state management coupled with Cloud Firestore real-time streams and offline caching guarantees continuous operation even during internet dropouts.

---

## 6.2. System Limitations

- **Hardware EMV Integration:** Credit/debit card swipe machines operate independently; transaction approval codes are recorded manually rather than communicating via direct USB/Bluetooth POS hardware protocol.
- **Offline Multi-Device Conflict Resolution:** If two separate offline devices attempt to sell the exact same single IMEI handset simultaneously, conflict resolution relies on last-write-wins timestamp arbitration upon cloud reconnection.
- **SMS Gateway Cost:** Automated SMS receipt notifications require subscription to a third-party SMS aggregator API.

---

## 6.3. Future Works & Enhancements

- **Automated WhatsApp / SMS Gateway:** Integration with Twilio or local Bangladesh SMS gateways (e.g., Greenweb, SSL Wireless) to dispatch automated digital receipts directly to customer WhatsApp and SMS.
- **AI-Powered Demand & Price Forecasting:** Machine learning algorithms analyzing historical sales velocity to recommend optimal restock quantities and seasonal pricing adjustments.
- **Multi-Branch Central Warehouse Routing:** Extending the database schema to support multi-store chains with inter-branch stock transfers and regional manager permissions.
- **Customer Loyalty & Warranty Portal:** A public-facing web lookup portal where end customers can enter their IMEI number to verify remaining warranty period and service history.

\newpage

---

# References

[1] Google LLC. "Flutter Documentation: Build apps for any screen." Flutter Dev, 2026, https://docs.flutter.dev.  
[2] Google LLC. "Cloud Firestore Documentation: Realtime NoSQL Database." Firebase Documentation, 2026, https://firebase.google.com/docs/firestore.  
[3] Remi Rousselet. "Riverpod: A Reactive Caching and Data-Binding Framework." Riverpod Documentation, 2026, https://riverpod.dev.  
[4] Dart Programming Language Team. "Dart Language and Library Specification (Version 3.x)." Dart Dev, 2026, https://dart.dev.  
[5] Microsoft Corporation. "Entity-Relationship Modeling and Relational Database Concepts." Microsoft Learn, 2024.  
[6] GSM Association. "IMEI Allocation and Administration Guidelines." GSMA Security Standards, 2023, https://www.gsma.com.  
[7] IEEE Computer Society. "IEEE Standard for Software User Documentation (IEEE Std 1063-2001)." IEEE, 2001.  
[8] Martin Fowler. "Patterns of Enterprise Application Architecture." Addison-Wesley Professional, 2002.  
[9] Robert C. Martin. "Clean Architecture: A Craftsman's Guide to Software Structure and Design." Prentice Hall, 2017.  
[10] International Accounting Standards Board (IASB). "IAS 2: Inventories — Measurement of Cost of Goods Sold." IFRS Foundation, 2023.

\newpage

---

# Appendix A

## A.1. Project Repository & Deployment Details
- **Project Source Repository:** `https://github.com/ARI-Software-Lab/Smart-Buy_Online-App`
- **Live Web Application URL:** `http://localhost:8080` (Local production build served via Flutter Web & Python HTTP Engine)
- **Firebase Project Console:** `https://console.firebase.google.com/project/smart-buy-online`
- **Database Engine:** Google Cloud Firestore (Location: `asia-southeast1`)

---

## A.2. Complete Directory Structure

```text
d:\I-buzz bd mangement\
├── android/                         # Android native Gradle configuration & manifest
├── assets/                          # Static assets
│   ├── fonts/                       # Custom fonts (Noto Sans Bengali, Roboto)
│   ├── icons/                       # Application icons
│   └── images/                      # App logos & branding illustrations
├── build/                           # Compiled production outputs
│   └── web/                         # Production Flutter Web compilation bundle
├── ios/                             # iOS native Xcode project & Podfile
├── lib/                             # Core Application Source Code (Dart)
│   ├── main.dart                    # Application entrypoint & Firebase initialization
│   ├── app.dart                     # MaterialApp, localization delegates & AuthWrapper
│   ├── firebase_options.dart        # Auto-generated Firebase platform configs
│   ├── repair_db.dart               # Database repair & data migration utility
│   ├── admin/                       # Store administration & data audit screens
│   │   └── screens/
│   │       ├── bulk_import_screen.dart
│   │       └── data_audit_screen.dart
│   ├── auth/                        # User authentication & role management
│   │   ├── models/user_model.dart
│   │   ├── providers/auth_provider.dart
│   │   └── screens/login_screen.dart
│   ├── baki_due/                    # Customer credit & dues ledger
│   │   ├── models/customer_due.dart
│   │   ├── providers/due_provider.dart
│   │   └── screens/baki_due_screen.dart
│   ├── capital/                     # Partner investment & capital tracker
│   │   ├── models/capital_item.dart
│   │   ├── providers/capital_provider.dart
│   │   └── screens/capital_screen.dart
│   ├── dashboard/                   # Executive dashboard & real-time analytics
│   │   ├── providers/dashboard_provider.dart
│   │   └── screens/dashboard_screen.dart
│   ├── expenses/                    # Operational expense & rent ledger
│   │   ├── models/expense.dart
│   │   ├── providers/expense_provider.dart
│   │   └── screens/expense_screen.dart
│   ├── gadget_sector/               # Accessories & non-serialized inventory
│   │   ├── models/gadget_stock.dart
│   │   ├── providers/gadget_provider.dart
│   │   └── screens/gadget_stock_screen.dart
│   ├── mobile_sector/               # Serialized mobile handset inventory & IMEIs
│   │   ├── models/mobile_stock.dart
│   │   ├── providers/mobile_provider.dart
│   │   └── screens/mobile_stock_list_screen.dart
│   ├── reports/                     # P&L calculations, charts & Excel export
│   │   ├── providers/report_provider.dart
│   │   ├── services/export_service.dart
│   │   └── screens/reports_screen.dart
│   ├── returns/                     # Customer returns & warranty claims
│   ├── salary/                      # Employee payroll, advances & monthly payouts
│   │   ├── models/salary_item.dart
│   │   ├── providers/salary_provider.dart
│   │   └── screens/salary_screen.dart
│   ├── sales/                       # Point-of-sale checkout, cart & invoices
│   │   ├── models/sale.dart
│   │   ├── providers/sales_provider.dart
│   │   └── screens/sales_screen.dart
│   ├── search/                      # Global multi-sector inventory search
│   ├── settings/                    # Theme configuration & store metadata
│   │   └── screens/settings_screen.dart
│   ├── shared/                      # Shared reusable UI & backend services
│   │   ├── constants/               # Colors, themes, styles & Firestore keys
│   │   ├── l10n/                    # Bengali & English localization delegates
│   │   ├── providers/               # Global theme & locale providers
│   │   ├── services/
│   │   │   ├── bulk_import_service.dart
│   │   │   ├── data_audit_service.dart
│   │   │   └── receipt_service.dart # Thermal & A4 PDF invoice generator
│   │   ├── utils/calculations.dart  # Core mathematical & financial formulas
│   │   └── widgets/                 # Reusable buttons, cards, text fields
│   └── transport/                   # Landed transport cost accumulation helpers
├── pubspec.yaml                     # Project manifest & third-party dependencies
├── web/                             # Web harness, index.html, manifest.json
└── windows/                         # Windows C++ runner & desktop wrapper
```

---

## A.3. Test Cases & Verification Summary

Table 7 summarizes the automated verification and manual functional testing performed on the core modules of **Smart Buy Online**.

| Test ID | Module Tested | Verification Scenario | Expected Outcome | Status |
| :---: | :--- | :--- | :--- | :---: |
| **TC-01** | **Authentication** | User logs in with valid email/password credentials | Session authenticated; routed to Dashboard with valid role | **PASS** |
| **TC-02** | **Mobile Inventory** | Add phone with Base Price = ৳20,000, Transport = ৳500 | Net Purchase Price stored as ৳20,500 with unique IMEI | **PASS** |
| **TC-03** | **IMEI Duplicate** | Attempt to add a phone with an existing active IMEI | System displays validation error and prevents document write | **PASS** |
| **TC-04** | **POS Checkout** | Sell phone for ৳25,000 Cash with ৳500 discount | Phone status updated to `sold`; gross margin recorded as ৳4,000 | **PASS** |
| **TC-05** | **Baki Settlement** | Customer buys ৳30,000 phone, pays ৳20,000 cash | Sale recorded; ৳10,000 added to Customer Due ledger | **PASS** |
| **TC-06** | **Net Profit Engine** | Gross Profit = ৳50,000, Expenses = ৳15,000, Salary = ৳10,000 | Dashboard computes and renders True Net Profit = ৳25,000 | **PASS** |
| **TC-07** | **PDF Invoicing** | Trigger A4 invoice generation for Bengali customer name | Formatted PDF generated with Noto Sans Bengali typography | **PASS** |
| **TC-08** | **Excel Bulk Import**| Upload 100-row `.xlsx` inventory file with 2 duplicate IMEIs | 98 valid items imported; 2 duplicates flagged in audit log | **PASS** |
| **TC-09** | **Offline Sync** | Process sale while disconnected from internet | Sale stored in local cache; auto-synced upon reconnect | **PASS** |
| **TC-10** | **Role Security** | Staff account attempts to access Capital / Salary screen | Screen access denied by Firestore security rules and UI gating | **PASS** |

*Table 7: Sample Automated & Manual Test Coverage Results*
