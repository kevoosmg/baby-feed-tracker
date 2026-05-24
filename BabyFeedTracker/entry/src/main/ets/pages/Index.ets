import { SupabaseClient, FeedRecord } from '../utils/SupabaseClient';
import { preferences } from '@kit.ArkData';
import { promptAction } from '@kit.ArkUI';
import { BusinessError } from '@ohos.base';

const FEED_INTERVAL_MS: number = 2.5 * 60 * 60 * 1000; // 2.5小时
const SUPABASE_URL: string = 'https://xfkixutmglsbxlimkbtn.supabase.co';

interface LastFeedCache {
  big: number;
  small: number;
}

@Entry
@Component
struct Index {
  @State currentBaby: string = 'big';
  @State feedType: string = 'formula';
  @State amount: number = 120;
  @State lastFeedBig: number = 0;
  @State lastFeedSmall: number = 0;
  @State timerText: string = '--:--';
  @State timerProgress: number = 0;
  @State isOverdue: boolean = false;
  @State timerLabel: string = '暂无记录';
  @State online: boolean = false;
  @State vitADDone: boolean = false;
  @State vitD3Done: boolean = false;
  @State loading: boolean = true;
  @State lastFeedLabel: string = '上次喂奶';

  private timerId: number = -1;
  private dataPrefs?: preferences.Preferences;
  private readonly AMOUNTS: number[] = [60, 90, 120, 150, 180];

  aboutToAppear(): void {
    this.initPrefs();
    this.loadAllData();
    this.timerId = setInterval(() => this.updateTimer(), 1000);
  }

  aboutToDisappear(): void {
    if (this.timerId >= 0) {
      clearInterval(this.timerId);
    }
  }

  initPrefs(): void {
    try {
      const context = getContext(this);
      this.dataPrefs = preferences.getPreferencesSync(context, { name: 'babyFeed' });
    } catch (e) {
      console.error('Failed to init preferences');
    }
  }

  // ========== DATA LOADING ==========
  async loadAllData(): Promise<void> {
    const lf: LastFeedCache = { big: 0, small: 0 };

    // Try Supabase
    try {
      const feeds: FeedRecord[] = await SupabaseClient.getFeedRecords(200);
      feeds.forEach((r: FeedRecord) => {
        if (r.feed_type !== 'direct' && !lf[r.baby as keyof LastFeedCache]) {
          lf[r.baby as keyof LastFeedCache] = new Date(r.time).getTime();
        }
      });
      this.online = true;
    } catch (e) {
      // Fall back to local cache
      this.online = false;
      try {
        if (this.dataPrefs) {
          const cached: string = this.dataPrefs.getSync('lastFeedCache', '{}') as string;
          const parsed: LastFeedCache = JSON.parse(cached);
          if (parsed.big) lf.big = parsed.big;
          if (parsed.small) lf.small = parsed.small;
        }
      } catch (e2) { /* ignore */ }
    }

    this.lastFeedBig = lf.big;
    this.lastFeedSmall = lf.small;

    // Save cache locally
    try {
      if (this.dataPrefs) {
        this.dataPrefs.putSync('lastFeedCache', JSON.stringify(lf));
        this.dataPrefs.flush();
      }
    } catch (e) { /* ignore */ }

    // Load vitamin state
    try {
      if (this.dataPrefs) {
        this.vitADDone = this.dataPrefs.getSync('vitAD', false) as boolean;
        this.vitD3Done = this.dataPrefs.getSync('vitD3', false) as boolean;
      }
    } catch (e) { /* ignore */ }

    this.loading = false;
    this.updateTimer();
  }

  // ========== TIMER ==========
  getLastFeed(): number {
    return this.currentBaby === 'big' ? this.lastFeedBig : this.lastFeedSmall;
  }

