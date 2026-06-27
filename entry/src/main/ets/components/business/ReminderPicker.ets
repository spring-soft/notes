import { ThemeConfig } from '../../model/ThemeConfigModel';
import { MaterialConstants } from '../../constants/MaterialConstants';
import { Timestamp } from '../../model/AppConstantsModel';
import { RepeatType } from '../../model/ReminderModel';

/**
 * Date and time picker for setting todo reminder times.
 */
@Component
export struct ReminderPicker {
  @Consume('themeConfig') themeConfig: ThemeConfig;
  @Prop reminderTime: Timestamp = 0;
  @Prop repeatType: RepeatType = RepeatType.NONE;
  @Prop enabled: boolean = false;
  onTimeChange: (timestamp: Timestamp) => void = (_t: Timestamp) => {
  };
  onRepeatChange: (repeat: RepeatType) => void = (_r: RepeatType) => {
  };
  onToggle: (enabled: boolean) => void = (_e: boolean) => {
  };

  @State selectedDate: Date = new Date();

  aboutToAppear(): void {
    if (this.reminderTime > 0) {
      this.selectedDate = new Date(this.reminderTime);
    } else {
      this.selectedDate = new Date(Date.now() + 3600000); // Default: 1 hour from now
    }
  }

  build() {
    Column() {
      // Enable/disable toggle
      Row() {
        Text('设置提醒')
          .fontSize(15 * this.themeConfig.fontScale)
          .fontColor(this.themeConfig.textColor);

        Blank();

        Toggle({ type: ToggleType.Switch, isOn: this.enabled })
          .selectedColor(this.themeConfig.primaryColor)
          .onChange((isOn: boolean) => {
            this.onToggle(isOn);
          });
      }
      .width('100%')
      .margin({ bottom: this.enabled ? 16 : 0 });

      if (this.enabled) {
        // Date picker
        DatePicker({
          start: new Date(Date.now()),
          end: new Date(Date.now() + 365 * 24 * 3600 * 1000), // 1 year
          selected: this.selectedDate,
        })
          .onChange((value: DatePickerResult) => {
            this.selectedDate = new Date(value.year!, value.month!, value.day!);
            this.onTimeChange(this.selectedDate.getTime());
          })
          .margin({ bottom: 12 });

        // Time picker
        TimePicker({
          selected: this.selectedDate,
        })
          .onChange((value: TimePickerResult) => {
            this.selectedDate.setHours(value.hour!, value.minute!);
            this.onTimeChange(this.selectedDate.getTime());
          })
          .margin({ bottom: 16 });

        // Repeat type selector
        Text('重复')
          .fontSize(14 * this.themeConfig.fontScale)
          .fontColor(this.themeConfig.textSecondaryColor)
          .margin({ bottom: 8 });

        Row() {
          this.repeatChip(RepeatType.NONE, '不重复');
          this.repeatChip(RepeatType.DAILY, '每天');
          this.repeatChip(RepeatType.WEEKLY, '每周');
          this.repeatChip(RepeatType.MONTHLY, '每月');
        };
      }
    }
  }

  @Builder
  repeatChip(type: RepeatType, label: string) {
    Text(label)
      .fontSize(13)
      .fontColor(this.repeatType === type ? '#FFFFFF' : this.themeConfig.textColor)
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .borderRadius(16)
      .backgroundColor(
        this.repeatType === type
          ? this.themeConfig.primaryColor
          : Color.Transparent
      )
      .backdropBlur(
          this.repeatType === type
            ? 0
            : MaterialConstants.getBlur(MaterialConstants.CHIP)
        )
      .margin({ right: 8 })
      .onClick(() => {
        this.onRepeatChange(type);
      });
  }
}
