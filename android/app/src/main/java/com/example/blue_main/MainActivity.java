package com.example.blue_main;

import android.content.Intent;
import android.os.Build;


import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.retroportalstudio.messages";

    private Intent forService;

    @Override
    public void configureFlutterEngine( FlutterEngine flutterEngine) {
        forService = new Intent(MainActivity.this, com.example.blue_main.MyService.class);
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            // Note: this method is invoked on the main thread.
                            if (call.method.equals("startService")) {
                                startService();
                                result.success("Service Started");

                            } else {
                                result.error("UNAVAILABLE", "Battery level not available.", null);
                            }
                        }
                );
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        stopService(forService);
    }

    private void startService() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(forService);
        } else {
            startService(forService);
        }
    }


}

