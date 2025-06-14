# Journey Mate App 🚗🌍

Welcome to **Journey Mate App**, a Flutter-based application designed to revolutionize your travel experience. Whether you're looking to create rides, search for available rides, or chat with fellow travelers, Journey Mate App has got you covered. This app is built with cutting-edge technologies and offers seamless integration with Firebase, Mapbox, and other powerful tools.

---

## 🌟 Features

### 🚀 Core Features
- **User Authentication**: Secure login and signup using Firebase Authentication.
- **Ride Creation**: Create rides with detailed information like origin, destination, date, time, and price.
- **Ride Search**: Search for available rides based on your preferences.
- **Live Map Integration**: View rides and user locations on an interactive Mapbox map.
- **Chat System**: Communicate with other users via real-time chat for each ride.
- **Profile Management**: View and manage your profile details, including profile picture and car details.
- **Booking Confirmation**: Confirm your ride bookings with ease.
- **Admin Controls**: Manage users, block/unblock accounts, and verify user profiles.

### 🌐 Multi-Platform Support
- **Android**: Optimized for Android devices.
- **iOS**: Fully compatible with iOS devices.
- **Web**: Accessible via web browsers.
- **Windows, macOS, Linux**: Desktop support for a complete cross-platform experience.

---

## 🛠️ Tech Stack

### 📱 Frontend
- **Flutter**: A powerful UI toolkit for building natively compiled applications.
- **Dart**: The programming language behind Flutter.

### 🔥 Backend
- **Firebase**:
  - Authentication
  - Firestore Database
  - Realtime Database
  - Firebase Storage

### 🗺️ Map Integration
- **Mapbox**: Interactive maps and geolocation services.

### 📡 Connectivity
- **Connectivity Plus**: Network status monitoring.

---

## 📂 Project Structure

```
lib/
├── main.dart
├── firebase_options.dart
├── models/
│   ├── ride.dart
│   └── user.dart
├── screens/
│   ├── home_screen.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── profile_screen.dart
│   ├── ride_creation_screen.dart
│   └── ride_search_screen.dart
├── services/
│   ├── auth_service.dart
│   ├── database_service.dart
│   ├── ride_service.dart
│   └── chat_service.dart
├── widgets/
│   ├── custom_button.dart
│   ├── custom_input_field.dart
│   ├── ride_tile.dart
│   └── user_tile.dart
└── utils/
    ├── constants.dart
    └── helpers.dart
```

### System Design Diagram

#### **Basic System Design**

```plaintext
+---------------------+       +---------------------+       +---------------------+
|                     |       |                     |       |                     |
|   Flutter Frontend  |       | Firebase Services   |       | Third-Party APIs    |
|                     |       |                     |       |                     |
|---------------------|       |---------------------|       |---------------------|
| - UI Components     |       | - Authentication    |       | - Mapbox API        |
| - Screens           |       | - Firestore DB      |       | - Geocoding         |
| - Widgets           |       | - Realtime DB       |       | - Directions        |
|                     |       | - Firebase          |Storage  |       |                     |
+---------------------+       +---------------------+       +---------------------+

        |                           |                           |
        |                           |                           |
        +---------------------------+---------------------------+
                                |
                                |
                        +---------------------+
                        |                     |
                        |  Backend Services   |
                        |                     |
                        |---------------------|
                        | - Ride Service      |
                        | - Chat Service      |
                        | - Location Service  |
                        | - Admin Service     |
                        | - Storage Service   |
                        +---------------------+
```

#### **Advanced System Design**

```plaintext
+---------------------------------------------------+
|                   Frontend Layer                  |
|---------------------------------------------------|
| Flutter App                                       |
| - Screens: Login, Signup, Home, Profile, Rides    |
| - Widgets: UserCard, RideCard, LoadingDialog      |
| - Navigation: FIFO for chat messages, LIFO for    |
|   screen transitions                              |
+---------------------------------------------------+
                           |
                           |
                           v
+---------------------------------------------------+
|                   Backend Layer                   |
|---------------------------------------------------|
| Firebase Services                                 |
| - Authentication: User login/signup               |
| - Firestore DB: Structured data storage           |
| - Realtime DB: Real-time updates for location     |
| - Firebase Storage: File uploads (e.g., profile   |
|   pictures, documents)                            |
|---------------------------------------------------|
| Backend Services                                  |
| - Ride Service: Create/Search/Book rides          |
| - Chat Service: Real-time messaging               |
| - Location Service: Track user locations          |
| - Admin Service: Manage users                     |
| - Storage Service: Upload/retrieve documents      |
+---------------------------------------------------+
                           |
                           |
                           v
+---------------------------------------------------+
|           Third-Party Integration Layer           |
|---------------------------------------------------|
| Mapbox API                                        |
| - Geocoding: Convert addresses to coordinates     |
| - Directions: Calculate routes and distances      |
| - Maps: Render interactive maps                   |
+---------------------------------------------------+

```

