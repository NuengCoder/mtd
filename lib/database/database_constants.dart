/// Table names
class DbTables {
  static const String tasks = 'tasks';
  static const String homeworks = 'homeworks';
  static const String plans = 'plans';
  static const String planTasks = 'plan_tasks';
  static const String weeklyPlans = 'weekly_plans';
  static const String weeklyPlanTasks = 'weekly_plan_tasks';
  static const String userImages = 'user_images';
  static const String userSounds = 'user_sounds';
  static const String settings = 'settings';
  static const String themeSettings = 'theme_settings';
}

/// Column names for each table
class DbCols {
  // Generic
  static const String id = 'id';
  static const String name = 'name';
  static const String title = 'title';
  static const String data = 'data';
  static const String value = 'value';
  static const String key = 'key';
  static const String mode = 'mode';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  // tasks
  static const String date = 'date';
  static const String time = 'time';
  static const String notifyTime = 'notify_time';
  static const String isComplete = 'is_complete';
  static const String imageId = 'image_id';
  static const String soundId = 'sound_id';

  // homeworks
  static const String deployDate = 'deploy_date';
  static const String deadlineDate = 'deadline_date';
  static const String isSubmitted = 'is_submitted';

  // plans
  // (name, created_at, updated_at)

  // plan_tasks
  static const String planId = 'plan_id';
  // (title, time, notify_time, sound_id, image_id, created_at)

  // weekly_plans
  static const String isSystem = 'is_system';
  static const String autoDeploy = 'auto_deploy';
  // (name, created_at, updated_at)

  // weekly_plan_tasks
  static const String weeklyPlanId = 'weekly_plan_id';
  static const String weekday = 'weekday';
  // (title, time, notify_time, sound_id, image_id, created_at)

  // user_images
  // (name, data, created_at)

  // user_sounds
  static const String durationMs = 'duration_ms';
  // (name, data, created_at)

  // settings
  // (key, value)

  // theme_settings
  static const String colorKey = 'color_key';
  static const String argbValue = 'argb_value';

  static const String filePath = 'file_path';
// (mode, color_key)
  static const String mediaUri = 'media_uri';
}

/// Full CREATE TABLE SQL statements
class DbCreate {
  static const String tasks = '''
    CREATE TABLE IF NOT EXISTS ${DbTables.tasks} (
      ${DbCols.id} INTEGER PRIMARY KEY AUTOINCREMENT,
      ${DbCols.title} TEXT NOT NULL,
      ${DbCols.date} TEXT NOT NULL,
      ${DbCols.time} TEXT,
      ${DbCols.notifyTime} TEXT,
      ${DbCols.isComplete} INTEGER NOT NULL DEFAULT 0,
      ${DbCols.imageId} INTEGER,
      ${DbCols.soundId} INTEGER,
      ${DbCols.createdAt} TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      ${DbCols.updatedAt} TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (${DbCols.imageId}) REFERENCES ${DbTables.userImages}(${DbCols.id}) ON DELETE SET NULL,
      FOREIGN KEY (${DbCols.soundId}) REFERENCES ${DbTables.userSounds}(${DbCols.id}) ON DELETE SET NULL
    );
  ''';

  static const String tasksIndexDate = '''
    CREATE INDEX IF NOT EXISTS idx_tasks_date ON ${DbTables.tasks}(${DbCols.date});
  ''';

  static const String tasksIndexTime = '''
    CREATE INDEX IF NOT EXISTS idx_tasks_time ON ${DbTables.tasks}(${DbCols.time});
  ''';

  static const String homeworks = '''
    CREATE TABLE IF NOT EXISTS ${DbTables.homeworks} (
      ${DbCols.id} INTEGER PRIMARY KEY AUTOINCREMENT,
      ${DbCols.name} TEXT NOT NULL,
      ${DbCols.deployDate} TEXT NOT NULL,
      ${DbCols.deadlineDate} TEXT NOT NULL,
      ${DbCols.isSubmitted} INTEGER NOT NULL DEFAULT 0,
      ${DbCols.imageId} INTEGER,
      ${DbCols.createdAt} TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      ${DbCols.updatedAt} TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (${DbCols.imageId}) REFERENCES ${DbTables.userImages}(${DbCols.id}) ON DELETE SET NULL
    );
  ''';

  static const String homeworksIndexDeploy = '''
    CREATE INDEX IF NOT EXISTS idx_homeworks_deploy ON ${DbTables.homeworks}(${DbCols.deployDate});
  ''';

  static const String homeworksIndexDeadline = '''
    CREATE INDEX IF NOT EXISTS idx_homeworks_deadline ON ${DbTables.homeworks}(${DbCols.deadlineDate});
  ''';

  static const String plans = '''
    CREATE TABLE IF NOT EXISTS ${DbTables.plans} (
      ${DbCols.id} INTEGER PRIMARY KEY AUTOINCREMENT,
      ${DbCols.name} TEXT NOT NULL UNIQUE,
      ${DbCols.createdAt} TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      ${DbCols.updatedAt} TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    );
  ''';

