// // lib/application/services/progressive_disclosure_service.dart

// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../../domain/models/user_progress.dart';

// class ProgressiveDisclosureService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   Future<UserProgress> getUserProgress(String userId) async {
//     final doc = await _firestore.collection('user_progress').doc(userId).get();
    
//     if (!doc.exists) {
//       final newProgress = UserProgress(userId: userId);
//       await _firestore.collection('user_progress').doc(userId).set(newProgress.toJson());
//       return newProgress;
//     }
    
//     return UserProgress.fromJson({...doc.data()!, 'userId': userId});
//   }

//   Future<void> recordFirstHabit(String userId) async {
//     final progress = await getUserProgress(userId);
    
//     if (progress.firstHabitCreatedAt == null) {
//       await _firestore.collection('user_progress').doc(userId).update({
//         'firstHabitCreatedAt': FieldValue.serverTimestamp(),
//         'habitsCreated': FieldValue.increment(1),
//       });
//     } else {
//       await _firestore.collection('user_progress').doc(userId).update({
//         'habitsCreated': FieldValue.increment(1),
//       });
//     }
//   }

//   Future<void> recordFirstLog(String userId) async {
//     final progress = await getUserProgress(userId);
    
//     if (progress.firstLogAt == null) {
//       await _firestore.collection('user_progress').doc(userId).update({
//         'firstLogAt': FieldValue.serverTimestamp(),
//         'totalLogsCount': FieldValue.increment(1),
//       });
//     } else {
//       await _firestore.collection('user_progress').doc(userId).update({
//         'totalLogsCount': FieldValue.increment(1),
//       });
//     }
//   }

//   Future<void> completeOnboarding(String userId) async {
//     await _firestore.collection('user_progress').doc(userId).update({
//       'onboardingCompleted': true,
//     });
//   }

//   OnboardingPhase determinePhase(UserProgress progress) {
//     if (progress.firstHabitCreatedAt == null) {
//       return OnboardingPhase.trackingOnly;
//     }

//     final daysSinceFirst = DateTime.now()
//         .difference(progress.firstHabitCreatedAt!)
//         .inDays;

//     if (daysSinceFirst < 3) {
//       return OnboardingPhase.trackingOnly;
//     } else if (daysSinceFirst < 8) {
//       return OnboardingPhase.basicStats;
//     } else if (progress.totalLogsCount >= 10) {
//       return OnboardingPhase.insightsEnabled;
//     }

//     return OnboardingPhase.basicStats;
//   }

//   bool shouldShowInsights(UserProgress progress) {
//     return determinePhase(progress) == OnboardingPhase.insightsEnabled;
//   }

//   bool shouldShowStats(UserProgress progress) {
//     final phase = determinePhase(progress);
//     return phase == OnboardingPhase.basicStats || 
//            phase == OnboardingPhase.insightsEnabled;
//   }
// }

// lib/application/services/progressive_disclosure_service.dart

import '../../domain/models/user_progress.dart';

class ProgressiveDisclosureService {
  OnboardingPhase determinePhase(UserProgress progress) {
    if (progress.firstHabitCreatedAt == null) {
      return OnboardingPhase.trackingOnly;
    }

    final daysSinceFirst = DateTime.now()
        .difference(progress.firstHabitCreatedAt!)
        .inDays;

    if (daysSinceFirst < 3) {
      return OnboardingPhase.trackingOnly;
    }

    if (daysSinceFirst < 8) {
      return OnboardingPhase.basicStats;
    }

    if (progress.totalLogsCount >= 10) {
      return OnboardingPhase.insightsEnabled;
    }

    return OnboardingPhase.basicStats;
  }

  bool shouldShowInsights(UserProgress progress) {
    return determinePhase(progress) == OnboardingPhase.insightsEnabled;
  }

  bool shouldShowStats(UserProgress progress) {
    final phase = determinePhase(progress);
    return phase == OnboardingPhase.basicStats ||
        phase == OnboardingPhase.insightsEnabled;
  }
}

