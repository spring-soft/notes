/**
 * Application icon library — HarmonyOS NEXT SymbolGlyph resources.
 *
 * All icons are now native SymbolGlyph system symbols instead of Unicode
 * text characters.  This gives crisp vector rendering, automatic dark-mode
 * adaptation, and multi-color layering support.
 *
 * Usage: import { ICON } from '../utils/IconGlyphs';
 *         SymbolGlyph(ICON.PLUS).fontSize(28).fontColor([Color.White])
 *
 * Key difference from the old Text() approach: fontColor takes an ARRAY
 * of ResourceColor, e.g. `.fontColor([this.themeConfig.primaryColor])`.
 *
 * Full sys.symbol reference: https://developer.huawei.com/consumer/cn/design/harmonyos-symbol/
 */
export class ICON {
  // ── Navigation / Actions ──
  static readonly BACK: Resource = $r('sys.symbol.chevron_backward');
  static readonly MENU: Resource = $r('sys.symbol.text_alignleft');
  static readonly PLUS: Resource = $r('sys.symbol.plus');
  static readonly CLOSE: Resource = $r('sys.symbol.xmark');
  static readonly CHECK: Resource = $r('sys.symbol.checkmark');
  static readonly MORE: Resource = $r('sys.symbol.ellipsis_bubble');
  static readonly DELETE: Resource = $r('sys.symbol.trash');

  // ── Tab bar ──
  static readonly NOTES: Resource = $r('sys.symbol.doc_text');
  static readonly TODOS: Resource = $r('sys.symbol.list_bullet');
  static readonly POMODORO: Resource = $r('sys.symbol.timer');
  static readonly SETTINGS: Resource = $r('sys.symbol.gearshape');

  // ── Note actions ──
  static readonly COLOR: Resource = $r('sys.symbol.circle_fill');
  static readonly SEARCH: Resource = $r('sys.symbol.magnifyingglass');
  static readonly SORT: Resource = $r('sys.symbol.arrow_counterclockwise');
  static readonly PIN: Resource = $r('sys.symbol.pin');

  // ── Status / Empty states ──
  static readonly EMPTY_NOTES: Resource = $r('sys.symbol.doc_text');
  static readonly EMPTY_TODOS: Resource = $r('sys.symbol.list_bullet');
  static readonly EMPTY_GENERAL: Resource = $r('sys.symbol.circle');

  // ── Media ──
  static readonly PLAY: Resource = $r('sys.symbol.play_fill');
  static readonly PAUSE: Resource = $r('sys.symbol.pause_fill');
  static readonly STOP: Resource = $r('sys.symbol.stop_circle');
  static readonly PAUSE_BARS: Resource = $r('sys.symbol.pause_fill');

  // ── Timer ──
  static readonly START: Resource = $r('sys.symbol.play_fill');
  static readonly RESET: Resource = $r('sys.symbol.arrow_counterclockwise');
  static readonly SKIP: Resource = $r('sys.symbol.forward_end_fill');

  // ── Misc ──
  static readonly TRASH: Resource = $r('sys.symbol.trash');
  static readonly ALARM: Resource = $r('sys.symbol.alarm');
  static readonly IMAGE: Resource = $r('sys.symbol.ohos_photo');
  static readonly RECORDING: Resource = $r('sys.symbol.mic');
  static readonly EDIT: Resource = $r('sys.symbol.square_and_pencil');
  static readonly VIEW_GRID: Resource = $r('sys.symbol.square_grid_2x2');
  static readonly VIEW_LIST: Resource = $r('sys.symbol.list_bullet');
}
