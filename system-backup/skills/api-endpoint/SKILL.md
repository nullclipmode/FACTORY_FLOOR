---
description: Create API endpoint with validation, auth, error handling
---

# API Endpoint

Create a complete API endpoint.

## Steps

1. Create route file at correct path (e.g., /app/api/[route]/route.ts)
2. Implement handler with input validation
3. Add authentication check if required
4. Add error handling (400 invalid input, 401 unauth, 404 not found, 500 server)
5. Test endpoint with valid and invalid requests
6. Document endpoint with request/response examples

## Output

Route file with:
- Type-safe request parsing
- Input validation
- Auth middleware (if needed)
- Proper error responses
- TypeScript types for request/response
