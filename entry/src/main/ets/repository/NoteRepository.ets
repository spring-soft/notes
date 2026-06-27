import { relationalStore } from '@kit.ArkData';
import { Note, NoteSortOrder } from '../model/NoteModel';
import { ID } from '../model/AppConstantsModel';
import {
  TABLE_NOTES,
  COL_NOTES_ID,
  COL_NOTES_TITLE,
  COL_NOTES_CONTENT,
  COL_NOTES_CREATED_AT,
  COL_NOTES_UPDATED_AT,
  COL_NOTES_COLOR_TAG,
  COL_NOTES_IS_PINNED,
  COL_NOTES_CATEGORY_ID,
} from '../constants/DatabaseConstants';

export class NoteRepository {
  private store: relationalStore.RdbStore;

  constructor(store: relationalStore.RdbStore) {
    this.store = store;
  }

  async getAll(sortOrder: NoteSortOrder): Promise<Note[]> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_NOTES);
    // Sort is handled in-memory by NotesViewModel.applyFilters().
    // Only do a basic pin-first ordering at the DB level.
    predicates.orderByDesc(COL_NOTES_IS_PINNED);

    const resultSet: relationalStore.ResultSet = await this.store.query(predicates);
    const notes: Note[] = [];

    while (resultSet.goToNextRow()) {
      notes.push(this.rowToNote(resultSet));
    }
    resultSet.close();
    return notes;
  }

  async getById(id: ID): Promise<Note | null> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_NOTES);
    predicates.equalTo(COL_NOTES_ID, id);

    const resultSet: relationalStore.ResultSet = await this.store.query(predicates);
    let note: Note | null = null;
    if (resultSet.goToFirstRow()) {
      note = this.rowToNote(resultSet);
    }
    resultSet.close();
    return note;
  }

  async search(query: string): Promise<Note[]> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_NOTES);
    predicates.like(COL_NOTES_TITLE, `%${query}%`)
      .or()
      .like(COL_NOTES_CONTENT, `%${query}%`);
    predicates.orderByAsc(`${COL_NOTES_IS_PINNED} DESC, ${COL_NOTES_UPDATED_AT} DESC`);

    const resultSet: relationalStore.ResultSet = await this.store.query(predicates);
    const notes: Note[] = [];
    while (resultSet.goToNextRow()) {
      notes.push(this.rowToNote(resultSet));
    }
    resultSet.close();
    return notes;
  }

  async getPinned(): Promise<Note[]> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_NOTES);
    predicates.equalTo(COL_NOTES_IS_PINNED, 1);
    predicates.orderByAsc(COL_NOTES_UPDATED_AT + ' DESC');

    const resultSet: relationalStore.ResultSet = await this.store.query(predicates);
    const notes: Note[] = [];
    while (resultSet.goToNextRow()) {
      notes.push(this.rowToNote(resultSet));
    }
    resultSet.close();
    return notes;
  }

  async insert(note: Note): Promise<void> {
    const valueBucket: relationalStore.ValuesBucket = this.noteToValuesBucket(note);
    await this.store.insert(TABLE_NOTES, valueBucket);
  }

  async update(note: Note): Promise<void> {
    const valueBucket: relationalStore.ValuesBucket = this.noteToValuesBucket(note);
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_NOTES);
    predicates.equalTo(COL_NOTES_ID, note.id);
    await this.store.update(valueBucket, predicates);
  }

  async delete(id: ID): Promise<void> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_NOTES);
    predicates.equalTo(COL_NOTES_ID, id);
    await this.store.delete(predicates);
  }

  private rowToNote(resultSet: relationalStore.ResultSet): Note {
    const catIdx: number = resultSet.getColumnIndex(COL_NOTES_CATEGORY_ID);
    return {
      id: resultSet.getString(resultSet.getColumnIndex(COL_NOTES_ID)),
      title: resultSet.getString(resultSet.getColumnIndex(COL_NOTES_TITLE)),
      content: resultSet.getString(resultSet.getColumnIndex(COL_NOTES_CONTENT)),
      createdAt: resultSet.getLong(resultSet.getColumnIndex(COL_NOTES_CREATED_AT)),
      updatedAt: resultSet.getLong(resultSet.getColumnIndex(COL_NOTES_UPDATED_AT)),
      colorTag: resultSet.getString(resultSet.getColumnIndex(COL_NOTES_COLOR_TAG)),
      isPinned: resultSet.getLong(resultSet.getColumnIndex(COL_NOTES_IS_PINNED)) === 1,
      categoryId: catIdx >= 0 ? resultSet.getString(catIdx) : '未分类',
    };
  }

  private noteToValuesBucket(note: Note): relationalStore.ValuesBucket {
    const bucket: relationalStore.ValuesBucket = {};
    bucket[COL_NOTES_ID] = note.id;
    bucket[COL_NOTES_TITLE] = note.title;
    bucket[COL_NOTES_CONTENT] = note.content;
    bucket[COL_NOTES_CREATED_AT] = note.createdAt;
    bucket[COL_NOTES_UPDATED_AT] = note.updatedAt;
    bucket[COL_NOTES_COLOR_TAG] = note.colorTag;
    bucket[COL_NOTES_IS_PINNED] = note.isPinned ? 1 : 0;
    bucket[COL_NOTES_CATEGORY_ID] = note.categoryId;
    return bucket;
  }
}
