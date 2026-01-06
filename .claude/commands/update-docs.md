Update all project documentation by scanning the codebase for latest changes.

## What This Command Does

1. Scans `frontend/` directory for:
   - Package dependencies (package.json)
   - TypeScript types (src/types/)
   - Components (src/components/)
   - Hooks (src/hooks/)
   - Services (src/services/)
   - Stores (src/stores/)

2. Scans `backend/` directory for:
   - Python dependencies (requirements.txt)
   - Models (*/models.py)
   - Schemas (*/schemas.py)
   - API routes (*/api.py)
   - Services (*/service.py)
   - Constants (common/constants.py)
   - Exceptions (common/exceptions.py)

3. Updates documentation files:
   - `README.md` - Project overview with current versions
   - `frontend/DOCS.md` - Frontend architecture and types
   - `backend/DOCS.md` - Backend architecture and patterns

## Instructions

When running this command:

1. **Read current state** of both projects:
   - `frontend/package.json` for dependencies and versions
   - `backend/requirements.txt` for Python packages
   - All TypeScript files in `frontend/src/types/`
   - All Python files in `backend/common/`
   - API routes in `backend/main.py`

2. **Update frontend/DOCS.md** with:
   - Current dependency versions from package.json
   - All TypeScript interfaces from src/types/
   - List of components, hooks, services, stores
   - Environment variables
   - Available npm scripts

3. **Update backend/DOCS.md** with:
   - Current dependency versions from requirements.txt
   - All constants from common/constants.py
   - All exceptions from common/exceptions.py
   - Database configuration from database/connection.py
   - API endpoints from main.py and any *_api.py files
   - Module structure for any feature modules

4. **Update README.md** with:
   - Tech stack with exact versions
   - Quick start commands
   - Current project structure
   - All available scripts
   - Environment setup instructions
   - Current API endpoints

## Output Format

After updating, report:
- Files scanned
- Documentation files updated
- Summary of changes made

## Usage

```
/update-docs
```

This will scan the entire codebase and regenerate all documentation to reflect the current state.
