import { TodoItem, TodoCategory, TodoPriority, TodoFilterType } from '../model/TodoModel';
import { ID, Timestamp } from '../model/AppConstantsModel';
import { RepeatType } from '../model/ReminderModel';
import { TodoRepository } from '../repository/TodoRepository';
import { generateId } from '../utils/IdGenerator';
import { now } from '../utils/DateUtils';

/**
 * ViewModel for the Todos feature.
 * Manages todo items, categories, filtering, and completion tracking.
 */
@ObservedV2
export class TodosViewModel {
  @Trace todos: TodoItem[] = [];
  @Trace categories: TodoCategory[] = [];
  @Trace filteredTodos: TodoItem[] = [];
  @Trace activeFilter: TodoFilterType = TodoFilterType.ALL;
  @Trace selectedCategoryId: string = '';
  @Trace isLoading: boolean = false;

  private repository: TodoRepository;

  constructor(repository: TodoRepository) {
    this.repository = repository;
  }

  /**
   * Loads todos and categories.
   */
  async loadData(): Promise<void> {
    this.isLoading = true;
    this.categories = await this.repository.getAllCategories();
    this.todos = await this.repository.getAll(this.activeFilter);
    this.applyFilters();
    this.isLoading = false;
  }

  /**
   * Gets todos grouped by category.
   */
  getTodosByCategory(): Map<string, TodoItem[]> {
    const grouped: Map<string, TodoItem[]> = new Map();

    // Add uncategorized first
    const uncategorized: TodoItem[] = [];
    for (const todo of this.filteredTodos) {
      let found: boolean = false;
      for (const cat of this.categories) {
        if (todo.categoryId === cat.id) {
          found = true;
          const existing: TodoItem[] | undefined = grouped.get(cat.id);
          if (existing !== undefined) {
            existing.push(todo);
          } else {
            grouped.set(cat.id, [todo]);
          }
          break;
        }
      }
      if (!found) {
        uncategorized.push(todo);
      }
    }

    if (uncategorized.length > 0) {
      grouped.set('__uncategorized__', uncategorized);
    }

    return grouped;
  }

  /**
   * Gets the active todo count (not completed).
   */
  getActiveCount(): number {
    let count: number = 0;
    for (const todo of this.todos) {
      if (!todo.isCompleted) {
        count++;
      }
    }
    return count;
  }

  /**
   * Gets the completed todo count.
   */
  getCompletedCount(): number {
    let count: number = 0;
    for (const todo of this.todos) {
      if (todo.isCompleted) {
        count++;
      }
    }
    return count;
  }

  /**
   * Creates a new todo item.
   */
  async createTodo(
    title: string,
    description: string,
    priority: TodoPriority,
    categoryId: ID,
    reminderTime: Timestamp,
    repeatType: RepeatType,
    dueDate: Timestamp
  ): Promise<TodoItem> {
    const todo: TodoItem = {
      id: generateId(),
      title: title,
      description: description,
      isCompleted: false,
      priority: priority,
      categoryId: categoryId,
      reminderTime: reminderTime,
      reminderRepeatType: repeatType,
      createdAt: now(),
      dueDate: dueDate,
      completedAt: 0,
    };
    await this.repository.insert(todo);
    // Update in-memory state immediately for responsive UI.
    // (DB reload via getAll() can return stale data if the WAL
    //  hasn't been flushed yet, causing the new todo to not appear.)
    const newTodosList: TodoItem[] = [todo];
    for (const t of this.todos) {
      newTodosList.push(t);
    }
    this.todos = newTodosList;
    this.applyFilters();
    return todo;
  }

  /**
   * Toggles the completion status of a todo.
   */
  async toggleComplete(id: ID): Promise<void> {
    const todo: TodoItem | undefined = this.findTodoById(id);
    if (todo === undefined) {
      return;
    }
    const updated: TodoItem = {
      id: todo.id,
      title: todo.title,
      description: todo.description,
      isCompleted: !todo.isCompleted,
      priority: todo.priority,
      categoryId: todo.categoryId,
      reminderTime: todo.reminderTime,
      reminderRepeatType: todo.reminderRepeatType,
      createdAt: todo.createdAt,
      dueDate: todo.dueDate,
      completedAt: !todo.isCompleted ? now() : 0,
    };
    await this.repository.update(updated);
    // Update in-memory immediately
    const newTodos: TodoItem[] = [];
    for (const t of this.todos) {
      if (t.id === id) {
        newTodos.push(updated);
      } else {
        newTodos.push(t);
      }
    }
    this.todos = newTodos;
    this.applyFilters();
  }

