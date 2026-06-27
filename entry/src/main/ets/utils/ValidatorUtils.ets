/**
 * Input validation utilities.
 */

/**
 * Checks if a string is empty or only whitespace.
 */
export function isEmpty(value: string): boolean {
  return value.trim().length === 0;
}

/**
 * Checks if a string exceeds the maximum length.
 */
export function exceedsMaxLength(value: string, maxLength: number): boolean {
  return value.length > maxLength;
}

/**
 * Validates a note title.
 */
export function validateNoteTitle(title: string): string {
  if (isEmpty(title)) {
    return '标题不能为空';
  }
  return '';
}

/**
 * Validates a todo title.
 */
export function validateTodoTitle(title: string): string {
  if (isEmpty(title)) {
    return '待办事项不能为空';
  }
  return '';
}

/**
 * Validates a category name.
 */
export function validateCategoryName(name: string): string {
  if (isEmpty(name)) {
    return '分类名称不能为空';
  }
  return '';
}

