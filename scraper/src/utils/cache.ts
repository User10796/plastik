import { existsSync, mkdirSync, readFileSync, writeFileSync, readdirSync, unlinkSync } from 'fs';
import { join } from 'path';
import { ScrapeResult } from '../types/index.js';

const cacheDir = join(process.cwd(), '..', 'data', 'cache');

export class Cache {
  constructor() {
    if (!existsSync(cacheDir)) {
      mkdirSync(cacheDir, { recursive: true });
    }
  }

  private getCacheKey(source: string, url: string): string {
    const sanitized = url.replace(/[^a-zA-Z0-9]/g, '_').slice(0, 100);
    return `${source}_${sanitized}`;
  }

  private getCachePath(key: string): string {
    return join(cacheDir, `${key}.json`);
  }

  get(source: string, url: string): ScrapeResult | null {
    const key = this.getCacheKey(source, url);
    const path = this.getCachePath(key);

    if (!existsSync(path)) return null;

    try {
      const data = JSON.parse(readFileSync(path, 'utf-8'));

      // Cache expires after 6 hours
      const cacheAge = Date.now() - new Date(data.scrapedAt).getTime();
      if (cacheAge > 6 * 60 * 60 * 1000) {
        return null;
      }

      return data;
    } catch {
      return null;
    }
  }

  set(result: ScrapeResult): void {
    const key = this.getCacheKey(result.source, result.url);
    const path = this.getCachePath(key);
    writeFileSync(path, JSON.stringify(result, null, 2));
  }

  clear(): void {
    if (!existsSync(cacheDir)) return;
    const files = readdirSync(cacheDir);
    for (const file of files) {
      unlinkSync(join(cacheDir, file));
    }
  }
}

export const cache = new Cache();
