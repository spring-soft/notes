/**
 * Application-wide constants.
 */

export class AppConstants {
  static readonly APP_NAME: string = 'MemoFlow';
  static readonly APP_VERSION: string = '1.1.0';

  static readonly MAX_NOTE_TITLE_LENGTH: number = 200;
  static readonly MAX_NOTE_CONTENT_LENGTH: number = 50000;
  static readonly MAX_TODO_TITLE_LENGTH: number = 200;
  static readonly MAX_TODO_DESC_LENGTH: number = 2000;
  static readonly MAX_CATEGORY_NAME_LENGTH: number = 50;

  static readonly DB_NAME: string = 'MemoFlow.db';
  static readonly DB_VERSION: number = 1;

  static readonly PREFERENCES_NAME: string = 'memoflow_settings';

  static readonly NOTIFICATION_TIMER_ID: number = 1001;
  static readonly NOTIFICATION_SESSION_COMPLETE_ID: number = 1002;
}

/**
 * Page route constants for navigation.
 */
export class PageRoutes {
  static readonly INDEX: string = 'pages/Index';
  static readonly NOTES: string = 'pages/NotesPage';
  static readonly NOTE_DETAIL: string = 'pages/NoteDetailPage';
  static readonly TODOS: string = 'pages/TodosPage';
  static readonly POMODORO: string = 'pages/PomodoroPage';
  static readonly SETTINGS: string = 'pages/SettingsPage';
}

/**
 * Navigation destination names.
 */
export class NavDestinationNames {
  static readonly NOTES_LIST: string = 'notes_list';
  static readonly NOTE_DETAIL: string = 'note_detail';
  static readonly TODOS_LIST: string = 'todos_list';
  static readonly POMODORO: string = 'pomodoro';
  static readonly SETTINGS: string = 'settings';
}

/**
 * Tab item configuration.
 */
export interface TabItemConfig {
  id: string;
  title: string;
  icon: ResourceStr;
  selectedIcon: ResourceStr;
  navDestination: string;
}

export function getTabItems(): TabItemConfig[] {
  return [
    {
      id: 'notes',
      title: '笔记',
      icon: '',
      selectedIcon: '',
      navDestination: NavDestinationNames.NOTES_LIST,
    },
    {
      id: 'todos',
      title: '待办',
      icon: '',
      selectedIcon: '',
      navDestination: NavDestinationNames.TODOS_LIST,
    },
    {
      id: 'pomodoro',
      title: '专注',
      icon: '',
      selectedIcon: '',
      navDestination: NavDestinationNames.POMODORO,
    },
    {
      id: 'settings',
      title: '设置',
      icon: '',
      selectedIcon: '',
      navDestination: NavDestinationNames.SETTINGS,
    },
  ];
}
