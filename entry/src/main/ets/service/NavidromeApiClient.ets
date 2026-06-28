import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  NovidromeConfig,
  SubsonicArtist,
  SubsonicAlbum,
  SubsonicSong,
  SubsonicSearchResult3,
  SubsonicArtistsResponse,
  SubsonicDirectoryResponse,
  SubsonicAlbumListResponse,
  SubsonicSearchResponse,
  SubsonicResponseBase,
} from '../model/MusicModel';
import { MusicConstants } from '../constants/MusicConstants';

const DOMAIN: number = 0x0001;
const TAG: string = 'NavidromeApiClient';

/**
 * Subsonic-compatible REST API client for Navidrome music server.
 * Implements MD5-based token authentication per the Subsonic API spec.
 */
export class NavidromeApiClient {
  private config: NovidromeConfig;
  lastError: string = '';

  constructor(config: NovidromeConfig) {
    this.config = this.normalizeConfig(config);
  }

  updateConfig(config: NovidromeConfig): void {
    this.config = this.normalizeConfig(config);
  }

  getConfig(): NovidromeConfig {
    return this.config;
  }

  private normalizeConfig(config: NovidromeConfig): NovidromeConfig {
    let url: string = config.serverUrl;
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (url !== '' && !url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://' + url;
    }
    return {
      serverUrl: url,
      username: config.username,
      password: config.password,
      enabled: config.enabled,
    };
  }

  // ── Authentication ──

  private generateSalt(length: number): string {
    const chars: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let result: string = '';
    for (let i: number = 0; i < length; i++) {
      const idx: number = Math.floor(Math.random() * chars.length);
      result += chars[idx];
    }
    return result;
  }

  private md5(input: string): string {
    const bytes: number[] = this.stringToUtf8Bytes(input);
    const hash: number[] = this.md5Hash(bytes);
    return this.bytesToHex(hash);
  }

  private stringToUtf8Bytes(str: string): number[] {
    const result: number[] = [];
    for (let i: number = 0; i < str.length; i++) {
      const code: number = str.charCodeAt(i);
      if (code < 0x80) {
        result.push(code);
      } else if (code < 0x800) {
        result.push(0xC0 | (code >> 6));
        result.push(0x80 | (code & 0x3F));
      } else {
        result.push(0xE0 | (code >> 12));
        result.push(0x80 | ((code >> 6) & 0x3F));
        result.push(0x80 | (code & 0x3F));
      }
    }
    return result;
  }

  private md5Hash(input: number[]): number[] {
    const msgLen: number = input.length;
    // paddedLen = number of 32-bit words (16 per 64-byte block)
    const wordCount: number = (((msgLen + 8) >> 6) + 1) << 4;
    // padded array must hold wordCount * 4 bytes (each element is one byte)
    const paddedByteLen: number = wordCount * 4;
    const padded: number[] = new Array<number>(paddedByteLen).fill(0);

    for (let i: number = 0; i < msgLen; i++) {
      padded[i] = input[i];
    }
    padded[msgLen] = 0x80;

    const bitLen: number = msgLen * 8;
    // Store 64-bit message length at the last 8 bytes of the final 64-byte block
    padded[paddedByteLen - 8] = bitLen & 0xFF;
    padded[paddedByteLen - 7] = (bitLen >> 8) & 0xFF;
    padded[paddedByteLen - 6] = (bitLen >> 16) & 0xFF;
    padded[paddedByteLen - 5] = (bitLen >> 24) & 0xFF;

    let a: number = 0x67452301;
    let b: number = 0xEFCDAB89;
    let c: number = 0x98BADCFE;
    let d: number = 0x10325476;

    const sinTable: number[] = [];
    for (let i: number = 0; i < 64; i++) {
      sinTable[i] = Math.floor(Math.abs(Math.sin(i + 1)) * 0x100000000) | 0;
    }

    const shiftAmounts: number[] = [
      7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
      5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
      4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
      6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21
    ];

    // Iterate over 64-byte blocks (16 words = 64 bytes per block)
    for (let offset: number = 0; offset < paddedByteLen; offset += 64) {
      const aa: number = a;
      const bb: number = b;
      const cc: number = c;
      const dd: number = d;

      for (let i: number = 0; i < 64; i++) {
        let f: number = 0;
        let g: number = 0;
        if (i < 16) {
          f = (b & c) | (~b & d);
          g = i;
        } else if (i < 32) {
          f = (d & b) | (~d & c);
          g = (5 * i + 1) % 16;
        } else if (i < 48) {
          f = b ^ c ^ d;
          g = (3 * i + 5) % 16;
        } else {
          f = c ^ (b | ~d);
          g = (7 * i) % 16;
        }

        const wordAtG: number =
          (padded[offset + g * 4]) |
          (padded[offset + g * 4 + 1] << 8) |
          (padded[offset + g * 4 + 2] << 16) |
          (padded[offset + g * 4 + 3] << 24);

        const temp: number = d;
        d = c;
        c = b;
        const x: number = a + f + sinTable[i] + wordAtG;
        b = b + ((x << shiftAmounts[i]) | ((x >>> (32 - shiftAmounts[i]))));
        a = temp;
      }

      a = (a + aa) | 0;
      b = (b + bb) | 0;
      c = (c + cc) | 0;
      d = (d + dd) | 0;
    }

    return [a, b, c, d];
  }

