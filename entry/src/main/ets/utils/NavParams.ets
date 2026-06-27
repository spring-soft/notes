/**
 * Simple navigation parameter store.
 * Used to pass data between pages without indexed access (arkts-no-props-by-index).
 * Pages set values before pushing to NavPathStack, and read them in aboutToAppear.
 *
 * Also provides a refresh signal for the notes list:
 * NoteDetailPage sets needsNotesRefresh=true before popping,
 * and NotesPage checks and resets it to trigger a reload.
 */
export class NavParams {
  static noteId: string = '';
  static needsNotesRefresh: boolean = false;
  /**
   * Callback registered by NotesPage so that NoteDetailPage can trigger an
   * immediate refresh before popping.  This bypasses the unreliable onShown
   * lifecycle callback on NavDestination.
   */
  static triggerNotesRefresh: () => void = () => {};
}