  static const String planTasks = '''
    CREATE TABLE IF NOT EXISTS ${DbTables.planTasks} (
      ${DbCols.id} INTEGER PRIMARY KEY AUTOINCREMENT,
      ${DbCols.planId} INTEGER NOT NULL,
      ${DbCols.title} TEXT NOT NULL,
      ${DbCols.time} TEXT,
      ${DbCols.notifyTime} TEXT,
      ${DbCols.soundId} INTEGER,
      ${DbCols.imageId} INTEGER,
      ${DbCols.createdAt} TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (${DbCols.planId}) REFERENCES ${DbTables.plans}(${DbCols.id}) ON DELETE CASCADE,
      FOREIGN KEY (${DbCols.soundId}) REFERENCES ${DbTables.userSounds}(${DbCols.id}) ON DELETE SET NULL,
      FOREIGN KEY (${DbCols.imageId}) REFERENCES ${DbTables.userImages}(${DbCols.id}) ON DELETE SET NULL
    );
  ''';

  static const String planTasksIndexPlan = '''
    CREATE INDEX IF NOT EXISTS idx_plan_tasks_plan ON ${DbTables.planTasks}(${DbCols.planId});
  ''';

  static const String weeklyPlans = '''
    CREATE TABLE IF NOT EXISTS ${DbTables.weeklyPlans} (
      ${DbCols.id} INTEGER PRIMARY KEY AUTOINCREMENT,
      ${DbCols.name} TEXT NOT NULL UNIQUE,
      ${DbCols.isSystem} INTEGER NOT NULL DEFAULT 0,
      ${DbCols.autoDeploy} INTEGER NOT NULL DEFAULT 0,
      ${DbCols.createdAt} TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      ${DbCols.updatedAt} TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    );
  ''';

  static const String weeklyPlanTasks = '''
    CREATE TABLE IF NOT EXISTS ${DbTables.weeklyPlanTasks} (
      ${DbCols.id} INTEGER PRIMARY KEY AUTOINCREMENT,
      ${DbCols.weeklyPlanId} INTEGER NOT NULL,
      ${DbCols.title} TEXT NOT NULL,
      ${DbCols.time} TEXT,
      ${DbCols.weekday} TEXT NOT NULL,
      ${DbCols.notifyTime} TEXT,
      ${DbCols.soundId} INTEGER,
      ${DbCols.imageId} INTEGER,
      ${DbCols.createdAt} TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (${DbCols.weeklyPlanId}) REFERENCES ${DbTables.weeklyPlans}(${DbCols.id}) ON DELETE CASCADE,
      FOREIGN KEY (${DbCols.soundId}) REFERENCES ${DbTables.userSounds}(${DbCols.id}) ON DELETE SET NULL,
      FOREIGN KEY (${DbCols.imageId}) REFERENCES ${DbTables.userImages}(${DbCols.id}) ON DELETE SET NULL
    );
  ''';

  static const String weeklyPlanTasksIndexPlan = '''
    CREATE INDEX IF NOT EXISTS idx_wpt_plan ON ${DbTables.weeklyPlanTasks}(${DbCols.weeklyPlanId});
  ''';

  static const String weeklyPlanTasksIndexWeekday = '''
    CREATE INDEX IF NOT EXISTS idx_wpt_weekday ON ${DbTables.weeklyPlanTasks}(${DbCols.weekday});
  ''';

  static final String userImages = '''
    CREATE TABLE IF NOT EXISTS ${DbTables.userImages} (
      ${DbCols.id} INTEGER PRIMARY KEY AUTOINCREMENT,
      ${DbCols.name} TEXT NOT NULL,
      ${DbCols.filePath} TEXT NOT NULL,
      ${DbCols.createdAt} TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    );
  ''';

  static final String userSounds = '''
    CREATE TABLE IF NOT EXISTS ${DbTables.userSounds} (
      ${DbCols.id} INTEGER PRIMARY KEY AUTOINCREMENT,
      ${DbCols.name} TEXT NOT NULL,
      ${DbCols.filePath} TEXT NOT NULL,
      ${DbCols.mediaUri} TEXT,
      ${DbCols.durationMs} INTEGER NOT NULL,
      ${DbCols.createdAt} TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    );
  ''';

  static const String settings = '''
    CREATE TABLE IF NOT EXISTS ${DbTables.settings} (
      ${DbCols.key} TEXT PRIMARY KEY,
      ${DbCols.value} TEXT NOT NULL
    );
  ''';

  static const String themeSettings = '''
    CREATE TABLE IF NOT EXISTS ${DbTables.themeSettings} (
      ${DbCols.id} INTEGER PRIMARY KEY AUTOINCREMENT,
      ${DbCols.mode} TEXT NOT NULL,
      ${DbCols.colorKey} TEXT NOT NULL,
      ${DbCols.argbValue} TEXT NOT NULL,
      UNIQUE(${DbCols.mode}, ${DbCols.colorKey})
    );
  ''';
}