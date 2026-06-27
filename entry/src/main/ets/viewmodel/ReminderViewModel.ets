import { ID, Timestamp } from '../model/AppConstantsModel';
import { RepeatType } from '../model/ReminderModel';
import { ReminderService } from '../service/ReminderService';

/**
 * ViewModel for managing todo reminders.
 * Bridges between TodoViewModel and the ReminderService.
 */
@Observed
export class ReminderViewModel {
  private reminderService: ReminderService;

  constructor(reminderService: ReminderService) {
    this.reminderService = reminderService;
  }

  /**
   * Schedules a reminder for a todo item.
   */
  async scheduleReminder(
    todoId: ID,
    title: string,
    reminderTime: Timestamp,
    repeatType: RepeatType
  ): Promise<number> {
    return this.reminderService.createTodoReminder(todoId, title, reminderTime, repeatType);
  }

  /**
   * Cancels a reminder.
   */
  async cancelReminder(reminderId: number): Promise<void> {
    await this.reminderService.cancelReminder(reminderId);
  }

  /**
   * Cancels all reminders.
   */
  async cancelAllReminders(): Promise<void> {
    await this.reminderService.cancelAllReminders();
  }
}
