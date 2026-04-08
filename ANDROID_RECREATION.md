# Apta Android Recreation Guide
**Kotlin + Jetpack Compose — 1:1 iOS Recreation**

---

## Table of Contents
1. [Project Setup](#1-project-setup)
2. [Dependencies](#2-dependencies)
3. [Project Structure](#3-project-structure)
4. [Data Models](#4-data-models)
5. [Design System](#5-design-system)
6. [Services](#6-services)
7. [Screens & Navigation](#7-screens--navigation)
8. [Notifications](#8-notifications)
9. [In-App Purchases (Pro)](#9-in-app-purchases-pro)
10. [Widgets](#10-widgets)
11. [Platform Equivalency Reference](#11-platform-equivalency-reference)

---

## 1. Project Setup

### New Project Settings
- **Language**: Kotlin
- **Minimum SDK**: API 26 (Android 8.0) — required for Java 8 time APIs
- **Target SDK**: API 35 (Android 15)
- **Build System**: Gradle (Kotlin DSL)
- **Package name**: `com.gazi.apta`
- **Template**: Empty Activity (Compose)

### `AndroidManifest.xml` Permissions
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.INTERNET" />
```

Also register the notification receiver and boot receiver:
```xml
<receiver android:name=".notifications.NotificationReceiver" android:exported="false" />
<receiver android:name=".notifications.BootReceiver" android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED" />
    </intent-filter>
</receiver>
```

---

## 2. Dependencies

Add to `build.gradle.kts` (app module):

```kotlin
dependencies {
    // Compose BOM
    val composeBom = platform("androidx.compose:compose-bom:2024.12.01")
    implementation(composeBom)
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.animation:animation")
    implementation("androidx.activity:activity-compose:1.9.3")

    // Navigation
    implementation("androidx.navigation:navigation-compose:2.8.4")

    // Lifecycle & ViewModel
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.7")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.8.7")

    // Prayer Times Calculation (Adhan Android port)
    implementation("com.batoulapps.adhan:adhan-kotlin:2.2.0")

    // Location
    implementation("com.google.android.gms:play-services-location:21.3.0")

    // DataStore (replaces SharedPreferences/UserDefaults)
    implementation("androidx.datastore:datastore-preferences:1.1.1")

    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")

    // Kotlinx Serialization (for JSON models)
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.7.3")

    // Billing (In-App Purchases)
    implementation("com.android.billingclient:billing-ktx:7.1.1")

    // Glance (App Widgets)
    implementation("androidx.glance:glance-appwidget:1.1.1")
    implementation("androidx.glance:glance-material3:1.1.1")

    // WorkManager (Widget/notification scheduling)
    implementation("androidx.work:work-runtime-ktx:2.10.0")
}
```

Also enable Kotlin serialization plugin in `build.gradle.kts`:
```kotlin
plugins {
    id("org.jetbrains.kotlin.plugin.serialization") version "2.0.21"
}
```

---

## 3. Project Structure

Mirror the iOS MVVM + Coordinator architecture:

```
app/src/main/java/com/gazi/apta/
├── AptaApplication.kt          // Application class, DI setup
├── MainActivity.kt             // Single activity host
│
├── navigation/
│   └── RootNavGraph.kt         // Replaces RootCoordinator.swift
│
├── models/
│   ├── PrayerName.kt
│   ├── PrayerSettings.kt
│   ├── CalculationMethod.kt
│   ├── BackgroundTheme.kt
│   ├── BackgroundPreset.kt
│   └── PrayerTimeEntry.kt
│
├── data/
│   └── AppDataStore.kt         // Replaces SharedDefaults.swift
│
├── services/
│   ├── LocationService.kt
│   ├── PrayerCalculationService.kt
│   └── NotificationScheduler.kt
│
├── purchases/
│   └── PurchaseManager.kt
│
├── ui/
│   ├── splash/
│   │   └── SplashScreen.kt
│   ├── onboarding/
│   │   ├── OnboardingScreen.kt
│   │   ├── OnboardingMethodPage.kt
│   │   ├── OnboardingPreferencesPage.kt
│   │   ├── OnboardingLocationPage.kt
│   │   └── OnboardingNotificationPage.kt
│   ├── prayer/
│   │   ├── PrayerTimesScreen.kt
│   │   ├── PrayerTimesViewModel.kt
│   │   ├── PrayerDayView.kt
│   │   └── QiblaStripCompass.kt
│   ├── calendar/
│   │   └── IslamicCalendarView.kt
│   ├── settings/
│   │   ├── SettingsSheet.kt
│   │   └── BackgroundSettingsSheet.kt
│   └── design/
│       ├── AptaColors.kt
│       ├── AptaTypography.kt
│       ├── AptaTheme.kt
│       ├── Haptics.kt
│       └── AnimationConstants.kt
│
├── notifications/
│   ├── NotificationReceiver.kt
│   ├── BootReceiver.kt
│   └── NotificationMessages.kt
│
└── widgets/
    ├── PrayerWidget.kt
    └── PrayerWidgetReceiver.kt
```

---

## 4. Data Models

### `PrayerName.kt`
```kotlin
enum class PrayerName(val displayName: String) {
    FAJR("Fajr"),
    SUNRISE("Sunrise"),
    DHUHR("Dhuhr"),
    ASR("Asr"),
    MAGHRIB("Maghrib"),
    ISHA("Isha"),
    ISHRAQ("Ishraq")
}

data class PrayerTimeEntry(
    val name: PrayerName,
    val time: java.time.LocalTime
)
```

### `CalculationMethod.kt`
The iOS app uses the Adhan library — use `adhan-kotlin` which has identical API:
```kotlin
import com.batoulapps.adhan.CalculationMethod as AdhanMethod

enum class CalculationMethod(val displayName: String) {
    MUSLIM_WORLD_LEAGUE("Muslim World League"),
    EGYPTIAN("Egyptian General Authority"),
    KARACHI("University of Islamic Sciences, Karachi"),
    UMM_AL_QURA("Umm al-Qura University, Makkah"),
    DUBAI("Dubai"),
    MOON_SIGHTING_COMMITTEE("Moonsighting Committee"),
    ISNA("Islamic Society of North America"),
    KUWAIT("Kuwait"),
    QATAR("Qatar"),
    SINGAPORE("Singapore"),
    TURKEY("Turkey"),
    TEHRAN("Institute of Geophysics, University of Tehran"),
    OTHER("Other");                // Custom angles

    fun toAdhanMethod(): AdhanMethod = when (this) {
        MUSLIM_WORLD_LEAGUE     -> AdhanMethod.MUSLIM_WORLD_LEAGUE
        EGYPTIAN                -> AdhanMethod.EGYPTIAN
        KARACHI                 -> AdhanMethod.KARACHI
        UMM_AL_QURA             -> AdhanMethod.UMM_AL_QURA
        DUBAI                   -> AdhanMethod.DUBAI
        MOON_SIGHTING_COMMITTEE -> AdhanMethod.MOON_SIGHTING_COMMITTEE
        ISNA                    -> AdhanMethod.NORTH_AMERICA
        KUWAIT                  -> AdhanMethod.KUWAIT
        QATAR                   -> AdhanMethod.QATAR
        SINGAPORE               -> AdhanMethod.SINGAPORE
        TURKEY                  -> AdhanMethod.TURKEY
        TEHRAN                  -> AdhanMethod.TEHRAN
        OTHER                   -> AdhanMethod.OTHER
    }
}
```

### `PrayerSettings.kt`
```kotlin
import kotlinx.serialization.Serializable

enum class AsrMethod { STANDARD, HANAFI }
enum class HighLatitudeRule { MIDDLE_OF_NIGHT, SEVENTH_OF_NIGHT, TWILIGHT_ANGLE, NONE }
enum class AppTheme { LIGHT, DARK, SYSTEM, AUTO }
enum class TimeFormat { HOUR_12, HOUR_24 }
enum class NotificationStyle { FUN, SIMPLE }
enum class PrayerFontSize { SMALL, MEDIUM, LARGE }

@Serializable
data class PrayerNotificationPref(
    val enabled: Boolean = true
)

@Serializable
data class PrayerSettings(
    val calculationMethod: CalculationMethod = CalculationMethod.ISNA,
    val asrMethod: AsrMethod = AsrMethod.STANDARD,
    val highLatitudeRule: HighLatitudeRule = HighLatitudeRule.MIDDLE_OF_NIGHT,
    val theme: AppTheme = AppTheme.SYSTEM,
    val timeFormat: TimeFormat = TimeFormat.HOUR_12,
    val notificationStyle: NotificationStyle = NotificationStyle.FUN,
    val fontSize: PrayerFontSize = PrayerFontSize.MEDIUM,
    val simpleMode: Boolean = false,
    val showIshraq: Boolean = false,
    val customFajrAngle: Double = 15.0,
    val customIshaAngle: Double = 15.0,
    val hijriOffset: Int = 0,
    val prayerNotifications: Map<String, PrayerNotificationPref> = emptyMap()
)
```

### `BackgroundPreset.kt` + `BackgroundTheme.kt`
```kotlin
import androidx.compose.ui.graphics.Color

enum class BackgroundPreset(
    val displayName: String,
    val lightColor: Color,
    val darkColor: Color
) {
    EMERALD("Emerald", Color(0xFFD1FAE5), Color(0xFF064E3B)),
    INDIGO("Indigo",   Color(0xFFE0E7FF), Color(0xFF1E1B4B)),
    ROSE("Rose",       Color(0xFFFFE4E6), Color(0xFF4C0519)),
    AMBER("Amber",     Color(0xFFFEF3C7), Color(0xFF451A03)),
    TEAL("Teal",       Color(0xFFCCFBF1), Color(0xFF042F2E)),
    SLATE("Slate",     Color(0xFFF1F5F9), Color(0xFF0F172A)),
    MIDNIGHT("Midnight", Color(0xFFDBEAFE), Color(0xFF0C1445)),
    PURPLE("Purple",   Color(0xFFF3E8FF), Color(0xFF2E1065))
}

enum class BackgroundVariant { ADAPTIVE, LIGHT, DARK }

@kotlinx.serialization.Serializable
data class BackgroundTheme(
    val preset: BackgroundPreset? = null,
    val variant: BackgroundVariant = BackgroundVariant.ADAPTIVE
)
```

---

## 5. Design System

### `AptaColors.kt`
Map all iOS `AptaColors` and `ThemeColors` to Compose equivalents. The iOS app uses system semantic colors — use `MaterialTheme.colorScheme` equivalents:

| iOS color                  | Android / Compose equivalent                              |
|----------------------------|-----------------------------------------------------------|
| `.label`                   | `MaterialTheme.colorScheme.onBackground`                  |
| `.secondaryLabel`          | `MaterialTheme.colorScheme.onSurfaceVariant`              |
| `.tertiaryLabel`           | `MaterialTheme.colorScheme.outline`                       |
| `.separator`               | `MaterialTheme.colorScheme.outlineVariant`                |
| `.systemBackground`        | `MaterialTheme.colorScheme.background`                    |
| `.secondarySystemBackground` | `MaterialTheme.colorScheme.surface`                     |

### `AptaTypography.kt`
Map iOS font sizes 1:1:
```kotlin
val AptaTypography = Typography(
    // Current prayer large time display
    displayLarge = TextStyle(fontSize = 88.sp, fontWeight = FontWeight.W300, letterSpacing = (-2).sp),
    // Current prayer name label
    labelMedium  = TextStyle(fontSize = 13.sp, fontWeight = FontWeight.W500, letterSpacing = 4.sp),
    // Upcoming prayer rows
    bodyLarge    = TextStyle(fontSize = 17.sp, fontWeight = FontWeight.W400),
    bodyMedium   = TextStyle(fontSize = 15.sp, fontWeight = FontWeight.W400),
    bodySmall    = TextStyle(fontSize = 13.sp, fontWeight = FontWeight.W400),
    // Onboarding title
    headlineLarge = TextStyle(fontSize = 28.sp, fontWeight = FontWeight.W700),
    // Settings section header
    labelSmall   = TextStyle(fontSize = 13.sp, fontWeight = FontWeight.W500)
)
```
The `PrayerFontSize` setting maps to `bodySmall`/`bodyMedium`/`bodyLarge` for prayer name rows.

### `AptaTheme.kt`
```kotlin
@Composable
fun AptaTheme(
    settings: PrayerSettings,
    backgroundTheme: BackgroundTheme,
    content: @Composable () -> Unit
) {
    val systemDark = isSystemInDarkTheme()
    val useDark = when (settings.theme) {
        AppTheme.LIGHT  -> false
        AppTheme.DARK   -> true
        AppTheme.SYSTEM -> systemDark
        AppTheme.AUTO   -> {
            // Use sunrise/sunset to determine — compute via PrayerCalculationService
            // Fall back to system if no location
            systemDark
        }
    }
    MaterialTheme(
        colorScheme = if (useDark) darkColorScheme() else lightColorScheme(),
        typography = AptaTypography,
        content = content
    )
}
```

### `Haptics.kt`
```kotlin
object Haptics {
    fun qiblaTick(context: Context) {
        val v = context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        v.vibrate(VibrationEffect.createOneShot(30, VibrationEffect.DEFAULT_AMPLITUDE))
    }

    fun qiblaFound(context: Context) {
        val v = context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        v.vibrate(VibrationEffect.createWaveform(longArrayOf(0, 50, 30, 80), -1))
    }

    fun selection(context: Context) {
        val v = context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        v.vibrate(VibrationEffect.createOneShot(15, 50))
    }
}
```

---

## 6. Services

### `AppDataStore.kt`
Replaces `SharedDefaults.swift` (App Group UserDefaults):
```kotlin
val Context.dataStore by preferencesDataStore(name = "apta_prefs")

object AppDataStore {
    val ONBOARDING_COMPLETE = booleanPreferencesKey("onboarding_complete")
    val IS_PRO_USER         = booleanPreferencesKey("is_pro_user")
    val PRAYER_SETTINGS_JSON = stringPreferencesKey("prayer_settings_json")
    val BACKGROUND_THEME_JSON = stringPreferencesKey("background_theme_json")
    val CACHED_LATITUDE     = doublePreferencesKey("cached_latitude")
    val CACHED_LONGITUDE    = doublePreferencesKey("cached_longitude")
    val CACHED_CITY_NAME    = stringPreferencesKey("cached_city_name")
    val LOCATION_TIMESTAMP  = longPreferencesKey("location_timestamp")
}
```

### `LocationService.kt`
Replaces `LocationService.swift` (CoreLocation → FusedLocationProviderClient):
```kotlin
class LocationService(private val context: Context) {
    private val fusedClient = LocationServices.getFusedLocationProviderClient(context)

    // Request location permissions at runtime using ActivityResultLauncher in the composable
    // Use ACCESS_FINE_LOCATION for GPS accuracy matching iOS behavior

    suspend fun getCurrentLocation(): Location? {
        // Use fusedClient.getCurrentLocation(Priority.PRIORITY_BALANCED_POWER_ACCURACY, ...)
    }

    // For Qibla heading: use SensorManager with TYPE_ROTATION_VECTOR
    // This replaces CLLocationManager heading updates
    fun startHeadingUpdates(onHeading: (Float) -> Unit): SensorEventListener {
        val sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val rotationSensor = sensorManager.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
        val listener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                val rotationMatrix = FloatArray(9)
                SensorManager.getRotationMatrixFromVector(rotationMatrix, event.values)
                val orientation = FloatArray(3)
                SensorManager.getOrientation(rotationMatrix, orientation)
                val azimuthDeg = Math.toDegrees(orientation[0].toDouble()).toFloat()
                onHeading((azimuthDeg + 360) % 360)
            }
            override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
        }
        sensorManager.registerListener(listener, rotationSensor, SensorManager.SENSOR_DELAY_UI)
        return listener
    }
}
```

### `PrayerCalculationService.kt`
The `adhan-kotlin` library is a direct port of the iOS Adhan library with identical API:
```kotlin
import com.batoulapps.adhan.*
import com.batoulapps.adhan.data.DateComponents

class PrayerCalculationService {

    fun getPrayerTimes(
        latitude: Double,
        longitude: Double,
        date: LocalDate,
        settings: PrayerSettings
    ): PrayerTimes {
        val coordinates = Coordinates(latitude, longitude)
        val dateComponents = DateComponents(date.year, date.monthValue, date.dayOfMonth)

        val params = settings.calculationMethod.toAdhanMethod().parameters.also { p ->
            p.madhab = if (settings.asrMethod == AsrMethod.HANAFI) Madhab.HANAFI else Madhab.SHAFI
            p.highLatitudeRule = settings.highLatitudeRule.toAdhanRule()
            if (settings.calculationMethod == CalculationMethod.OTHER) {
                p.fajrAngle = settings.customFajrAngle
                p.ishaAngle = settings.customIshaAngle
            }
        }
        return PrayerTimes(coordinates, dateComponents, params)
    }

    fun getQiblaDirection(latitude: Double, longitude: Double): Double {
        return Qibla(Coordinates(latitude, longitude)).direction
    }
}
```

Map `HighLatitudeRule`:
```kotlin
fun HighLatitudeRule.toAdhanRule(): com.batoulapps.adhan.HighLatitudeRule = when (this) {
    HighLatitudeRule.MIDDLE_OF_NIGHT  -> com.batoulapps.adhan.HighLatitudeRule.MIDDLE_OF_NIGHT
    HighLatitudeRule.SEVENTH_OF_NIGHT -> com.batoulapps.adhan.HighLatitudeRule.SEVENTH_OF_NIGHT
    HighLatitudeRule.TWILIGHT_ANGLE   -> com.batoulapps.adhan.HighLatitudeRule.TWILIGHT_ANGLE
    HighLatitudeRule.NONE             -> com.batoulapps.adhan.HighLatitudeRule.MIDDLE_OF_NIGHT
}
```

---

## 7. Screens & Navigation

### `RootNavGraph.kt`
Replaces `RootCoordinator.swift`. Use a `NavHost` with sealed class routes:
```kotlin
sealed class Screen(val route: String) {
    object Splash     : Screen("splash")
    object Onboarding : Screen("onboarding")
    object Main       : Screen("main")
}

@Composable
fun RootNavGraph(dataStore: AppDataStore) {
    val navController = rememberNavController()
    NavHost(navController, startDestination = Screen.Splash.route) {
        composable(Screen.Splash.route) {
            SplashScreen(onComplete = { isFirstLaunch ->
                val dest = if (isFirstLaunch) Screen.Onboarding.route else Screen.Main.route
                navController.navigate(dest) {
                    popUpTo(Screen.Splash.route) { inclusive = true }
                }
            })
        }
        composable(Screen.Onboarding.route) {
            OnboardingScreen(onComplete = {
                navController.navigate(Screen.Main.route) {
                    popUpTo(Screen.Onboarding.route) { inclusive = true }
                }
            })
        }
        composable(Screen.Main.route) {
            PrayerTimesScreen()
        }
    }
}
```

---

### `SplashScreen.kt`
The iOS splash animates "apta" letters with staggered opacity + vertical offset. Replicate with Compose `LaunchedEffect` and `AnimatedVisibility` or `animateFloatAsState`:

```kotlin
@Composable
fun SplashScreen(onComplete: (isFirstLaunch: Boolean) -> Unit) {
    val letters = listOf("a", "p", "t", "a")
    val alphas = letters.indices.map { remember { Animatable(0f) } }
    val offsets = letters.indices.map { remember { Animatable(8f) } }  // 8dp down start

    LaunchedEffect(Unit) {
        letters.indices.forEach { i ->
            launch {
                delay(i * 80L)
                launch { alphas[i].animateTo(1f, tween(300)) }
                launch { offsets[i].animateTo(0f, tween(300, easing = EaseOut)) }
            }
        }
        delay(800L)
        // Check onboarding status and call onComplete
    }

    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Row {
            letters.forEachIndexed { i, letter ->
                Text(
                    letter,
                    modifier = Modifier
                        .graphicsLayer { alpha = alphas[i].value }
                        .offset(y = offsets[i].value.dp),
                    style = MaterialTheme.typography.headlineLarge
                )
            }
        }
    }
}
```

---

### Onboarding (`OnboardingScreen.kt`)
Use a `HorizontalPager` (Accompanist or Compose Foundation) with 4 pages, mirroring the iOS `OnboardingContainerView` step-based flow:

**Page 0 — Method Selection** (`OnboardingMethodPage`)
- Title: "Select Your Calculation Method"
- Scrollable list of all 12 `CalculationMethod` values
- Tapping a row selects it (checkmark indicator)
- Auto-suggest method based on device locale (`Locale.getDefault()`)

**Page 1 — Preferences** (`OnboardingPreferencesPage`)
- Asr method picker: Standard / Hanafi
- High latitude rule picker

**Page 2 — Location** (`OnboardingLocationPage`)
- Request `ACCESS_FINE_LOCATION` with `rememberLauncherForActivityResult`
- Show permission rationale text matching iOS strings
- "Allow Location" button → triggers permission request

**Page 3 — Notifications** (`OnboardingNotificationPage`)
- Request `POST_NOTIFICATIONS` permission (Android 13+)
- "Enable Notifications" button
- "Skip" option

Progress indicator at top, "Continue" / "Done" button at bottom.

---

### `PrayerTimesScreen.kt` + `PrayerTimesViewModel.kt`

**ViewModel** (mirrors `PrayerTimesViewModel.swift`):
```kotlin
class PrayerTimesViewModel(
    private val prayerCalcService: PrayerCalculationService,
    private val locationService: LocationService,
    private val dataStore: AppDataStore
) : ViewModel() {

    private val _selectedDate = MutableStateFlow(LocalDate.now())
    val selectedDate = _selectedDate.asStateFlow()

    private val _prayerEntries = MutableStateFlow<List<PrayerTimeEntry>>(emptyList())
    val prayerEntries = _prayerEntries.asStateFlow()

    private val _currentPrayer = MutableStateFlow<PrayerName?>(null)
    val currentPrayer = _currentPrayer.asStateFlow()

    private val _countdown = MutableStateFlow("")
    val countdown = _countdown.asStateFlow()

    private val _qiblaDirection = MutableStateFlow(0.0)
    val qiblaDirection = _qiblaDirection.asStateFlow()

    private val _cityName = MutableStateFlow("")
    val cityName = _cityName.asStateFlow()

    // 1-second ticker using viewModelScope
    init {
        viewModelScope.launch {
            while (true) {
                updateCountdown()
                delay(1000L)
            }
        }
        viewModelScope.launch { loadPrayerTimes() }
    }

    // Advance/retreat date
    fun goToPreviousDay() { _selectedDate.update { it.minusDays(1) } }
    fun goToNextDay()     { _selectedDate.update { it.plusDays(1) } }
    fun goToToday()       { _selectedDate.update { LocalDate.now() } }
}
```

**Screen layout** (mirrors `PrayerTimesView.swift`):
- **Top bar**: city name (center), settings gear (trailing)
- **Date navigation**: left chevron | date string | right chevron
- **Current prayer section**: prayer name label (caps, tracked), large time display (88sp), countdown
- **Qibla strip**: `QiblaStripCompass` composable below current prayer
- **Upcoming prayers list**: `PrayerDayView`
- **Settings**: `ModalBottomSheet` (replaces SwiftUI `.sheet`)

---

### `PrayerDayView.kt`
Displays a list of prayer time rows. Each row:
- Prayer name (left)
- Time string (right, formatted per 12/24h setting)
- Highlight current prayer row (bold or accent color)

```kotlin
@Composable
fun PrayerDayView(
    entries: List<PrayerTimeEntry>,
    currentPrayer: PrayerName?,
    timeFormat: TimeFormat,
    fontSize: PrayerFontSize
) {
    Column {
        entries.forEach { entry ->
            val isCurrent = entry.name == currentPrayer
            PrayerRow(entry, isCurrent, timeFormat, fontSize)
        }
    }
}
```

---

### `QiblaStripCompass.kt`
Custom `Canvas`-based composable — direct translation of iOS `QiblaStripCompass.swift`:

```kotlin
@Composable
fun QiblaStripCompass(
    deviceHeading: Float,   // degrees, from SensorManager
    qiblaDirection: Float,  // degrees, from PrayerCalculationService
    modifier: Modifier = Modifier
) {
    val animatedHeading by animateFloatAsState(
        targetValue = deviceHeading,
        animationSpec = tween(durationMillis = 200, easing = LinearEasing)
    )

    Canvas(modifier = modifier.fillMaxWidth().height(60.dp)) {
        // Draw tick marks for cardinal/intercardinal directions
        // Center the compass so the current heading is at center
        // Mark the Qibla tick in accent color (e.g., green)
        // Match iOS tick sizes: major (N/S/E/W) taller, minor ticks shorter
    }
}
```

Heading stability logic (mirrors iOS):
- Keep a rolling buffer of last N readings
- Only fire haptic if heading changes more than threshold degrees between stable readings
- Fire `Haptics.qiblaFound()` when `|deviceHeading - qiblaDirection| < 2°`

---

### `IslamicCalendarView.kt`
Android has no built-in Hijri calendar widget. Use a `DatePicker` composable from Material3 and convert the selected date to Hijri using `java.util.Calendar` with `UmmAlQuraCalendar`:

```kotlin
// Use android.icu.util.IslamicCalendar (available API 24+)
fun LocalDate.toHijri(): String {
    val islamicCal = android.icu.util.IslamicCalendar()
    islamicCal.time = java.util.Date.from(
        this.atStartOfDay(ZoneId.systemDefault()).toInstant()
    )
    // islamicCal.get(IslamicCalendar.YEAR), MONTH, DAY_OF_MONTH
    return "${islamicCal.get(IslamicCalendar.DAY_OF_MONTH)} " +
           "${islamicMonthName(islamicCal.get(IslamicCalendar.MONTH))} " +
           "${islamicCal.get(IslamicCalendar.YEAR)} AH"
}
```

Wrap Material3's `DatePicker` in a `Dialog` composable. Apply the `hijriOffset` setting by offsetting the displayed Hijri date.

---

### `SettingsSheet.kt`
Shown as `ModalBottomSheet`. Sections mirror iOS `SettingsView`:

1. **Apta Pro** — "Unlock Custom Backgrounds" button; if pro, show checkmark
2. **Appearance** — Theme picker, time format toggle, font size picker, simple mode toggle
3. **Prayer Calculation** — Calculation method, Asr method, high latitude rule, custom angles (if OTHER)
4. **Notifications** — Style picker (Fun/Simple), per-prayer toggles, Ramadan notification section
5. **App Info** — Version, restore purchases, feedback link

Use `LazyColumn` with `ListItem` for settings rows, `HorizontalDivider` between sections.

---

### `BackgroundSettingsSheet.kt`
Shown as another `ModalBottomSheet` from within SettingsSheet. Grid of 8 preset color swatches (2×4), each showing the light and dark color side by side. Tapping selects the preset. A "Variant" row below lets user choose Adaptive / Light / Dark. Pro gate: blur overlay + "Unlock Pro" button if not pro user.

---

## 8. Notifications

### `NotificationScheduler.kt`
Replaces `NotificationScheduler.swift`. Schedule `AlarmManager` exact alarms for each prayer (3 days ahead):

```kotlin
class NotificationScheduler(private val context: Context) {

    fun scheduleNotifications(
        prayerSettings: PrayerSettings,
        latitude: Double,
        longitude: Double
    ) {
        cancelAll()
        val calcService = PrayerCalculationService()
        val today = LocalDate.now()

        repeat(3) { dayOffset ->
            val date = today.plusDays(dayOffset.toLong())
            val times = calcService.getPrayerTimes(latitude, longitude, date, prayerSettings)
            PrayerName.values()
                .filter { it != PrayerName.SUNRISE }
                .forEach { prayer ->
                    val pref = prayerSettings.prayerNotifications[prayer.name]
                    if (pref?.enabled != false) {
                        val time = times.timeForPrayer(prayer.toAdhanPrayer()) ?: return@forEach
                        scheduleAlarm(prayer, time, prayerSettings.notificationStyle, date)
                    }
                }
        }
    }

    private fun scheduleAlarm(prayer: PrayerName, time: Date, style: NotificationStyle, date: LocalDate) {
        val intent = Intent(context, NotificationReceiver::class.java).apply {
            putExtra("prayer_name", prayer.displayName)
            putExtra("message", NotificationMessages.pick(prayer, date, style))
        }
        val pi = PendingIntent.getBroadcast(
            context,
            requestCodeFor(prayer, date),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, time.time, pi)
    }

    fun cancelAll() { /* cancel all pending intents */ }
}
```

### `NotificationMessages.kt`
Port the date-seeded message logic from iOS:
```kotlin
object NotificationMessages {
    fun pick(prayer: PrayerName, date: LocalDate, style: NotificationStyle): String {
        if (style == NotificationStyle.SIMPLE) return "${prayer.displayName} time"
        val seed = date.toEpochDay() * 10 + prayer.ordinal
        val messages = funMessagesFor(prayer)
        return messages[(seed % messages.size).toInt()]
    }

    private fun funMessagesFor(prayer: PrayerName): List<String> = when (prayer) {
        PrayerName.FAJR    -> listOf("Rise and shine! Fajr time 🌙", /* ... */)
        PrayerName.DHUHR   -> listOf("Midday check-in!", /* ... */)
        // ... mirror all iOS notification messages from NotificationMessages.swift
        else -> listOf("${prayer.displayName} time")
    }
}
```

Port the exact messages from `NotificationMessages.swift` to keep the 1:1 parity.

---

## 9. In-App Purchases (Pro)

### `PurchaseManager.kt`
Replaces `PurchaseManager.swift` (StoreKit 2 → Play Billing Library):

```kotlin
class PurchaseManager(private val context: Context) {

    // Product ID — create this in Google Play Console
    // Match the feature set: unlocks custom backgrounds
    val PRO_PRODUCT_ID = "com.gazi.apta.pro"  // set your actual product ID

    private val billingClient = BillingClient.newBuilder(context)
        .setListener { billingResult, purchases ->
            if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                purchases?.forEach { handlePurchase(it) }
            }
        }
        .enablePendingPurchases()
        .build()

    private val _isProUser = MutableStateFlow(false)
    val isProUser = _isProUser.asStateFlow()

    fun startConnection() {
        billingClient.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(result: BillingResult) {
                if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                    queryExistingPurchases()
                }
            }
            override fun onBillingServiceDisconnected() {}
        })
    }

    fun launchPurchaseFlow(activity: Activity) {
        // Query product details then launch billing flow
    }

    private fun handlePurchase(purchase: Purchase) {
        if (purchase.purchaseState == Purchase.PurchaseState.PURCHASED) {
            _isProUser.value = true
            if (!purchase.isAcknowledged) {
                // Acknowledge the purchase
            }
        }
    }
}
```

> **Note**: Create the subscription or one-time product in the Google Play Console with product ID `com.gazi.apta.pro`. The feature unlock (custom backgrounds) is identical to iOS.

---

## 10. Widgets

### `PrayerWidget.kt`
Use **Glance** (Jetpack's widget API, Compose-based) to replicate iOS WidgetKit widgets.

Create the following widget sizes (mirrors iOS widget targets):
| iOS Widget          | Android Glance equivalent        |
|---------------------|----------------------------------|
| Small (next prayer) | `SizeMode.Single` 2×1 cell       |
| Medium (today list) | `SizeMode.Responsive` 4×2 cells  |
| Large (full day)    | `SizeMode.Responsive` 4×4 cells  |

```kotlin
class PrayerWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val entries = /* read from DataStore */ listOf<PrayerTimeEntry>()
            SmallPrayerWidgetContent(entries)
        }
    }
}

