import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppConstants } from '../constants/AppConstants';
import {
  ALL_CREATE_TABLE_SQL,
  TABLE_NOTES,
  COL_NOTES_CATEGORY_ID,
} from '../constants/DatabaseConstants';

const DOMAIN: number = 0x0001;
const TAG: string = 'DatabaseHelper';

/**
 * Singleton database helper for initializing and providing RDB store access.
 * Must be initialized from EntryAbility with the application context.
 */
export class DatabaseHelper {
  private static instance: DatabaseHelper | null = null;
  private store: relationalStore.RdbStore | null = null;
  private isInitialized: boolean = false;
  private initPromise: Promise<void> | null = null;

  static getInstance(): DatabaseHelper {
    if (DatabaseHelper.instance === null) {
      DatabaseHelper.instance = new DatabaseHelper();
    }
    return DatabaseHelper.instance;
  }

  /**
   * Initialize the database. Call once from EntryAbility.
   */
  async initialize(context: common.Context): Promise<void> {
    if (this.isInitialized) {
      return;
    }
    if (this.initPromise !== null) {
      return await this.initPromise;
    }

    this.initPromise = this.doInitialize(context);
    try {
      await this.initPromise;
    } finally {
      this.initPromise = null;
    }
  }

  private async doInitialize(context: common.Context): Promise<void> {
    const config: relationalStore.StoreConfig = {
      name: AppConstants.DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1,
    };

    try {
      this.store = await relationalStore.getRdbStore(context, config);
      await this.createTables();
      this.isInitialized = true;
      hilog.info(DOMAIN, TAG, 'Database initialized successfully');
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'Failed to initialize database: %{public}d, %{public}s', e.code, e.message);
    }
  }

  private async createTables(): Promise<void> {
    if (this.store === null) {
      return;
    }
    for (const sql of ALL_CREATE_TABLE_SQL) {
      try {
        await this.store.executeSql(sql);
      } catch (err) {
        const e: BusinessError = err as BusinessError;
        hilog.error(DOMAIN, TAG, 'Failed to create table: %{public}s', e.message);
      }
    }
    // Run migrations for schema upgrades on existing databases
    await this.migrateDatabase();
  }

  /**
   * Adds columns that may be missing from older versions of the database.
   * Uses ALTER TABLE ADD COLUMN with IF NOT EXISTS-style error tolerance —
   * if the column already exists the error is logged and ignored.
   */
  private async migrateDatabase(): Promise<void> {
    if (this.store === null) {
      return;
    }

    const migrations: Array<[string, string]> = [
      // [table, migration SQL]
      [TABLE_NOTES, `ALTER TABLE ${TABLE_NOTES} ADD COLUMN ${COL_NOTES_CATEGORY_ID} TEXT NOT NULL DEFAULT '未分类'`],
    ];

    for (const migration of migrations) {
      const tableName: string = migration[0];
      const sql: string = migration[1];
      try {
        await this.store.executeSql(sql);
        hilog.info(DOMAIN, TAG, `Migration applied to table %{public}s`, tableName);
      } catch (err) {
        // Column may already exist — this is expected for new installs
        const e: BusinessError = err as BusinessError;
        hilog.warn(DOMAIN, TAG, `Migration skipped for table %{public}s: %{public}s`, tableName, e.message);
      }
    }
  }

  /**
   * Returns the RdbStore instance. Throws if not initialized.
   */
  getStore(): relationalStore.RdbStore {
    if (this.store === null) {
      throw new Error('Database not initialized. Call DatabaseHelper.initialize() first.');
    }
    return this.store;
  }

  /**
   * Returns true if the database has been initialized.
   */
  get initialized(): boolean {
    return this.isInitialized;
  }
}
