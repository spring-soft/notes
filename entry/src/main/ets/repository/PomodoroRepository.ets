import { relationalStore } from '@kit.ArkData';
import { PomodoroSession } from '../model/PomodoroSessionModel';
import { ID, Timestamp } from '../model/AppConstantsModel';
import {
  TABLE_POMODORO_SESSIONS,
  COL_POM_ID,
  COL_POM_START_TIME,
  COL_POM_END_TIME,
  COL_POM_TYPE,
  COL_POM_DURATION,
  COL_POM_IS_COMPLETED,
  COL_POM_ABANDONED_AT,
} from '../constants/DatabaseConstants';

export class PomodoroRepository {
  private store: relationalStore.RdbStore;

  constructor(store: relationalStore.RdbStore) {
    this.store = store;
  }

  async getSessionsInRange(startTime: Timestamp, endTime: Timestamp): Promise<PomodoroSession[]> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_POMODORO_SESSIONS);
    predicates.between(COL_POM_START_TIME, startTime, endTime);
    predicates.orderByAsc(COL_POM_START_TIME + ' DESC');

    const resultSet: relationalStore.ResultSet = await this.store.query(predicates);
    const sessions: PomodoroSession[] = [];
    while (resultSet.goToNextRow()) {
      sessions.push(this.rowToSession(resultSet));
    }
    resultSet.close();
    return sessions;
  }

  async getTodaySessions(): Promise<PomodoroSession[]> {
    const now: Date = new Date();
    const todayStart: Timestamp = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
    const todayEnd: Timestamp = todayStart + 24 * 60 * 60 * 1000 - 1;
    return this.getSessionsInRange(todayStart, todayEnd);
  }

  async getById(id: ID): Promise<PomodoroSession | null> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_POMODORO_SESSIONS);
    predicates.equalTo(COL_POM_ID, id);

    const resultSet: relationalStore.ResultSet = await this.store.query(predicates);
    let session: PomodoroSession | null = null;
    if (resultSet.goToFirstRow()) {
      session = this.rowToSession(resultSet);
    }
    resultSet.close();
    return session;
  }

  async insert(session: PomodoroSession): Promise<void> {
    const valueBucket: relationalStore.ValuesBucket = this.sessionToValuesBucket(session);
    await this.store.insert(TABLE_POMODORO_SESSIONS, valueBucket);
  }

  async update(session: PomodoroSession): Promise<void> {
    const valueBucket: relationalStore.ValuesBucket = this.sessionToValuesBucket(session);
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TABLE_POMODORO_SESSIONS);
    predicates.equalTo(COL_POM_ID, session.id);
    await this.store.update(valueBucket, predicates);
  }

  async getCompletedCountToday(): Promise<number> {
    const todaySessions: PomodoroSession[] = await this.getTodaySessions();
    let count: number = 0;
    for (const session of todaySessions) {
      if (session.isCompleted) {
        count++;
      }
    }
    return count;
  }

  async getTotalFocusMinutesToday(): Promise<number> {
    const todaySessions: PomodoroSession[] = await this.getTodaySessions();
    let totalSeconds: number = 0;
    for (const session of todaySessions) {
      if (session.isCompleted) {
        totalSeconds += session.duration;
      }
    }
    return Math.floor(totalSeconds / 60);
  }

  private rowToSession(resultSet: relationalStore.ResultSet): PomodoroSession {
    return {
      id: resultSet.getString(resultSet.getColumnIndex(COL_POM_ID)),
      startTime: resultSet.getLong(resultSet.getColumnIndex(COL_POM_START_TIME)),
      endTime: resultSet.getLong(resultSet.getColumnIndex(COL_POM_END_TIME)),
      type: resultSet.getLong(resultSet.getColumnIndex(COL_POM_TYPE)),
      duration: resultSet.getLong(resultSet.getColumnIndex(COL_POM_DURATION)),
      isCompleted: resultSet.getLong(resultSet.getColumnIndex(COL_POM_IS_COMPLETED)) === 1,
      abandonedAt: resultSet.getLong(resultSet.getColumnIndex(COL_POM_ABANDONED_AT)),
    };
  }

  private sessionToValuesBucket(session: PomodoroSession): relationalStore.ValuesBucket {
    const bucket: relationalStore.ValuesBucket = {};
    bucket[COL_POM_ID] = session.id;
    bucket[COL_POM_START_TIME] = session.startTime;
    bucket[COL_POM_END_TIME] = session.endTime;
    bucket[COL_POM_TYPE] = session.type;
    bucket[COL_POM_DURATION] = session.duration;
    bucket[COL_POM_IS_COMPLETED] = session.isCompleted ? 1 : 0;
    bucket[COL_POM_ABANDONED_AT] = session.abandonedAt;
    return bucket;
  }
}