@Composable
private fun SmallPrayerWidgetContent(entries: List<PrayerTimeEntry>) {
    Column(modifier = GlanceModifier.fillMaxSize().padding(12.dp)) {
        val next = entries.firstOrNull { it.time > LocalTime.now() }
        Text(next?.name?.displayName ?: "–")
        Text(next?.time?.toString() ?: "–")
    }
}
```

Schedule widget updates via `WorkManager` every 15 minutes and on each prayer time boundary.

---

## 11. Platform Equivalency Reference

| iOS / Swift                        | Android / Kotlin                              |
|------------------------------------|-----------------------------------------------|
| `SwiftUI`                          | `Jetpack Compose`                             |
| `@StateObject` / `@ObservedObject` | `viewModel()` + `collectAsStateWithLifecycle` |
| `@Published`                       | `StateFlow` / `MutableStateFlow`              |
| `UserDefaults` / App Group         | `DataStore<Preferences>`                      |
| `Codable` / JSON encoding          | `@Serializable` (kotlinx.serialization)       |
| `CoreLocation`                     | `FusedLocationProviderClient` (Play Services) |
| `CLLocationManager` heading        | `SensorManager` TYPE_ROTATION_VECTOR          |
| `UNUserNotificationCenter`         | `NotificationManagerCompat` + `AlarmManager`  |
| `StoreKit 2`                       | `Play Billing Library 6+`                     |
| `WidgetKit`                        | `Glance AppWidget`                            |
| `WatchConnectivity`                | Wear OS `ChannelClient` / `MessageClient`     |
| `UICalendarView` (Hijri)           | `android.icu.util.IslamicCalendar`            |
| `UIViewRepresentable`              | `AndroidView` composable                      |
| `Canvas` (SwiftUI)                 | `Canvas` (Compose)                            |
| `UIImpactFeedbackGenerator`        | `Vibrator` / `VibrationEffect`                |
| `NavigationStack`                  | `NavHost` + `NavController`                   |
| `.sheet`                           | `ModalBottomSheet`                            |
| `HStack` / `VStack` / `ZStack`     | `Row` / `Column` / `Box`                      |
| `LazyVStack`                       | `LazyColumn`                                  |
| `GeometryReader`                   | `BoxWithConstraints`                          |
| `animatable` / `withAnimation`     | `Animatable` / `animate*AsState`              |
| `Timer.publish`                    | `while(true) { delay(1000) }` in coroutine    |
| Adhan iOS library                  | `adhan-kotlin` (same API, direct port)        |

---

## Implementation Order

Build in this sequence to minimize rework:

1. **Data layer** — models, DataStore, PrayerCalculationService
2. **Design system** — colors, typography, theme
3. **Navigation skeleton** — RootNavGraph with placeholder screens
4. **Splash screen** — letter animation
5. **Onboarding flow** — all 4 pages, permissions
6. **Main prayer screen** — ViewModel, PrayerDayView, current prayer UI
7. **Qibla compass** — Canvas component, heading sensor integration
8. **Islamic calendar** — date picker overlay with Hijri conversion
9. **Settings sheet** — all settings wired to DataStore
10. **Notifications** — scheduler, receiver, boot receiver, messages
11. **Background themes (Pro)** — BackgroundSettingsSheet, theme application
12. **In-app purchases** — billing integration, pro gate
13. **Widgets** — Glance widget, WorkManager update scheduling
