import pLimit from 'p-limit';

interface RateLimitConfig {
  requestsPerMinute: number;
  concurrentRequests: number;
}

const defaultConfig: Record<string, RateLimitConfig> = {
  DoctorOfCredit: { requestsPerMinute: 10, concurrentRequests: 2 },
  ThePointsGuy: { requestsPerMinute: 10, concurrentRequests: 2 },
  IssuerSites: { requestsPerMinute: 5, concurrentRequests: 1 },
  default: { requestsPerMinute: 20, concurrentRequests: 3 },
};

class RateLimiter {
  private lastRequest: Map<string, number> = new Map();
  private limiters: Map<string, ReturnType<typeof pLimit>> = new Map();

  async wait(source: string): Promise<void> {
    const config = defaultConfig[source] || defaultConfig.default;
    const minInterval = 60000 / config.requestsPerMinute;

    const lastTime = this.lastRequest.get(source) || 0;
    const elapsed = Date.now() - lastTime;

    if (elapsed < minInterval) {
      await new Promise(resolve => setTimeout(resolve, minInterval - elapsed));
    }

    this.lastRequest.set(source, Date.now());
  }

  getLimiter(source: string): ReturnType<typeof pLimit> {
    if (!this.limiters.has(source)) {
      const config = defaultConfig[source] || defaultConfig.default;
      this.limiters.set(source, pLimit(config.concurrentRequests));
    }
    return this.limiters.get(source)!;
  }
}

export const rateLimiter = new RateLimiter();
