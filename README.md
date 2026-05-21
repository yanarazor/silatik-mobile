# 📱 SILATIK Mobile App

Aplikasi Mobile Sistem Informasi Layanan Sertifikasi (SILATIK) hasil kerja sama dengan BRIN (Badan Riset dan Inovasi Nasional). Aplikasi ini memfasilitasi pengguna/lembaga dalam melakukan pendaftaran, manajemen auditor, melengkapi dokumen akreditasi, hingga meninjau status sertifikasi SPBE.

---

## 🛠 Tech Stack

Proyek ini dibangun menggunakan **Flutter** dengan library/arsitektur pendukung berikut:

- **State Management**: [Riverpod](https://pub.dev/packages/flutter_riverpod) (`flutter_riverpod`) digunakan sebagai pusat pengelolaan _state_, logika bisnis, dan _dependency injection_.
- **Routing & Navigation**: [GetX](https://pub.dev/packages/get) (`get`) digunakan untuk manajemen rute aplikasi secara ringkas (`Get.toNamed`, `Get.offAllNamed`) serta pemanggilan dialog dan snackbar.
- **Networking/API**: [Dio](https://pub.dev/packages/dio) digunakan untuk melakukan _HTTP request_ ke Backend. Dio telah dikonfigurasi menggunakan _interceptor_ untuk memberikan _Bearer Token_ otomatis.
- **Form Validation**: [Reactive Forms](https://pub.dev/packages/reactive_forms) untuk model-driven form validation yang reaktif.
- **Local Storage**: [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage) disiapkan untuk menyimpan data sensitif seperti JWT _Token_ secara aman, dilengkapi dengan SharedPreferences.

---

## 📂 Struktur Folder Aplikasi (`/lib`)

Proyek diatur menggunakan pola **Feature-wise/Layered Architecture**:

```text
lib/
├── core/               # Konfigurasi inti (API endpoints, utility, formatter, konstanta, theme)
├── data/
│   ├── models/         # Data class & parsing JSON
│   ├── repositories/   # Lapisan perantara data (Repository pattern)
│   └── services/       # Komunikasi langsung dengan pihak ketiga (API/Dio, Storage)
├── presentation/       # Tampilan antarmuka aplikasi dibagi per-fitur (auth, dashboard, registration)
├── providers/          # Riverpod State/Notifier untuk state management tiap fitur
├── app.dart            # Inisialisasi awal GetX Router, Thema, dan root Widget
└── main.dart           # Entry point aplikasi
```

---

## 🚀 Cara Menjalankan Proyek (Getting Started)

### Prasyarat

- Flutter SDK (Versi Stabil Terbaru)
- Dart SDK
- Android Studio / Xcode untuk emulator/simulator.

### Instalasi

1. Clone / buka repositori ini di VS Code atau IDE favorit Anda.
2. Unduh semua dependensi pub:
   ```bash
   flutter pub get
   ```
3. _(Opsional)_ Jika ada _file_ `.env`, pastikan Anda menyalin dari `.env.example` ke `.env` dan mengisi _value_ yang benar. (Secara default `ApiClient` menggunakan `https://testapilatik.brin.go.id/api`).

### Menjalankan Mode Development

```bash
flutter run
```

---

## 🌐 Dokumentasi API

- **Base URL Development:** `https://testapilatik.brin.go.id/api`
- **Swagger UI:** [API Documentation](https://testapilatik.brin.go.id/api/documentation)

Semua perutean endpoint sudah didaftarkan pada direktori `lib/core/constants/api_endpoints.dart`.  
Pemanggilan API berada di dalam _directory_ `lib/data/services/` (contoh: `auth_service.dart`, `latik_service.dart`).

---

## 💡 Panduan Pengembangan (Development Guidelines)

1. **Membuat Screen Baru**:
   - Letakkan di folder `lib/presentation/<nama_fitur>/`.
   - Gunakan `ConsumerWidget` atau `ConsumerStatefulWidget` dari _Riverpod_ jika butuh memantau state.
2. **Setup Rute Baru**:
   - Daftarkan rute baru di `lib/core/constants/app_routes.dart` (contoh: `static const String myPage = '/mypage';`).
   - Daftarkan _binding_ rutenya pada _array_ `getPages` di dalam `lib/app.dart`.
3. **Penyambungan API Baru**:
   - Daftarkan path endpoint di `api_endpoints.dart`.
   - Buat fungsi pemanggilannya (`GET/POST/...`) di `/services/` melalui instansi `Dio`.
   - Proses dan bungkus logika bisinisnya (seperti pengaktifan status _loading_, _error handling_) di `/providers/`.
4. **Penanganan Error (Error Handling)**:
   - Apabila melempar / menangkap error dari API (Exception), manfaatkan kelas perantara `ApiErrorHandler.getMessage(error)` di `api_error_handler.dart` agar pesan yang muncul di-UI menjadi lebih rapi dan dapat dibaca (Human-readable).
