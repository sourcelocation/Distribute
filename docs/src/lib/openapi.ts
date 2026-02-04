import { createOpenAPI } from 'fumadocs-openapi/server';

export const openapi = createOpenAPI({
  input: ['./content/api/swagger.json'],
});