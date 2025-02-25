package io.github.vishalmysore.easyqzm;

import android.app.Application;
import io.github.vishalmysore.log.ELog;


public class EasyQZApplication extends Application{
    @Override
    public void onCreate() {
        super.onCreate();
        ELog.debug("EasyQZ initiated");
    }
}