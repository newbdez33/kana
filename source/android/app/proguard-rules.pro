# Google Mobile Ads, UMP and Play Billing ship their own consumer rules.
# org.json is part of the Android platform.

# WorkManager's Room database is created by reflection during app startup.
# Room's consumer rules do not retain its constructor in R8 full mode.
-keep class * extends androidx.room.RoomDatabase {
    void <init>();
}
