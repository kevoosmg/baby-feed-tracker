import http from '@ohos.net.http';
import { BusinessError } from '@ohos.base';

const SUPABASE_URL: string = 'https://xfkixutmglsbxlimkbtn.supabase.co';
const SUPABASE_KEY: string = 'sb_publishable_8kzHQn4rDaaQ-2gLN91hcA_9_0bvRWN';

export interface FeedRecord {
  id?: number;
  baby: string;
  time: string;
  amount: number;
  feed_type: string;
  note?: string;
}

export interface VitaminRecord {
  id?: number;
  type: string;
  date_key: string;
}

export class SupabaseClient {
  /**
   * Fetch recent feed records from Supabase
   */
  static async getFeedRecords(limit: number = 100): Promise<FeedRecord[]> {
    return new Promise<FeedRecord[]>((resolve, reject) => {
      const httpRequest = http.createHttp();
      const url = `${SUPABASE_URL}/rest/v1/feed_records?select=*&order=time.desc&limit=${limit}`;

      httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: {
          'apikey': SUPABASE_KEY,
          'Authorization': `Bearer ${SUPABASE_KEY}`,
          'Content-Type': 'application/json'
        },
        connectTimeout: 5000,
        readTimeout: 5000
      }, (err: BusinessError, data: http.HttpResponse) => {
        if (!err && data.responseCode === 200) {
          try {
            const records: FeedRecord[] = JSON.parse(data.result as string);
            resolve(records);
          } catch (parseErr) {
            reject(new Error('Failed to parse feed records'));
          }
        } else {
          reject(err || new Error(`HTTP ${data.responseCode}`));
        }
        httpRequest.destroy();
      });
    });
  }

  /**
   * Create a new feed record
   */
  static async createFeedRecord(record: FeedRecord): Promise<FeedRecord | null> {
    return new Promise<FeedRecord | null>((resolve, reject) => {
      const httpRequest = http.createHttp();
      const url = `${SUPABASE_URL}/rest/v1/feed_records`;

      httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'apikey': SUPABASE_KEY,
          'Authorization': `Bearer ${SUPABASE_KEY}`,
          'Content-Type': 'application/json',
          'Prefer': 'return=representation'
        },
        extraData: JSON.stringify({
          baby: record.baby,
          time: record.time,
          amount: record.amount,
          feed_type: record.feed_type,
          note: record.note || ''
        }),
        connectTimeout: 5000,
        readTimeout: 5000
      }, (err: BusinessError, data: http.HttpResponse) => {
        if (!err && (data.responseCode === 200 || data.responseCode === 201)) {
          try {
            const created: FeedRecord[] = JSON.parse(data.result as string);
            resolve(created.length > 0 ? created[0] : null);
          } catch (parseErr) {
            resolve(null);
          }
        } else {
          reject(err || new Error(`HTTP ${data.responseCode}`));
        }
        httpRequest.destroy();
      });
    });
  }

  /**
   * Get vitamin records for today
   */
  static async getVitaminRecords(dateKey: string): Promise<VitaminRecord[]> {
    return new Promise<VitaminRecord[]>((resolve, reject) => {
      const httpRequest = http.createHttp();
      const url = `${SUPABASE_URL}/rest/v1/vitamin_records?select=*&date_key=eq.${dateKey}`;

      httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: {
          'apikey': SUPABASE_KEY,
          'Authorization': `Bearer ${SUPABASE_KEY}`
        },
        connectTimeout: 5000,
        readTimeout: 5000
      }, (err: BusinessError, data: http.HttpResponse) => {
        if (!err && data.responseCode === 200) {
          try {
            const records: VitaminRecord[] = JSON.parse(data.result as string);
            resolve(records);
          } catch (parseErr) {
            resolve([]);
          }
        } else {
          resolve([]);
        }
        httpRequest.destroy();
      });
    });
  }

  /**
   * Upsert vitamin record (insert if not exists, update if exists)
   */
  static async upsertVitamin(vitamin: VitaminRecord): Promise<boolean> {
    return new Promise<boolean>((resolve, reject) => {
      const httpRequest = http.createHttp();
      const url = `${SUPABASE_URL}/rest/v1/vitamin_records`;

      httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'apikey': SUPABASE_KEY,
          'Authorization': `Bearer ${SUPABASE_KEY}`,
          'Content-Type': 'application/json',
          'Prefer': 'resolution=merge-duplicates'
        },
        extraData: JSON.stringify({
          type: vitamin.type,
          date_key: vitamin.date_key
        }),
        connectTimeout: 5000,
        readTimeout: 5000
      }, (err: BusinessError, data: http.HttpResponse) => {
        if (!err && (data.responseCode === 200 || data.responseCode === 201)) {
          resolve(true);
        } else {
          resolve(false);
        }
        httpRequest.destroy();
      });
    });
  }
}
