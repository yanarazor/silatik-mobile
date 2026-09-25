import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Footer showing the installed app version and a copyright line.
class AppVersionFooter extends StatelessWidget {
  const AppVersionFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    final year = DateTime.now().year;

    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '...';
        // final buildNumber = snapshot.data?.buildNumber ?? '';
        return Column(
          children: [
            Text('Versi $version (Mobile)', style: style),
            const SizedBox(height: 4),
            Text(
              '© $year | Direktorat Alih dan Sistem Audit Teknologi',
              style: style,
            ),
          ],
        );
      },
    );
  }
}