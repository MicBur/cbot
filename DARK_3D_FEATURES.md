# Qt Trade Frontend - Dark 3D Edition

## 🎨 New Dark Theme Features

### Enhanced Color Scheme
- Deep dark backgrounds with subtle gradients
- Neon cyan accent colors with glow effects
- Glass morphism effects on UI elements
- Dynamic color transitions and animations

### Theme Properties
```qml
// Main colors
bg: "#050507"              // Deep black background
bgElevated: "#0a0a0f"      // Slightly elevated surfaces
bgCard: "#111119"          // Card backgrounds
bgGlass: "#ffffff08"       // Glass effect overlay

// Accent colors with glow
accent: "#00ffff"          // Neon cyan
accentGlow: "#00ffff"      // For glow effects
success: "#00ff88"         // Bright green
danger: "#ff4757"          // Vibrant red
```

## 🎭 3D Chart Components

### CandleChart3D
- Pseudo-3D candlestick visualization using Canvas
- Depth perspective effects
- Animated candle bodies with gradients
- Glow effects on recent candles
- Interactive grid with 3D perspective
- Smooth loading animations

Features:
- `perspectiveDepth`: Control 3D depth effect
- `showGrid`: Toggle 3D grid display
- `showGlow`: Enable/disable glow effects
- Real-time data updates with animations

### Portfolio3D
- 3D donut chart for portfolio visualization
- Auto-rotation with pause control
- Interactive hover effects
- Animated segment highlighting
- Dynamic legend with percentages
- Glass morphism effects

## ✨ Enhanced UI Components

### MarketListEnhanced
- Staggered appearance animations
- Live price flash effects
- Sparkline mini-charts for each ticker
- Glow effects for high movers (>5% change)
- Interactive hover scaling
- Pulse animations for significant changes
- Volume indicators

### Modern Navigation (SideNav)
- Icon-based navigation with labels
- Bounce animations on selection
- Glow effects for active items
- Glass morphism background
- Smooth hover transitions
- Selection indicator bars

### StatusBadge Updates
- Gradient backgrounds
- Glass overlay effects
- Pulse animations on status change
- Interactive hover scaling
- Modern rounded design

## 🌟 Special Effects

### Particle System
- Floating particle effects in background
- Customizable emit rate and lifespan
- Cyan-colored particles with fade effects

### Animations
- Smooth transitions (150ms fast, 300ms medium, 600ms slow)
- Glow pulse effects (1200ms duration)
- Easing curves for natural motion
- Scale and opacity animations

### Glass Morphism
- Semi-transparent overlays
- Blur effects on backgrounds
- Subtle borders with hover states

## 🚀 Usage

The application automatically uses the new dark theme and 3D components. Key features:

1. **Market Dashboard**: Enhanced market list with live animations
2. **3D Charts**: Interactive candlestick charts with depth
3. **Portfolio View**: 3D donut visualization of holdings
4. **Status Indicators**: Modern badges with glow effects

## 🔧 Customization

To adjust theme settings, modify `/workspace/qml/Theme.qml`

To control 3D effects:
- Adjust `perspectiveDepth` in CandleChart3D
- Toggle `autoRotate` in Portfolio3D
- Enable/disable `showGlow` for glow effects

## 📱 Performance

All animations are GPU-accelerated and optimized for smooth performance. The particle system uses minimal resources with configurable emit rates.