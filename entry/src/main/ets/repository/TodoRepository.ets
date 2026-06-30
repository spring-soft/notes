import { relationalStore } from '@kit.ArkData';
import { TodoItem, TodoCategory, TodoFilterType } from '../model/TodoModel';
import { ID } from '../model/AppConstantsModel';
import {
  TABLE_TODOS,
  COL_TODOS_ID,
  COL_TODOS_TITLE,
  COL_TODOS_DESCRIPTION,
  COL_TODOS_IS_COMPLETED,
  COL_TODOS_PRIORITY,
  COL_TODOS_CATEGORY_ID,
  COL_TODOS_REMINDER_TIME,
  COL_TODOS_REMINDER_REPEAT_TYPE,
  COL_TODOS_CREATED_AT,
  COL_TODOS_DUE_DATE,
  COL_TODOS_COMPLETED_AT,
  TABLE_TODO_CATEGORIES,
  COL_TODO_CAT_ID,
  COL_TODO_CAT_NAME,
  COL_TODO_CAT_COLOR_HEX,
  COL_TODO_CAT_SORT_ORDER,
} from '../constants/DatabaseConstants';

export class TodoRepository {
  private store: relationalStore.RdbStore;

  constructor(store: relationalStore.RdbStore) {
    this.store = store;
  }

  // ── Todo Items ──

