# RunBuddy Storyboard

This storyboard describes 5 screens for a native iOS running tracker app.

## 1. Welcome Screen
- Title: `RunBuddy`
- Main elements:
  - App logo/image view
  - Headline label: "Run smarter every day"
  - `Get Started` button
  - Secondary `I already have an account` text button
- Approximate layout:
  - Vertical stack centered in the visible area
  - Logo in upper half, CTA buttons near lower third
- iOS constraint guidance:
  - Pin root container to `Safe Area` (`top`, `leading`, `trailing`, `bottom` = 0)
  - Center stack horizontally
  - Top of stack >= `safeArea.top + 32`
  - Primary button pinned above bottom safe area: `safeArea.bottom - 24`
  - Respect compact height by reducing stack spacing (e.g., 24 -> 16)

## 2. Login / Signup Screen
- Title: `Welcome Back`
- Main elements:
  - Segmented control: `Login | Sign Up`
  - Text fields: email, password (and confirm password in signup mode)
  - Primary button: `Continue`
  - `Forgot Password?` button
  - Social sign-in row (Apple/Google placeholders)
- Approximate layout:
  - Form card under navigation title
  - Vertical field stack with consistent spacing
  - CTA button full-width below fields
- iOS constraint guidance:
  - Embed in `UINavigationController`
  - Pin scroll view to safe area for keyboard-safe form behavior
  - Form container: leading/trailing = 20
  - Field heights = 44
  - Bottom content inset >= keyboard height (managed via scroll view/content inset)

## 3. Home Dashboard (Run History)
- Title: `Home`
- Main elements:
  - Weekly summary card (distance, pace, calories)
  - `Start Run` button
  - `Recent Runs` table/list (date, distance, duration)
- Approximate layout:
  - Summary card at top
  - Prominent action button below card
  - Run history list fills remainder
- iOS constraint guidance:
  - Place inside `UITabBarController` (tab: `Home`)
  - Top summary card pinned to safe area top + 12, side margins 16
  - `Start Run` button fixed height 50, full width with side margins 16
  - Table view pinned from button bottom + 12 to safe area bottom
  - Keep bottom content above tab bar (`contentInset.bottom` for scrollable list)

## 4. Map Tracking Screen
- Title: `Track Run`
- Main elements:
  - Full-size map view
  - Floating metrics panel (time, distance, pace)
  - Bottom control row: `Start/Pause`, `Stop`, `Lap`
- Approximate layout:
  - Map as background canvas
  - Metrics card pinned near top
  - Controls anchored near bottom above tab bar/home indicator
- iOS constraint guidance:
  - Place inside `UITabBarController` (tab: `Track`)
  - Map view pinned to full safe area edges
  - Metrics panel: top = safe area + 12, centered X, width ~85%
  - Controls container: leading/trailing = 16, bottom = safe area.bottom - 12
  - Buttons equal widths in horizontal stack, min height 48

## 5. Settings Screen
- Title: `Settings`
- Main elements:
  - Profile header (avatar, name, weekly goal)
  - Table sections:
    - Preferences (units, notifications)
    - Privacy & permissions (location, health)
    - Account (logout)
- Approximate layout:
  - Profile header on top
  - Grouped table beneath
- iOS constraint guidance:
  - Place inside `UITabBarController` (tab: `Settings`)
  - Use grouped `UITableView` pinned to safe area
  - Header container height 120-160, tableHeaderView or first section header
  - Standard cell height 44+, larger tap targets for toggles (`>= 44`)

## Navigation Flow
- Welcome -> Login/Signup -> Main Tab Bar
- Tab Bar contains: Home, Track, Settings
- `Start Run` from Home can deep-link to Track tab
