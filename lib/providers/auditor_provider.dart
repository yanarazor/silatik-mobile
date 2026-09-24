import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/auditor_certificate.dart';
import '../data/models/auditor_document.dart';
import '../data/models/auditor_model.dart';
import '../data/repositories/auditor_repository.dart';
import '../data/services/auditor_service.dart';
import 'auth_provider.dart';

final auditorServiceProvider =
    Provider((ref) => AuditorService(ref.watch(dioProvider)));
final auditorRepoProvider =
    Provider((ref) => AuditorRepository(ref.watch(auditorServiceProvider)));
final auditorListProvider = FutureProvider<List<AuditorModel>>(
    (ref) => ref.watch(auditorRepoProvider).getAuditors());

final auditorDocsProvider = FutureProvider.autoDispose
    .family<List<AuditorDocument>, String>((ref, auditorRef) =>
        ref.watch(auditorRepoProvider).getDocuments(auditorRef));

final auditorSertifikasiProvider = FutureProvider.autoDispose
    .family<List<AuditorCertificate>, String>((ref, auditorRef) =>
        ref.watch(auditorRepoProvider).getSertifikasiTeknis(auditorRef));
