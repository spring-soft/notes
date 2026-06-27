/**
 * Application icon glyphs — clean, consistent Unicode symbols.
 *
 * Usage: import { ICON } from '../utils/IconGlyphs';
 *         Text(ICON.PLUS) ...
 */
export class ICON {
  // Navigation / Actions
  static readonly BACK: string = '‹';
  static readonly MENU: string = '☰';
  static readonly PLUS: string = '+';
  static readonly CLOSE: string = '✕';
  static readonly CHECK: string = '✓';
  static readonly MORE: string = '⋯';
  static readonly DELETE: string = '✕';

  // Tab bar
  static readonly NOTES: string = '☷';
  static readonly TODOS: string = '☑';
  static readonly POMODORO: string = '◷';
  static readonly SETTINGS: string = '⚙';

  // Note actions
  static readonly COLOR: string = '⬤';
  static readonly SEARCH: string = '🔍';
  static readonly SORT: string = '⇅';
  static readonly PIN: string = '📌';

  // Status / Empty states
  static readonly EMPTY_NOTES: string = '☷';
  static readonly EMPTY_TODOS: string = '☐';
  static readonly EMPTY_GENERAL: string = '○';

  // Media
  static readonly PLAY: string = '▶';
  static readonly PAUSE: string = '⏸';
  static readonly STOP: string = '⏹';
  static readonly PAUSE_BARS: string = '❚❚';

  // Timer
  static readonly START: string = '▶';
  static readonly RESET: string = '↺';
  static readonly SKIP: string = '⏭';

  // Misc
  static readonly TRASH: string = '🗑';
  static readonly ALARM: string = '⏰';
  static readonly IMAGE: string = '🖼';
  static readonly RECORDING: string = '🎙';
}
