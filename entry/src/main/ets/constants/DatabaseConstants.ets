/**
 * Database table names, column names, and CREATE TABLE SQL statements.
 */

// ── Table Names ──
export const TABLE_NOTES: string = 'notes';
export const TABLE_TODO_CATEGORIES: string = 'todo_categories';
export const TABLE_TODOS: string = 'todos';
export const TABLE_POMODORO_SESSIONS: string = 'pomodoro_sessions';

// ── Notes Column Names ──
export const COL_NOTES_ID: string = 'id';
export const COL_NOTES_TITLE: string = 'title';
export const COL_NOTES_CONTENT: string = 'content';
export const COL_NOTES_CREATED_AT: string = 'created_at';
export const COL_NOTES_UPDATED_AT: string = 'updated_at';
export const COL_NOTES_COLOR_TAG: string = 'color_tag';
export const COL_NOTES_CATEGORY_ID: string = 'category_id';
export const COL_NOTES_IS_PINNED: string = 'is_pinned';

// ── Todo Categories Column Names ──
export const COL_TODO_CAT_ID: string = 'id';
export const COL_TODO_CAT_NAME: string = 'name';
export const COL_TODO_CAT_COLOR_HEX: string = 'color_hex';
export const COL_TODO_CAT_SORT_ORDER: string = 'sort_order';

// ── Todos Column Names ──
export const COL_TODOS_ID: string = 'id';
export const COL_TODOS_TITLE: string = 'title';
export const COL_TODOS_DESCRIPTION: string = 'description';
export const COL_TODOS_IS_COMPLETED: string = 'is_completed';
export const COL_TODOS_PRIORITY: string = 'priority';
export const COL_TODOS_CATEGORY_ID: string = 'category_id';
export const COL_TODOS_REMINDER_TIME: string = 'reminder_time';
export const COL_TODOS_REMINDER_REPEAT_TYPE: string = 'reminder_repeat_type';
export const COL_TODOS_CREATED_AT: string = 'created_at';
export const COL_TODOS_DUE_DATE: string = 'due_date';
export const COL_TODOS_COMPLETED_AT: string = 'completed_at';

// ── Pomodoro Sessions Column Names ──
export const COL_POM_ID: string = 'id';
export const COL_POM_START_TIME: string = 'start_time';
export const COL_POM_END_TIME: string = 'end_time';
export const COL_POM_TYPE: string = 'type';
export const COL_POM_DURATION: string = 'duration';
export const COL_POM_IS_COMPLETED: string = 'is_completed';
export const COL_POM_ABANDONED_AT: string = 'abandoned_at';

// ── CREATE TABLE SQL Statements ──
export const CREATE_TABLE_NOTES: string =
  `CREATE TABLE IF NOT EXISTS ${TABLE_NOTES} (` +
  `${COL_NOTES_ID} TEXT PRIMARY KEY, ` +
  `${COL_NOTES_TITLE} TEXT NOT NULL DEFAULT '', ` +
  `${COL_NOTES_CONTENT} TEXT NOT NULL DEFAULT '', ` +
  `${COL_NOTES_CREATED_AT} INTEGER NOT NULL, ` +
  `${COL_NOTES_UPDATED_AT} INTEGER NOT NULL, ` +
  `${COL_NOTES_COLOR_TAG} TEXT NOT NULL DEFAULT '#4A90D9', ` +
  `${COL_NOTES_CATEGORY_ID} TEXT NOT NULL DEFAULT '未分类', ` +
  `${COL_NOTES_IS_PINNED} INTEGER NOT NULL DEFAULT 0)`;

export const CREATE_TABLE_TODO_CATEGORIES: string =
  `CREATE TABLE IF NOT EXISTS ${TABLE_TODO_CATEGORIES} (` +
  `${COL_TODO_CAT_ID} TEXT PRIMARY KEY, ` +
  `${COL_TODO_CAT_NAME} TEXT NOT NULL, ` +
  `${COL_TODO_CAT_COLOR_HEX} TEXT NOT NULL DEFAULT '#4A90D9', ` +
  `${COL_TODO_CAT_SORT_ORDER} INTEGER NOT NULL DEFAULT 0)`;

export const CREATE_TABLE_TODOS: string =
  `CREATE TABLE IF NOT EXISTS ${TABLE_TODOS} (` +
  `${COL_TODOS_ID} TEXT PRIMARY KEY, ` +
  `${COL_TODOS_TITLE} TEXT NOT NULL, ` +
  `${COL_TODOS_DESCRIPTION} TEXT NOT NULL DEFAULT '', ` +
  `${COL_TODOS_IS_COMPLETED} INTEGER NOT NULL DEFAULT 0, ` +
  `${COL_TODOS_PRIORITY} INTEGER NOT NULL DEFAULT 0, ` +
  `${COL_TODOS_CATEGORY_ID} TEXT NOT NULL, ` +
  `${COL_TODOS_REMINDER_TIME} INTEGER NOT NULL DEFAULT 0, ` +
  `${COL_TODOS_REMINDER_REPEAT_TYPE} INTEGER NOT NULL DEFAULT 0, ` +
  `${COL_TODOS_CREATED_AT} INTEGER NOT NULL, ` +
  `${COL_TODOS_DUE_DATE} INTEGER NOT NULL DEFAULT 0, ` +
  `${COL_TODOS_COMPLETED_AT} INTEGER NOT NULL DEFAULT 0)`;

export const CREATE_TABLE_POMODORO_SESSIONS: string =
  `CREATE TABLE IF NOT EXISTS ${TABLE_POMODORO_SESSIONS} (` +
  `${COL_POM_ID} TEXT PRIMARY KEY, ` +
  `${COL_POM_START_TIME} INTEGER NOT NULL, ` +
  `${COL_POM_END_TIME} INTEGER NOT NULL DEFAULT 0, ` +
  `${COL_POM_TYPE} INTEGER NOT NULL DEFAULT 0, ` +
  `${COL_POM_DURATION} INTEGER NOT NULL DEFAULT 0, ` +
  `${COL_POM_IS_COMPLETED} INTEGER NOT NULL DEFAULT 0, ` +
  `${COL_POM_ABANDONED_AT} INTEGER NOT NULL DEFAULT 0)`;

export const ALL_CREATE_TABLE_SQL: string[] = [
  CREATE_TABLE_NOTES,
  CREATE_TABLE_TODO_CATEGORIES,
  CREATE_TABLE_TODOS,
  CREATE_TABLE_POMODORO_SESSIONS,
];
