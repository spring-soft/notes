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

// ── Music Tracks Column Names ──
export const COL_TRACKS_ID: string = 'id';
export const COL_TRACKS_TITLE: string = 'title';
export const COL_TRACKS_ARTIST: string = 'artist';
export const COL_TRACKS_ALBUM: string = 'album';
export const COL_TRACKS_DURATION_MS: string = 'duration_ms';
export const COL_TRACKS_FILE_URI: string = 'file_uri';
export const COL_TRACKS_ALBUM_ART_URI: string = 'album_art_uri';
export const COL_TRACKS_SOURCE: string = 'source';
export const COL_TRACKS_SERVER_TRACK_ID: string = 'server_track_id';
export const COL_TRACKS_DATE_ADDED: string = 'date_added';

// ── Music Playlists Column Names ──
export const COL_PLAYLISTS_ID: string = 'id';
export const COL_PLAYLISTS_NAME: string = 'name';
export const COL_PLAYLISTS_CREATED_AT: string = 'created_at';

// ── Music Playlist-Track Junction Column Names ──
export const COL_PLTRACKS_PLAYLIST_ID: string = 'playlist_id';
export const COL_PLTRACKS_TRACK_ID: string = 'track_id';
export const COL_PLTRACKS_POSITION: string = 'position';

// ── CREATE TABLE SQL Statements (Music) ──
export const TABLE_MUSIC_TRACKS: string = 'music_tracks';
export const TABLE_MUSIC_PLAYLISTS: string = 'music_playlists';
export const TABLE_MUSIC_PLAYLIST_TRACKS: string = 'music_playlist_tracks';

export const CREATE_TABLE_MUSIC_TRACKS: string =
  `CREATE TABLE IF NOT EXISTS ${TABLE_MUSIC_TRACKS} (` +
  `${COL_TRACKS_ID} TEXT PRIMARY KEY, ` +
  `${COL_TRACKS_TITLE} TEXT NOT NULL DEFAULT '', ` +
  `${COL_TRACKS_ARTIST} TEXT NOT NULL DEFAULT '', ` +
  `${COL_TRACKS_ALBUM} TEXT NOT NULL DEFAULT '', ` +
  `${COL_TRACKS_DURATION_MS} INTEGER NOT NULL DEFAULT 0, ` +
  `${COL_TRACKS_FILE_URI} TEXT NOT NULL DEFAULT '', ` +
  `${COL_TRACKS_ALBUM_ART_URI} TEXT NOT NULL DEFAULT '', ` +
  `${COL_TRACKS_SOURCE} TEXT NOT NULL DEFAULT 'local', ` +
  `${COL_TRACKS_SERVER_TRACK_ID} TEXT NOT NULL DEFAULT '', ` +
  `${COL_TRACKS_DATE_ADDED} INTEGER NOT NULL)`;

export const CREATE_TABLE_MUSIC_PLAYLISTS: string =
  `CREATE TABLE IF NOT EXISTS ${TABLE_MUSIC_PLAYLISTS} (` +
  `${COL_PLAYLISTS_ID} TEXT PRIMARY KEY, ` +
  `${COL_PLAYLISTS_NAME} TEXT NOT NULL, ` +
  `${COL_PLAYLISTS_CREATED_AT} INTEGER NOT NULL)`;

export const CREATE_TABLE_MUSIC_PLAYLIST_TRACKS: string =
  `CREATE TABLE IF NOT EXISTS ${TABLE_MUSIC_PLAYLIST_TRACKS} (` +
  `${COL_PLTRACKS_PLAYLIST_ID} TEXT NOT NULL, ` +
  `${COL_PLTRACKS_TRACK_ID} TEXT NOT NULL, ` +
  `${COL_PLTRACKS_POSITION} INTEGER NOT NULL DEFAULT 0, ` +
  `PRIMARY KEY (${COL_PLTRACKS_PLAYLIST_ID}, ${COL_PLTRACKS_TRACK_ID}))`;

export const ALL_CREATE_TABLE_SQL: string[] = [
  CREATE_TABLE_NOTES,
  CREATE_TABLE_TODO_CATEGORIES,
  CREATE_TABLE_TODOS,
  CREATE_TABLE_POMODORO_SESSIONS,
  CREATE_TABLE_MUSIC_TRACKS,
  CREATE_TABLE_MUSIC_PLAYLISTS,
  CREATE_TABLE_MUSIC_PLAYLIST_TRACKS,
];
