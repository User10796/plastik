import winston from 'winston';
import { mkdirSync, existsSync } from 'fs';
import { join } from 'path';

const logsDir = join(process.cwd(), 'logs');
if (!existsSync(logsDir)) {
  mkdirSync(logsDir, { recursive: true });
}

export const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      ),
    }),
    new winston.transports.File({
      filename: join(logsDir, `scraper-${new Date().toISOString().split('T')[0]}.log`),
    }),
    new winston.transports.File({
      filename: join(logsDir, 'error.log'),
      level: 'error',
    }),
  ],
});
