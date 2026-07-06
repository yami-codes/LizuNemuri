# ASMR Music App Development Guidelines

## Important Notice

These guidelines are living documents that evolve with the project. Any change in practice must be reflected here, especially the architecture section, which must stay consistent with the actual project structure.

## 1. Architecture Design Guidelines

### 1.1 Decoupling Principles
- Follow SOLID principles strictly
- Use dependency injection to manage component dependencies
- Use the BLoC pattern to separate business logic from UI
- Define interfaces as contracts between modules

### 1.2 Modularization Principles
- Divide modules by functionality
- Follow the single responsibility principle
- Communicate between modules through clear interfaces
- Place shared components under common/shared

### 1.3 Code Organization
<pre>
lib/
├── core/                 # Core functionality
│   ├── di/              # Dependency injection
│   ├── theme/           # Theme configuration
│   └── utils/           # Utilities
├── data/                # Data layer
│   ├── models/          # Data models
│   ├── repositories/    # Data repositories
│   └── services/        # Service implementations
├── domain/              # Domain layer
│   ├── entities/        # Business entities
│   └── repositories/    # Repository interfaces
├── presentation/        # Presentation layer
│   ├── blocs/          # State management
│   ├── screens/        # Screens
│   └── widgets/        # Widgets
└── common/             # Shared functionality
    ├── constants/      # Constants
    └── extensions/     # Extension methods
</pre>

## 2. UI/UX Design Guidelines

### 2.1 Interface Design
- Follow Material Design 3
- Use a consistent color theme and typography
- Maintain visual hierarchy and balanced spacing
- Pay attention to detail and pixel-level alignment

### 2.2 Animation
- Use Flutter's built-in animation system
- Keep animation duration between 200–300ms
- Use curved animations (Curves.easeInOut)
- Implement smooth page transitions
- Add meaningful micro-interactions

### 2.3 Performance
- Use const constructors
- Use StatelessWidget appropriately
- Avoid heavy computation in build methods
- Use ListView.builder for long lists
- Compress and cache image assets appropriately

## 3. Code Quality Guidelines

### 3.1 Code Style
- Follow the official Dart style guide
- Format with dartfmt
- Stay type-safe; avoid dynamic
- Add comments where business logic is non-obvious

### 3.2 Testing
- Target unit test coverage > 80%
- Write widget tests for UI behavior
- Cover key flows with integration tests
- Isolate dependencies with mocks

## 4. Version Control Guidelines

### 4.1 Git
- Use a feature-branch workflow
- Follow Angular commit message conventions
- Review code regularly
- Keep main stable and releasable

### 4.2 Releases
- Follow semantic versioning
- Maintain a clear changelog per release
- Run full testing before major releases
- Update documentation for each release

## 5. Project Management Guidelines

### 5.1 Documentation
- Keep API documentation up to date
- Maintain a clear README
- Record important design decisions
- Write user and developer guides

### 5.2 Issue Tracking
- Track bugs and features with Issues
- Label Issues appropriately
- Keep tasks traceable
- Review and update task status regularly
