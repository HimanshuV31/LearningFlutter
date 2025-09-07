package com.ehv.infinitynotes;
import io.flutter.embedding.android.FlutterActivity;
import androidx.core.splashscreen.SplashScreen;
import android.os.Bundle;

public class MainActivity extends FlutterActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        SplashScreen.installSplashScreen(this);
        super.onCreate(savedInstanceState);
    }
    void main(){
    }
}