  updateTimer(): void {
    const lf: number = this.getLastFeed();
    if (!lf) {
      this.timerText = '--:--';
      this.timerProgress = 0;
      this.isOverdue = false;
      this.timerLabel = '暂无记录';
      this.lastFeedLabel = '上次喂奶';
      return;
    }

    const now: number = Date.now();
    const elapsed: number = now - lf;
    const elapsedMin: number = Math.floor(elapsed / 60000);
    const hours: number = Math.floor(elapsedMin / 60);
    const mins: number = elapsedMin % 60;

    this.timerText = `${hours}:${String(mins).padStart(2, '0')}`;

    const ratio: number = Math.min(1, elapsed / FEED_INTERVAL_MS);
    this.timerProgress = ratio * 100;

    if (ratio >= 1) {
      this.isOverdue = true;
      this.timerLabel = '可以喂奶了！';
    } else {
      this.isOverdue = false;
      const remaining: number = FEED_INTERVAL_MS - elapsed;
      const remainMin: number = Math.floor(remaining / 60000);
      this.timerLabel = `距下次 ${remainMin}分钟`;
    }

    // Last feed time display
    const d: Date = new Date(lf);
    this.lastFeedLabel = `上次 ${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
  }

  // ========== ACTIONS ==========
  switchBaby(baby: string): void {
    this.currentBaby = baby;
    this.updateTimer();
  }

  setFeedType(type: string): void {
    this.feedType = type;
  }

  setAmount(val: number): void {
    this.amount = val;
  }

  adjustAmount(delta: number): void {
    this.amount = Math.max(10, Math.min(500, this.amount + delta));
  }

  cycleAmount(): void {
    const idx: number = this.AMOUNTS.indexOf(this.amount);
    this.amount = this.AMOUNTS[(idx + 1) % this.AMOUNTS.length];
  }

  async recordFeed(): Promise<void> {
    const baby: string = this.currentBaby;
    const ts: number = Date.now();
    const recordAmount: number = this.feedType === 'direct' ? 0 : this.amount;

    // Update local immediately
    if (this.feedType !== 'direct') {
      if (baby === 'big') {
        this.lastFeedBig = ts;
      } else {
        this.lastFeedSmall = ts;
      }

      // Save to local prefs
      try {
        if (this.dataPrefs) {
          const lf: LastFeedCache = { big: this.lastFeedBig, small: this.lastFeedSmall };
          this.dataPrefs.putSync('lastFeedCache', JSON.stringify(lf));
          this.dataPrefs.flush();
        }
      } catch (e) { /* ignore */ }
    }

    this.updateTimer();

    // Sync to Supabase
    try {
      await SupabaseClient.createFeedRecord({
        baby: baby,
        time: new Date(ts).toISOString(),
        amount: recordAmount,
        feed_type: this.feedType
      });
      this.online = true;
    } catch (e) {
      this.online = false;
    }

    // Toast
    const name: string = baby === 'big' ? '大宝' : '小宝';
    const typeNames: Record<string, string> = { 'formula': '奶粉', 'breast': '母乳', 'direct': '亲喂' };
    const typeLabel: string = typeNames[this.feedType] || this.feedType;
    const amountText: string = this.feedType === 'direct' ? '' : `${recordAmount}ml `;
    this.showToast(`${name} ${typeLabel} ${amountText}已记录`);
  }

  toggleVitamin(type: string): void {
    if (type === 'AD') {
      this.vitADDone = !this.vitADDone;
    } else {
      this.vitD3Done = !this.vitD3Done;
    }

    // Save locally
    try {
      if (this.dataPrefs) {
        this.dataPrefs.putSync('vitAD', this.vitADDone);
        this.dataPrefs.putSync('vitD3', this.vitD3Done);
        this.dataPrefs.flush();
      }
    } catch (e) { /* ignore */ }

    // Sync to Supabase
    const today: string = new Date().toISOString().split('T')[0];
    const newDone: boolean = type === 'AD' ? this.vitADDone : this.vitD3Done;
    if (newDone) {
      SupabaseClient.upsertVitamin({ type: type, date_key: today });
    }
  }

  showToast(msg: string): void {
    promptAction.showToast({
      message: msg,
      duration: 1500,
      bottom: 40
    });
  }

  // ========== UI ==========
  getBabyColor(): string {
    return this.currentBaby === 'big' ? '#FF6B9D' : '#4FACFE';
  }

  getTimerColor(): string {
    if (this.isOverdue) return '#FF4757';
    return this.getBabyColor();
  }

  build() {
    Scroll() {
      Column({ space: 8 }) {
        // === Header: Baby Tabs ===
        Row({ space: 6 }) {
          Button('大宝')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.currentBaby === 'big' ? Color.White : '#888')
            .backgroundColor(this.currentBaby === 'big' ? '#FF6B9D' : '#1A1A1A')
            .borderRadius(20)
            .height(40)
            .layoutWeight(1)
            .onClick(() => this.switchBaby('big'))

          Button('小宝')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.currentBaby === 'small' ? Color.White : '#888')
            .backgroundColor(this.currentBaby === 'small' ? '#4FACFE' : '#1A1A1A')
            .borderRadius(20)
            .height(40)
            .layoutWeight(1)
            .onClick(() => this.switchBaby('small'))
        }
        .width('100%')
        .padding({ top: 12, left: 8, right: 8 })

        // === Timer Ring ===
        Stack({ alignContent: Alignment.Center }) {
          Progress({
            value: this.timerProgress,
            total: 100,
            type: ProgressType.Ring
          })
            .width(160)
            .height(160)
            .color(this.getTimerColor())
            .style({
              strokeWidth: 8,
              scaleCount: 60,
              scaleWidth: 4
            })

          Column() {
            Text(this.timerText)
              .fontSize(40)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.isOverdue ? '#FF4757' : Color.White)
              .fontFamily('monospace')

            Text(this.timerLabel)
              .fontSize(12)
              .fontColor('#999')
              .margin({ top: 2 })
          }
        }
        .width('100%')
        .height(170)
        .margin({ top: 4 })

        // === Last Feed ===
        Text(this.lastFeedLabel)
          .fontSize(13)
          .fontColor('#999')
          .margin({ bottom: 4 })

        // === Feed Type ===
        Row({ space: 6 }) {
          this.FeedTypeButton('formula', '奶粉')
          this.FeedTypeButton('breast', '母乳')
          this.FeedTypeButton('direct', '亲喂')
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)

        // === Amount (hidden for direct feed) ===
        if (this.feedType !== 'direct') {
          Row({ space: 8 }) {
            Button('−')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .width(40)
              .height(40)
              .borderRadius(20)
              .backgroundColor('#1A1A1A')
              .fontColor(Color.White)
              .onClick(() => this.adjustAmount(-10))

            Text(`${this.amount}ml`)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFD700')
              .textAlign(TextAlign.Center)
              .layoutWeight(1)
              .onClick(() => this.cycleAmount())

            Button('+')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .width(40)
              .height(40)
              .borderRadius(20)
              .backgroundColor('#1A1A1A')
              .fontColor(Color.White)
              .onClick(() => this.adjustAmount(10))
          }
          .width('100%')
          .margin({ top: 4 })
        }

        // === Presets ===
        if (this.feedType !== 'direct') {
          Row({ space: 5 }) {
            ForEach(this.AMOUNTS, (val: number) => {
              Button(`${val}`)
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.amount === val ? Color.Black : '#CCC')
                .backgroundColor(this.amount === val ? '#FFD700' : '#1A1A1A')
                .borderRadius(14)
                .height(32)
                .padding({ left: 10, right: 10 })
                .onClick(() => this.setAmount(val))
            })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
        }

        // === Record Button ===
        Button(this.feedType === 'direct' ? '记录亲喂' : '记 录')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .backgroundColor(this.getBabyColor())
          .borderRadius(22)
          .height(48)
          .width('100%')
          .shadow({
            radius: 12,
            color: this.getBabyColor(),
            offsetY: 4
          })
          .onClick(() => this.recordFeed())
          .margin({ top: 6 })

        // === Vitamin ===
        Row({ space: 8 }) {
          this.VitaminButton('AD', this.vitADDone)
          this.VitaminButton('D3', this.vitD3Done)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 8 })

        // === Connection ===
        Row({ space: 4 }) {
          Circle()
            .width(6)
            .height(6)
            .fill(this.online ? '#43E97B' : '#FF4757')

          Text(this.online ? '在线' : '离线')
            .fontSize(10)
            .fontColor('#666')
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .margin({ top: 4, bottom: 16 })

        // Loading overlay
        if (this.loading) {
          LoadingProgress()
            .width(32)
            .height(32)
            .color('#FFD700')
        }
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0D0D0D')
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Off)
  }

  @Builder FeedTypeButton(type: string, label: string) {
    Button(label)
      .fontSize(13)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.feedType === type ? Color.Black : '#CCC')
      .backgroundColor(this.feedType === type ? '#FFD700' : '#1A1A1A')
      .borderRadius(16)
      .height(34)
      .padding({ left: 12, right: 12 })
      .onClick(() => this.setFeedType(type))
  }

  @Builder VitaminButton(type: string, done: boolean) {
    Button(done ? `${type} ✓` : type)
      .fontSize(13)
      .fontWeight(FontWeight.Medium)
      .fontColor(done ? '#43E97B' : '#888')
      .backgroundColor(done ? '#1A3A2A' : '#1A1A1A')
      .border({ width: done ? 1 : 0, color: done ? '#43E97B' : 'transparent' })
      .borderRadius(16)
      .height(34)
      .layoutWeight(1)
      .onClick(() => this.toggleVitamin(type))
  }
}
