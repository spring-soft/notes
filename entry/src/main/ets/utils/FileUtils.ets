import { fileIo } from '@kit.CoreFileKit';
import { Bytes, FilePath } from '../model/AppConstantsModel';

/**
 * Checks if a file exists.
 */
export function fileExists(filePath: FilePath): boolean {
  return fileIo.accessSync(filePath);
}

/**
 * Gets the file size in bytes.
 */
export function getFileSize(filePath: FilePath): Bytes {
  try {
    const stat: fileIo.Stat = fileIo.statSync(filePath);
    return stat.size;
  } catch (_e) {
    return 0;
  }
}

/**
 * Deletes a file if it exists.
 */
export function deleteFile(filePath: FilePath): boolean {
  try {
    if (fileIo.accessSync(filePath)) {
      fileIo.unlinkSync(filePath);
      return true;
    }
    return false;
  } catch (_e) {
    return false;
  }
}

/**
 * Formats bytes to a human-readable string.
 */
export function formatFileSize(bytes: Bytes): string {
  if (bytes < 1024) {
    return `${bytes} B`;
  }
  if (bytes < 1024 * 1024) {
    return `${(bytes / 1024).toFixed(1)} KB`;
  }
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}
