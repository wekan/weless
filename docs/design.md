## Convert Meteor 3 WeKan kanban to Haxe and HaxeUI

- WeKan Directory Structure: docs/DeveloperDocs/Directory-Structure.md
- WeKan uses:
  - Meteor 3.5-rc.2
  - Node.js 24.18.0
  - MongoDB 7.x
  - Haxe 5.0.0-preview.1 (installed with `npx lix install haxe 5.0.0-preview.1` and `npx lix use haxe 5.0.0-preview.1`)
- Save Haxe files to haxe directory
- Haxe 5.0.0-previes.1 was installed with:
```
npx lix install haxe 5.0.0-preview.1
npx lix use haxe 5.0.0-preview.1
```
- PHP 8.5 was installed at macOS with:
```
brew install php@8.5
```

# Context & Architecture Summary for Haxe Full-Stack App

## Objective
Build a Trello/Wekan-style Kanban board application featuring drag-and-drop mechanics and a desktop-like SPA layout (similar to GWT Mail architecture). The goal is a unified Haxe codebase that compiles to both an HTML5 frontend and a highly portable backend.

## Tech Stack & Constraints
- **Language:** Haxe (Full-Stack)
- **Frontend Framework:** HaxeUI (specifically `haxeui-core` and `haxeui-html5`) using XML for layouts and macros for component binding.
- **Backend Targets:** Must support Dual-Target Compilation via `build.hxml`:
  1. **PHP:** Standard PHP (using native PDO for database connectivity) for traditional web hosting.
  2. **JavaScript (Node.js):** Tailored for AWS Lambda / Cloudflare Workers (Serverless environments).
- **Backend API Library:** Tink Ecosystem (`tink_web` / `tink_http`) for type-safe, environment-agnostic routing.
- **Database:** PostgreSQL (Cloud-native, e.g., Neon or AWS Aurora Serverless).

## Database Schema (PostgreSQL)
Three core relational tables:
1. `Board`: id (Int/Serial), title (String)
2. `Column`: id (Int/Serial), board_id (FK), title (String), position (Int)
3. `Card`: id (Int/Serial), column_id (FK), title (String), description (Text), position (Int)

### Additional Notes:
- Ensure all database fields are properly indexed for performance.
- Consider adding constraints and validations as needed.

## Project Structure & Build Configuration (`build.hxml`)
```hxml
# Common configuration
-cp src
-lib tink_web

--each

# --- TARGET 1: Frontend (HTML5/JS) ---
-cp src/client
-lib haxeui-core
-lib haxeui-html5
-main ClientMain
-js deploy/www/html5/index.js

--next

# --- TARGET 2: Backend (PHP / AWS Lambda Node.js) ---
-cp src/server
-main ServerMain
# Conditional compilation flags handle target outputs:
# -php deploy/www/api  (For PHP Webhosts)
# -js deploy/aws/index.js (For AWS Lambda/Serverless)

```

## Instructions for AI Generation

When generating code, configurations, or refactoring logic for this project, always ensure:

1. **HaxeUI Idioms:** Use HaxeUI custom XML layouts for views and macro-driven `ComponentMacros.buildComponent()` in the client main.
2. **Platform Agnostic Backend:** Use Haxe conditional compilation flags (`#if php`, `#if js`) when writing backend logic, especially for database connection pools, to ensure it compiles flawlessly to both target environments.
3. **Type-Safety:** Leverage `tink_web` routing structures for processing `PUT` requests for card repositioning (e.g., updating `column_id` and `position`).

