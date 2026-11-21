import UIAbility from '@ohos.app.ability.UIAbility';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import Want from '@ohos.app.ability.Want';
import window from '@ohos.window';

export default class WebAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    AppStorage.setOrCreate<string>('launchUrl', '');
    if (want.parameters !== undefined) {
      const v = want.parameters['url'];
      if (typeof v === 'string' && v.length > 0) {
        AppStorage.setOrCreate<string>('launchUrl', v as string);
      }
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index').then(() => {
      return windowStage.getMainWindow();
    }).then((win: window.Window) => {
      win.setWindowKeepScreenOn(true);
    }).catch((e: Error) => {
      console.error('window init failed: ' + e.message);
    });
  }
}
