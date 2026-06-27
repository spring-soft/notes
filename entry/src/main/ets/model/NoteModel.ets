import { ID, Timestamp, ColorHex } from './AppConstantsModel';

export interface Note {
  id: ID;
  title: string;
  content: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  colorTag: ColorHex;
  isPinned: boolean;
  categoryId: string;
}

export enum NoteSortOrder {
  UPDATED_DESC = 0,
  UPDATED_ASC = 1,
  TITLE_ASC = 2,
}

/** Default note categories available to the user. */
export const NOTE_CATEGORIES: string[] = ['未分类', '工作', '个人', '学习', '生活', '其他'];
