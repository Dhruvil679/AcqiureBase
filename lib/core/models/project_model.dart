import 'package:flutter/foundation.dart';

import '../utils/firestore_timestamps.dart';

// Categories used in the explore filters.
enum ProjectCategory {
  saas('SaaS'),
  aiTools('AI Tools'),
  webApps('Web Apps'),
  mobileApps('Mobile Apps'),
  eCommerce('E-Commerce'),
  marketplace('Marketplace'),
  developerTools('Developer Tools'),
  education('Education'),
  finance('Finance'),
  healthcare('Healthcare'),
  marketing('Marketing'),
  productivity('Productivity'),
  other('Other');

  const ProjectCategory(this.label);

  final String label;

  static ProjectCategory fromString(String value) {
    return ProjectCategory.values.firstWhere(
      (c) => c.name == value,
      orElse: () => ProjectCategory.other,
    );
  }
}

// Project data class — lines up with the fields we'd store in Firestore.
@immutable
class ProjectModel {
  const ProjectModel({
    required this.projectId,
    required this.ownerId,
    required this.name,
    this.logoUrl = '',
    this.tagline = '',
    this.description = '',
    this.category = ProjectCategory.other,
    this.websiteUrl = '',
    this.businessAge = '',
    this.monthlyVisitors = '',
    this.screenshotUrls = const [],
    this.documentUrls = const [],
    this.founderName = '',
    this.founderBio = '',
    this.status = 'pending',
    this.isFeatured = false,
    this.createdAt,
    this.updatedAt,
    this.saveCount = 0,
    this.viewCount = 0,
  });

  final String projectId;
  final String ownerId;
  final String name;
  final String logoUrl;
  final String tagline;
  final String description;
  final ProjectCategory category;
  final String websiteUrl;
  final String businessAge;
  final String monthlyVisitors;
  final List<String> screenshotUrls;
  final List<String> documentUrls;
  final String founderName;
  final String founderBio;
  final String status;
  final bool isFeatured;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int saveCount;
  final int viewCount;

  ProjectModel copyWith({
    String? projectId,
    String? ownerId,
    String? name,
    String? logoUrl,
    String? tagline,
    String? description,
    ProjectCategory? category,
    String? websiteUrl,
    String? businessAge,
    String? monthlyVisitors,
    List<String>? screenshotUrls,
    List<String>? documentUrls,
    String? founderName,
    String? founderBio,
    String? status,
    bool? isFeatured,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? saveCount,
    int? viewCount,
  }) {
    return ProjectModel(
      projectId: projectId ?? this.projectId,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      tagline: tagline ?? this.tagline,
      description: description ?? this.description,
      category: category ?? this.category,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      businessAge: businessAge ?? this.businessAge,
      monthlyVisitors: monthlyVisitors ?? this.monthlyVisitors,
      screenshotUrls: screenshotUrls ?? this.screenshotUrls,
      documentUrls: documentUrls ?? this.documentUrls,
      founderName: founderName ?? this.founderName,
      founderBio: founderBio ?? this.founderBio,
      status: status ?? this.status,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      saveCount: saveCount ?? this.saveCount,
      viewCount: viewCount ?? this.viewCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'projectId': projectId,
        'ownerId': ownerId,
        'name': name,
        'logoUrl': logoUrl,
        'tagline': tagline,
        'description': description,
        'category': category.name,
        'websiteUrl': websiteUrl,
        'businessAge': businessAge,
        'monthlyVisitors': monthlyVisitors,
        'screenshotUrls': screenshotUrls,
        'documentUrls': documentUrls,
        'founderName': founderName,
        'founderBio': founderBio,
        'status': status,
        'isFeatured': isFeatured,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'saveCount': saveCount,
        'viewCount': viewCount,
      };

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      projectId: json['projectId'] as String,
      ownerId: json['ownerId'] as String,
      name: json['name'] as String,
      logoUrl: json['logoUrl'] as String? ?? '',
      tagline: json['tagline'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: ProjectCategory.fromString(json['category'] as String? ?? 'other'),
      websiteUrl: json['websiteUrl'] as String? ?? '',
      businessAge: json['businessAge'] as String? ?? '',
      monthlyVisitors: json['monthlyVisitors'] as String? ?? '',
      screenshotUrls:
          (json['screenshotUrls'] as List<dynamic>?)?.cast<String>() ?? const [],
      documentUrls:
          (json['documentUrls'] as List<dynamic>?)?.cast<String>() ?? const [],
      founderName: json['founderName'] as String? ?? '',
      founderBio: json['founderBio'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      isFeatured: json['isFeatured'] as bool? ?? false,
      createdAt: parseTimestamp(json['createdAt']),
      updatedAt: parseTimestamp(json['updatedAt']),
      saveCount: json['saveCount'] as int? ?? 0,
      viewCount: json['viewCount'] as int? ?? 0,
    );
  }
}
