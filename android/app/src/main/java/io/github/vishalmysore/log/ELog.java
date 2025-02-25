package io.github.vishalmysore.log;

import io.flutter.BuildConfig;

public class ELog {

    public static void info(String msg) {
        if (BuildConfig.DEBUG) {
            System.out.println(msg);
        }
    }
    public static void debug(String msg) {
        if (BuildConfig.DEBUG) {
            System.out.println(msg);
        }
    }
}
