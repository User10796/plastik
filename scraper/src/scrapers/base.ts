import { ScrapeResult } from '../types/index.js';
import { rateLimiter } from '../utils/rateLimiter.js';
import { logger } from '../utils/logger.js';

export abstract class BaseScraper {
  protected name: string;
  protected baseUrl: string;
  protected userAgent = 'Plastik Data Bot/1.0 (https://github.com/User10796/Plastik)';

  constructor(name: string, baseUrl: string) {
    this.name = name;
    this.baseUrl = baseUrl;
  }

  abstract getUrls(): string[];

  async scrape(): Promise<ScrapeResult[]> {
    const urls = this.getUrls();
    const results: ScrapeResult[] = [];

    for (const url of urls) {
      try {
        await rateLimiter.wait(this.name);

        logger.info(`Scraping ${url}`);

        const response = await fetch(url, {
          headers: {
            'User-Agent': this.userAgent,
            'Accept': 'text/html,application/xhtml+xml',
          },
        });

        if (!response.ok) {
          throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }

        const html = await response.text();

        results.push({
          source: this.name,
          url,
          scrapedAt: new Date().toISOString(),
          rawContent: html,
          success: true,
        });

        logger.info(`Successfully scraped ${url} (${html.length} bytes)`);

      } catch (error) {
        const errorMessage = error instanceof Error ? error.message : 'Unknown error';
        logger.error(`Failed to scrape ${url}: ${errorMessage}`);

        results.push({
          source: this.name,
          url,
          scrapedAt: new Date().toISOString(),
          rawContent: '',
          success: false,
          error: errorMessage,
        });
      }
    }

    return results;
  }
}
