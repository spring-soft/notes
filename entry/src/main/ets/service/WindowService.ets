import { window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0002;
const TAG: string = 'WindowService';

/**
 * Configures the window for full-screen immersive display.
 */
export function configureFullScreen(windowStage: window.WindowStage): void {
  try {
    const windowClass: window.Window = windowStage.getMainWindowSync();
    windowClass.setWindowLayoutFullScreen(true);
    windowClass.setWindowSystemBarProperties({
      statusBarColor: '#00FFFFFF',
      navigationBarColor: '#00FFFFFF',
      isStatusBarLightIcon: false,
      isNavigationBarLightIcon: false,
    });
    hilog.info(DOMAIN, TAG, 'Full-screen immersive window configured');
  } catch (err) {
    const e: BusinessError = err as BusinessError;
    hilog.error(DOMAIN, TAG, 'Failed to configure full-screen window: %{public}s', e.message);
  }
}

/**
 * Updates the status bar icon color based on dark mode.
 * Must be called from a component context that can provide getContext().
 */
export async function updateSystemBarStyle(isDarkMode: boolean, context: common.Context): Promise<void> {
  try {
    const windowClass: window.Window = await window.getLastWindow(context);
    windowClass.setWindowSystemBarProperties({
      isStatusBarLightIcon: isDarkMode,
      isNavigationBarLightIcon: isDarkMode,
    });
  } catch (err) {
    const e: BusinessError = err as BusinessError;
    hilog.error(DOMAIN, TAG, 'Failed to update system bar style: %{public}s', e.message);
  }
}
