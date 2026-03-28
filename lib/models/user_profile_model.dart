import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserProfile {
  // 🧾 Basic Profile (Required)
  String? firstName;
  DateTime? dob;
  String? gender;
  String? interestedIn;
  String? location;
  List<String> photos;
  String? bio;
  double? latitude;
  double? longitude;

  // ❤️ Personal Details
  String? height;
  String? bodyType;
  String? ethnicity;
  String? religion;
  List<String> languages;

  // 🎯 Lifestyle & Habits
  String? smoking;
  String? drinking;
  String? fitness;
  String? diet;
  String? sleepingHabits;

  // 💼 Work & Education
  String? occupation;
  String? industry;
  String? educationLevel;
  String? school;

  // 💕 Relationship Goals
  List<String> lookingFor;
  bool? openToLongDistance;
  String? wantKids;

  // 🎨 Interests & Hobbies
  List<String> hobbies;
  List<String> musicGenres;
  List<String> moviesShows;
  List<String> weekendActivities;

  // 🧠 Personality & Values
  String? introvertExtrovert;
  String? loveLanguage;
  String? mbti;
  String? politicalViews;
  String? coreValues;

  // 📸 Media & Verification
  String? videoIntro;
  bool isVerified;

  // 💬 Prompts
  String? promptPerfectDate;
  String? promptFallForYou;
  String? promptGreenFlag;
  String? promptTwoTruths;

  // 🔐 Privacy / Safety 
  bool showAge;
  bool showDistance;

  UserProfile({
    this.firstName,
    this.dob,
    this.gender,
    this.interestedIn,
    this.location,
    this.photos = const [],
    this.bio,
    this.height,
    this.bodyType,
    this.ethnicity,
    this.religion,
    this.languages = const [],
    this.smoking,
    this.drinking,
    this.fitness,
    this.diet,
    this.sleepingHabits,
    this.occupation,
    this.industry,
    this.educationLevel,
    this.school,
    this.lookingFor = const [],
    this.openToLongDistance,
    this.wantKids,
    this.hobbies = const [],
    this.musicGenres = const [],
    this.moviesShows = const [],
    this.weekendActivities = const [],
    this.introvertExtrovert,
    this.loveLanguage,
    this.mbti,
    this.politicalViews,
    this.coreValues,
    this.videoIntro,
    this.isVerified = false,
    this.promptPerfectDate,
    this.promptFallForYou,
    this.promptGreenFlag,
    this.promptTwoTruths,
    this.showAge = true,
    this.showDistance = true,
    this.latitude,
    this.longitude,
  });

  int? get age {
    if (dob == null) return null;
    final now = DateTime.now();
    int age = now.year - dob!.year;
    if (now.month < dob!.month || (now.month == dob!.month && now.day < dob!.day)) {
      age--;
    }
    return age;
  }

  factory UserProfile.empty() {
    return UserProfile();
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    try {
      return UserProfile(
        firstName: map['firstName']?.toString(),
        dob: _parseDate(map['dob']),
        gender: map['gender']?.toString(),
        interestedIn: map['interestedIn']?.toString(),
        location: map['location']?.toString(),
        photos: _parseList(map['photos']),
        bio: map['bio']?.toString(),
        height: map['height']?.toString(),
        bodyType: map['bodyType']?.toString(),
        ethnicity: map['ethnicity']?.toString(),
        religion: map['religion']?.toString(),
        languages: _parseList(map['languages']),
        smoking: map['smoking']?.toString(),
        drinking: map['drinking']?.toString(),
        fitness: map['fitness']?.toString(),
        diet: map['diet']?.toString(),
        sleepingHabits: map['sleepingHabits']?.toString(),
        occupation: map['occupation']?.toString(),
        industry: map['industry']?.toString(),
        educationLevel: map['educationLevel']?.toString(),
        school: map['school']?.toString(),
        lookingFor: _parseList(map['lookingFor']),
        openToLongDistance: map['openToLongDistance'] is bool ? map['openToLongDistance'] : null,
        wantKids: map['wantKids']?.toString(),
        hobbies: _parseList(map['hobbies']),
        musicGenres: _parseList(map['musicGenres']),
        moviesShows: _parseList(map['moviesShows']),
        weekendActivities: _parseList(map['weekendActivities']),
        introvertExtrovert: map['introvertExtrovert']?.toString(),
        loveLanguage: map['loveLanguage']?.toString(),
        mbti: map['mbti']?.toString(),
        politicalViews: map['politicalViews']?.toString(),
        coreValues: map['coreValues']?.toString(),
        videoIntro: map['videoIntro']?.toString(),
        isVerified: map['isVerified'] == true,
        promptPerfectDate: map['promptPerfectDate']?.toString(),
        promptFallForYou: map['promptFallForYou']?.toString(),
        promptGreenFlag: map['promptGreenFlag']?.toString(),
        promptTwoTruths: map['promptTwoTruths']?.toString(),
        showAge: map['showAge'] ?? true,
        showDistance: map['showDistance'] ?? true,
        latitude: _parseDouble(map['latitude']),
        longitude: _parseDouble(map['longitude']),
      );
    } catch (e) {
      debugPrint('UserProfile error parsing map: $e');
      return UserProfile(); // Return empty profile rather than crashing
    }
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static List<String> _parseList(dynamic value) {
    if (value == null || value is! List) return [];
    return value.map((e) => e.toString()).toList();
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'dob': dob != null ? Timestamp.fromDate(dob!) : null,
      'gender': gender,
      'interestedIn': interestedIn,
      'location': location,
      'photos': photos,
      'bio': bio,
      'height': height,
      'bodyType': bodyType,
      'ethnicity': ethnicity,
      'religion': religion,
      'languages': languages,
      'smoking': smoking,
      'drinking': drinking,
      'fitness': fitness,
      'diet': diet,
      'sleepingHabits': sleepingHabits,
      'occupation': occupation,
      'industry': industry,
      'educationLevel': educationLevel,
      'school': school,
      'lookingFor': lookingFor,
      'openToLongDistance': openToLongDistance,
      'wantKids': wantKids,
      'hobbies': hobbies,
      'musicGenres': musicGenres,
      'moviesShows': moviesShows,
      'weekendActivities': weekendActivities,
      'introvertExtrovert': introvertExtrovert,
      'loveLanguage': loveLanguage,
      'mbti': mbti,
      'politicalViews': politicalViews,
      'coreValues': coreValues,
      'videoIntro': videoIntro,
      'isVerified': isVerified,
      'promptPerfectDate': promptPerfectDate,
      'promptFallForYou': promptFallForYou,
      'promptGreenFlag': promptGreenFlag,
      'promptTwoTruths': promptTwoTruths,
      'showAge': showAge,
      'showDistance': showDistance,
      'latitude': latitude,
      'longitude': longitude,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  int get completionPercentage {
    int totalFields = 28;
    int filledFields = 0;

    if (firstName != null && firstName!.isNotEmpty) filledFields++;
    if (dob != null) filledFields++;
    if (gender != null && gender!.isNotEmpty) filledFields++;
    if (interestedIn != null && interestedIn!.isNotEmpty) filledFields++;
    if (location != null && location!.isNotEmpty) filledFields++;
    if (photos.isNotEmpty) filledFields++;
    if (bio != null && bio!.isNotEmpty) filledFields++;

    if (height != null && height!.isNotEmpty) filledFields++;
    if (bodyType != null && bodyType!.isNotEmpty) filledFields++;
    if (ethnicity != null && ethnicity!.isNotEmpty) filledFields++;
    if (religion != null && religion!.isNotEmpty) filledFields++;
    if (languages.isNotEmpty) filledFields++;

    if (smoking != null && smoking!.isNotEmpty) filledFields++;
    if (drinking != null && drinking!.isNotEmpty) filledFields++;
    if (fitness != null && fitness!.isNotEmpty) filledFields++;
    if (diet != null && diet!.isNotEmpty) filledFields++;
    if (sleepingHabits != null && sleepingHabits!.isNotEmpty) filledFields++;

    if (occupation != null && occupation!.isNotEmpty) filledFields++;
    if (industry != null && industry!.isNotEmpty) filledFields++;
    if (educationLevel != null && educationLevel!.isNotEmpty) filledFields++;
    if (school != null && school!.isNotEmpty) filledFields++;

    if (lookingFor.isNotEmpty) filledFields++;
    if (openToLongDistance != null) filledFields++;
    if (wantKids != null && wantKids!.isNotEmpty) filledFields++;

    if (hobbies.isNotEmpty) filledFields++;
    if (musicGenres.isNotEmpty) filledFields++;
    if (moviesShows.isNotEmpty) filledFields++;
    if (weekendActivities.isNotEmpty) filledFields++;

    if (introvertExtrovert != null && introvertExtrovert!.isNotEmpty) filledFields++;
    if (loveLanguage != null && loveLanguage!.isNotEmpty) filledFields++;
    if (mbti != null && mbti!.isNotEmpty) filledFields++;
    if (politicalViews != null && politicalViews!.isNotEmpty) filledFields++;
    if (coreValues != null && coreValues!.isNotEmpty) filledFields++;

    if (promptPerfectDate != null && promptPerfectDate!.isNotEmpty) filledFields++;
    if (promptFallForYou != null && promptFallForYou!.isNotEmpty) filledFields++;
    if (promptGreenFlag != null && promptGreenFlag!.isNotEmpty) filledFields++;
    if (promptTwoTruths != null && promptTwoTruths!.isNotEmpty) filledFields++;

    totalFields = 37;
    return ((filledFields / totalFields) * 100).round();
  }

  bool isCategoryComplete(String category) {
    switch (category.toLowerCase()) {
      case 'basic':
        return (firstName?.isNotEmpty ?? false) &&
            dob != null &&
            (gender?.isNotEmpty ?? false) &&
            (interestedIn?.isNotEmpty ?? false) &&
            (location?.isNotEmpty ?? false) &&
            photos.isNotEmpty &&
            (bio?.isNotEmpty ?? false);
      case 'personal':
        return (height?.isNotEmpty ?? false) &&
            (bodyType?.isNotEmpty ?? false) &&
            (ethnicity?.isNotEmpty ?? false) &&
            (religion?.isNotEmpty ?? false) &&
            languages.isNotEmpty;
      case 'lifestyle':
        return (smoking?.isNotEmpty ?? false) &&
            (drinking?.isNotEmpty ?? false) &&
            (fitness?.isNotEmpty ?? false) &&
            (diet?.isNotEmpty ?? false) &&
            (sleepingHabits?.isNotEmpty ?? false);
      case 'work':
        return (occupation?.isNotEmpty ?? false) &&
            (industry?.isNotEmpty ?? false) &&
            (educationLevel?.isNotEmpty ?? false) &&
            (school?.isNotEmpty ?? false);
      case 'goals':
        return lookingFor.isNotEmpty &&
            openToLongDistance != null &&
            (wantKids?.isNotEmpty ?? false);
      case 'interests':
        return hobbies.isNotEmpty &&
            musicGenres.isNotEmpty &&
            moviesShows.isNotEmpty &&
            weekendActivities.isNotEmpty;
      case 'personality':
        return (introvertExtrovert?.isNotEmpty ?? false) &&
            (loveLanguage?.isNotEmpty ?? false) &&
            (mbti?.isNotEmpty ?? false) &&
            (politicalViews?.isNotEmpty ?? false) &&
            (coreValues?.isNotEmpty ?? false);
      case 'media':
        return photos.length >= 4; // Min 4 photos as requested
      case 'prompts':
        return (promptPerfectDate?.isNotEmpty ?? false) &&
            (promptFallForYou?.isNotEmpty ?? false) &&
            (promptGreenFlag?.isNotEmpty ?? false) &&
            (promptTwoTruths?.isNotEmpty ?? false);
      case 'privacy':
        return true; // Simple switches, always "complete" in terms of state
      default:
        return true;
    }
  }
}
