# SILATIK Mobile

> **Aplikasi mobile SILATIK, Sistem Informasi Layanan Sertifikasi hasil kerja sama dengan BRIN (Badan Riset dan Inovasi Nasional).**
> Lembaga pengguna dapat mendaftar, mengelola data auditor, melengkapi dokumen akreditasi, dan memantau status sertifikasi SPBE.

---

## Daftar Isi

- [Tentang Aplikasi](#tentang-aplikasi)
- [Tech Stack](#tech-stack)
- [Arsitektur](#arsitektur)
- [Struktur Folder](#struktur-folder)
- [Peta Fitur](#peta-fitur)
- [Konfigurasi Environment](#konfigurasi-environment)
- [Memulai Proyek](#memulai-proyek)
- [Menjalankan Tes dan Analisis](#menjalankan-tes-dan-analisis)
- [Dokumentasi API](#dokumentasi-api)
- [Panduan Pengembangan](#panduan-pengembangan)
- [Catatan Rilis](#catatan-rilis)

---

## Tentang Aplikasi

SILATIK Mobile adalah sisi pengguna dari sistem LATIK (Lembaga Terakreditasi). Alur utamanya:

1. Lembaga **registrasi** dan login, lalu menunggu aktivasi akun.
2. Lembaga melengkapi **profil lembaga**, **data pengguna**, dan **dokumen berkas**.
3. Lembaga menambahkan **auditor** dan melengkapi data pendukungnya.
4. Lembaga mengajukan **verifikasi** LATIK, memantau **notifikasi**, dan merespons **revisi** dari verifikator.
5. Lembaga memperpanjang sertifikasi (**perpanjangan**) dan memantau **transaksi** serta invoice.

---

## Tech Stack

| Kategori | Library |
|---|---|
| Framework | Flutter, Dart SDK `>=3.4.0 <4.0.0` |
| State management & DI | [Riverpod](https://pub.dev/packages/flutter_riverpod) (`flutter_riverpod`) |
| Routing | [go_router](https://pub.dev/packages/go_router) dengan redirect autentikasi |
| HTTP | [Dio](https://pub.dev/packages/dio) dengan interceptor untuk Bearer token dan logging |
| Form & validasi | [Reactive Forms](https://pub.dev/packages/reactive_forms) |
| Penyimpanan token | [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) |
| Preferensi lokal | [shared_preferences](https://pub.dev/packages/shared_preferences) |
| Konfigurasi | [flutter_dotenv](https://pub.dev/packages/flutter_dotenv) |
| Gambar & peta | `cached_network_image`, `flutter_map`, `latlong2` |
| Dokumen | `file_picker`, `syncfusion_flutter_pdfviewer`, `open_filex`, `share_plus` |
| Notifikasi lokal | `flutter_local_notifications` |
| Tipografi & animasi | `google_fonts`, `lottie`, `shimmer` |

---

## Arsitektur

Proyek memakai pemisahan lapisan sederhana: **presentation** (UI) membaca **providers** (Riverpod), providers memanggil **repositories**, dan repositories memakai **services** yang berbicara langsung dengan API melalui Dio. Model di `data/models` menjadi bentuk data yang dipakai di seluruh lapisan.

```
Presentation (screen & widget)
      │ watch / read
      ▼
Providers (Riverpod)
      │ memanggil
      ▼
Repositories (data/repositories)
      │ memakai
      ▼
Services (data/services) ──▶ ApiClient (Dio + Bearer token) ──▶ REST API BRIN
                         └──▶ StorageService (secure storage, shared preferences)
```

### Alur Sesi

```
App start
    │
    ├── Splash: cek force update, lalu AuthNotifier.checkAuth()
    │       ├── Token tidak ada                            ──▶ Login
    │       ├── GET user/me gagal (termasuk 401)           ──▶ logout ──▶ Login
    │       ├── User tidak lolos AccessControl.canUseMobile ──▶ logout ──▶ Login
    │       └── Token valid                                ──▶ Dashboard
    │
    └── Login ──▶ token disimpan di secure storage ──▶ Dashboard
```

Saat request lain di tengah sesi menerima 401, interceptor di `providers/auth_provider.dart` memanggil `onUnauthorized`, yang memicu `logoutDueToSessionExpired()` lalu mengarahkan pengguna ke halaman login.

---

## Struktur Folder

```text
lib/
├── core/
│   ├── auth/           # Pemeriksaan hak akses (access_control.dart)
│   ├── constants/      # api_endpoints.dart, app_routes.dart, enums.dart, map_config.dart
│   ├── router/         # app_router.dart, konfigurasi GoRouter dan redirect
│   ├── theme/          # app_theme.dart
│   └── utils/          # ApiErrorHandler, validators, formatters, file & url helper
├── data/
│   ├── models/         # Data class dan parsing JSON
│   ├── repositories/   # Lapisan perantara antara provider dan service
│   └── services/       # Pemanggilan API (Dio) dan StorageService
├── presentation/       # Layar dan widget, dikelompokkan per fitur
│   ├── auditor/        ├── dashboard/      ├── dokumen/
│   ├── auth/           ├── notifikasi/     ├── perpanjangan/
│   ├── profil/         ├── revisi/         ├── shared/
│   ├── splash/         ├── transaksi/      └── verifikasi/
├── providers/          # Riverpod provider dan notifier per fitur
├── app.dart            # Bootstrap: dotenv, locale id_ID, ProviderScope, MaterialApp.router
└── main.dart           # Entry point, mengatur pesan error Dio yang ramah pengguna
```

---

## Peta Fitur

| Fitur | Folder presentation | Service / repository |
|---|---|---|
| Login, registrasi, lupa password | `auth/` | `auth_service.dart` |
| Dashboard | `dashboard/` | `latik_service.dart` |
| Data auditor | `auditor/` | `auditor_service.dart`, `auditor_repository.dart` |
| Dokumen akreditasi | `dokumen/`, `profil/dokumen_berkas*` | `dokumen_service.dart`, `dokumen_repository.dart` |
| Profil lembaga dan data pengguna | `profil/` | `latik_service.dart`, `profile_menu_service.dart` |
| Verifikasi LATIK | `verifikasi/` | `latik_verifikasi_repository.dart` |
| Revisi | `revisi/` | `auditor_ext_repository.dart`, `latik_ext_repository.dart` |
| Perpanjangan | `perpanjangan/` | `auditor_ext_repository.dart`, `latik_ext_repository.dart` |
| Transaksi dan invoice | `transaksi/` | `invoice_provider.dart` |
| Notifikasi | `notifikasi/` | `notifikasi_service.dart`, `notifikasi_repository.dart` |
| Data master | Dropdown di seluruh form | `master_data_service.dart`, `master_data_repository.dart` |
| Force update dan slider landing | `splash/`, `shared/` | `force_update_service.dart`, `slider_service.dart` |

---

## Konfigurasi Environment

Konfigurasi dibaca dari file `.env` di root proyek. File ini **wajib ada**, karena `bootstrap()` memuatnya saat startup (`dotenv.load`) sebelum aplikasi berjalan.

| Variabel | Wajib | Default | Keterangan |
|---|---|---|---|
| `API_BASE_URL` | Tidak | `https://testapilatik.brin.go.id/api` | Base URL API. Path `/api` ditambahkan otomatis jika belum ada. |
| `MAP_TILE_URL` | Tidak | OpenStreetMap | Template tile peta dengan `{z}/{x}/{y}`. Untuk produksi gunakan penyedia dengan SLA. |
| `PLAY_STORE_URL` | Tidak | Play Store `id.go.brin.silatik` | Link toko untuk Android dan fallback web. Dipakai oleh dialog force update dan tombol "Beri rating" di Pengaturan. |
| `APP_STORE_URL` | Tidak | `https://apps.apple.com/app/id0000000000` | Link toko untuk iOS. Nilai default masih placeholder, ganti dengan App ID asli sebelum rilis. |

Langkah menyiapkan `.env`:

```bash
cp .env.example .env
```

> `.env` terdaftar sebagai asset di `pubspec.yaml`, sehingga **isinya ikut terbundel ke dalam aplikasi**. Jangan menyimpan secret atau kunci privat di sana. File `.env` juga sudah masuk `.gitignore`.

---

## Memulai Proyek

### Prasyarat

| Kebutuhan | Versi |
|---|---|
| Flutter SDK | Stable terbaru, kompatibel dengan Dart `>=3.4.0` |
| Android Studio atau Xcode | Untuk emulator atau simulator |

### Instalasi

1. Buka repositori di IDE favorit Anda.
2. Salin konfigurasi environment:
   ```bash
   cp .env.example .env
   ```
3. Unduh dependensi:
   ```bash
   flutter pub get
   ```
4. Jalankan aplikasi:
   ```bash
   flutter run
   ```

---

## Menjalankan Tes dan Analisis

```bash
flutter analyze
flutter test
```

Tes berada di `test/`:

- `test/unit/` mencakup providers, repositories, services, models, utils, dan presentation helper.
- `test/fixtures/` berisi contoh respons JSON dari API.
- `test/helpers/mock_helpers.dart` berisi helper mock bersama.
- `test/tooling/file_length_test.dart` gagal jika ada file `lib/**/*.dart` lebih dari 350 baris.

---

## Dokumentasi API

- **Base URL development:** `https://testapilatik.brin.go.id/api`
- **Daftar endpoint:** `lib/core/constants/api_endpoints.dart`
- **Pemanggilan API:** `lib/data/services/`

Semua request melalui `ApiClient.dio` di `lib/data/services/api_client.dart`. Header `X-App-Client: flutter-silatik` dikirim pada setiap request. Bearer token ditambahkan oleh interceptor di `providers/auth_provider.dart` dari secure storage, kecuali pada endpoint login, registrasi, dan lupa password.

---

## Panduan Pengembangan

1. **Membuat layar baru**
   - Letakkan di `lib/presentation/<nama_fitur>/`.
   - Gunakan `ConsumerWidget` atau `ConsumerStatefulWidget` jika layar perlu membaca state Riverpod.
2. **Menambah rute baru**
   - Tambahkan konstanta path di `lib/core/constants/app_routes.dart`, misalnya `static const myPage = '/my-page';`.
   - Daftarkan `GoRoute` di `lib/core/router/app_router.dart`.
3. **Menyambungkan API baru**
   - Tambahkan path di `lib/core/constants/api_endpoints.dart`.
   - Tulis pemanggilan di `lib/data/services/` memakai `ApiClient.dio`.
   - Bungkus logika bisnis (loading, error, mapping) di `lib/data/repositories/` dan `lib/providers/`.
4. **Penanganan error**
   - `main.dart` mengatur `DioException.readableStringBuilder` ke `ApiErrorHandler.getMessage`, sehingga `'$e'` dan `e.toString()` sudah menghasilkan pesan yang bisa dibaca.
   - Untuk error non-Dio, gunakan `ApiErrorHandler.messageFrom(error)`, yang selalu mengembalikan pesan generik dan tidak membocorkan stack trace.

---

## Catatan Rilis

- **Application ID masih template.** Android memakai `com.example.silatik_mobile` dan iOS memakai `com.example.silatikMobile`. Ganti sebelum rilis ke Play Store atau App Store.
- **Link toko diatur lewat `.env`.** Ubah `PLAY_STORE_URL` dan `APP_STORE_URL` tanpa perlu rilis kode. `APP_STORE_URL` masih memakai App ID placeholder (`id0000000000`), jadi perbarui sebelum rilis iOS.

---

<p align="center">SILATIK Mobile, dikembangkan untuk BRIN.</p>
