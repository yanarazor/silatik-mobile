import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auditor_provider.dart';
import '../../providers/registrasi_provider.dart';
import 'steps/step1_data_lembaga.dart';
import 'steps/step2_akreditasi.dart';
import 'steps/step3_dokumen.dart';
import 'steps/step4_auditor.dart';
import 'steps/step5_review.dart';
import 'widgets/step_indicator.dart';

class RegistrationFlowScreen extends ConsumerWidget {
  const RegistrationFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(registrasiBootstrapProvider);
    final reg = ref.watch(registrasiProvider);
    final notifier = ref.read(registrasiProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    ref.listen(
        auditorProvider, (_, auditors) => notifier.setAuditors(auditors));

    final steps = [
      const Step1DataLembaga(),
      const Step2Akreditasi(),
      const Step3Dokumen(),
      const Step4Auditor(),
      const Step5Review(),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFFF7FAFE),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SizedBox(
                height: constraints.maxHeight,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 14, 22, 10),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded,
                                color: AppColors.primary),
                            onPressed: () {
                              if (reg.step > 0) {
                                notifier.setStep(reg.step - 1);
                              } else {
                                Navigator.of(context).pop();
                              }
                            },
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reg.step == 4
                                      ? 'Review & Kirim'
                                      : 'Registrasi Lembaga',
                                  style: textTheme.titleLarge?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Langkah ${reg.step + 1} dari 5',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF5B6880),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: StepIndicator(current: reg.step),
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: bootstrap.when(
                        data: (_) => steps[reg.step],
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, __) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Gagal memuat data registrasi'),
                                const SizedBox(height: 12),
                                FilledButton(
                                  onPressed: () => ref
                                      .invalidate(registrasiBootstrapProvider),
                                  child: const Text('Coba Lagi'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}
