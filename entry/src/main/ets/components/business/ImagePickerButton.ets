import { picker } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { ThemeConfig } from '../../model/ThemeConfigModel';
import { ICON } from '../../utils/IconGlyphs';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0003;
const TAG: string = 'ImagePickerButton';

/**
 * Button for selecting a custom background image from the device gallery.
 */
@Component
export struct ImagePickerButton {
  @Consume('themeConfig') themeConfig: ThemeConfig;
  @Prop currentImageUri: string = '';
  onImagePicked: (uri: string) => void = (_uri: string) => {
  };
  onImageRemoved: () => void = () => {
  };

  build() {
    Row() {
      if (this.currentImageUri !== '') {
        // Show current background thumbnail
        Image(this.currentImageUri)
          .width(60)
          .height(60)
          .borderRadius(12)
          .objectFit(ImageFit.Cover)
          .margin({ right: 16 });
      } else {
        // Placeholder
        Column()
          .width(60)
          .height(60)
          .borderRadius(12)
          .backgroundColor(
            this.themeConfig.isDarkMode
              ? 'rgba(255, 255, 255, 0.08)'
              : 'rgba(0, 0, 0, 0.06)'
          )
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .margin({ right: 16 });

        Text(ICON.IMAGE)
          .fontSize(28)
          .fontColor(this.themeConfig.textSecondaryColor)
          .position({ x: 16, y: 16 });
      }

      Column() {
        Text(this.currentImageUri !== '' ? '更换背景图片' : '选择背景图片')
          .fontSize(15 * this.themeConfig.fontScale)
          .fontColor(this.themeConfig.textColor);

        if (this.currentImageUri !== '') {
          Text('点击移除自定义背景')
            .fontSize(12 * this.themeConfig.fontScale)
            .fontColor(this.themeConfig.textSecondaryColor)
            .margin({ top: 4 });
        }
      }
      .layoutWeight(1);
    }
    .padding(16)
    .borderRadius(this.themeConfig.borderRadius)
    .backgroundColor(
      this.themeConfig.isDarkMode
        ? 'rgba(255, 255, 255, 0.06)'
        : this.themeConfig.surfaceColor
    )
    .borderWidth(1)
    .borderColor(
      this.themeConfig.isDarkMode
        ? 'rgba(255, 255, 255, 0.08)'
        : 'rgba(255, 255, 255, 0.2)'
    )
    .onClick(() => {
      if (this.currentImageUri !== '') {
        this.onImageRemoved();
      } else {
        this.openImagePicker();
      }
    });
  }

  private openImagePicker(): void {
    try {
      const documentSelectOptions: picker.DocumentSelectOptions = new picker.DocumentSelectOptions();
      documentSelectOptions.maxSelectNumber = 1;
      documentSelectOptions.defaultFilePathUri = '';
      documentSelectOptions.fileSuffixFilters = ['.jpg', '.jpeg', '.png', '.webp', '.bmp'];

      const documentViewPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker();
      documentViewPicker.select(documentSelectOptions).then((documentSelectResult: string[]) => {
        if (documentSelectResult.length > 0) {
          const uri: string = documentSelectResult[0];
          hilog.info(DOMAIN, TAG, 'Image selected: %{public}s', uri);
          this.onImagePicked(uri);
        }
      }).catch((err: BusinessError) => {
        hilog.error(DOMAIN, TAG, 'Document picker failed: %{public}s', err.message);
      });
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'Failed to open image picker: %{public}s', e.message);
    }
  }
}
