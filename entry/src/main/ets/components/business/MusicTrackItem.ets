import { Track, MusicSource } from '../../model/MusicModel';
import { ThemeConfig, DEFAULT_THEME_CONFIG } from '../../model/ThemeConfigModel';
import { MaterialConstants } from '../../constants/MaterialConstants';
import { ICON } from '../../utils/IconGlyphs';

/**
 * Single music track row with album art, title, artist, duration.
 * Pattern follows NoteCard.ets.
 */
@ComponentV2
export struct MusicTrackItem {
  @Consumer('themeConfig') themeConfig: ThemeConfig = DEFAULT_THEME_CONFIG;
  @Param track: Track = {
    id: '',
    title: '',
    artist: '',
    album: '',
    durationMs: 0,
    fileUri: '',
    albumArtUri: '',
    source: MusicSource.LOCAL,
    serverTrackId: '',
    dateAdded: 0,
  };
  @Param isPlaying: boolean = false;
  @Param index: number = 1;
  @Event onClick: () => void = () => {};
  @Event onMore: () => void = () => {};

  build() {
    Row() {
      // Index / now-playing indicator
      Column() {
        if (this.isPlaying) {
          SymbolGlyph(ICON.PLAY)
            .fontSize(13)
            .fontColor([this.themeConfig.primaryColor]);
        } else {
          Text(String(this.index))
            .fontSize(13)
            .fontColor(this.themeConfig.textSecondaryColor)
            .opacity(0.6);
        }
      }
      .width(32)
      .alignItems(HorizontalAlign.Center);

      // Album art thumbnail or placeholder
      if (this.track.albumArtUri !== '') {
        Image(this.track.albumArtUri)
          .width(44)
          .height(44)
          .borderRadius(6)
          .objectFit(ImageFit.Cover);
      } else {
        Column() {
          SymbolGlyph(ICON.MUSIC)
            .fontSize(20)
            .fontColor([this.themeConfig.textSecondaryColor]);
        }
        .width(44)
        .height(44)
        .borderRadius(6)
        .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.SURFACE, this.themeConfig.isDarkMode))
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center);
      }

      // Title + Artist
      Column() {
        Text(this.track.title !== '' ? this.track.title : '未知曲目')
          .fontSize(14 * this.themeConfig.fontScale)
          .fontColor(this.themeConfig.textColor)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });

        Text(this.track.artist !== '' ? this.track.artist : '未知艺术家')
          .fontSize(12 * this.themeConfig.fontScale)
          .fontColor(this.themeConfig.textSecondaryColor)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 2 });
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 });

      // Source badge
      if (this.track.source === MusicSource.NOVIDROME) {
        SymbolGlyph(ICON.STREAM)
          .fontSize(12)
          .fontColor([this.themeConfig.primaryColor]);
        Blank().width(6);
      }

      // Duration
      Text(this.formatDuration(this.track.durationMs))
        .fontSize(12 * this.themeConfig.fontScale)
        .fontColor(this.themeConfig.textSecondaryColor)
        .opacity(0.7)
        .margin({ right: 4 });

      // More button
      SymbolGlyph(ICON.MORE)
        .fontSize(16)
        .fontColor([this.themeConfig.textSecondaryColor])
        .onClick(() => {
          this.onMore();
        });
    }
    .width('100%')
    .height(60)
    .padding({ left: 12, right: 8 })
    .borderRadius(this.themeConfig.borderRadius)
    .backdropBlur(MaterialConstants.getBlur(MaterialConstants.REGULAR))
    .backgroundColor(MaterialConstants.getOverlayColor(MaterialConstants.REGULAR, this.themeConfig.isDarkMode))
    .onClick(() => {
      this.onClick();
    });
  }

  private formatDuration(ms: number): string {
    if (ms <= 0) {
      return '--:--';
    }
    const totalSec: number = Math.floor(ms / 1000);
    const min: number = Math.floor(totalSec / 60);
    const sec: number = totalSec % 60;
    let result: string = String(min);
    result += ':';
    if (sec < 10) {
      result += '0';
    }
    result += String(sec);
    return result;
  }
}
