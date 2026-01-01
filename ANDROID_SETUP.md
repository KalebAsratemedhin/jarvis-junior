# Android Setup Guide for Flutter

## Quick Setup Steps

### Step 1: Install Android SDK Command Line Tools

You have two options:

#### Option A: Install Android Studio (Easier, Recommended)
1. Download Android Studio from: https://developer.android.com/studio
2. Install it (you can use the snap package):
   ```bash
   sudo snap install android-studio --classic
   ```
3. Open Android Studio and follow the setup wizard
4. It will automatically install the Android SDK

#### Option B: Install Command Line Tools Only (Lighter)
```bash
# Install required packages
sudo apt update
sudo apt install -y wget unzip openjdk-17-jdk

# Create Android SDK directory
mkdir -p ~/Android/Sdk
cd ~/Android/Sdk

# Download command line tools
wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip commandlinetools-linux-11076708_latest.zip
mkdir -p cmdline-tools/latest
mv cmdline-tools/* cmdline-tools/latest/ 2>/dev/null || true

# Set environment variables (add to ~/.bashrc)
echo 'export ANDROID_HOME=$HOME/Android/Sdk' >> ~/.bashrc
echo 'export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin' >> ~/.bashrc
echo 'export PATH=$PATH:$ANDROID_HOME/platform-tools' >> ~/.bashrc
source ~/.bashrc

# Install SDK components
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
```

### Step 2: Configure Flutter to use Android SDK

After installing the SDK, tell Flutter where it is:

```bash
# If using Android Studio (default location):
flutter config --android-sdk ~/Android/Sdk

# Or if Android Studio installed it elsewhere, find it:
# find ~ -name "platform-tools" -type d 2>/dev/null | head -1
```

### Step 3: Accept Android Licenses

```bash
flutter doctor --android-licenses
# Press 'y' to accept all licenses
```

### Step 4: Enable USB Debugging on Your Phone

1. **Enable Developer Options:**
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times
   - You'll see "You are now a developer!"

2. **Enable USB Debugging:**
   - Go to Settings → Developer Options
   - Enable "USB Debugging"
   - Enable "Install via USB" (if available)

3. **Connect Your Phone:**
   - Connect your phone to your computer via USB
   - On your phone, when prompted, tap "Allow USB Debugging"
   - Check "Always allow from this computer"

### Step 5: Verify Connection

```bash
# Install adb if not already installed
sudo apt install android-tools-adb

# Check if your phone is detected
adb devices

# You should see your device listed
```

### Step 6: Run the App

```bash
# Check available devices
flutter devices

# Run on your phone
flutter run
```

## Troubleshooting

### Phone Not Detected?
1. Make sure USB debugging is enabled
2. Try a different USB cable
3. Try different USB ports
4. On your phone: Settings → Developer Options → Revoke USB debugging authorizations, then reconnect

### Permission Denied?
```bash
# Add your user to plugdev group
sudo usermod -aG plugdev $USER
# Log out and back in for this to take effect
```

### Still Having Issues?
Run `flutter doctor -v` to see detailed information about what's missing.













