# Proguard rules to ignore missing optional MLKit language classes 
# (Chinese, Japanese, Devanagari, Korean)
# since we only use Latin/default MLKit text recognition in google_mlkit_text_recognition

-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Automatically generated from missing_rules.txt
-dontwarn io.flutter.embedding.engine.plugins.lifecycle.FlutterLifecycleAdapter
-dontwarn io.flutter.plugins.flutter_plugin_android_lifecycle.FlutterAndroidLifecyclePlugin
