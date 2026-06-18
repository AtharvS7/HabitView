#!/bin/bash

echo "Creating HabitVault folder structure..."

BASE=lib

mkdir -p $BASE/core/{theme,constants,utils}
mkdir -p $BASE/domain/models
mkdir -p $BASE/data/{repositories,firebase}
mkdir -p $BASE/application/{services,providers}
mkdir -p $BASE/presentation/screens/{auth,today,habits,insights,onboarding}
mkdir -p $BASE/presentation/widgets

touch $BASE/app.dart

touch $BASE/core/theme/app_theme.dart
touch $BASE/core/constants/app_constants.dart
touch $BASE/core/utils/date_utils.dart

touch $BASE/domain/models/habit.dart
touch $BASE/domain/models/habit_log.dart
touch $BASE/domain/models/insight.dart
touch $BASE/domain/models/user_progress.dart

touch $BASE/data/repositories/habit_repository.dart
touch $BASE/data/repositories/habit_log_repository.dart
touch $BASE/data/repositories/insight_repository.dart
touch $BASE/data/firebase/firestore_service.dart

touch $BASE/application/services/consistency_calculator.dart
touch $BASE/application/services/insight_engine.dart
touch $BASE/application/services/progressive_disclosure_service.dart

touch $BASE/application/providers/habit_providers.dart
touch $BASE/application/providers/insight_providers.dart
touch $BASE/application/providers/user_progress_provider.dart

touch $BASE/presentation/screens/auth/login_screen.dart
touch $BASE/presentation/screens/auth/register_screen.dart
touch $BASE/presentation/screens/today/today_screen.dart
touch $BASE/presentation/screens/habits/habit_create_screen.dart
touch $BASE/presentation/screens/habits/habit_edit_screen.dart
touch $BASE/presentation/screens/insights/insights_screen.dart
touch $BASE/presentation/screens/onboarding/onboarding_screen.dart

touch $BASE/presentation/widgets/habit_card.dart
touch $BASE/presentation/widgets/metric_card.dart
touch $BASE/presentation/widgets/insight_card.dart
touch $BASE/presentation/widgets/skip_reflection_sheet.dart

echo "HabitVault architecture created successfully."
