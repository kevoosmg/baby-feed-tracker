import { UIAbility, Want, AbilityConstant } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'BabyFeedTracker', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(0x0000, 'BabyFeedTracker', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(0x0000, 'BabyFeedTracker', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'BabyFeedTracker', 'Failed to load content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(0x0000, 'BabyFeedTracker', 'Succeeded in loading content.');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(0x0000, 'BabyFeedTracker', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(0x0000, 'BabyFeedTracker', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(0x0000, 'BabyFeedTracker', 'Ability onBackground');
  }
}
