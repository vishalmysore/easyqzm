package io.github.vishalmysore.easyqzm;

import android.content.Intent;
import android.os.Bundle;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.plugin.common.MethodChannel;
import io.github.vishalmysore.log.ELog;

import java.util.Objects;


public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.easyqzm/sharing"; // Define the channel name
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);


        Intent intent = getIntent();
        String action = intent.getAction();
        String type = intent.getType();

        if (Intent.ACTION_SEND.equals(action) && type != null) {
            if ("text/plain".equals(type)) {
                handleSendText(intent); // Handle text being sent
            }
        }
    }

    void handleSendText(Intent intent) {
     try{
        String sharedText = intent.getStringExtra(Intent.EXTRA_TEXT);
        ELog.debug(("received here in Java " + sharedText));
        if (sharedText != null) {
            new MethodChannel(Objects.requireNonNull(getFlutterEngine()).getDartExecutor(), CHANNEL)
                    .invokeMethod("sharedText", sharedText);
        }
        ELog.debug(("received here in Java ends" + sharedText));
    }
        catch (Exception e) {
            e.printStackTrace();
        }
    }
}
