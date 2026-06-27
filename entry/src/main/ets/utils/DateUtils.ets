import { Timestamp, Seconds } from '../model/AppConstantsModel';

/**
 * Returns the current timestamp in milliseconds.
 */
export function now(): Timestamp {
  return Date.now();
}

/**
 * Formats a timestamp as "HH:MM" string.
 */
export function formatTime(timestamp: Timestamp): string {
  const date: Date = new Date(timestamp);
  const hours: string = date.getHours().toString().padStart(2, '0');
  const minutes: string = date.getMinutes().toString().padStart(2, '0');
  return `${hours}:${minutes}`;
}

/**
 * Formats a timestamp as "YYYY-MM-DD" string.
 */
export function formatDate(timestamp: Timestamp): string {
  const date: Date = new Date(timestamp);
  const year: number = date.getFullYear();
  const month: string = (date.getMonth() + 1).toString().padStart(2, '0');
  const day: string = date.getDate().toString().padStart(2, '0');
  return `${year}-${month}-${day}`;
}

/**
 * Formats a timestamp as "YYYY-MM-DD HH:MM" string.
 */
export function formatDateTime(timestamp: Timestamp): string {
  return `${formatDate(timestamp)} ${formatTime(timestamp)}`;
}

/**
 * Formats a relative time string (e.g., "刚刚", "5分钟前", "昨天").
 */
export function formatRelativeTime(timestamp: Timestamp): string {
  const diffMs: number = now() - timestamp;
  const diffSeconds: number = Math.floor(diffMs / 1000);

  if (diffSeconds < 60) {
    return '刚刚';
  }
  if (diffSeconds < 3600) {
    return `${Math.floor(diffSeconds / 60)}分钟前`;
  }
  if (diffSeconds < 86400) {
    return `${Math.floor(diffSeconds / 3600)}小时前`;
  }
  if (diffSeconds < 172800) {
    return '昨天';
  }
  if (diffSeconds < 604800) {
    return `${Math.floor(diffSeconds / 86400)}天前`;
  }
  return formatDate(timestamp);
}

/**
 * Formats seconds duration to "MM:SS" string.
 */
export function formatDuration(seconds: Seconds): string {
  const mins: number = Math.floor(Math.max(0, seconds) / 60);
  const secs: number = Math.floor(Math.max(0, seconds) % 60);
  return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
}

/**
 * Returns the start of today (00:00:00.000) as a timestamp.
 */
export function startOfToday(): Timestamp {
  const d: Date = new Date();
  d.setHours(0, 0, 0, 0);
  return d.getTime();
}

/**
 * Returns the end of today (23:59:59.999) as a timestamp.
 */
export function endOfToday(): Timestamp {
  const d: Date = new Date();
  d.setHours(23, 59, 59, 999);
  return d.getTime();
}

/**
 * Returns a short date label relative to today.
 */
export function formatDateLabel(timestamp: Timestamp): string {
  const todayStart: Timestamp = startOfToday();
  const tomorrowStart: Timestamp = todayStart + 86400000;
  const yesterdayStart: Timestamp = todayStart - 86400000;

  if (timestamp >= todayStart && timestamp < tomorrowStart) {
    return '今天';
  }
  if (timestamp >= tomorrowStart && timestamp < tomorrowStart + 86400000) {
    return '明天';
  }
  if (timestamp >= yesterdayStart && timestamp < todayStart) {
    return '昨天';
  }
  return formatDate(timestamp);
}
