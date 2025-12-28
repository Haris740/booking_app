<div align="center">
  <h1>🏥 Professional Booking App</h1>
  <p><strong>A modern Flutter app for booking appointments with professionals across various fields</strong></p>
  
  ![Flutter](https://img.shields.io/badge/Flutter-3.33.0-02569B?style=for-the-badge&logo=flutter&logoColor=white)
  ![Node.js](https://img.shields.io/badge/Node.js-Express-339933?style=for-the-badge&logo=node.js&logoColor=white)
  ![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Database-336791?style=for-the-badge&logo=postgresql&logoColor=white)
  ![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)
  
  <p>
    <a href="#features">Features</a> •
    <a href="#screenshots">Screenshots</a> •
    <a href="#getting-started">Getting Started</a> •
    <a href="#tech-stack">Tech Stack</a> •
    <a href="#contributing">Contributing</a>
  </p>
</div>

---

## 📋 Overview

Professional Booking App is a cross-platform mobile application that connects users with verified professionals across multiple domains including doctors, lawyers, tutors, therapists, and technicians. Built with Flutter and powered by a robust Node.js/Express backend with PostgreSQL, the app streamlines the appointment booking process with real-time token tracking and location-based search.

### ✨ Key Highlights

- 🔐 **Secure OTP Authentication** - Phone number-based login with SMS verification
- 🌍 **GPS-Enabled Location** - Automatic city detection for personalized results
- 👥 **Dual User Roles** - Users can book appointments AND become verified professionals
- ⚡ **Real-time Search** - Instant professional discovery with advanced filters
- 🎫 **Token System** - Queue management for efficient appointment scheduling
- 📱 **Modern UI/UX** - Clean blue-green theme with smooth animations

---

## 🎯 Features

### For Users
- **Phone OTP Login** - Quick and secure authentication without passwords
- **Smart Search** - Find professionals by name, category, city, or specialty
- **GPS Location** - Auto-detect your city or manually enter it
- **Profile Management** - Update name, email, city, and preferences
- **Booking History** - Track all your appointments in one place
- **Saved Favorites** - Bookmark your preferred professionals

### For Professionals
- **Easy Onboarding** - Simple application process with admin verification
- **Profile Customization** - Showcase experience, fees, and services
- **Consultation Modes** - Offer online, offline, or both options
- **Category Tags** - Highlight specialties (24/7, emergency, home visits, etc.)
- **Booking Management** - Dashboard to handle appointments and schedules

### Admin Features
- **Application Review** - Approve/reject professional profiles
- **User Management** - Monitor platform activity
- **Analytics Dashboard** - Track growth and engagement metrics

---

## 📱 Screenshots

<div align="center">
  <img src="screenshots/welcome.png" width="200" alt="Welcome Screen"/>
  <img src="screenshots/login.png" width="200" alt="Login"/>
  <img src="screenshots/home.png" width="200" alt="Home"/>
  <img src="screenshots/search.png" width="200" alt="Search"/>
</div>

---

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (3.0 or higher) - [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Android Studio** or **Xcode** (for mobile development)
- **Git** - [Install Git](https://git-scm.com/downloads)
- **Node.js** (v18+) and **npm** - [Install Node](https://nodejs.org/)
- **PostgreSQL** (v14+) - [Install PostgreSQL](https://www.postgresql.org/download/)

### Installation

#### 1️⃣ Clone the Repository

git clone https://github.com/yourusername/doctor_booking_app.git
cd doctor_booking_app

text

#### 2️⃣ Install Flutter Dependencies

flutter pub get

text

#### 3️⃣ Backend Setup

The backend is hosted separately. API Base URL:

https://booking-backend-0b9z.onrender.com

text

For local backend development, see [Backend Repository](https://github.com/yourusername/booking-backend).

#### 4️⃣ Configure Environment (Optional)

Create a `.env` file in the project root if you want to customize the API endpoint:

API_BASE_URL=https://booking-backend-0b9z.onrender.com

text

#### 5️⃣ Run the App

Check for issues
flutter doctor

Run on connected device/emulator
flutter run

Build for release
flutter build apk --release # Android
flutter build ios --release # iOS

text

---

## 🛠️ Tech Stack

### Frontend (Flutter)
- **Framework:** Flutter 3.33.0
- **Language:** Dart
- **State Management:** BLoC Pattern
- **HTTP Client:** http package
- **Local Storage:** shared_preferences
- **Location Services:** geolocator, geocoding
- **UI Components:** Material Design 3

### Backend (Node.js + Express)
- **Runtime:** Node.js v18+
- **Framework:** Express.js
- **Database:** PostgreSQL with Prisma ORM
- **Authentication:** JWT (Access + Refresh Tokens)
- **OTP Service:** SMS Gateway Integration
- **Hosting:** Render

### Architecture
- **Design Pattern:** Feature-based modular architecture
- **API Style:** RESTful API
- **Authentication Flow:** Phone OTP → JWT Tokens
- **Data Flow:** User → API Client → Backend → PostgreSQL

---

## 📂 Project Structure

lib/
├── main.dart # App entry point
├── app.dart # Root widget
├── core/
│ ├── theme/
│ │ └── app_theme.dart # Blue-green theme
│ └── constants/
│ └── app_constants.dart
├── features/
│ ├── onboarding/
│ │ └── presentation/
│ │ └── welcome_screen.dart
│ ├── auth/
│ │ └── presentation/
│ │ ├── login_screen.dart # Phone OTP login
│ │ ├── otp_screen.dart # OTP verification
│ │ └── registration_screen.dart
│ ├── user/
│ │ └── presentation/
│ │ ├── user_home_screen.dart
│ │ ├── professional_search_screen.dart
│ │ └── profile_screen.dart
│ └── professional/
│ └── presentation/
│ └── become_professional_screen.dart
└── services/
└── api_client.dart # HTTP service layer

text

---

## 🔑 Key API Endpoints

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| `POST` | `/auth/send-otp` | Send OTP to phone | No |
| `POST` | `/auth/verify-otp` | Verify OTP & get tokens | No |
| `POST` | `/auth/register` | Complete user profile | Yes |
| `POST` | `/professional/apply` | Apply to be professional | Yes |
| `GET` | `/professional` | Search professionals | No |
| `GET` | `/professional/:id` | Get professional details | No |
| `POST` | `/bookings` | Create booking | Yes |
| `GET` | `/bookings/me` | Get user bookings | Yes |
| `GET` | `/admin/professionals/pending` | Get pending approvals | Admin |
| `POST` | `/admin/professionals/:id/approve` | Approve professional | Admin |

---

## 🧪 Testing

Run tests with:

Unit tests
flutter test

Integration tests
flutter test integration_test

text

---

## 🤝 Contributing

We welcome contributions! Here's how you can help:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/AmazingFeature`)
3. **Commit** your changes (`git commit -m 'Add some AmazingFeature'`)
4. **Push** to the branch (`git push origin feature/AmazingFeature`)
5. **Open** a Pull Request

### Development Guidelines

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) style guide
- Write meaningful commit messages
- Add comments for complex logic
- Test your changes before submitting PR
- Update documentation if needed

---

## 🐛 Known Issues & Roadmap

### Current Limitations
- OTP is currently hardcoded in development (`123456`)
- Location permissions require manual grant on first launch
- Admin panel is backend-only (no mobile UI yet)

### Upcoming Features
- [ ] In-app chat with professionals
- [ ] Payment gateway integration
- [ ] Push notifications for appointments
- [ ] Review & rating system
- [ ] Multi-language support (Hindi, Malayalam)
- [ ] Video consultation feature
- [ ] Calendar integration

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**Your Name**

- GitHub: [@yourusername](https://github.com/yourusername)
- LinkedIn: [Your LinkedIn](https://linkedin.com/in/yourprofile)
- Email: your.email@example.com

---

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev/) - UI framework
- [Node.js](https://nodejs.org/) - Backend runtime
- [PostgreSQL](https://www.postgresql.org/) - Database
- [Render](https://render.com/) - Hosting platform
- [Material Design](https://m3.material.io/) - Design system
- All contributors who help improve this project

---

## 📞 Support

If you encounter any issues or have questions:

1. Check the [Issues](https://github.com/yourusername/doctor_booking_app/issues) page
2. Create a new issue with detailed description
3. Join our [Discord community](#) (if applicable)
4. Email us at support@yourapp.com

---

<div align="center">
  <p>Made with ❤️ using Flutter</p>
  <p>
    <a href="#top">⬆️ Back to Top</a>
  </p>
</div>