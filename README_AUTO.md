# pide_claudia

*Documentación generada automáticamente - 2025-10-03 16:51:04.193690*

## 📊 Resumen del Proyecto

- **Total de archivos Dart:** 36
- **Características detectadas:** 5
- **Tareas pendientes:** 0

## 🚀 Características Implementadas

- **Product management** (8 archivos)
- **Shopping cart** (10 archivos)
- **Admin panel** (3 archivos)
- **Authentication** (2 archivos)
- **Delivery system** (3 archivos)

## 📁 Estructura del Proyecto

```
lib/
├── lib\data\christian_messages.dart
├── lib\data\mock_products.dart
├── lib\firebase_options.dart
├── lib\main.dart
├── lib\models\cart_item.dart
├── lib\models\inventory_product.dart
├── lib\models\order.dart
├── lib\models\product.dart
├── lib\providers\cart_provider.dart
├── lib\providers\order_provider.dart
├── lib\providers\role_provider.dart
├── lib\screens\admin_home_screen.dart
├── lib\screens\admin_metrics_screen.dart
├── lib\screens\admin_orders_screen.dart
├── lib\screens\auth_gate.dart
├── lib\screens\custom_order_screen.dart
├── lib\screens\delivery_config_screen.dart
├── lib\screens\driver_home_screen.dart
├── lib\screens\driver_order_detail_screen.dart
├── lib\screens\driver_register_screen.dart
├── lib\screens\home_screen.dart
├── lib\screens\inventory_screen.dart
├── lib\screens\login_screen.dart
├── lib\screens\menu_screen.dart
├── lib\screens\migrate_products_to_firestore.dart
├── lib\screens\order_history_screen.dart
├── lib\screens\order_summary_screen.dart
├── lib\screens\order_tracking_screen.dart
├── lib\screens\product_detail_screen.dart
├── lib\screens\register_screen.dart
├── lib\screens\reset_password_screen.dart
├── lib\services\inventory_service.dart
├── lib\services\store_service.dart
├── lib\services\store_settings_screen.dart
├── lib\widgets\product_card.dart
├── lib\widgets\store_status_widget.dart

```

## 🔧 Próximos Pasos Sugeridos

- ✅ Todas las tareas detectadas están completadas
- 🚀 Considera agregar nuevas funcionalidades

---

*Este documento se genera automáticamente. Ejecuta `dart doc_generator.dart` para actualizar.*

🧑‍🍳 Platos de Claudia - Catálogo de Cocina

Aplicación móvil desarrollada en Flutter para mostrar el catálogo de comidas, bebidas y platos especiales del restaurante La Cocina de Claudia.
La app permite que los usuarios seleccionen productos, personalicen su pedido, elijan métodos de pago y dirección de entrega.

🚨 Problema encontrado

Durante la instalación de la aplicación en un dispositivo Android, el archivo generado con el comando:

flutter build apk


generaba un APK en modo debug (app-debug.apk) que no se podía instalar en el celular.
El error se debía a que las aplicaciones debug solo se pueden instalar si el dispositivo tiene activado el modo desarrollador y depuración USB.

🧩 Análisis

Se confirmó que la app compilaba correctamente, pero al intentar instalarla manualmente desde el celular, aparecía el mensaje:
"No se pudo instalar la aplicación".

Verificando la carpeta /build/app/outputs/flutter-apk/, se observó que el archivo generado era app-debug.apk.

Las versiones debug son útiles solo para pruebas conectadas a VSCode o Android Studio, no para instalación final.

✅ Solución aplicada

Se generó la versión release (instalable para usuarios finales) ejecutando el siguiente comando desde la raíz del proyecto:

flutter build apk --release


Esto produjo el archivo:

build/app/outputs/flutter-apk/app-release.apk


El cual puede instalarse normalmente en cualquier dispositivo Android.

📲 Instalación del APK en el celular

Existen dos opciones:

🔹 Opción 1: Manual

Copiar el archivo app-release.apk al celular y abrirlo directamente desde el explorador de archivos.

🔹 Opción 2: Usando ADB (con el celular conectado por USB)
adb install build/app/outputs/flutter-apk/app-release.apk

🔐 (Opcional) Firma del APK

Para futuras publicaciones en Google Play Store, se debe firmar el APK con una clave propia.
El proceso consiste en generar un archivo key.properties y configurarlo en android/app/build.gradle.

📦 Resultado Final

✅ La app se ejecuta correctamente en dispositivos Android.

✅ Se solucionó el problema de instalación del modo debug.

✅ Se generó correctamente el archivo app-release.apk.

🧠 Aprendizaje

Las versiones debug son solo para pruebas con cable o emulador.

Para distribuir la app, siempre se debe generar el release build.

Documentar cada paso ayuda a mantener trazabilidad y facilita futuras actualizaciones.



ARCHIVOS CRITICOS PARA TENNER ENCUENTA 

ANDOID/build.gradle.kts
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}


ANDOID/APP/build.gradle.kts
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.waypoint.pide_claudia"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.waypoint.pide_claudia"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
    implementation(platform("com.google.firebase:firebase-bom:33.6.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-storage")
}
apply(plugin = "com.google.gms.google-services")


ANDOID/APP/google-services.json
{
  "project_info": {
    "project_number": "842578828696",
    "project_id": "pideclaudia-e1921",
    "storage_bucket": "pideclaudia-e1921.firebasestorage.app"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:842578828696:android:551a6a860cc89a7f161fed",
        "android_client_info": {
          "package_name": "com.waypoint.pide_claudia"
        }
      },
      "oauth_client": [],
      "api_key": [
        {
          "current_key": "AIzaSyADSGc_yE4uHe29WVyq75UWgrMQRRzim5M"
        }
      ],
      "services": {
        "appinvite_service": {
          "other_platform_oauth_client": []
        }
      }
    }
  ],
  "configuration_version": "1"
}


🧾 Registro de actualización técnica

Fecha: (30/10/2025)
Descripción del cambio:

Se realizó un ajuste general en el proyecto, enfocado en la mejora de la interfaz de usuario (UI) y la optimización de la presentación visual de los componentes.

Se corrigieron y reorganizaron las tarjetas (cards) para mejorar la consistencia del diseño y la experiencia de usuario (UX).

Se implementaron ajustes visuales y de estilo con el objetivo de lograr una interfaz más limpia, legible y funcional.

Se formatearon valores numéricos en tres archivos del proyecto para garantizar una presentación uniforme (uso de separadores de miles y formato de moneda).

Resultado:
El sistema presenta ahora una interfaz más intuitiva y estética, con una mejor disposición de los elementos visuales y datos correctamente formateados.


ANDROID/SRC/MAIN/AndroidManifest.xml

<!-- <manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="pide_claudia"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <!-- Specifies an Android theme to apply to this Activity as soon as
                 the Android process has started. This theme is visible to the user
                 while the Flutter UI initializes. After that, this theme continues
                 to determine the Window background behind the Flutter UI. -->
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <!-- Don't delete the meta-data below.
             This is used by the Flutter tool to generate GeneratedPluginRegistrant.java -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
    <!-- Required to query activities that can process text, see:
         https://developer.android.com/training/package-visibility and
         https://developer.android.com/reference/android/content/Intent#ACTION_PROCESS_TEXT.

         In particular, this is used by the Flutter engine in io.flutter.plugin.text.ProcessTextPlugin. -->
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
    </queries>
</manifest> -->
