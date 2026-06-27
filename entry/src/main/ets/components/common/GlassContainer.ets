import { ThemeConfig } from '../../model/ThemeConfigModel';
import { MaterialConstants } from '../../constants/MaterialConstants';

/**
 * Immersive surface container with system material depth.
 *
 * @param borderRadius - Corner radius (defaults to themeConfig.borderRadius)
 * @param padding - Inner padding (default 16)
 * @param elevation - Depth level: 1=low(REGULAR), 2=mid(THICK), 3=high(ULTRA_THICK)
 * @param content - BuilderParam slot for child content
 */
@Component
export struct GlassContainer {
  @Consume('themeConfig') themeConfig: ThemeConfig;
  @Prop borderRadius: number = -1;
  @Prop padding: number = 16;
  @Prop elevation: number = 1;
  @BuilderParam content: () => void = this.defaultContent;

  @Builder
  defaultContent() {
  }

  build() {
    Column() {
      this.content();
    }
    .padding(this.padding)
    .borderRadius(this.effectiveRadius)
    .backdropBlur(MaterialConstants.getBlur(this.getMaterialStyle()))
    .backgroundColor(MaterialConstants.getOverlayColor(
      this.getMaterialStyle(), this.themeConfig.isDarkMode
    ));
  }

  private get effectiveRadius(): number {
    return this.borderRadius > 0 ? this.borderRadius : this.themeConfig.borderRadius;
  }

  private getMaterialStyle(): number {
    if (this.elevation >= 3) {
      return MaterialConstants.CONTAINER_HIGH;
    }
    if (this.elevation >= 2) {
      return MaterialConstants.CONTAINER_MID;
    }
    return MaterialConstants.CONTAINER_LOW;
  }
}
