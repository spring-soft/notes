import { ID } from '../model/AppConstantsModel';

/**
 * Generates a UUID v4 string for use as entity IDs.
 */
export function generateId(): ID {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c: string): string => {
    const r: number = Math.floor(Math.random() * 16);
    const v: number = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

/**
 * Generates a short unique ID (8 hex characters).
 */
export function generateShortId(): ID {
  return Math.floor(Math.random() * 0xFFFFFFFF).toString(16).padStart(8, '0');
}
