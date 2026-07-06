# Application Architecture Notes

## MainScreen Architecture

### Overview
`MainScreen` uses a centralized state-management architecture as the app's primary page container. It is responsible for:
1. Managing ViewModels for all main tabs/pages
2. Providing a single entry point for shared state
3. Ensuring one ViewModel instance per screen

### Core Principles

1. **Single ViewModel instance**
   - All page ViewModels are created in `MainScreen`
   - Child pages obtain ViewModels through `Provider`; they must not create their own
   - Keeps state consistent and predictable

2. **State provision**
   - `MultiProvider` at the top level supplies every ViewModel
   - Child pages use `context.read` or `Provider.of` to access them
   - Avoid creating duplicate ViewModel instances

3. **Lifecycle management**
   - `MainScreen` owns ViewModel creation and disposal
   - Initialize all ViewModels in `initState`
   - Release resources in `dispose`

### Child Page Guidelines

1. **Accessing ViewModels**
   ```dart
   // Prefer context.read
   final viewModel = context.read<HomeViewModel>();

   // Or Provider.of (equivalent)
   final viewModel = Provider.of<HomeViewModel>(context, listen: false);
   ```

2. **Listening to state**
   ```dart
   Consumer<HomeViewModel>(
     builder: (context, viewModel, child) {
       // Use viewModel state here
     },
   )
   ```

3. **Notes**
   - Do not create new ViewModel instances in child pages
   - Use `AutomaticKeepAliveClientMixin` to preserve tab state when needed
   - Perform page-specific initialization in `initState`

### Common Issues

1. **Duplicate instance**
   - Symptom: state updates appear to do nothing
   - Cause: child page created its own ViewModel
   - Fix: use the instance provided by `MainScreen`

2. **State out of sync**
   - Symptom: different tabs show different state
   - Cause: multiple ViewModel instances for the same screen
   - Fix: ensure every consumer uses `MainScreen`'s single instance