  private bytesToHex(hash: number[]): string {
    let result: string = '';
    for (let i: number = 0; i < hash.length; i++) {
      for (let j: number = 0; j < 4; j++) {
        const byte: number = (hash[i] >> (j * 8)) & 0xFF;
        const hex: string = byte.toString(16);
        if (hex.length === 1) {
          result += '0';
        }
        result += hex;
      }
    }
    return result;
  }

  private generateAuthParams(): string {
    const salt: string = this.generateSalt(12);
    const token: string = this.md5(this.config.password + salt);
    return 'u=' + encodeURIComponent(this.config.username) +
      '&t=' + token +
      '&s=' + salt +
      '&v=' + MusicConstants.NOVIDROME_API_VERSION +
      '&c=' + MusicConstants.NOVIDROME_CLIENT_NAME +
      '&f=json';
  }

  // ── HTTP Request Helper ──

  private async sendGetRequest(endpoint: string): Promise<string> {
    const url: string = this.config.serverUrl + '/rest/' + endpoint + '?' + this.generateAuthParams();
    hilog.info(DOMAIN, TAG, 'Request: %{public}s', endpoint);

    const httpClient: http.HttpRequest = http.createHttp();
    let response: http.HttpResponse | null = null;

    try {
      response = await httpClient.request(url, {
        method: http.RequestMethod.GET,
        connectTimeout: MusicConstants.NOVIDROME_TIMEOUT_MS,
        readTimeout: MusicConstants.NOVIDROME_TIMEOUT_MS,
      });

      if (response.responseCode === 200) {
        const body: string = response.result as string;
        return body;
      }

      hilog.error(DOMAIN, TAG, 'HTTP %{public}d for %{public}s', response.responseCode, endpoint);
      throw new Error('HTTP error: ' + response.responseCode + ' for ' + endpoint);
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'Request failed: %{public}s', e.message);
      throw new Error('Connection failed: ' + e.message);
    } finally {
      httpClient.destroy();
    }
  }

  // ── Response Parsing ──

  /**
   * Unwraps the Subsonic JSON envelope.
   * All Subsonic JSON responses are wrapped in a "subsonic-response" object.
   * Example: {"subsonic-response":{"status":"ok","version":"1.16.1",...}}
   */
  private unwrap(json: string): Record<string, Object> {
    const raw = JSON.parse(json) as Record<string, Object>;
    const inner = raw['subsonic-response'] as Record<string, Object>;
    return inner;
  }

  private parseResponse<T extends SubsonicResponseBase>(json: string, endpoint: string): T {
    const resp = this.unwrap(json);
    const status: string = resp['status'] as string;
    if (status !== 'ok') {
      const errObj = resp['error'] as Record<string, Object>;
      const msg: string = errObj !== undefined ? errObj['message'] as string : 'Unknown error';
      throw new Error('Subsonic error: ' + msg);
    }
    return resp as T;
  }

  // ── Public API Methods ──

  async ping(): Promise<boolean> {
    try {
      const json: string = await this.sendGetRequest('ping');
      const resp = this.unwrap(json);
      const status: string = resp['status'] as string;
      hilog.info(DOMAIN, TAG, 'Ping response: %{public}s', status);
      this.lastError = '';
      return status === 'ok';
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      this.lastError = e.message;
      hilog.error(DOMAIN, TAG, 'Ping failed: %{public}s', e.message);
      return false;
    }
  }

  async getArtists(): Promise<SubsonicArtist[]> {
    const json: string = await this.sendGetRequest('getArtists');
    const parsed: SubsonicArtistsResponse = this.parseResponse<SubsonicArtistsResponse>(json, 'getArtists');
    const artists: SubsonicArtist[] = [];
    if (parsed.artists !== undefined && parsed.artists.index !== undefined) {
      for (let i: number = 0; i < parsed.artists.index.length; i++) {
        const indexGroup = parsed.artists.index[i];
        if (indexGroup.artist !== undefined) {
          for (let j: number = 0; j < indexGroup.artist.length; j++) {
            artists.push(indexGroup.artist[j]);
          }
        }
      }
    }
    return artists;
  }

  async getAlbums(artistId?: string): Promise<SubsonicAlbum[]> {
    let endpoint: string = 'getAlbumList2?type=newest&size=500';
    if (artistId !== undefined && artistId !== '') {
      endpoint = 'getArtist?id=' + artistId;
    }
    const json: string = await this.sendGetRequest(endpoint);

    if (artistId !== undefined && artistId !== '') {
      const resp = this.unwrap(json);
      const artistObj = resp['artist'] as Record<string, Object>;
      if (artistObj !== undefined && artistObj['album'] !== undefined) {
        return artistObj['album'] as SubsonicAlbum[];
      }
      return [];
    }

    const parsed: SubsonicAlbumListResponse = this.parseResponse<SubsonicAlbumListResponse>(json, endpoint);
    return parsed.albumList !== undefined && parsed.albumList.album !== undefined ? parsed.albumList.album : [];
  }

  async getSongs(albumId: string): Promise<SubsonicSong[]> {
    const endpoint: string = 'getAlbum?id=' + albumId;
    const json: string = await this.sendGetRequest(endpoint);

    const resp = this.unwrap(json);
    const albumObj = resp['album'] as Record<string, Object>;
    if (albumObj !== undefined && albumObj['song'] !== undefined) {
      return albumObj['song'] as SubsonicSong[];
    }
    return [];
  }

  async search3(query: string): Promise<SubsonicSearchResult3> {
    const endpoint: string = 'search3?query=' + encodeURIComponent(query);
    const json: string = await this.sendGetRequest(endpoint);
    const parsed: SubsonicSearchResponse = this.parseResponse<SubsonicSearchResponse>(json, endpoint);
    if (parsed.searchResult3 !== undefined) {
      return parsed.searchResult3;
    }
    return { artist: [], album: [], song: [] };
  }

  getStreamUrl(trackId: string): string {
    return this.config.serverUrl + '/rest/stream?id=' + trackId + '&' + this.generateAuthParams();
  }

  getCoverArtUrl(coverArtId: string, size?: number): string {
    let endpoint: string = 'getCoverArt?id=' + coverArtId;
    if (size !== undefined && size > 0) {
      endpoint += '&size=' + size;
    }
    return this.config.serverUrl + '/rest/' + endpoint + '&' + this.generateAuthParams();
  }
}