---

## 📸 Screenshots

Here are some screenshots of the Journey Mate App to give you a glimpse of its features and design. Replace the placeholder text with actual screenshots when available.

### Home Screen
![Home Screen](assets/screenshots/home_screen.png)
- **Description**: The home screen provides an overview of the app, including quick access to ride creation, ride search, and user profile.

### Login Screen
![Login Screen](assets/screenshots/login_screen.png)
- **Description**: The login screen allows users to securely log in using their credentials.

### Signup Screen
![Signup Screen](assets/screenshots/signup_screen.png)
- **Description**: The signup screen enables new users to create an account with required details.

### Profile Screen
![Profile Screen](assets/screenshots/profile_screen.png)
- **Description**: The profile screen displays user information, including name, email, and car details. Users can edit their profile here.

### Ride Creation Screen
![Ride Creation Screen](assets/screenshots/ride_creation_screen.png)
- **Description**: The ride creation screen allows users to create a new ride by entering details like origin, destination, date, and time.

### Ride Search Screen
![Ride Search Screen](assets/screenshots/ride_search_screen.png)
- **Description**: The ride search screen helps users find available rides based on their preferences.

### Chat Screen
![Chat Screen](assets/screenshots/chat_screen.png)
- **Description**: The chat screen enables real-time communication between users for a specific ride.

### Booking Confirmation Screen
![Booking Confirmation Screen](assets/screenshots/booking_confirmation_screen.png)
- **Description**: The booking confirmation screen allows users to confirm their ride bookings and view ride details.

---

To add screenshots:
1. Save your screenshots in the `assets/screenshots/` directory.
2. Replace the placeholder image paths (`assets/screenshots/...`) with the actual file names.

For example:
```markdown
![Home Screen](assets/screenshots/home_screen.png)
```

---

## 🚀 Getting Started

To get started with Journey Mate App, follow these steps:

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/journey_mate_app_v1.git
   ```
2. **Navigate to the project directory**:
   ```bash
   cd journey_mate_app_v1
   ```
3. **Install the dependencies**:
   ```bash
   flutter pub get
   ```
4. **Set up Firebase**:
   - Create a new Firebase project.
   - Add your app to the Firebase project (Android, iOS, Web).
   - Download the `google-services.json` and `GoogleService-Info.plist` files and place them in the respective directories.
   - Enable the required Firebase services (Authentication, Firestore, Storage, etc.).
5. **Set up Mapbox**:
   - Create a Mapbox account and get your access token.
   - Enable the required Mapbox services (Maps, Geocoding, etc.).
6. **Run the app**:
   ```bash
   flutter run
   ```

For detailed instructions, refer to the [documentation](docs/).

---



---

## 🤝 Contributing

We welcome contributions to improve Journey Mate App! To contribute:

1. **Fork the repository**:
   - Click the "Fork" button at the top-right corner of the repository page.

2. **Clone your forked repository**:
   ```bash
   git clone https://github.com/yourusername/journey_mate_app_v1.git
   ```

3. **Create a new branch**:
   ```bash
   git checkout -b feature-name
   ```

4. **Make your changes**:
   - Add new features, fix bugs, or improve documentation.

5. **Commit your changes**:
   ```bash
   git commit -m "Add feature-name"
   ```

6. **Push your changes**:
   ```bash
   git push origin feature-name
   ```

7. **Create a pull request**:
   - Go to the original repository and click "New Pull Request."
   - Provide a detailed description of your changes.


---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev/) - The UI toolkit used to build the app.
- [Firebase](https://firebase.google.com/) - The backend platform for app development.
- [Mapbox](https://www.mapbox.com/) - The mapping and location data platform.
- [OpenAI](https://openai.com/) - For providing the AI assistance in app development.

---

## 📞 Contact

For any inquiries or feedback, please reach out:

- Email: support@journeymateapp.com
- Twitter: [@journeymateapp](https://twitter.com/journeymateapp)
- Facebook: [Journey Mate App](https://facebook.com/journeymateapp)

---

Thank you for choosing Journey Mate App. We wish you safe and happy travels!

---

## 👥 Contributors

This project is developed collaboratively by the following team members:

1. **Amitabha Jana** - Project Lead & Backend Developer  
   - **Contributions**: Led the project, developed backend services, coordinated development efforts, and worked on database integration and real-time features.

2. **Rahul Kumar** - Frontend Developer  
   - **Contributions**: Worked on UI components, screens, and overall frontend design.

3. **Hrithik Bhowmik** - QA Tester  
   - **Contributions**: Conducted extensive testing to ensure the app's functionality and quality.

4. **Srilakha Bishwas** - UI/UX Designer  
   - **Contributions**: Designed the app's user interface and provided feedback on user experience improvements.

5. **Pabitra Kumar Sarkar** - Market Researcher  
   - **Contributions**: Conducted market research and provided external insights to improve app usability and reach.

---
