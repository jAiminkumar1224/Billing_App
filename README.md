# 🧾 Flutter Billing App

A modern **Billing & Invoice Management System** built using **Flutter (Desktop )** and **SQLite**.

This application is designed for small businesses to efficiently create invoices, track payments, generate reports, and print professional bills — all offline.

---

## ✨ Features

* 📄 Create and manage invoices
* 🧾 Item-based billing system
* ⏳ Track **Pending Bills**
* 💰 Mark invoices as **Paid**
* 📊 Advanced **Sales Reports Dashboard**
* 🔍 Search invoices (Customer / Invoice Number)
* 📅 Filter sales by **Weekly / Monthly / Yearly / Custom Range**
* 🖨 Generate & print **PDF invoices**
* 💾 Offline storage using **SQLite**
* 🖥 Desktop support (**Windows .exe build**)

---

## 🛠 Tech Stack

* **Flutter** – Cross-platform UI framework
* **Dart** – Programming language
* **SQLite** – Local database
* **PDF & Printing** – Invoice generation

---

## 📂 Project Structure

```
lib/
│
├── database/
│   └── database_helper.dart
│
├── models/
│   ├── invoice_model.dart
│   └── invoice_item_model.dart
│
├── screens/
│   ├── Reports/
│   │   ├── all_invoices.dart
│   │   ├── customer_details.dart
│   │   ├── pending_bills.dart
│   │   └── sales_report_screen.dart
│   │
│   ├── bill_screen.dart
│   ├── data_screen.dart
│   └── login_screen.dart
│
├── services/
│   ├── pdf_service.dart
│   ├── print_bill.dart
│   └── sales_report_pdf.dart
│
├── widgets/
│
└── main.dart
```

---

## 🚀 Getting Started

### 1️⃣ Clone the repository

```
git clone https://github.com/your-username/flutter-billing-app.git
```

### 2️⃣ Navigate to project

```
cd flutter-billing-app
```

### 3️⃣ Install dependencies

```
flutter pub get
```

---

## ▶️ Run the Application

### 📱 Android 
```
flutter run
```

### 🖥 Windows Desktop

```
flutter config --enable-windows-desktop
flutter run -d windows
```

---

## 📦 Build Windows EXE

```
flutter build windows
```

Output location:

```
build/windows/runner/Release/
```

👉 You can convert this into a setup installer using tools like **Inno Setup**.

---

## 📥 Download (Executable)

You can download the latest `.exe` from the **Releases** section of this repository.

---

## 📸 Screenshots

### Billing Page

<img width="1919" height="1021" alt="Billing" src="https://github.com/user-attachments/assets/54c5425e-3c73-4be1-9e93-bce464e8e7c1" />

### Data Page

<img width="1919" height="1018" alt="Data" src="https://github.com/user-attachments/assets/c7922e24-0e1b-42b4-9ef6-5d0bb38172a7" />

---

## 💼 Real-World Use Case

This application helps small businesses:

* Replace manual billing systems
* Reduce calculation errors
* Maintain digital transaction history
* Generate instant sales reports
* Print professional invoices

---

## 📌 Future Improvements

* Customer management module
* GST calculation support
* Cloud backup / sync
* Multi-user authentication
* Advanced analytics dashboard

---

## 👨‍💻 Author

**Jaiminkumar Patel**

---

## 📜 License

This project is open-source and available under the **MIT License**.
