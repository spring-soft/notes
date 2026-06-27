import photoAccessHelper from '@ohos.file.photoAccessHelper';
import { common } from '@kit.AbilityKit';
import { ThemeConfig, DEFAULT_THEME_CONFIG } from '../../model/ThemeConfigModel';
import { MaterialConstants } from '../../constants/MaterialConstants';
import { ICON } from '../../utils/IconGlyphs';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0003;
const TAG: string = 'ImagePickerButton';

/**
 * Button for selecting a custom background image from the device photo gallery.
 * Uses photoAccessHelper.PhotoViewPicker — the HarmonyOS-recommended
 * photo picker — so the returned URI is directly usable by Image().
 */
@ComponentV2
export struct ImagePickerButton {
  @Consumer('themeConfig') themeConfig: ThemeConfig = DEFAULT_THEME_CONFIG;
  @Param currentImageUri: string = '';
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

        SymbolGlyph(ICON.IMAGE)
          .fontSize(28)
          .fontColor([this.themeConfig.textSecondaryColor])
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
    .backdropBlur(MaterialConstants.getBlur(MaterialConstants.SURFACE))
    .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.SURFACE, this.themeConfig.isDarkMode))
    .onClick(() => {
      if (this.currentImageUri !== '') {
        this.onImageRemoved();
      } else {
        this.openPhotoPicker();
      }
    });
  }

  private openPhotoPicker(): void {
    try {
      const photoPicker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
      const options: photoAccessHelper.PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      options.maxSelectNumber = 1;

      photoPicker.select(options).then((result: photoAccessHelper.PhotoSelectResult) => {
        if (result.photoUris.length > 0) {
          const uri: string = result.photoUris[0];
          hilog.info(DOMAIN, TAG, 'Photo selected: %{public}s', uri);
          this.onImagePicked(uri);
        }
      }).catch((err: BusinessError) => {
        hilog.error(DOMAIN, TAG, 'Photo picker failed: %{public}s', err.message);
      });
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'Failed to open photo picker: %{public}s', e.message);
    }
  }
}
