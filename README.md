# FSPrinter
Electron app to connect printers to FacturaScripts a factura.city

## Installation

```bash
npm install
```

## Development

Run the application in development mode:

```bash
npm start
```

## Build

The project uses **electron-builder** to create distributable packages.

### Build for all platforms
```bash
npm run build
```

### Build for specific platforms

**Linux** (deb, rpm, AppImage):
```bash
npm run build:linux
```

**Windows** (installer NSIS and portable):
```bash
npm run build:win
```

**macOS** (dmg and zip):
```bash
npm run build:mac
```

The compiled files will be generated in the `dist/` directory.

## macOS: "The application is damaged"

The macOS build is not signed with an Apple Developer ID, so Gatekeeper
blocks it after download with a misleading "damaged" message. Remove the
quarantine attribute to allow it to run:

```bash
xattr -dr com.apple.quarantine "/Applications/FSPrinter.app"
```

## Project Information

- **Author:** Carlos García Gómez
- **License:** LGPL-3.0

## Contact or feedback
https://facturascripts.com/plugins/tickets