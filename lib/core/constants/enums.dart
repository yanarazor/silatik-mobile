enum IdentityType { ktp, passport }

enum Gender { male, female }

enum DocumentVerificationStatus { unverified, valid, invalid }

enum LatikVerificationStatus {
  unverified,
  waitingForVerification,
  returned,
  publishingStr,
  active,
  expired,
  freezed,
  revoked,
}

enum AuditorStatus { tetap, tidakTetap }

enum AuditorVerificationStatus { unverified, valid, invalid }

enum InvoiceType {
  registrasiLATIK,
  perpanjanganLATIK,
  registrasiAuditor,
  perpanjanganAuditor,
  penambahanAuditor,
}

enum AuditorIsNew { baru, perpanjangan }

enum AuditorStatusType { tetap, tidakTetap }

// ponytail: mirrors SilatikConstant.LATIK_VERIFICATION_STATUS from FE
class LatikVerificationStatusCode {
  static const registration = '0';
  static const verificationProcess = '1';
  static const rejected = '2';
  static const publishingStr = '3';
  static const active = '4';
  static const expired = '5';
  static const frozen = '6';
  static const revoked = '7';
  static const waitingPayment = '8';
}

// ponytail: mirrors SilatikConstant.LATIK_VERIFICATION_STATUS_STRING from FE
class LatikVerificationStatusString {
  static const registration = 'registrasi';
  static const verificationProcess = 'proses_verifikasi';
  static const rejected = 'dikembalikan';
  static const publishingStr = 'proses_penerbitan_str';
  static const active = 'aktif';
  static const expired = 'kadaluarsa';
  static const frozen = 'dibekukan';
  static const revoked = 'dicabut';
  static const waitingPayment = 'menunggu_pembayaran';
}
