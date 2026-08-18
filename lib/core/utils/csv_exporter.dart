import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project_model.dart';
import '../models/user_model.dart';

// Builds CSV files for the admin export buttons.
class CsvExporter {
  CsvExporter._();

  static String usersToCsv(List<UserModel> users) {
    final rows = <List<String>>[
      [
        'UID',
        'Display Name',
        'Email',
        'Username',
        'Role',
        'Profession',
        'Age',
        'Suspended',
        'Joined At',
      ],
      ...users.map((u) => [
        u.uid,
        u.displayName,
        u.email,
        u.username,
        u.role,
        u.profession.label,
        u.age?.toString() ?? '',
        u.isSuspended ? 'Yes' : 'No',
        u.createdAt?.toIso8601String() ?? '',
      ]),
    ];
    return const CsvEncoder().convert(rows);
  }

  static String projectsToCsv(List<ProjectModel> projects) {
    final rows = <List<String>>[
      [
        'Project ID',
        'Name',
        'Tagline',
        'Category',
        'Status',
        'Featured',
        'Saves',
        'Views',
        'Owner ID',
        'Founder Name',
        'Created At',
      ],
      ...projects.map((p) => [
        p.projectId,
        p.name,
        p.tagline,
        p.category.label,
        p.status,
        p.isFeatured ? 'Yes' : 'No',
        p.saveCount.toString(),
        p.viewCount.toString(),
        p.ownerId,
        p.founderName,
        p.createdAt?.toIso8601String() ?? '',
      ]),
    ];
    return const CsvEncoder().convert(rows);
  }

  static Future<void> shareCsv({
    required String filename,
    required String csv,
  }) async {
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/$filename';
    final file = File(path);
    await file.writeAsString(csv);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: 'text/csv')],
        subject: filename,
      ),
    );
  }
}