  async getAll(filter: TodoFilterType): Promise<TodoItem[]> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_TODOS);
    if (filter === TodoFilterType.ACTIVE) {
      predicates.equalTo(COL_TODOS_IS_COMPLETED, 0);
    } else if (filter === TodoFilterType.COMPLETED) {
      predicates.equalTo(COL_TODOS_IS_COMPLETED, 1);
    }
    predicates.orderByAsc(`${COL_TODOS_IS_COMPLETED} ASC, ${COL_TODOS_CREATED_AT} DESC`);

    const resultSet: relationalStore.ResultSet = await this.store.query(predicates);
    const todos: TodoItem[] = [];
    while (resultSet.goToNextRow()) {
      todos.push(this.rowToTodoItem(resultSet));
    }
    resultSet.close();
    return todos;
  }

  async getByCategoryId(categoryId: ID): Promise<TodoItem[]> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_TODOS);
    predicates.equalTo(COL_TODOS_CATEGORY_ID, categoryId);
    predicates.orderByAsc(`${COL_TODOS_IS_COMPLETED} ASC, ${COL_TODOS_CREATED_AT} DESC`);

    const resultSet: relationalStore.ResultSet = await this.store.query(predicates);
    const todos: TodoItem[] = [];
    while (resultSet.goToNextRow()) {
      todos.push(this.rowToTodoItem(resultSet));
    }
    resultSet.close();
    return todos;
  }

  async getById(id: ID): Promise<TodoItem | null> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_TODOS);
    predicates.equalTo(COL_TODOS_ID, id);

    const resultSet: relationalStore.ResultSet = await this.store.query(predicates);
    let todo: TodoItem | null = null;
    if (resultSet.goToFirstRow()) {
      todo = this.rowToTodoItem(resultSet);
    }
    resultSet.close();
    return todo;
  }

  async insert(todo: TodoItem): Promise<void> {
    const valueBucket: relationalStore.ValuesBucket = this.todoToValuesBucket(todo);
    await this.store.insert(TABLE_TODOS, valueBucket);
    // Force WAL checkpoint so the write reaches disk immediately —
    // without this, a process kill before the next auto-checkpoint
    // can lose data that was "successfully" inserted.
    try {
      await this.store.executeSql('PRAGMA wal_checkpoint(FULL)');
    } catch (_e) {
      // PRAGMA may not be supported in all RDB implementations — ignore
    }
  }

  async update(todo: TodoItem): Promise<void> {
    const valueBucket: relationalStore.ValuesBucket = this.todoToValuesBucket(todo);
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_TODOS);
    predicates.equalTo(COL_TODOS_ID, todo.id);
    await this.store.update(valueBucket, predicates);
  }

  async delete(id: ID): Promise<void> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_TODOS);
    predicates.equalTo(COL_TODOS_ID, id);
    await this.store.delete(predicates);
  }

  async deleteByCategoryId(categoryId: ID): Promise<void> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_TODOS);
    predicates.equalTo(COL_TODOS_CATEGORY_ID, categoryId);
    await this.store.delete(predicates);
  }

  // ── Categories ──

  async getAllCategories(): Promise<TodoCategory[]> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_TODO_CATEGORIES);
    predicates.orderByAsc(COL_TODO_CAT_SORT_ORDER + ' ASC');

    const resultSet: relationalStore.ResultSet = await this.store.query(predicates);
    const categories: TodoCategory[] = [];
    while (resultSet.goToNextRow()) {
      categories.push(this.rowToCategory(resultSet));
    }
    resultSet.close();
    return categories;
  }

  async getCategoryById(id: ID): Promise<TodoCategory | null> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_TODO_CATEGORIES);
    predicates.equalTo(COL_TODO_CAT_ID, id);

    const resultSet: relationalStore.ResultSet = await this.store.query(predicates);
    let category: TodoCategory | null = null;
    if (resultSet.goToFirstRow()) {
      category = this.rowToCategory(resultSet);
    }
    resultSet.close();
    return category;
  }

  async insertCategory(category: TodoCategory): Promise<void> {
    const valueBucket: relationalStore.ValuesBucket = this.categoryToValuesBucket(category);
    await this.store.insert(TABLE_TODO_CATEGORIES, valueBucket);
  }

  async updateCategory(category: TodoCategory): Promise<void> {
    const valueBucket: relationalStore.ValuesBucket = this.categoryToValuesBucket(category);
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_TODO_CATEGORIES);
    predicates.equalTo(COL_TODO_CAT_ID, category.id);
    await this.store.update(valueBucket, predicates);
  }

  async deleteCategory(id: ID): Promise<void> {
    await this.deleteByCategoryId(id);
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_TODO_CATEGORIES);
    predicates.equalTo(COL_TODO_CAT_ID, id);
    await this.store.delete(predicates);
  }

  // ── Row Mappers ──

  private rowToTodoItem(resultSet: relationalStore.ResultSet): TodoItem {
    return {
      id: resultSet.getString(resultSet.getColumnIndex(COL_TODOS_ID)),
      title: resultSet.getString(resultSet.getColumnIndex(COL_TODOS_TITLE)),
      description: resultSet.getString(resultSet.getColumnIndex(COL_TODOS_DESCRIPTION)),
      isCompleted: resultSet.getLong(resultSet.getColumnIndex(COL_TODOS_IS_COMPLETED)) === 1,
      priority: resultSet.getLong(resultSet.getColumnIndex(COL_TODOS_PRIORITY)),
      categoryId: resultSet.getString(resultSet.getColumnIndex(COL_TODOS_CATEGORY_ID)),
      reminderTime: resultSet.getLong(resultSet.getColumnIndex(COL_TODOS_REMINDER_TIME)),
      reminderRepeatType: resultSet.getLong(resultSet.getColumnIndex(COL_TODOS_REMINDER_REPEAT_TYPE)),
      createdAt: resultSet.getLong(resultSet.getColumnIndex(COL_TODOS_CREATED_AT)),
      dueDate: resultSet.getLong(resultSet.getColumnIndex(COL_TODOS_DUE_DATE)),
      completedAt: resultSet.getLong(resultSet.getColumnIndex(COL_TODOS_COMPLETED_AT)),
    };
  }

  private todoToValuesBucket(todo: TodoItem): relationalStore.ValuesBucket {
    const bucket: relationalStore.ValuesBucket = {};
    bucket[COL_TODOS_ID] = todo.id;
    bucket[COL_TODOS_TITLE] = todo.title;
    bucket[COL_TODOS_DESCRIPTION] = todo.description;
    bucket[COL_TODOS_IS_COMPLETED] = todo.isCompleted ? 1 : 0;
    bucket[COL_TODOS_PRIORITY] = todo.priority;
    bucket[COL_TODOS_CATEGORY_ID] = todo.categoryId;
    bucket[COL_TODOS_REMINDER_TIME] = todo.reminderTime;
    bucket[COL_TODOS_REMINDER_REPEAT_TYPE] = todo.reminderRepeatType;
    bucket[COL_TODOS_CREATED_AT] = todo.createdAt;
    bucket[COL_TODOS_DUE_DATE] = todo.dueDate;
    bucket[COL_TODOS_COMPLETED_AT] = todo.completedAt;
    return bucket;
  }

  private rowToCategory(resultSet: relationalStore.ResultSet): TodoCategory {
    return {
      id: resultSet.getString(resultSet.getColumnIndex(COL_TODO_CAT_ID)),
      name: resultSet.getString(resultSet.getColumnIndex(COL_TODO_CAT_NAME)),
      colorHex: resultSet.getString(resultSet.getColumnIndex(COL_TODO_CAT_COLOR_HEX)),
      sortOrder: resultSet.getLong(resultSet.getColumnIndex(COL_TODO_CAT_SORT_ORDER)),
    };
  }

  private categoryToValuesBucket(category: TodoCategory): relationalStore.ValuesBucket {
    const bucket: relationalStore.ValuesBucket = {};
    bucket[COL_TODO_CAT_ID] = category.id;
    bucket[COL_TODO_CAT_NAME] = category.name;
    bucket[COL_TODO_CAT_COLOR_HEX] = category.colorHex;
    bucket[COL_TODO_CAT_SORT_ORDER] = category.sortOrder;
    return bucket;
  }
}