  /**
   * Updates a todo item.
   */
  async updateTodo(updatedTodo: TodoItem): Promise<void> {
    await this.repository.update(updatedTodo);
    // Update in-memory immediately
    const newTodos: TodoItem[] = [];
    for (const t of this.todos) {
      if (t.id === updatedTodo.id) {
        newTodos.push(updatedTodo);
      } else {
        newTodos.push(t);
      }
    }
    this.todos = newTodos;
    this.applyFilters();
  }

  /**
   * Deletes a todo item.
   */
  async deleteTodo(id: ID): Promise<void> {
    await this.repository.delete(id);
    // Update in-memory immediately
    const newTodos: TodoItem[] = [];
    for (const t of this.todos) {
      if (t.id !== id) {
        newTodos.push(t);
      }
    }
    this.todos = newTodos;
    this.applyFilters();
  }

  // ── Categories ──

  /**
   * Creates a new category.
   */
  async createCategory(name: string, colorHex: string): Promise<TodoCategory> {
    const maxOrder: number = this.getMaxCategoryOrder();
    const category: TodoCategory = {
      id: generateId(),
      name: name,
      colorHex: colorHex,
      sortOrder: maxOrder + 1,
    };
    await this.repository.insertCategory(category);
    // Update in-memory immediately
    const newCategories: TodoCategory[] = [];
    for (const c of this.categories) {
      newCategories.push(c);
    }
    newCategories.push(category);
    this.categories = newCategories;
    return category;
  }

  /**
   * Deletes a category and its todos.
   */
  async deleteCategory(id: ID): Promise<void> {
    await this.repository.deleteCategory(id);
    // Update in-memory immediately
    const catsAfter: TodoCategory[] = [];
    for (const c of this.categories) {
      if (c.id !== id) {
        catsAfter.push(c);
      }
    }
    this.categories = catsAfter;
    const todosAfter: TodoItem[] = [];
    for (const t of this.todos) {
      if (t.categoryId !== id) {
        todosAfter.push(t);
      }
    }
    this.todos = todosAfter;
    this.applyFilters();
  }

  /**
   * Sets the active filter type.
   */
  setFilter(filter: TodoFilterType): void {
    this.activeFilter = filter;
    this.applyFilters();
  }

  /**
   * Sets the selected category for filtering.
   */
  setSelectedCategory(categoryId: string): void {
    this.selectedCategoryId = categoryId;
    this.applyFilters();
  }

  /**
   * Finds a todo by ID.
   */
  findTodoById(id: ID): TodoItem | undefined {
    for (const todo of this.todos) {
      if (todo.id === id) {
        return todo;
      }
    }
    return undefined;
  }

  /**
   * Finds a category by name (case-insensitive).
   */
  findCategoryByName(name: string): TodoCategory | undefined {
    const normalized: string = name.trim().toLowerCase();
    for (const cat of this.categories) {
      if (cat.name.toLowerCase() === normalized) {
        return cat;
      }
    }
    return undefined;
  }

  /**
   * Gets an existing category by name or creates a new one.
   */
  async getOrCreateCategory(name: string, colorHex: string): Promise<TodoCategory> {
    const existing: TodoCategory | undefined = this.findCategoryByName(name);
    if (existing !== undefined) {
      return existing;
    }
    return await this.createCategory(name.trim(), colorHex);
  }

  /**
   * Finds a category by ID.
   */
  findCategoryById(id: ID): TodoCategory | undefined {
    for (const cat of this.categories) {
      if (cat.id === id) {
        return cat;
      }
    }
    return undefined;
  }

  private applyFilters(): void {
    let result: TodoItem[] = this.todos;

    // Status filter
    if (this.activeFilter === TodoFilterType.ACTIVE) {
      result = result.filter((t: TodoItem) => !t.isCompleted);
    } else if (this.activeFilter === TodoFilterType.COMPLETED) {
      result = result.filter((t: TodoItem) => t.isCompleted);
    }

    // Category filter
    if (this.selectedCategoryId !== '') {
      result = result.filter((t: TodoItem) => t.categoryId === this.selectedCategoryId);
    }

    this.filteredTodos = result;
  }

  private getMaxCategoryOrder(): number {
    let maxOrder: number = 0;
    for (const cat of this.categories) {
      if (cat.sortOrder > maxOrder) {
        maxOrder = cat.sortOrder;
      }
    }
    return maxOrder;
  }
}
