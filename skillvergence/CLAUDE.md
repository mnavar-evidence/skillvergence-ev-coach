# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a React Native Expo app using Expo Router for navigation with file-based routing. The project is built with TypeScript and follows a tab-based navigation structure.

## Development Commands

- **Start development server**: `npm start` or `npx expo start`
- **Run on specific platforms**:
  - Android: `npm run android` or `expo start --android`
  - iOS: `npm run ios` or `expo start --ios`  
  - Web: `npm run web` or `expo start --web`
- **Linting**: `npm run lint`
- **Reset project**: `npm run reset-project` (moves current app to app-example and creates blank starter)

## Architecture

### Directory Structure

- `app/` - File-based routing with Expo Router
  - `(tabs)/` - Tab navigator group
  - `_layout.tsx` - Root layout with theme provider and navigation setup
- `components/` - Reusable UI components
  - `ui/` - Platform-specific UI components (iOS variants)
  - Themed components like `ThemedText` and `ThemedView`
- `hooks/` - Custom React hooks
  - `useColorScheme.ts` - Color scheme detection (with web variant)
  - `useThemeColor.ts` - Theme color management
- `constants/` - App constants including color definitions
- `assets/` - Static assets (fonts, images)

### Key Patterns

- **Theming**: Uses React Navigation's theme system with light/dark mode support
- **Color System**: Centralized in `constants/Colors.ts` with themed components
- **Font Loading**: Custom font loading with SpaceMono in root layout
- **Platform Support**: Cross-platform (iOS, Android, Web) with platform-specific variants
- **TypeScript**: Strict mode enabled with path mapping (`@/*` maps to project root)

### Navigation Structure

- Root Stack Navigator with tab navigation
- File-based routing in `app/` directory
- Tab group in `(tabs)/` directory
- 404 handling with `+not-found.tsx`

## Configuration

- **TypeScript**: Extends Expo's base config with strict mode
- **ESLint**: Uses Expo's recommended config with `dist/*` ignored
- **Expo**: Configured for universal app with new architecture enabled
- **Metro**: Web bundler with static output for web builds

## Testing & Building

The project uses Expo's build system. Check package.json scripts for available commands. No specific test framework is currently configured.