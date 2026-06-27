import { ThemeConfig } from '../../model/ThemeConfigModel';
import { MaterialConstants } from '../../constants/MaterialConstants';
import { PomodoroState } from '../../model/PomodoroSessionModel';
import { ICON } from '../../utils/IconGlyphs';

/**
 * Control buttons for the pomodoro timer: start/pause, reset, skip.
 * Press deformation is provided by systemMaterial interactive:true.
 */
@Component
export struct PomodoroControls {
  @Consume('themeConfig') themeConfig: ThemeConfig;
  @Prop currentState: PomodoroState = PomodoroState.IDLE;
  @Prop isRunning: boolean = false;
  @Prop stateSignal: number = 0;
  onStartPause: () => void = () => {
  };
  onReset: () => void = () => {
  };
  onSkip: () => void = () => {
  };

  build() {
    Row() {
      // Reset button
      Button() {
        SymbolGlyph(ICON.RESET)
          .fontSize(22)
          .fontColor([this.themeConfig.primaryColor]);
      }
      .width(56)
      .height(56)
      .borderRadius(28)
      .backdropBlur(MaterialConstants.getBlur(MaterialConstants.SURFACE))
    .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.SURFACE, this.themeConfig.isDarkMode))
      .onClick(() => {
        this.onReset();
      });

      Blank().width(24);

      // Start / Pause button (larger, primary) — icon uses primaryColor for contrast
      Button() {
        SymbolGlyph(this.isRunning ? ICON.PAUSE_BARS : ICON.PLAY)
          .fontSize(28)
          .fontColor([this.themeConfig.primaryColor]);
      }
      .width(72)
      .height(72)
      .borderRadius(36)
      .backdropBlur(MaterialConstants.getBlur(MaterialConstants.FAB))
    .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.FAB, this.themeConfig.isDarkMode))
      .onClick(() => {
        this.onStartPause();
      });

      Blank().width(24);

      // Skip button
      Button() {
        SymbolGlyph(ICON.SKIP)
          .fontSize(22)
          .fontColor([this.themeConfig.primaryColor]);
      }
      .width(56)
      .height(56)
      .borderRadius(28)
      .backdropBlur(MaterialConstants.getBlur(MaterialConstants.SURFACE))
    .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.SURFACE, this.themeConfig.isDarkMode))
      .onClick(() => {
        this.onSkip();
      });
    }
    .justifyContent(FlexAlign.Center);
  }
}
