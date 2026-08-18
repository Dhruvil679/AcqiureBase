import 'package:flutter/foundation.dart';

import '../utils/firestore_timestamps.dart';

// Profession options shown in the profile form.
enum Profession {
  student('Student'),
  employee('Employee'),
  selfEmployed('Self-Employed'),
  founder('Founder'),
  other('Other');

  const Profession(this.label);
  final String label;

  static Profession fromString(String value) {
    return Profession.values.firstWhere(
      (p) => p.name == value,
      orElse: () => Profession.other,
    );
  }
}

// Social links shown on the profile.
@immutable
class SocialLinks {
  const SocialLinks({
    this.twitter = '',
    this.linkedin = '',
    this.website = '',
  });

  final String twitter;
  final String linkedin;
  final String website;

  SocialLinks copyWith({
    String? twitter,
    String? linkedin,
    String? website,
  }) {
    return SocialLinks(
      twitter: twitter ?? this.twitter,
      linkedin: linkedin ?? this.linkedin,
      website: website ?? this.website,
    );
  }

  Map<String, dynamic> toJson() => {
        'twitter': twitter,
        'linkedin': linkedin,
        'website': website,
      };

  factory SocialLinks.fromJson(Map<String, dynamic> json) {
    return SocialLinks(
      twitter: json['twitter'] as String? ?? '',
      linkedin: json['linkedin'] as String? ?? '',
      website: json['website'] as String? ?? '',
    );
  }
}

// User data class — matches the users/{uid} doc shape in Firestore.
@immutable
class UserModel {
  const UserModel({
    required this.uid,
    this.username = '',
    this.email = '',
    this.firstName = '',
    this.lastName = '',
    this.displayName = '',
    this.age,
    this.skills = const [],
    this.profession = Profession.other,
    this.photoUrl = '',
    this.bio = '',
    this.socialLinks = const SocialLinks(),
    this.role = 'user',
    this.isSuspended = false,
    this.createdAt,
    this.profileViews = 0,
    this.publishedProjectIds = const [],
    this.savedProjectIds = const [],
  });

  final String uid;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String displayName;
  final int? age;
  final List<String> skills;
  final Profession profession;
  final String photoUrl;
  final String bio;
  final SocialLinks socialLinks;
  final String role;
  final bool isSuspended;
  final DateTime? createdAt;
  final int profileViews;
  final List<String> publishedProjectIds;
  final List<String> savedProjectIds;

  UserModel copyWith({
    String? uid,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? displayName,
    int? age,
    List<String>? skills,
    Profession? profession,
    String? photoUrl,
    String? bio,
    SocialLinks? socialLinks,
    String? role,
    bool? isSuspended,
    DateTime? createdAt,
    int? profileViews,
    List<String>? publishedProjectIds,
    List<String>? savedProjectIds,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      displayName: displayName ?? this.displayName,
      age: age ?? this.age,
      skills: skills ?? this.skills,
      profession: profession ?? this.profession,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      socialLinks: socialLinks ?? this.socialLinks,
      role: role ?? this.role,
      isSuspended: isSuspended ?? this.isSuspended,
      createdAt: createdAt ?? this.createdAt,
      profileViews: profileViews ?? this.profileViews,
      publishedProjectIds: publishedProjectIds ?? this.publishedProjectIds,
      savedProjectIds: savedProjectIds ?? this.savedProjectIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'username': username,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'displayName': displayName,
        'age': age,
        'skills': skills,
        'profession': profession.name,
        'photoUrl': photoUrl,
        'bio': bio,
        'socialLinks': socialLinks.toJson(),
        'role': role,
        'isSuspended': isSuspended,
        'createdAt': createdAt?.toIso8601String(),
        'profileViews': profileViews,
        'publishedProjectIds': publishedProjectIds,
        'savedProjectIds': savedProjectIds,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      age: json['age'] as int?,
      skills: (json['skills'] as List<dynamic>?)?.cast<String>() ?? const [],
      profession: Profession.fromString(json['profession'] as String? ?? 'other'),
      photoUrl: json['photoUrl'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      socialLinks: SocialLinks.fromJson(
        (json['socialLinks'] as Map<String, dynamic>?) ?? {},
      ),
      role: json['role'] as String? ?? 'user',
      isSuspended: json['isSuspended'] as bool? ?? false,
      createdAt: parseTimestamp(json['createdAt']),
      profileViews: json['profileViews'] as int? ?? 0,
      publishedProjectIds:
          (json['publishedProjectIds'] as List<dynamic>?)?.cast<String>() ?? const [],
      savedProjectIds:
          (json['savedProjectIds'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }
}
