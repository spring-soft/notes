import { Note, NoteSortOrder } from '../model/NoteModel';
import { ID } from '../model/AppConstantsModel';
import { NoteRepository } from '../repository/NoteRepository';
import { generateId } from '../utils/IdGenerator';
import { now } from '../utils/DateUtils';

/**
 * ViewModel for the Notes feature.
 * Manages note CRUD, search, filtering, and sorting.
 */
@Observed
export class NotesViewModel {
  notes: Note[] = [];
  filteredNotes: Note[] = [];
  searchQuery: string = '';
  currentSortOrder: NoteSortOrder = NoteSortOrder.UPDATED_DESC;
  isLoading: boolean = false;
  isPinnedFilter: boolean = false;

  private repository: NoteRepository;

  constructor(repository: NoteRepository) {
    this.repository = repository;
  }

  /**
   * Loads a single note by ID directly from the repository.
   * Avoids loading all notes when only one is needed.
   */
  async loadNoteById(id: ID): Promise<Note | null> {
    return await this.repository.getById(id);
  }

  /**
   * Loads all notes from the repository.
   */
  async loadNotes(): Promise<void> {
    this.isLoading = true;
    try {
      this.notes = await this.repository.getAll(this.currentSortOrder);
      this.applyFilters();
    } catch (err) {
      console.error('NotesViewModel.loadNotes: query failed - ' + String(err));
      this.notes = [];
      this.filteredNotes = [];
    }
    this.isLoading = false;
  }

  /**
   * Creates a new note.
   */
  async createNote(title: string, content: string, colorTag: string, categoryId: string): Promise<Note> {
    const timestamp: number = now();
    const note: Note = {
      id: generateId(),
      title: title,
      content: content,
      createdAt: timestamp,
      updatedAt: timestamp,
      colorTag: colorTag,
      isPinned: false,
      categoryId: categoryId,
    };
    try {
      await this.repository.insert(note);
    } catch (err) {
      console.error('NotesViewModel.createNote: insert failed - ' + String(err));
      throw new Error(String(err));
    }
    const newNotesList: Note[] = [note];
    for (const n of this.notes) {
      newNotesList.push(n);
    }
    this.notes = newNotesList;
    this.applyFilters();
    return note;
  }

  /**
   * Updates an existing note.
   */
  async updateNote(updatedNote: Note): Promise<void> {
    const newNote: Note = {
      id: updatedNote.id,
      title: updatedNote.title,
      content: updatedNote.content,
      createdAt: updatedNote.createdAt,
      updatedAt: now(),
      colorTag: updatedNote.colorTag,
      isPinned: updatedNote.isPinned,
      categoryId: updatedNote.categoryId,
    };
    try {
      await this.repository.update(newNote);
    } catch (err) {
      console.error('NotesViewModel.updateNote: update failed - ' + String(err));
      throw new Error(String(err));
    }

    const newNotes: Note[] = [];
    for (const n of this.notes) {
      if (n.id === newNote.id) {
        newNotes.push(newNote);
      } else {
        newNotes.push(n);
      }
    }
    this.notes = newNotes;
    this.applyFilters();
  }

  /**
   * Deletes a note by ID.
   */
  async deleteNote(id: ID): Promise<void> {
    await this.repository.delete(id);
    const newNotes: Note[] = [];
    for (const n of this.notes) {
      if (n.id !== id) {
        newNotes.push(n);
      }
    }
    this.notes = newNotes;
    this.applyFilters();
  }

  /**
   * Toggles the pinned status of a note.
   */
  async togglePin(id: ID): Promise<void> {
    const note: Note | undefined = this.findNoteById(id);
    if (note === undefined) {
      return;
    }
    const updated: Note = {
      id: note.id,
      title: note.title,
      content: note.content,
      createdAt: note.createdAt,
      updatedAt: now(),
      colorTag: note.colorTag,
      isPinned: !note.isPinned,
      categoryId: note.categoryId,
    };
    await this.updateNote(updated);
  }

  /**
   * Updates the search query and re-filters.
   */
  setSearchQuery(query: string): void {
    this.searchQuery = query;
    this.applyFilters();
  }

  /**
   * Toggles the pinned-only filter.
   */
  togglePinnedFilter(): void {
    this.isPinnedFilter = !this.isPinnedFilter;
    this.applyFilters();
  }

  /**
   * Changes the sort order and reloads.
   */
  setSortOrder(order: NoteSortOrder): void {
    this.currentSortOrder = order;
  }

  /**
   * Applies search and pin filters in memory.
   */
  private applyFilters(): void {
    let result: Note[] = this.notes;

    // Sort — make a manual copy before sorting to avoid mutating original
    const sortedNotes: Note[] = [];
    for (const n of result) {
      sortedNotes.push(n);
    }
    if (this.currentSortOrder === NoteSortOrder.UPDATED_DESC) {
      sortedNotes.sort((a: Note, b: Note) => {
        if (a.isPinned !== b.isPinned) {
          return b.isPinned ? 1 : -1;
        }
        return b.updatedAt - a.updatedAt;
      });
    } else if (this.currentSortOrder === NoteSortOrder.UPDATED_ASC) {
      sortedNotes.sort((a: Note, b: Note) => {
        if (a.isPinned !== b.isPinned) {
          return b.isPinned ? 1 : -1;
        }
        return a.updatedAt - b.updatedAt;
      });
    } else if (this.currentSortOrder === NoteSortOrder.TITLE_ASC) {
      sortedNotes.sort((a: Note, b: Note) => {
        if (a.isPinned !== b.isPinned) {
          return b.isPinned ? 1 : -1;
        }
        return a.title.localeCompare(b.title);
      });
    }
    result = sortedNotes;

    // Pin filter
    if (this.isPinnedFilter) {
      result = result.filter((n: Note) => n.isPinned);
    }

    // Search filter
    if (this.searchQuery !== '') {
      const query: string = this.searchQuery.toLowerCase();
      result = result.filter((n: Note) =>
        n.title.toLowerCase().includes(query) || n.content.toLowerCase().includes(query)
      );
    }

    this.filteredNotes = result;
  }

  /**
   * Returns category names that have at least one note in filteredNotes.
   * Categories without notes are excluded.
   */
  getActiveCategories(): string[] {
    const seen: Record<string, boolean> = {};
    const cats: string[] = [];
    for (const note of this.filteredNotes) {
      const cat: string = note.categoryId !== '' ? note.categoryId : '未分类';
      if (seen[cat] === undefined) {
        seen[cat] = true;
        cats.push(cat);
      }
    }
    return cats;
  }

  /**
   * Returns filtered notes belonging to a specific category.
   */
  getNotesByCategory(category: string): Note[] {
    const result: Note[] = [];
    for (const note of this.filteredNotes) {
      const cat: string = note.categoryId !== '' ? note.categoryId : '未分类';
      if (cat === category) {
        result.push(note);
      }
    }
    return result;
  }

  private findNoteById(id: ID): Note | undefined {
    for (const note of this.notes) {
      if (note.id === id) {
        return note;
      }
    }
    return undefined;
  }
}
