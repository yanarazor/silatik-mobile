class ApiEndpoints {
  // AUTH
  static const String login = 'login';
  static const String register = 'createuser';
  static const String forgotPassword = 'auth/forgot-password';
  static const String changePassword = 'auth/change-password';
  static const String logout = 'auth/logout';
  static const String userMe = 'user/me';

  // LATIK
  static const String latikList = 'latik';
  static const String latikSave = 'latik/save';
  static const String latikUpdate = 'latik/updatelatik';
  static const String latikProfile = 'latik/profile';
  static const String latikSaveProfile = 'latik/saveprofile';
  static const String latikUpdateProfile = 'latik/updateprofile';
  static const String latikView = 'latik/view'; // + /{ref}
  static const String latikViewMain = 'latik/viewmain'; // + /{ref}
  static const String latikCheckNib = 'latik/checknib';
  static const String latikKonfirmasi = 'latik/konfirmasidata';
  static const String latikRequestVerif = 'latik/requestverifikasi';
  static const String latikListVerif = 'latik/listverifikasi';
  static const String latikSearch = 'latik/search'; // public

  // DOKUMEN LATIK
  static const String latikSaveDokumen = 'latik/savedokumen';
  static const String latikGetDokumen = 'latik/dokumen/view';

  // STR
  static const String strLatik = 'latik/str_latik';
  static const String strLatikPreview = 'str/latik'; // + /{ref}/preview
  static const String strListInvoiceLatik = 'latik/liststrinvoicelatik';
  static const String strUpdateLatik = 'str/update-latik';

  // INVOICE / BILLING
  static const String latikCreateInvoice = 'latik/createinvoice';
  static const String latikBilling = 'latik/billing';
  static const String latikCheckBilling = 'latik/checkbilling';
  static const String latikInvoice = 'latik/invoice'; // + /{ref}
  static const String latikListInvoices = 'latik/listinvoices';

  // AUDITOR
  static const String auditorSave = 'auditor/save';
  static const String auditorUpdate = 'auditor/update';
  static const String auditorDelete = 'auditor'; // + /{ref}
  static const String auditorsByLatik = 'latik/auditors';
  static const String auditorView = 'latik/auditor/view'; // + /{ref}
  static const String auditorSaveDokumen = 'auditor/savedokumen';
  static const String auditorGetDokumen = 'auditor/dokumen';
  static const String auditorSimpanSertif = 'auditor/simpansertifikasiteknis';
  static const String auditorUpdateSertif = 'auditor/updatesertifikasiteknis';
  static const String auditorDeleteSertif =
      'auditor/sertifikasiteknis'; // + /{ref}
  static const String auditorRequestVerif =
      'auditor/penambahan/requestverifikasi';

  // NOTIFICATION
  static const String notificationAll = 'notification/all';
  static const String notificationUnread = 'notification/unread';
  static const String notificationUnreadCount = 'notification/unreadCount';
  static const String notificationMarkAllAsRead = 'notification/markallasread';
  static const String notificationMarkAsRead = 'notification/markasread'; // + /{ref}
  static const String notificationDetail = 'notification/detail'; // + /{ref}
  static const String notificationDelete = 'notification/delete'; // + /{ref}

  // MASTER DATA
  static const String kabupaten = 'kabupaten';
  static const String dokumenPendukungAktif = 'dokumen_pendukung/aktif';
  static const String faqs = 'faqs';
  static const String faqsAll = 'faqs/all';
  static const String dokumenAll = 'dokumen/all';
  static const String sliderLanding = 'slider/landing';
  static const String latikCount = 'latik/count';
  static const String auditorCount = 'auditors/count';
  static const String settingsPermission = 'settings/permission';
  static const String settingsRoles = 'settings/roles';

  // USER
  static const String updateUser = 'settings/users/update'; // + /{ref}
}
